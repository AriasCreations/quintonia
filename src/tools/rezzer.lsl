// CHANGE LOG
// Added 'backup/restore' option for babies
// Added upgrade to work with attached babies

// rezzer.lsl
// Rez animals and also update the animal.lsl script in them
// Objexct changes size/rotation tso you can rez it or wear it.

// This is used to check if updates available from Quintonia product update server
float VERSION = 5.6;    // 6 December 2020
string NAME = "SF Animal Rezzer - Quintonia";
//
integer DEBUGMODE = FALSE;    // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}
//
// config notecard can overide the following:
integer VER=-1;                 // read from config notecard - is the version of the animal script. Use -1 to force sending script with no version checking e.g. downgrades
integer sexToggle = 0;
vector  rezzPosition = <0.0, 0.0, 0.5>;     // REZ_POSITION
string  SF_PREFIX = "SF";                   // SF_PREFIX=SF
integer scanRange = 96;                     // SENSOR_DISTANCE=96
//
string  languageCode = "en-GB";      // use defaults below unless language config notecard present
//
// Multilingual support
string TXT_CLOSE="CLOSE";
string TXT_UPGRADE_ALL="UPGRADING all";
string TXT_ALL="ALL";
string TXT_SELECT="Select";
string TXT_REZ_ANIMAL="Rez an animal";
string TXT_REZZING="Rezzing";
string TXT_REZ="Rez...";
string TXT_UPGRADE="Upgrade...";
string TXT_SET_RANGE="Set Range...";
string TXT_ENTER_RADIUS="Enter upgrade radius in m (1 to 96)";
string TXT_CURRENT_VALUE="Current value is a";
string TXT_RANGE_SET="Upgrade range set to";
string TXT_CHOOSE_ANIMAL="Upgrade";
string TXT_WARNING_A="WARNING: All animals within a";
string TXT_RADIUS="radius";
string TXT_WARNING_B="will be upgraded!";
string TXT_TRYING="Trying";
string TXT_SENDING="sending items..";
string TXT_SEX="Sex";
string TXT_RANDOM="Random";
string TXT_TOGGLE="Toggle";
string TXT_ANIMAL_VERSION="Animal Version:";
string TXT_WAIT="Please allow a few seconds for the animal to initialize...";
string TXT_CANT_UPGRADE="Item can't be upgraded";
string TXT_UPGRADED="Upgraded ";
string TXT_NOT_REQUIRED="Upgrade not required for";
string TXT_NOT_FOUND="not found";
string TXT_BACKUP = "Backup";
string TXT_RESTORE = "Restore";
string TXT_NO_BACKUPS = "No backups stored";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "R1";
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer dChan;
string  mode;
integer attachedTo;     // Flags if being run as a HUD rather than rezzed as an object
integer face;
string  status;
list    buttons;
list    backups;
string  senseFor;
integer nextSex = 1;    // 1=Female, -1 = Male
string  productScript = "product";
string  birthCertNC = "birth-date";
string  statusNC = "an_statusNC";
string  rezTex;
string  codedDescNC = "CD";
string  codedHeader = "";
string  savedRot = "ZERO_ROTATION";
string  savedPos = "<0.0, 0.0, 0.0>";
key     ownerID;
integer listener=-1;
integer startOffset=0;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (listener<0)
    {
        dChan = chan(llGetKey());
        listener = llListen(dChan, "", "", "");
    }
}

multiPageMenu(string message, list opt)
{
    llSetTimerEvent(180);
    integer l = llGetListLength(opt);
    if (l < 12)
    {
        llDialog(ownerID, message, opt+[TXT_CLOSE], dChan);
    }
    else
    {
        if (startOffset >= l) startOffset = 0;
        list its = llList2List(opt, startOffset, startOffset + 9);
        llDialog(ownerID, message, [TXT_CLOSE]+its+[">>"], dChan);
    }
}

list animalButtons()
{
    string tmpStr = "";
    list buttons = [];
    integer i;
    for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
    {
        // Remove the "SF " bit for the buttons
        tmpStr = llGetInventoryName(INVENTORY_OBJECT, i);
        tmpStr = llGetSubString(tmpStr, 3, llStringLength(tmpStr));
        buttons += tmpStr;
    }
    return buttons;
}

showMainMenu()
{
    string tmpStr = "";
    if (llToUpper(llGetScriptName()) != "B-REZZER")
    {
        tmpStr = "\n \n" + TXT_SEX +": ";
        if (sexToggle == 0) tmpStr += TXT_RANDOM; else tmpStr += TXT_TOGGLE;
    }
    startListen();
    if (llToUpper(llGetScriptName()) != "B-REZZER")
    {
        multiPageMenu(TXT_SELECT+tmpStr, [TXT_SET_RANGE, TXT_SEX, TXT_LANGUAGE, TXT_REZ, TXT_UPGRADE]);
    }
    else
    {
        multiPageMenu(TXT_SELECT, [TXT_SET_RANGE, TXT_UPGRADE, TXT_LANGUAGE, TXT_REZ, TXT_BACKUP, TXT_RESTORE]);
    }
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
             if (cmd == "VER")              VER = (integer)val;
        else if (cmd == "SEX_ALTERNATE")    sexToggle = (integer)val;
        else if (cmd == "REZ_POSITION")     rezzPosition = (vector)val;
        else if (cmd == "SF_PREFIX")        SF_PREFIX = val;
        else if (cmd == "SENSOR_DISTANCE")  scanRange = (integer)val;
        else if (cmd == "LANG")             languageCode = val;
    }
}

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
    // Load lang if stored in description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "LANG") languageCode = llList2String(desc, 1);
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
                    else if (cmd == "TXT_BACKUP") TXT_BACKUP = val;
                    else if (cmd == "TXT_RESTORE") TXT_RESTORE = val;
                    else if (cmd == "TXT_UPGRADE_ALL") TXT_UPGRADE_ALL = val;
                    else if (cmd == "TXT_ALL") TXT_ALL = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_SEX") TXT_SEX = val;
                    else if (cmd == "TXT_RANDOM") TXT_RANDOM = val;
                    else if (cmd == "TXT_TOGGLE") TXT_TOGGLE = val;
                    else if (cmd == "TXT_REZ_ANIMAL") TXT_REZ_ANIMAL = val;
                    else if (cmd == "TXT_REZZING") TXT_REZZING = val;
                    else if (cmd == "TXT_REZ") TXT_REZ = val;
                    else if (cmd == "TXT_UPGRADE") TXT_UPGRADE = val;
                    else if (cmd == "TXT_SET_RANGE") TXT_SET_RANGE = val;
                    else if (cmd == "TXT_ENTER_RADIUS") TXT_ENTER_RADIUS = val;
                    else if (cmd == "TXT_CURRENT_VALUE") TXT_CURRENT_VALUE = val;
                    else if (cmd == "TXT_RANGE_SET") TXT_RANGE_SET = val;
                    else if (cmd == "TXT_CHOOSE_ANIMAL") TXT_CHOOSE_ANIMAL = val;
                    else if (cmd == "TXT_WARNING_A") TXT_WARNING_A = val;
                    else if (cmd == "TXT_RADIUS") TXT_RADIUS = val;
                    else if (cmd == "TXT_WARNING_B") TXT_WARNING_B = val;
                    else if (cmd == "TXT_TRYING") TXT_TRYING = val;
                    else if (cmd == "TXT_SENDING") TXT_SENDING = val;
                    else if (cmd == "TXT_ANIMAL_VERSION") TXT_ANIMAL_VERSION = val;
                    else if (cmd == "TXT_WAIT") TXT_WAIT = val;
                    else if (cmd == "TXT_CANT_UPGRADE") TXT_CANT_UPGRADE = val;
                    else if (cmd == "TXT_UPGRADED") TXT_UPGRADED = val;
                    else if (cmd == "TXT_NOT_REQUIRED") TXT_NOT_REQUIRED = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_NO_BACKUPS") TXT_NO_BACKUPS = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

psys(key k, string tex)
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
                    PSYS_SRC_TEXTURE,tex,
                    PSYS_SRC_MAX_AGE,5,
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

texAnim(integer animate)
{
    if (animate == TRUE) llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, face, 1, 1, 0, TWO_PI, 2.0); else llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
}

startUpgrading(string m)
{
    texAnim(TRUE);
    m = "SF " + m;
    llSleep(1.);
    llSay(0, TXT_UPGRADE_ALL +" '"+m+"' " +TXT_RANGE_SET+" "  +(string)(llRound(scanRange))+" " +TXT_RADIUS);
    senseFor=m;
    llSensor(m, "", SCRIPTED, scanRange, PI);
}

setIdleText()
{
    llSetText("...", <0,1,1>, 1.0);
    string name;
    string prompt = "\n";
    integer index;
    integer prefixLength = llStringLength(statusNC);
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    for (index = 0; index < count; index++)
    {
        name = llGetInventoryName(INVENTORY_NOTECARD, index);
        if ((llGetSubString(name, 0, prefixLength-1) == statusNC) && (name != statusNC))
        {
            prompt +=  llGetSubString(name, prefixLength+1, -1) +"\n";
        }
    }
    llSetText(TXT_REZ_ANIMAL + "\n OR \n" +TXT_CHOOSE_ANIMAL +"\n \n" +prompt, <1,1,1>,1.0);
    llSetColor(<1,1,1>, ALL_SIDES);
    texAnim(FALSE);
}


default
{

    listen(integer c, string nm, key id, string m)
    {
        debug("listen:"+m +" from:"+nm +"  mode="+mode);
        if (m == TXT_CLOSE)
        {
            llSetTimerEvent(0.1);
        }
        else if (m ==">>")
        {
            startOffset += 10;
            if (mode == "Rezzing") multiPageMenu(TXT_REZ_ANIMAL, animalButtons()); else multiPageMenu(TXT_SELECT, buttons);
        }
        else if (m ==TXT_SET_RANGE)
        {
            mode = "waitRange";
            llTextBox(ownerID, "\n" + TXT_ENTER_RADIUS+"\n" +TXT_CURRENT_VALUE+" "  +(string)(llRound(scanRange)) + " m " +TXT_RADIUS, dChan);
        }
        else if  (m == TXT_UPGRADE)
        {
            if (llToUpper(llGetScriptName()) == "B-REZZER")
            {
                texAnim(TRUE);
                llSetText(TXT_UPGRADE+"...", <1.0, 0.0, 1.0>, 1.0);
                mode = "waitSearchBaby";
                llRegionSay(FARM_CHANNEL, "UPGRADE-REQ|"+PASSWORD+"|"+(string)ownerID+"|"+(string)llGetKey());
                llSetTimerEvent(60);
            }
            else
            {
                mode = "upgradingAnimals";
                buttons = animalButtons();
                multiPageMenu("\n " +TXT_CHOOSE_ANIMAL+"\n\n" +TXT_WARNING_A+" " +(string)(llRound(scanRange)) + "m " +TXT_RADIUS + " " + TXT_WARNING_B +"\n \n", [TXT_ALL]+buttons);
            }
        }
        else if (m == TXT_REZ)
        {
            string tmpStr = "\n \n";
            if (llToUpper(llGetScriptName()) != "B-REZZER")
            {
                tmpStr += TXT_SEX +": ";
                if (sexToggle == 0)
                {
                    tmpStr += TXT_RANDOM;
                }
                else
                {
                    if (nextSex == -1) tmpStr += "♂ m"; else tmpStr += "♀ f";
                }
            }
            mode = "Rezzing";
            multiPageMenu("\n" +TXT_REZ_ANIMAL +tmpStr, animalButtons());
        }
        else if (m == TXT_BACKUP)
        {
            texAnim(TRUE);
            llSetText(TXT_BACKUP+"...", <1.0, 0.0, 1.0>, 1.0);
            mode = "waitBackupNC";
            if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD) llRemoveInventory(statusNC);
            llRegionSay(FARM_CHANNEL, "BACKUP-REQ|"+PASSWORD+"|"+(string)ownerID+"|"+(string)llGetKey());
            llSetTimerEvent(30);
        }
        else if (m == TXT_RESTORE)
        {
            if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD) llRemoveInventory(statusNC);
            backups = [];
            buttons = [];
            string name;
            string prompt = "\n";
            integer index;
            integer tally = 0;
            integer prefixLength = llStringLength(statusNC);
            integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
            for (index = 0; index < count; index++)
            {
                name = llGetInventoryName(INVENTORY_NOTECARD, index);
                if (llGetSubString(name, 0, prefixLength-1) == statusNC)
                {
                    buttons += llGetSubString(name, prefixLength+1, -1);
                    tally++;
                    backups += (string)tally;
                    prompt += (string)tally +"\t" + llGetSubString(name, prefixLength+1, -1) +"\n";
                }
            }
            if (llGetListLength(buttons) != 0)
            {
                mode = "waitBackupSelect";
                startOffset = 0;
                multiPageMenu(TXT_SELECT+prompt, backups);
            }
            else
            {
                llOwnerSay(TXT_NO_BACKUPS);
            }
        }
        else if (m == TXT_ALL && mode == "upgradingAnimals")
        {
            texAnim(TRUE);
            integer i;
            for (i=0; i < llGetListLength(buttons); i++)
            {
                startUpgrading(llList2String(buttons,i));
            }
        }
        else if (m == TXT_SEX)
        {
            sexToggle = !sexToggle;
            mode = "";
            showMainMenu();
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
            mode = "";
        }
        else if (mode == "waitRange")
        {
            mode = "";
            integer tmpVal = (integer)m;
            if (tmpVal >96) scanRange = 96;
            else if (tmpVal <1) scanRange = 1; else scanRange = tmpVal;
            llOwnerSay(TXT_RANGE_SET+" " + scanRange + "m " +TXT_RADIUS);
        }
        else if (mode == "upgradingAnimals")
        {
            texAnim(TRUE);
            llOwnerSay(TXT_ANIMAL_VERSION+": " +(string)VER);
            startUpgrading(m);
        }
        else  if (mode == "Rezzing")
        {
            texAnim(TRUE);
            m = "SF " + m;
            llSay(0, TXT_REZZING+" "+m+". "+TXT_WAIT);
            llSetText(TXT_REZZING+" "+m+"\n"+TXT_WAIT +"\n ", <1.000, 0.522, 0.106>,1.0);
            llSetColor(<1.000, 0.522, 0.106>, 4);
            psys(ownerID, rezTex);
            vector pos;
            if (attachedTo == 0)
            {
                pos = llGetPos() + <1.0, 0.0, 0.2>*llGetRot();
            }
            else
            {
                key    owner = llGetOwner();
                vector agent = llGetAgentSize(owner);
                pos = llList2Vector(llGetObjectDetails(owner, [OBJECT_POS]), 0);
                //  "pos" needs to be adjusted to not rez at head height.
                pos.z = pos.z - (agent.z / 2) + 0.25;
                //  makes sure it found the owner, a zero vector evaluates as false
                 // if(agent)
                // llSetPos(pos);
            }
            //llRezObject(m, pos, <0,0,0>, ZERO_ROTATION, nextSex);
            llMessageLinked(LINK_SET, -1, "REZ_PRODUCT|" +PASSWORD +"|" +(string)id +"|" +m, NULL_KEY);
        }
        else if (mode == "waitBackupSelect")
        {
            texAnim(TRUE);
            integer index = (integer)m;
            index = index -1;
            string name = statusNC + ":" + llList2String(buttons, index);
            if (llGetInventoryType(name) == INVENTORY_NOTECARD)
            {
                llSetText(TXT_RESTORE+"...", <1,1,1>, 1.0);
                if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
                {
                    llRemoveInventory(statusNC);
                    llSleep(0.2);
                }
                string tmpStr = osGetNotecard(name);
                osMakeNotecard(statusNC, tmpStr);
                //
                name = codedDescNC + ":" + llList2String(buttons, index);
                if (llGetInventoryType(name) == INVENTORY_NOTECARD)
                {
                    if (llGetInventoryType(codedDescNC) == INVENTORY_NOTECARD)
                    {
                        llRemoveInventory(codedDescNC);
                        llSleep(0.2);
                    }
                    tmpStr = osGetNotecard(name);
                    osMakeNotecard(codedDescNC, tmpStr);
                    llSleep(1.0);
                    llRegionSay(FARM_CHANNEL, "RESTORE-REQ|"+PASSWORD+"|"+(string)ownerID+"|"+(string)llGetKey());
                }
                else
                {
                    llOwnerSay(TXT_NO_BACKUPS);
                    texAnim(FALSE);
                }
            }
            else
            {
                llOwnerSay(TXT_NO_BACKUPS);
                texAnim(FALSE);
            }
        }
        else
        {
            // ERROR!
        }
    }

    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(listener);
        listener = -1;
        mode = "";
        setIdleText();
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) == ownerID) showMainMenu();
    }

    state_entry()
    {
        texAnim(FALSE);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        loadLanguage(languageCode);
        ownerID = llGetOwner();
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (i=0; i<count; i++)
        {
            if (llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 6) == "product") productScript = llGetInventoryName(INVENTORY_SCRIPT, i);
        }
        setIdleText();
        if (llToUpper(llGetScriptName()) != "B-REZZER")
        {
            rezTex = "rez-animal";
            attachedTo =  llGetAttached();
            if (attachedTo == 0)
            {
                face = 0;
                vector pos = llGetPos();
                pos.z += 0.5;
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, <0.5, 0.5, 0.5>,
                                                          PRIM_POSITION, pos,
                                                          PRIM_ROTATION, ZERO_ROTATION ]);
            }
            else
            {
                face = 5;
                rotation rot = llEuler2Rot(<0, 45, 0>*DEG_TO_RAD);
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, <0.15, 0.10, 0.15>,
                                                          PRIM_ROTATION, rot ]);
            }
        }
        else
        {
            rezTex = "rez-baby";
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(2.0);
        llGiveInventory(id, llKey2Name(id));
        llGiveInventory(id , "sfp");
        string ncName;
        string ncSuffix;
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
        // For baby rezzer need to give them the B1 and B2 language notecards
        if (llToUpper(llGetScriptName()) == "B-REZZER")
        {
            debug("giving: B1 & B2 languages");
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                ncSuffix = llGetSubString(ncName, 5, 11);
                if (ncSuffix == "-langB1" || ncSuffix == "-langB2") llGiveInventory(id, ncName);
            }
        }
        else
        {
            // For animals just need to give the A1 language notecards
            debug("giving: A1 languages");
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                if (llGetSubString(ncName, 5, 11) == "-langA1") llGiveInventory(id, ncName);
            }
        }
        debug("giving script: language_plugin");
        llRemoteLoadScriptPin(id, "language_plugin", 999, TRUE, 1);
        debug("giving: angel texture");
        llGiveInventory(id, "angel");
        debug("giving script: animal-heaven");
        llRemoteLoadScriptPin(id, "animal-heaven", 999, TRUE, 1);
        debug("giving script: prod-rez_plugin");
        llRemoteLoadScriptPin(id, "prod-rez_plugin", 999, TRUE, 1);
        // If this is the baby rezzer give them a birth certificate
        if( llToUpper(llGetScriptName()) == "B-REZZER")
        {
            debug("giving: birth certificate");
            // Give them birth certificate
            if (llGetInventoryType(birthCertNC) == INVENTORY_NOTECARD) llRemoveInventory(birthCertNC);
            osMakeNotecard(birthCertNC, llGetDate());
            llGiveInventory(id, birthCertNC);
            debug("giving script: hud-main");
            llRemoteLoadScriptPin(id, "hud-main", 999, TRUE, 1);
        }
        debug("giving script: "+productScript);
        //llGiveInventory(id, "product");
        llGiveInventory(id, productScript);
        if (sexToggle == TRUE)
        {
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, nextSex);
            if (nextSex == -1) nextSex = 1; else nextSex = -1;
        }
        else
        {
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, 0);
        }
        llSetTimerEvent(0.5);
    }

    sensor(integer n)
    {
        integer i;
        if (mode == "upgradingAnimals")
        {
            for (i=0; i < n; i++)
            {
                key u = llDetectedKey(i);
                list desc = llParseString2List(llList2String(llGetObjectDetails(u, [OBJECT_DESC]) , 0) , [";"], []);
                if (llList2String(desc, 0) == "A")
                {
                    llSay(0, TXT_TRYING +" '"+llList2String(desc, 10)+"'");
                    messageObj(u, "VERSION-CHECK|"+PASSWORD+"|"+(string)llGetKey());
                    llSleep(2);
                }
                else
                {
                    // llOwnerSay(llKey2Name(u) +" ("+(string)u+") " +TXT_CANT_UPGRADE);
                }
            }
        }
    }

    no_sensor()
    {
        llSay(0, senseFor+" " +TXT_NOT_FOUND);
        llSetTimerEvent(5);
    }

    dataserver(key id, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseString2List(m, ["|"], []);
        if (llList2String(tk,1) == PASSWORD)
        {
            string cmd = llList2String(tk, 0);
            key kobject = llList2Key(tk, 2);

            if (cmd == "VERSION-REPLY")
            {
                //  Versions before 4.1 can't be upgraded
                if (llList2Integer(tk, 3) <41)
                {
                    //
                }
                else if ((llList2Integer(tk, 3) < VER) || (VER == -1))
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
                    messageObj(id, "DO-UPDATE|" +PASSWORD+"|" +(string)llGetKey() +"|animal,setpin,language_plugin,prod-rez_plugin,product,animal 1,animal-heaven,angel,hud-main" + langNCs);
                }
                else
                {
                    llOwnerSay(TXT_NOT_REQUIRED +": " +llKey2Name(id) +"\n" + (string)id);
                    if (llToUpper(llGetScriptName()) == "B-REZZER") llSetTimerEvent(0.1);
                }
                llSetTimerEvent(15);
            }
            else if (cmd == "DO-UPDATE-REPLY")
            {
                integer ipin = llList2Integer(tk, 3);
                llOwnerSay("PIN="+(string)ipin+", " +TXT_SENDING +"...");
                string ncName;
                string ncSuffix;
                integer i;
                integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
                // For baby rezzer need to give them the B1 and B2 language notecards and the latest hud-main script
                if (llToUpper(llGetScriptName()) == "B-REZZER")
                {
                    for (i=0; i<count; i+=1)
                    {
                        ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                        ncSuffix = llGetSubString(ncName, 5, 11);
                        if (ncSuffix == "-langB1" || ncSuffix == "-langB2") llGiveInventory(id, ncName);
                    }
                    llRemoteLoadScriptPin(kobject, "hud-main", ipin, TRUE, 0);
                }
                else
                {
                    // For animals just need to give the A1 language notecards
                    for (i=0; i<count; i+=1)
                    {
                        ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                        if (llGetSubString(ncName, 5, 11) == "-langA1") llGiveInventory(id, ncName);
                    }
                }
                llRemoteLoadScriptPin(kobject, "language_plugin", ipin, TRUE, 0);
                llGiveInventory(id, "angel");
                llRemoteLoadScriptPin(kobject, "animal-heaven", ipin, TRUE, 0);
                llRemoteLoadScriptPin(kobject, "prod-rez_plugin", ipin, TRUE, 0);
                llGiveInventory(kobject, "product");
                llRemoteLoadScriptPin(kobject, "animal", ipin, TRUE, 0);
                list desc = llParseString2List(llList2String(llGetObjectDetails(kobject, [OBJECT_DESC]) , 0) , [";"], []);
                llSay(0, TXT_UPGRADED +" "+ llList2String(desc,10)+ " (" +llKey2Name(kobject)+")");
            }
            else if (cmd == "STATUSNC-SENT")
            {
                if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
                {
                    string tmpStr = osGetNotecard(statusNC);
                    string timeStamp = llGetTimestamp();
                    osMakeNotecard(statusNC+":"+timeStamp, tmpStr);
                    llSleep(1.0);
                    llRemoveInventory(statusNC);
                    codedHeader = llList2String(tk, 2);
                    savedRot = llList2String(tk, 3);
                    savedPos = llList2String(tk, 4);
                    osMakeNotecard(codedDescNC+":"+timeStamp, codedHeader+"\n"+ savedRot +"\n" +savedPos);
                    llSetTimerEvent(0.1);
                }
            }
            else if (cmd == "STATUSNC-DEAD")
            {
                codedHeader = osGetNotecardLine(codedDescNC, 0);
                savedRot = osGetNotecardLine(codedDescNC, 1);
                savedPos = osGetNotecardLine(codedDescNC, 2);
                llGiveInventory(llList2Key(tk, 2), statusNC);
                llSleep(0.5);
                messageObj(llList2Key(tk, 2), "GET-STATUSNC|"+PASSWORD+"|"+codedHeader+"|"+savedRot+"|"+savedPos);
                llSetTimerEvent(5.0);
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message:"+str);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "VERSION-REQUEST")
        {
            llMessageLinked(LINK_SET, (integer)(10*VERSION), "VERSION-REPLY", (key)NAME);
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetText(TXT_REZ_ANIMAL, <1,1,1>,1.0);
            llSetObjectDesc("LANG;"+languageCode);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
        }
    }

}
