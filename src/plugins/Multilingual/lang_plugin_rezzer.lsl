// lang_plugin_rezzer.lsl
/**
This script is used to install and upgrade language notecards.
On startup it records the version and language of notecards in the object.
It responds to the LANGUAGE-CHECK command from the language manager.
**/

float VERSION = 1.4;  //16 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

string TXT_CLOSE = " ❌ ";
string TXT_SELECT = "*";

integer VERSION;
string PASSWORD;
list langVers  =[];
list langNames =[];
string SUFFIX = "R1";

getLangInfo()
{
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    langNames = [];
    langVers  = [];
    string cmd;
    string val;
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer j;
    for (j=0; j<count; j+=1)
    {
        if ( llGetSubString( llGetInventoryName(INVENTORY_NOTECARD, j), -7, -1) == "-langR1")
        {
            string langName = llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, j), 0, 4);
            integer langVer = 0;
            list lines = llParseString2List(osGetNotecard(langName+"-lang"+SUFFIX), ["\n"], []);
            integer i;
            for (i=0; i < llGetListLength(lines); i++)
            {
                list tok = llParseString2List(llList2String(lines,i), ["="], []);
                if (llList2String(tok,1) != "")
                {
                    cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    if (cmd == "@VER") langVer = llList2Integer(tok, 1);
                }
            }
            debug("SUFFIX:" +SUFFIX + " LANG:" + langName + "  VER:" +(string)langVer);
            langNames += [langName];
            langVers  += [langVer];
        }
    }
    debug(llDumpList2String(langNames, "\t") + "\n" + llDumpList2String(langVers, "\t"));
}


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

integer listener=-1;
integer listenTs;

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

integer startOffset=0;

multiPageMenu(key id, string message, list opt)
{
    integer l = llGetListLength(opt);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, opt+[TXT_CLOSE], ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(opt, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}

default
{

    state_entry()
    {
        getLangInfo();
        debug("langInfo:\n" + llDumpList2String(langNames, "\t") + "\n" +llDumpList2String(langVers, "\t"));
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("listen: " + m);
        if (m == TXT_CLOSE)
        {
            //;
        }
        else if (m ==">>")
        {
            startOffset += 10;
            multiPageMenu(id, TXT_SELECT, langNames);
        }
        else
        {
            // change language
            llMessageLinked(LINK_THIS, 1, "SET-LANG|"+m, "");
            llListenRemove(listener);
            listener = -1;
        }
    }

    dataserver(key id, string m)
    {
        debug("dataserver: " +m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk, 1) != PASSWORD) return;
        string lang;
        string cmd = llList2String(tk,0);
        key managerKey = llList2Key(tk, 2);

        if (cmd == "LANGUAGE-CHECK")
        {
            // We get  CMD|PASSWORD|SENDERID|LANGNC|SUFFIX|VER
            // Send back LANGUAGE-REPLY|PASSWORD|ourID|lang|ver
            lang = llList2String(tk, 3);
            string answer = "LANGUAGE-REPLY|" + PASSWORD + "|" + (string)llGetKey() + "|" + lang +"|";

            integer i = llListFindList(langNames, lang);
            if (i != -1) answer += llList2String(langVers, i); else answer += "0";
            osMessageObject(managerKey, answer);
            debug("dataserver_reply: " + answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            // Update available for an existing notecard
            if (llGetOwnerKey(id) != llGetOwner())
            {
                osMessageObject(managerKey, "UPDATE-FAILED");
            }
            else
            {
                lang = llList2String(tk, 3);
                if (llGetInventoryType(lang +"-lang") == INVENTORY_NOTECARD)
                {
                    llRemoveInventory(lang +"-lang");
                    llSleep(1.0);
                }
                osMessageObject(managerKey, "UPDATE-REPLY|" + PASSWORD + "|" + (string)llGetKey() + "|" + lang);
            }
        }
        else if (cmd == "ADD-CHECK")
        {
            // check that the new notecard is here
            lang = llList2String(tk, 3);
            if (llGetInventoryType(lang +"-lang") == INVENTORY_NOTECARD)
            {
                osMessageObject(managerKey, "UPDATE-OKAY");
                llMessageLinked(LINK_THIS, 1, "RELOAD", "");
            }
            else
            {
                osMessageObject(managerKey, "UPDATE-FAILED");
            }
            llResetScript();
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg + " From:" + (string)sender_num);
        list tk = llParseString2List(msg, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "LANG_MENU")
        {
            startListen();
            multiPageMenu(id, TXT_SELECT, langNames);
            llSetTimerEvent(1000);
        }
        if (cmd == "CMD_DEBUG")
        {
            DEBUGMODE = llList2Integer(tk, 2);
            return;
        }
        else if (cmd == "RESET") llResetScript();
    }

    timer()
    {
        checkListen();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
