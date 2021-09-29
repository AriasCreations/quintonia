// petify.lsl

float   VERSION = 1.3;    // RC 13 March 2021
integer RSTATE  = -1;     // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

//
integer DEBUGMODE = TRUE;    // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}

//
// config notecard can overide the following:
integer FORCE_ADULT = 1;             // FORCE_ADULT=1
integer scanRange = 10;              // SENSOR_DISTANCE=10
integer requireFeeding = FALSE;      // NEED_FOOD=NO
string  SF_PREFIX = "SF";            // SF_PREFIX=SF
string  languageCode = "en-GB";      // LANG=en-GB
//

// Multilingual support
string TXT_CLOSE = "CLOSE";
string TXT_SELECT = "Select";
string TXT_OPTIONS = "Options";
string TXT_RANGE = "Range";
string TXT_FORCE_ADULT = "Force adult";
string TXT_NEED_FOOD = "Require food";
string TXT_ON = "ON";
string TXT_OFF = "OFF";
string TXT_TRYING="Trying";
string TXT_NOT_FOUND="Not found";
string TXT_INFO="Animal/Pet converter";
string TXT_PETIFY="Animal to Pet";
string TXT_DEPETIFY="Pet to Animal";
string TXT_CAUTION="Caution: Animal will resort to it's true age!";
string TXT_TOO_MANY="Too many animals detected";
string TXT_REDUCE="Please reduce range and stand close to the animal you wish to transform";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "A2";
string  PASSWORD="*";
string  status;
key     userID;
list    names = [];
list    animalIDs = [];

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
    //sfp notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        string cmd;
        string val;
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            list tok = llParseString2List(llList2String(lines,i), ["="], []);
            if (llList2String(tok,1) != "")
            {
                cmd = llStringTrim(llList2String(tok, 0), STRING_TRIM);
                val = llStringTrim(llList2String(tok, 1), STRING_TRIM);
                     if (cmd == "SENSOR_DISTANCE") scanRange = (integer)val;
                else if (cmd == "FORCE_ADULT") FORCE_ADULT = (integer)val;
                else if (cmd == "NEED_FOOD")
                {
                    if (llToUpper(val) == "YES") requireFeeding = TRUE; else requireFeeding = FALSE;
                }
                else if (cmd == "SF_PREFIX") SF_PREFIX = val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang"+SUFFIX;
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
                         if (cmd == "TXT_CLOSE")  TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_OPTIONS") TXT_OPTIONS = val;
                    else if (cmd == "TXT_TRYING") TXT_TRYING = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_INFO") TXT_INFO = val;
                    else if (cmd == "TXT_PETIFY") TXT_PETIFY = val;
                    else if (cmd == "TXT_DEPETIFY") TXT_DEPETIFY = val;
                    else if (cmd == "TXT_CAUTION") TXT_CAUTION = val;
                    else if (cmd == "TXT_RANGE") TXT_RANGE = val;
                    else if (cmd == "TXT_FORCE_ADULT") TXT_FORCE_ADULT = val;
                    else if (cmd == "TXT_NEED_FOOD") TXT_NEED_FOOD = val;
                    else if (cmd == "TXT_OFF") TXT_OFF = val;
                    else if (cmd == "TXT_ON") TXT_ON = val;
                    else if (cmd == "TXT_TOO_MANY") TXT_TOO_MANY = val;
                    else if (cmd == "TXT_REDUCE") TXT_REDUCE = val;
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
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
                    PSYS_SRC_ANGLE_BEGIN, 0.0,
                    PSYS_SRC_ANGLE_END, 0.0,

                    PSYS_SRC_TARGET_KEY, k,
                    PSYS_PART_TARGET_LINEAR_MASK, 1,

                    PSYS_PART_START_COLOR,<1.0, 0.8, 0.8>,
                    PSYS_PART_END_COLOR,<1.0, 1.0, 1.0>,

                    PSYS_PART_START_ALPHA,0.5,
                    PSYS_PART_END_ALPHA,1.0,

                    PSYS_PART_START_GLOW,0.05,
                    PSYS_PART_END_GLOW,0.1,

                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.20, 0.20, 0>,
                    PSYS_PART_END_SCALE,<0.75, 0.75, 0>,

                    PSYS_SRC_TEXTURE,"heart",

                    PSYS_SRC_MAX_AGE, 0.5,
                    PSYS_PART_MAX_AGE, 2,
                    PSYS_SRC_BURST_RATE, 0.1,
                    PSYS_SRC_BURST_PART_COUNT, 3,
                    PSYS_SRC_BURST_SPEED_MIN, 2.0,
                    PSYS_SRC_BURST_SPEED_MAX, 2.0,

                    PSYS_SRC_ACCEL,<0.00, 0.10, 0.00>,
                    PSYS_SRC_OMEGA,<0.00, 0.00, 0.00>,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                       PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
}

string setInfoText()
{
    string result = TXT_RANGE +": " +(string)scanRange +"m\t" +TXT_FORCE_ADULT +": ";
    if (FORCE_ADULT == TRUE) result += TXT_ON; else result += TXT_OFF;
    result += "\t" +TXT_NEED_FOOD +": ";
    if (requireFeeding == TRUE) result += TXT_ON; else result += TXT_OFF;
    return result;
}

default
{

    timer()
    {
        checkListen();
        llSetTimerEvent(0);
        string str = "";
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        llSetText(TXT_INFO+str, <1,1,1>, 1.0);
        llParticleSystem([]);
    }

    listen(integer channel, string name, key id, string message)
    {
        debug("listen:"+message);
        llParticleSystem([]);
        if (message == TXT_CLOSE)
        {
            llListenRemove(listener);
            listener = -1;
        }
        else if (message == TXT_OPTIONS)
        {
            list buttons = [TXT_RANGE, TXT_FORCE_ADULT, TXT_NEED_FOOD, TXT_CLOSE];
            listener=-1;
            startListen();
            llDialog(userID, "\n("+setInfoText()+")\n \n"+TXT_OPTIONS, buttons, chan(llGetKey()));
        }
        else if (message == TXT_RANGE)
        {
            llTextBox(userID, TXT_RANGE, chan(llGetKey()));
            status = "waitRange";
        }
        else if (message == TXT_FORCE_ADULT)
        {
            FORCE_ADULT = !FORCE_ADULT;
            if (FORCE_ADULT) llOwnerSay(TXT_FORCE_ADULT +" "+TXT_ON); else llOwnerSay(TXT_FORCE_ADULT +" "+TXT_OFF);
            listener=-1;
            startListen();
            llDialog(userID, "\n("+setInfoText()+")\n \n"+TXT_SELECT, [TXT_PETIFY, TXT_DEPETIFY, TXT_OPTIONS, TXT_LANGUAGE, TXT_CLOSE], chan(llGetKey()));
        }
        else if (message == TXT_NEED_FOOD)
        {
            requireFeeding = !requireFeeding;
            if (requireFeeding) llOwnerSay(TXT_NEED_FOOD +" "+TXT_ON); else llOwnerSay(TXT_NEED_FOOD +" "+TXT_OFF);
            listener=-1;
            startListen();
            llDialog(userID, "\n("+setInfoText()+")\n \n"+TXT_SELECT, [TXT_PETIFY, TXT_DEPETIFY, TXT_OPTIONS, TXT_LANGUAGE, TXT_CLOSE], chan(llGetKey()));
        }
        else if (message == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
            llListenRemove(listener);
            listener = -1;
        }
        else if ((message == TXT_PETIFY) || (message == TXT_DEPETIFY))
        {
            if (message == TXT_PETIFY) status = "waitScanP"; else status = "waitScanD";
            llSensor("", "", SCRIPTED, scanRange, PI);
            llSetText("...", <0.0, 1.0, 0.2>, 1.0);
        }
        else if (status == "waitRange")
        {
            scanRange = (integer)message;
            if (scanRange < 1) scanRange = 1;
            listener=-1;
            startListen();
            llDialog(userID, "\n("+setInfoText()+")\n \n"+TXT_SELECT, [TXT_PETIFY, TXT_DEPETIFY, TXT_OPTIONS, TXT_LANGUAGE, TXT_CLOSE], chan(llGetKey()));
        }
        else if ((status == "waitSelectA") || (status == "waitSelectX"))
        {
            string cmd;
            if (status == "waitSelectA") cmd = "PETIFY"; else cmd = "DEPETIFY";
            integer index = llListFindList(names, [message]);
            if (index != -1)
            {
                key aniID = llList2Key(animalIDs, index);
                llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, 5, 1, 1, 0, TWO_PI, 2.0);
                llSetText(TXT_TRYING + ": " + message +"\n["+(string)aniID+"]", <1.0, 0.0, 0.5>, 1.0);
                psys(aniID);
                llSleep(1.0);
                llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, 3, 1, 1, 0, TWO_PI, 2.0);
                osMessageObject(aniID, cmd+"|"+PASSWORD+"|"+(string)FORCE_ADULT+"|"+(string)requireFeeding);
                llSleep(1.5);
                llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, 4, 1, 1, 0, TWO_PI, 2.0);
                llSleep(1.5);
                llParticleSystem([]);
                llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
                llSetText("DONE!", <1,1,1>, 1);
                llSetTimerEvent(5);
            }
        }
    }

    touch_start(integer n)
    {
        userID = llDetectedKey(0);
        if (llGetOwner() == userID)
        {
            listener=-1;
            startListen();
            llDialog(userID, "\n("+setInfoText()+")\n \n"+TXT_SELECT, [TXT_PETIFY, TXT_DEPETIFY, TXT_OPTIONS, TXT_LANGUAGE, TXT_CLOSE], chan(llGetKey()));
        }
    }

    state_entry()
    {
        llParticleSystem([]);
        loadConfig();
        loadLanguage(languageCode);
        string str = "";
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        llSetText(TXT_INFO+str, <1,1,1>, 1.0);
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    sensor(integer n)
    {
        names = [];
        animalIDs = [];
        list desc = [];
        string idCode;
        if (status == "waitScanP") idCode = "A"; else idCode = "X";
        integer i;
        for (i=0; i < n; i++)
        {
            key u = llDetectedKey(i);
            if (llGetSubString(llKey2Name(u), 0, 2) == SF_PREFIX+" ")
            {
                desc = llParseString2List(llList2String(llGetObjectDetails(u, [OBJECT_DESC]) , 0) , [";"], []);
                if (llList2String(desc, 0) == idCode)
                {
                    if (llList2String(desc, 1) == "EGG") names += "EGG"; else names += [llList2String(desc, 10)];
                    animalIDs += [u];
                }
            }
        }
        if (llGetListLength(names) == 0)
        {
            llOwnerSay(TXT_NOT_FOUND);
            llSetText(TXT_NOT_FOUND, <0.7, 0.1, 0.5>, 1.0);
            llSetTimerEvent(5);
        }

        else if (n > 11)
        {
            llOwnerSay(TXT_TOO_MANY +"\n" + TXT_REDUCE);
            llSetText(TXT_TOO_MANY +"\n" + TXT_REDUCE, <0.7, 0.1, 0.5>, 1.0);
            llSetTimerEvent(10);
        }
        else
        {
            llSetText("", ZERO_VECTOR, 0);
            names += [TXT_CLOSE];
            listener=-1;
            startListen();
            if (idCode == "A")
            {
                status = "waitSelectA";
                llDialog(userID, TXT_SELECT, names, chan(llGetKey()));
            }
            else
            {
                status = "waitSelectX";
                llDialog(userID, "\n"+TXT_CAUTION +"\n" +TXT_SELECT, names, chan(llGetKey()));
            }
            llSetTimerEvent(120);
        }
    }

    no_sensor()
    {
        llOwnerSay(TXT_NOT_FOUND);
        llSetTimerEvent(15);
    }

    dataserver(key id, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseString2List(m, ["|"], []);
        if (llList2String(tk,1) != PASSWORD)
        {
            return;
        }
        string cmd = llList2String(tk, 0);
        key kobject = llList2Key(tk, 2);

        if (cmd == "VERSION-REPLY")
        {
            string ncName;
            string langNCs = ",";
            integer i;
            integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                if (llGetSubString(ncName, 5, 11) == "-langA1") langNCs = langNCs + ncName +",";
            }
            osMessageObject(id, "DO-UPDATE|" +PASSWORD+"|" +(string)llGetKey() +"|animal,setpin,language_plugin,prod-rez_plugin,product,animal 1" + langNCs);
            llSetTimerEvent(15);
        }
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetText(TXT_INFO, <1,1,1>, 1.0);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
