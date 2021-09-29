// power_water_pump.lsl
//  Electrical water pump - supplies water to powered water towers on request if enough energy in grid

float VERSION = 5.0;      // 27 November 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

integer showText = 1;               // SHOW_TXT=1
string  languageCode = "en-GB";     // LANG=en-GB
// For multilingual notecard support
string TXT_IDLE="ONLINE";
string TXT_RUNNING="Running";
string TXT_STOPPED="Stopped";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
//
string  SUFFIX = "W1";
//
integer energy_channel = -321321;
string  PASSWORD = "*";
string  status;
key     requester;
key     myGroup;

vector GREEN  = <0.0, 0.9, 0.2>;
vector YELLOW = <1.000, 0.863, 0.000>;
vector RED =    <1.000, 0.255, 0.212>;
vector BLUE   = <0.00, 0.50, 1.00>;

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

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
                         if (cmd == "SHOW_TXT") showText = (integer)val;
                    else if (cmd == "LANG")     languageCode = val;
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
                         if (cmd == "TXT_IDLE")  TXT_IDLE = val;
                    else if (cmd == "TXT_RUNNING") TXT_RUNNING = val;
                    else if (cmd == "TXT_STOPPED") TXT_STOPPED = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                }
            }
        }
    }
}

psys(key k)
{
    integer flags = 0;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    flags = flags | PSYS_PART_TARGET_POS_MASK;

    llLinkParticleSystem(getLinkNum("outlet"),
     [
            PSYS_PART_MAX_AGE, 2.4,
            PSYS_PART_FLAGS, flags,
            PSYS_PART_START_COLOR, <0.8, 0.8, 0.8>,
            PSYS_PART_END_COLOR, <0.9, 0.9, 1.0>,
            PSYS_PART_START_SCALE, <0.1, 0.1, 1>,
            PSYS_PART_END_SCALE, <0.25, 0.25 ,1>,
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
            PSYS_SRC_BURST_RATE, 0.1,
            PSYS_SRC_ACCEL, <0.0,0.0,-5.0>,
            PSYS_SRC_BURST_PART_COUNT, 20,
            PSYS_SRC_BURST_RADIUS, 0.25,
            PSYS_SRC_BURST_SPEED_MIN, 10.0,
            PSYS_SRC_BURST_SPEED_MAX, 20.0,
            PSYS_SRC_TARGET_KEY, k,
            PSYS_SRC_INNERANGLE, 0.5,
            PSYS_SRC_OUTERANGLE, 4*PI,
            PSYS_SRC_OMEGA, <0,0,0>,
            PSYS_SRC_MAX_AGE, 40.0,
            PSYS_SRC_TEXTURE, "img",
            PSYS_PART_START_ALPHA, 1.0,
            PSYS_PART_END_ALPHA, 0.8
                        ]);
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

integer checkAllowed(key keyCheck)
{
    key theirGroup = llList2Key(llGetObjectDetails(keyCheck, [OBJECT_GROUP]), 0);
    if (theirGroup == myGroup) return TRUE; else return FALSE;
}

refresh(string msg, vector floatColour)
{
    if (showText == TRUE) llSetText(msg, floatColour, 1.0);
    status = "";
    requester = NULL_KEY;
    llSetTimerEvent(0);
}

string fixedPrecision(float input, integer precision)
{
    precision = precision - 7 - (precision < 1);
    if(precision < 0)
        return llGetSubString((string)input, 0, precision);
    return (string)input;
}

string neatVector(vector input)
{
    string output = "<";
    output += fixedPrecision(input.x, 2) +", ";
    output += fixedPrecision(input.y, 2) +", ";
    output += fixedPrecision(input.z, 2) +">";
    return output;
}

default
{

    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        llLinkParticleSystem(getLinkNum("outlet"),[]);
        llStopSound();
        llSetText("", ZERO_VECTOR, 0);
        llMessageLinked(LINK_SET, 0, "OFF", "");
        myGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0);
        loadConfig();
        loadLanguage(languageCode);
        if (showText == TRUE) llSetText(TXT_STOPPED,BLUE, 1.0);
        llMessageLinked(LINK_SET, -1, "", "");
        llListen(energy_channel, "", "", "");
        status = "";
    }

    listen(integer channel, string name, key id, string message)
    {
        // Mke sure we are still in same group as we started out in
        if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == myGroup)
        {
            if (channel == energy_channel)
            {
                // Only supply water to consumers in same group as us
                if (checkAllowed(id) == TRUE)
                {
                    debug("listen:"+message);
                    list tk = llParseStringKeepNulls(message, ["|"] , []);
                    string cmd = llList2String(tk,0);
                    if (cmd == "STARTPUMP") // Request for water so see if there is enough energy to start pump
                    {
                        if (showText == TRUE) llSetText(TXT_IDLE,BLUE, 1.0);
                        llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
                        requester = id;
                        status = "waitEnergyRequest";
                        llSetTimerEvent(60);
                    }
                }
            }
        }
        else
        {
            llResetScript();
        }
    }

    dataserver(key kk, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        string cmd = llList2String(tk,0);
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
            messageObj(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        else
        {
            if (llList2String(tk,1) != PASSWORD ) return;
            cmd = llList2String(tk,0);
            if (cmd == "HAVEENERGY")
            {
                // okay to start pump and send some water
                llLoopSound("pump", 1.0);
                llMessageLinked(LINK_SET, 1, "ON", "");
                psys(requester);
                messageObj(requester,  "PUMPOK|"+PASSWORD);
                refresh(TXT_RUNNING+ "\n ... \n" +llKey2Name(requester)+" @ "+neatVector(llList2Vector(llGetObjectDetails(kk, [OBJECT_POS]),0)) ,YELLOW);
                llSetTimerEvent(120);
            }
            else if (cmd == "NOENERGY")
            {
                status = "stopped";
                llSetTimerEvent(1);
                if (showText == TRUE) llSetText(TXT_STOPPED, RED, 1.0);
                llMessageLinked(LINK_SET, 1, "STALL", "");
           }
        }
    }

    timer()
    {
        if (status != "")
        {
            // no energy for pump
            messageObj(requester, "PUMPSTOPED|"+PASSWORD);
            refresh(TXT_STOPPED, RED);
            llMessageLinked(LINK_SET, 1, "STALL", "");
        }
        else
        {
            if (showText == TRUE) llSetText(TXT_IDLE, GREEN, 1.0);
        }
        llParticleSystem([]);
        llStopSound();
        llMessageLinked(LINK_SET, 0, "OFF", "");
    }

    touch_end(integer index)
    {
        llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, llDetectedKey(0));
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message:" +m);
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            refresh(TXT_IDLE, GREEN);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
