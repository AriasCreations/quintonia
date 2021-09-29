// power_mine.lsl
//  SF Mine script

float   VERSION = 5.0;    // Beta 27 November 2020
integer RSTATE  = 1;      // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overridden by config notecard
integer MINETIME = 172800;   // 48 hours
integer WATER_TIMES = 2;
integer ENERGY_TIMES = 2;
list    PLANTS = [];
vector  REZ_POS = <1.0, 1.0, 2.0>;
string  languageCode = "en-GB";
//
string SF_WATER_TOWER="SF Water Tower";
string SF_WATER="SF Water";

// For language support
string TXT_LOOKING_FOR="Looking for";
string TXT_NEEDS_WATER="NEEDS WATER";
string TXT_NEEDS_ENERGY="NEEDS ENERGY";
string TXT_MINING="Mining";
string TXT_ENERGY="Energy";
string TXT_WATER="Water";
string TXT_FINISHED_MINING="Finished mining";
string TXT_CLEANUP="Cleanup";
string TXT_COLLECT="Collect";
string TXT_MINE="Mine";
string TXT_STARTING="Starting mining";
string TXT_ADD_WATER="Add water";
string TXT_AUTOWATER="AutoWater";
string TXT_FOUND_ENERGY="Found energy";
string TXT_ABORT="ABORT";
string TXT_SELECT="Select";
string TXT_CLOSE="CLOSE";
string TXT_ON="ON";
string TXT_OFF="OFF";
string TXT_STATUS="Status";
string TXT_IDLE="IDLE";
string TXT_EMPTYING="Emptying";
string TXT_NOT_FOUND="Error! Not found! You must bring it closer to me";
string TXT_NO_WATER="Error! Water tower not found within 96m. Auto-watering NOT working!";

string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";

string TXT_LANGUAGE="@";
//
string TXT_STATUS_EXPIRED="Expired";
string TXT_STATUS_EMPTY="Empty";
string TXT_STATUS_CRUSHING="Crushing";
string TXT_STATUS_SAMPLING="Sampling";
string TXT_STATUS_MINING="Mining";
string TXT_STATUS_COLLECT="Collect";
string TXT_STATUS_DEAD="Dead";
//
string SUFFIX="M2";
//
string  panelImg = "panel";
string  status = "Empty";
integer energy_channel = -321321;
string  PASSWORD = "*";
string  PRODUCT_NAME;
list    customOptions = [];
integer createdTs =0;
integer lastTs = 0;
integer statusLeft;
integer statusDur;
string  plant = "";
float   energy = 0.0;
float   water = 10.0;
float   wood = 0;
string  mode = "";
integer autoWater = 0;
string  sense = "";
key     lastUser = NULL_KEY;
string  infoString = "";

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
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

loadConfig()
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
                 if (cmd == "LIFETIME")    MINETIME = (integer)val;
            else if (cmd == "MINETIME")    MINETIME = (integer)val;
            else if (cmd == "WATER_TIMES") WATER_TIMES = (integer)val;
            else if (cmd == "ENERGY_TIMES") ENERGY_TIMES = (integer)val;
            else if (cmd == "REZ_POSITION") REZ_POS = (vector)val;
            else if (cmd == "LANG") languageCode = val;
        }
    }
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "M")
    {
        autoWater = llList2Integer(desc, 1);
        languageCode = llList2String(desc, 2);
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
                         if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_NEEDS_WATER") TXT_NEEDS_WATER = val;
                    else if (cmd == "TXT_NEEDS_ENERGY") TXT_NEEDS_ENERGY = val;
                    else if (cmd == "TXT_MINING") TXT_MINING = val;
                    else if (cmd == "TXT_ENERGY") TXT_ENERGY = val;
                    else if (cmd == "TXT_WATER") TXT_WATER = val;
                    else if (cmd == "TXT_FINISHED_MINING") TXT_FINISHED_MINING = val;
                    else if (cmd == "TXT_CLEANUP") TXT_CLEANUP = val;
                    else if (cmd == "TXT_COLLECT") TXT_COLLECT = val;
                    else if (cmd == "TXT_MINE") TXT_MINE = val;
                    else if (cmd == "TXT_STARTING") TXT_STARTING = val;
                    else if (cmd == "TXT_ADD_WATER") TXT_ADD_WATER = val;
                    else if (cmd == "TXT_AUTOWATER") TXT_AUTOWATER = val;
                    else if (cmd == "TXT_FOUND_ENERGY") TXT_FOUND_ENERGY = val;
                    else if (cmd == "TXT_ABORT") TXT_ABORT = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_ON") TXT_ON = val;
                    else if (cmd == "TXT_OFF") TXT_OFF = val;
                    else if (cmd == "TXT_STATUS") TXT_STATUS = val;
                    else if (cmd == "TXT_IDLE") TXT_IDLE = val;
                    else if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_NO_WATER") TXT_NO_WATER = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_STATUS_EXPIRED") TXT_STATUS_EXPIRED = val;
                    else if (cmd == "TXT_STATUS_EMPTY") TXT_STATUS_EMPTY = val;
                    else if (cmd == "TXT_STATUS_CRUSHING") TXT_STATUS_CRUSHING = val;
                    else if (cmd == "TXT_STATUS_SAMPLING") TXT_STATUS_SAMPLING = val;
                    else if (cmd == "TXT_STATUS_MINING") TXT_STATUS_MINING = val;
                    else if (cmd == "TXT_STATUS_COLLECT") TXT_STATUS_COLLECT = val;
                    else if (cmd == "TXT_STATUS_DEAD") TXT_STATUS_DEAD = val;
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
                    PSYS_SRC_BURST_RATE, 100,
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

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

string getStatus(string value)
{
         if (value == "Expired") return TXT_STATUS_EXPIRED;
    else if (value == "Empty") return TXT_STATUS_EMPTY;
    else if (value == "Crushing") return TXT_STATUS_CRUSHING;
    else if (value == "Sampling") return TXT_STATUS_SAMPLING;
    else if (value == "Mining") return TXT_STATUS_MINING;
    else if (value == "Collect") return TXT_STATUS_COLLECT;
    else if (value == "Dead") return TXT_STATUS_DEAD;
    else return "ERROR";
}

setAnimations(integer level)
{
    integer i;
    for (i=0; i <= llGetNumberOfPrims(); i++)
    {
        if (llGetSubString(llGetLinkName(i),0,4) == "spin ")
        {
            list tk = llParseString2List(llGetLinkName(i), [" "], []);
            float rate = 0.0;
            if (level==1) rate = 1.0;
            llSetLinkPrimitiveParamsFast(i, [PRIM_OMEGA, llList2Vector(tk, 1), level, 1.0]);
        }
        else if (llGetSubString( llGetLinkName(i), 0, 17)  == "show_while_cooking")
        {
            vector color = llList2Vector(llGetLinkPrimitiveParams(i, [PRIM_COLOR, 0]), 0);
            float f = (float)llGetSubString( llGetLinkName(i), 18, -1);
            if (f ==0.) f= 1.0;
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, color, (level>0)*f]);
        }
    }
}

showStatus(integer stage)
{
    float y = 0.4 - (stage * 0.2);
    llSetLinkPrimitiveParamsFast(getLinkNum("status_panel"), [ PRIM_TEXTURE, 0, panelImg+"-"+languageCode, <1.0, 0.2 ,1.0>, <0.0, y, 0.0>, 0.0,
                                                         PRIM_FULLBRIGHT, 0, stage ]);
    if (stage == 0)
    {
        setAnimations(0);
        llStopSound();
    }
}

refresh(integer ts)
{
    water -=  (float)(llGetUnixTime() - lastTs)/(MINETIME/WATER_TIMES)*100.0;
    energy -=  (float)(llGetUnixTime() - lastTs)/(MINETIME/ENERGY_TIMES)*100.0;
    integer isWilted;
    string progress = "";
    if (status == "Expired" || status == "Empty")
    {
        //
    }
    else if ((water <= 0.0 || energy <= 0.0) && status != "Crushing")
    {
        if (energy <= 0.0) progress += TXT_NEEDS_ENERGY +"!\n";
        if (water <= 0.0) progress += TXT_NEEDS_WATER +"!\n";
        isWilted = 1;
        if (autoWater>0)
        {
            sense = "AutoWater";
            llSensor(SF_WATER_TOWER, "", SCRIPTED, 96, PI);
            llWhisper(0, TXT_LOOKING_FOR +": " +SF_WATER_TOWER +"...");
        }
        if (energy<=0.0)
        {
            energy = 0.1;
            llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
        }
    }
    else
    {
        statusLeft -= (ts - lastTs);
        if ( statusLeft <=0)
        {
            if (status == "Sampling")
            {
                status = "Mining";
                statusLeft = statusDur =  (integer)(MINETIME);
                showStatus(2);
            }
            else if (status == "Mining")
            {
                status = "Crushing";
                statusLeft = statusDur =  (integer)(MINETIME);
                showStatus(3);
            }
            else if (status == "Crushing")
            {
                statusLeft = statusDur =  (integer)(MINETIME);
                setAnimations(0);
                status = "Collect";
                showStatus(4);
                llStopSound();
                doHarvest();
            }
       }
    }
    if (status == "Expired" || status == "Empty")
        progress += "Status: "+getStatus(status)+"\n";
    else
    {
       float p= 1- ((float)(statusLeft)/(float)statusDur);
       progress += TXT_STATUS +": "+getStatus(status)+" ("+(string)((integer)(p*100.))+"%)\n";
    }
    float sw = water;
    if (sw< 0) sw=0;
    if (status == "Empty")
    {
        llSetText(TXT_IDLE +infoString, <1,.9,.6>, 1.0);
        showStatus(0);
    }
    else
    {
        if (status != "Crushing")
        {
            llSetText(TXT_MINING +" "+plant+"\n" +TXT_WATER +": " + (string)((integer)(sw))+ "%\n" +TXT_ENERGY +": "+(string)(llFloor(energy))+"%\n"+progress+infoString, <1,.9,.6>, 1.0);
        }
        else
        {
          llSetText(TXT_MINING +" "+plant+"\n"+progress+infoString, <0,1.0,0.5>, 1.0);
        }
    }
    if (isWilted)   llSetLinkColor(getLinkNum("status_panel"), <1.000, 0.255, 0.212>, ALL_SIDES);
     else            llSetLinkColor(getLinkNum("status_panel"), <1.0, 1.0, 1.0>, ALL_SIDES);
    psys(llGetKey());
    llStopSound();
    if (!isWilted && (status == "Mining" || status == "Sampling"))
    {
        llLoopSound("mining", 1.0);
        setAnimations(1);
    }
    else
    {
        llStopSound();
        setAnimations(0);
        llMessageLinked(LINK_SET, 99, "STATUS|"+status+"|"+(string)statusLeft+"|WATER|"+(string)water, NULL_KEY);
    }
    // Save in object description
    llSetObjectDesc("M;" +(string)autoWater +";" +languageCode);
}

doHarvest()
{
    if ((status == "Collect") || (status == "Reload"))
    {
        llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +PRODUCT_NAME, NULL_KEY);
        llRegionSayTo(lastUser, 0, TXT_FINISHED_MINING +": " +PRODUCT_NAME);
        status = "Empty";
        showStatus(0);
        refresh(llGetUnixTime());
        llTriggerSound("lap", 1.0);
    }
}

default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|"+PASSWORD);
    }

    state_entry()
    {
        llStopSound();
        loadConfig();
        loadLanguage(languageCode);
        if (RSTATE == 0) infoString = "\n-B-"; else if (RSTATE == -1) infoString = "\n-RC-";
        lastTs = llGetUnixTime();
        lastUser = llGetOwner();
        createdTs = lastTs;
        refresh(lastTs);
        PASSWORD = llStringTrim(osGetNotecardLine("sfp", 0), STRING_TRIM);
        //BW Load products and levels dynamically
        integer i;
        for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
        {
            if (llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),0 ,2) == "SF ")
                PLANTS += llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),3,-1);
        }
        showStatus(0);
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
        llPreloadSound("crushing");
        llSetTimerEvent(1);
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            lastUser = llDetectedKey(0);
            list opts = [];
            if (status == "Dead")  opts += TXT_CLEANUP;
              else if (status == "Empty") opts += TXT_MINE;
            if (water < 90) opts += TXT_ADD_WATER;
            if (autoWater) opts += "-"+TXT_AUTOWATER; else opts += "+"+TXT_AUTOWATER;
            opts += customOptions;
            opts += [TXT_LANGUAGE, TXT_CLOSE];
            if ((status == "Sampling") || (status == "Mining") || (status == "Crushing")) opts += "ABORT";
            startListen();
            llDialog(lastUser, TXT_SELECT, opts, chan(llGetKey()));
        }
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == TXT_CLOSE) return;
        if (m == TXT_ADD_WATER)
        {
            llSensor(SF_WATER, "", SCRIPTED, 5, PI);
        }
        else if ((m == TXT_CLEANUP) || (m == TXT_ABORT))
        {
            status="Empty";
            showStatus(0);
            setAnimations(0);
            llStopSound();
            refresh(llGetUnixTime());
            if (m == TXT_ABORT) llResetScript();
        }
        else if (m == TXT_COLLECT)
        {
            doHarvest();
        }
        else if (m == TXT_MINE)
        {
            mode = "SelectPlant";
            llDialog(id, TXT_SELECT, PLANTS+[TXT_CLOSE], chan(llGetKey()));
        }
        else if (m == ("+"+TXT_AUTOWATER) || m == ("-"+TXT_AUTOWATER))
        {
            if (m == "+"+TXT_AUTOWATER)
            {
                autoWater = TRUE;
                llRegionSayTo(lastUser, 0, TXT_AUTOWATER +": "+TXT_ON);
            }
            else
            {
                autoWater = FALSE;
                llRegionSayTo(lastUser, 0, TXT_AUTOWATER +": "+TXT_OFF);
            }
            llSetTimerEvent(1);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (mode == "SelectPlant")
        {
            plant = m;
            PRODUCT_NAME = "SF "+plant;
            statusLeft = statusDur = (integer)(MINETIME/5.0);
            status="Sampling";
            if (water <0) water =0;
            lastTs = llGetUnixTime();
            llSay(0, TXT_STARTING +": " +m);
            llTriggerSound("lap", 1.0);
            showStatus(1);
            setAnimations(1);
            refresh(llGetUnixTime());
            mode = "";
        }
        else
            llMessageLinked(LINK_SET, 99, "MENU_OPTION|"+m, NULL_KEY);
    }

    dataserver(key k, string m)
    {
        debug("dataserver:" +m);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk,0);

        if ((cmd == "VERSION-CHECK") || (cmd == "DO-UPDATE"))
        {
            if (llList2String(tk,1) != PASSWORD ) return;
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
            refresh(llGetUnixTime());
        }
        else
        {
            if (cmd == "HAVEWATER")
            {
                // found water
                if (sense == "WaitTower")
                {
                    water=100.0;
                    refresh(llGetUnixTime());
                    sense = "";
                }
            }
            else if (cmd == "WATER")
            {
                water=100.0;
                refresh(llGetUnixTime());
            }
            else
            {
                if (llList2String(tk,1) != PASSWORD ) return;
                cmd = llList2String(tk,0);

                if (cmd == "HAVEENERGY")
                {
                    energy = 100.0;
                    refresh(llGetUnixTime());
                    llWhisper(0, TXT_FOUND_ENERGY);
                }
            }
        }
    }

    timer()
    {
        integer ts = llGetUnixTime();
        if (ts - lastTs> 0)
        {
            refresh(ts);
            llSetTimerEvent(300);
            lastTs = ts;
        }
        checkListen();
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        debug("sensor:" +(string)id);
        if (sense == "AutoWater")
        {
            messageObj(id, "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
            sense = "WaitTower";
        }
        else
        {
            llRegionSayTo(lastUser,0, TXT_EMPTYING +"...");
            messageObj(id,  "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        if (sense == "AutoWater")
           llOwnerSay(TXT_NO_WATER);
        else
           llRegionSayTo(lastUser, 0, TXT_NOT_FOUND);
        sense = "";
    }

    link_message(integer sender, integer val, string m, key id)
    {
        if (val ==99) return; // Dont listen to self

        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET_MENU_OPTIONS")  // Add custom dialog menu options.
        {
            customOptions = llList2List(tok, 1, -1);
        }
        else if (cmd == "SETSTATUS")    // Change the status of this plant
        {
            status = llList2String(tok, 1);
            statusLeft = statusDur = llList2Integer(tok, 2);
            refresh(llGetUnixTime());
        }
        else if (cmd == "HARVEST")    // Change the status of this plant
        {
                doHarvest();  // Status must be "Ripe"
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
                 if (status == "Sampling") showStatus(1);
            else if (status == "Mining") showStatus(2);
            else if (status == "Crushing") showStatus(3);
             else showStatus(4);
            refresh(llGetUnixTime());
        }
    }
}
