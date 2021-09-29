// power_lighting_switch.lsl
// Lighting that uses power from the region grid and/or loacal SF kWh
//

float   VERSION = 5.0;    // Beta  5 November 2020
integer RSTATE = 0;       // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overidden by config notecard
integer sensorMode = FALSE;     // SENSOR_MODE=0
float sensorDistance = 10.0;    // SENSOR_DISTANCE=10
integer SHOW_TXT = TRUE;        // SHOW_TXT=1
string FUEL = "SF kWh";         // FUEL_NAME=SF kWh
integer onGrid = FALSE;         // ON_GRID=0
integer channOffset = 0;        // CHAN=0
string  languageCode = "en-GB"; // LANG=en-GB
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
string TXT_SENSOR="Sensor";
string TXT_CLOSE="CLOSE";
string TXT_KWH_FOUND="Found kWh, emptying...";
string TXT_ERROR_NOT_FOUND="Error! kWh not found nearby! You must bring it near me!";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string SUFFIX = "L1";
//
integer energy_channel = -321321;
integer comms_channel;
//
string PASSWORD="*";
integer lastTs;

vector RED =    <1.000, 0.227, 0.227>;  // No power
vector ORANGE = <1.000, 0.612, 0.227>;  // Off grid, with power
vector GREEN =  <0.000, 1.000, 0.000>;  // On grid
vector WHITE =  <0.867, 0.867, 0.867>;  // Float text colour
vector TEAL =   <0.224, 0.800, 0.800>;  // Auto mode (day/night)
vector YELLOW = <1.000, 1.000, 0.502>;  // Sensor mode on
vector SALMON = <0.930, 0.739, 0.664>;  // Sensor mode off

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

float fuel_level=0.0;
integer wattage = 6000;
integer burning;
string status;
string mode;
integer waitConnect;

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
                else if (cmd == "CHAN")
                {
                    comms_channel = chan(llGetOwner());
                    channOffset = (integer)val;
                    comms_channel += channOffset;
                }
                else if (cmd == "LANG") languageCode = val;
                else if (cmd == "SENSOR_MODE") sensorMode = (integer)val;
                else if (cmd == "SENSOR_DISTANCE") sensorDistance = (float)val;
                if (sensorDistance <1.0) sensorDistance = 1.0;
            }
        }
    }
     // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "L")
    {
        languageCode = llList2String(desc, 1);
        onGrid = llList2Integer(desc, 2);
        sensorMode = llList2Integer(desc, 3);
        mode = llList2String(desc, 4);
    }
    else
    {
        save2Description();
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
                    else if (cmd == "TXT_SENSOR") TXT_SENSOR = val;
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

save2Description()
{
    llSetObjectDesc("L;"+languageCode +";"+(string)onGrid +";"+(string)sensorMode +";"+mode);
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
        llRegionSay(comms_channel, "OFF|" + PASSWORD);
        llSetTimerEvent(0);
        burning = FALSE;
        llMessageLinked(LINK_SET, 0, "ENDCOOKING", NULL_KEY);
    }
    else
    {
        burning = FALSE;
    }
}

fireOn()
{
    if (burning == FALSE)
    {
        burning = TRUE;
        lastTs = llGetUnixTime();
        if (fuel_level >0)
        {
            llRegionSay(comms_channel, "ON|" + PASSWORD);
            llMessageLinked(LINK_SET, 0, "STARTCOOKING", NULL_KEY);
        }
        else
        {
            burning = FALSE;
            setText(TXT_LOW);
        }
        llSetTimerEvent(0.1);
    }
    else
    {
        burning = TRUE;
    }
}

setSupplier()
{
    vector colour;
    if (onGrid == FALSE)
    {
        if (fuel_level <10) colour = RED; else colour = ORANGE;
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [ PRIM_COLOR, 0, colour, 1.0,
                                                            PRIM_FULLBRIGHT, 0, 1]);
    }
    else
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [ PRIM_COLOR, 0, GREEN, 1.0,
                                                            PRIM_FULLBRIGHT, 0, 1]);
    }
}

setMode()
{
    vector colour = <0,0,0>;
    if (mode == TXT_AUTO) colour = TEAL;
     else if (sensorMode == TRUE) colour = YELLOW;
      else colour = SALMON;
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [ PRIM_COLOR, 4, colour, 1.0,
                                                            PRIM_FULLBRIGHT, 4, 1]);
    }
}

setText(string msg)
{
    string str = "";
    if (RSTATE == 0) str += "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";

    if (SHOW_TXT == TRUE)
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_TEXT, msg+str, WHITE, 1.0]);
    }
    else
    {
        llSetLinkPrimitiveParams(getLinkNum("Indicator"), [PRIM_TEXT, str, SALMON, 0.5]);
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
        fuel_level -= 100.*(float)(ts - lastTs) / (wattage);
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
        if (sensorMode == TRUE)
        {
            llSensor("", NULL_KEY, AGENT, sensorDistance, PI);
            status = "checkAgents";
        }
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
        if (fuel_level < 100) setText(TXT_ENERGY +": "+(string)((integer)fuel_level)+"%\n" +mode);
        else setText("");
    }
    else
    {
        setText("");
    }
    setSupplier();
    setMode();
    save2Description();
}


default
{
    listen(integer c, string nm, key id, string m)
    {
        debug("listen:"+m);
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
                waitConnect = TRUE;
                llSetTimerEvent(3.0);
            }
            else
            {
                refresh(TRUE);
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
            sensorMode = FALSE;
            refresh(FALSE);
            llSetTimerEvent(0.2);
        }
        else if (m == "-"+TXT_SENSOR)
        {
            sensorMode = FALSE;
            refresh(FALSE);
            llRegionSayTo(id, 0, TXT_SENSOR + " " +TXT_STOP);
        }
        else if (m == "+"+TXT_SENSOR)
        {
            sensorMode = TRUE;
            refresh(FALSE);
            llRegionSayTo(id, 0, TXT_SENSOR + " " +TXT_START);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
    }

    dataserver(key kk, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseStringKeepNulls(m , ["|"], []);
        string cmd = llList2String(tk,0);
        if ((cmd == "VERSION-CHECK") ||  (cmd == "DO-UPDATE"))
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
                waitConnect = FALSE;
                refresh(FALSE);
            }
        }
    }

    timer()
    {
        if (waitConnect == TRUE)
        {
            llSetTimerEvent(0);
            onGrid = FALSE;
            waitConnect = FALSE;
            setSupplier();
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
        key toucher = llDetectedKey(0);
        if (!(llSameGroup(toucher)  || osIsNpc(toucher)))
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
            return;
        }
        integer touchLink = llDetectedLinkNumber(0);
        if (touchLink == 2)
        {
            if ((burning == TRUE) && (mode == TXT_MANUAL))
            {
                fireOff();
                refresh(FALSE);
            }
            else if ((fuel_level >10) && (mode == TXT_MANUAL))
            {
                fireOn();
            }
        }
        else
        {
            list opts = [];
            opts += [TXT_LANGUAGE];
            if (mode == TXT_AUTO) opts += TXT_MANUAL; else opts += TXT_AUTO;
            opts += [TXT_CLOSE];
            if ((fuel_level < 10) && (onGrid == FALSE)) opts += TXT_ADD_KWH;

            if ((burning == TRUE) && (mode == TXT_MANUAL)) opts += TXT_STOP;
             else if ((fuel_level >10) && (mode == TXT_MANUAL)) opts += TXT_START;

            if (onGrid == TRUE) opts += TXT_DISCONNECT; else opts += TXT_CONNECT;

            string txtExtra = "";
            if (mode != TXT_AUTO)
            {
                if (sensorMode == TRUE)
                {
                    txtExtra = TXT_START;
                    opts += "-"+TXT_SENSOR;
                }
                else
                {
                    txtExtra = TXT_STOP;
                    opts += "+"+TXT_SENSOR;
                }
            }
            startListen();
            llDialog(llDetectedKey(0), TXT_SELECT+"\n"+TXT_MODE+": "+mode +"\t " +TXT_SENSOR +": " +txtExtra, opts, chan(llGetKey()));
        }
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
        if (status == "WaitFuel") llSay(0, TXT_ERROR_NOT_FOUND);
        else if (status == "checkAgents") fireOff();
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh(TRUE);
        }
    }

    state_entry()
    {
        mode = TXT_MANUAL;
        llSetText("", ZERO_VECTOR, 0);
        setText("");
        comms_channel = chan(llGetOwner());
        loadConfig();
        loadLanguage(languageCode);
        refresh(TRUE);
        lastTs = llGetUnixTime();
        llSetTimerEvent(1);
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
        if (change & CHANGED_REGION_START) llResetScript();
    }

}
