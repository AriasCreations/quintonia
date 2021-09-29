// power_light.lsl
// Lighting that uses power from the region grid and/or loacal SF kWh
//
float   VERSION = 5.0;    // Beta  27 November 2020
integer RSTATE = 1;       // RSTATE: 1=release, 0=beta, -1=RC

// Can be overidden by config notecard
integer SHOW_TXT = TRUE;    // SHOW_TXT=
string FUEL = "SF kWh";     // FUEL_NAME=
integer onGrid = FALSE;     // ON_GRID=
// Optional lighting config
float brightness = 1.0;                     // BRIGHTNESS=
vector lightColour = <1.000, 1.000, 0.800>; // COLOR=
float radius = 20.0;                        // RADIUS=20.0
float falloff = 0.01;                       // FALLOFF=0.01
//
string  languageCode = "";  // LANG=  use defaults below unless language config notecard present
// Multilingual support
string TXT_ENERGY="Energy";
string TXT_ADD_KWH="Add kWh";
string TXT_CONNECT="Connect";
string TXT_DISCONNECT="Disconnect";
string TXT_CONNECTING="Connecting";
string TXT_STOP="Off";
string TXT_START="On";
string TXT_MODE="Mode";
string TXT_AUTO="Auto";
string TXT_MANUAL="Manual";
string TXT_LOW="Low energy";
string TXT_SELECT="Select";
string TXT_CLOSE="CLOSE";
string TXT_KWH_FOUND="Found kWh, emptying...";
string TXT_ERROR_NOT_FOUND="Error! kWh not found nearby! You must bring it near me!";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_ERROR_GROUP = "Sorry, we are not in the same group";
string TXT_LANGUAGE="@";
//
string SUFFIX = "L1";
//
integer energy_channel = -321321;
//
string  PASSWORD="*";
integer lastTs;
key     toucher;

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
        toucher = NULL_KEY;
    }
}

float fuel_level=0.;
integer burning;
string status;
string mode;

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
    //sfp Notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
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
                     if (cmd == "FUEL_NAME") FUEL = val;
                else if (cmd == "SHOW_TXT") SHOW_TXT = (integer)val;
                else if (cmd == "ON_GRID") onGrid = (integer)val;
                else if (cmd == "COLOR") lightColour = (vector)val;
                else if (cmd == "BRIGHTNESS")
                {
                    brightness = (float)val/10;
                    if (brightness > 1.0) brightness = 1.0;
                }
                else if (cmd == "RADIUS")
                {
                    radius = (float)val;
                    if (radius > 20.0) radius = 20.0;
                    if (radius < 0.1) radius = 0.1;
                }
                else if (cmd == "FALLOFF")
                {
                    falloff = (float)val;
                    if (falloff > 2.0) falloff = 2.0;
                    if (falloff < 0.01) falloff = 0.01;
                }
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "L")
    {
        languageCode = llList2String(desc, 1);
        SHOW_TXT = llList2Integer(desc, 2);
        onGrid = llList2Integer(desc, 3);
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
                         if (cmd == "TXT_ENERGY") TXT_ENERGY = val;
                    else if (cmd == "TXT_ADD_KWH") TXT_ADD_KWH = val;
                    else if (cmd == "TXT_STOP") TXT_STOP = val;
                    else if (cmd == "TXT_START") TXT_START = val;
                    else if (cmd == "TXT_MODE") TXT_MODE = val;
                    else if (cmd == "TXT_AUTO") TXT_AUTO = val;
                    else if (cmd == "TXT_MANUAL") TXT_MANUAL = val;
                    else if (cmd == "TXT_CONNECT") TXT_CONNECT = val;
                    else if (cmd == "TXT_DISCONNECT") TXT_DISCONNECT = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_LOW") TXT_LOW = val;
                    else if (cmd == "TXT_KWH_FOUND") TXT_KWH_FOUND = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
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

integer qlDayCheck()
{
    // Check with lsl functions if sun above or below horizon
    vector sun=llGetSunDirection();
    float time = sun.z;
    if (llRound(sun.z) == 1) return 1; else return 0;
}

fireOff()
{
    if (burning == TRUE)
    {
        llSetLinkPrimitiveParams(getLinkNum("Lightbulb"), [PRIM_COLOR, 3, <0,0,0> , 1.0, PRIM_GLOW, ALL_SIDES, 0.0, PRIM_POINT_LIGHT, FALSE, <1.0, 1.0, 0.8>, 1.0, 15.0, 0.0 ]);
        llSetTimerEvent(0);
        burning = FALSE;
        llMessageLinked(LINK_SET, 0, "ENDCOOKING", NULL_KEY);
    }
}

fireOn()
{
    if (burning == FALSE)
    {
        burning = TRUE;
        psys(NULL_KEY);
        lastTs = llGetUnixTime();
        if (fuel_level >0)
        {
            llSetLinkPrimitiveParams(getLinkNum("Lightbulb"), [ PRIM_COLOR, 3, <0.789, 0.631, 0.211> , 1.0,
                                                                PRIM_GLOW, ALL_SIDES, 0.5,
                                                                PRIM_POINT_LIGHT, TRUE, lightColour, brightness, radius, falloff]);
            llMessageLinked(LINK_SET, 0, "STARTCOOKING", NULL_KEY);
        }
        else burning = FALSE;
        llSetTimerEvent(0.1);
    }
}

setSupplier()
{
    if (onGrid == FALSE)
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_COLOR, ALL_SIDES, <0.502, 0.502, 1.000>, 1.0]);
    }
    else
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_COLOR, ALL_SIDES, <0.000, 0.502, 0.502>, 1.0]);
    }
}

setText(string msg)
{
    string str = "";
    if (RSTATE == 0) str += "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";

    if (SHOW_TXT == TRUE)
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_TEXT, msg+str, <0.867, 0.867, 0.867>, 1.0]);
    }
    else
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_TEXT, str, <0.3, 0.3, 0.3>, 0.5]);
    }
}

refresh(integer force)
{
    if ((burning == TRUE) || (force == TRUE))
    {
        if (mode == TXT_AUTO)
        {
            if (qlDayCheck() == TRUE)
            {
                fireOff();
                return;
            }
        }
        integer ts = llGetUnixTime();
        fuel_level -= 100.*(float)(ts - lastTs) / (7200.);
        if (fuel_level<0) fuel_level=0;
        if ((onGrid == TRUE) && (fuel_level < 10))
        {
            llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
            setText(TXT_LOW);
        }
        else if (fuel_level <=0)
        {
            fireOff();
            fuel_level=0;
        }
        lastTs = ts;
    }
    else if (mode == TXT_AUTO)
    {
        if (qlDayCheck() == FALSE)
        {
            fireOn();
            return;
        }
    }
    //
    if (onGrid == FALSE)
    {
        if (fuel_level < 100) setText(TXT_ENERGY +": "+(string)((integer)fuel_level)+"%\n");
        else setText("");
    }
    else
    {
        setText("");
    }
    setSupplier();
    llSetObjectDesc("L;" + languageCode + ";" + (string)SHOW_TXT + ";" + (string)onGrid);
}


default
{
    listen(integer c, string nm, key id, string m)
    {
        if (m == TXT_ADD_KWH)
        {
            status = "WaitFuel";
            llSensor(FUEL, "",SCRIPTED,  5, PI);
        }
        else if (m == TXT_STOP)
        {
            fireOff();
            refresh(FALSE);
        }
         else if (m == TXT_START)
         {
            fireOn();
        }
        else if (m == TXT_DISCONNECT)
        {
            onGrid = FALSE;
            refresh(TRUE);
        }
        else if (m == TXT_CONNECT)
        {
            onGrid = TRUE;
            if (fuel_level < 10)
            {
                llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
                llRegionSayTo(id, 0, TXT_CONNECTING);
                setText(TXT_CONNECTING);
                status = "WaitConnect";
                llSetTimerEvent(5.0);
            }
            else
            {
                refresh(FALSE);
            }
        }
        else if (m == TXT_MANUAL)
        {
            mode = TXT_MANUAL;
            refresh(TRUE);
        }
        else if (m == TXT_AUTO)
        {
            mode = TXT_AUTO;
            llSetTimerEvent(0.2);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
    }

    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m , ["|"], []);
        string cmd = llList2String(tk,0);
        if ((cmd == "VERSION-CHECK") || (cmd == "DO-UPDATE"))
        {
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
                //Send a message to other prim with script
                osMessageObject(llGetLinkKey(3), "VERSION-CHECK|" + PASSWORD + "|" + llList2String(tk, 2));
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
        }
        else
        {
            if (llList2String(tk,1) != PASSWORD ) return;
            cmd = llList2String(tk,0);
            if (cmd == "KWH") // Add kWh & turn on light
            {
                fuel_level = 100.0;
                fireOn();
                refresh(TRUE);
            }
            else if (cmd == "HAVEENERGY")
            {
                fuel_level = 100.0;
                setText("");
                status = "";
                refresh(FALSE);
            }
        }
    }

    timer()
    {
        if (status == "WaitConnect")
        {
            onGrid = FALSE;
            status = "";
            llSetTimerEvent(30);
            refresh(TRUE);
        }
        else
        {
            refresh(FALSE);
            llSetTimerEvent(600);
            checkListen();
        }
    }

    touch_start(integer n)
    {
        toucher = llDetectedKey(0);
        if (!(llSameGroup(toucher)  || osIsNpc(toucher)))
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
            return;
        }
        list opts = [];
        opts += [TXT_LANGUAGE];
        if (mode == TXT_AUTO) opts += TXT_MANUAL; else opts += TXT_AUTO;
        opts += [TXT_CLOSE];

        if ((fuel_level < 10) && (onGrid == FALSE)) opts += TXT_ADD_KWH;
        if ((burning == TRUE) && (mode == TXT_MANUAL)) opts += TXT_STOP;
        else if ((fuel_level >10) && (mode == TXT_MANUAL)) opts += TXT_START;
        if (onGrid == TRUE) opts += TXT_DISCONNECT; else opts += TXT_CONNECT;

        startListen();
        llDialog(toucher, TXT_SELECT+"\n"+TXT_MODE+":"+mode, opts, chan(llGetKey()));
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if ( status == "WaitFuel")
        {
            llSay(0, TXT_KWH_FOUND);
            osMessageObject(id, "DIE|"+(string)llGetKey());
            fireOn();
        }
    }

    no_sensor()
    {
        if (status == "WaitFuel")
            llSay(0, TXT_ERROR_NOT_FOUND);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetObjectDesc("L;" + languageCode + ";" + (string)SHOW_TXT + ";" + (string)onGrid);
            refresh(TRUE);
        }
    }

    state_entry()
    {
        fireOff();
        mode = TXT_MANUAL;
        llSetText("", ZERO_VECTOR, 0);
        setText("");
        loadConfig();
        loadLanguage(languageCode);
        lastTs = llGetUnixTime();
        llSetTimerEvent(1);
    }

    on_rez(integer n)
    {
        llSetObjectDesc(" ");
        llSleep(0.2);
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }
}
