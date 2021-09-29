//### language-manager.lsl
/**
This script is used to install and upgrade language notecards for the Satyr Farm system.
It scans for upgradeable items nearby (96m), asks for it's version and a list of language notecards in its inventory, decides what and if to upgrade and initiates the update.

#Configuration Notecards:
 languages      = List of languages to install/upgrade, one per line
 sfp            = SatyrFarm Password
 upgradeables   = List of objects that will be checked, one per line [CURRENTLY ONLY SUPPORTS 1 OBJECT]
 uuidignore     = List of ignored UUIDs that won't get updated, one per line
**/

// Used to check for updates from Quintonia product update server
float VERSION = 1.0;        //  BETA 17 February 2020
string NAME = "SF Language Manager HUD";

integer DEBUGMODE = TRUE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

string  PASSWORD;
list    UPGRADEABLES = [];
list    UUIDIGNORE = [];
list    languageList;
list    myItems;
integer scan;
list    clients;
integer counter;
integer counter_none;
integer counter_scan;
integer counter_global;
string  LANG;
integer LANG_VER;
integer active = FALSE;

loadConfig()
{
    //config notecards
    if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("languages") == INVENTORY_NONE)
    {
        llOwnerSay("No version or password notecard in inventory! Can't work like that.");
    }
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    if (llGetInventoryType("upgradeables") != INVENTORY_NONE)
    {
        UPGRADEABLES = llParseString2List(osGetNotecard("upgradeables"), ["\n"], []);
        if (llGetListLength(UPGRADEABLES) >1) llOwnerSay("Only support for single item update at present");
    }
    if (llGetInventoryType("uuidignore") != INVENTORY_NONE)
    {
        UUIDIGNORE = llParseString2List(osGetNotecard("uuidignore"), ["\n"], []);
    }
    if (llGetInventoryType("languages") != INVENTORY_NONE)
    {
        list LANGUAGES = llParseString2List(osGetNotecard("languages"), ["\n"], []);
        // Build list of language notecard names and versions
        string val;
        string lang;
        string langNC;
        languageList = [];
        integer count = llGetListLength(LANGUAGES);
        integer j;
        for (j=0; j<count; j+=1)
        {
            lang = llList2String(LANGUAGES, j);
            langNC = lang+"-lang";
            if (llGetInventoryType(langNC) == INVENTORY_NOTECARD)
            {
                integer langVer = 0;
                list lines = llParseString2List(osGetNotecard(langNC), ["\n"], []);
                integer i;
                for (i=0; i < llGetListLength(lines); i++)
                {
                    list tok = llParseString2List(llList2String(lines,i), ["="], []);
                    if (llList2String(tok,1) != "")
                    {
                        if (llStringTrim(llList2String(tok, 0), STRING_TRIM) == "@VER") langVer = llList2Integer(tok, 1);
                    }
                }
                languageList += [lang, langVer];
            }
        }
        debug("languageList:\n" +llDumpList2String(languageList, "\n"));
    }
    //own items
    myItems = [];
    integer len = llGetInventoryNumber(INVENTORY_ALL);
    while (len--)
    {
        myItems += [llGetInventoryName(INVENTORY_ALL, len)];
    }
}

giveLangNC(key object)
{
    llGiveInventory(object, LANG+"-lang");
    llSleep(2.0);
    osMessageObject(object, "ADD-CHECK|" +PASSWORD+"|" +(string)llGetKey()+"|" +LANG);
    llSleep(1.0);
    llSay(0, "Updated items: \n    " + llKey2Name(object) + "\n-----------");
    ++counter;
    llSetTimerEvent(1.0);
}


scanNext()
{
    string target = llList2String(UPGRADEABLES, scan);
    if (target == "")
    {
        string tmpStr = "Update for " +LANG + " finished.\nScanned for " + (string)counter_scan + "objects.\nUpdated " + (string)counter + " items.\n";
        if (counter_none !=0 ) tmpStr += "Update not neccessary on " + (string)counter_none + " objects.\n" ;
        llRegionSayTo(llGetOwner(), 0, tmpStr);
        state default;
    }
    llOwnerSay("Scanning for " +target +" Lang:" +LANG +" Ver:" +(string)LANG_VER);
    llSetText("Talking to " +target +"...", <1.0,0.0,0.8>, 1.0);
    ++scan;
    llSensor(target, "", SCRIPTED, 96, PI);
}


default
{
    state_entry()
    {
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        loadConfig();
        llSetText("CLICK TO START\n \nUPDATE: " + llDumpList2String(UPGRADEABLES, "\n") + "\n" + "IGNORE: " + llDumpList2String(UUIDIGNORE, "\n"), <1,1,1>, 1.0);
        counter_global = 0;
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner())
        {
            llRegionSayTo(llDetectedKey(0), 0, "Only the owner can use this");
            return;
        }
        active = TRUE;
        counter_global = 0;
        LANG = llList2String(languageList, counter_global);
        LANG_VER = llList2Integer(languageList, counter_global+1);
        state update;
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        debug("link_message: {" + msg + "}\ncmd: {" + cmd + "}");
        if (cmd == "VERSION-REQUEST")
        {
            llMessageLinked(LINK_SET, (integer)(10*VERSION), "VERSION-REPLY", (key)NAME);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
}


state update
{
    state_entry()
    {
        llSetText("Update Running...", <0.0,1.0,0.2>, 1.0);
        llSetColor(<0.0, 1.0, 0.75>, ALL_SIDES);
        llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, ALL_SIDES,1,1,0, TWO_PI, -1.0);
        counter = 0;
        counter_none = 0;
        counter_scan = 0;
        scan = 0;
        scanNext();
    }

    sensor(integer n)
    {
        clients = [];
        key owner = llGetOwner();
        while (n--)
        {
            key det = llDetectedKey(n);
            if (owner == llGetOwnerKey(det) && llListFindList(UUIDIGNORE, [(string)det]) == -1)
            {
                clients += [det];
            }
        }
        llSetTimerEvent(1.0);
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if (clients == [])
        {
            scanNext();
            return;
        }
        key target = llList2Key(clients, 0);
        clients = llDeleteSubList(clients, 0, 0);
        llOwnerSay(" \n-------------\nChecking " + llKey2Name(target) + "\n" + (string)target + " (VER: " + (string)LANG_VER +")");
        llSetTimerEvent(3.0);
        ++counter_scan;
        // CMD|PASSWORD|SENDERID|LANG|VER
        osMessageObject(target, "LANGUAGE-CHECK|" +PASSWORD+"|" +(string)llGetKey()+"|" +LANG+"|" +(string)LANG_VER);
    }

    no_sensor()
    {
        llOwnerSay("No item found");
        scanNext();
    }

    dataserver(key k, string m)
    {
        debug("dataserver: " + m);
        list tk = llParseString2List(m, ["|"], []);
        if (llList2String(tk,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(tk, 0);

        if (command == "LANGUAGE-REPLY")
        {
            // LANGUAGE-REPLY|PASSWORD|uuid|lang|ver|
            string iVersion = llList2String(tk, 4);
            if (iVersion =="")
            {
                // No notecard so send one
                giveLangNC(llList2Key(tk, 2));
                return;
            }
            if ((integer)iVersion < LANG_VER)
            {
                    llOwnerSay("Update possible - trying to update item...");
                    osMessageObject(llList2Key(tk, 2), "DO-UPDATE|" +PASSWORD+"|" +(string)llGetKey() +"|" +LANG);
                    llSetTimerEvent(20.0);
                    return;
            }
            ++counter_none;
            llSetTimerEvent(0.5);
        }
        else if (command == "UPDATE-REPLY")
        {
            giveLangNC(llList2Key(tk, 2));
        }
    }
}
