// B-main.lsl
// Version 2.2  Beta 3 December 2020

// multilingual
string TXT_CLOTHING = "Clothing";
string TXT_BIRTHDATE = "Birth date";
string TXT_MOVE = "Move";
string TXT_SELECT = "Please select option";
string TXT_CLOSE = "CLOSE";
string TXT_BACK = "BACK";
string TXT_RESET = "RESET";
string TXT_ALREADY_THERE = "I'm already there!";
string TXT_PUT_DOWN = "Put down";
string TXT_ATTACH = "Attach";
string TXT_DETACH = "Detach";
string TXT_MATERIAL = "MATERIAL...";
string TXT_BABYGROW = "Babygrow";
//
//listen script vars
integer listener = -1;
float   timeout = 300.00;
integer chan = -1;
//
list    mainMenuButtons = [];
key     userID;
key     lastUser = NULL_KEY;
//
// birth date items
string g_strMessage="was born on";
string g_strFilename="birth-date";
string myName ="";
string g_strDate;
//
// clothing items
list clothTextures;     // List of textures that can be applied to clothing
list wearableNames;     // list of inventory items to 'wear'
list babyGrowPrims;     // list of prims that make the 'babygrow'
string CLOTHES_PREFIX = "clothing-";
string TORSO_PREFIX = "body-";
string TINTABLE = "tintable";
string selectedItem;
//
// Movement (target) items
list targets = [];
string mainTarget = "";
string SF_PREFIX = "SF ";
string whereAmI = "";
integer useOS = FALSE;
integer attachPoint = ATTACH_BACK;
integer amAttached = FALSE;
integer result;
string  status;


integer randomchannel()
{
    integer intRandom;
    do
    {
        intRandom=(integer)llFrand(9000.0);
    } while(intRandom==0);
    intRandom = intRandom * -1;
    llMessageLinked(LINK_SET, intRandom, "set channel", NULL_KEY);
    return intRandom;
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

// if incSign == TRUE will assume turning clothing on/off else assume texturing clothing
list getClothing(integer incSign)
{
    list    returnVals = [];
    string  symbol;
    string  fullName;
    string  shortName;
    integer prefixLength = llStringLength(TORSO_PREFIX);
    integer index;
    // Build a list af available textures that can be applied to clothing
    integer count = llGetInventoryNumber(INVENTORY_TEXTURE);
    clothTextures = [];
    for (index = 0; index < count ; index++)
    {
        fullName = llGetInventoryName(INVENTORY_TEXTURE, index);
        if (llSubStringIndex(fullName, "TEX-") != -1)
        {
            clothTextures += llGetSubString(fullName, 4, -1);
        }
    }
    // for clothing function build list of the 'babygrow' prims
    count = llGetNumberOfPrims();
    babyGrowPrims = [];
    for(index = 0; index < count; index++)
    {
        fullName = llList2String(llGetLinkPrimitiveParams(index, [PRIM_NAME]), 0);
        if (llSubStringIndex(fullName, TORSO_PREFIX) != -1)
        {
            babyGrowPrims  += index;
        }
    }
    // Next find prim clothing items (either to toggle visibility or for setting texture)
    prefixLength = llStringLength(CLOTHES_PREFIX);
    for (index = 0; index < count; index++)
    {
        fullName = llList2String(llGetLinkPrimitiveParams(index, [PRIM_NAME]), 0);
        if (llSubStringIndex(fullName, CLOTHES_PREFIX) != -1)
        {
            shortName = llGetSubString(fullName, prefixLength, -1);
            if (incSign == TRUE)
            {
                // names are clothing- followed by descriptive name e.g. clothing-hat2
                if (llList2Integer(llGetLinkPrimitiveParams(index, [PRIM_COLOR, ALL_SIDES]), 1) == 1) symbol = "-"; else symbol = "+";
                // store as +hat2   or -hat2 depending upon current alpha
                returnVals += symbol+shortName;
            }
            else
            {
                if (llList2String(llGetLinkPrimitiveParams(index, [PRIM_DESC]), 0) == TINTABLE) returnVals += shortName;
            }
        }
    }
    returnVals = llListSort(returnVals, 1, TRUE);
    return returnVals;
}

list makeButtonList()
{
    list theButtons = [TXT_CLOTHING, TXT_BIRTHDATE];
    if (llGetAttached() == 0)
    {
        theButtons += [TXT_MOVE];
    }
    else
    {
        if (useOS == TRUE)
        {
            theButtons += [TXT_DETACH];
        }
    }
    theButtons += [TXT_RESET, TXT_CLOSE];
    return theButtons;
}

integer startOffset=0;

multiPageMenu(key id, string message, list opt)
{
    integer l = llGetListLength(opt);
    if (l < 12)
    {
        llDialog(id, message, [TXT_BACK]+opt, chan);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(opt, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_BACK]+its+[">>"], chan);
}

showMenu(list buttons, string prompt)
{
    llListenRemove(listener);
    listener = llListen(chan, "" ,NULL_KEY, "");
    llSetTimerEvent(timeout);
    multiPageMenu(userID, "\n" +prompt, buttons);
}

doAttach()
{
    whereAmI = "";
    llAttachToAvatar(attachPoint);
    llMessageLinked(LINK_SET, 0, "FORCE_SLEEP", "");
}



default
{

    state_entry()
    {
        // Set up comms channel
        if (chan == -1) chan = randomchannel();
        wearableNames = getClothing(TRUE);
        userID = llGetOwner();
        lastUser = userID;
        //asks permission to attach/detach
        llRequestPermissions(userID, PERMISSION_ATTACH);
    }

    on_rez(integer start_param)
    {
        chan = randomchannel();
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == TXT_CLOSE)
        {
            llListenRemove(listener);
            llSetTimerEvent(0);
        }
        else if (message == TXT_CLOTHING)
        {
            userID = id;
            multiPageMenu(userID, TXT_SELECT, TXT_MATERIAL + getClothing(TRUE));
            status = "waitClothing";
        }
        else if (message == TXT_MATERIAL)
        {
            // Give them a list of items that have tintable material
            userID = id;
            multiPageMenu(userID, TXT_SELECT, TXT_BABYGROW + getClothing(FALSE));
            status = "waitTintable";
        }
        else if (message == TXT_BACK)
        {
            userID = id;
            showMenu(makeButtonList(), TXT_SELECT);
        }
        else if (message ==">>")
        {
            startOffset += 10;
            if (status == "waitClothing") multiPageMenu(userID, TXT_SELECT, TXT_MATERIAL + getClothing(TRUE));
                else if (status  == "waitTintable") multiPageMenu(userID, TXT_SELECT, TXT_BABYGROW + getClothing(FALSE));
                    else if (status == "waitTexture") showMenu(clothTextures, TXT_CLOTHING +": "+selectedItem);
                        else  multiPageMenu(id, TXT_SELECT, wearableNames);
        }
        else if (message == TXT_BIRTHDATE)
        {
            if (llGetInventoryType(g_strFilename) == INVENTORY_NOTECARD)
            {
                g_strDate = osGetNotecardLine(g_strFilename, 0);
            }
            else
            {
                g_strDate = "n/a";
            }
            //
            if (llGetInventoryType("B-statusNC") == INVENTORY_NOTECARD)
            {
                list desc = llParseStringKeepNulls(osGetNotecardLine("B-statusNC", 0), [";"], []);
                myName = llList2String(desc, 10);
            }
            llRegionSayTo(id, 0, myName +" " +g_strMessage +" " +g_strDate);
            //
            llMessageLinked(LINK_SET, 0, "touch", id);
            userID = id;
            llDialog(userID, "\n" +TXT_SELECT, makeButtonList(), chan);
        }
        else if (message == TXT_RESET)
        {
            llMessageLinked(LINK_SET, 666, "reset", "");
            llSleep(0.5);
            llResetScript();
        }
        else if (status == "waitClothing")
        {
            if (message == TXT_BACK)
            {
                status = "";
            }
            else
            {
                // -bib1|-dummy1b|-dummy1a|-hat1|-hairband1|-hat2|-ears1
                string itemName = llGetSubString(message, 1, -1);
                result = getLinkNum(CLOTHES_PREFIX+itemName);
                if (result != -1)
                {
                    integer index = llListFindList(wearableNames, [message]);
                    if (llGetSubString(message, 0, 0) == "-")
                    {
                        llSetLinkAlpha(result, 0.0, ALL_SIDES);
                        wearableNames = llListReplaceList(wearableNames, ["+"+itemName], index, index);
                    }
                    else
                    {
                        llSetLinkAlpha(result, 1.0, ALL_SIDES);
                        wearableNames = llListReplaceList(wearableNames, ["-"+itemName], index, index);
                    }
                }
                multiPageMenu(lastUser, TXT_SELECT, wearableNames);
            }
        }
        else if (status == "waitTintable")
        {
            selectedItem = message;
            status = "waitTexture";
            showMenu(clothTextures, TXT_CLOTHING +": "+selectedItem);
        }
        else if (status == "waitTexture")
        {
            string tex = "TEX-"+message;
            integer index;
            if  (selectedItem == TXT_BABYGROW)
            {
                if (llGetInventoryType("TEX-"+message) == INVENTORY_TEXTURE)
                {
                    integer count = llGetListLength(babyGrowPrims);
                    for (index = 0; index < count; index++)
                    {
                        llSetLinkTexture(llList2Integer(babyGrowPrims, index), tex, ALL_SIDES);
                    }
                }
            }
            else
            {
                index = getLinkNum(CLOTHES_PREFIX+selectedItem);
                if (index != -1) llSetLinkTexture(index, tex, ALL_SIDES);
            }
            startOffset = 0;
            status = "waitClothing";
            multiPageMenu(userID, TXT_SELECT, TXT_MATERIAL + getClothing(TRUE));
        }
        else
        {
            llMessageLinked(LINK_SET,0,message,id);
            llSetTimerEvent(0.1);
        }
    }

    link_message(integer sender_num, integer number, string message,key id)
    {
        list tk = llParseString2List(message, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "B_TARGETS")
        {
            if (llGetListLength(tk) >1)
            {
                SF_PREFIX = llList2String(tk,1) +" ";
                targets = llList2List(tk, 2, -1);
                mainTarget = llList2String(targets, 0);
                targets += [TXT_PUT_DOWN, TXT_ATTACH];
                useOS = number;
            }
        }
        else if (cmd == "MY_LOCATION")
        {
            whereAmI = llList2String(tk, 1);
            if (whereAmI == "AM_DOWN")
            {
                llMessageLinked(LINK_SET, 0, "MOVEMENT_SET", "");
                llMessageLinked(LINK_SET, 0, "FORCE_SLEEP", "");
            }
            else if (whereAmI != "")
            {
                llMessageLinked(LINK_SET, 1, "MOVEMENT_SET", "");
                llMessageLinked(LINK_SET, 1, "FORCE_SLEEP", "");
            }
            else
            {
                llMessageLinked(LINK_SET, 0, "FORCE_SLEEP", "");
            }
        }
        else
        {
            if (message == TXT_ATTACH)
            {
                if (userID == lastUser)
                {
                    if (llGetPermissions() & PERMISSION_ATTACH) doAttach(); else llRequestPermissions(userID, PERMISSION_ATTACH);
                }
                else
                {
                    userID = id;
                    llRequestPermissions(userID, PERMISSION_ATTACH);
                }
            }
            else if (message == TXT_PUT_DOWN)
            {
                llMessageLinked(LINK_SET, 1, "PUT_DOWN", "");
                amAttached = FALSE;
            }
            else if (llListFindList(targets, [message]) != -1)
            {
                // EXAMPLE   SF_PREFIX = "SF "    whereAmI = "SF Item Name"   message = "Item Name"
                if (SF_PREFIX+message == whereAmI)
                {
                    llRegionSayTo(userID, 0, TXT_ALREADY_THERE);
                }
                else
                {
                    llMessageLinked(LINK_SET, 1, "SEEK_SURFACE|"+SF_PREFIX +message, "");
                }
            }
            else
            {
                message = llToLower(message);
                //
                if (message == "get channel")
                {
                    llMessageLinked(sender_num, chan, "set channel", id);
                }
                else if (message == "reset")
                {
                    llResetScript();
                }
                else if (message == llToLower(TXT_DETACH))
                {
                    osDropAttachment();
                    whereAmI = "AM_DOWN";
                    if (mainTarget != "") llMessageLinked(LINK_SET, 1, "SEEK_SURFACE|"+SF_PREFIX +mainTarget, "");
                }
                else if (message == "dotouch")
                {
                    userID = id;
                    lastUser = userID;
                    showMenu(makeButtonList(), TXT_SELECT);
                }
                else if (message == llToLower(TXT_MOVE))
                {
                    startOffset += 0;
                    multiPageMenu(id, TXT_SELECT, targets);
                }
            }
        }
    }

    timer()
    {
        if (listener == -1)
        {
            llListenRemove(listener);
            listener = -1;
        }
        llSetTimerEvent(0);
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_ATTACH)
        {
            lastUser = userID;
            doAttach();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (llGetAttached() == 0) amAttached = FALSE; else amAttached = TRUE;
        }
    }

}
