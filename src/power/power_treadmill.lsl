// power_treadmill.lsl
//  Generates SF kWh by running

float VERSION = 1.4;     // 18 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// these can be overriden with config notecard
vector rezzPosition = <0.0, 0.0, 0.0>;
string SF_KWH="SF kWh";
string languageCode = "en-GB";      // use defaults below unless language config notecard present

// Multilingual notecard support
string TXT_STARTED="Started...";
string TXT_CHARGING="Charging flux capacitor: ";
string TXT_COMPLETE="Energy generation complete! Your kWh is ready";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string SUFFIX="T1";
string PASSWORD="*";
integer ENERGY_CHANNEL= -321321;

float level = 0.0;
integer lastTs = 0;

integer seated;
key     avatar;
integer fxPrim;

string fxSound = "sound";

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return 0;
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
                if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
                else if (cmd == "SF_KWH")  SF_KWH = val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" +SUFFIX;
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
                    if (cmd == "TXT_STARTED") TXT_STARTED = val;
                    else if (cmd == "TXT_CHARGING") TXT_CHARGING = val;
                    else if (cmd == "TXT_COMPLETE") TXT_COMPLETE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

particles()
{
    integer flags = 0;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,3,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, <0.592, 1.000, 0.541>,
                        PSYS_PART_END_COLOR, <0.7, 1.000, 0.6>,
                        PSYS_PART_START_SCALE,<0.25, 0.25, 1>,
                        PSYS_PART_END_SCALE,<1,1,1>,
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_SRC_BURST_RATE,0.1,
                        PSYS_SRC_ACCEL, <0.0, 0.0, -0.5>,
                        PSYS_SRC_BURST_PART_COUNT,8,
                        PSYS_SRC_BURST_RADIUS,1.0,
                        PSYS_SRC_BURST_SPEED_MIN,0.0,
                        PSYS_SRC_BURST_SPEED_MAX,0.05,
                        PSYS_SRC_TARGET_KEY,llGetKey(),
                        PSYS_SRC_INNERANGLE,0.65,
                        PSYS_SRC_OUTERANGLE,0.1,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 2,
                        PSYS_SRC_TEXTURE, "",
                        PSYS_PART_START_ALPHA, level,
                        PSYS_PART_END_ALPHA, 0.0
                            ]);
}


default
{
    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        level = 0.0;
        seated = FALSE;
        avatar = NULL_KEY;
        fxPrim = getLinkNum("collector");
        llSetLinkAlpha(fxPrim, level, ALL_SIDES);
        llSetLinkPrimitiveParamsFast(fxPrim, [PRIM_GLOW, ALL_SIDES, level]);
        llSetLinkTextureAnim(getLinkNum("belt"), FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        llStopSound();
    }

    touch_end(integer index)
    {
        llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, llDetectedKey(0));
    }

    link_message(integer lnk, integer v, string s, key id)
    {
        if   (s == "GLOBAL_START_USING")
        {
            seated = TRUE;
            level = 0;
            lastTs = llGetUnixTime();
            avatar = llAvatarOnSitTarget();
            llSetText(TXT_STARTED, <0.0, 0.2, 1.0>, 1.0);
            llSetLinkTextureAnim(getLinkNum("belt"), ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 0, 0, 1.0, 1.0, 0.1);
        }
        else if (llGetSubString(s, 0, 13)   == "GLOBAL_NEXT_AN")
        {
            llSetTimerEvent(1);
        }
        else if (s== "GLOBAL_SYSTEM_RESET" ||   llGetSubString(s, 0, 16) == "GLOBAL_USER_STOOD")
        {
            llSetText("", <1,1,1>, 1.0);
            llResetScript();
        }
        else
        {
            list tk = llParseString2List(s, ["|"], []);
            string cmd = llList2String(tk, 0);
            if (cmd == "SET-LANG")
            {
                languageCode = llList2String(tk, 1);
                loadLanguage(languageCode);
            }
        }
    }

    timer()
    {
        if (level == -1) return;

        if (seated == TRUE)
        {
            if (llGetUnixTime() - lastTs >=10)
            {
                level += 0.02;
                if (level>1)
                {
                    llPlaySound(fxSound, 1.0);
                    level = -1;
                    llRegionSayTo(avatar, 0, TXT_COMPLETE);
                    llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)avatar +"|" +SF_KWH, NULL_KEY);
                    llUnSit(avatar);
                    avatar = NULL_KEY;
                    seated = FALSE;
                    llSetTimerEvent(0);
                    llPlaySound(fxSound, 1.0);
                    llSetLinkAlpha(fxPrim, 0.0, ALL_SIDES);
                    llSetLinkPrimitiveParamsFast(fxPrim, [PRIM_GLOW, ALL_SIDES, 0.01]);
                    llStopSound();
                    return;
                }
                else
                {
                    llSetText(TXT_CHARGING + llRound(level*100) + "% ", <1,1,1>, 1.0);
                    llPlaySound(fxSound, level);
                    particles();
                    llSetLinkPrimitiveParamsFast(fxPrim, [PRIM_GLOW, ALL_SIDES, level]);
                    llSetLinkAlpha(fxPrim, level, ALL_SIDES);
                    llSetTimerEvent(10);
                    lastTs = llGetUnixTime();
                }
            }
        }
        else
        {
            llResetScript();
        }
    }

    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD+"|");
    }

    dataserver(key kk  , string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk, 1) != PASSWORD)
        {
            llOwnerSay(TXT_BAD_PASSWORD);
            return;
        }

        string cmd = llList2String(tk, 0);
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

}
