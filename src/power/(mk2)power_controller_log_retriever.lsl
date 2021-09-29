// power_controller_log_retriever.lsl
//   Based on:
        // Paramour Stats Retriever for Region Traffic Monitor 2.0
        // by Aine Caoimhe (LACM) Setp 2015
        // Provided under Creative Commons Attribution-Non-Commercial-ShareAlike 4.0 International license.
        // Please be sure you read and adhere to the terms of this license: https://creativecommons.org/licenses/by-nc-sa/4.0/
        //
        // Requires no additional OSSL functions other than the ones that already need to be enabled for the Traffic Monitor
        //
        // Reports are handed to you directly (and very briefly stored in the prim in order to be able to deliver it to you, then deleted)
        // Times/dates are converted to SL time and is daylight-savings aware
        // original dates/times stored on source cards are UTC so may overlap to next month on final day
        //
        // list monthList;     // UTC | Name | Position | Key
        //

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

float VERSION = 5.0;		// 27 November 2020

string PASSWORD = "*";
string  languageCode = "";      // use defaults below unless language config notecard present
// For multilingual support
string	TXT_CLOSE="CLOSE";
string	TXT_PREVIOUS="< PREV";
string	TXT_NEXT="NEXT >";
string	TXT_SHOW_LOG="Show log";
string	TXT_ZERO_STATS="Zero stats";
string	TXT_RESETTING_STATS="Resetting statistics";
string	TXT_SELECT="Select";
string	TXT_MONTH_STATS="Statistics for the month";
string	TXT_TOTAL_CONSUMERS="Total consumer requests";
string	TXT_UNIQUE_LOCS="Unique locations";
// Three letter abbreviations for days of week
string	TXT_DAYS="Days";
string	TXT_SUN="Sun";
string	TXT_MON="Mon";
string	TXT_TUE="Tue";
string	TXT_WED="Wed";
string	TXT_THU="Thu";
string	TXT_FRI="Fri";
string	TXT_SAT="Sat";
// Months
string	TXT_MONTHS="months";
string	TXT_JANUARY="January";
string	TXT_FEBRUARY="February";
string	TXT_MARCH="March";
string	TXT_APRIL="April";
string	TXT_MAY="May";
string	TXT_JUNE="June";
string	TXT_JULY="July";
string	TXT_AUGUST="August";
string	TXT_SEPTEMBER="September";
string	TXT_OCTOBER="October";
string	TXT_NOVEMBER="November";
string	TXT_DECEMBER="December";
string	TXT_ERROR_NOTFOUND="ERROR: could not find that card....rebuilding card list";
string	TXT_BAD_PASSWORD="Bad password";
string	TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
//
string SUFFIX="C4";
//
float timeOut=120.0;        // 2 minutes to respond to a dialog or remove listener
integer myChannel;
integer handle;
string txtDia;
list butDia;
list logs;
integer indLog;
list months;
list weekdays;
string heading = "";
string status = "";

loadConfig()
{
    PASSWORD = osGetNotecardLine("sfp", 0);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                if (cmd == "LANG") languageCode = val;
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang"+SUFFIX;
    if (llGetInventoryType(languageNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(languageNC), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    // Remove start and end " marks
                    val = llGetSubString(val, 1, -2);
                    // Now check for language translations
                    if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_PREVIOUS") TXT_PREVIOUS = val;
                    else if (cmd == "TXT_NEXT") TXT_NEXT = val;
                    else if (cmd == "TXT_SHOW_LOG") TXT_SHOW_LOG = val;
                    else if (cmd == "TXT_ZERO_STATS") TXT_ZERO_STATS = val;
                    else if (cmd == "TXT_RESETTING_STATS") TXT_RESETTING_STATS = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_MONTH_STATS") TXT_MONTH_STATS = val;
                    else if (cmd == "TXT_TOTAL_CONSUMERS") TXT_TOTAL_CONSUMERS = val;
                    else if (cmd == "TXT_UNIQUE_LOCS") TXT_UNIQUE_LOCS = val;
                    else if (cmd == "TXT_DAYS") TXT_DAYS = val;
                    else if (cmd == "TXT_SUN") TXT_SUN = val;
                    else if (cmd == "TXT_MON") TXT_MON = val;
                    else if (cmd == "TXT_TUE") TXT_TUE = val;
                    else if (cmd == "TXT_WED") TXT_WED = val;
                    else if (cmd == "TXT_THU") TXT_THU = val;
                    else if (cmd == "TXT_FRI") TXT_FRI = val;
                    else if (cmd == "TXT_SAT") TXT_SAT = val;
                    else if (cmd == "TXT_MONTHS") TXT_MONTHS = val;
                    else if (cmd == "TXT_JANUARY") TXT_JANUARY = val;
                    else if (cmd == "TXT_FEBRUARY") TXT_FEBRUARY = val;
                    else if (cmd == "TXT_MARCH") TXT_MARCH = val;
                    else if (cmd == "TXT_APRIL") TXT_APRIL = val;
                    else if (cmd == "TXT_MAY") TXT_MAY = val;
                    else if (cmd == "TXT_JUNE") TXT_JUNE = val;
                    else if (cmd == "TXT_JULY") TXT_JULY = val;
                    else if (cmd == "TXT_AUGUST") TXT_AUGUST = val;
                    else if (cmd == "TXT_SEPTEMBER") TXT_SEPTEMBER = val;
                    else if (cmd == "TXT_OCTOBER") TXT_OCTOBER = val;
                    else if (cmd == "TXT_NOVEMBER") TXT_NOVEMBER = val;
                    else if (cmd == "TXT_DECEMBER") TXT_DECEMBER = val;
                    else if (cmd == "TXT_ERROR_NOTFOUND") TXT_ERROR_NOTFOUND = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                }
            }
        }
    }
}

// ********************** THIS PART COMES FROM SECOND LIFE WIKI: http://wiki.secondlife.com/wiki/Unix2PST_PDT ****************
// Convert Unix Time to SLT, identifying whether it is currently PST or PDT (i.e. Daylight Saving aware)
// Original script: Omei Qunhua December 2013
// Fixed by Aine Caoimhe to work in Opensim Setp 2015
// Returns a string containing the SLT date and time, annotated with PST or PDT as appropriate, corresponding to the given Unix time.
// e.g. Wed 2013-12-25 06:48 PST
//
string Unix2PST_PDT(integer insecs)
{
    string str = Convert(insecs - (3600 * 8) );   // PST is 8 hours behind GMT
    if (llGetSubString(str, -3, -1) == "PDT")     // if the result indicates Daylight Saving Time ...
        str = Convert(insecs - (3600 * 7) );      // ... Recompute at 1 hour later
    return str;
}

// This leap year test is correct for all years from 1901 to 2099 and hence is quite adequate for Unix Time computations
integer LeapYear(integer year)
{
    return !(year & 3);
}

integer DaysPerMonth(integer year, integer month)
{
    if (month == 2)      return 28 + LeapYear(year);
    return 30 + ( (month + (month > 7) ) & 1);           // Odd months up to July, and even months after July, have 31 days
}

string Convert(integer insecs)
{
    integer w; integer month; integer daysinyear;
    integer mins = insecs / 60;
    integer secs = insecs % 60;
    integer hours = mins / 60;
    mins = mins % 60;
    integer days = hours / 24;
    hours = hours % 24;
    integer DayOfWeek = (days + 4) % 7;    // 0=Sun thru 6=Sat

    integer years = 1970 +  4 * (days / 1461);
    days = days % 1461;                  // number of days into a 4-year cycle

    @loop;
    daysinyear = 365 + LeapYear(years);
    if (days >= daysinyear)
    {
        days -= daysinyear;
        ++years;
        jump loop;
    }
    ++days;

    month=0;
    w=0;
    while (days > w)
    {
        days -= w;
        w = DaysPerMonth(years, ++month);
    }
    string str =  ((string) years + "-" + llGetSubString ("0" + (string) month, -2, -1) + "-" + llGetSubString ("0" + (string) days, -2, -1) + " " +
    llGetSubString ("0" + (string) hours, -2, -1) + ":" + llGetSubString ("0" + (string) mins, -2, -1) );

    integer LastSunday = days - DayOfWeek;
    string PST_PDT = " PST";                  // start by assuming Pacific Standard Time
    // Up to 2006, PDT is from the first Sunday in April to the last Sunday in October
    // After 2006, PDT is from the 2nd Sunday in March to the first Sunday in November
    if (years > 2006 && month == 3  && LastSunday >  7)     PST_PDT = " PDT";
    if (month > 3)                                          PST_PDT = " PDT";
    if (month > 10)                                         PST_PDT = " PST";
    if (years < 2007 && month == 10 && LastSunday > 24)     PST_PDT = " PST";
    return (llList2String(weekdays, DayOfWeek) + " " + str + PST_PDT);
}
// ***************** END OF FUNCTION FROM SL WIKI ****************************

doFetch(string cardName)
{
    integer year=(integer)llGetSubString(cardName,5,8);
    integer month=(integer)llGetSubString(cardName,10,11);
    list data=llParseString2List(osGetNotecard(cardName),["|","\n"],[]);
    string details;
    list positions;
    integer consumersCount;
    integer i=0;
    integer l=llGetListLength(data);
    while (i<l)
    {
        // UTC | Name | Position | Key
        string date=Unix2PST_PDT(llList2Integer(data,i));
        string name=llList2String(data,i+1);
        string position=llList2String(data,i+2);
        key who=llList2Key(data,i+3);
        details=date+" "+name+" @ "+position+"\n"+details;   // prepend so the list order ends up being from start of month to end
        consumersCount++;
        if (llListFindList(positions,[position])==-1) positions=[]+positions+[position];
        i+=4;
    }
    string stats=TXT_MONTH_STATS + " " +llList2String(months,month)+ " " +(string)year;
    stats+="\n-------------------------------------------------------";
    stats+="\n" + TXT_TOTAL_CONSUMERS + ": " + (string)consumersCount;
    stats+="\n" + TXT_UNIQUE_LOCS + ": " +(string)llGetListLength(positions);
    stats+="\n-------------------------------------------------------\n";
    stats+=details;
    string cardToGive="Stats for "+heading+" for "+llList2String(months,month)+" "+(string)year;
    osMakeNotecard(cardToGive,stats);
    llSleep(0.25);  // give it time to be stored
    llGiveInventory(llGetOwner(),cardToGive);
    llRemoveInventory(cardToGive);
}

showMenuMain()
{
    txtDia=TXT_SELECT;
    butDia=[]+llList2List(logs,indLog,indLog+8);
    while (llGetListLength(butDia)<9) {butDia=[]+butDia+["-"];}
    butDia=[]+butDia+[TXT_PREVIOUS, TXT_CLOSE, TXT_NEXT];
    startListening();
}

doPrebuild()
{
    integer i=llGetInventoryNumber(INVENTORY_NOTECARD);
    logs=[];
    indLog=0;
    while (--i>=0)
    {
        string name=llGetInventoryName(INVENTORY_NOTECARD,i);
        if (llSubStringIndex(name,"log: ")==0) logs=[]+logs+[llGetSubString(name,5,-1)];
    }
}

startListening()
{
    llSetTimerEvent(timeOut);
    handle=llListen(myChannel,"",llGetOwner(),"");
    llDialog(llGetOwner(),txtDia,llList2List(butDia,9,11)+llList2List(butDia,6,8)+llList2List(butDia,3,5)+llList2List(butDia,0,2),myChannel);
}

stopListening()
{
    llSetTimerEvent(0.0);
    llListenRemove(handle);
}


default
{
    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        months = [TXT_MONTHS, TXT_JANUARY, TXT_FEBRUARY, TXT_MARCH, TXT_APRIL, TXT_MAY, TXT_JUNE, TXT_JULY, TXT_AUGUST, TXT_SEPTEMBER, TXT_OCTOBER, TXT_NOVEMBER, TXT_DECEMBER];
        weekdays = [TXT_SUN, TXT_MON, TXT_TUE, TXT_WED, TXT_THU, TXT_FRI, TXT_SAT];
        myChannel=0x80000000|(integer)("0x"+(string)llGetKey());
    }

    changed (integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
        else if (change & CHANGED_REGION_START) llResetScript();
    }

    on_rez(integer foo)
    {
        integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
        integer index;
        string name;
        for (index = 0; index < count; index++)
        {
            name = llGetInventoryName(INVENTORY_NOTECARD, index);
            if (llGetSubString(name, 0, 3) == "log:") llRemoveInventory(name);
        }
        llResetScript();
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_Message:"+str +" KEY="+(string)id);
        list tok = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tok,0);

        if (cmd == "SHOW_LOG")
        {
            status = "showLog";
            doPrebuild();
            showMenuMain();
        }
        if (cmd == "DEL_LOG")
        {
            status = "delLog";
            doPrebuild();
            showMenuMain();
        }
        else if (cmd == "INIT")
        {
            PASSWORD = llList2String(tok, 1);
            heading = llList2String(tok, 2);
        }
        else
        {
            tok = llParseString2List(str, ["|"], []);
            cmd = llList2String(tok,0);
            if (cmd == "SET-LANG")
            {
                languageCode = llList2String(tok, 1);
                loadLanguage(languageCode);
                llResetScript();
            }
        }
    }

    timer()
    {
        stopListening();
    }

    listen(integer channel, string name, key who, string message)
    {
        stopListening();
        if (message == TXT_CLOSE)
        {
            stopListening();
        }
        else if (message == "-")
        {
            startListening();
        }
        else if ((message == TXT_PREVIOUS) || (message == TXT_NEXT))
        {
            if (message==TXT_NEXT) indLog+=9;
            else indLog-=9;
            if (indLog>=llGetListLength(logs)) indLog=0;
            if (indLog<=-9) indLog=llGetListLength(logs)-9;
            if (indLog<0) indLog=0;
            showMenuMain();
        }
        else
        {
            string logToFetch="log: "+message;
            if (llGetInventoryType(logToFetch) != INVENTORY_NOTECARD)
            {
                llOwnerSay(TXT_ERROR_NOTFOUND);
                doPrebuild();
                showMenuMain();
            }
            else
            {
                if (status == "showLog")
                {
                    status = "";
                    doFetch(logToFetch);
                }
                else if (status == "delLog")
                {
                    status = "";
                    llRemoveInventory(logToFetch);
                    doPrebuild();
                    showMenuMain();
                }
            }
            startListening();
        }
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
