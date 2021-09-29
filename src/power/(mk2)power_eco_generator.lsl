// power_eco_generator.lsl
// Generates and adds energy to the region-wide power controller - can be configured for using wind, sun or water
//
float   VERSION = 5.0;     // 27 November 2020
integer  RSTATE = 1;       // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}
// Notecard settings
string  type = "WATER";          // TYPE=WATER   or WIND or SUN
integer floatText = TRUE;        // FLOAT_TEXT=1    (set to 0 to not show the status float text)
vector  COLOUR = <1,1,1>;        // COLOR=<1.0, 1.0, 1.0>
string  languageCode = "en-GB";  // use defaults below unless language config notecard present

// For multilingual notecard support
string TXT_CHARGE = "Charge";
string TXT_NIGHT = "Nightime";
string TXT_EFFICIENCY = "Power rate";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_DISABLED = "Disabled - Touch to enable";
string TXT_WIND_DIR = "Wind direction";
string TXT_WIND_SPEED = "Wind speed";
string TXT_STOPPED = "Stopped";
string TXT_LANGUAGE = "@";
//
string SUFFIX = "T2";
//
integer energy_channel = -321321;
string PASSWORD = "*";
//
integer updateTime = 60;   // How often in seconds to check conditions
integer period     = 600;  // How often in seconds to update energy
float   fill = 0.0;
integer lastTs = 0;
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
                         if (cmd == "TYPE")         type = val;
                    else if (cmd == "FLOAT_TEXT")   floatText = (integer)val;
                    else if (cmd == "COLOR")        COLOUR = (vector)val;
                    else if (cmd == "LANG")         languageCode = val;
                }
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
                         if (cmd == "TXT_EFFICIENCY")  TXT_EFFICIENCY = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_DISABLED") TXT_DISABLED = val;
                    else if (cmd == "TXT_WIND_DIR") TXT_WIND_DIR = val;
                    else if (cmd == "TXT_WIND_SPEED") TXT_WIND_SPEED = val;
                    else if (cmd == "TXT_CHARGE") TXT_CHARGE = val;
                    else if (cmd == "TXT_NIGHT") TXT_NIGHT = val;
                    else if (cmd == "TXT_STOPPED") TXT_STOPPED = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

vector getWind()
{
    // See http://wiki.secondlife.com/wiki/User:Dora_Gustafson/moderated_world_wind
    vector windVector = llWind( -llGetPos()); // Wind velocity in region at <0,0,0>
    float speed = 5.0*llPow( llVecMag( windVector), .333333); // moderated speed
    windVector = speed*llVecNorm( windVector); // moderated wind velocity
    return windVector;
}

integer checkWater()
{
    integer result;
    vector ground = llGetPos();
    float fGround = ground.z;
    float fWater = llWater(ZERO_VECTOR) + 0.5;
    if ( fGround > fWater ) result = FALSE; else result = TRUE;
    debug("checkWater:Ground="+(string)fGround + " Water="+(string)fWater + " Result="+(string)result);
    return result;
}

refresh()
{
    if (enabled == TRUE)
    {
        integer effi;
        float rate;
        string txtMsg = "";
        if (type == "WIND")
        {
            vector windVector = getWind();
            float windSpeed = llVecMag( windVector);
            float windDirection = llAtan2(windVector.y, windVector.x);
            integer compassWind = (450 - (integer)( RAD_TO_DEG*windDirection))%360;
            rate = llFabs(windVector*(<1.0,0,0>*llGetRot()));
            rate = rate/10.0;
            if (rate >1) rate = 1;
            effi = llRound(rate*100);
            txtMsg = TXT_WIND_DIR+": "+(string)compassWind+"°\n" +TXT_WIND_SPEED +": "+(string)windSpeed+" m/S\n"+ TXT_EFFICIENCY +": " +(string)effi + " %\n";
            if ((llGetUnixTime() - lastTs) > period)
            {
                fill+=rate;
                if (fill>0.7)
                {
                    llRegionSay(energy_channel, "ADDENERGY|"+PASSWORD);
                    fill = 0.0;
                }
                lastTs = llGetUnixTime();
            }
        }
        else if (type == "SUN")
        {
            integer isDay = TRUE;
            rotation ourRot = llGetRot();
            rotation sunRot = ZERO_ROTATION;
            vector sun = llGetSunDirection();
            // If it is day, rotation towards the sun otherwise is night time
            if (sun.z >= 0.0) sunRot = llAxes2Rot(<sun.x, sun.y, 0.0>, <-sun.y, sun.x, 0.0>, <0.0, 0.0, 1.0>); else isDay = FALSE;
            // Work out difference between where the panel points and where the sun is
            float angle = llAngleBetween(ourRot, sunRot);
            if (isDay == FALSE)
            {
                effi = 0;
            }
            else
            {
                effi = 10 - llRound(angle * PI);  // (10 - 0) for perfect, (10 - ~10) for worse case
                effi = 10*effi;
            }
            if (llGetUnixTime()-lastTs > period)
            {
                fill += effi/20;
                lastTs = llGetUnixTime();
            }
            if (fill >8.0)
            {
                llRegionSay(energy_channel, "ADDENERGY|"+PASSWORD);
                fill = 0.0;
            }
            if (isDay == TRUE) txtMsg = TXT_EFFICIENCY +": " +(string)effi +"%\n" +TXT_CHARGE +": " +(string)llRound(fill*10) +"/100"; else txtMsg = TXT_NIGHT;
        }
        else    // assume type == WATER
        {
            if (checkWater() == TRUE)
            {
                effi = 100;
                if ((llGetUnixTime() - lastTs) > period)
                {
                    fill += 0.5;
                    if (fill > 1.0)
                    {
                        llRegionSay(energy_channel, "ADDENERGY|"+PASSWORD);
                        fill = 0.0;
                    }
                    lastTs = llGetUnixTime();
                }
                txtMsg = TXT_CHARGE +": " +(string)llRound(fill*100) +"%";
            }
            else
            {
                llMessageLinked(LINK_SET, 0, "VELOCITY", "");
                txtMsg = TXT_STOPPED;
            }
        }
        llRegionSay(energy_channel, "ENERGYSTATS|"+PASSWORD + "|"+llGetObjectDesc() +"|"+(string)effi);
        llMessageLinked(LINK_SET, effi, "VELOCITY", "");

        if (floatText == TRUE)
        {
            if (RSTATE == 0) txtMsg += "\n-B-"; else if (RSTATE == -1) txtMsg += "\n-RC-";
            llSetText(txtMsg, COLOUR, 1.0);
        }
        else
        {
            if (RSTATE == 0) txtMsg = "-B-"; else if (RSTATE == -1) txtMsg = "-RC-"; else txtMsg = "";
            if (txtMsg == "") llSetText("", ZERO_VECTOR, 0); else llSetText(txtMsg, <0.6,0.6,0.6>, 0.75);
        }
    }
    else
    {
        llMessageLinked(LINK_SET, 0, "VELOCITY", "");
        llSetText(TXT_DISABLED, <1.0, 0.8, 0.2>, 1.0);
    }
}


default
{
    on_rez(integer n)
    {
        llSetObjectDesc("---");
        llSleep(1.0);
        llResetScript();
    }

    state_entry()
    {
        if (llGetObjectDesc() == "---")
        {
            enabled = FALSE;
            llSetText(TXT_DISABLED, <1.0, 0.8, 0.2>, 1.0);
        }
        loadConfig();
        refresh();
        if (enabled == TRUE) llSetTimerEvent(updateTime);
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
        }
    }

    timer()
    {
        refresh();
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
            loadConfig();
            loadLanguage(languageCode);
            refresh();
        }
    }

}
