// power_generator.lsl
//  Unit generates energy from fuel and sends power to region controller
//
float   VERSION = 5.0;    // 27 November 2020
integer RSTATE = 1;       // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overidden by config notecard
list FUEL_LIST = ["SF Fuel", "SF Oil", "SF Gas"];   //  FUEL_LIST=SF Fuel,SF Oil,SF Gas
integer showFumes = TRUE;                           // FUMES=1
integer scanRange = 20;                             // SENSOR_DISTANCE=20
string  languageCode = "en-GB";                     // use defaults below unless language config notecard present
//
// Multilingual support
string TXT_FUEL="Fuel";
string TXT_ADD_FUEL="Add fuel";
string TXT_CHARGED="Charged";
string TXT_STOP="Switch Off";
string TXT_START="Switch On";
string TXT_SELECT="Select";
string TXT_CLOSE="CLOSE";
string TXT_FUEL_FOUND="Found fuel, emptying...";
string TXT_ERROR_NOT_FOUND="Error! Fuel not found nearby! You must bring it  near me!";
string TXT_NOT_FOUND100="with 100% not found nearby. Please bring it closer.";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string SUFFIX = "G2";
//
string VALSNC = "valsNC";
integer FARM_CHANNEL = -911201;
integer ENERGY_CHANNEL= -321321;
string PASSWORD="*";
integer lastTs;
float fuel_level;
float energy;
integer consuming;
string status;
string lookingFor;
list selitems = [];
integer startOffset=0;
key lastUser = NULL_KEY;
key ownKey;
integer listener=-1;
integer listenTs;

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

checkListen(integer force)
{
    if ( (listener > 0 && llGetUnixTime() - listenTs > 300) || (force == TRUE) )
    {
        llListenRemove(listener);
        listener = -1;
        selitems = [];
    }
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(ownKey);
    if (l < 12)
    {
        llDialog(id, message, [TXT_CLOSE]+buttons, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(buttons, startOffset, startOffset + 9);
    its = llListSort(its, 1, TRUE);
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
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
                     if (cmd == "SENSOR_DISTANCE" ) scanRange = (integer)val;
                else if (cmd == "FUMES") showFumes = (integer)val;
                else if (cmd == "FUEL_LIST") FUEL_LIST = llParseString2List(val, [","],[]);
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    // Load settings from NC
    if (llGetInventoryType(VALSNC) == INVENTORY_NOTECARD) loadData(); else saveData();
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
                    else if (cmd == "TXT_ADD_FUEL") TXT_ADD_FUEL = val;
                    else if (cmd == "TXT_CHARGED") TXT_CHARGED = val;
                    else if (cmd == "TXT_STOP") TXT_STOP = val;
                    else if (cmd == "TXT_START") TXT_START = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_FUEL_FOUND") TXT_FUEL_FOUND = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_NOT_FOUND100") TXT_NOT_FOUND100 = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

saveData()
{
    string data ="G;" +(string)fuel_level+";" +(string)energy+";" +languageCode;
    if (llGetInventoryType(VALSNC) == INVENTORY_NOTECARD) llRemoveInventory(VALSNC);
    osMakeNotecard(VALSNC, data);
}

loadData()
{
    if (llGetInventoryType(VALSNC) == INVENTORY_NOTECARD)
    {
        integer i;
        list lines = llParseString2List(osGetNotecard(VALSNC), [";"], []);
        if ((llGetListLength(lines) == 4) && (llList2String(lines,0) == "G"))
        {
            fuel_level = llList2Float(lines, 1);
            energy  = llList2Float(lines, 2);
            languageCode =  llList2String(lines,3);
        }
        else
        {
            saveData();
        }
    }
    else
    {
        saveData();
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

showFuelLevel()
{
    debug("showFuelLevel:lang=" +languageCode);
    string str = "";
    if (RSTATE == 0) str += "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
    llSetText(TXT_FUEL +": "+(string)(llRound(fuel_level))+"\n" +(string)(llRound(energy*10))+"% "+TXT_CHARGED +str , <1,1,1>, 1.0);
}

generatorOff()
{
    if (consuming == TRUE)
    {
        llSetTimerEvent(0);
        llStopSound();
        consuming = FALSE;
        lastUser = NULL_KEY;
        llMessageLinked(LINK_SET, 0, "ENDCOOKING", NULL_KEY);
        saveData();
    }
}

generatorOn()
{
    if (consuming == FALSE)
    {
        consuming = TRUE;
        psys(NULL_KEY);
        llSetTimerEvent(1);
        lastTs = llGetUnixTime();
        llLoopSound("fx", 1.0);
        llMessageLinked(LINK_SET, showFumes, "STARTCOOKING", NULL_KEY);
    }
}

refresh(integer force)
{
    debug("refresh:lang=" +languageCode);
    if ((consuming == TRUE) || (force == TRUE))
    {
        integer ts = llGetUnixTime();
        fuel_level -= (float)(ts - lastTs) / (60);
        energy += (float)(ts - lastTs) / (60);
        debug("fuel_level="+(string)fuel_level +"  energy="+(string)energy);
        if(energy >9.5)
        {
            llRegionSay(ENERGY_CHANNEL, "ADDENERGY|"+PASSWORD);
            energy = 0.0;
            debug("Sending energy...");
        }
        if (fuel_level<0.0) fuel_level = 0.0;
        if (fuel_level <= 0.0)
        {
            generatorOff();
            fuel_level = 0.0;
        }
        lastTs = ts;
        saveData();
    }
    showFuelLevel();
}


default
{
    listen(integer c, string nm, key id, string m)
    {
        debug("listen:"+m);
        if (m == "CLOSE")
        {
            checkListen(TRUE);
        }
        else if (m == TXT_ADD_FUEL)
        {
            status = "WaitFuel";
            if (llGetListLength(FUEL_LIST) == 1)
            {
                lookingFor = llList2String(FUEL_LIST, 0);
                llSensor(lookingFor, "",SCRIPTED,  scanRange, PI);
            }
            else
            {
                lookingFor = "all";
                llSensor("", "", SCRIPTED, scanRange, PI);
            }
            checkListen(TRUE);
        }
        else if (m == TXT_STOP)
        {
            generatorOff();
            checkListen(TRUE);
        }
         else if (m == TXT_START)
         {
            generatorOn();
            checkListen(TRUE);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
            checkListen(TRUE);
        }
        else if (status == "WaitFuel")
        {
            if (m == ">>")
            {
                startOffset += 10;
            }
            else
            {
                status = "GetFuel";
                lookingFor = "SF "+m;
                llSensor(lookingFor, "",SCRIPTED,  scanRange, PI);
                checkListen(TRUE);
            }
        }
    }

    dataserver(key kk, string m)
    {
        debug("dataserver:" +m);
        list tk = llParseStringKeepNulls(m , ["|"], []);
        if (llList2String(tk,1) != PASSWORD)  { llOwnerSay(TXT_BAD_PASSWORD); return;  }
        string cmd = llList2String(tk,0);

        if (cmd == "WOOD") // Add wood & start generator
        {
            fuel_level = 100.0;
            generatorOn();
        }
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

    timer()
    {
        refresh(FALSE);
        llSetTimerEvent(60);
        checkListen(FALSE);
    }

    touch_start(integer n)
    {
        lastUser = llDetectedKey(0);
        list opts = [];
        if (consuming == TRUE) opts += TXT_STOP; else if (fuel_level >9) opts += TXT_START;
        opts += [TXT_ADD_FUEL, TXT_LANGUAGE, TXT_CLOSE];
        startListen();
        llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
    }

    sensor(integer n)
    {
        if (lookingFor == "all")
        {
            list buttons = [];
            while (n--)
            {
                string fullName = llKey2Name(llDetectedKey(n));
                string shortName = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);

                if (llListFindList(FUEL_LIST, [fullName]) != -1 && llListFindList(buttons, [shortName]) == -1)
                {
                    buttons += [shortName];
                }
            }
            if (buttons == [])
            {
                if (selitems == [])
                {
                    llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND);
                }
                checkListen(TRUE);
            }
            else
            {
                startListen();
                multiPageMenu(lastUser, TXT_ADD_FUEL, buttons);
            }
            return;
        }
        //get first product that isn't already selected and has enough percentage
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (llListFindList(FUEL_LIST, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
            {
                ready_obj = llDetectedKey(c);
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llRegionSayTo(lastUser, 0, lookingFor + " " + TXT_NOT_FOUND100);
            return;
        }
        selitems += [ready_obj];
        llRegionSayTo(lastUser, 0, TXT_FUEL_FOUND +"  " +lookingFor);
        messageObj(ready_obj, "DIE|"+(string)ownKey);
        fuel_level += 10.0;
        showFuelLevel();
        saveData();
    }

    no_sensor()
    {
        if (lookingFor == "all" && selitems == [])
        {
            llRegionSayTo(lastUser, 0, TXT_FUEL_FOUND);
        }
        else
        {
            llRegionSayTo(lastUser, 0, lookingFor +" " +TXT_NOT_FOUND100);
        }
        checkListen(TRUE);
    }


    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message:"+str);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh(FALSE);
        }
    }

    state_entry()
    {
        llSetText("", ZERO_VECTOR, 0);
        loadConfig();
        loadLanguage(languageCode);
        consuming = TRUE;
        generatorOff();
        lastUser = NULL_KEY;
        ownKey = llGetKey();
        lastTs = llGetUnixTime();
        showFuelLevel();
        llSetTimerEvent(1);
    }

    on_rez(integer n)
    {
        llResetScript();
    }


}
