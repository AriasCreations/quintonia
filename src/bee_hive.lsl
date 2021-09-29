// This script is used for bee hives and bee houses to produce honey, no food, water or other products needed.
//--
float VERSION = 4.1;  // 19 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// config notecard can override these
vector rezzPosition = <0.0, 1.5, 2.0>;  // REZ_POSITION=<0.0, 1.5, 2.0>   (where to rez product)
string SF_PRODUCT = "SF Honey";         // PRODUCT
integer floatText = TRUE;               // FLOAT_TEXT=1
string languageCode = "en-GB";          // LANG=en-GB

// Language support
string TXT_BEE_ALERT = "Watch out, bees!";
string TXT_NO_HONEY =  "There is not enough honey yet, sorry";
string TXT_BEES_UNHAPPY = "The bees are not happy - no honey for you yet!";
string TXT_LEVEL = "level";
string TXT_AGITATION = "Hive agitation";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_ERROR_NO_CONFIG = "Error: No config Notecard found.\nI can't work without one";
string TXT_LANGUAGE="@";

string SUFFIX = "B1";

string PASSWORD="*";
integer FARM_CHANNEL = -911201;

integer lastTs=0;
integer FILLTIME = 43200;
integer fill;
integer angry;
key lastUser = NULL_KEY;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
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
                         if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
                    else if (cmd == "PRODUCT")      SF_PRODUCT = val;
                    else if (cmd == "FLOAT_TEXT")   floatText = (integer)val;
                    else if (cmd == "LANG")         languageCode = val;
                }
            }
        }
    }
    else
    {
        llSay(0, TXT_ERROR_NO_CONFIG);
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
                         if (cmd == "TXT_BEE_ALERT") TXT_BEE_ALERT = val;
                    else if (cmd == "TXT_NO_HONEY") TXT_NO_HONEY = val;
                    else if (cmd == "TXT_BEES_UNHAPPY") TXT_BEES_UNHAPPY = val;
                    else if (cmd == "TXT_LEVEL") TXT_LEVEL = val;
                    else if (cmd == "TXT_AGITATION") TXT_AGITATION = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_NO_CONFIG") TXT_ERROR_NO_CONFIG = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

refresh()
{
    string details = llGetObjectDesc();
    integer do_fill = FALSE;
    if (llGetUnixTime() - lastTs >  FILLTIME)
    {
        do_fill = TRUE;
        lastTs = llGetUnixTime();
    }
    vector color;
    if (do_fill && fill < 100)
    {
        if (angry <5)
        {
            fill += 10;  if (fill >100) fill = 100;
        }
    }
    llSetObjectDesc((string)fill +";" +(string)lastTs +";" +(string)angry);
    if (lastUser == NULL_KEY) bees(0, 0.5, llGetKey()); else bees(2, 0.5, lastUser);
    if (fill == 100) color = <0.180, 0.800, 0.251>; else color = <1, 1, 1>;
    string extraText = "";
    if (angry > 1)
    {
        extraText = "\n" +TXT_AGITATION + ": " + (string)angry + "%\n";
        if (angry > 84) color = <1.000, 0.255, 0.212>;
         else color = <1.000, 0.863, 0.000>;
    }
    llSetText(SF_PRODUCT +" " +TXT_LEVEL +" " + (string)fill+ "%\n" + extraText, color, 1.0);
    angry -= 1;
    if (angry <0) angry = 0;
}

bees(integer time, float rate, key k)
{
    llParticleSystem([
                    // PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,PI/2,
                    PSYS_SRC_ANGLE_END,PI/2+.3,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,

                    PSYS_PART_START_ALPHA,1.,
                    PSYS_PART_END_ALPHA,0.3,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.070000,0.070000,0.000000>,
                    PSYS_PART_END_SCALE,<.0700000,.07000000,0.000000>,
                    PSYS_SRC_TEXTURE,"Bee",
                    PSYS_SRC_MAX_AGE,time,
                    PSYS_PART_MAX_AGE,8,
                    PSYS_SRC_BURST_RATE, rate,
                    PSYS_SRC_BURST_PART_COUNT, angry+1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,.5000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,2.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, .1,
                    PSYS_SRC_BURST_SPEED_MAX, 2,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |PSYS_PART_WIND_MASK |
                        PSYS_PART_INTERP_SCALE_MASK |
                        PSYS_PART_FOLLOW_VELOCITY_MASK
                    ]);
}



default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(0.5);
        messageObj(id,  "INIT|"+PASSWORD);
        llRegionSayTo(lastUser, FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|health|10");
        refresh();
        lastUser = NULL_KEY;
    }

    state_entry()
    {
        angry = 0;
        loadConfig();
        loadLanguage(languageCode);
        string details = llGetObjectDesc();
        fill   = llList2Integer(llParseString2List(details, [";"], []), 0);
        lastTs = llList2Integer(llParseString2List(details, [";"], []), 1);
        angry  = llList2Integer(llParseString2List(details, [";"], []), 2);
        llVolumeDetect(TRUE);
        llSetTimerEvent(1);
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {
            lastUser = llDetectedKey(0);
            refresh();
            if (fill < 100)
            {
                llRegionSayTo(llDetectedKey(0), 0, TXT_NO_HONEY);
                lastUser = NULL_KEY;
            }
            else if (angry > 9)
            {
                llRegionSayTo(llDetectedKey(0), 0, TXT_BEES_UNHAPPY);
                lastUser = NULL_KEY;
            }
            else
            {
                fill = 0;
                angry = 0;
                llSetObjectDesc("0;" +(string)lastTs +";0");
                llSetText(SF_PRODUCT +" " +TXT_LEVEL +" " + (string)fill+ "%\n", <1,1,1>, 1.0);
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PRODUCT, NULL_KEY);
            }
        }
        else llRegionSayTo(llDetectedKey(0), 0, TXT_ERROR_GROUP);
    }

    collision_start(integer n)
    {
        lastUser = llDetectedKey(0);
        llRegionSayTo(lastUser, 0, TXT_BEE_ALERT);
        llPlaySound("bees", 1.0);
        angry +=10;  if (angry > 100) angry = 100;
        llRegionSay(FARM_CHANNEL, "STUNG|" + PASSWORD + "|" + (string)lastUser);
        bees(30, 0.02, lastUser);
        llTriggerSound("bees", 1.0);
        refresh();
        llSetTimerEvent(30);
    }

    timer()
    {
        refresh();
        lastUser = NULL_KEY;
        llSetTimerEvent(1000);
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
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

    dataserver(key k, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);
        //for updates
        if (command == "VERSION-CHECK")
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
        else if (command == "DO-UPDATE")
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

}
