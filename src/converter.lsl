// CHANGE LOG
// Fixed not loading non en-GB lang at startup


// converter.lsl

float VERSION = 4.3;     // 17 November 2020
integer RSTATE = 1;     // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// Default values - can be overridden by config notecard
integer SENSOR_DISTANCE = 10;       // SENSOR_DISTANCE
float minHeight = -1;               // MIN_HEIGHT
float maxHeight = 1;                // MAX_HEIGHT
integer ONE_PART = 10;              // ONE_PART=10          For non-compostable mode, percent increase for each item added
vector rezzPosition;                // REZ_POSITION         Where to rez it
list acceptItems = [];              // ITEMS=ANY            What goes in
string TXT_PRODUCT = "SF Compost";  // PRODUCT=SF Compost   What comes out
string languageCode = "en-GB";      // LANG
//
// Mulitlingual support - defaults
string TXT_ADD = "Add";
string TXT_ADDED = "Added";
string TXT_ADDING = "Adding";
string TXT_CLOSE = "CLOSE";
string TXT_CONGRATULATION = "Here is your";
string TXT_SELECT = "Select";
string TXT_SELECT_ITEM = "Select item to use";
string TXT_TRYING = "Trying";
string TXT_LEVEL = "level is now";
string TXT_PROGRESS = "Progress";
string TXT_NOTHING_FOUND = "Nothing found to use! Make sure it is close";
string TXT_TOO_FRESH = "This is too fresh to use";
string TXT_BAD_PASSWORD = "Bad password";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "C2";
string PASSWORD="*";
integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

string productName;
integer productPercent;
float level;
integer listener=-1;
integer listenTs;
integer startOffset=0;
key dlgUser = NULL_KEY;

integer lastTs;
string lookingFor;
list selitems = [];
string status;
integer repeat;

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


messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llGetListLength(check) != -1) osMessageObject(objId, msg);
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
                    PSYS_SRC_BURST_PART_COUNT, 10,
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

refresh()
{
    integer ts = llGetUnixTime();
    integer i;
    if (ts- lastTs > 86400)
    {
        level -= 1;
        if (level <0) level=0;
        lastTs = ts;
    }

    if (level >= 100)
    {
        llSay(0, TXT_CONGRATULATION +" " +TXT_PRODUCT);
        llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)dlgUser +"|" +TXT_PRODUCT, NULL_KEY);
        level =0;
    }

    integer lnk;
    for (lnk=2; lnk <= llGetNumberOfPrims(); lnk++)
    {
        if (llGetLinkName(lnk) == "Compost")
        {
            float lev = level;
            vector p = llList2Vector(llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL]), 0);
            p.z = minHeight + (maxHeight-minHeight)*0.99*lev/100;
            vector c = <0.6, 1.0, 0.6>;
            if (lev < 10) c = <1,0,0>;  else  if (lev<50) c = <1,1,0>;
            string str = "";
            if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
            llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p, PRIM_TEXT,  TXT_PRODUCT +"\n"+TXT_PROGRESS+": " +llRound(lev)+"%\n"+str ,c, 1.0]);
        }
    }
    // Save in object description
    llSetObjectDesc("C;" +(string)level +";" +languageCode);
}

loadConfig()
{
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    if (llGetInventoryType("config") != INVENTORY_NOTECARD) return;
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        list tok = llParseString2List(llList2String(lines,i), ["="], []);
        if (llList2String(tok,1) != "")
        {
            string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
            string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
            if (cmd == "SENSOR_DISTANCE")     SENSOR_DISTANCE = (integer)val;   // How far to look for items
            else if (cmd == "MIN_HEIGHT")     minHeight = (float)val;
            else if (cmd == "MAX_HEIGHT")     maxHeight = (float)val;
            else if (cmd == "ONE_PART")       ONE_PART = (integer)val;
            else if (cmd == "REZ_POSITION")   rezzPosition = (vector)val;
            else if (cmd =="PRODUCT")         TXT_PRODUCT = val;
            else if (cmd == "LANG")           languageCode = val;
            else if (cmd == "ITEMS")
            {
                if (llToLower(val) == "any") acceptItems = []; else acceptItems = [] + llParseString2List(val, [","], []);
            }
        }
    }
    if (ONE_PART <1) ONE_PART = 1;
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "C")
    {
        level = llList2Float(desc, 1);
        languageCode = llList2String(desc, 2);
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    debug("loadLanguage asked for " + TXT_LANGUAGE + " " +languageNC);
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
                         if (cmd == "TXT_ADD")  TXT_ADD = val;
                    else if (cmd == "TXT_ADDED") TXT_ADDED = val;
                    else if (cmd == "TXT_ADDING") TXT_ADDING = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_CONGRATULATION") TXT_CONGRATULATION = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_SELECT_ITEM") TXT_SELECT_ITEM = val;
                    else if (cmd == "TXT_TRYING") TXT_TRYING = val;
                    else if (cmd == "TXT_LEVEL") TXT_LEVEL = val;
                    else if (cmd == "TXT_NOTHING_FOUND") TXT_NOTHING_FOUND = val;
                    else if (cmd == "TXT_TOO_FRESH") TXT_TOO_FRESH = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                    else if (cmd == "TXT_BAD_PASSWORD")    TXT_BAD_PASSWORD = val;
                }
            }
        }
    }
}


default
{

    listen(integer c, string nm, key id, string m)
    {
        if (m == TXT_CLOSE)
        {
            refresh();
            return;
        }
        else if (m == TXT_ADD)
        {
            dlgUser = id;
            status = "WaitSearch";
            if (llGetListLength(acceptItems) == 0)
            {
                status = "WaitSearchAny";
            }
            else
            {
                status = "WaitSearchSpecific";
                lookingFor = "all";
            }
            llSensor("", "",SCRIPTED,  SENSOR_DISTANCE, PI);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if ((status == "WaitSelection") || (status == "WaitSelectionSpecific"))
        {
            lookingFor = "SF "+m;
            if (status == "WaitSelection") status = "WaitItem"; else status ="WaitItemSpecific";
            llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
        }
    }

    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD ) { llOwnerSay(TXT_BAD_PASSWORD); return; }

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
            llResetScript();
        }
        else if (cmd == "PRODSTATUS")
        {
            //
        }
        else
        {
            if (llToUpper(productName) ==  cmd)
            {
                if (status =="WaitItemSpecific")
                {
                    level += ONE_PART;
                }
                else
                {
                    // Fill up
                    integer add = productPercent/2;
                    if (add >15) add = 10;
                    level +=  add;
                    if (level>100) level = 100;
                }
                llSay(0, TXT_ADDED +" " +llToLower(cmd) +", " +TXT_LEVEL +llRound(level)+"%");
                refresh();
                if (llGetListLength(acceptItems) == 0) status = "WaitSearchAny"; else status = "WaitSearchSpecific";
                lookingFor = "all";
                repeat = TRUE;
                llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
            }
        }
    }

    timer()
    {
        refresh();
        checkListen();
        llSetTimerEvent(1000);
    }

    touch_start(integer n)
    {
        list opts = [];
        opts += [TXT_ADD, TXT_LANGUAGE, TXT_CLOSE];
        startListen();
        dlgUser = llDetectedKey(0);
        status = "";
        llDialog(dlgUser, TXT_SELECT, opts, chan(llGetKey()));
        llSetTimerEvent(300);
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
                llRegionSayTo(dlgUser, 0, TXT_NOTHING_FOUND);
                status = "";
            }
            else
            {
                status = "WaitSelection";
                llDialog(dlgUser,  TXT_SELECT_ITEM, [TXT_CLOSE] + foundList, chan(llGetKey()));
            }
        }
        else if ((status == "WaitItem") || ( status == "WaitItemSpecific"))
        {
            key id = llDetectedKey(0);
            llRegionSayTo(dlgUser, 0, TXT_TRYING +" "+lookingFor+"...");
            string desc= llList2String(llGetObjectDetails(llDetectedKey(0), [OBJECT_DESC]), 0);
            list parts = llParseString2List(desc, [";"], []);
            if (llList2String(parts,0) == "P")
            {
                productPercent = llList2Integer(parts,1);
                integer productTimeleft = llList2Integer(parts,2);
                if ( (productPercent <100) || (productTimeleft <2) || (status =="WaitItemSpecific") )
                {
                    llRegionSayTo(dlgUser, 0, TXT_ADDING +" "+llDetectedName(0)+"...");
                    productName = llGetSubString(llDetectedName(0), 3, -1);
                    messageObj(id, "DIE|"+llGetKey()+"|"+(string)productPercent);
                }
                else
                {
                    status = "";
                    llRegionSayTo(dlgUser, 0, lookingFor + ": " +TXT_TOO_FRESH);
                    return;
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

                    if (llListFindList(acceptItems, [fullName]) != -1 && llListFindList(buttons, [shortName]) == -1)
                    {
                        buttons += [shortName];
                    }
                }
                if (buttons == [])
                {
                    if (selitems == [])
                    {
                        if (repeat == FALSE) llRegionSayTo(dlgUser, 0, TXT_NOTHING_FOUND);
                        repeat = FALSE;
                    }
                    checkListen();
                }
                else
                {
                    status = "WaitSelectionSpecific";
                    llDialog(dlgUser,  TXT_SELECT, [TXT_CLOSE] + buttons, chan(llGetKey()));
                }
                return;
            }
        }
    }

    no_sensor()
    {
        llRegionSayTo(dlgUser, 0, TXT_NOTHING_FOUND);
        status = "";
    }

    state_entry()
    {
        lastTs = llGetUnixTime();
        level = 10;
        loadConfig();
        loadLanguage(languageCode);
        dlgUser = llGetOwner();
        llSetTimerEvent(1);
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|" +PASSWORD);
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
            refresh();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
