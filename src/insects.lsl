// insects.lsl
// This script is used for insect farms such as bees, silkworks, cochineal beatles ect
//
float VERSION = 5.0;  // BETA  10 October 2020

integer DEBUGMODE = TRUE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// config notecard can override these
vector  rezzPosition = <0.0, 1.5, 2.0>;  // REZ_POSITION=<0.0, 1.5, 2.0>   (where to rez product)
string  SF_PRODUCT = "SF Honey";         // PRODUCT
string  insectName = "Bees";             // INSECT=Bees
float   waterMinZ;                       // WATER_ZMIN=  prim Z position
float   waterMaxZ;                       // WATER_ZMAX
integer fill = 10;                       // INITIAL_LEVEL=10         What level should we start at when rezzed
integer WATERTIME = 43200;               // WATERTIME=43200          How often in seconds to increase level by 10%  (43200 = 12 hours)
string  REQUIRES = "";                   // REQUIRES=WATER_LEVEL     WATER_LEVEL forces it to be at water level to work.  Can also specify item to scan for
integer range = 6;                       // RANGE=6                  Radius to scan for REQUIRES item
integer impactEnabled = TRUE;            // IMPACT=1                 Set to 0 to disable the impact mode
string  languageCode = "en-GB";          // LANG=en-GB

// Language support
string TXT_AGITATION = "agitation";
string TXT_ALERT = "Watch out";
string TXT_LEVEL = "level";
string TXT_NEEDS = "Needs";
string TXT_NO_PRODUCT =  "Sorry, not ready yet";
string TXT_SEARCHING = "Searching";
string TXT_UNHAPPY = "are not happy";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_ERROR_NO_CONFIG = "Error: No config Notecard found.\nI can't work without one";
string TXT_LANGUAGE="@";

//
string SUFFIX = "I2";

string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer lastTs;
integer angry;
key     lastUser = NULL_KEY;
integer singleLevel = 100;
integer searchInterval = 60;
string  insectImage = "";
string  insectSound = "";
integer active = FALSE;
string  status = "";
string  floatMsg = "";
key     insectTarget = NULL_KEY;
integer toggle = FALSE;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
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
                         if (cmd == "REZ_POSITION")     rezzPosition = (vector)val;
                    else if (cmd == "PRODUCT")          SF_PRODUCT = val;
                    else if (cmd == "INSECT")           insectName = val;
                    else if (cmd == "WATER_ZMIN")       waterMinZ = (float)val;
                    else if (cmd == "WATER_ZMAX")       waterMaxZ = (float)val;
                    else if (cmd == "INITIAL_LEVEL")    fill = (integer)val;
                    else if (cmd == "WATERTIME")        WATERTIME = (integer)val;
                    else if (cmd == "REQUIRES")         REQUIRES = val;
                    else if (cmd == "RANGE")            range = (integer)val;
                    else if (cmd == "IMPACT")           impactEnabled = (integer)val;
                    else if (cmd == "LANG")             languageCode = val;
                }
            }
        }
        if (WATERTIME < 100) WATERTIME = 100;
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
                         if (cmd == "TXT_ALERT") TXT_ALERT = val;
                    else if (cmd == "TXT_NO_PRODUCT") TXT_NO_PRODUCT = val;
                    else if (cmd == "TXT_UNHAPPY") TXT_UNHAPPY = val;
                    else if (cmd == "TXT_LEVEL") TXT_LEVEL = val;
                    else if (cmd == "TXT_NEEDS") TXT_NEEDS = val;
                    else if (cmd == "TXT_AGITATION") TXT_AGITATION = val;
                    else if (cmd == "TXT_SEARCHING") TXT_SEARCHING = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_NO_CONFIG") TXT_ERROR_NO_CONFIG = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

saveToDesc()
{
    llSetObjectDesc((string)fill +";" +(string)lastTs +";" +(string)angry);
}

loadFromDesc()
{
    list settings = llParseString2List(llGetObjectDesc(), [";"], []);
    if (llGetListLength(settings) != 0)
    {
        fill   = llList2Integer(settings, 0);
        lastTs = llList2Integer(settings, 1);
        angry  = llList2Integer(settings, 2);
    }
    else
    {
        saveToDesc();
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

refresh()
{
    if ((insectTarget != NULL_KEY) && (toggle == FALSE))
    {
        swarm(0, 0.3, insectTarget);
        toggle = TRUE;
    }
    else if (lastUser != NULL_KEY)
    {
        toggle = FALSE;
        swarm(5, 0.1, lastUser);
    }
    else
    {
        toggle = FALSE;
        swarm(0, 0.2, llGetKey());
    }

    if (active == TRUE)
    {
        integer do_fill = FALSE;
        if (llGetUnixTime() - lastTs >  WATERTIME)
        {
            if (active == TRUE)
            {
                do_fill = TRUE;
                lastTs = llGetUnixTime();
            }
        }
        if (do_fill == TRUE)
        {
            if (angry <5) fill += 10;
            if (fill >100) fill = 100;
        }
    }
    vector color;
    string extraText = "";
    if (fill == 100) color = <0.180, 0.800, 0.251>; else color = <1, 1, 1>;
    if (angry > 1)
    {
        extraText = "\n" +insectName + " "+TXT_AGITATION + ": " + (string)angry + "%\n";
        if (angry > 84) color = <1.000, 0.255, 0.212>;
         else color = <1.000, 0.863, 0.000>;
    }
    angry -= 1;
    if (angry <0) angry = 0;
    saveToDesc();
    // Set the level prim position if one exists
    vector v;
    integer ln = getLinkNum("Water");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* fill/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }
    floatMsg = SF_PRODUCT +" " +TXT_LEVEL +" " + (string)fill+ "%\n" + extraText;
    debug("refresh: status="+status+" active="+(string)active+" floatMsg="+floatMsg);
    if (active == TRUE) llSetText(floatMsg, color, 1.0); else errorText();
}

errorText()
{
    llSetText(TXT_NEEDS + ": " +REQUIRES +"\n"+floatMsg, <1, 0, 0>, 1.0);
    lastTs = llGetUnixTime();
}

swarm(integer time, float rate, key k)
{
    llMessageLinked(LINK_SET, time, "FX|" +PASSWORD+"|" +(string)rate+"|" +(string)angry+"|" +insectImage+"|" +(string)k, "");
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
        lastTs = llGetUnixTime();
        angry = 0;
        llSetText("", ZERO_VECTOR, 0);
        llParticleSystem([]);
        insectSound = llGetInventoryName(INVENTORY_SOUND, 0);
        insectImage = llGetInventoryName(INVENTORY_TEXTURE, 0);
        loadConfig();
        loadLanguage(languageCode);
        loadFromDesc();
        llVolumeDetect(impactEnabled);
        if (REQUIRES != "")
        {
            llSetText(TXT_NEEDS + ": "+ REQUIRES +"\n"+TXT_SEARCHING+"...", <0.224, 0.800, 0.800>, 1.0);
            swarm(searchInterval-1, 0.2, llGetKey());
            status = "nameScan";
            llSensorRepeat(REQUIRES, NULL_KEY, ( AGENT | PASSIVE | ACTIVE ), range, PI, searchInterval);
        }
        else
        {
            llSetText("", ZERO_VECTOR, 0);
            active = TRUE;
            llSetTimerEvent(1);
        }
    }

    touch_end(integer n)
    {
        lastUser = llDetectedKey(0);
        if (llSameGroup(llDetectedKey(0)) == TRUE)
        {
            refresh();
            if (fill < singleLevel)
            {
                llRegionSayTo(lastUser, 0, TXT_NO_PRODUCT +": " +SF_PRODUCT);
                lastUser = NULL_KEY;
            }
            else if (angry > 9)
            {
                llRegionSayTo(lastUser, 0, TXT_UNHAPPY);
                lastUser = NULL_KEY;
            }
            else
            {
                fill = fill - singleLevel;
                angry = 0;
                saveToDesc();
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PRODUCT, NULL_KEY);
            }
            floatMsg = SF_PRODUCT +" " +TXT_LEVEL +" " + (string)fill+ "%\n";
            if (active == FALSE)
            {
                errorText();
                llSetTimerEvent(0.1);
            }
            else
            {
                llSetText(floatMsg, <1,1,1>, 1.0);
            }
        }
        else
        {
            llRegionSayTo(lastUser, 0, TXT_ERROR_GROUP);
            lastUser = NULL_KEY;
        }
    }

    collision_start(integer n)
    {
        if (impactEnabled == TRUE)
        {
            lastUser = llDetectedKey(0);
            llRegionSayTo(lastUser, 0, TXT_ALERT + " " +insectName +"!");
            llPlaySound(insectSound, 1.0);
            angry +=10;  if (angry > 100) angry = 100;
            llRegionSay(FARM_CHANNEL, "STUNG|" + PASSWORD + "|" + (string)lastUser);
            swarm(10, 0.02, lastUser);
            llTriggerSound(insectSound, 1.0);
            refresh();
            llSetTimerEvent(10);
        }
    }

    timer()
    {
        llSetTimerEvent(WATERTIME);
        refresh();
        lastUser = NULL_KEY;
    }

    sensor(integer count)
    {
        debug("sensor:status="+status+" active="+(string)active);
        if (status == "nameScan")
        {
            active = TRUE;
            insectTarget = llDetectedKey(0);
            swarm(10, 0.2, insectTarget);
        }
        else
        {
            active = FALSE;
            list desc;
            integer i=0;
            while ((i < count) || (active == FALSE))
            {
                desc = llParseString2List(llList2String(llGetObjectDetails(llDetectedKey(i), [OBJECT_DESC]),0), [";"], []);
                if (llListFindList(desc, [REQUIRES]) != -1)
                {
                    llOwnerSay(llDumpList2String(desc, ";"));
                    active = TRUE;
                    insectTarget = llDetectedKey(i);
                    swarm(10, 0.2, insectTarget);
                }
                i +=1;
            }
        }
        refresh();
    }

    no_sensor()
    {
        debug("no_sensor:status="+status+" active="+(string)active+"  (range="+(string)range+"m)");
        llSetText(TXT_NEEDS + ": "+ REQUIRES +"\n"+TXT_SEARCHING+"...", <1.000, 0.863, 0.000>, 1.0);

        if (status == "nameScan")
        {
            status = "descScan";
            llSensorRemove();
            llSensorRepeat("", NULL_KEY, ( AGENT | PASSIVE | ACTIVE ), range, PI, searchInterval);
        }
        else
        {
            active = FALSE;
            refresh();
        }
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
        debug("link_message="+m);
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
        debug("dataserver="+m);
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
