// Quintonia map/TP HUD
// Teleport using only LSL commands

// Used to check for updates from Quintonia product update server
float VERSION = 3.1;    // 25 March 2020
string NAME = "Quintonia Map HUD (wear)";

// For multilingual support
string TXT_WELCOME = "Welcome to";
string TXT_ADJUSTING = "adjusting map, may take a few seconds...";
string TXT_NEED_PERMISSION = "Sorry, I don't have your permission yet to teleport you...";
string TXT_ERROR1 = "Sorry, your viewer doesn't support touched faces";
string TXT_ERROR2 = "Sorry, the touch position upon the texture could not be determined";
string TXT_ERROR3 = "Sorry, something went wrong - attempting to reset HUD";
string TXT_SELECT ="Select";
string TXT_CLOSE = "CLOSE";
string TXT_LANGUAGE="Language";
//
string  languageCode = "en-GB";             // LANG
//
string SUFFIX = "H2";

string gridM = "Mintor";
list crossRefM = [1, 15, 22, 28, 29, 35, 36, 44, 37, 23, 10, 18, 26, 40, 13];
//
list locationsM = [ <142, 113, 23>,     // 1 Learning centre
                    <142, 146, 23>,     // 2 Welcome centre
                    <117, 225, 23>,     // 3 Petting Zoo
                    < 42, 290, 23>,     // 4 Water Mill
                    < 93, 312, 23>,     // 5 Geodome
                    < 38, 401, 66>,     // 6 Mountain top
                    <105, 413, 25>,     // 7 Picnic area
                    <160, 459, 23>,     // 8 Art gallery & Café
                    <190, 332, 23>,     // 9 Dino park
                    <133, 276, 23>,     // 10 Nature reserve
                    <269, 134, 23>,     // 11 Winter garden
                    <344, 170, 23>,     // 12 Residential
                    <413, 219, 23>,     // 13 Estate office
                    <348, 362, 23>,     // 14 Farm
                    <475, 171, 22> ];   // 15 Rainbow Island
//
list namesM =     [ "1 Learning centre",
                    "2 Welcome centre",
                    "3 Petting Zoo",
                    "4 Water Mill",
                    "5 Geodome",
                    "6 Mountain top",
                    "7 Picnic area",
                    "8 Art gallery & Café",
                    "9 Dino park",
                    "10 Nature reserve",
                    "11 Winter garden",
                    "12 Residential",
                    "13 Estate office",
                    "14 Farm",
                    "15 Rainbow Island" ];

string gridL = "Luxgrave";
list crossRefL = [18, 12, 6, 1, 15, 29, 43, 44, 45, 30, 24, 39, 40, 33, 26];
//
list locationsL = [ <328, 178, 23>,     // 1 Harbour
                    <356, 136, 22>,     // 2 Pool
                    <455,  17, 23>,     // 3 Unicorn island
                    <106,  22, 22>,     // 4 Venereum Gardens
                    <143, 145, 22>,     // 5 Venereum
                    < 72, 240, 53>,     // 6 View point
                    <106, 440, 23>,     // 7 Sea view 1
                    <139, 440, 23>,     // 8 Sea view 2
                    <184, 440, 23>,     // 9 Sea view 3
                    <189, 382, 23>,     // 10 Free land -A
                    <245, 284, 23>,     // 11 Free land -b
                    <323, 382, 23>,     // 12 QuintoDisco
                    <362, 407, 27>,     // 13 East Side 3
                    <362, 354, 27>,     // 14 East Side 2
                    <362, 298, 27> ];   // 15 East Side 1
//
list namesL = [ "1 Harbour",
                "2 Pool",
                "3 Unicorn island",
                "4 Venereum Gardens",
                "5 Venereum",
                "6 View point",
                "7 Sea view 1",
                "8 Sea view 2",
                "9 Sea view 3",
                "10 Free land - A",
                "11 Free land - B",
                "12 QuintoDisco",
                "13 East Side 3",
                "14 East Side 2",
                "15 East Side 1" ];

string gridS = "Sandy Island";

// Location selection grid
integer numberOfRows    = 7;
integer numberOfColumns = 7;

// For hide/face show of HUD
vector rotMintor = <0.0, 270.0, 180.0>;
vector rotLuxgrave = <0.0, 90.0, 0.0>;
vector rotHide = <180.0, 0.0, 180.0>;
//
key owner = NULL_KEY;
vector landingPoint;
integer tpAllowed;
string thisRegion = "";
vector simGlobalCoords;
integer listener = -1;
integer listenTs;
// TP avatar rotation
float gAngle = 180.0;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

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


regionCheck()
{
    if ((thisRegion == gridM) || (thisRegion == gridL))
    {
        numberOfRows    = 7;
        numberOfColumns = 7;
        // Set correct rotation of hud for current region
        if (thisRegion == gridM)
        {
            llSetClickAction(CLICK_ACTION_TOUCH);
            llOwnerSay(TXT_WELCOME +" " + gridM + " - " +TXT_ADJUSTING);
            llSetLinkTexture(1, thisRegion+"_"+languageCode, 0);
            llSetRot(llEuler2Rot(rotMintor * DEG_TO_RAD));
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
        else if (thisRegion == gridL)
        {
            llSetClickAction(CLICK_ACTION_TOUCH);
            llOwnerSay(TXT_WELCOME +" " + gridL + " - " + TXT_ADJUSTING);
            llSetLinkTexture(2, thisRegion+"_"+languageCode, 0);
            llSetRot(llEuler2Rot(rotLuxgrave * DEG_TO_RAD));
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
        else
        {
            // Something wrong! marker1
            llOwnerSay(TXT_ERROR3);
            llResetScript();
        }

        if (tpAllowed == FALSE) llRequestPermissions(owner, PERMISSION_TELEPORT);
    }
    else
    {
        numberOfRows    = 1;
        numberOfColumns = 2;
        llOwnerSay(TXT_WELCOME + " " + thisRegion);
        // Rotate to edge on
        llSetRot(llEuler2Rot(rotHide * DEG_TO_RAD));
        llSetClickAction(CLICK_ACTION_NONE);
    }

}

// index=0 for Mintor, 1 for Luxgrave, 2 for Sandy Island
showMap(integer index)
{
    string simName;
    if (index == 0)
    {
        simName = gridM;
        landingPoint = llList2Vector(locationsM, 1);
    }
    else if (index == 1)
    {
        simName = gridL;
        landingPoint = llList2Vector(locationsL, 0);
    }
    else
    {
        simName = gridS;
        landingPoint = <128, 128, 23>;
    }
    llMapDestination(simName, landingPoint, ZERO_VECTOR);
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
                if (cmd =="LANG") languageCode = val;
        }
    }
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "H")
    {
        languageCode = llList2String(desc, 1);
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
                         if (cmd == "TXT_WELCOME")        TXT_WELCOME = val;
                    else if (cmd == "TXT_ADJUSTING")       TXT_ADJUSTING = val;
                    else if (cmd == "TXT_NEED_PERMISSION") TXT_NEED_PERMISSION = val;
                    else if (cmd == "TXT_ERROR1") TXT_ERROR1 = val;
                    else if (cmd == "TXT_ERROR2") TXT_ERROR2 = val;
                    else if (cmd == "TXT_ERROR3") TXT_ERROR3 = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}



default
{

    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        tpAllowed = FALSE;
        owner = llGetOwner();
        thisRegion = llGetRegionName();
        llRequestSimulatorData(thisRegion, DATA_SIM_POS);
        loadConfig();
        loadLanguage(languageCode);
        llSleep(2);
        regionCheck();
    }

    touch_start(integer num_detected)
    {
        if (simGlobalCoords == ZERO_VECTOR)
        {
            llOwnerSay(TXT_ERROR3);
            llResetScript();
        }

        if (tpAllowed == TRUE)
        {
            vector touchUV = llDetectedTouchUV(0);
            integer face = llDetectedTouchFace(0);
            integer side = llDetectedLinkNumber(0);     // Side 1 = Mintor,  Side 2 = Luxgrave,  3 = Other

            if (face == TOUCH_INVALID_FACE)
                llOwnerSay(TXT_ERROR1);
                    else if (touchUV == TOUCH_INVALID_TEXCOORD)
                        llOwnerSay(TXT_ERROR2);
            else if (face == 0)
            {
                // Not map so show menu
                list options = [];
                if (thisRegion == gridM) options += [gridL, gridS];
                else if (thisRegion == gridL) options += [gridM, gridS];
                else if (thisRegion == gridS) options += [gridM, gridL];
                options += [TXT_LANGUAGE, TXT_CLOSE];
                startListen();
                llDialog(owner,  TXT_SELECT, options, chan(llGetKey()));
                llSetTimerEvent(300);
            }
            else
            {
                //      ZERO_VECTOR (<0.0, 0.0, 0.0> ... the origin) is in the bottom left corner of the texture
                //      touchUV.x goes across the texture from left to right
                //      touchUV.y goes up the texture from bottom to top
                integer columnIndex = (integer) (touchUV.x * numberOfColumns);
                integer rowIndex    = (integer) (touchUV.y * numberOfRows);
                integer cellIndex   = rowIndex * numberOfColumns + columnIndex;
                integer locationCell;

                if (side == 1) locationCell = llListFindList(crossRefM, [cellIndex]);
                    else if (side == 2) locationCell = llListFindList(crossRefL, [cellIndex]);
                        else if (side == 3)
                        {
                            if (touchUV.x < 0.5) locationCell = 0; else locationCell = 1;
                            showMap(locationCell);
                            return;
                        }
                            else return;

                if (locationCell == -1)
                {
                    // Not valid map
                    llOwnerSay(TXT_ERROR2);
                    return;
                }
                else
                {
                    if (locationCell == -1) return;

                    if (side ==1)
                    {
                        // Mintor location
                        if (thisRegion == gridM)
                        {
                            landingPoint = llList2Vector(locationsM, locationCell);
                            vector LookAt = <llCos(gAngle * DEG_TO_RAD),llSin(gAngle * DEG_TO_RAD),0.0>;
                            llTeleportAgent(owner, "", landingPoint, LookAt);
                        }
                        else
                        {
                            showMap(1);
                        }
                    }
                    else
                    {
                        if (locationCell != -1)
                        {
                            // Luxgrave location
                            if (thisRegion == gridL)
                            {
                                landingPoint = llList2Vector(locationsL, locationCell);
                                vector LookAt = <llCos(gAngle * DEG_TO_RAD),llSin(gAngle * DEG_TO_RAD),0.0>;
                                llTeleportAgent(owner, "", landingPoint, LookAt);
                            }
                            else
                            {
                                showMap(0);
                            }
                        }
                    }
                }
            }
        }
        else
        {
            llOwnerSay(TXT_NEED_PERMISSION);
            llRequestPermissions(owner, PERMISSION_TELEPORT);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (message == gridM)
        {
            showMap(0);
        }
        else if (message == gridL)
        {
            showMap(1);
        }
        else if (message == gridS)
        {
            showMap(2);
        }
    }

    timer()
    {
        regionCheck();
        checkListen();
        llSetTimerEvent(30);
    }

    //  dataserver event only called if data is returned or in other words, if you request data for a sim that does
    //  not exist this event will NOT be called.
    dataserver(key query_id, string data)
    {
        simGlobalCoords = (vector)data;
    }

    run_time_permissions(integer perm)
    {
        // if permission request has been denied (read ! as not)
        if (!(perm & PERMISSION_TELEPORT))
        {
            tpAllowed = FALSE;
            llRequestPermissions(owner, PERMISSION_TELEPORT);
        }
        else
        {
          tpAllowed = TRUE;
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            tpAllowed = FALSE;
            llResetScript();
        }
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
        }
        if (change & CHANGED_REGION)
        {
            thisRegion = llGetRegionName();
            regionCheck();
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "VERSION-REQUEST")
        {
            llMessageLinked(LINK_SET, (integer)(10*VERSION), "VERSION-REPLY", (key)NAME);
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetObjectDesc("H;" + languageCode);
            integer linknumber;
            if (thisRegion == gridM) linknumber = 1; else linknumber = 2;
            llSetLinkTexture(linknumber, thisRegion+"_"+languageCode, 0);
        }
    }

}
