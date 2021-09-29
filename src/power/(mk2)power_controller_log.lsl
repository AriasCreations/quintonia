// power_controller_log.lsl
// Logs the regions kWh usage
//  Based upon: Paramour Region Traffic Monitor v2.0 By Aine Caoimhe (LACM) Sept 2015
//   Provided under Creative Commons Attribution-Non-Commercial-ShareAlike 4.0 International license.
//   Please be sure you read and adhere to the terms of this license: https://creativecommons.org/licenses/by-nc-sa/4.0/

float VERSION = 5.0;        // 27 November 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

float persistDelay = 30.0;    // when there is new data to persist, how long to wait (in seconds) before writing the notecard

string PASSWORD = "*";
integer thisMonth;
integer thisYear;
list monthList;     // UTC | Name | Position | Key
list masterList;    // UTC | Key
integer lastStatsUpdate;
string thisGrid = "";
integer logging;


updateConsumers(key consumer)
{
    integer now=llGetUnixTime();
    // get consumer name
    string name = llKey2Name(consumer);
    // get consumer position
    vector position = llList2Vector(llGetObjectDetails(consumer, [OBJECT_POS]), 0);
    // add to both master list and monthly list
    masterList = [] + masterList + [now,consumer];
    monthList = [] + monthList + [now, name, position, consumer];
    // sort both lists in descending order
    masterList=[]+llListSort(masterList,2,FALSE);
    monthList=[]+llListSort(monthList,4,FALSE);
}

persistData()
{
    if (logging == TRUE)
    {
        // whenever data has changed and new persist needs to happen
        string cardName="log: "+(string)thisYear+"-";
        if (thisMonth<10) cardName+="0";
        cardName+=(string)thisMonth;
        if (llGetInventoryType(cardName)==INVENTORY_NOTECARD)
        {
            llRemoveInventory(cardName);
            llSleep(0.25);  // have to sleep to give it time to register
        }
        integer i;
        integer l=llGetListLength(monthList);
        string data;
        while (i<l)
        {
            data+=llDumpList2String(llList2List(monthList,i,i+3),"|")+"\n";
            i+=4;
        }
        if (llStringLength(data)>0) osMakeNotecard(cardName,data);
    }
}

doMonthRollOver(list today)
{
    // triggered by first tick of the timer after month changes so force a persist to close out previous month first
    persistData();
    // set new date
    thisYear=llList2Integer(today,0);
    thisMonth=llList2Integer(today,1);
    monthList=[];
    // need to force persist of this new month too
    persistData();
}

loadData()
{
    monthList=[];
    masterList=[];
    integer i=llGetInventoryNumber(INVENTORY_NOTECARD);
    while (--i>-1)
    {
        string card=llGetInventoryName(INVENTORY_NOTECARD,i);
        if (llSubStringIndex(card,"log: ")==0)
        {
            integer year=(integer)llGetSubString(card,5,8);
            integer month=(integer)llGetSubString(card,10,11);
            list thisData=llParseString2List(osGetNotecard(card),["|","\n"],[]);
            if ((year==thisYear) && (month==thisMonth)) monthList=[]+thisData;
            integer e;
            integer l=llGetListLength(thisData);
            while (e<l)
            {
                key who=llList2Key(thisData,e+3);
                integer when=llList2Integer(thisData,e);
                integer index=llListFindList(masterList,[who]);
                if (index==-1) masterList=[]+masterList+[when,who];
                else if (llList2Integer(masterList,index-1)<when) masterList=llListReplaceList(masterList,[when],index-1,index-1);
                e+=4;
            }
        }
    }
}


default
{
    state_entry()
    {
        list today=llParseString2List( llGetTimestamp(), ["-", "T", ":", "."], [] );
        thisYear=llList2Integer(today,0);
        thisMonth=llList2Integer(today,1);
        loadData();
        llSetTimerEvent(persistDelay);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_Message:"+str +" KEY="+(string)id);
        list tok = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "LOG_CONSUMER")
        {
            updateConsumers(id);
        }
		else if (cmd == "INIT")
		{
			PASSWORD = llList2String(tok, 1);
            thisGrid = llList2String(tok, 2);
            logging = num;
		}
        else if (cmd == "LOGSET")
        {
            logging = num;
        }
    }

    timer()
    {
        // check for month roll-over
        list today=llParseString2List( llGetTimestamp(), ["-", "T", ":", "."], [] );
        integer newMonth=llList2Integer(today,1);
        if (newMonth!=thisMonth) doMonthRollOver(today);
        persistData();
    }

    changed (integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
        else if (change & CHANGED_REGION_START) llResetScript();
    }

    on_rez (integer foo)
    {
        llResetScript();
    }

    dataserver(key id, string m)
    {
        debug("dataserver: " +m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk, 1) != PASSWORD) return;
        string cmd = llList2String(tk,0);
        integer i;
        //for updates
        if (cmd == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)((integer)(VERSION*10)) + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            string me = llGetScriptName();
            while (len--)
            {
                string item = llGetInventoryName(INVENTORY_SCRIPT, len);
                if (item != me)
                {
                    answer += item + ",";
                }
            }
            answer += me;
            osMessageObject(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(id) != llGetOwner())
            {
                llMessageLinked(LINK_SET, 0, "UPDATE-FAILED", "");
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(tk, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer delSelf = FALSE;
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item == me) delSelf = TRUE;
                else if (llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }

}
