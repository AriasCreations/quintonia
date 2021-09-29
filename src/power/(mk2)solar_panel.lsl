// solar_panel.lsl
// A sun power device that generates and adds energy to the region-wide power controller.
//
float VERSION = 2.0;     // RC-1 22 September 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}
// Notecard settings
integer floatText = TRUE;        // FLOAT_TEXT=1    (set to 0 to not show the status float text)
vector  COLOUR = <1,1,1>;        // COLOR=<1.0, 1.0, 1.0>
string  accessKey = "";          // KEY=        Value used if connecting to a restricted access controller
string  languageCode = "en-GB";  // LANG=en-GB
//
// For multilingual notecard support
string TXT_EFFICIENCY = "Power rate";
string TXT_CHARGE = "Charge";
string TXT_NIGHT = "Nightime";
string TXT_DISABLED = "Disabled - Touch to enable";
string TXT_LANGUAGE="@";
string TXT_ERROR_UPDATE ="Error: unable to update - you are not my Owner";
//
integer updateTime = 30;   // How often in seconds to check sun intensity
integer period     = 600;  // How often in seconds to update energy
string SUFFIX = "S3";
string PASSWORD = "*";
integer lastTs=0;
float fill=0.0;
float rate;
integer energy_channel = -321321;
integer enabled = TRUE;


loadConfig()
{
    //sfp notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
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
                         if (cmd == "FLOAT_TEXT") floatText = (integer)val;
                    else if (cmd == "COLOR") COLOUR = (vector)val;
                    else if (cmd == "KEY") accessKey = val;
                    else if (cmd == "LANG") languageCode = val;
                }
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" +SUFFIX;
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
                         if (cmd == "TXT_EFFICIENCY")  TXT_EFFICIENCY = val;
                    else if (cmd == "TXT_CHARGE") TXT_CHARGE = val;
                    else if (cmd == "TXT_NIGHT") TXT_NIGHT = val;
                    else if (cmd == "TXT_DISABLED") TXT_DISABLED = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE =val;
                }
            }
        }
    }
}

refresh()
{
    if (enabled == TRUE)
    {
        integer isDay = TRUE;
        rotation ourRot = llGetRot();
        rotation sunRot = ZERO_ROTATION;
        vector sun = llGetSunDirection();
        // If it is day, rotation towards the sun otherwise is night time
        if (sun.z >= 0.0) sunRot = llAxes2Rot(<sun.x, sun.y, 0.0>, <-sun.y, sun.x, 0.0>, <0.0, 0.0, 1.0>); else isDay = FALSE;
        // Work out difference between where the panel points and where the sun is
        float angle = llAngleBetween(ourRot, sunRot);
        integer effi;
        if (isDay == FALSE)
        {
            effi = 0;
        }
        else
        {
            effi = 10 - llRound(angle * PI);  // 0 for perfect, approx 10 for worse case
            effi = 10*effi;
        }
        if (llGetUnixTime()-lastTs > period)
        {
            fill += effi/20;
            lastTs = llGetUnixTime();
        }
        if (fill >8.0)
        {
            if (accessKey == "") llRegionSay(energy_channel, "ADDENERGY|"+PASSWORD); else llRegionSay(energy_channel, accessKey+"|ADDENERGY|"+PASSWORD);
            fill = 0.0;
        }

        if (floatText == TRUE)
        {
            if (isDay == TRUE)
            {
                llSetText(TXT_EFFICIENCY +": " +(string)effi +"%\n" +TXT_CHARGE +": " +(string)llRound(fill*10) +"/100", COLOUR, 1.0);
            }
            else
            {
                llSetText(TXT_NIGHT, COLOUR, 1.0);
            }
        }
        if (accessKey == "") llRegionSay(energy_channel, "ENERGYSTATS|"+PASSWORD + "|"+llGetObjectDesc() +"|"+(string)effi);
           else llRegionSay(energy_channel, accessKey+"|ENERGYSTATS|"+PASSWORD + "|"+llGetObjectDesc() +"|"+(string)effi);
        llMessageLinked(LINK_SET, effi, "VELOCITY", "");
    }
    else
    {
        llSetText(TXT_DISABLED, <1.0, 0.8, 0.2>, 1.0);
    }
}


default
{
    on_rez(integer n)
    {
        enabled = FALSE;
        refresh();
    }

    state_entry()
    {
        if (llGetObjectDesc() == "---") enabled = FALSE;
        refresh();
        if (enabled == TRUE) llSetTimerEvent(updateTime);
    }

    timer()
    {
        refresh();
    }

    touch_end(integer index)
    {
        if (enabled == TRUE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, llDetectedKey(0));
        }
        else
        {
            enabled = TRUE;
            loadConfig();
            loadLanguage(languageCode);
            llMessageLinked(LINK_SET, 0, "", "");
            if ((llGetObjectDesc() == "") || (llGetObjectDesc() == "---")) llSetObjectDesc(llGetSubString((string)llGetKey(),0,9));
            lastTs = llGetUnixTime();
            refresh();
            llSetTimerEvent(updateTime);
            refresh();
        }
    }

    dataserver(key kk  , string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk, 1) != PASSWORD) return;
        string cmd = llList2String(tk, 0);
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
            if (llGetOwnerKey(kk) != llGetOwner())
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
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        refresh();
    }

    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            refresh();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

}
