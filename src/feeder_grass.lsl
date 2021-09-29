// feeder_grass.lsl
//  Grass feeder - self sustaining feeder that just requires a water source
//
float VERSION = 4.1;      // 28 November 2020
integer   RSTATE = 1;     // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = TRUE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}
// Can be changed via CONFIG notecard
string SF_WATER_TOWER = "SF Water Tower";
string SF_WATER = "SF Water";
string languageCode = "en-GB";
//
// Language support
string TXT_LOOKING_FOR_WT = "Looking for water tower...";
string TXT_ADD_WATER = "➕ Water";
string TXT_FOUND_BUCKET = "Found water bucket...";
string TXT_WATER_GRASS = "Water Grass";
string TXT_AUTO_ON = "+AutoWater";
string TXT_AUTO_OFF = "-AutoWater";
string TXT_AUTO_WATERING = "Auto watering";
string TXT_ON = "On";
string TXT_OFF = "Off";
string TXT_CLOSE = "CLOSE";
string TXT_SELECT = "Select";
string TXT_DRINKABLE_WATER = "Drinkable Water";
string TXT_GRASS_LEVEL = "Grass Level";
string TXT_GRASS_WATERED = "Grass watered";
string TXT_DRINK_WATER_LOW = "DRINK WATER LOW!";
string TXT_GRASS_NEEDS_WATER = "GRASS NEEDS WATERING!";
string TXT_OVERGRAZING = "OVERGRAZING!";
string TXT_ERROR_WT = "Error! Water tower not found within 96m. Auto-watering NOT working!";
string TXT_ERROR_BUCKET = "Error! Water bucket not found! You must bring a water bucket near me!";
string TXT_ERROR_GROUP = "We are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_LANGUAGE = "@";
//
// Commands from NPC are always these words
string NPC_ADD_WATER  = "Add Water";
//
string SUFFIX = "G1";
string PASSWORD="*";
float drinkWater=0.0;
float grassWater=0.0;
float grassLevel = 70.0;
integer autoWater =0;
string sense= "";
integer createdTs =0;
integer lastTs=0;

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

loadConfig()
{
    PASSWORD = osGetNotecardLine("sfp", 0);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                     if (cmd == "WELL") SF_WATER_TOWER = val;
                else if (cmd == "WATER_OBJECT") SF_WATER = val;
                else if (cmd == "LANG") languageCode = val;
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
                         if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_LOOKING_FOR_WT") TXT_LOOKING_FOR_WT = val;
                    else if (cmd == "TXT_ADD_WATER") TXT_ADD_WATER = val;
                    else if (cmd == "TXT_FOUND_BUCKET") TXT_FOUND_BUCKET = val;
                    else if (cmd == "TXT_WATER_GRASS") TXT_WATER_GRASS = val;
                    else if (cmd == "TXT_AUTO_ON") TXT_AUTO_ON = val;
                    else if (cmd == "TXT_AUTO_OFF") TXT_AUTO_OFF = val;
                    else if (cmd == "TXT_AUTO_WATERING") TXT_AUTO_WATERING = val;
                    else if (cmd == "TXT_ON") TXT_ON = val;
                    else if (cmd == "TXT_OFF") TXT_OFF = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_DRINKABLE_WATER") TXT_DRINKABLE_WATER = val;
                    else if (cmd == "TXT_GRASS_LEVEL") TXT_GRASS_LEVEL = val;
                    else if (cmd == "TXT_GRASS_WATERED") TXT_GRASS_WATERED = val;
                    else if (cmd == "TXT_DRINK_WATER_LOW") TXT_DRINK_WATER_LOW = val;
                    else if (cmd == "TXT_GRASS_NEEDS_WATER") TXT_GRASS_NEEDS_WATER = val;
                    else if (cmd == "TXT_OVERGRAZING") TXT_OVERGRAZING = val;
                    else if (cmd == "TXT_ERROR_WT") TXT_ERROR_WT = val;
                    else if (cmd == "TXT_ERROR_BUCKET") TXT_ERROR_BUCKET = val;
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
    llSetObjectDesc("F;Water;"+(string)llRound(drinkWater)+";"+(string)llRound(grassLevel) + ";" + (string)llRound(grassWater) + ";" + (string)autoWater +";" +languageCode);
}

loadStateByDesc()
{
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) != "F")
    {
        saveStateToDesc();
    }
    else
    {
        drinkWater = llList2Float(desc, 2);
        grassLevel = llList2Float(desc, 3);
        grassWater = llList2Float(desc, 4);
        autoWater  = llList2Integer(desc, 5);
        languageCode = llList2String(desc, 6);
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
}

refresh()
{
    integer isWilted;
    string progress = "";
    grassWater -=  (float)(llGetUnixTime() - lastTs)/(86400.)*100.;
    if (grassWater <0) grassWater =0;
    if (drinkWater <0) drinkWater =0;

    if (drinkWater <= 5)
    {
        progress += TXT_DRINK_WATER_LOW +"\n";
        if (autoWater)
        {
            sense = "AutoWaterDrink";
            llSensor(SF_WATER_TOWER, "", SCRIPTED, 96, PI);
            llWhisper(0, TXT_LOOKING_FOR_WT);
        }
    }
    else if (grassWater <=0)
    {
        progress += TXT_GRASS_NEEDS_WATER + "\n";
        isWilted=1;
        if (autoWater)
        {
            sense = "AutoWaterGrass";
            llSensor(SF_WATER_TOWER, "", SCRIPTED, 96, PI);
            llWhisper(0, TXT_LOOKING_FOR_WT);
        }
    }

    if (grassWater>0)
    {
        grassLevel += (llGetUnixTime() - lastTs)/120;
        if (grassLevel>100.0) grassLevel=100.0;
    }

    if (grassLevel<=5)
    {
        progress += TXT_OVERGRAZING +"\n";
    }

    string str = progress  + "\n" + TXT_DRINKABLE_WATER + ": " + (string)((integer)(drinkWater))+ "%\n" + TXT_GRASS_LEVEL +": "+(string)((integer)grassLevel) + "%\n" + TXT_GRASS_WATERED + ": "+(string)((integer)grassWater)+"%\n";
    if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";

    if (progress != "")
        llSetText(str, <1,.1,.1>, 1.0);
    else
        llSetText(str, <1,.9,.6>, 1.0);

    if (isWilted)
        llSetLinkColor(2, <1, .15, 0>, ALL_SIDES);
    else
        llSetLinkColor(2, <1,1,1>, ALL_SIDES);

    llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, ALL_SIDES, "Grass", <9, .5, 0>, <0,  .20  - (grassLevel/100.)*0.45 ,  0>, PI/2]);
    psys();
    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(3, [PRIM_SIZE]), 0);
    v.z = 1.0* drinkWater/100.;
    llSetLinkPrimitiveParamsFast(3, [PRIM_SIZE, v]);
    saveStateToDesc();
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
        osMessageObject(id, "INIT|"+PASSWORD+"|100|-1|<1.000, 0.965, 0.773>|");
    }

    state_entry()
    {
        lastTs = llGetUnixTime();
        createdTs = lastTs;
        llSetTimerEvent(1);
        loadConfig();
        loadLanguage(languageCode);
        loadStateByDesc();
        refresh();
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)) || osIsNpc(llDetectedKey(0)))
        {
           list opts = [];
           if (drinkWater < 90) opts += TXT_ADD_WATER;
           if (grassWater < 90) opts += TXT_WATER_GRASS;
           if (autoWater) opts += TXT_AUTO_OFF;
           else opts += TXT_AUTO_ON;
           opts += TXT_LANGUAGE;
           opts += TXT_CLOSE;
           startListen();
           llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
        }
        else llWhisper(0, TXT_ERROR_GROUP);
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == TXT_CLOSE) return;

        if ((m == TXT_ADD_WATER) || (m == NPC_ADD_WATER))
        {
            sense = "WaterDrink";
            llSensor(SF_WATER, "", SCRIPTED, 5, PI);
        }
        if (m == TXT_WATER_GRASS)
        {
            sense = "WaterGrass";
            llSensor(SF_WATER, "", SCRIPTED, 5, PI);
        }
        else if (m == TXT_AUTO_ON || m == TXT_AUTO_OFF)
        {
            autoWater =  (m == TXT_AUTO_ON);
            if (autoWater == 1) llSay(0, TXT_AUTO_WATERING + "=" + TXT_ON); else llSay(0, TXT_AUTO_WATERING + "=" + TXT_OFF);
            llSetTimerEvent(1);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
    }

    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2Key(tk,0);
        if (llList2String(tk,1) != PASSWORD)  { llOwnerSay("'"+llList2String(tk,1)+"'!='"+PASSWORD+"'"); return;  }

        if (cmd  == "WATER"  )
        {
            if (sense == "WaterDrink")
            {
                drinkWater+=20.;
                if (drinkWater>100) drinkWater = 100.;
            }
            else if (sense == "WaterGrass")
                grassWater = 100.;
            llSetTimerEvent(2);
        }
        else if (cmd == "HAVEWATER" )
        {
            if (sense == "AutoWaterDrink")
            {
                drinkWater+=30.0;
                if (drinkWater>100) drinkWater = 100.;
            }
            else if (sense == "AutoWaterGrass")
            {
                grassWater = 100.0;
                refresh();
            }

            llSetTimerEvent(2);
        }
        else if (cmd  == "FEEDME")
        {
            key u = llList2Key(tk, 2);
            float f = llList2Float(tk,3);
            if (grassLevel>f)
            {
                grassLevel -= f;
                if (grassLevel<0) grassLevel=0;
                osMessageObject(u,  "FOOD|"+PASSWORD);
                psys();
            llSetTimerEvent(2);
            }
        }
        else if (cmd == "WATERME")
        {
            key u = llList2Key(tk, 2);
            float f = llList2Float(tk,3);
            if (drinkWater>f)
            {
                drinkWater -= f;
                if (drinkWater<0) drinkWater=0;
                osMessageObject(u,  "WATER|"+PASSWORD);;
                psys();
                llSetTimerEvent(2);
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
            osMessageObject(llList2Key(tk, 2), answer);
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
        integer ts = llGetUnixTime();
        if (ts - lastTs> 0)
        {
            refresh();
            llSetTimerEvent(300);
            lastTs = ts;
        }
        checkListen();
    }

    sensor(integer n)
    {
        if (sense == "AutoWaterDrink" || sense =="AutoWaterGrass")
        {
            key id = llDetectedKey(0);
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
        }
        else
        {
            llSay(0, TXT_FOUND_BUCKET);
            key id = llDetectedKey(0);
            osMessageObject(id,  "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        if (sense == "AutoWaterDrink" || sense =="AutoWaterGrass")
           llSay(0, TXT_ERROR_WT +"\n["+SF_WATER_TOWER+"]");
        else
             llSay(0, TXT_ERROR_BUCKET);
          sense = "";
    }

    link_message(integer sender, integer val, string m, key id)
    {
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
