//### updater.lsl
/**
This script is used to upgrade SatyrFarm items.
It scans for upgradeable items nearby (96m), asks for it's version and a list of items in its inventory, decides what and if to upgrade and initiates the update.

#Configuration Notecards:
 sfp            = SatyrFarm Password
 version        = This version of the new farm item(s)
 upgradeables   = List of objects that will be upgraded, one per line
 itemignore     = List of items in own inventory that will not be shared while updating
 uuidignore     = List of ignored UUIDs that won't get updated
 additions      = List of additional items to add ( item1:item2:item3: ...)

 Version 1.2   14 February 2020
**/

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

integer VERSION;
string PASSWORD;
list UPGRADEABLES = [];
list ITEMIGNORE = [];
list UUIDIGNORE = [];
list ADDITIONS = [];
list myItems;

integer scan;
list clients;
integer counter;
integer counter_none;
integer counter_scan;

loadConfig()
{
    //config notecards
    if (llGetInventoryType("sfp") == INVENTORY_NONE || llGetInventoryType("version") == INVENTORY_NONE)
    {
        llOwnerSay("No verion or password notecard in inventory! Can't work like that.");
    }
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    VERSION = (integer)llStringTrim(osGetNotecard("version"), STRING_TRIM);
    if (llGetInventoryType("upgradeables") != INVENTORY_NONE)
    {
        UPGRADEABLES = llParseString2List(osGetNotecard("upgradeables"), ["\n"], []);
    }
    if (llGetInventoryType("itemignore") != INVENTORY_NONE)
    {
        ITEMIGNORE = llParseString2List(osGetNotecard("itemignore"), ["\n"], []);
    }
    if (llGetInventoryType("uuidignore") != INVENTORY_NONE)
    {
        UUIDIGNORE = llParseString2List(osGetNotecard("uuidignore"), ["\n"], []);
    }
    if (llGetInventoryType("additions") != INVENTORY_NONE)
    {
        ADDITIONS = [];
        list addnc = llParseString2List(osGetNotecard("additions"), ["\n"], []);
        integer c = llGetListLength(addnc);
        while (c--)
        {
            ADDITIONS += llParseStringKeepNulls(llList2String(addnc, c), [":"], []);
        }
    }
    //own items
    myItems = [];
    integer len = llGetInventoryNumber(INVENTORY_ALL);
    while (len--)
    {
        myItems += [llGetInventoryName(INVENTORY_ALL, len)];
    }
}

scanNext()
{
    string target = llList2String(UPGRADEABLES, scan);
    if (target == "")
    {
        string tmpStr = "Update finished.\nScanned for " + (string)counter_scan + "objects.\nUpdated " + (string)counter + " items.\n";
        if (counter_none !=0 ) tmpStr += "Update not neccessary on " + (string)counter_none + " objects.\n" ;
        llRegionSayTo(llGetOwner(), 0, tmpStr);
        llResetScript();
        return;
    }
    llOwnerSay("Scanning for " + target);
    llSetText("Talking to " + target + "...", <1.0,0.0,0.8>, 1.0);
    ++scan;
    llSensor(target, "", SCRIPTED, 96, PI);
}

string itemsToReplace(string sItems, key kObject)
{
    list lReplace = [];
    integer found_add = llListFindList(ADDITIONS, [llKey2Name(kObject)]) + 1;
    if (found_add)
    {
        lReplace += llParseString2List(llList2String(ADDITIONS, found_add), [","], []);
    }
    list lItems = llParseString2List(sItems, [","], []);
    integer i = llGetListLength(lItems);
    integer c;
    for (c = 0; c < i;  c++)
    {
        string item = llList2String(lItems, c);
        if (llListFindList(myItems, [item]) != -1 && llListFindList(ITEMIGNORE, [item]) == -1 && llListFindList(lReplace, [item]) == -1)
        {
            lReplace += [item];
        }
    }
    return llDumpList2String(lReplace, ",");
}


default
{
    state_entry()
    {
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        loadConfig();
        llSetText("CLICK TO START\n \nUPDATE: " + llDumpList2String(UPGRADEABLES, "\n") + "\n" + "IGNORE: " + llDumpList2String(UUIDIGNORE, "\n"), <1,1,1>, 1.0);
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) != llGetOwner())
        {
            llSay(0, "You are not my owner, please go away '.'");
            return;
        }
        state update;
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
        llOwnerSay(" \n-------------\nChecking " + llKey2Name(target) + "\n" + (string)target + " (from: " + (string)llGetKey());
        llSetTimerEvent(3.0);
        ++counter_scan;
        osMessageObject(target, "VERSION-CHECK|" + PASSWORD + "|" + (string)llGetKey());
    }

    no_sensor()
    {
        llOwnerSay("No item found");
        scanNext();
    }

    dataserver(key k, string m)
    {
        debug("dataserver: " + m);
        list cmd = llParseString2List(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);

        if (command == "VERSION-REPLY")
        {
            integer iVersion = llList2Integer(cmd,3);
            if(iVersion != VERSION)
            {
                string repstr = itemsToReplace(llList2String(cmd,4), llList2Key(cmd, 2));
                if (repstr != "")
                {
                    llSay(0, "Update possible - trying to update item...");
                    osMessageObject(llList2Key(cmd, 2), "DO-UPDATE|"+PASSWORD+"|"+(string)llGetKey()+"|"+repstr);
                    llSetTimerEvent(20.0);
                    return;
                }
            }
            ++counter_none;
            llSetTimerEvent(0.5);
        }
        else if (command == "DO-UPDATE-REPLY")
        {
            llSleep(2.0);
            key kobject = llList2Key(cmd, 2);
            integer ipin = llList2Integer(cmd, 3);
            list litems = llParseString2List(llList2String(cmd, 4), [","], []);
            integer type;
            string sitem;
            integer d = llGetListLength(litems);
            integer c;
            for (c = 0; c < d; c++)
            {
                sitem = llList2String(litems, c);
                if (llListFindList(ITEMIGNORE, [sitem]) == -1)
                {
                    type = llGetInventoryType(sitem);
                    if (type == INVENTORY_SCRIPT)
                    {
                        llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                    }
                    else if (type != INVENTORY_NONE)
                    {
                        llGiveInventory(kobject, sitem);
                    }
                }
            }

            d = llGetListLength(ADDITIONS);
            if (d >0)
            {
                for (c = 0; c < d; c++)
                {
                    sitem = llList2String(ADDITIONS, c);
                    type = llGetInventoryType(sitem);
                    if (type == INVENTORY_SCRIPT)
                    {
                        llRemoteLoadScriptPin(kobject, sitem, ipin, TRUE, 0);
                    }
                    else if (type != INVENTORY_NONE)
                    {
                        llGiveInventory(kobject, sitem);
                    }
                }
            }
            llSay(0, "Updated items: \n    " + llList2String(cmd,4) + "\n-----------");
            ++counter;
            llSetTimerEvent(1.0);
        }
    }
}
