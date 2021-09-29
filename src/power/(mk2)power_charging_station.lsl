// power_charging_station.lsl
//  Charging station takes power from power controller to charge other items

float   VERSION = 5.0;   // 27 November 2020
integer RSTATE  = 1;     // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// These can be overridden in config notecard
float sensorRange = 10.0;    // SENSOR_DISTANCE=10   sensor radius
list receiver_names = [];    // NAMES=[]             can add names to restrict sensor search to only look for those names eg "SF Vehicle|SF Electric Car"]
string SF_KWH="SF kWh";
string languageCode = "en-GB";

// For multulingual notecard support
string TXT_TITLE="Wireless Charging station";
string TXT_SUB_TITLE="Charge your vehicle here";
string TXT_SCANNING="Scanning...";
string TXT_OFF_LINE="Sorry, charger is off-line. Please try again later.";
string TXT_CHECKING="Checking available energy reserves...";
string TXT_CHARGING="Charging";
string TXT_TRANSMITTING="Transmitting...";
string TXT_NO_ENERGY="There is not enough energy available. Please try again later.";
string TXT_OFFLINE="OFFLINE";
string TXT_IN_USE="In use...";
string TEXT_SELECT_ITEM="Select item to charge";
string TXT_NOT_FOUND="Cannot detect anything, please bring closer.";
string TXT_CLOSE="CLOSE";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "C3";
//
string PASSWORD="*";
integer energy_channel = -321321;
key vehicle;
list receiver_keys = [];
key toucher;
key ownkey;
integer status;

vector AQUA      = <0.498, 0.859, 1.000>;
vector ORANGE    = <1.000, 0.522, 0.106>;
vector LIME      = <0.004, 1.000, 0.439>;
vector RED       = <1.000, 0.255, 0.212>;

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
        listener = llListen(chan(ownkey), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
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
            list tok = llParseString2List(llList2String(lines,i), ["="], []);
            if (llList2String(tok,1) != "")
            {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                if (cmd == "SENSOR_DISTANCE")  sensorRange = (float)val;
                else if (cmd == "NAMES") receiver_names = llParseString2List(val, ["|"], "");
                else if (cmd == "SF_KWH") SF_KWH = val;
                else if (cmd == "LANG") languageCode = val;
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
                         if (cmd == "TXT_TITLE")  TXT_TITLE = val;
                    else if (cmd == "TXT_SUB_TITLE") TXT_SUB_TITLE = val;
                    else if (cmd == "TXT_SCANNING") TXT_SCANNING = val;
                    else if (cmd == "TXT_OFF_LINE") TXT_OFF_LINE = val;
                    else if (cmd == "TXT_CHECKING") TXT_CHECKING = val;
                    else if (cmd == "TXT_CHARGING") TXT_CHARGING = val;
                    else if (cmd == "TXT_TRANSMITTING") TXT_TRANSMITTING = val;
                    else if (cmd == "TXT_NO_ENERGY") TXT_NO_ENERGY = val;
                    else if (cmd == "TXT_OFFLINE") TXT_OFFLINE = val;
                    else if (cmd == "TXT_IN_USE") TXT_IN_USE = val;
                    else if (cmd == "TEXT_SELECT_ITEM") TEXT_SELECT_ITEM = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE =val;
                }
            }
        }
    }
}

showStatus(integer level)
{
    integer i;
    integer ln;
    for (i=2; i<6; i++)
    {
        ln =getLinkNum((string)i);
        if (i <= level)
        {
            llSetLinkPrimitiveParamsFast(ln, [ PRIM_FULLBRIGHT, -1, 0,
                                                                  PRIM_GLOW, -1, 0.3
                                                                ]);
        }
        else
        {
            llSetLinkPrimitiveParamsFast(ln, [ PRIM_FULLBRIGHT, -1, 0,
                                                                  PRIM_GLOW, -1, 0.0
                                                                ]);
        }
    }
}

noEnergy()
{
    llRegionSayTo(toucher, 0,TXT_NO_ENERGY);
    llSetText(TXT_OFFLINE, RED, 1.0);
    status = 0;
    showStatus(1);

    llSetPrimitiveParams([ PRIM_FULLBRIGHT, -1, 0,
                           PRIM_GLOW, -1, 0.0 ]);
    llSetTimerEvent(300);
}

water(key u)
{
        llParticleSystem(
        [

            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_BURST_RADIUS,.2,
            PSYS_SRC_ANGLE_BEGIN,0.,
            PSYS_SRC_ANGLE_END,.5,
            PSYS_PART_START_COLOR,<1,1,1>,
            PSYS_PART_END_COLOR,<1,1,1>,
            PSYS_PART_START_ALPHA,0.9,
            PSYS_PART_END_ALPHA,0.0,
            PSYS_PART_START_GLOW,0.0,
            PSYS_PART_END_GLOW,0.0,
            PSYS_PART_START_SCALE,<0.1, 0.1, 1>,
            PSYS_PART_END_SCALE,<0.5, 0.5, 1>,
            PSYS_SRC_TEXTURE,llGetInventoryName(INVENTORY_TEXTURE,0),
            PSYS_SRC_TARGET_KEY, u,
            PSYS_SRC_MAX_AGE,4,
            PSYS_PART_MAX_AGE,5,
            PSYS_SRC_BURST_RATE, 0.5,
            PSYS_SRC_BURST_PART_COUNT,3,
            PSYS_SRC_ACCEL,<0.000000,0.000000,-1.1>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,1,
            PSYS_SRC_BURST_SPEED_MAX,2,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_TARGET_POS_MASK |
                PSYS_PART_INTERP_COLOR_MASK |
                PSYS_PART_INTERP_SCALE_MASK
        ] );
       llTriggerSound(llGetInventoryName(INVENTORY_SOUND,0), 1.0);
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}



default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD);
    }

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        string str = "";
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        llSetText(TXT_TITLE + "\n" +TXT_SUB_TITLE +str, AQUA, 1.0);
        showStatus(2);
        ownkey = llGetKey();
        status = 1;
    }

    touch_start(integer n)
    {
        toucher = llDetectedKey(0);
        if (llSameGroup(toucher))
        {
            if (status == 1)
            {
                llSetText(TXT_SCANNING, ORANGE, 1.0);
                showStatus(3);
                toucher = llDetectedKey(0);
                llSensor("", "", SCRIPTED, sensorRange, PI);
            }
            else
            {
                llRegionSayTo(toucher, 0, TXT_OFF_LINE);
            }
        }
        else
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
        }
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == TXT_CLOSE)
        {
            checkListen(TRUE);
            llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE, AQUA, 1.0);
            status = 1;
            showStatus(2);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else
        {
            showStatus(4);
            vehicle = llList2Key(receiver_keys, (integer)m);
            llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
            llSetText(TXT_CHECKING, LIME, 1.0);
        }
    }

    dataserver(key id, string m)
    {
        debug("dataserver: " +m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        string cmd = llList2String(tk,0);
        // update commands won't have an access key so check these first
        if ((cmd == "VERSION-CHECK") || (cmd == "DO-UPDATE"))
        {
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
                if (llGetOwnerKey(id) != llGetOwner())
                {
                    llMessageLinked(LINK_SET, 0, "UPDATE-FAILED", "");
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
            integer i;
            if ((cmd == "HAVEENERGY") && (status != -1))
            {
                status = 1;
                water(toucher);
                llSleep(2);
                llRegionSayTo(toucher, 0,TXT_CHARGING + " " + llKey2Name(vehicle)+"...");
                llSetText(TXT_TRANSMITTING, <1.000, 0.522, 0.106>, 1.0);
                water(vehicle);
                showStatus(5);
                osMessageObject(vehicle, "KWH|"+PASSWORD+"|"+(string)llGetKey());
                llSleep(2);
                showStatus(4);
                llSleep(0.75);
                showStatus(3);
                llSleep(0.5);
                showStatus(2);
                llSleep(1);
                llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE, AQUA, 1.0);
            }
            else if (cmd  == "NOENERGY")
            {
                noEnergy();
            }
        }

    }

    timer()
    {
        llSetTimerEvent(0);
        status = 1;
        showStatus(2);
        string str;
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        llSetText(TXT_TITLE + "\n" +TXT_SUB_TITLE +str, AQUA, 1.0);
    }

    sensor(integer num_detected)
    {
        llSetText(TXT_IN_USE, AQUA, 1.0);
        receiver_keys = [];
        list buttons = [];
        string dlgText = "";
        integer prefix=0;
        integer index = 0;
        while (index < num_detected)
        {
            string name = llKey2Name(llDetectedKey(index));
            if ((llGetListLength(receiver_names) == 0) || (llListFindList(receiver_names, [name]) != -1))
            {
                if (prefix < 10)
                {
                    receiver_keys += llDetectedKey(index);
                    dlgText += "\n" +(string)prefix +" " +name;
                    buttons += (string)prefix;
                    prefix += 1;
                }
            }
            index +=1;
        }

        if (buttons == [])
        {
            llRegionSayTo(toucher, 0, TXT_NOT_FOUND);
            checkListen(TRUE);
            llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE, AQUA, 1.0);
            showStatus(2);
        }
        else
        {
            buttons += [TXT_LANGUAGE, TXT_CLOSE];
            startListen();
            llDialog(toucher, "\n" + TEXT_SELECT_ITEM +":\n"+dlgText, buttons, chan(llGetKey()));
        }
    }

    no_sensor()
    {
        llRegionSayTo(toucher, 0, TXT_NOT_FOUND);
        llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE, AQUA, 1.0);
        showStatus(2);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message: " + str);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE, AQUA, 1.0);
            checkListen(TRUE);
            status = -1;
            llSetTimerEvent(1.0);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
