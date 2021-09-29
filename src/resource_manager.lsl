// resource_manager.lsl

float VERSION = 1.0;      // 23 August 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

string BASEURL  = "https://test.quintonia.net/index.php?option=com_quinty&format=raw&";
string scriptsServerURL = "https://test.quintonia.net/components/com_quinty/resource_manager.php";

key farmHTTP = NULL_KEY;

// Use the values below if no language notecard
string  languageCode = "en-GB";             // LANG=en-GB

// For multi-lingual support
string TXT_CLOSE="CLOSE";
string TXT_CHECK="Check";
string TXT_ADDED="Added";
string TXT_SELECT="Select";
string TXT_FOUND="Found";
string TXT_STOP="STOP";
string TXT_START="START";
string TXT_OFF="OFF";
string TXT_NOT_STORED="not in my Inventory";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE    = "@";

string SUFFIX = "R2";
string PASSWORD="*";
integer FARM_CHANNEL = -911201;

vector OLIVE   = <0.239, 0.600, 0.439>;   // Okay
vector PURPLE  = <0.694, 0.051, 0.788>;   // Status change / Comms

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


list scripts = [];
list versions = [];
list recents = [];

integer listener=-1;
integer listenTs;
integer startOffset=0;
integer lastTs;
integer numScripts = 0;
key ownKey;
key ownGroup;
key toucher = NULL_KEY;
key notecardQueryId;
string status;
integer active=TRUE;


startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(ownKey), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        status = "";
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
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
                    else if (cmd == "TXT_SELECT") TXT_SELECT= val;
                    else if (cmd == "TXT_CHECK") TXT_CHECK = val;
                    else if (cmd == "TXT_ADDED") TXT_ADDED = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_NOT_STORED") TXT_NOT_STORED = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

postMessage(string msg)
{
    debug("postMessage: " + msg);
    farmHTTP = llHTTPRequest( BASEURL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded", HTTP_BODY_MAXLENGTH, 16384], msg);
}

// Convert to human-readable HH:MM:SS format
string getTime()
{
    integer now = (integer)llGetWallclock();
    integer seconds = now % 60;
    integer minutes = (now / 60) % 60;
    integer hours = now / 3600;
    return llGetSubString("0" + (string)hours, -2, -1) + ":"
        + llGetSubString("0" + (string)minutes, -2, -1) + ":"
        + llGetSubString("0" + (string)seconds, -2, -1);
}

refresh()
{
debug("START:" +llDumpList2String(recents, "\n"));
    integer count = llGetListLength(recents);
    if (count >0)
    {
        integer ts = llGetUnixTime();
        integer i;
        for (i=0; i<count; i+=2)
        {
            if (ts - llList2Integer(recents, i+1) > 120) recents = llDeleteSubList(recents, i, i+1);
        }
    }
debug("END:" +llDumpList2String(recents, "\n"));
    if (active == TRUE)
    {
        llSetText("V:" +qsFloat2String(VERSION, 1, FALSE) +"\n" +TXT_FOUND +": " +(string)numScripts, OLIVE, 1.0);
    }
    else
    {
        llSetText(TXT_OFF, <1,0,0>, 1.0);
    }
}

//allows string output of a float in a tidy text format
//rnd (rounding) should be set to TRUE for rounding, FALSE for no rounding
string qsFloat2String ( float num, integer places, integer rnd)
{
    if (rnd)
    {
        float f = llPow( 10.0, places );
        integer i = llRound(llFabs(num) * f);
        string s = "00000" + (string)i; // number of 0s is (value of max places - 1 )
        if(num < 0.0)
            return "-" + (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
        return (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
    }
    if (!places)
        return (string)((integer)num );
    if ( (places = (places - 7 - (places < 1) ) ) & 0x80000000)
        return llGetSubString((string)num, 0, places);
    return (string)num;
}


default
{
    listen(integer c, string nm, key id, string m)
    {
        debug("listen: " +m  +"  status=" +status);
        if (c == FARM_CHANNEL)
        {
            if (active == TRUE)
            {
                list tk = llParseString2List(m, ["|"], []);
                string cmd = llList2String(tk, 0);
                if (llList2String(tk, 1) != PASSWORD) return;
                if (cmd == "SCRIPT_REQ")
                {
                    key senderKey = llList2Key(tk, 2);
                    string scriptToCheck = llToLower(llList2String(tk, 3));
                    integer versionToCheck = llList2Integer(tk, 4);
                    integer index = llListFindList(scripts, [scriptToCheck]);
                    if (index != -1)
                    {
                        if (llList2Integer(versions, index) > versionToCheck)
                        {
                            if (llListFindList(recents, [id]) == -1)
                            {
                                string invScript = llList2String(scripts, index) + llList2String(versions, index);
                                llGiveInventory(id, invScript);
                                llSleep(1.0);
                                messageObj(id, "SCRIPT_GIVEN|" +PASSWORD +"|" + invScript);
                                llSetText("SCRIPT_GIVEN:"+invScript+"\nto:"+(string)id+"\n@"+getTime(), <1,1,1>, 1.0);
                                llPlaySound("fx",1.0);
                                recents += [id, llGetUnixTime()];
                                llSetTimerEvent(300);
                            }
                        }
                    }
                }
            }
            return;
        }
        // DIALOG CHANNEL
        if (m == TXT_CLOSE)
        {
            refresh();
        }
        else if (m == TXT_CHECK)
        {
            //
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if ((m == TXT_START) || (m == TXT_STOP))
        {
            active = !active;
            llSetObjectDesc((string)active);
            refresh();
        }
        else if (status  == "GET")
        {
            //
        }
        checkListen(TRUE);
    }


    on_rez(integer n)
    {
        llResetScript();
    }

    timer()
    {
        checkListen(FALSE);
        refresh();
        llSetTimerEvent(600);
    }

    touch_start(integer n)
    {
        toucher = llDetectedKey(0);
        if (!llSameGroup(toucher))
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
            return;
        }
        status = "";
        list opts = [TXT_CLOSE, TXT_CHECK, TXT_LANGUAGE];
        if (active == TRUE) opts += TXT_STOP; else opts += TXT_START;
        startListen();
        llDialog(toucher, TXT_SELECT, opts, chan(ownKey));
        llSetTimerEvent(300);
    }

    state_entry()
    {
        llSetText("...", PURPLE, 1.0);
        active = (integer)llGetObjectDesc();
        notecardQueryId = llGetNotecardLine("sfp", 0);
        ownKey = llGetKey();
        ownGroup = llList2Key(llGetObjectDetails(ownKey, [OBJECT_GROUP]), 0);
        lastTs = llGetUnixTime();
        loadLanguage(languageCode);
        scripts = [];
        versions = [];
        numScripts = 0;
        string itemName;
        string itemVer;
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (i=0; i < count; i++)
        {
            itemName = llGetInventoryName(INVENTORY_SCRIPT, i);
            if ((itemName != llGetScriptName()) && (itemName != "language_plugin"))
            {
                itemName = llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 6);
                itemVer  = llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 7, -1);
                scripts += itemName;
                versions += (integer)itemVer;
                numScripts ++;
            }
        }
        debug("\n"+llDumpList2String(scripts, ", ") +"\n" +llDumpList2String(versions, ", "));
        refresh();
        llListen(FARM_CHANNEL, "", "", "");
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetObjectDesc("S;" + languageCode);
            refresh();
        }
    }

    dataserver(key k, string m)
    {
        if (k == notecardQueryId)
        {
            PASSWORD = m;
            return;
        }

        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD ) return;

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
            messageObj(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, TXT_ERROR_UPDATE);
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
            messageObj(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }


    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
        if (change & CHANGED_REGION_START)
        {
            llResetScript();
        }
    }

}
