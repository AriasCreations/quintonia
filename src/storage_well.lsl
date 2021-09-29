// storage_well.lsl
// Universal storage tower/well  for liquid e.g. water to give to items set as 'auto water'
// Works with wind pump, electric pump or self contained pump

float   VERSION = 5.1;   // 27 November 2020
integer RSTATE  = 1;     // RSTATE = 1 for release, 0 for beta, -1 for RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overiden by config notecard
float   level = 100.0;                   // INITIAL_LEVEL=100
integer singleLevel = 2;                 // ONE_PART=2
vector  rezzPosition = <0.0, 0.0, 0.0>;  // REZ_POSITION=
string  LIQUID = "Water";                // LIQUID=Water
integer acceptProduct = TRUE;            // ACCEPT_PRODUCT=1
float   dropTime = 86400.0;              // DROP_TIME=1                 rate for evaporation in days
integer WATERTIME = 600;                 // WATERTIME=600               How often in seconds to increase level by ONE_PART if MODE=SELF
integer menuMode = 1;                    // MENU_MODE=1                 set to 0 to disable menu and just rez product on touch)
string  mode = "WIND";                   // MODE=WIND                   mode for getting top up. WIND to use wind pumps, GRID to use electricity, RELAY to find nearby source, SELF to use built in system
string  relayWell ="SF Water Tower";     // RELAY_WELL=SF Water tower   in RELAY mode, where to get water from
integer doWeather = 0;                   // WEATHER=0                   set to 1 to have clouds and rain
integer rainRadius = 35;                 // RAIN_RADIUS=35              maximum ~ 50
string  REQUIRES = "";                   // REQUIRES=WATER_LEVEL        WATER_LEVEL forces it to be at water level to work.  Can also specify item to scan for
integer range = 6;                       // RANGE=6                     radius to scan for REQUIRES item
string  languageCode = "en-GB";          // LANG=en-GB
//
// For multi-lingual support
string TXT_LEVEL="Level";
string TXT_ASK_PUMP="Requesting pump start...";
string TXT_ADD="Add";
string TXT_GET="Get";
string TXT_CHECKING = "Checking storage locations...";
string TXT_CLOSE="CLOSE";
string TXT_SELECT="Select";
string TXT_FOUND="Found";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_NOT_FOUND="Nothing found, please bring it closer";
string TXT_ERROR_GROUP="Error: not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_NO_WATER = "Empty";
string TXT_NO_PUMP = "Pump not available";
string TXT_NOT_ENOUGH = "Sorry, there is not enough";
string TXT_SEA_LEVEL = "Sea level";
string TXT_NEEDS = "Needs";
string TXT_LANGUAGE="@";
//
string SUFFIX = "W2";
//
integer energy_channel = -321321;
string  PASSWORD = "*";
string  SF_PRODUCT = "SF Water";
//
vector  NOWATER =  <0.634, 0.241, 0.241>;
vector  WATER = <0.000, 1.000, 1.000>;
key     toucher;
integer request;
string  status = "";
string  weatherStatus = "";
integer weatherLevel;
integer lastWater = 0;
integer lastTs;
integer dropTs;
integer listener=-1;
integer listenTs;
integer maxTries = 5;
integer active = TRUE;
integer wdb = 0;
string lookingFor;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

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
                         if (cmd == "REZ_POSITION")     rezzPosition = (vector)val;
                    else if (cmd == "INITIAL_LEVEL")    level = (float)val;
                    else if (cmd == "DROP_TIME")        dropTime = (float)val * 86400.0;
                    else if (cmd == "ONE_PART")         singleLevel = (integer)val;
                    else if (cmd == "LIQUID")         LIQUID = val;
                    else if (cmd == "ACCEPT_PRODUCT")   acceptProduct = (integer)val;
                    else if (cmd == "MENU_MODE")        menuMode = (integer)val;
                    else if (cmd == "MODE")             mode = val;
                    else if (cmd == "RELAY_WELL")       relayWell = val;
                    else if (cmd == "WEATHER")          doWeather = (integer)val;
                    else if (cmd == "RAIN_RADIUS")      rainRadius = (integer)val;
                    else if (cmd == "REQUIRES")
                    {
                        if (val == "SEA_LEVEL") REQUIRES = TXT_SEA_LEVEL; else REQUIRES = val;
                    }
                    else if (val == "RANGE") range = (integer)val;
                    else if (cmd == "LANG") languageCode = val;
                }
            }
        }
    }
    debug("mode="+mode);
    if ((mode != "WIND") && (mode != "GRID") && (mode !="SELF") && (mode !="RELAY")) mode = "WIND";
    if (relayWell == "") relayWell = "SF Water Tower";
    SF_PRODUCT = "SF " + LIQUID;
    loadStateFromDesc();
    debug("mode="+mode);
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
                         if (cmd == "TXT_LEVEL")  TXT_LEVEL = val;
                    else if (cmd == "TXT_ASK_PUMP") TXT_ASK_PUMP = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_GET") TXT_GET = val;
                    else if (cmd == "TXT_CHECKING") TXT_CHECKING = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT= val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_SEA_LEVEL") TXT_SEA_LEVEL = val;
                    else if (cmd == "TXT_NEEDS") TXT_NEEDS = val;
                    else if (cmd == "TXT_NO_WATER") TXT_NO_WATER = val;
                    else if (cmd == "TXT_NO_PUMP") TXT_NO_PUMP = val;
                    else if (cmd == "TXT_NOT_ENOUGH") TXT_NOT_ENOUGH = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

saveStateToDesc()
{
    llSetObjectDesc((string)llRound(level) +";" +languageCode);
}

loadStateFromDesc()
{
    list settings = llParseString2List(llGetObjectDesc(), [";"], []);
    if (llGetListLength(settings) != 0)
    {
        level = llList2Float(settings, 0);
        languageCode = llList2String(settings, 1);
    }
    else
    {
        saveStateToDesc();
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

psys(key k)
{
    if (weatherStatus != "rainStart")
    {
        llParticleSystem(
                    [
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_SRC_BURST_RADIUS,1,
                        PSYS_SRC_ANGLE_BEGIN,0,
                        PSYS_SRC_ANGLE_END,0.5,
                        PSYS_SRC_TARGET_KEY, (key) k,
                        PSYS_PART_START_COLOR,<.7000000,.700000,1.00000>,
                        PSYS_PART_END_COLOR,<7.000000,.800000,1.00000>,

                        PSYS_PART_START_ALPHA,.5,
                        PSYS_PART_END_ALPHA,0,
                        PSYS_PART_START_GLOW,0,
                        PSYS_PART_END_GLOW,0,
                        PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                        PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                        PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                        PSYS_PART_END_SCALE,<1.9000000,1.9000000,0.000000>,
                        PSYS_SRC_TEXTURE,"",
                        PSYS_SRC_MAX_AGE,2,
                        PSYS_PART_MAX_AGE,5,
                        PSYS_SRC_BURST_RATE, .01,
                        PSYS_SRC_BURST_PART_COUNT, 1,
                        PSYS_SRC_ACCEL,<0.000000,0.000000,0.9000000>,
                        PSYS_SRC_OMEGA,<0.000000,0.000000,5.000000>,
                        PSYS_SRC_BURST_SPEED_MIN, 1.1,
                        PSYS_SRC_BURST_SPEED_MAX, 2.,
                        PSYS_PART_FLAGS,
                            0 |
                            PSYS_PART_EMISSIVE_MASK |
                            PSYS_PART_TARGET_POS_MASK|
                            PSYS_PART_INTERP_COLOR_MASK |
                            PSYS_PART_INTERP_SCALE_MASK
                    ]);
    }
}

makeRain(integer radius)
{
    debug("makeRain:"+(string)radius+"m");
    llMessageLinked(LINK_SET, radius, "START_RAIN", "");
}

refresh()
{
    if (REQUIRES == TXT_SEA_LEVEL)
    {
        if (checkWater() == FALSE) active = FALSE;
    }

    if (active == FALSE)
    {
        errorText();
    }
    else
    {
        // Decrease the level for the effects of 'evaporation'
        if (llGetUnixTime() - dropTs > dropTime)
        {
            level -= singleLevel;
            dropTs = llGetUnixTime();
        }
        llParticleSystem([]);
        //
        // If on the power grid and level is low, request some more
        if (mode == "GRID")
        {
            if ((level < 40) && (request == FALSE))  // Don't put in multiple requests
            {
                maxTries -= 1;
                if (maxTries >0)
                {
                    // level getting low so request some more from the region pumping system
                    llRegionSay(energy_channel, "STARTPUMP|"+PASSWORD);
                    llSetText(TXT_ASK_PUMP, <0.000, 0.455, 0.851>, 1.0);
                    request = TRUE;
                    llSetTimerEvent(10.0);
                }
                else
                {
                    maxTries = 5;
                    llSetTimerEvent(300.0);
                    llSetText("-!-", <0.9, 0.0, 0.1>, 1.0);
                }
            }
        }
        else if (mode == "SELF")
        {
            if (llGetUnixTime() - lastTs >  WATERTIME)
            {
                level += singleLevel;
                if (level >100) level = 100;
                lastTs = llGetUnixTime();
            }
        }
        else if (mode == "RELAY")
        {
            if (level < 10)
            {
                debug("doing wellSearch for "+relayWell);
                status = "wellSearch";
                lookingFor = relayWell;
                llSensor(relayWell, "", SCRIPTED, 96, PI);
            }
        }
        // Adjust the weather
        if (doWeather == TRUE)
        {
            weatherLevel = llRound(llFrand(3.0));
            if (weatherLevel != 0) llMessageLinked(LINK_SET, weatherLevel, "START_CLOUDS", NULL_KEY);
        }
        string str = "";
        // Set float text
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        if ((DEBUGMODE==TRUE) && (doWeather == TRUE))str += "\nWeather:"+(string)weatherLevel;
        llSetText(LIQUID+"\n"+TXT_LEVEL+": "+(string)(llRound(level))+"%\n "+str , <1,1,1>, 1.0);
    }

    // Set position of level prims
    vector v;
    string data;
    list limits;
    float waterMinZ;
    float waterMaxZ;
    integer linkNum = getLinkNum("water_1");
    if (linkNum != -1)
    {
        data = llList2String(llGetLinkPrimitiveParams(linkNum, [PRIM_DESC]), 0);
        limits = llParseString2List(data, [","], []);
        waterMinZ = llList2Float(limits, 0);
        waterMaxZ = llList2Float(limits, 1);
        v = llList2Vector(llGetLinkPrimitiveParams(linkNum, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* level/100.0;
        llSetLinkPrimitiveParamsFast(linkNum, [PRIM_POS_LOCAL, v]);
    }
    linkNum = getLinkNum("water_2");
    if (linkNum != -1)
    {
        data = llList2String(llGetLinkPrimitiveParams(linkNum, [PRIM_DESC]), 0);
        limits = llParseString2List(data, [","], []);
        waterMinZ = llList2Float(limits, 0);
        waterMaxZ = llList2Float(limits, 1);
        v = llList2Vector(llGetLinkPrimitiveParams(linkNum, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* level/100.0;
        llSetLinkPrimitiveParamsFast(linkNum, [PRIM_POS_LOCAL, v]);
    }
    saveStateToDesc();
    if (level < 2) llSetText(TXT_NO_WATER, NOWATER, 1);
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

errorText()
{
    llSetText(TXT_NEEDS + ": " +REQUIRES, <1, 0, 0>, 1.0);
    lastTs = llGetUnixTime();
}

default
{
    listen(integer c, string nm, key id, string m)
    {
        if (m == TXT_ADD+" "+LIQUID)
        {
            status = "WaitWater";
            lookingFor = SF_PRODUCT;
            llSensor(SF_PRODUCT, "",SCRIPTED,  10, PI);
        }
        else if (m == TXT_GET+" "+LIQUID)
        {
            if (level>0)
            {
                level -= singleLevel;
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)toucher +"|" +SF_PRODUCT, NULL_KEY);
                if (level<0) level =0;
                refresh();
            }
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (m == "DEBUG")
        {
            if (wdb == TRUE) llMessageLinked(LINK_SET, 0, "DEBUG", ""); else llMessageLinked(LINK_SET, 1, "DEBUG", "");
            wdb = !(wdb);
        }
    }

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|"+PASSWORD);
    }

    dataserver(key k, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk,0);

        if ((cmd == "WATER") || (cmd == "HAVEWATER"))  // add water from bucket/storage-well
        {
            lastWater = llGetUnixTime();
            level += singleLevel;
            if (level > 100) level = 100;
            psys(NULL_KEY);
            refresh();
        }
        else if (cmd == "GIVEWATER")    // send water out
        {
            if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == llList2Key(llGetObjectDetails(llList2Key(tk, 2), [OBJECT_GROUP]), 0))
            {
                if (level>0)
                {
                    level -= singleLevel;
                    messageObj( llList2Key(tk, 2),  "HAVEWATER|"+PASSWORD);
                    if (level<0) level =0;
                    refresh();
                    psys(llList2Key(tk, 2));
                    if (doWeather == TRUE)
                    {
                        llSleep(1.0);
                        llMessageLinked(LINK_SET, 4, "STARTCLOUDS", NULL_KEY);
                        weatherStatus = "rainStart";
                        llSetTimerEvent(0.1);
                    }
                }
            }
            else
            {
                key requester = llList2String(tk, 2);
                vector location = llList2Vector(llGetObjectDetails(llList2Key(tk, 2), [OBJECT_POS]),0);
                llRegionSayTo(llGetOwner(), 0, TXT_ERROR_GROUP +" : " +llKey2Name(requester) + " @ " +  (string)location);
            }
        }
        //for updates
        else if (cmd == "VERSION-CHECK")
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
            refresh();
        }
        else
        {
            if (llList2String(tk,1) != PASSWORD ) return;
            cmd = llList2String(tk,0);
            if (cmd == "PUMPOK")          // add from region pump
            {
                llSetColor(WATER, 1);
                llSetText("+", <0.000, 0.9, 0.2>, 1.0);
                lastWater = llGetUnixTime();
                level += 25;
                if (level > 100) level = 100;
                llSleep(2);
                request = FALSE;
                llSetTimerEvent(42);
                status = "filling";
            }
            else if (cmd == "PUMPSTOPED")  // not enough energy for pump
            {
                llSetText(TXT_NO_PUMP, NOWATER, 1);
                llMessageLinked(LINK_SET, 0, "STARTCLOUDS", NULL_KEY);
                llSetTimerEvent(180);      // Wait a while before trying again;
            }
        }
    }

    timer()
    {
        debug("timer:status="+status +"  weatherStatus="+weatherStatus);

        if (weatherStatus == "raining")
        {
            weatherStatus = "";
            llMessageLinked(LINK_THIS, 0, "END_CLOUDS", "");
            llSetTimerEvent(WATERTIME);
        }
        else if (weatherStatus == "rainStart")
        {
            weatherStatus = "raining";
            makeRain(rainRadius);
            llSetTimerEvent(WATERTIME);
        }
        else if (request == TRUE)
        {
            request = FALSE;
            llSetTimerEvent(120);
            refresh();
        }
        else if (status == "filling")
        {
            status = "";
            refresh();
        }
        else if (status == "checkItem")
        {
            lookingFor = REQUIRES;
            llSensor(REQUIRES, NULL_KEY, ( AGENT | PASSIVE | ACTIVE ), range, PI);
        }
        else
        {
            checkListen();
            refresh();
            llSetTimerEvent(WATERTIME);
        }
    }

    touch_start(integer n)
    {
        toucher = llDetectedKey(0);
        if (active == TRUE)
        {
            if (llSameGroup(toucher) || osIsNpc(toucher))
            {
                if (menuMode == TRUE)
                {
                    startListen();
                    list opts = [];
                    if (DEBUGMODE == TRUE) opts += "DEBUG";
                    if ((level < 100) && (acceptProduct == TRUE)) opts += TXT_ADD+" "+LIQUID;
                    if (level > 0) opts += TXT_GET+" "+LIQUID;
                    opts += [TXT_LANGUAGE, TXT_CLOSE];
                    llDialog(toucher, TXT_SELECT, opts, chan(llGetKey()));
                    llSetTimerEvent(300);
                }
                else
                {
                    if (active == TRUE)
                    {
                        if (level < singleLevel)
                        {
                            llRegionSayTo(toucher, 0, TXT_NOT_ENOUGH +" " +LIQUID);
                        }
                        else
                        {
                            level -= singleLevel;
                            if (level < 0) level = 0;
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
            }
            else
            {
                llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
            }
        }
        else
        {
            llRegionSayTo(toucher, 0, TXT_NOT_ENOUGH +" " +LIQUID);
            status = "checkItem";
            llSetTimerEvent(0.1);
        }
    }

    sensor(integer index)
    {
        debug("sensor:status="+status +" lookingFor:"+lookingFor);
        if (status == "WaitWater")
        {
            key id = llDetectedKey(0);
            llRegionSayTo(toucher, 0, TXT_FOUND+": "+LIQUID);
            messageObj(id, "DIE|"+(string)llGetKey());
        }
        else if (status == "wellSearch")
        {
            status = "";
            key id = llDetectedKey(0);
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
        }
        else
        {
            debug("sensor ok for: "+REQUIRES);
            active = TRUE;
        }
    }

    no_sensor()
    {
        debug("n0_sensor:status="+status +" lookingFor:"+lookingFor);
        if (status == "WaitWater")
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_NOT_FOUND);
        }
        else if (status == "wellSearch")
        {
            llRegionSayTo(llGetOwner(), 0, relayWell+": "+TXT_ERROR_NOT_FOUND);
        }
        else
        {
            debug("no_sensor for: "+REQUIRES);
            active = FALSE;
            errorText();
        }
    }

    state_entry()
    {
        status = "";
        loadConfig();
        loadLanguage(languageCode);
        llMessageLinked(LINK_THIS, 1, "RESET|"+PASSWORD, NULL_KEY);
        if (llGetInventoryType(SF_PRODUCT) != INVENTORY_OBJECT)
        {
            active = FALSE;
            llOwnerSay(TXT_CHECKING);
            llSetText(TXT_CHECKING+"\n"+ SF_PRODUCT, NOWATER, 1.0);
            llMessageLinked(LINK_SET, 0, "GET_PRODUCT|" +PASSWORD +"|" +SF_PRODUCT, NULL_KEY);
        }
        else
        {
            lastTs = lastWater = dropTs = llGetUnixTime();
            request = FALSE;
            if (REQUIRES == TXT_SEA_LEVEL)
            {
                if (checkWater() == FALSE)
                {
                    errorText();
                }
                else
                {
                    llSetText("", ZERO_VECTOR, 0.0);
                }
            }
            else if (REQUIRES != "")
            {
                status = "checkItem";
                llSetTimerEvent(1);
            }
            else
            {
                llSetText("", ZERO_VECTOR, 0);
                llSetTimerEvent(1);
            }
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    link_message(integer sender, integer val, string m, key id)
    {
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh();
        }
        else if (cmd == "PRODUCT_FOUND")
        {
            llResetScript();
        }
        else if (cmd == "NO_PRODUCT")
        {
            llSetText(TXT_NEEDS+ ": " +SF_PRODUCT, NOWATER, 1.0);
            llSetTimerEvent(0);
        }
    }

}
