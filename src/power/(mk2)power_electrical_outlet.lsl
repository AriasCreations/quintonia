// power_electrical_outlet.lsl
//  Electrical outlet - takes power from power controller and gives out kWh

float   VERSION = 5.0;    // Beta  5 November 2020
integer RSTATE  = 0;      // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// can be overridden by config notecard
vector  rezzPosition = <1,0,0>;
integer SHOW_TXT = TRUE;    // SHOW_TXT=1
string  SF_KWH = "SF kWh";
string  languageCode;
// for multilingual notecard support
string TXT_TITLE="Electrical outlet";
string TXT_SUB_TITLE="Touch for electricity";
string TXT_GET_KWH="Get kWh";
string TXT_CHECKING="Checking available energy reserves...";
string TXT_NO_ENERGY="There is not enough energy available. Please try again later";
string TEXT_SELECT = "Select";
string TXT_CLOSE="CLOSE";
string TXT_BAD_PASSWORD="Comms error";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="@";
//
string SUFFIX ="P3";
//
string PASSWORD="*";
integer energy_channel = -321321;
integer lastTs=0;
key toucher;

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
            PSYS_SRC_MAX_AGE,3,
            PSYS_PART_MAX_AGE,4,
            PSYS_SRC_BURST_RATE, 1.0,
            PSYS_SRC_BURST_PART_COUNT,2,
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
}

refresh()
{
    llParticleSystem([]);
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
                if (cmd =="REZ_POSITION") rezzPosition = (vector)val;
                else if (cmd == "SHOW_TXT") SHOW_TXT = (integer)val;
                else if (cmd == "SF_KWH") SF_KWH = val;
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
                         if (cmd == "TXT_TITLE")  TXT_TITLE = val;
                    else if (cmd == "TXT_SUB_TITLE")  TXT_SUB_TITLE = val;
                    else if (cmd == "TXT_GET_KWH") TXT_GET_KWH = val;
                    else if (cmd == "TXT_CHECKING") TXT_CHECKING = val;
                    else if (cmd == "TXT_NO_ENERGY") TXT_NO_ENERGY = val;
                    else if (cmd == "TXT_SELECT") TEXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

setDefaultMsg()
{
    string str = "";
    if (RSTATE == 0) str+= "-B-"; else if (RSTATE == -1) str+= "-RC-";
    if (SHOW_TXT == TRUE) llSetText(TXT_TITLE + "\n" + TXT_SUB_TITLE +"\n" +str, <0.239, 0.600, 0.439>, 1.0); else llSetText(str, <0.2, 0.2, 0.2>, 0.5);
}


default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        setDefaultMsg();
        lastTs = llGetUnixTime();
        refresh();
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)) || osIsNpc(llDetectedKey(0)))
        {
            toucher = llDetectedKey(0);
            list opts = [];
            opts += TXT_GET_KWH;
            opts += [TXT_LANGUAGE, TXT_CLOSE];
            startListen();
            llDialog(toucher, TEXT_SELECT, opts, chan(llGetKey()));
            llSetTimerEvent(100);
            refresh();
        }
        else llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == TXT_GET_KWH)
        {
            llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
            llRegionSayTo(toucher, 0, TXT_CHECKING);
            if (SHOW_TXT == TRUE) llSetText(TXT_CHECKING, <0.000, 0.455, 0.851>, 1.0); else llSetText("", ZERO_VECTOR, 0.0);
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

    dataserver(key k  , string m)
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
            refresh();
        }
        else
        {
            if (llList2String(tk,1) != PASSWORD ) return;
            cmd = llList2String(tk,0);
            if (cmd == "HAVEENERGY")
            {
                llSleep(1);
                water(toucher);
                llSleep(1);
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)toucher +"|" +llGetInventoryName(INVENTORY_OBJECT,0), NULL_KEY);
                setDefaultMsg();
            }
            else if (cmd == "NOENERGY")
            {
                llRegionSayTo(toucher, 0, TXT_NO_ENERGY);
                setDefaultMsg();
           }
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
            setDefaultMsg();
        }
    }

    timer()
    {
        checkListen();
        llSetTimerEvent(0);
        setDefaultMsg();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

}
