// well.lsl
// Produces a liquid, constantly topping up over time
// Part of the  SatyrFarm scripts.  This code is released under the CC-BY-NC-SA license

float VERSION = 4.1;      // BETA 11 October 2020

integer DEBUGMODE = TRUE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Default values, can be changed via config notecard
float  waterMinZ;               // WATER_ZMIN=  prim Z position
float  waterMaxZ;               // WATER_ZMAX
vector rezzPosition = <1,0,0>;  // REZ_POSITION=<1.0, 1.0, 1.0>
string LIQUID = "Water";        // LIQUID=Water
integer fill = 10;              // INITIAL_LEVEL=10         What level should we start at when rezzed
integer singleLevel = 10;       // ONE_PART=10
integer WATERTIME = 600;        // WATERTIME=600            How often in seconds to increase level by 10%
string REQUIRES = "";           // REQUIRES=WATER_LEVEL     WATER_LEVEL forces it to be at water level to work.  Can also specify item to scan for
integer range = 6;              // RANGE=6                  Radius to scan for REQUIRES item

string languageCode = "en-GB";  // LANG=en-GB

// For multi-lingual support
string TXT_LEVEL = "level";
string TXT_NOT_ENOUGH = "Sorry, there is not enough";
string TXT_NEEDS = "Needs";
string TXT_WATER_LEVEL = "Sea level";
string TXT_ERROR_GROUP = "Error, we are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_BAD_PASSWORD = "Bad password";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "W3";

integer lastTs = 0;
string  PASSWORD = "*";
integer active = TRUE;
string  status = "";

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
             if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
        else if (cmd == "LIQUID") LIQUID = val;
        else if (cmd == "WATER_ZMIN") waterMinZ = (float)val;
        else if (cmd == "WATER_ZMAX") waterMaxZ = (float)val;
        else if (cmd == "INITIAL_LEVEL") fill = (integer)val;
        else if (cmd == "WATERTIME") WATERTIME = (integer)val;
        else if (cmd == "REQUIRES")
        {
            if (val == "WATER_LEVEL") REQUIRES = TXT_WATER_LEVEL; else REQUIRES = val;
        }
        else if (val == "RANGE") range = (integer)val;
        else if (cmd == "LANG") languageCode = val;
    }
}

loadConfig()
{
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
    debug("REQUIRES="+REQUIRES);
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
                         if (cmd == "TXT_LEVEL")     TXT_LEVEL = val;
                    else if (cmd == "TXT_NOT_ENOUGH")  TXT_NOT_ENOUGH = val;
                    else if (cmd == "TXT_NEEDS") TXT_NEEDS = val;
                    else if (cmd == "TXT_WATER_LEVEL") TXT_WATER_LEVEL = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_LANGUAGE")  TXT_LANGUAGE = val;
                }
            }
        }
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

integer checkWater()
{
    integer result;
    vector ground = llGetPos();
    float fGround = ground.z;
    fGround = fGround - 0.75;
    float fWater = llWater(ZERO_VECTOR);
    if ( fGround > fWater ) result = FALSE; else result = TRUE;
    debug("checkWater:Ground="+(string)fGround + " Water="+(string)fWater + " Result="+(string)result);
    return result;
}

statusText()
{
    llSetText(LIQUID +" " +TXT_LEVEL +": " + (string)fill+ "%\n", <1,1,1>, 1.0);
}

errorText()
{
    llSetText(TXT_NEEDS + ": " +REQUIRES, <1, 0, 0>, 1.0);
    lastTs = llGetUnixTime();
}

refresh()
{
    if (llGetUnixTime() - lastTs >  WATERTIME)
    {
        if ((REQUIRES == TXT_WATER_LEVEL) && (checkWater() == FALSE))
        {
            errorText();
        }
        else if (active == FALSE)
        {
            errorText();
        }
        else
        {
            fill += singleLevel;
            if (fill >100) fill = 100;
            lastTs = llGetUnixTime();
        }
    }
    statusText();
    vector v;
    integer ln = getLinkNum("Water");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* fill/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }
}


default
{
    on_rez(integer n)
    {
       llResetScript();
    }

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        lastTs = llGetUnixTime();
        if (REQUIRES == TXT_WATER_LEVEL)
        {
             if (checkWater() == FALSE) errorText(); else llSetText("", ZERO_VECTOR, 0);
        }
        else if (REQUIRES != "")
        {
            status = "checkItem";
        }
        else
        {
            llSetText("", ZERO_VECTOR, 0);
        }
        llSetTimerEvent(1);
    }

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|"+PASSWORD);
        statusText();
    }

    touch_start(integer n)
    {
        key toucher = llDetectedKey(0);
        if (llSameGroup(toucher) || osIsNpc(toucher))
        {
            if (active == TRUE)
            {
                if (fill < singleLevel)
                {
                    llRegionSayTo(toucher, 0, TXT_NOT_ENOUGH +" " +LIQUID);
                }
                else
                {
                    fill -= singleLevel;
                    if (fill < 0) fill = 0;
                    llMessageLinked(LINK_SET, 1, "REZ_PRODUCT|" +PASSWORD +"|" +(string)toucher +"|" +llGetInventoryName(INVENTORY_OBJECT,0), NULL_KEY);
                    refresh();
                }
            }
            else
            {
                llRegionSayTo(toucher, 0, TXT_NOT_ENOUGH +" " +LIQUID);
                status = "checkItem";
                llSetTimerEvent(0.1);
            }
        }
        else llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
    }

    timer()
    {
        llSetTimerEvent(WATERTIME);
        if (status == "checkItem")
        {
            llSensor(REQUIRES, NULL_KEY, ( AGENT | PASSIVE | ACTIVE ), range, PI);
        }
        else
        {
            refresh();
        }
        status = "";
    }

    sensor(integer index)
    {
        debug("sensor ok for: "+REQUIRES);
        active = TRUE;
        statusText();
        refresh();
    }

    no_sensor()
    {
        debug("no_sensor for: "+REQUIRES);
        active = FALSE;
        errorText();
        refresh();
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
            refresh();
        }
    }

    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD ) { llOwnerSay(TXT_BAD_PASSWORD); return; }
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
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
