// This script is used for the chicken coop to produce eggs and chicken meat
//--
float VERSION = 4.0;  // 29 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// config notecard can override these
vector rezzPosition = <0.0, 1.5, 2.0>;   // REZ_POSITION=<0.0, 1.5, 2.0>   (where to rez product)
list    FOODITEMS = [];                  // Product to accept as food. There can be multiple FOOD= lines if the feeder can accept multiple foods
string  FOODITEM =   "Corn";             // FOODITEM=Corn
string  FOODTOWER =  "SF Storage Rack";  // FOODTOWER=SF Storage Rack
string  WATERITEM =  "Water";            // WATERITEM=Water
string  WATERTOWER = "SF Water Tower";   // WATERTOWER=SF Water Tower
integer floatText = TRUE;                // FLOAT_TEXT=1
string  languageCode = "en-GB";          // LANG=en-GB
// Language support
string TXT_EMPTYING = "Emptying";
string TXT_DONE_AUTOFOOD = "Auto-food completed";
string TXT_DONE_AUTOWATER = "Auto-water completed";
string TXT_LOOKING_FOR = "Looking for";
string TXT_EGGS = "Eggs";
string TXT_EGGS_READY = "Your eggs are ready!";
string TXT_CHICKEN = "Chicken meat";
string TXT_CHICKEN_READY = "Your chicken is ready!";
string TXT_NEEDS_FOOD = "NEEDS FOOD!";
string TXT_NEEDS_WATER = "NEEDS WATER!";
string TXT_STATUS = "Status";
string TXT_FOOD = "Food";
string TXT_WATER = "Water";
string TXT_HELP = "Help!";
string TXT_ADD = "Add";
string TXT_GET = "Get";
string TXT_AUTOFOOD = "AutoFood";
string TXT_AUTOWATER = "AutoWater";
string TXT_ON = "On";
string TXT_OFF = "Off";
string TXT_CLOSE = "CLOSE";
string TXT_SELECT = "Select";
string TXT_NO_TOWER = "Error! Required tower not found within range";
string TXT_NOT_FOUND = "Error! Item not found nearby, please bring it closer";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string TXT_STATUS_DEAD = "Dead";
string TXT_STATUS_EMPTY = "Empty";
//
string SF_EGGS = "SF Eggs";
string SF_CHICKEN = "SF Chicken";
//
string SUFFIX = "C1";

string status="OK";
string PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer createdTs =0;
integer lastTs=0;
integer statusTs;
string sense;
integer autoWater = 0;
integer autoFood = 0;
string lookFor;
float water = 20.0;
float food = 20.0;
float meat = 0.0;
float eggs = 0.0;
float EGGSTIME = 86400.0;
float MEATTIME = 259200.0;
float WATER_TIMES = 0.3; // Per day
key toucher = NULL_KEY;

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
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                         if (cmd == "REZ_POSITION")   rezzPosition = (vector)val;
                    else if (cmd == "FOODTOWER")      FOODTOWER = val;
                    else if (cmd == "WATERTOWER")     WATERTOWER = val;
                    else if (cmd == "FOODITEM")       FOODITEM = val;
                    else if (cmd == "WATERITEM")      WATERITEM = val;
                    else if (cmd == "FLOAT_TEXT")     floatText = (integer)val;
                    else if (cmd == "LANG")           languageCode = val;
                }
            }
        }
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
                         if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_DONE_AUTOFOOD") TXT_DONE_AUTOFOOD = val;

                    else if (cmd == "TXT_DONE_AUTOWATER") TXT_DONE_AUTOWATER = val;
                    else if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_EGGS") TXT_EGGS = val;
                    else if (cmd == "TXT_EGGS_READY") TXT_EGGS_READY = val;
                    else if (cmd == "TXT_CHICKEN") TXT_CHICKEN = val;
                    else if (cmd == "TXT_CHICKEN_READY") TXT_CHICKEN_READY = val;
                    else if (cmd == "TXT_NEEDS_FOOD") TXT_NEEDS_FOOD = val;
                    else if (cmd == "TXT_NEEDS_WATER") TXT_NEEDS_WATER = val;
                    else if (cmd == "TXT_STATUS") TXT_STATUS = val;
                    else if (cmd == "TXT_FOOD") TXT_FOOD = val;
                    else if (cmd == "TXT_WATER") TXT_WATER = val;
                    else if (cmd == "TXT_HELP") TXT_HELP = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_GET") TXT_GET = val;
                    else if (cmd == "TXT_AUTOFOOD") TXT_AUTOFOOD = val;
                    else if (cmd == "TXT_AUTOWATER") TXT_AUTOWATER = val;
                    else if (cmd == "TXT_ON") TXT_ON = val;
                    else if (cmd == "TXT_OFF") TXT_OFF = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_NO_TOWER") TXT_NO_TOWER = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

psys()
{
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    //PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<.4000000,.900000,.400000>,
                    PSYS_PART_END_COLOR,<8.000000,1.00000,8.800000>,

                    PSYS_PART_START_ALPHA,.6,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<.5000000,.5000000,0.000000>,
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
                       // PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
        llTriggerSound(llGetInventoryName(INVENTORY_SOUND, (integer)llFrand(llGetInventoryNumber(INVENTORY_SOUND))), 1.0);
}

refresh()
{
    water -=  (float)(llGetUnixTime() - lastTs)/(86400/WATER_TIMES)*100.;
    food -=  (float)(llGetUnixTime() - lastTs)/(86400/WATER_TIMES)*100.;
    if (water<0) water=0;
    if (food<0) food =0;

    integer isWilted;
    string progress;

    if (status == "Dead" || status == "Empty")
    {
        //
    }
    else if (water < 5. || food < 5.)
    {
        if (water<5)   progress += TXT_NEEDS_WATER +"\n";
        if (food <5)   progress +=  TXT_NEEDS_FOOD +"\n";
        isWilted=1;

        if (water <5 && autoWater)
        {
            sense = "WaitAutoWater";
            lookFor = WATERTOWER;
            llSensor(lookFor, "" , SCRIPTED, 96, PI);
            llWhisper(0, TXT_LOOKING_FOR +": " +WATERTOWER +"...");
        }
        else if (food <5 && autoFood)
        {
            lookFor =  FOODTOWER; //"SF Storage Rack";
            sense = "WaitAutoFood";
            llSensor(lookFor, "", SCRIPTED, 96, PI);
            llWhisper(0, TXT_LOOKING_FOR +": " +FOODTOWER +"...");
        }
    }
    else
    {
        eggs +=  (float)(llGetUnixTime() - statusTs)/(EGGSTIME)*100.;
        meat +=  (float)(llGetUnixTime() - statusTs)/(MEATTIME)*100.;
        if (eggs >100) eggs = 100;
        if (meat >100) meat = 100;
        statusTs = llGetUnixTime();
    }

    if (status == "Dead" || status == "Empty")
    {
        progress += TXT_STATUS +": ";
        if (status == "Dead") progress += TXT_STATUS_DEAD; else progress += TXT_STATUS_EMPTY;
        progress += "\n";
    }
    else
    {
       progress += TXT_EGGS +": "+(string)llRound(eggs)+"%\n" +TXT_CHICKEN +": "+(string)llRound(meat)+"%\n";
    }

    vector col = <1,1,1>;
    if (isWilted)
    {
        col = <1,0,0>;
        llOwnerSay(TXT_HELP);
    }

    llSetText(TXT_FOOD +": "+(string)((integer)food) + "% \n" +TXT_WATER +": " + (string)((integer)(water))+ "%\n"+progress, col, 1.0);

    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(2, [PRIM_SIZE]), 0);
    v.z = 0.34* food/100.;
    llSetLinkPrimitiveParamsFast(2, [PRIM_SIZE, v]);

    v = llList2Vector(llGetLinkPrimitiveParams(3, [PRIM_SIZE]), 0);
    v.z = 0.34* water/100.;
    llSetLinkPrimitiveParamsFast(3, [PRIM_SIZE, v]);

    psys();
}


default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(0.3);
        messageObj(id,  "INIT|"+PASSWORD);
    }

    state_entry()
    {
        lastTs = llGetUnixTime();
        createdTs = lastTs;
        statusTs = lastTs;
        status = "OK";
        refresh();
        llSetTimerEvent(1);
        loadConfig();
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            toucher = llDetectedKey(0);
            list opts = [];
            if (food< 50)  opts += TXT_ADD +": " +FOODITEM;
            if (water< 50)  opts += TXT_ADD +": " +TXT_WATER;
            if (eggs>=100)  opts += TXT_GET +": " +TXT_EGGS;
            if (meat>=100)  opts += TXT_GET +": " +TXT_CHICKEN;
            if (autoWater) opts += "-"+TXT_AUTOWATER; else opts += "+"+TXT_AUTOWATER;
            if (autoFood) opts += "-"+TXT_AUTOFOOD; else opts += "+"+TXT_AUTOFOOD;
            opts += [TXT_LANGUAGE, TXT_CLOSE];
            startListen();
            llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
            llSetTimerEvent(300);
        }
        else llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
    }

    listen(integer c, string n ,key id , string m)
    {
        debug("listen: " +m);
        if (m == TXT_ADD+": "+WATERITEM)
        {
            lookFor = "SF "+WATERITEM;
            llSensor(lookFor, "", SCRIPTED, 5, PI);
        }
        else if (m == TXT_ADD+": "+FOODITEM)
        {
            lookFor = "SF " + FOODITEM;
            llSensor(lookFor, "", SCRIPTED, 5, PI);
        }
        else if (m == (TXT_GET+": "+TXT_EGGS))
        {
            if (eggs>=100)
            {
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)id +"|" +SF_EGGS, NULL_KEY);
                llRegionSayTo(id, 0, TXT_EGGS_READY);
                llTriggerSound("lap", 1.0);
                eggs=0;
                llSetTimerEvent(1);
            }
        }
        else if (m == (TXT_GET+": "+TXT_CHICKEN))
        {
            if (meat>=100)
            {
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)id +"|" +SF_CHICKEN, NULL_KEY);
                llRegionSayTo(id, 0, TXT_CHICKEN_READY);
                llTriggerSound("lap", 1.0);
                llSetTimerEvent(1);
                meat=0;
            }
        }
        else if (m == "+"+TXT_AUTOWATER || m == "-"+TXT_AUTOWATER)
        {
            if (m == "+"+TXT_AUTOWATER)
            {
                autoWater = TRUE;
                llRegionSayTo(id, 0, TXT_AUTOWATER +": " +TXT_ON);
            }
            else
            {
                autoWater = FALSE;
                llRegionSayTo(id, 0, TXT_AUTOWATER +": " +TXT_OFF);
            }
            llSetTimerEvent(1);
        }
        else if (m == "+"+TXT_AUTOFOOD || m == "-"+TXT_AUTOFOOD)
        {
            if (m == "+"+TXT_AUTOFOOD)
            {
                autoFood = TRUE;
                llRegionSayTo(id, 0, TXT_AUTOFOOD +": " +TXT_ON);
            }
            else
            {
                autoFood = FALSE;
                llRegionSayTo(id, 0, TXT_AUTOFOOD +": " +TXT_OFF);
            }
            llSetTimerEvent(1);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else
        {
            //
        }
    }

    dataserver(key k, string m)
    {
        debug("dataserver: " +m);
        list tk= llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk,1) != PASSWORD) return;
        string cmd = llList2String(tk,0);

        if (cmd == "HAVEWATER")
        {
            llWhisper(0, TXT_DONE_AUTOWATER);
            water = 100;
            psys();
            sense = "";
            llSetTimerEvent(1);
        }
        else if (cmd == "HAVE"  && llList2Key(tk,2)==FOODITEM)
        {
            llWhisper(0, TXT_DONE_AUTOFOOD);
            food =100.0;
            psys();
            sense = "";
            llSetTimerEvent(1);
        }
        else if (cmd == "WATER" )
        {
             water=100.;
            refresh();
        }
        else if (cmd == "CORN" )
        {
            food=100.;
            refresh();
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
            messageObj(llList2Key(cmd, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, TXT_ERROR_UPDATE);
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(cmd, 3);
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
            messageObj(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
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
        integer ts = llGetUnixTime();
        if (ts - lastTs> 0)
        {

            refresh();
            lastTs = ts;
        }
        llSetTimerEvent(200);

        checkListen();
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if (sense== "WaitAutoWater")
        {
            messageObj(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
        }
        else  if (sense == "WaitAutoFood")
        {
            messageObj(id,  "GIVE|"+PASSWORD+"|"+ FOODITEM+"|"+(string)llGetKey());
        }
        else
        {
            llRegionSayTo(toucher, 0,TXT_EMPTYING + "...");
            messageObj(id, "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        if (sense == "WaitAutoWater" || sense == "WaitAutoFood")
            llRegionSayTo(toucher, 0, TXT_NO_TOWER);
        else
            llRegionSayTo(toucher, 0, TXT_NOT_FOUND);
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            refresh();
        }
    }

}
