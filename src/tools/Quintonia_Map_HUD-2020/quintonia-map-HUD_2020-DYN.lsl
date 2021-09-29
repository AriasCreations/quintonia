// Quintonia map/TP HUD
// Teleport using only LSL commands

// Used to check for updates from Quintonia product update server
float VERSION = 3.0;    // 1 March 2020
string NAME = "Quintonia Map HUD (wear)";

//SimAddress

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
list languages = ["fr-FR", "es-ES", "en-GB", "de-DE"];

string SUFFIX = "H2";

string gridM = "Mintor";
list crossRefM = [1, 15, 22, 28, 29, 35, 36, 44, 37, 23, 10, 18, 26, 40, 13];
//
list locationsM = [ <142, 113, 23>,     // 1 Learning centre
                    <142, 146, 23>,     // 2 Welcome centre
                    <129, 224, 23>,     // 3 Petting Zoo
                    < 42, 290, 23>,     // 4 Water Mill
                    <118, 314, 23>,     // 5 Geodome
                    < 38, 401, 66>,     // 6 Mountain top
                    <111, 415, 25>,     // 7 Picnic area
                    <160, 459, 23>,     // 8 Art gallery & Café
                    <182, 336, 23>,     // 9 Dino park
                    <142, 283, 23>,     // 10 Nature reserve
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
                    " 9 Dino park",
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
                "4 Gardens",
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
//
key owner = NULL_KEY;
vector landingPoint;
string thisRegion = "";
vector simGlobalCoords;
integer listener = -1;
integer listenTs;
// TP avatar rotation
float gAngle = 180.0;
key toucher;


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
        toucher = NULL_KEY;
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
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);

        }
        else if (thisRegion == gridL)
        {
            llSetClickAction(CLICK_ACTION_TOUCH);
            llOwnerSay(TXT_WELCOME +" " + gridL + " - " + TXT_ADJUSTING);
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        }
        else
        {
            // Something wrong! marker1
            llOwnerSay(TXT_ERROR3);
            llResetScript();
        }
    }
    else
    {
        numberOfRows    = 1;
        numberOfColumns = 2;
        llOwnerSay(TXT_WELCOME + " " + thisRegion);
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
                    else if (cmd == "TXT_1")  namesM = llListReplaceList(namesM, [val], 0,0);
                    else if (cmd == "TXT_2")  namesM = llListReplaceList(namesM, [val], 1,1);
                    else if (cmd == "TXT_3")  namesM = llListReplaceList(namesM, [val], 2,2);
                    else if (cmd == "TXT_4")  namesM = llListReplaceList(namesM, [val], 3,3);
                    else if (cmd == "TXT_5")  namesM = llListReplaceList(namesM, [val], 4,4);
                    else if (cmd == "TXT_6")  namesM = llListReplaceList(namesM, [val], 5,5);
                    else if (cmd == "TXT_7")  namesM = llListReplaceList(namesM, [val], 6,6);
                    else if (cmd == "TXT_8")  namesM = llListReplaceList(namesM, [val], 7,7);
                    else if (cmd == "TXT_9")  namesM = llListReplaceList(namesM, [val], 8,8);
                    else if (cmd == "TXT_10") namesM = llListReplaceList(namesM, [val], 9,9);
                    else if (cmd == "TXT_11") namesM = llListReplaceList(namesM, [val], 10,10);
                    else if (cmd == "TXT_12") namesM = llListReplaceList(namesM, [val], 11,11);
                    else if (cmd == "TXT_13") namesM = llListReplaceList(namesM, [val], 12,12);
                    else if (cmd == "TXT_14") namesM = llListReplaceList(namesM, [val], 13,13);
                    else if (cmd == "TXT_15") namesM = llListReplaceList(namesM, [val], 14, 14);
                }
            }
        }
    }
}

showNames()
{
    integer i;
    string outputTextL = "";
    string outputTextR = "";
    integer FACE = 0;
    llSetTexture("blank", FACE);
    string body = "width:512,height:256";
    string CommandList = "";  // Storage for our drawing commands
    // Names, LHS
    CommandList = osMovePen(CommandList, 10, 20);
    CommandList = osSetFontSize(CommandList, 15);
    CommandList = osSetPenColor(CommandList, "DarkBlue");
    CommandList += "FontName Arial;";
    string names;
    if (thisRegion == gridM)
    {
        names="";
        for( i = 0; i < 8; i = i+1 )
        {
            names += llList2String(namesM, i) + "\n";
        }
        CommandList = osDrawText(CommandList, names);
        // Names, RHS
        names = "";
        for( i = 8; i < 16; i = i+1 )
        {
            names += llList2String(namesM, i) + "\n";
        }
        CommandList = osMovePen(CommandList, 285, 20);
        CommandList = osDrawText(CommandList, names);
    }
    else if (thisRegion == gridL)
    {
        names="";
        for( i = 0; i < 8; i = i+1 )
        {
            names += llList2String(namesL, i) + "\n";
        }
        CommandList = osDrawText(CommandList, names);
        // Names, RHS
        names = "";
        for( i = 8; i < 16; i = i+1 )
        {
            names += llList2String(namesL, i) + "\n";
        }
        CommandList = osMovePen(CommandList, 255, 20);
        CommandList = osDrawText(CommandList, names);
    }
    else return;

    // Show region name
    CommandList = osSetFontSize(CommandList, 28);
    CommandList = osSetPenColor(CommandList, "MidnightBlue");
    CommandList = osMovePen(CommandList, 300,200);
    CommandList = osDrawText(CommandList, thisRegion);
    // Do it!
    osSetDynamicTextureDataFace("", "vector", CommandList, body, 0, FACE);
}


default
{

    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        owner = llGetOwner();
        thisRegion = llGetRegionName();
        llRequestSimulatorData(thisRegion, DATA_SIM_POS);
        loadConfig();
        loadLanguage(languageCode);
        regionCheck();
        showNames();
        llSleep(2);
    }

    touch_start(integer num_detected)
    {
        if (simGlobalCoords == ZERO_VECTOR)
        {
            llOwnerSay(TXT_ERROR3);
            llResetScript();
        }

        toucher = llDetectedKey(0);

        vector touchUV = llDetectedTouchUV(0);
        integer face = llDetectedTouchFace(0);
        integer prim = llDetectedLinkNumber(0);

        if (prim == 2)
        {
            numberOfRows    = 2;
            numberOfColumns = 2;
        }
        else if (prim == 3)
        {
            string obj2give = llGetInventoryName(INVENTORY_OBJECT, 0);
            llGiveInventory(llDetectedKey(0), obj2give);
            return;
        }
        else if (face == TOUCH_INVALID_FACE)
        {
            llOwnerSay(TXT_ERROR1);
            return;
        }
        else if (touchUV == TOUCH_INVALID_TEXCOORD)
        {
            llOwnerSay(TXT_ERROR2);
            return;
        }
        else
        {
            numberOfRows    = 7;
            numberOfColumns = 7;
        }

        //      ZERO_VECTOR (<0.0, 0.0, 0.0> ... the origin) is in the bottom left corner of the texture
        //      touchUV.x goes across the texture from left to right
        //      touchUV.y goes up the texture from bottom to top
        integer columnIndex = (integer) (touchUV.x * numberOfColumns);
        integer rowIndex    = (integer) (touchUV.y * numberOfRows);
        integer cellIndex   = rowIndex * numberOfColumns + columnIndex;
        integer locationCell;

        if (prim == 2)
        {
            languageCode = llList2String(languages, cellIndex);
            loadLanguage(languageCode);
            llSetObjectDesc("H;" + languageCode);
            showNames();
            llMessageLinked(LINK_SET, 1, "LANG|"+languageCode, NULL_KEY);
        }
        else
        {
            locationCell = llListFindList(crossRefM, [cellIndex]);
                        llOwnerSay("cellIndex=" +(string)cellIndex +" locationCell=" + (string)locationCell + " face=" + (string)face + " prim=" + (string)prim);
            if ((locationCell == -1) || (face == 5))
            {
                // Not map so show menu
                list options = [];
                options += [TXT_LANGUAGE, TXT_CLOSE];
                startListen();
                llDialog(owner,  TXT_SELECT, options, chan(llGetKey()));
                llSetTimerEvent(300);
            }
            else
            {
                if (locationCell == -1) return;

                landingPoint = llList2Vector(locationsM, locationCell);
                vector LookAt = <llCos(gAngle * DEG_TO_RAD),llSin(gAngle * DEG_TO_RAD),0.0>;
                osTeleportAgent(toucher, landingPoint, LookAt);
            }
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

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
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
            showNames();
            llMessageLinked(LINK_SET, 1, "LANG|"+languageCode, NULL_KEY);
        }
    }

}
