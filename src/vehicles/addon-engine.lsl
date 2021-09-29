// addon-engine.lsl
//  Plugin to allow vehicles to use any type of 'SF fuel'
//
// First add the notecards  config & sfp
// Then add this plugin

float VERSION = 1.1;     // 21 November 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// these can be overriden with config notecard
vector sitTarget = <0.0, 0.0, 0.1>; // SIT_TARGET=<0,0,0.1>  >> Sit position adjustment
integer initial_level   = 50;       // INITIAL_LEVEL=50      >> Initial percentage of fuel
integer         AMOUNT  = 5;        // AMOUNT=5              >> How much fuel to use each drop time
integer     drop_time   = 60;       // DROP_TIME=1           >> How often (in minutes) to reduce fuel by AMOUNT
integer  health_value   = 0;        // HEALTH=0              >> Can set a number + or - to be applied each drop time
list        fuel_types  = [];       // FUEL=Petrol,Oil       >> Comma or semicolon separated list of fuels
integer SENSOR_DISTANCE = 10;       // SENSOR_DISTANCE=10    >> Radius in m to scan for fuel
integer mode = 3;                   // MODE=All              >> Can be OWNER (1), GROUP (2) or ALL (3)
vector  txtColour = <1,1,1>;        // TXT_COLOR=<1,1,1>     >> Float text colour - set as color vector or use  OFF  for no float text
integer handleTouch = TRUE;         // HANDLE_TOUCH=YES      >> If YES, respond to touch otherwise ignore touch
string languageCode = "en-GB";      // LANG=en-GB            >> Default language
string  SF_PREFIX = "SF";           // SF_PREFIX=SF          >> If your products start with a different prefix set it here
string  lnkCmd_Gear = "";
//
// Multilingual support
string TXT_ADD_FUEL = "Add fuel";
string TXT_CLOSE = "CLOSE";
string TXT_MENU = "MENU";
string TXT_SELECT = "Select";
string TXT_TRYING = "Trying";
string TXT_ADDING = "Adding";
string TXT_ADDED = "Added";
string TXT_LEVEL = "Level is now";
string TXT_EMPTY = "Out of fuel!";
string TXT_FUEL_LEVEL = "Fuel level";
string TXT_NOT_ALLOWED = "Sorry, you are not allowed to use this";
string TXT_NOTHING_FOUND = "No fuel found nearby";
string TXT_ERROR_FUEL = "ERROR: No fuel types set!";
string TXT_ERROR_GROUP = "Error, we are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_LANGUAGE = "@";
//
string SUFFIX = "E2";

string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer seated;
list    avatarIDs = [];
key     avatarID;
integer fuel;
integer listener=-1;
integer listenTs;
integer startOffset=0;
string  status;
string  lookingFor;
string  productName;
integer productPercent;
list    selitems = [];
integer repeat;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llGetListLength(check) != -1) osMessageObject(objId, msg);
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
                     if (cmd == "INITIAL_LEVEL")    initial_level = (integer)val;
                else if (cmd == "AMOUNT")           AMOUNT = (integer)val;
                else if (cmd == "DROP_TIME")        drop_time = (integer)val*60;
                else if (cmd == "HEALTH")           health_value = (integer)val;
                else if (cmd == "FUEL")             fuel_types = llParseString2List(val, [";", ","], []);
                else if (cmd == "SENSOR_DISTANCE")  SENSOR_DISTANCE = (integer)val;
                else if (cmd == "SIT_TARGET")       sitTarget = (vector)val;
                else if (cmd == "LANG")             languageCode = val;
                else if (cmd == "SF_PREFIX")        SF_PREFIX = val;
                else if (cmd == "HANDLE_TOUCH")
                {
                    if (llToUpper(val) == "YES") handleTouch = TRUE; else handleTouch = FALSE;
                }
                else if (cmd == "MODE")
                {
                    string value = llToUpper(val);
                    if (value == "OWNER") mode = 1; else if (value == "GROUP") mode =2; else mode =3;
                }
                else if (cmd == "TXT_COLOR")
                {
                    if ((val == "ZERO_VECTOR") || (val == "OFF"))
                    {
                        txtColour = ZERO_VECTOR;
                    }
                    else
                    {
                        txtColour = (vector)val;
                        if (txtColour == ZERO_VECTOR) txtColour = <1,1,1>;
                    }
                }
            }
        }
    }
    if (llGetListLength(fuel_types) == 0) llOwnerSay(TXT_ERROR_FUEL);
    if (AMOUNT < 1) AMOUNT = 1;
    if (drop_time < 60) drop_time = 60;
    if (sitTarget == ZERO_VECTOR) sitTarget = <0.0, 0.0, 0.1>;
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    //if (llGetInventoryType(languageNC) != INVENTORY_NOTECARD) languageNC = "en-GB-lang"+SUFFIX;
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
                         if (cmd == "TXT_ADD_FUEL")         TXT_ADD_FUEL = val;
                    else if (cmd == "TXT_ERROR_FUEL")       TXT_ERROR_FUEL = val;
                    else if (cmd == "TXT_CLOSE")            TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT")           TXT_SELECT = val;
                    else if (cmd == "TXT_MENU")             TXT_MENU = val;
                    else if (cmd == "TXT_TRYING")           TXT_TRYING = val;
                    else if (cmd == "TXT_ADDING")           TXT_ADDING = val;
                    else if (cmd == "TXT_ADDED")            TXT_ADDED = val;
                    else if (cmd == "TXT_LEVEL")            TXT_LEVEL = val;
                    else if (cmd == "TXT_FUEL_LEVEL")       TXT_FUEL_LEVEL = val;
                    else if (cmd == "TXT_NOTHING_FOUND")    TXT_NOTHING_FOUND = val;
                    else if (cmd == "TXT_EMPTY")            TXT_EMPTY = val;
                    else if (cmd == "TXT_NOT_ALLOWED")      TXT_NOT_ALLOWED = val;
                    else if (cmd == "TXT_ERROR_GROUP")      TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE")     TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE")         TXT_LANGUAGE = val;
                }
            }
        }
    }
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

particles()
{
    integer flags = 0;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,2,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, <1.000, 0.800, 0.900>,
                        PSYS_PART_END_COLOR, <0.318, 0.000, 0.633>,
                        PSYS_PART_START_SCALE,<0.25, 0.25, 1>,
                        PSYS_PART_END_SCALE,<1.5, 1.5, 1>,
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_SRC_BURST_RATE,0.1,
                        PSYS_SRC_ACCEL, <0.0, 0.0, -0.5>,
                        PSYS_SRC_BURST_PART_COUNT,2,
                        PSYS_SRC_BURST_RADIUS,1.0,
                        PSYS_SRC_BURST_SPEED_MIN,0.0,
                        PSYS_SRC_BURST_SPEED_MAX,0.05,
                        PSYS_SRC_TARGET_KEY,llGetOwner(),
                        PSYS_SRC_INNERANGLE,0.65,
                        PSYS_SRC_OUTERANGLE,0.1,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 2,
                        PSYS_SRC_TEXTURE, "",
                        PSYS_PART_START_ALPHA, 0.5,
                        PSYS_PART_END_ALPHA, 0.0
                    ]);
}

doTouch(key toucher)
{
    // integer mode  >> Can be OWNER (1), GROUP (2) or ALL (3)
    integer allowed = FALSE;
         if ((mode == 1) && (toucher == llGetOwner())) allowed = TRUE;
    else if ((mode == 2) && (llSameGroup(toucher) == TRUE)) allowed = TRUE;
    else if (mode == 3) allowed = TRUE;

    if (allowed == TRUE)
    {
        list opts = [];
        opts += [TXT_ADD_FUEL, TXT_LANGUAGE, TXT_CLOSE];
        startListen();
        avatarID = toucher;
        status = "";
        llDialog(avatarID, "\n>>   "+TXT_FUEL_LEVEL +": "+(string)fuel+"%   <<\n \n" +TXT_SELECT, opts, chan(llGetKey()));
        llSetTimerEvent(60);
    }
    else
    {
        llRegionSayTo(toucher, 0, TXT_NOT_ALLOWED);
    }
}

refresh()
{
    checkListen();
    llMessageLinked(LINK_SET, fuel, "FUEL_LEVEL", "");
    if (txtColour != ZERO_VECTOR) llSetText(TXT_FUEL_LEVEL +": "+(string)fuel+"%", txtColour, 1.0);
}

init()
{
    llSetText("", ZERO_VECTOR, 0);
    integer index;
    integer count = llGetListLength(avatarIDs);
    for (index = 0 ; index < count; index++)
    {
        llUnSit(llList2Key(avatarIDs, index));
    }
    llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
    seated = FALSE;
    avatarIDs = [];
    loadConfig();
    loadLanguage(languageCode);
    llSitTarget(sitTarget, ZERO_ROTATION);
    if (handleTouch == TRUE)
    {
        llSetTouchText(TXT_MENU);
    }
    else
    {
        llMessageLinked(LINK_SET, 1, "ADD_MENU_OPTION|"+TXT_ADD_FUEL, "");
        llMessageLinked(LINK_SET, 1, "ADD_MENU_OPTION|"+TXT_FUEL_LEVEL, "");
    }
    refresh();
}



default
{
    state_entry()
    {
        init();
        fuel = initial_level;
        refresh();
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("listen:"+m + " ID="+(string)id);
        if (m == TXT_CLOSE)
        {
            refresh();
        }
        else if (m == TXT_ADD_FUEL)
        {
            avatarID = id;
            status = "WaitSearchSpecific";
            lookingFor = "all";
            llSensor("", "",SCRIPTED,  SENSOR_DISTANCE, PI);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "MENU_LANGS|" + SUFFIX, id);
        }
        else if ((status == "WaitSelection") || (status == "WaitSelectionSpecific"))
        {
            lookingFor = SF_PREFIX +" "+m;
            if (status == "WaitSelection") status = "WaitItem"; else status ="WaitItemSpecific";
            llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
        }
    }

    sensor(integer n)
    {
        debug("sensor: status=" +status +"  lookingFor="+lookingFor);
        if (status == "WaitSearchAny")
        {
            integer i;
            list names;
            list foundList = [];
            for (i=0; i < 10; i++)
            {
                if (llGetSubString(llDetectedName(i),0, 2) == "SF ")
                {
                    string desc= llList2String(llGetObjectDetails(llDetectedKey(i), [OBJECT_DESC]), 0);
                    string name = llGetSubString(llDetectedName(i), 3,-1);
                    if (llGetSubString(desc, 0,1) == "P;")
                    {
                        if (llListFindList(foundList, [name]) == -1) foundList+= llGetSubString(llDetectedName(i), 3,-1); // Add everything
                    }
                }
            }
            if (llGetListLength(foundList)==0)
            {
                llRegionSayTo(avatarID, 0, TXT_NOTHING_FOUND);
                status = "";
            }
            else
            {
                status = "WaitSelection";
                llDialog(avatarID,  TXT_SELECT, [TXT_CLOSE] +foundList, chan(llGetKey()));
            }
        }
        else if ((status == "WaitItem") || ( status == "WaitItemSpecific"))
        {
            key id = llDetectedKey(0);
            llRegionSayTo(avatarID, 0, TXT_TRYING +" "+lookingFor+"...");
            string desc= llList2String(llGetObjectDetails(llDetectedKey(0), [OBJECT_DESC]), 0);
            list parts = llParseString2List(desc, [";"], []);
            if (llList2String(parts,0) == "P")
            {
                productPercent = llList2Integer(parts,1);
                integer productTimeleft = llList2Integer(parts,2);
                if ( (productPercent <100) || (productTimeleft <2) || (status =="WaitItemSpecific") )
                {
                    llRegionSayTo(avatarID, 0, TXT_ADDING +" "+llDetectedName(0)+"...");
                    productName = llGetSubString(llDetectedName(0), 3, -1);
                    messageObj(id, "DIE|"+llGetKey()+"|"+(string)productPercent);
                }
                else
                {
                    status = "";
                    //llRegionSayTo(avatarID, 0, lookingFor + ": " +TXT_TOO_FRESH);
                }
            }
        }
        else
        {
            //specifics  status = WaitSearchSpecific
            if (lookingFor == "all")
            {
                list buttons = [];
                while (n--)
                {
                    string fullName = llKey2Name(llDetectedKey(n));
                    string shortName = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);

                    if (llListFindList(fuel_types, [shortName]) != -1 && llListFindList(buttons, [shortName]) == -1)
                    {
                        buttons += [shortName];
                    }
                }
                if (buttons == [])
                {
                    if (selitems == [])
                    {
                        if (repeat == FALSE) llRegionSayTo(avatarID, 0, TXT_NOTHING_FOUND);
                        repeat = FALSE;
                    }
                    checkListen();
                }
                else
                {
                    status = "WaitSelectionSpecific";
                    llDialog(avatarID,  TXT_SELECT, [TXT_CLOSE] + buttons, chan(llGetKey()));
                }
            }
        }
    }

    no_sensor()
    {
        llRegionSayTo(avatarID, 0, TXT_NOTHING_FOUND);
        status = "";
    }

    touch_end(integer index)
    {
        if (handleTouch == TRUE) doTouch(llDetectedKey(0));
    }

    timer()
    {
        if (seated == TRUE)
        {
            integer i;
            integer j = llGetListLength(avatarIDs);
            float prog;
            for (i = 0; i < j; i += 2)
            {
                avatarID = llList2Key(avatarIDs, i);
                prog = ((llGetUnixTime()-llList2Float(avatarIDs, i+1))*100.0)/drop_time;
                if (prog >= 100.0)
                {
                    avatarID = llList2Key(avatarIDs, i);
                    if (health_value != 0) llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)avatarID +"|Health|" +(string)health_value);
                    // Use some fuel
                    fuel -= AMOUNT;
                    if (fuel < 1) fuel = 0;
                    refresh();
                    if (fuel == 0)
                    {
                        // Run out of fuel so unsit them then remove from list of avatars using this
                        llUnSit(avatarID);
                        llRegionSayTo(avatarID, 0, TXT_EMPTY);
                        avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
                    }
                    else
                    {
                        // Remove and then add back in so their timer starts again
                        i = llListFindList(avatarIDs,[avatarID]);
                        if (i != -1)
                        {
                            avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
                            avatarIDs += [avatarID, llGetUnixTime()];
                        }
                    }
                }
            }
            if (llGetListLength(avatarIDs) != 0)
            {
                particles();
                llSetTimerEvent(30);
            }
            else
            {
                seated = FALSE;
                llSetTimerEvent(0.1);
            }
        }
        else
        {
            llSetTimerEvent(0.0);
            avatarIDs = [];
            init();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message: " + str +" num="+(string)num);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "DO_TOUCH")
        {
            doTouch(id);
        }
        else if (cmd == "MENU_OPTION")
        {
            if (llList2String(tk, 1) == TXT_ADD_FUEL)
            {
                avatarID = id;
                status = "WaitSearchSpecific";
                lookingFor = "all";
                startListen();
                llSensor("", "",SCRIPTED,  SENSOR_DISTANCE, PI);
            }
            else if (llList2String(tk, 1) == TXT_FUEL_LEVEL)
            {
                llRegionSayTo(id, 0, TXT_FUEL_LEVEL +": " +(string)fuel +"%");
            }
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh();
        }
    }

    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) == PASSWORD)
        {
            if (cmd == "VERSION-CHECK")
            {
                string answer = "VERSION-REPLY|" + PASSWORD + "|";
                integer ver = (integer)(VERSION*10);
                answer += (string)llGetKey() + "|" + (string)ver + "|";
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
                init();
            }
            else
            {
                if (llToUpper(productName) ==  cmd)
                {
                    fuel += 50;
                    if (fuel > 100) fuel = 100;
                    llSay(0, TXT_ADDED +" " +llToLower(cmd) +", " +TXT_LEVEL +" " +(string)fuel+"%");
                    status = "";
                    refresh();
                }
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            integer result = llGetListLength(avatarIDs);
            result = (integer)(result *0.5);
            integer count = llGetNumberOfPrims();
            integer i;
            key avTest;
            if (count > llGetObjectPrimCount(llGetKey()) + result)
            {
                // check if someone sat
                for (i = 0; i < count; i++)
                {
                    avTest = llAvatarOnLinkSitTarget(i);
                    if ((avTest != NULL_KEY) && (osIsNpc(avTest) == FALSE))
                    {
                        result = llListFindList(avatarIDs, [avTest]);
                        if (result == -1)
                        {
                            if (seated == FALSE)
                            {
                                // first sitter
                                seated = TRUE;
                                llMessageLinked(LINK_SET,90, "STARTCOOKING", "");
                            }
                            avatarIDs += [avTest, llGetUnixTime()];
                        }
                    }
                }
                llSetTimerEvent(30);
            }
            else
            {
                // check if someone stood up
                integer j;
                for (i=0; i < llGetListLength(avatarIDs); i+=2)
                {
                    avTest = llList2Key(avatarIDs, i);
                    result = 0;
                    for (j=0; j < llGetNumberOfPrims(); j+=1)
                    {
                        if (llAvatarOnLinkSitTarget(j) == avTest) result = 1;
                    }
                    if (result == 0) avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
                }
            }
            //
            if (llGetNumberOfPrims() == llGetObjectPrimCount(llGetKey()))
            {
                // No one left sitting
                llSetTimerEvent(0);
                llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
                init();
            }
        }

        if (change & CHANGED_INVENTORY)
        {
            init();
        }
    }

}
