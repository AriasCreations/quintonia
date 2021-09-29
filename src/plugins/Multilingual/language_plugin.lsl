// language_plugin.lsl
/**
 This script is used to install and upgrade language notecards.
 On startup it records the version and language of notecards in the object.
 It responds to the LANGUAGE-CHECK command from the language manager.
**/

float VERSION = 2.0;  // Beta  29 November 2020
integer RSTATE = -1;  // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

string TXT_CLOSE = "X";
string TXT_SELECT = "*";

integer VERSION;
string PASSWORD;
list langSuffixes = [];   // eg: [ B1     B2      B1      B2      B1      B2      B1      B2      B1      B2    ]
list langNames    = [];   // eg: [ de-DE  de-DE   en-GB   en-GB   es-ES   es-ES   r-FR    fr-FR   pt-PT   pt-PT ]
list langVers     = [];   // eg: [ 2      2       2       2       2       2       2       2       2       2     ]

string SUFFIX = "*";

integer checkNcExists(string name)
{
    integer result = FALSE;
    if (llGetInventoryType(name) == INVENTORY_NOTECARD) result = TRUE;
    return result;
}

getLangInfo()
{
    if (checkNcExists("sfp") == TRUE) PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    langSuffixes = [];
    langNames = [];
    langVers  = [];
    string  langName;
    integer langVer;
    string tmpName;
    list lines = [];
    string cmd;
    string val;
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer j;
    for (j = 0; j < count; j++)
    {
        if (llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, j), -7, -3) == "-lang")
        {
            SUFFIX = llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, j), -2, -1);
            langName = llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, j), 0, 4);
            langVer = 0;
            tmpName = langName+"-lang"+SUFFIX;
            if (checkNcExists(tmpName) == TRUE)
            {
                lines = llParseString2List(osGetNotecard(tmpName), ["\n"], []);
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
                langSuffixes += SUFFIX;
                langNames += [langName];
                langVers  += [langVer];
            }
        }
    }
    debug("Suffixes:\n"+llDumpList2String(langSuffixes, "\t") +"\nLangNames:\n"+llDumpList2String(langNames, "\t") +"\nLanVers:\n"+llDumpList2String(langVers, "\t"));
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
        if (llSubStringIndex(llGetObjectName(), "Update")>=0 || llSubStringIndex(llGetObjectName(), "Rezzer")>=0)
        {
            llSetScriptState(llGetScriptName(), FALSE); // Dont run in the rezzer as that has own 'special' version
            return;
        }
        //
        getLangInfo();
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
            llMessageLinked(LINK_SET, 1, "SET-LANG|"+m, id);
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
                if (checkNcExists(lang +"-lang") == TRUE)
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

            if (checkNcExists(lang +"-lang") == TRUE)
            {
                osMessageObject(managerKey, "UPDATE-OKAY");
                llMessageLinked(LINK_SET, 1, "RELOAD", "");
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
        list tk = llParseString2List(msg, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "MENU_LANGS")
        {
            debug("link_message: " + msg + "  Num="+(string)num +" From:" + (string)sender_num);
            list suffixLangs = [];
            // LANG_MENU|SUFFIX
            SUFFIX = llList2String(tk, 1);
            integer i;
            integer count = llGetListLength(langSuffixes);
            for (i = 0; i < count; i++)
            {
                if (llList2String(langSuffixes, i) == SUFFIX) suffixLangs += llList2String(langNames, i);
            }
            string str = TXT_SELECT;
            if (RSTATE == 0) str += " (-B-)"; else if (RSTATE == -1) str += " (-RC-)";
            startListen();
            multiPageMenu(id, str, suffixLangs);
            llSetTimerEvent(1000);
        }
        // Previous behaviour - to be
        if (cmd == "LANG_MENU")
        {
            string str = TXT_SELECT;
            if (RSTATE == 0) str += " (-B-)"; else if (RSTATE == -1) str += " (-RC-)";
            startListen();
            multiPageMenu(id, str, langNames);
            llSetTimerEvent(1000);
        }
        else if (cmd == "CMD_DEBUG")
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
