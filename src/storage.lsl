// CHANGE LOG
//  Added support for the utility-storage_xfer tool
//  Added 'inventory add' function for owners
//  Added support for switching to 'units' so maximum fill amount can be larger than 100%
//  For storage with product level prims, now shows any items without level prims on main float text
// Added config option to set float text brightness

//### storage.lsl
/**
Storage - stores single or multiple products. The script scans its inventory to generate the list of products automatically.
It uses the linked prims with the same name to set text with the status of each product. E.g. for SF Olives the linked prim named
"Olives" is used to show the text about the current level of SF Olives.
**/
float   VERSION = 5.4;   // 6 May 2021
integer RSTATE  = 1;     // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Default values, can be changed via config notecard
vector  rezzPosition = <0.0, 1.5, 2.0>;     // REZ_POSITION=<0.0, 1.5, 2.0>
integer initialLevel = 5;                   // INITIAL_LEVEL=5
integer dropTime = 172800;                  // DROP_TIME=2
integer singleLevel = 2;                    // ONE_PART=2
integer maxFill = 100;                      // MAX_FILL=100
integer SENSOR_DISTANCE=10;                 // SENSOR_DISTANCE=10
vector  TXT_COLOR = <1,1,1>;                // TXT_COLOR=<1,1,1>
float   textBrightness = 1.0;               // TXT_BRIGHT=10    (1 to 10)
integer SORTDIR = 1;                        // SORTDIR=ASC  (set as ASC[1] or DEC[0])
integer groupAddStock = TRUE;               // GROUP_STOCK_ADD=1
string  shareMode = "all";                  // SHARE_MODE=All    (can be All, Group or None)
string  SF_PREFIX = "SF";                   // SF_PREFIX=SF
// Use the values below if no language notecard
string  languageCode = "en-GB";             // LANG=en-GB

// For multi-lingual support
string TXT_ADDED="Added";
string TXT_ADD="Add Product";
string TXT_ADD_STOCK = "New Stock";
string TXT_CHECK="Check";
string TXT_CHECKING = "Checking";
string TXT_CLOSE="CLOSE";
string TXT_GET="Get Product";
string TXT_SELECT="Select";
string TXT_GET_ITEM="Select item to get";
string TXT_STORE_ITEM="Select product to store";
string TXT_FULL="I am full of";
string TXT_LEVEL="level is now";
string TXT_LEVELS="Levels";
string TXT_FOUND="Found";
string TXT_EMPTYING="emptying...";
string TXT_NOT_AVAILABLE="No products available";
string TXT_NOT_ENOUGH="Sorry, there is not enough left";
string TXT_NOT_FOUND="No items found nearby";
string TXT_NOT_FOUND_ITEM="not found nearby. You must bring them closer";
string TXT_NOT_FOUND100="with 100% not found nearby. Please bring it closer.";
string TXT_NOT_STORED="not in my Inventory";
string TXT_BAD_PASSWORD="Bad password";
string TXT_ERROR_USE="Sorry, you are not allowed to use this";
string TXT_ERROR_LOCKED="I am locked, did you try to copy me? You can still unlock me, without losing any progress by asking the farm manager";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_INV_SEARCH_FAIL = "Sorry, unable to add to inventory";
string TXT_IN_INVENTORY = "Product already in my inventory";
string TXT_MENU = "MENU";
string TXT_RIDE = "RIDE";
string TXT_EMPTY = "-NO PRODUCTS-";
string TXT_LANGUAGE = "@";
// NPC Farmer messages in English
string NPC_ADD="Add Product";
string  SUFFIX = "S1";
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
string  STORAGENC = "storagenc";

vector ORANGE = <1.000, 0.522, 0.106>;
vector YELLOW = <1.000, 0.863, 0.000>;
vector GREEN =     <0.180, 0.800, 0.251>;
vector AQUA = <0.224, 0.800, 0.800>;

//0 = never reset
//1 = reset when UUID doesn't metch
//2 = lock down when UUID doesn't match
//-1 = is locked down
integer doReset = 1;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

//for notecard config saving
integer saveNC = 0;
//status variables
list products = [];
list levels = [];
list customOptions = [];
list customText = [];
//listens and menus
integer listener=-1;
integer listenTs;
integer startOffset=0;
integer lastTs;
key ownKey;
key ownGroup;
//temp
string tmpkey;
string lookingFor;
string status;
list selitems = [];
list availProducts =[];
key toucher = NULL_KEY;
integer hudDetected;
integer timeout = 1800;
integer timeoutTs;
key controller = NULL_KEY;

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(ownKey), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        selitems = [];
        availProducts =[];
    }
}

// Function to put buttons in "correct" human-readable order
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

// Returns a list that is vLstSrc with the elements in reverse order
list listReverse(list lst)
{
    if (llGetListLength(lst) <= 1) return lst;
    return listReverse(
        llList2List(
            lst,
            1,
            llGetListLength(lst)
        )
    ) + llList2List(lst, 0, 0);
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(ownKey);
    if (l < 12)
    {
        llDialog(id, message, order_buttons(buttons) +[TXT_CLOSE], ch);
    }
    else
    {
        if (startOffset >= l) startOffset = 0;
        list its = llList2List(buttons, startOffset, startOffset + 9);
        its = llListSort(its, 1, SORTDIR);
        llDialog(id, message, order_buttons(its)+[TXT_CLOSE]+[">>"], ch);
    }
}

loadConfig(integer checkForReset)
{
    integer i;
    //sfp Notecard
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        string line;
        list tok;
        string cmd;
        string val;
        for (i=0; i < llGetListLength(lines); i++)
        {
            line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                tok = llParseStringKeepNulls(line, ["="], []);
                cmd = llList2String(tok, 0);
                val = llList2String(tok, 1);
                if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
                else if (cmd == "INITIAL_LEVEL") initialLevel = (integer)val;
                else if (cmd == "DROP_TIME") dropTime = (integer)val * 86400;
                else if (cmd == "ONE_PART") singleLevel = (integer)val;
                else if (cmd == "SENSOR_DISTANCE") SENSOR_DISTANCE = (integer)val;
                else if (cmd == "GROUP_STOCK_ADD") groupAddStock = (integer)val;
                else if (cmd == "SORTDIR")
                {
                    if (llToUpper(val) == "ASC") SORTDIR = 1; else SORTDIR = 0;
                }
                else if (cmd == "SHARE_MODE")
                {
                    shareMode = llToLower(val);
                    if (llListFindList(["all", "group", "none"], shareMode) == -1) shareMode = "all";
                }
                else if (cmd == "TXT_COLOR")
                {
                    if ((val == "ZERO_VECTOR") || (val == "OFF"))
                    {
                        TXT_COLOR = ZERO_VECTOR;
                    }
                    else
                    {
                        TXT_COLOR = (vector)val;
                        if (TXT_COLOR == ZERO_VECTOR) TXT_COLOR = <1,1,1>;
                    }
                }
                else if (cmd == "TXT_BRIGHT")
                {
                    textBrightness = 0.1 * (float)val;
                    if (textBrightness < 0.1) textBrightness = 0.1;
                     else if (textBrightness > 1.0) textBrightness = 1.0;
                }
                else if (cmd == "MAX_FILL") maxFill = (integer)val;
                else if (cmd == "SF_PREFIX") SF_PREFIX = val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    // Data integrity checks
    if (maxFill < 100) maxFill = 100;
    if (initialLevel > maxFill) initialLevel = maxFill;
    // get saved state from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "S")
    {
        languageCode = llList2String(desc, 1);
    }
    else
    {
        llSetObjectDesc("S;" + languageCode);
    }
    //storagenc Notecard
    list storageNC = [];
    if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
    {
        storageNC = llParseString2List(llStringTrim(osGetNotecard(STORAGENC), STRING_TRIM), [";"], []);
    }
    if ((llGetListLength(storageNC) < 3 || (llList2Key(storageNC, 0) != ownKey && llList2String(storageNC, 0) != "null")) && doReset && checkForReset)
    {
        if (doReset == 1)
        {
            llMessageLinked(LINK_SET, 99, "HARDRESET", NULL_KEY);
            if ((status != "stockXfer") && (status != "stockXferCheck"))
            {
                saveNC = 2;
                if (llGetInventoryType(STORAGENC+"-old") == INVENTORY_NOTECARD)
                {
                    saveNC++;
                    llRemoveInventory(STORAGENC+"-old");
                }
                osMakeNotecard(STORAGENC+"-old", "null;" + llDumpList2String(llList2List(storageNC, 1, -1), ";"));
            //    llRemoveInventory(STORAGENC);
                products = [];
                levels = [];
            }
        }
        else
        {
            doReset = -1;
        }
    }
    else
    {
        products = llParseString2List(llList2String(storageNC,1), [","], []);
        levels = llParseString2List(llList2String(storageNC,2), [","], []);
        if (llGetListLength(storageNC) > 3)
        {
            lastTs = llList2Integer(storageNC, 3);
        }
    }
    //objects in inventory
    string name;
    string product;
    for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
    {
        name = llGetInventoryName(INVENTORY_OBJECT, i);
        if (llGetSubString(name,0,2) == "SF ")
        {
            product = llGetSubString(name,3,-1);
            if (llListFindList(products, [product]) == -1)
            {
                products += product;
                levels += initialLevel;
                llMessageLinked(LINK_SET, 99, "GOTLEVEL|" + product + "|" + (string)initialLevel, NULL_KEY);
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    if (llGetInventoryType(languageNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(languageNC), ["\n"], []);
        string line;
        integer i;
        list tok = [];
        string cmd;
        string val;
        for (i=0; i < llGetListLength(lines); i++)
        {
            line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    // Remove start and end " marks
                    val = llGetSubString(val, 1, -2);
                    // Now check for language translations
                         if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT= val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_GET") TXT_GET= val;
                    else if (cmd == "TXT_CHECK") TXT_CHECK = val;
                    else if (cmd == "TXT_CHECKING") TXT_CHECKING = val;
                    else if (cmd == "TXT_ADDED") TXT_ADDED = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_GET_ITEM") TXT_GET_ITEM = val;
                    else if (cmd == "TXT_STORE_ITEM") TXT_STORE_ITEM = val;
                    else if (cmd == "TXT_FULL") TXT_FULL = val;
                    else if (cmd == "TXT_LEVEL") TXT_LEVEL = val;
                    else if (cmd == "TXT_LEVELS") TXT_LEVELS = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_ADD_STOCK") TXT_ADD_STOCK = val;
                    else if (cmd == "TXT_IN_INVENTORY") TXT_IN_INVENTORY = val;
                    else if (cmd == "TXT_EMPTY") TXT_EMPTY = val;
                    else if (cmd == "TXT_NOT_AVAILABLE") TXT_NOT_AVAILABLE = val;
                    else if (cmd == "TXT_NOT_ENOUGH") TXT_NOT_ENOUGH = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM") TXT_NOT_FOUND_ITEM = val;
                    else if (cmd == "TXT_NOT_FOUND100") TXT_NOT_FOUND100 = val;
                    else if (cmd == "TXT_NOT_STORED") TXT_NOT_STORED = val;
                    else if (cmd == "TXT_MENU") TXT_MENU = val;
                    else if (cmd == "TXT_RIDE") TXT_RIDE = val;
                    else if (cmd == "TXT_INV_SEARCH_FAIL") TXT_INV_SEARCH_FAIL = val;
                    else if (cmd == "TXT_ERROR_LOCKED") TXT_ERROR_LOCKED = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_USE") TXT_ERROR_USE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
    llMessageLinked(LINK_SET, 1, "LANGTEXT|"+PASSWORD+"|TXT_MENU|"+TXT_MENU, "");
    llMessageLinked(LINK_SET, 1, "LANGTEXT|"+PASSWORD+"|TXT_RIDE|"+TXT_RIDE, "");
    llMessageLinked(LINK_SET, 1, "LANGTEXT|"+PASSWORD+"|TXT_ERROR_USE|"+TXT_ERROR_USE, "");
}

saveConfig()
{
    //storage Notecard
    if (llGetInventoryType(STORAGENC) != INVENTORY_NONE)
    {
        saveNC++;
        llRemoveInventory(STORAGENC);
    }
    saveNC++;
    string contents = (string)ownKey+";" +llDumpList2String(products, ",")+ ";" +llDumpList2String(levels, ",")+";" +(string)lastTs;
    debug("saveConfig:"+contents);
    osMakeNotecard(STORAGENC, contents);
}

messageObj(key objId, string msg)
{
    debug("messageObj:"+msg +" to:"+(string)objId);
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg); else debug("messageObj failed sending to:"+(string)objId);
}

refresh(integer didChange)
{
    integer ts = llGetUnixTime();
    // yengine memory clearout
    if (ts - timeoutTs > timeout)
    {
        timeoutTs = ts;
        if (osGetScriptEngineName() == "YEngine") llResetScript();
    }
    integer productsLength = llGetListLength(products);
    integer lev;
    integer i;
    if (ts - lastTs > dropTime)
    {
            for (i=0; i < productsLength; i++)
            {
                lev = llList2Integer(levels,  i);
                lev-= singleLevel;
                if (lev <0 )  lev = 0;
                levels = llListReplaceList(levels, [lev], i, i);
            }
            lastTs = ts;
    }
    if (lev > maxFill) lev = maxFill;
    vector p = ZERO_VECTOR;
    string str = "";
    if (didChange == TRUE)
    {
        string product = "";
        string stati ="";
        integer lnk =0;
        list pstate = [];
        list desc = [];
        list noPrimProducts = products;
        float minHeight =0.0;
        float maxHeight=0.0;
        vector c = ZERO_VECTOR;
        integer found = 0;
        string statTotal = "";
        integer primFound;
        integer count;
        string units;
        if (maxFill >100) units = "/"+(string)maxFill; else units = "%";
        for (i=0; i < productsLength; i++)
        {
            lev = llList2Integer(levels, i);
            product = llList2String(products, i);
            stati = product + ": " + (string)lev + units+"\n";
            primFound = FALSE;
            count = llGetNumberOfPrims();
            for (lnk=2; lnk <= count; lnk++)
            {
                //method one: show status of specific products on linked prims
                if (llGetLinkName(lnk) == product)
                {
                    // has an indicator prim so remove from list of no prim products
                    primFound = TRUE;
                    noPrimProducts = llDeleteSubList(noPrimProducts, i, i);
                    found++;
                    // Set the colour
                    c = GREEN;
                    // Get level as a percent for colour coding
                    float adjLevel = lev*100/maxFill;
                         if (adjLevel < 10) c = ORANGE;
                    else if (adjLevel < 40) c = YELLOW;
                    else if (adjLevel > 95) c =  AQUA;
                    pstate = llGetLinkPrimitiveParams(lnk, [PRIM_POS_LOCAL, PRIM_DESC]);
                    p = llList2Vector(pstate, 0);
                    desc = llParseStringKeepNulls(llList2String(pstate, 1), [","], []);
                    if (llGetListLength(desc) == 2)
                    {
                        minHeight = llList2Float(desc, 0);
                        maxHeight = llList2Float(desc, 1);
                        p.z = minHeight + (maxHeight-minHeight) * (float)(lev) / maxFill;
                        llSetLinkPrimitiveParamsFast(lnk, [PRIM_POS_LOCAL, p]);
                    }
                    if (TXT_COLOR != ZERO_VECTOR) llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXT, stati, c, textBrightness]);
                     else llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
                }
                else
                {

                }
            }
            // No indicator prim found for this product so at to the float text we will put on root prim
            if (primFound == FALSE) statTotal += "\n" + stati;
        }

        // Add on any custom text that has been sent from other components
        string customStr = "";
        i = llGetListLength(customText);
        while (i--)
        {
            customStr = llList2String(customText, i) + "\n";
        }
        // If Beta or RC, add that text also
        if (RSTATE == 0) customStr += "\n-B-"; else if (RSTATE == -1) customStr += "\n-RC-";


        if (llGetListLength(noPrimProducts) != 0)
        {
            // if no prim gets status text for particular products, display them on the root prim
            if (TXT_COLOR != ZERO_VECTOR)
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXT,  statTotal +customStr, TXT_COLOR, textBrightness]);
            }
            else
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXT, str, <0.5, 0.0, 0.5>, 0.2]);
            }
        }
        else
        {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXT, customStr, TXT_COLOR, textBrightness]);
        }
        llMessageLinked(LINK_SET, 99, "STORESTATUS|"+(string)singleLevel+"|"+llDumpList2String(products, ",")+"|"+llDumpList2String(levels, ",")+"|"+(string)lastTs, NULL_KEY);
        // Clear up memory
        pstate = [];
        desc = [];
        product = "";
        stati ="";
        lnk =0;
        minHeight =0.0;
        maxHeight=0.0;
        p = ZERO_VECTOR;
        c = ZERO_VECTOR;
        found = 0;
        statTotal = "";
    }
    if (llGetListLength(products) == 0)
    {
        if (TXT_COLOR == ZERO_VECTOR) p = ZERO_VECTOR; else p = TXT_COLOR;
        str = "";
        if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
        llSetText(TXT_EMPTY+str, p, 1.0);
    }
}

rezzItem(string m, key agent)
{
    string object = "SF " + m;
    if (llGetInventoryType(object) != INVENTORY_OBJECT)
    {
        llRegionSayTo(agent, 0, object + " " + TXT_NOT_STORED);
    }
    else
    {
        integer idx = llListFindList(products, [m]);
        if (idx >= 0 && llList2Integer(levels,idx) >= singleLevel)
        {
            integer l = llList2Integer(levels,idx);
            l-= singleLevel;
            if (l <0) l =0;
            levels = [] + llListReplaceList(levels, [l], idx, idx);
            llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)agent +"|" +object, NULL_KEY);
            saveConfig();
            refresh(1);
        }
        else llRegionSayTo(agent, 0, TXT_NOT_ENOUGH);
    }
}

getItem(string m)
{
    integer idx = llListFindList(products, [m]);
    if (idx >=0 && llList2Integer(levels,idx) >= maxFill)
    {
        llRegionSayTo(toucher, 0, TXT_FULL + " " + m);
        if (status == "SELL")
        {
            llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
        }
    }
    else
    {
        lookingFor = "SF " +m;
        llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
    }
}

list getAvailProducts()
{
    list availProducts = [];
    integer len = llGetListLength(products);
    while (len--)
    {
        if (llList2Integer(levels, len) >= singleLevel)
        {
            availProducts += [llList2String(products, len)];
        }
    }
    return availProducts;
}

doBeacon(vector colour)
{
    llParticleSystem([]);
    llSleep(0.2);
    llParticleSystem( [
        PSYS_PART_FLAGS,       PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN,      PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_PART_START_COLOR, colour,
        PSYS_SRC_BURST_PART_COUNT, 2,
        PSYS_SRC_BURST_RATE, 1

    ] );
}

doTouch(key toucherID)
{
    if (status == "awaitConfirmTouch")
    {
        status = "";
        messageObj(controller, "REQUEST-INV-OKAY|"+PASSWORD);
    }
    else if (status == "stockXferCheck")
    {
        if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
        {
            llRemoveInventory(STORAGENC);
            llSleep(0.5);
        }
        messageObj(controller, "XFER-READY|"+PASSWORD);
    }
    else
    {
        toucher = toucherID;
        if (!llSameGroup(toucher) && !osIsNpc(toucher))
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
        }
        else
        {
            if (doReset == -1)
            {
                llRegionSayTo(toucher, 0, TXT_ERROR_LOCKED);
            }
            else
            {
                status = "";
                hudDetected = FALSE;
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)toucher +"|CQ");
                llSleep(0.25);
                list opts = [];
                if ((toucher == llGetOwner()) || (groupAddStock == TRUE))
                {
                    opts += [TXT_ADD_STOCK, TXT_LANGUAGE, TXT_CLOSE, TXT_ADD, TXT_GET, TXT_CHECK];
                }
                else
                {
                    opts += [TXT_CHECK, TXT_LANGUAGE, TXT_CLOSE, TXT_ADD, TXT_GET];
                }
                opts += customOptions;
                startListen();
                llDialog(toucher, TXT_SELECT, opts, chan(ownKey));
                llSetTimerEvent(300);
            }
        }
    }
}

default
{
    listen(integer c, string nm, key id, string m)
    {
        debug("listen: " +m +"  share mode=" +shareMode +"  status=" +status);
        if (c == FARM_CHANNEL)
        {
            list tk = llParseString2List(m, ["|"], []);
            string cmd = llList2String(tk, 0);

            if ((llList2String(tk, 1) != PASSWORD) || (shareMode == "none"))
            {
                //    return;
            }
            else
            {
                if (cmd == "INV_QRY")
                {
                    if ((shareMode != "group") || ( ownGroup == llList2Key(llGetObjectDetails(id, [OBJECT_GROUP]), 0)))
                    {
                        string object = "SF " + llList2String(tk, 3);
                        if (llGetInventoryType(object) == INVENTORY_OBJECT)
                        {
                            llRegionSay(FARM_CHANNEL, "INV_AVAIL|" +PASSWORD +"|" +(string)ownKey +"|" +object);
                        }
                    }
                }
                else if (cmd == "INV_REQ")
                {
                    // Belt and braces check we still have the item!
                    string object = llList2String(tk, 3);
                    if ((llGetInventoryType(object) == INVENTORY_OBJECT) && (llList2Key(tk, 2) == ownKey))
                    {
                        llGiveInventory(id, object);
                    }
                }
            }
        }
        else
        {
            // DIALOG CHANNEL
            //pre-select product if there is just one
            string product = "";
            if (llGetListLength(products) == 1)
            {
                product = llList2String(products, 0);
            }
            //parse buttons
            if (m == TXT_CLOSE)
            {
                checkListen(TRUE);
                status ="";
                refresh(1);
            }
            else if ((m == TXT_ADD) || (m == NPC_ADD))
            {
                tmpkey = id;
                status = "SELL";
                if (product != "")
                {
                    getItem(product);
                    /*
                    list opts = [TXT_CLOSE, TXT_ADD, TXT_GET] + customOptions;
                    llDialog(id, TXT_SELECT+"XX", opts, chan(ownKey));
                    */
                }
                else
                {
                    startOffset = 0;
                    lookingFor = "all";
                    llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
                }
            }
            else if (m == TXT_GET)
            {
                if (product != "")
                {
                    rezzItem(product, id);
                    list opts = [TXT_CLOSE, TXT_ADD, TXT_GET] + customOptions;
                    llDialog(id, TXT_SELECT, opts, chan(ownKey));
                }
                else
                {
                    status = "GET";
                    availProducts = [] + getAvailProducts();
                    availProducts = llListSort(availProducts, 1, SORTDIR);
                    if (availProducts == [])
                    {
                        llRegionSayTo(id, 0, TXT_NOT_AVAILABLE);
                        checkListen(TRUE);
                    }
                    else
                    {
                        startListen();
                        startOffset = 0;
                        multiPageMenu(id, TXT_GET_ITEM, availProducts);
                    }
                }
            }
            else if (m == TXT_CHECK)
            {
                integer i;
                string str = TXT_LEVELS + ":\n";
                string units;
                if (maxFill >100) units = "/"+(string)maxFill; else units = "%";
                for (i=0;  i < llGetListLength(products); i++)
                {
                    str += "\t"+llList2String(products, i)+": "+(string)((integer)llList2Float(levels,  i))+units+"\n";
                }
                llRegionSayTo(toucher, 0, str);
                checkListen(TRUE);
            }
            else if (m == TXT_LANGUAGE)
            {
                llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
                checkListen(TRUE);
            }
            else if (m == TXT_ADD_STOCK)
            {
                startOffset = 0;
                lookingFor = "all";
                status = "stockScan";
                llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
            }
            // End of buttons, now use status
            else if (status  == "SELL")
            {
                if (m == ">>") startOffset += 10;  else getItem(m);
            }

            else if (status  == "GET")
            {
                if (m == ">>")
                    startOffset += 10;
                else
                    rezzItem(m, id);
                list availProducts = getAvailProducts();
                availProducts = llListSort(availProducts, 1, SORTDIR);
                if (availProducts != [])
                {
                    multiPageMenu(id, TXT_GET_ITEM, availProducts);
                }
                else
                {
                    checkListen(TRUE);
                }
            }
            else if (status == "stockScan")
            {
                lookingFor = SF_PREFIX +" " +m;
                if (llGetInventoryType(lookingFor) != INVENTORY_OBJECT)
                {
                    status = "waitNewInventory";
                    llOwnerSay(TXT_CHECKING);
                    llSetText(TXT_CHECKING+"\n"+ lookingFor, TXT_COLOR, textBrightness);
                    llMessageLinked(LINK_SET, 0, "GET_PRODUCT|" +PASSWORD +"|" +lookingFor, NULL_KEY);
                }
                else
                {
                    llOwnerSay(TXT_IN_INVENTORY+": "+lookingFor);
                    status = "";
                }
            }
            else
            {
                llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
            }
        }
    }

    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD ) return;
        if (cmd == "INIT")
        {
            doReset = 2;
            loadConfig(FALSE);
            saveConfig();
            llSetRemoteScriptAccessPin(0);
            llSetTimerEvent(1);
        }
        else if (cmd == "HEALTH")
        {
            if (llList2Key(tk, 3) == toucher)
            {
                hudDetected = TRUE;
            }
        }
        //for updates
        else if (cmd == "VERSION-CHECK")
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
            messageObj(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, TXT_ERROR_UPDATE);
            }
            else
            {
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
                messageObj(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
                if (delSelf)
                {
                    llRemoveInventory(me);
                }
                llSleep(10.0);
                llResetScript();
            }
        }
        else if (cmd == "GIVE")
        {
            string productName = llList2String(tk,2);
            key u = llList2Key(tk,3);
            integer idx = llListFindList(products, [productName]);
            if (idx>=0 && llList2Float(levels, idx) > singleLevel )
            {
                integer l = llList2Integer(levels,idx);
                l-= singleLevel;
                if (l <0) l =0;
                levels = [] + llListReplaceList(levels, [l], idx, idx);;
                messageObj(u, "HAVE|"+PASSWORD+"|"+productName+"|"+(string)ownKey);
                llMessageLinked(LINK_SET, 99, "REZZEDPRODUCT|" + (string)u + "|" + productName, NULL_KEY);
                saveConfig();
                refresh(1);
            }
            else llRegionSayTo(toucher, 0, productName + "-" + TXT_NOT_ENOUGH);
        }

        else if (cmd == "REQUEST-INV-START")
        {
            status = "awaitConfirmTouch";
            controller = k;
            doBeacon(<1.000, 0.522, 0.106>);
        }
        else if (cmd == "REQUEST-INV-CONFIRM")
        {
            if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
            {
                llGiveInventory(controller, STORAGENC);
                llSleep(1.0);
                messageObj(controller, "REQUEST-INV-SENT|" +PASSWORD);
            }
            else
            {
                messageObj(controller, "REQUEST-INV-FAIL|" +PASSWORD);
                llResetScript();
            }
        }
        else if (cmd == "REQUEST-INV-DONE")
        {
            llSetText("", ZERO_VECTOR, 0);
            llRemoveInventory(STORAGENC);
            llParticleSystem([]);
            llResetScript();
        }
        else if (cmd == "REQUEST-INV-ABORT")
        {
            llParticleSystem([]);
            status = "";
        }
        else if (cmd == "STOCK-XFER-CHECK")
        {
            status = "stockXferCheck";
            controller = k;
            doBeacon(<0.180, 0.800, 0.251>);
        }
        else if (cmd == "REQUEST-XFER-CONFIRM")
        {
            llParticleSystem([]);
            if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
            {
                messageObj(controller, "XFER-CONFIRM-OKAY|" +PASSWORD);
                status = "stockXferDo";
            }
            else
            {
                llSleep(2);
                if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
                {
                    messageObj(controller, "XFER-CONFIRM-OKAY|" +PASSWORD);
                    status = "stockXferDo";
                }
                else
                {
                    messageObj(controller, "XFER-CONFIRM-FAIL|" +PASSWORD);
                }
            }
            if (status == "stockXferDo")
            {
                list storageList = llParseString2List(llStringTrim(osGetNotecard(STORAGENC), STRING_TRIM), [";"], []);
                products = llParseString2List(llList2String(storageList,1), [","], []);
                levels = llParseString2List(llList2String(storageList,2), [","], []);
                llRemoveInventory(STORAGENC);
                llSleep(2);
                osMakeNotecard(STORAGENC, ownKey + llDumpList2String(llList2List(storageList, 1, -1), ";"));
                if (llGetListLength(storageList) > 3)
                {
                    lastTs = llList2Integer(storageList, 3);
                }
                ++saveNC;
                ++saveNC;
                refresh(1);
            }
        }
        else if (doReset == -1)
        {
            //return;
        }
        else
        {
            // Add something to the jars
            string units;
            if (maxFill >100) units = "/"+(string)maxFill; else units = "%";
            integer i;
            for (i=0; i < llGetListLength(products); i++)
            {
                if (llToUpper(llList2String(products,i)) ==  cmd)
                {
                    // Fill up
                    integer l = llList2Integer(levels, i);
                    l += singleLevel; if (l > maxFill) l = maxFill;
                    levels = llListReplaceList(levels, [l], i,i);
                    llRegionSayTo(toucher, 0, TXT_ADDED +" " +llToLower(cmd) +", " +TXT_LEVEL +" " +(string)llRound(l)+units);
                    llMessageLinked(LINK_SET, 99, "GOTPRODUCT|" + (string)tmpkey + "|" + llList2String(products, i), NULL_KEY);
                    saveConfig();
                    refresh(1);
                }
            }
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    timer()
    {
        if ((status == "waitNewInventory") || (status == "stockScan"))
        {
            llSetText("", ZERO_VECTOR, 0);
        }
        refresh(0);
        checkListen(FALSE);
        status = "";
        llSetTimerEvent(1000);
    }

    touch_start(integer n)
    {
        debug("touch:status="+status);
        doTouch(llDetectedKey(0));
    }

    sensor(integer n)
    {
        debug("sensor:lookingFor="+lookingFor+" Status="+status);
        if (lookingFor == "all")
        {
            list buttons = [];
            string name;
            string desc;
            while (n--)
            {
                name = llKey2Name(llDetectedKey(n));
                if (llGetSubString(name, 0, 2) == SF_PREFIX+" ")
                {
                    name = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);
                    if (status == "stockScan")
                    {
                        if (llListFindList(buttons, [name]) == -1)
                        {
                            desc= llList2String(llGetObjectDetails(llDetectedKey(n), [OBJECT_DESC]), 0);
                            if (llGetSubString(desc, 0,1) == "P;") buttons += [name];
                        }
                    }
                    else if (llListFindList(products, [name]) != -1 && llListFindList(buttons, [name]) == -1)
                    {
                        buttons += [name];
                    }
                }
            }
            if (buttons == [])
            {
                if (selitems == [])
                {
                    llRegionSayTo(toucher, 0, TXT_NOT_FOUND);
                }
                checkListen(TRUE);
            }
            else
            {
                if (status == "stockScan")
                {
                    // put buttons so closest will appear on the top left
                    buttons = listReverse(buttons);
                }
                checkListen(TRUE);
                startListen();
                multiPageMenu(toucher, TXT_STORE_ITEM, buttons);
            }
        }
        else
        {
            //get first product that isn't already selected and has enough percentage
            integer c;
            key ready_obj = NULL_KEY;
            key obj;
            list stats;
            integer have_percent;
            for (c = 0; ready_obj == NULL_KEY && c < n; c++)
            {
                obj = llDetectedKey(c);
                stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
                have_percent = llList2Integer(stats, 1);
                // have_percent == 0 for backwards compatibility with old items
                if (llListFindList(selitems, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
                {
                    ready_obj = llDetectedKey(c);
                }
            }
            //--
            if (ready_obj == NULL_KEY)
            {
                llRegionSayTo(toucher, 0, lookingFor + " " + TXT_NOT_FOUND100);
            }
            else
            {
                selitems += [ready_obj];
                llRegionSayTo(toucher, 0, TXT_FOUND +"  " +lookingFor + ", " + TXT_EMPTYING);
                messageObj(ready_obj, "DIE|"+(string)ownKey);
                if (status == "SELL")
                {
                    lookingFor = "all";
                    llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
                }
            }
        }
    }


    no_sensor()
    {
        debug("no_sensor:lookingFor="+lookingFor+" Status="+status);
        if (lookingFor == "all" && selitems == [])
        {
            llRegionSayTo(toucher, 0, TXT_NOT_FOUND);
        }
        else
        {
            llRegionSayTo(toucher, 0, lookingFor +" " +TXT_NOT_FOUND100);
        }
        checkListen(TRUE);
    }


    state_entry()
    {
        llParticleSystem([]);
        //give it some time to load inventory items
        llSleep(2.0);
        //for updates
        if (osRegexIsMatch(llGetObjectName(), "(Update|Rezz)+"))
        {
            string me = llGetScriptName();
            llSetScriptState(me, FALSE);
            llSleep(0.5);
        }
        else
        {
            ownKey = llGetKey();
            ownGroup = llList2Key(llGetObjectDetails(ownKey, [OBJECT_GROUP]), 0);
            lastTs = llGetUnixTime();
            timeoutTs = lastTs;
            loadConfig(TRUE);
            loadLanguage(languageCode);
            llMessageLinked(LINK_SET, 99, "RESET", NULL_KEY);
            llListen(FARM_CHANNEL, "", "", "");
            refresh(1);
            llSetTimerEvent(1);
        }
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "ADD_MENU_OPTION")
        {
            string option = llList2String(tk, 1);
            if (llListFindList(customOptions, [option]) == -1)
            {
                customOptions += [option];
            }
        }
        else if (cmd == "REM_MENU_OPTION")
        {
            integer findOpt = llListFindList(customOptions, [llList2String(tk,1)]);
            if (findOpt != -1)
            {
                customOptions = llDeleteSubList(customOptions, findOpt, findOpt);
            }
        }
        else if (cmd == "ADD_TEXT")
        {
            customText += [llList2String(tk,1)];
        }
        else if (cmd == "RELOAD")
        {
            llResetScript();
        }
        else if (cmd == "REM_TEXT")
        {
            integer findTxt = llListFindList(customText, [llList2String(tk,1)]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
        }
        else if (cmd == "SETSTATUS")
        {
            products = llParseStringKeepNulls(llList2String(tk,1), [","], []);
            levels = llParseStringKeepNulls(llList2String(tk,2), [","], []);
            lastTs = llList2Integer(tk, 3);
            refresh(0);
            saveConfig();
        }
        else if (cmd == "GETPRODUCT")
        {
            rezzItem(llList2String(tk,1), id);
        }
        else if (cmd == "ADDPRODUCT")
        {
            tmpkey = id;
            checkListen(TRUE);
            getItem(llList2String(tk,1));
        }
        else if (cmd == "ADDPRODUCTNUM")
        {
            string product = llList2String(tk, 1);
            integer num = llList2Integer(tk, 2);
            integer found = llListFindList(products, [product]);
            integer level;
            if (found != -1)
            {
                level = llList2Integer(levels, found) + (num * singleLevel);
                levels = llListReplaceList(levels, [level], found, found);
                refresh(1);
                saveConfig();
            }
        }
        else if (cmd == "SETLEVEL")
        {
            string product = llList2String(tk, 1);
            integer level = llList2Integer(tk, 2);
            integer found = llListFindList(products, [product]);
            if (found != -1)
            {
                levels = llListReplaceList(levels, [level], found, found);
            }
            else
            {
                products += [product];
                levels += [level];
            }
            refresh(1);
            saveConfig();
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetObjectDesc("S;" + languageCode);
            refresh(0);
        }
        else if (cmd == "PRODUCT_FOUND")
        {
            llSetText("", ZERO_VECTOR,0);
            llResetScript();
        }
        else if (cmd == "NO_PRODUCT")
        {
            llSetText(TXT_INV_SEARCH_FAIL+"\n \n  "+lookingFor, TXT_COLOR, textBrightness);
            llOwnerSay(TXT_INV_SEARCH_FAIL+": "+lookingFor);
            llSetTimerEvent(5);
        }
        else if (cmd == "WAS_TOUCHED")
        {
            toucher = id;
            doTouch(toucher);
        }
        else if (cmd == "CMD_DEBUG")
        {
            DEBUGMODE = llList2Integer(tk, 2);
            if (DEBUGMODE == TRUE) llOwnerSay("DEBUG ON"); else llOwnerSay("DEBUG OFF");
        }
        else if (cmd == "IGNORE_CHANGED")
        {
            //next changed item event will be ignored
            ++saveNC;
        }
    }

    object_rez(key id)
    {
        llSleep(0.4);
        if (hudDetected == TRUE)
        {
            if (llGetListLength(llGetObjectDetails(id, [OBJECT_NAME])) !=0)  messageObj(id, "INIT|" +PASSWORD +"|" +(string)toucher);
        }
        else
        {
            if (llGetListLength(llGetObjectDetails(id, [OBJECT_NAME])) !=0) messageObj(id, "INIT|" +PASSWORD);
        }
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id, NULL_KEY);
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (saveNC)
            {
                --saveNC;
                loadConfig(FALSE);
                loadLanguage(languageCode);
                refresh(1);
            }
            else if ((status != "stockXfer") && (status != "stockXferCheck"))
            {
                llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
                llResetScript();
            }
            else
            {
                loadConfig(FALSE);
                loadLanguage(languageCode);
                refresh(0);
            }
        }
    }

}
