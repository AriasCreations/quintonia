// feeder.lsl
//  Animal feeder
// Change log:
//  Now stores auto water, auto food state & language in object description to survive resets
//

float VERSION = 3.6;   // 1 August 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}
// Can be changed via CONFIG notecard
string TITLE = "Feeder";
string AUTOFOODITEM = "Grain";                // Which food to take from rack
string FOODTOWER = "SF Storage Rack";
float waterMinZ;                            // prim Z position
float waterMaxZ;
float foodMinZ;
float foodMaxZ;
string SF_WATER_TOWER = "SF Water Tower";
string SF_WATER = "SF Water";
integer floatText = TRUE;                   // FLOAT_TEXT=1  (set to 0 to not show the status float text)
string languageCode = "en-GB";
//
// Language support
string TXT_LOOKING_FOR_WT = "Looking for water tower...";
string TXT_ADD_WATER = "➕ Water";
string TXT_ADD = "➕";
string TXT_LOOKING_FOR = "Looking for";
string TXT_FOUND_BUCKET = "Found water bucket...";
string TXT_FOUND = "Found";
string TXT_FOOD = "Food";
string TXT_WATER = "Water";
string TXT_AUTO_WATER_ON = "+AutoWater";
string TXT_AUTO_WATER_OFF = "-AutoWater";
string TXT_AUTO_WATERING = "Auto watering";
string TXT_AUTO_FOOD_ON = "+AutoFood";
string TXT_AUTO_FOOD_OFF = "-AutoFood";
string TXT_AUTO_FOOD = "Auto food";
string TXT_ON = "On";
string TXT_OFF = "Off";
string TXT_CLOSE = "CLOSE";
string TXT_SELECT = "Select";
string TXT_ERROR_NOAUTOOBJ = "Error! Auto-mode NOT working as can't find with 96m:";
string TXT_ERROR_ITEM = "Error! Can't find item:";
string TXT_ERROR_GROUP = "We are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_LANGUAGE = "@";
//
// Commands from NPC are always these words
string NPC_ADD_WATER  = "Add Water";
//
string SUFFIX = "F1";
string PASSWORD="*";
list FOODITEMS = [];

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

float food=10.;
float water=10.;
string status;
integer autoWater = 0;
integer autoFood = 0;
string lookFor;

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

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
        //llOwnerSay(cmd+"="+val);
        if (cmd == "TITLE") TITLE = val;
        else if (cmd == "FOOD") FOODITEMS += val;
        else if (cmd == "FOODTOWER") FOODTOWER = val;
        else if (cmd == "AUTOFOODITEM") AUTOFOODITEM = val;
        else if (cmd == "WATER_ZMIN") waterMinZ = (float)val;
        else if (cmd == "WATER_ZMAX") waterMaxZ = (float)val;
        else if (cmd == "FOOD_ZMAX") foodMaxZ = (float)val;
        else if (cmd == "FOOD_ZMIN") foodMinZ = (float)val;
        else if (cmd == "WATER_TOWER") SF_WATER_TOWER = val;
        else if (cmd == "SF_WATER") SF_WATER = val;
        else if (cmd == "FLOAT_TEXT") floatText = (integer)val;
        else if (cmd == "LANG") languageCode = val;
    }
}

loadConfig()
{
    PASSWORD = osGetNotecardLine("sfp", 0);

    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
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
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_FOUND_BUCKET") TXT_FOUND_BUCKET = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_FOOD") TXT_FOOD = val;
                    else if (cmd == "TXT_WATER") TXT_WATER = val;
                    else if (cmd == "TXT_AUTO_WATER_ON") TXT_AUTO_WATER_ON = val;
                    else if (cmd == "TXT_AUTO_WATER_OFF") TXT_AUTO_WATER_OFF = val;
                    else if (cmd == "TXT_AUTO_WATERING") TXT_AUTO_WATERING = val;
                    else if (cmd == "TXT_AUTO_FOOD_ON") TXT_AUTO_FOOD_ON = val;
                    else if (cmd == "TXT_AUTO_FOOD_OFF") TXT_AUTO_FOOD_OFF = val;
                    else if (cmd == "TXT_AUTO_FOOD") TXT_AUTO_FOOD = val;
                    else if (cmd == "TXT_ON") TXT_ON = val;
                    else if (cmd == "TXT_OFF") TXT_OFF = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_ERROR_NOAUTOOBJ") TXT_ERROR_NOAUTOOBJ = val;
                    else if (cmd == "TXT_ERROR_ITEM") TXT_ERROR_ITEM = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    string TXT_LANGUAGE = "@";
                }
            }
        }
    }
}

saveStateToDesc()
{
    llSetObjectDesc("F;"+AUTOFOODITEM+";"+(string)llRound(water)+";"+(string)llRound(food)+";"+(string)autoWater+";"+(string)autoFood+";"+languageCode);
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
        AUTOFOODITEM = llList2String(desc, 1);
        water = llList2Float(desc, 2);
        food = llList2Float(desc, 3);
        autoWater = llList2Integer(desc, 4);
        autoFood = llList2Integer(desc, 5);
        languageCode = llList2String(desc, 6);
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

refresh()
{

    if (floatText == TRUE) llSetText(TITLE+ "\n" + TXT_FOOD +": "+(string)((integer)food)+"%\n" + TXT_WATER +": "+(string)((integer)water)+"%\n" , <1,1,1>, 1.0); else llSetText("",ZERO_VECTOR,0);
    if (water <=5 && autoWater)
    {
        status = "WaitAutoWater";
        lookFor = SF_WATER_TOWER;
        llSensor(lookFor, "" , SCRIPTED, 96, PI);
        llWhisper(0, TXT_LOOKING_FOR_WT);
    }
    else if (AUTOFOODITEM != "" && food <=4 && autoFood)
    {
        lookFor =  FOODTOWER; //"SF Storage Rack";
        status = "WaitAutoFood";
        llSensor(lookFor, "", SCRIPTED, 96, PI);
        llWhisper(0, TXT_LOOKING_FOR +" "+FOODTOWER+"...");
    }

    vector v ;
    integer ln = getLinkNum("Water");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* water/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }
    ln = getLinkNum("Food");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = foodMinZ + (foodMaxZ-foodMinZ)* food/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }
    saveStateToDesc();
}



default
{
    listen(integer c, string nm, key id, string m)
    {
        debug("listen:" + m);
        if ((m == TXT_ADD_WATER) || (m == NPC_ADD_WATER))
        {
            status = "WaitWater";
            lookFor = SF_WATER;
            llSensor(lookFor, "",SCRIPTED,  5, PI);
        }
        else if (m == TXT_AUTO_WATER_ON || m == TXT_AUTO_WATER_OFF)
        {
            autoWater =  (m == TXT_AUTO_WATER_ON);
            if (autoWater == 1) llSay(0, TXT_AUTO_WATERING + "=" +TXT_ON); else llSay(0, TXT_AUTO_WATERING + "=" +TXT_OFF);
            llSetTimerEvent(1);
        }
        else if (m == TXT_AUTO_FOOD_ON || m == TXT_AUTO_FOOD_OFF)
        {
            autoFood =  (m == TXT_AUTO_FOOD_ON);
            if (autoFood == 1) llSay(0, TXT_AUTO_FOOD + "=" +TXT_ON); else llSay(0, TXT_AUTO_FOOD + "=" +TXT_OFF);
            llSetTimerEvent(1);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (llGetSubString(m, 0, llStringLength(TXT_ADD)-1) == TXT_ADD)
        {
            string what = llGetSubString(m,llStringLength(TXT_ADD), -1);
            status = "WaitSack";
            lookFor ="SF"+what;
            llSensor(lookFor, "",SCRIPTED,  5, PI);
        }
    }

    dataserver(key kk, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"] , []);
            string cmd = llList2Key(tk,0);
            if (llList2String(tk,1) != PASSWORD)  { llSay(0, "Bad password'"); return;  }

            if (cmd == "VERSION-CHECK")
            {
                string answer = "VERSION-REPLY|" + PASSWORD + "|";
                answer += (string)llGetKey() + "|" + (string)VERSION + "|";
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
            else if (cmd == "STATS-CHECK")
            {
                string answer = "STATS-REPLY|" + PASSWORD + "|";
                // answer += name|food|water
                answer += TITLE + (string)food + "|" + (string)water + "|";
                osMessageObject(llList2Key(tk, 2), answer);
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
            else if (cmd =="SETCONFIG")
            {
                if (llGetOwnerKey(kk) == llGetOwner())
                  setConfig(llList2String(tk,2));
            }
            else if (cmd  == "FEEDME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (food>f)
                {
                    food -= f;
                    if (food<0) food=0;
                    osMessageObject(u,  "FOOD|"+PASSWORD);
                    key o = llList2Key(tk, 4);
                    if (o != NULL_KEY)
                        psys(o);
                    else
                        psys(u);

                }
            }
            else if (cmd == "WATERME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (water>f)
                {
                    water -= f;
                    if (water<0) water=0;
                    osMessageObject(u,  "WATER|"+PASSWORD);
                    key o = llList2Key(tk, 4);
                    if (o != NULL_KEY)
                        psys(o);
                    else
                        psys(u);
                }
            }
            else if (cmd == "HAVEWATER")
            {
                water += 40;
                if (water > 100) water = 100;
                //llSleep(2.);
                psys(NULL_KEY);
                status = "";
            }

            else if (cmd == "HAVE"  && llList2Key(tk,2) == AUTOFOODITEM)
            {
                food += 40;
                if (food>100) food =100;
                llSleep(2.);
                psys(NULL_KEY);
                status = "";
            }
            else if (cmd == "WATER") // Add water
            {
                water += 40;
                if (water > 100) water = 100;
                llSleep(2.);
                psys(NULL_KEY);
            }
            else
            {
                integer i;
                for (i=0; i < llGetListLength(FOODITEMS); i++)
                    if (llToUpper(llList2String(FOODITEMS, i)) == cmd)
                    {
                        food += 40;
                        if (food>100) food =100;
                        llSleep(2.);
                        psys(NULL_KEY);
                    }
            }
            refresh();
    }


    timer()
    {
        refresh();
        llSetTimerEvent(300);
        checkListen();
    }

    touch_start(integer n)
    {
        key toucher = llDetectedKey(0);
        if (llSameGroup(toucher) || osIsNpc(toucher))
        {
            list opts = [];
            if (water < 80) opts += TXT_ADD_WATER;
            if (food  < 80)
            {
                integer i;
                for (i=0; i < llGetListLength(FOODITEMS); i++)
                    opts += TXT_ADD + " "+llList2String(FOODITEMS, i);;
            }
            if (autoWater) opts += TXT_AUTO_WATER_OFF; else opts += TXT_AUTO_WATER_ON;
            if (autoFood) opts += TXT_AUTO_FOOD_OFF; else opts += TXT_AUTO_FOOD_ON;
            opts += TXT_LANGUAGE;
            opts += TXT_CLOSE;
            startListen();
            llDialog(toucher, TXT_SELECT, opts, chan(llGetKey()));
        }
        else
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
        }
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llWhisper(0, TXT_FOUND + " "+llDetectedName(0));
        if (status == "WaitAutoWater")
        {
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
        }
        else  if (status== "WaitAutoFood")
        {
            osMessageObject(id,  "GIVE|"+PASSWORD+"|"+ AUTOFOODITEM +"|"+(string)llGetKey());
        }
        else if ( status == "WaitWater")
        {
            llSay(0, TXT_FOUND_BUCKET);
            osMessageObject(id, "DIE|"+(string)llGetKey());
        }
        else if ( status == "WaitSack")
        {
            llSay(0, TXT_FOUND + " "+lookFor);
            osMessageObject(id,  "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        if (status == "WaitAutoWater" || status == "WaitAutoFood")
            llSay(0, TXT_ERROR_NOAUTOOBJ +" "+lookFor);
        else
            llSay(0, TXT_ERROR_ITEM +" "+lookFor);
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

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        loadStateByDesc();
        refresh();
    }

    on_rez(integer n)
    {
        llResetScript();
    }
}
