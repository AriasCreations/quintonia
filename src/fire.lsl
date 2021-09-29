// CHANGE LOG
//  Can now specifiy multiple fuel types e.g SF Wood, SF Coal
//  Added TXT_COLOR as option in config notecard
//  Added SENSOR_DISTANCE as option in config notecard
//  Renamed script from firepit.lsl to fire.lsl

// fire.lsl
//  Fire that uses SF Wood or other fuel
//

float  VERSION = 4.2;   // BETA   29 October 2020
integer RSTATE = 0;     // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overidden by config notecard
list    fuelTypes = ["Wood", "Coal"];         //  FUELS=Wood;Coal
vector  TXT_COLOR = <1.0, 1.0, 1.0>;          //  TXT_COLOR=<1,1,1>     Can set to OFF to not use float text
integer isMade = FALSE;                       //  MANUFACTURED=0        If TRUE, item must be rezzed via kitchen.lsl script in order to work e.g. candles
integer EXPIRES = -1;                         //  EXPIRES=              If specified, item will 'wear out' and need to be replaced
float   range = 5;                            //  SENSOR_DISTANCE=5     How far to scan for items
string  SF_PREFIX = "SF";                     //  SF_PREFIX=SF
string  languageCode = "en-GB";               //  LANG=en-GB
// Multilingual support
string  TXT_FUEL="Fuel";
string  TXT_ADD="Add";
string  TXT_FUEL_FOUND="Found fuel, emptying...";
string  TXT_ERROR_NOT_FOUND="Error! Fuel not found nearby";
string  TXT_EXPIRED="I have expired! Removing...";
string  TXT_STOP_FIRE="Put out fire";
string  TXT_START_FIRE="Light fire";
string  TXT_SELECT="Select";
string  TXT_CLOSE="CLOSE";
string  TXT_FOLLOW_ME="Follow me";
string  TXT_STOP="STOP";
string  TXT_BAD_PASSWORD="Bad password";
string  TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string  TXT_LANGUAGE="@";
//
string  SUFFIX = "F2";
//
integer FARM_CHANNEL = -911201;
string  PASSWORD;
integer lastTs;
integer rezTs;
string  FUEL = "Wood";
vector  GRAY = <0.207, 0.214, 0.176>;
vector  RED = <1.0, 0.0, 0.0>;
float   fuel_level=0.0;
integer burning;
integer energy = -1;
key     lastUser = NULL_KEY;
key     followUser = NULL_KEY;
float   uHeight = 0;
integer listener=-1;
integer listenTs;
string  status;


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

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

loadConfig()
{
    integer i;
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                     if (cmd == "FUELS") fuelTypes = llParseString2List(val, [",", ";"], []);
                else if (cmd == "FUEL_NAME") fuelTypes = [val];
                else if (cmd == "SENSOR_DISTANCE") range = (float)val;
                else if (cmd == "EXPIRES") EXPIRES = (integer)val;
                else if (cmd == "MANUFACTURED") isMade = (integer)val;
                else if (cmd == "TXT_COLOR")
                {
                    if ((val == "ZERO_VECTOR") || (val == "OFF"))
                    {
                        TXT_COLOR = ZERO_VECTOR;
                    }
                    else
                    {
                        TXT_COLOR = (vector)val;
                        if (TXT_COLOR == ZERO_VECTOR) TXT_COLOR = <1,1,1>;
                    }
                }
                else if (cmd == "SF_PREFIX") SF_PREFIX = val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "F")
    {
        rezTs = llList2Integer(desc, 1);
        languageCode = llList2String(desc, 2);
        fuel_level = llList2Float(desc, 3);
    }
    //sfp Notecard
    if (isMade == FALSE) PASSWORD = osGetNotecardLine("sfp", 0);
}

saveToDesc()
{
    llSetObjectDesc("F;" +(string)rezTs+";" +languageCode+";" +(string)fuel_level);
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
                         if (cmd == "TXT_FUEL") TXT_FUEL = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_STOP_FIRE") TXT_STOP_FIRE = val;
                    else if (cmd == "TXT_START_FIRE") TXT_START_FIRE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_FOLLOW_ME") TXT_FOLLOW_ME = val;
                    else if (cmd == "TXT_STOP") TXT_STOP = val;
                    else if (cmd == "TXT_FUEL_FOUND") TXT_FUEL_FOUND = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_EXPIRED") TXT_EXPIRED = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

reset()
{
    if (llGetInventoryType(getProdScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(getProdScriptName());
    rezTs = llGetUnixTime();
    lastTs = -1;
    llParticleSystem([]);
    refresh(0);
    llSetTimerEvent(900);
}

psys(key k)
{
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,

                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 30,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
}

string getFuelName()
{
    if (llGetListLength(fuelTypes) == 1)
    {
        return llList2String(fuelTypes, 0);
    }
    else
    {
        return TXT_FUEL;
    }
}

string getProdScriptName()
{
    string prodScriptName = "";
    string itemName;
    integer i;
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    for (i=0; i < count; i++)
    {
        itemName = llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 6);
        if (itemName == "product")
        {
            prodScriptName = llGetInventoryName(INVENTORY_SCRIPT, i);
        }
    }
    return prodScriptName;
}

fireOff()
{
    if (burning == TRUE)
    {
        integer lnkNum;
        lnkNum = getLinkNum("Fire");
        if (lnkNum != -1)
        {
            llSetLinkPrimitiveParams(lnkNum, [PRIM_COLOR, ALL_SIDES, <1,1,1> , 0., PRIM_GLOW, ALL_SIDES, 0., PRIM_POINT_LIGHT, FALSE, <1,1,.8>, 1., 15., .25 ]);
        }
        lnkNum = getLinkNum("Wood");
        if (lnkNum != -1)
        {
            llSetLinkPrimitiveParams(lnkNum, [PRIM_TEXTURE, ALL_SIDES, "charwood", <1,1,1>, <0,0,0>, 0.0]);
        }
        llSetTimerEvent(0);
        llStopSound();
        burning = FALSE;
        lastUser = NULL_KEY;
        llMessageLinked(LINK_SET, 0, "ENDCOOKING", NULL_KEY);
    }
}

fireOn()
{
    if (burning == FALSE)
    {
        burning = TRUE;
        psys(NULL_KEY);
        llSetTimerEvent(1);
        lastTs = llGetUnixTime();
        llLoopSound("fire", 1.0);
        integer lnkNum;
        lnkNum = getLinkNum("Fire");
        if (lnkNum != -1)
        {
            llSetLinkPrimitiveParams(lnkNum, [PRIM_COLOR, ALL_SIDES, <1,1,1> , 1.0, PRIM_GLOW, ALL_SIDES, 0.1, PRIM_POINT_LIGHT, TRUE, <1,1,0.8>, 1.0, 15.0, 0.25 ]);
        }
        lnkNum = getLinkNum("Wood");
        if (lnkNum != -1)
        {
            llSetLinkPrimitiveParams(lnkNum, [PRIM_TEXTURE, ALL_SIDES, "firewood", <1,1,1>, <0,0,0>, 0.0]);
        }
        llMessageLinked(LINK_SET, 0, "STARTCOOKING", NULL_KEY);
    }
}

doDie(key objectKey)
{
    llOwnerSay(TXT_EXPIRED);
    if (llGetListLength(llGetObjectDetails(objectKey, [OBJECT_NAME])) != 0)
    {
        llSetLinkColor(LINK_SET, GRAY, ALL_SIDES);
        osMessageObject(objectKey, "DIE|"+llGetKey()+"|100");
        llSleep(2.5);
    }
    llDie();
}

refresh(integer force)
{
    integer days = llFloor((llGetUnixTime()- rezTs)/86400);
    if (EXPIRES > 0)
    {
        if (EXPIRES > 1 && (EXPIRES-days) < 2)
        {
            llSetLinkColor(LINK_SET, GRAY, ALL_SIDES);
        }
        if (days >= EXPIRES)
        {
            doDie(NULL_KEY);
        }
    }

    if ((burning == TRUE) || (force == TRUE))
    {
        string str = "";
        if (RSTATE == 0) str = "-B-"; else if (RSTATE == -1) str = "-RC-";

        integer ts = llGetUnixTime();
        fuel_level -= 100.0 *(float)(ts - lastTs) / (7200.);
        if (fuel_level < 0) fuel_level = 0;
        if (fuel_level < 100)
        {
            if (TXT_COLOR == ZERO_VECTOR)
            {
                if (str == "") llSetText("", ZERO_VECTOR, 0.0); else llSetText(str, GRAY, 0.5);
            }
            else
            {
                llSetText(TXT_FUEL +": "+(string)((integer)fuel_level)+"%\n"+str , TXT_COLOR, 1.0);
            }
        }
        else
        {
            llSetText(str, GRAY, 0.5);
        }

        if (fuel_level <= 0)
        {
            fireOff();
            fuel_level = 0;
        }
        lastTs = ts;
        saveToDesc();
    }
}


default
{
    listen(integer c, string nm, key id, string m)
    {

        if (m == TXT_ADD + " " +TXT_FUEL)
        {
            FUEL = "";
            llSensor(FUEL, "",SCRIPTED,  range, PI);
        }
        else if (m == TXT_ADD+" "+getFuelName())
        {
            FUEL = SF_PREFIX+" "+getFuelName();
            llSensor(FUEL, "",SCRIPTED,  range, PI);
        }
        else if (m == TXT_STOP_FIRE)
        {
            fireOff();
        }
         else if (m == TXT_START_FIRE)
         {
            fireOn();
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (m == TXT_FOLLOW_ME)
        {
            followUser = id;
            llSetTimerEvent(1);
        }
        else if (m == TXT_STOP)
        {
            followUser = NULL_KEY;
            // No target so just go to ground
            llSetPos( llGetPos()- <0,0, uHeight-0.5> );
            checkListen();
            llSetTimerEvent(0);
        }
        else if (status == "WaitSelection")
        {
            status = "";
            FUEL = SF_PREFIX+" "+m;
            llSensor(FUEL, "",SCRIPTED,  range, PI);
        }
    }

    dataserver(key kk, string m)
    {
        debug("dataserver:" +m);
        list tk = llParseStringKeepNulls(m , ["|"], []);
        string cmd = llList2String(tk,0);

        if (cmd == "INIT")
        {
            PASSWORD = llList2String(tk,1);
            loadConfig();
            loadLanguage(languageCode);
            reset();
        }
        else if (llList2String(tk,1) == PASSWORD)
        {
            if (SF_PREFIX+" "+cmd == llToUpper(FUEL)) // Add fuel & start using it
            {
                fuel_level = 100.0;
                burning = FALSE;
                fireOn();
            }
            else if (cmd == "HEALTH")
            {
                if (llList2Key(tk, 3) != lastUser) lastUser = NULL_KEY;
                return;
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
                osMessageObject(llList2Key(tk, 2), answer);
                //Send a message to other prim with script
                osMessageObject(llGetLinkKey(3), "VERSION-CHECK|" + PASSWORD + "|" + llList2String(tk, 2));
            }
            else if (cmd == "DO-UPDATE")
            {
                if (llGetOwnerKey(kk) != llGetOwner())
                {
                    llOwnerSay(TXT_ERROR_UPDATE);
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

    timer()
    {
        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
            }
            else
            {
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector size  = llGetAgentSize(followUser);
                uHeight = size.z;
                vector v = llList2Vector(userData, 1)+ <2.1, -1.0, 1.0> * llList2Rot(userData,2);
                float t = llVecDist(mypos, v)/10;
                if (t > .1)
                {
                    if (t > 5) t = 5;
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    //rotation r2 = llRotBetween(<1,0,0>,vn);
                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += t;
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    llSetTimerEvent(t+1);
                }
            }
        }
        else
        {
            llSetTimerEvent(600);
        }
        refresh(FALSE);
        if ((burning == TRUE) && (lastUser != NULL_KEY)) llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Health|5|Energy|10" );
        checkListen();
    }

    touch_start(integer n)
    {
        if (PASSWORD == "") doDie(NULL_KEY);
        energy = -1;
        lastUser = llDetectedKey(0);
        llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|CQ");
        list opts = [];
        if (fuel_level < 10) opts += TXT_ADD + " " +getFuelName();
        if (burning == TRUE) opts += TXT_STOP_FIRE;
        else if (fuel_level >10) opts += TXT_START_FIRE;
        if (lastUser == llGetOwner())
        {
            if (isMade == TRUE)
            {
                if (followUser == NULL_KEY) opts += TXT_FOLLOW_ME; else opts += TXT_STOP;
            }
         }
        opts += [TXT_LANGUAGE, TXT_CLOSE];
        startListen();
        llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
    }

    sensor(integer n)
    {
        debug("sensor:FUEL=|"+FUEL+"|  Status="+status+"  SF_PREFIX=|"+SF_PREFIX+"|");
        if (FUEL == "")
        {
            integer i;
            integer buttonCount = 0;
            list names;
            string desc;
            string name;
            list foundList = [];
            for (i = 0; i < n; i++)
            {
                name = llDetectedName(i);
                if ( llGetSubString(name, 0, 2) == SF_PREFIX+" ")
                {
                    desc= llList2String(llGetObjectDetails(llDetectedKey(i), [OBJECT_DESC]), 0);
                    name = llGetSubString(llDetectedName(i), 3,-1);
                    if (llGetSubString(desc, 0,1) == "P;")
                    {
                        if ((llListFindList(foundList, [name]) == -1) && (buttonCount < 11))
                        {
                            if (llListFindList(fuelTypes, [name]) != -1)
                            {
                                foundList += name; // Add valid fuels
                                buttonCount++;
                            }
                        }
                    }
                }
            }
            if (llGetListLength(foundList) != 0)
            {
                status = "WaitSelection";
                llDialog(lastUser,  TXT_SELECT, foundList+[TXT_CLOSE], chan(llGetKey()));
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND+" ("+llDumpList2String(fuelTypes, ", ")+")");
            }
        }
        else
        {
            key id = llDetectedKey(0);
            llRegionSayTo(lastUser, 0, TXT_FUEL_FOUND);
            osMessageObject(id, "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        debug("no_sensor:FUEL=|"+FUEL+"|  Status="+status);
        llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND+" ("+llDumpList2String(fuelTypes, ", ")+")");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            saveToDesc();
            refresh(TRUE);
        }
    }

    state_entry()
    {
        burning = TRUE;
        fireOff();
        llSetText("", ZERO_VECTOR, 0);
        loadConfig();
        loadLanguage(languageCode);
        lastUser = NULL_KEY;
        rezTs = llGetUnixTime();
        lastTs = rezTs;
        llSetTimerEvent(1);
    }

    on_rez(integer n)
    {
        llSetObjectDesc("-");
        llSleep(0.1);
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
            refresh(FALSE);
        }
    }
}
