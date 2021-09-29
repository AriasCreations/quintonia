// CHANGE LOG
// Exchange now is part of the share grid for distributing products
// config notecard option added  USE_HTTPS=0
// Extra products added to contents
// Some tweaks to displays (including fixing the 'href=' but that often showed!)
// Added a RESET button (visisble to owner only)
// Added state_entry check to not run script if in the updater
//
/////////////////////////////////////////////

// quintonia_exchange.lsl
// -----------------------------------------
//  QUINTONIA EXCHANGE
//  Allows anyone with a Quintonia account
//  to buy & sell goods using Quinto coins
// -----------------------------------------
//
float   VERSION = 5.3;    // 6 May 2021
integer RSTATE = 1;       // RSTATE = 1 for release, 0 for beta, -1 for Release candidate
//
integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}
//
// Server URLs
string URL =   "quintopia.org/index.php?option=com_quinty&format=raw&";
string ImageURL = "quintopia.org/images/logo/qex.png";
string BASEURL;
string BASEIMAGEURL;
//
string REGURL   = "https://quintopia.org/register";
//
string marketType = "market_grocery.inf";  // or  market_hardware.inf  or  market_concessions.inf  or  market_bazaar.inf
//
// Can be overridden by config notecard
string  exchangeType = "grocery";           // TYPE=Grocery         can be 'grocery', 'bazaar', 'hardware' or 'concessions'   [bazaar is grocery minus concessions items]
integer useScreen = 1;                      // SCREEN=1             Set to 0 for exchanges that don't use a screen
integer FACE = 4;                           // FACE=4               Which face to display information on
vector  rezzPosition = <-1.5, 0.0, -1.0>;   // REZ_POSITION=
integer SENSOR_DISTANCE = 10;               // SENSOR_DISTANCE=10   Radius in m to scan
integer offset = 0;                         // Offset from UTC
integer useHTTPS = FALSE;                   // USE_HTTPS=0;     Set to 1 to force https comms with server
string  languageCode = "en-GB";             //
//
string  SUFFIX = "E1";
// Multilingual support
string    TXT_ACCESS_LEVEL         =    "Access level";
string    TXT_ACTIVATE             =    "Activate";
string    TXT_ALWAYS_SELL          =    "Normal";
string    TXT_AM                   =    "AM";
string    TXT_BAD_PASSWORD         =    "Comms error";
string    TXT_BAZAAR               =    "Bazaar";
string    TXT_BUY                  =    "Buy goods";
string    TXT_BUY_SELL             =    "Trade";
string    TXT_CHARGED              =    "You have been charged";
string    TXT_CHECKING             =    "Checking other locations...";
string    TXT_CHECKING_POINTS      =    "Checking...";
string    TXT_CLICK_FOR_MENU       =    "Click for menu...";
string    TXT_CLOSE                =    "CLOSE";
string    TXT_COINS                =    "Coins";
string    TXT_COIN_SYMBOL          =    "Q";
string    TXT_CREDITED             =    "You have been credited ";
string    TXT_EMPTYING             =    "emptying";
string    TXT_ERROR_DISABLED       =    "Sorry, system is currently disabled";
string    TXT_ERROR_GROUP          =    "Error, we are not in the same group";
string    TXT_ERROR_NOT_FOUND      =    "not found nearby";
string    TXT_ERROR_UPDATE         =    "Error: unable to update - you are not my Owner";
string    TXT_EVERYONE             =    "Everyone";
string    TXT_EX_TYPE              =    "Exchange type";
string    TXT_GROCERY              =    "Grocery";
string    TXT_FARM_NAME            =    "Farm name";
string    TXT_FOUND                =    "Found";
string    TXT_GIVE_PURCHASE        =    "Here is your purchase of ";
string    TXT_GROUP                =    "Group";
string    TXT_GROUP_ONLY           =    "Sorry, this board only allows members of the group to use it";
string    TXT_HARDWARE             =    "Hardware";
string    TXT_CONCESSIONS          =    "Concessions";
string    TXT_INFO_MSG1            =    "To use points you first need to create an account";
string    TXT_INFO_MSG2            =    "You can create just a web account and link this avatar or create a new Quintonia avatar account.";
string    TXT_INSUFFICIENT_POINTS  =    "Sorry, you don't have enough points.";
string    TXT_LAST_UPDATE          =    "Last update";
string    TXT_LOCAL                =    "Local";
string    TXT_LOCAL_ONLY           =    "Sorry, this board only allows local residents to use it";
string    TXT_NAME                 =    "Name";
string    TXT_NO_STOCK             =    "I don't have any stock of";
string    TXT_NOT_FOUND            =    "Nothing found nearby.";
string    TXT_NOT_FOUND_INV        =    "Unable to find item in any other locations, sorry";
string    TXT_NOT_FOUND_ITEM       =    "not found nearby. You must bring them closer";
string    TXT_NOT_FOUND100         =    "with 100% not found nearby.";
string    TXT_NOW_AVAILABLE        =    "Now available";
string    TXT_OFFLINE              =    "-- System Offline --";
string    TXT_OPERATION_MODE       =    "Operation mode";
string    TXT_OPTIONS              =    "Options";
string    TXT_PM                   =    "PM";
string    TXT_POINTS               =    "XP";
string    TXT_PRICES               =    "Show prices";
string    TXT_RANK                 =    "Rank";
string    TXT_READY                =    "Ready";
string    TXT_SCORE                =    "Score";
string    TXT_SELECT               =    "Choose option";
string    TXT_SELL                 =    "Sell goods";
string    TXT_SELL_ONLY            =    "Sell only";
string    TXT_TOPTEN               =    "Quintonia Points Top TEN";
string    TXT_YOU_HAVE             =    "You have";
string    TXT_LANGUAGE             =    "@";
//
string TXT_RECENT_ACTIVITY = "Your Recent Activity";
string TXT_ACTIVITY = "Activity";
string TXT_DETAILS = "Details";
string TXT_RESET = "RESET";
//
string    TXT_DAYS="Days";
string    TXT_SUN="Sun";
string    TXT_MON="Mon";
string    TXT_TUE="Tue";
string    TXT_WED="Wed";
string    TXT_THU="Thu";
string    TXT_FRI="Fri";
string    TXT_SAT="Sat";
list    weekdays;
//
vector GREEN       = <0.180, 0.800, 0.251>;
vector YELLOW      = <1.000, 0.863, 0.000>;
vector WHITE       = <1.0, 1.0, 1.0>;
integer CREDIT = 1;
integer DEBIT = -1;
string farmName = "My Farm";
string PASSWORD="*";
string stockNC = "stklst";
integer quinActive;
integer slaveState;
key farmHTTP = NULL_KEY;
integer FARM_CHANNEL = -911201;
key userToPay;
key owner;
key ownKey;
string lookingFor;
string itemPrice;
integer startOffset = 0;
integer screenListOffset = 0;
integer screenCapacity = 60;
string status;
string screenState;
integer accessMode = 0;     // 0=Everyone, 1=Group, 2=Local residents
integer opMode = 1;         // 0=Only items sold to this exchange can be purchased, 1=Normal operation
list modeNames = [];
list items = [];
list prices = [];
list sellItems = [];
list stockItems = [];   // [item, quantity]
string  shareMode = "all";  // SHARE_MODE is always =All for the exchange
integer gIntMinute = 60;    //-- 1 minute in seconds
integer gIntHour   = 3600;  //-- 1 hour in seconds
integer gInt12Hr   = 43200; //-- 12hrs in seconds
integer gIntDay    = 86400; //-- 1 day in seconds


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
                          if (cmd == "TYPE") exchangeType = llToLower(val);
                     else if (cmd == "SCREEN") useScreen = (integer)val;
                     else if (cmd == "FACE") FACE = (integer)val;
                     else if (cmd == "SENSOR_DISTANCE") SENSOR_DISTANCE = (integer)val;
                     else if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
                     else if (cmd == "TIME_OFFSET") offset = (integer)val;
                     else if (cmd == "LANG") languageCode = val;
                     else if (cmd == "USE_HTTPS") useHTTPS = (integer)val;
            }
        }
    }
    if (exchangeType == "grocery") marketType = "market_grocery.inf"; else if (exchangeType == "hardware") marketType = "market_hardware.inf"; else if (exchangeType == "concessions") marketType = "market_concessions.inf"; else marketType = "market_bazaar.inf";
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "E")
    {
        accessMode = llList2Integer(desc, 1);
        languageCode = llList2String(desc, 2);
        farmName = llList2String(desc, 3);
        exchangeType = llList2String(desc, 4);
        opMode = llList2Integer(desc, 5);
    }
    else
    {
        saveToDesc();
    }
    // Set HTTP/HTTPS option
    if (useHTTPS == TRUE)
    {
        BASEURL = "https://"+URL;
        BASEIMAGEURL = "https://"+ImageURL;
    }
    else
    {
        BASEURL = "http://"+URL;
        BASEIMAGEURL = "http://"+ImageURL;
    }
    llMessageLinked(LINK_SET, useHTTPS, "SETHTTPS", "");
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

                         if (cmd == "TXT_ACCESS_LEVEL")      TXT_ACCESS_LEVEL     = val;
                    else if (cmd == "TXT_ACTIVATE")          TXT_ACTIVATE         = val;
                    else if (cmd == "TXT_ACTIVITY")          TXT_ACTIVITY         = val;
                    else if (cmd == "TXT_ALWAYS_SELL")       TXT_ALWAYS_SELL      = val;
                    else if (cmd == "TXT_AM")                TXT_AM               = val;
                    else if (cmd == "TXT_BAD_PASSWORD")      TXT_BAD_PASSWORD     = val;
                    else if (cmd == "TXT_BAZAAR")            TXT_BAZAAR           = val;
                    else if (cmd == "TXT_BUY")               TXT_BUY              = val;
                    else if (cmd == "TXT_BUY_SELL")          TXT_BUY_SELL         = val;
                    else if (cmd == "TXT_CHARGED")           TXT_CHARGED          = val;
                    else if (cmd == "TXT_CHECKING")          TXT_CHECKING         = val;
                    else if (cmd == "TXT_CHECKING_POINTS")   TXT_CHECKING_POINTS  = val;
                    else if (cmd == "TXT_CLICK_FOR_MENU")    TXT_CLICK_FOR_MENU   = val;
                    else if (cmd == "TXT_CLOSE")             TXT_CLOSE            = val;
                    else if (cmd == "TXT_COINS")             TXT_COINS            = val;
                    else if (cmd == "TXT_COIN_SYMBOL")       TXT_COIN_SYMBOL      = val;
                    else if (cmd == "TXT_CREDITED")          TXT_CREDITED         = val;
                    else if (cmd == "TXT_DETAILS")           TXT_DETAILS          = val;
                    else if (cmd == "TXT_EMPTYING")          TXT_EMPTYING         = val;
                    else if (cmd == "TXT_ERROR_DISABLED")    TXT_ERROR_DISABLED   = val;
                    else if (cmd == "TXT_ERROR_GROUP")       TXT_ERROR_GROUP      = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND")   TXT_ERROR_NOT_FOUND  = val;
                    else if (cmd == "TXT_ERROR_UPDATE")      TXT_ERROR_UPDATE     = val;
                    else if (cmd == "TXT_EVERYONE")          TXT_EVERYONE         = val;
                    else if (cmd == "TXT_EX_TYPE")           TXT_EX_TYPE          = val;
                    else if (cmd == "TXT_GROCERY")           TXT_GROCERY          = val;
                    else if (cmd == "TXT_FARM_NAME")         TXT_FARM_NAME        = val;
                    else if (cmd == "TXT_FOUND")             TXT_FOUND            = val;
                    else if (cmd == "TXT_GIVE_PURCHASE")     TXT_GIVE_PURCHASE    = val;
                    else if (cmd == "TXT_GROUP")             TXT_GROUP            = val;
                    else if (cmd == "TXT_GROUP_ONLY")        TXT_GROUP_ONLY       = val;
                    else if (cmd == "TXT_HARDWARE")          TXT_HARDWARE         = val;
                    else if (cmd == "TXT_CONCESSIONS")       TXT_CONCESSIONS      = val;
                    else if (cmd == "TXT_INFO_MSG2")         TXT_INFO_MSG2        = val;
                    else if (cmd == "TXT_INFO_MSG1")         TXT_INFO_MSG1        = val;
                    else if (cmd == "TXT_INSUFFICIENT_POINTS") TXT_INSUFFICIENT_POINTS = val;
                    else if (cmd == "TXT_LAST_UPDATE") TXT_LAST_UPDATE            = val;
                    else if (cmd == "TXT_LOCAL")   TXT_LOCAL                      = val;
                    else if (cmd == "TXT_LOCAL_ONLY")   TXT_LOCAL_ONLY            = val;
                    else if (cmd == "TXT_NAME")      TXT_NAME                     = val;
                    else if (cmd == "TXT_NOT_FOUND")  TXT_NOT_FOUND               = val;
                    else if (cmd == "TXT_NO_STOCK")    TXT_NO_STOCK               = val;
                    else if (cmd == "TXT_NOT_FOUND_INV") TXT_NOT_FOUND_INV        = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM") TXT_NOT_FOUND_ITEM      = val;
                    else if (cmd == "TXT_NOT_FOUND100") TXT_NOT_FOUND100          = val;
                    else if (cmd == "TXT_NOW_AVAILABLE")  TXT_NOW_AVAILABLE       = val;
                    else if (cmd == "TXT_OFFLINE") TXT_OFFLINE                    = val;
                    else if (cmd == "TXT_OPERATION_MODE") TXT_OPERATION_MODE      = val;
                    else if (cmd == "TXT_OPTIONS")    TXT_OPTIONS                 = val;
                    else if (cmd == "TXT_PM")         TXT_PM                      = val;
                    else if (cmd == "TXT_POINTS")     TXT_POINTS                  = val;
                    else if (cmd == "TXT_PRICES") TXT_PRICES                      = val;
                    else if (cmd == "TXT_RANK")   TXT_RANK                        = val;
                    else if (cmd == "TXT_READY")  TXT_READY                       = val;
                    else if (cmd == "TXT_RECENT_ACTIVITY") TXT_RECENT_ACTIVITY    = val;
                    else if (cmd == "TXT_SCORE") TXT_SCORE                        = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT                      = val;
                    else if (cmd == "TXT_SELL") TXT_SELL                          = val;
                    else if (cmd == "TXT_SELL_ONLY")   TXT_SELL_ONLY              = val;
                    else if (cmd == "TXT_TOPTEN")  TXT_TOPTEN                     = val;
                    else if (cmd == "TXT_YOU_HAVE")   TXT_YOU_HAVE                = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE                  = val;
                    else if (cmd == "TXT_SUN") TXT_SUN = val;
                    else if (cmd == "TXT_MON") TXT_MON = val;
                    else if (cmd == "TXT_TUE") TXT_TUE = val;
                    else if (cmd == "TXT_WED") TXT_WED = val;
                    else if (cmd == "TXT_THU") TXT_THU = val;
                    else if (cmd == "TXT_FRI") TXT_FRI = val;
                    else if (cmd == "TXT_SAT") TXT_SAT = val;
                }
            }
        }
    }
}

saveToDesc()
{
    llSetObjectDesc("E;" +(string)accessMode+";" +languageCode + ";" +farmName +";" +exchangeType +";" +(string)opMode);
    if (exchangeType == "grocery") marketType = "market_grocery.inf"; else if (exchangeType == "hardware") marketType = "market_hardware.inf"; else if (exchangeType == "concessions") marketType = "market_concessions.inf"; else marketType = "market_bazaar.inf";
}

loadStock()
{
    stockItems = [];
    if (llGetInventoryType(stockNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(stockNC), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            // SF Beef|1
            list values = llParseString2List(llList2String(lines, i), ["|"], []);
            stockItems += values;
        }
    }
    debug("STOCK:" +llDumpList2String(stockItems, ","));
}

saveStock(string item, integer transaction)
{   integer qty;
    if (llGetInventoryType(stockNC) == INVENTORY_NOTECARD) llRemoveInventory(stockNC);
    // Check if item already in stock
    integer invCheck = llListFindList(stockItems, [item]);
    if (invCheck != -1)
    {
        // already in stock so update total
        if (transaction == CREDIT) qty = llList2Integer(stockItems, invCheck+1) +1;
            else qty = llList2Integer(stockItems, invCheck+1) -1;

        if (qty >0) stockItems = llListReplaceList(stockItems, [item, qty], invCheck, invCheck+1);
            else stockItems = llDeleteSubList(stockItems, invCheck, invCheck+1);
    }
    else
    {
        if (transaction == CREDIT)
        {
            // not in stock so add to stock list
            stockItems += [item, 1];
        }
    }
    // now save updated stock list
    string output = "";
    integer count = llGetListLength(stockItems);
    integer i;
    for (i=0; i < count; i+=2)
    {
        output += llList2String(stockItems, i) + "|" + llList2String(stockItems, i+1) +"\n";
    }
    osMakeNotecard(stockNC, output);
}

integer inStock(string prodName)
{
    if (llListFindList(stockItems, [prodName]) != -1) return TRUE; else return FALSE;
}

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
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        status = "";
        sellItems = [];
    }
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(ownKey);
    if (l < 12)
    {
        llDialog(id, message, [TXT_CLOSE]+buttons, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(buttons, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}

setImage()
{
    if (llGetInventoryNumber(INVENTORY_TEXTURE) != 0)
    {
        if (getLinkNum("secondary_display") != -1) llSetLinkTexture(getLinkNum("secondary_display"), llGetInventoryName(INVENTORY_TEXTURE, 0), FACE);
        if (getLinkNum("display_board") != -1) llSetLinkTexture(getLinkNum("display_board"), llGetInventoryName(INVENTORY_TEXTURE, 0), FACE);
    }
    else
    {
        if (getLinkNum("secondary_display") != -1) llSetLinkTexture(getLinkNum("secondary_display"), "cdf521e1-f3d7-4e3b-ab32-34c3b268cba9", FACE);
        if (getLinkNum("display_board") != -1) llSetLinkTexture(getLinkNum("display_board"), "cdf521e1-f3d7-4e3b-ab32-34c3b268cba9", FACE);
    }
}

messageScreen(string msg)
{
    screenState = "idle";
    if (useScreen == TRUE)
    {
        if (getLinkNum("secondary_display") != -1) llSetLinkAlpha(getLinkNum("secondary_display"), 1.0, ALL_SIDES);
        if (getLinkNum("buttons_display") != -1) llSetLinkAlpha(getLinkNum("buttons_display"), 0.0, ALL_SIDES);

        llSetTexture("blank", FACE);
        string body = "width:512,height:512,Alpha:255";
        string CommandList = "";  // Storage for our drawing commands
        string statusColour;
        string tmpStr = "";
        integer X;
        // Draw the border
        if (quinActive == FALSE) {statusColour = "crimson";} else {statusColour = "chartreuse";}
        CommandList = osSetPenSize( CommandList, 70);
        CommandList = osSetPenColor( CommandList, statusColour );
        CommandList = osMovePen( CommandList, 0,0);
        CommandList = osDrawRectangle( CommandList, 505,505);
        // Fill in background
        CommandList = osSetPenColor( CommandList, "cornsilk" );
        CommandList = osMovePen( CommandList, 10, 10 );
        CommandList = osDrawFilledRectangle( CommandList, 490, 490 );
        //
        CommandList = osMovePen(CommandList, 10, 10 );                // Upper left corner
        CommandList = osDrawImage(CommandList, 455, 75, BASEIMAGEURL );   // Display logo
        //
        if (quinActive == TRUE)
        {
            CommandList = osSetPenColor(CommandList, "navy");
            CommandList = osSetFontSize(CommandList, 28);
            vector Extents = osGetDrawStringSize( "vector", farmName, "Arial", 28);
            integer xpos = 256 - ((integer) Extents.x >> 1);        // Center the text horizontally
            CommandList = osMovePen(CommandList, xpos, 75);         // Position the text
            CommandList = osDrawText(CommandList, farmName);        // Place the text
            //
            CommandList = osSetPenColor(CommandList, "darkgreen");
            if (llStringLength(msg) < 40)
            {
                CommandList = osSetFontSize(CommandList, 14);
                Extents = osGetDrawStringSize( "vector", msg, "Arial", 14);
            }
            else
            {
                CommandList = osSetFontSize(CommandList, 12);
                Extents = osGetDrawStringSize( "vector", msg, "Arial", 12);
            }
            xpos = 256 - ((integer) Extents.x >> 1);                // Center the text horizontally
            CommandList = osMovePen(CommandList, xpos, 420);        // Position the text
            CommandList = osDrawText(CommandList, msg);             // Place the text
            // show exchange type
            CommandList = osSetFontSize(CommandList, 7);
            CommandList = osSetPenColor(CommandList, "black");
                 if (exchangeType == "grocery")   tmpStr =  TXT_GROCERY;
            else if (exchangeType == "hardware") tmpStr =  TXT_HARDWARE;
            else if (exchangeType == "concessions") tmpStr = TXT_CONCESSIONS;
            else if (exchangeType == "bazaar") tmpStr =  TXT_BAZAAR;
            // Show version info
            tmpStr += " (V" +qsFixPrecision(VERSION, 2);
            if (RSTATE == 0) tmpStr+= " Beta"; else if (RSTATE == -1) tmpStr+= " RC";
            tmpStr += ")"; 
            CommandList = osMovePen(CommandList, 420, 500);        // Position the text
            CommandList = osDrawText(CommandList, tmpStr);         // Place the text
        }
        else
        {
            CommandList = osSetFontSize(CommandList, 30);
            CommandList = osMovePen(CommandList, 100,150);
            CommandList = osDrawText(CommandList, TXT_OFFLINE);
        }
        osSetDynamicTextureDataBlendFace("", "vector", CommandList, body, TRUE, 2, 0, 245, FACE);
    }
}

showPrices()
{
    screenState = "showPrices";
    if (useScreen == TRUE)
    {
        if (getLinkNum("secondary_display") != -1) llSetLinkAlpha(getLinkNum("secondary_display"), 0.0, ALL_SIDES);

        if (getLinkNum("buttons_display")   != -1)
        {
            llSetLinkAlpha(getLinkNum("buttons_display"), 1.0, ALL_SIDES);
            if (screenListOffset == 0) llSetLinkAlpha(getLinkNum("buttons_display"), 0.0, 2);

            if (screenListOffset+screenCapacity > llGetListLength(items)) llSetLinkAlpha(getLinkNum("buttons_display"), 0.0, 4);
        }
        integer i;
        integer j = llGetListLength(items);
        integer k;
        string outputTextL = "";
        string outputTextR = "";
        string tmpStr = "";
        llSetTexture("blank", FACE);
        string body = "width:512,height:512";
        string CommandList = "";  // Storage for our drawing commands
        string statusColour;
        CommandList = osMovePen(CommandList, 8, 8);                      // Upper left corner
        CommandList = osDrawImage(CommandList, 230, 40, BASEIMAGEURL );  // Display small logo
        // show exchange type
        CommandList = osSetFontSize(CommandList, 10);
        CommandList = osSetPenColor(CommandList, "slateblue");
             if (exchangeType == "grocery")   tmpStr =  TXT_GROCERY;
        else if (exchangeType == "hardware") tmpStr =  TXT_HARDWARE;
        else if (exchangeType == "concessions") tmpStr = TXT_CONCESSIONS;
        else if (exchangeType == "bazaar") tmpStr =  TXT_BAZAAR;
         // Show version info
        tmpStr += " (V" +qsFixPrecision(VERSION, 2);
        if (RSTATE == 0) tmpStr+= " Beta"; else if (RSTATE == -1) tmpStr+= " RC";
        tmpStr += ")"; 
        // Show last update info
        tmpStr += " - " +TXT_LAST_UPDATE + ": " +getDay(offset) +" @ "  +getGMTtime(offset);
        CommandList = osMovePen(CommandList, 60, 40);        // Position the text
        CommandList = osDrawText(CommandList, tmpStr);         // Place the text
        if (quinActive == FALSE) {statusColour = "Red";} else {statusColour = "chartreuse";}
        CommandList = osSetPenSize(CommandList, 20);
        CommandList = osSetPenColor(CommandList, statusColour);
        CommandList = osMovePen(CommandList, 0,0);
        CommandList = osDrawRectangle(CommandList, 505,505);
        CommandList = osMovePen(CommandList, 15, 70);
        CommandList = osSetFontSize(CommandList, 10);
        if (quinActive == TRUE)
        {
            CommandList = osSetPenColor(CommandList, "DarkBlue");
            string product;
            string what;
            //integer j = (integer)(screenCapacity/2);
            for( i = 0; i < screenCapacity; i = i+2 )
            {
                product =  llList2String(items, i+screenListOffset);
                if (product != "")
                {
                    what = "SF " + product;
                    if (llGetInventoryType(what) != INVENTORY_OBJECT)
                    {
                        product = "x ";
                    }
                    else
                    {
                        if (opMode == 0)
                        {

                            if (inStock(what) == FALSE)
                            {
                                product = "x ";
                            }
                            else
                            {
                                product = "• ";
                            }
                        }
                        else
                        {
                            product = "• ";
                        }
                    }
                    outputTextL = outputTextL +product +llList2String(items, i+screenListOffset) +" " +llList2String(prices, i+screenListOffset) +TXT_COIN_SYMBOL +"\n";
                }
                else
                {
                    outputTextL = outputTextL + "-";
                }
                k = i + 1;
                product =  llList2String(items, k+screenListOffset);
                if (product != "")
                {
                    what = "SF " + product;
                    if (llGetInventoryType(what) != INVENTORY_OBJECT)
                    {
                        product = "x ";
                    }
                    else
                    {
                        if (opMode == 0)
                        {

                            if (inStock(what) == FALSE)
                            {
                                product = "x ";
                            }
                            else
                            {
                                product = "• ";
                            }
                        }
                        else
                        {
                            product = "• ";
                        }
                    }
                    outputTextR = outputTextR +product +llList2String(items, k+screenListOffset) +" " +llList2String(prices, k+screenListOffset) +TXT_COIN_SYMBOL +"\n";
                }
                else
                {
                    outputTextL = outputTextL + "-";
                }
            }
            CommandList = osDrawText(CommandList, outputTextL);
            CommandList = osMovePen(CommandList, 280, 70);
            CommandList = osDrawText(CommandList, outputTextR);
        }
        else
        {
            CommandList = osMovePen(CommandList, 150,150);
            CommandList = osDrawText(CommandList, TXT_OFFLINE);
        }
        // Show key
        CommandList = osSetPenSize(CommandList, 1);
        CommandList = osSetPenColor(CommandList, "MidnightBlue");
        // Do it!
        osSetDynamicTextureDataFace("", "vector", CommandList, body, 0, FACE);
        status = "displayActive";
        llSetTimerEvent(60);
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

activate()
{
    // Talk to PHP script and check comms is okay then activate
    postMessage("task=activq327&data1=1");
    userToPay = llGetOwner();
    llSetTimerEvent(60);
    psys(userToPay);
}

postMessage(string msg)
{
    debug("postMessage: " + msg);
    farmHTTP = llHTTPRequest( BASEURL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded", HTTP_BODY_MAXLENGTH, 16384], msg);
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

psys(key k)
{

     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,GREEN,
                    PSYS_PART_END_COLOR,YELLOW,

                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
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

string getGMTtime(integer vIntLocalOffset)
{
    //-- get the correct time in seconds for the given offset
    integer vIntBaseTime = ((integer)llGetGMTclock() + gIntDay + vIntLocalOffset * gIntHour) % gIntDay;
    string vStrReturn;
    //-- store morning or night and reduce to 12hour format if needed
    if (vIntBaseTime < gInt12Hr)
    {
        vStrReturn = " " + TXT_AM;
    }
    else
    {
        vStrReturn = " " + TXT_PM;
        vIntBaseTime = vIntBaseTime % gInt12Hr;
    }
    //-- get and format minutes
    integer vIntMinutes = (vIntBaseTime % gIntHour) / gIntMinute;
    vStrReturn = (string)vIntMinutes + vStrReturn;
    if (10 > vIntMinutes)
    {
        vStrReturn = "0" + vStrReturn;
    }
    //-- add in the correct hour, force 0 to 12
    if (vIntBaseTime < gIntHour)
    {
        vStrReturn = "12:" + vStrReturn;
    }
    else
    {
        vStrReturn = (string)(vIntBaseTime / gIntHour) + ":" + vStrReturn;
    }
    return vStrReturn;
}

string getDay(integer offset)
{
    integer hours = llGetUnixTime()/3600;
    integer days = (hours + offset)/24;
    integer day_of_week = days%7;
    return llList2String(weekdays, day_of_week);
}

string qsFixPrecision(float input, integer precision)
{
    precision = precision - 7 - (precision < 1);
    if(precision < 0)
        return llGetSubString((string)input, 0, precision);
    return (string)input;
}

// --- STATE DEFAULT -- //

default
{

    on_rez(integer n)
    {
        loadConfig();
        loadLanguage(languageCode);
        saveToDesc();
        llResetScript();
    }

    state_entry()
    {

        if (osRegexIsMatch(llGetObjectName(), "(Update|Rezz)+"))
        {
            string me = llGetScriptName();
            llSetScriptState(me, FALSE);
            llSleep(0.5);
        }
        else
        {
            loadConfig();
            loadLanguage(languageCode);
            weekdays = [TXT_THU, TXT_FRI, TXT_SAT, TXT_SUN, TXT_MON, TXT_TUE, TXT_WED];
            loadStock();
            llMessageLinked(LINK_SET, 1, "LANG_TOPTEN|" +TXT_NAME +"|" +TXT_SCORE +"|" +TXT_TOPTEN +"|", "");
            llMessageLinked(LINK_SET, 1, "LANG_ACTIVITY|"  +TXT_RECENT_ACTIVITY +"|" +TXT_ACTIVITY +"|" +TXT_DETAILS +"|" +TXT_POINTS +"|", "");
            setImage();
            owner = llGetOwner();
            ownKey = llGetKey();
            modeNames = [TXT_EVERYONE, TXT_GROUP, TXT_LOCAL];
            messageScreen(TXT_CLICK_FOR_MENU);
            llListen(FARM_CHANNEL, "", "", "");
            activate();
        }
    }
    
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
            loadStock();
            setImage();
        }

        if (change & CHANGED_REGION_START)
        {
            loadStock();
        }
    }

    touch_start(integer n)
    {
        userToPay = llDetectedKey(0);
        // Owner always allowed!
        if (userToPay != owner)
        {
            // 0=Everyone, 1=Group, 2=Local residents
            if (accessMode != 0)
            {
                if (accessMode == 1)
                {
                    if (llDetectedGroup(0) == FALSE)
                    {
                        llRegionSayTo(userToPay, 0, TXT_GROUP_ONLY);
                        return;
                    }
                }
                else if (osGetAvatarHomeURI(userToPay) != osGetGridHomeURI())
                {
                    llRegionSayTo(userToPay, 0, TXT_LOCAL_ONLY);
                    return;
                }
            }
        }
        // If they get here they are allowed to use the board

        // First check if itt was the navigation buttons touched
        if ((llDetectedLinkNumber(0) == getLinkNum("buttons_display")) && (screenState = "showPrices"))
        {
            if ((screenListOffset + screenCapacity) > llGetListLength(items)) screenListOffset = 0;

            integer face = llDetectedTouchFace(0);
            if (face == 2)
            {
                // go back;
                if (screenListOffset -screenCapacity >=0)  screenListOffset -= screenCapacity; else screenListOffset = 0;
                showPrices();
            }
            else if (face == 4)
            {
                // go forward
                if (screenListOffset +screenCapacity <= llGetListLength(items))  screenListOffset += screenCapacity; else screenListOffset = llGetListLength(items) - screenCapacity;
                showPrices();
            }
            else if (face == 0)
            {
                // Home
                screenListOffset = 0;
                showPrices();
            }
            return;
        }
        // If not, show the menu
        list opts = [];
        screenListOffset = 0;
        status = "";
        if (quinActive == FALSE)
        {
            opts += [TXT_ACTIVATE, TXT_CLOSE];
        }
        else
        {
            opts += [TXT_COINS, TXT_PRICES, TXT_CLOSE, TXT_SELL, TXT_BUY, TXT_POINTS, TXT_LANGUAGE];
        }
        if (userToPay == owner)
        {
             opts += [TXT_OPTIONS, TXT_RESET];
        }
        startListen();
        llDialog(userToPay, TXT_SELECT, opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }

    timer()
    {
        if (status == "waitNewItem")
        {
            llRegionSayTo(userToPay, 0, TXT_NOT_FOUND_INV);
            messageScreen(lookingFor + "\n \n" +TXT_NOT_FOUND_INV);
            status = "";
            llSetTimerEvent(30);
        }
        else
        {
            messageScreen(TXT_CLICK_FOR_MENU);
            checkListen(FALSE);
            llSetTimerEvent(180);
            if (slaveState == 0) llMessageLinked(LINK_SET, 1, "CMD_INIT", PASSWORD);
        }
    }

    dataserver( key id, string m)
    {
        debug("dataserver: " + m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        string cmd = llList2String(tk,0);
        integer i;

        if (llList2String(tk,1) != PASSWORD)
        {
            llRegionSayTo(userToPay, 0, TXT_BAD_PASSWORD);
            return;
        }
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
            messageObj(llList2Key(tk, 2), answer);
            //Send a message to other prim with script
            messageObj(llGetLinkKey(3), "VERSION-CHECK|" + PASSWORD + "|" + llList2String(tk, 2));
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(id) != llGetOwner())
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
            messageObj(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        else
        {
            for (i=0; i < llGetListLength(items); i++)
            {
                if (llToUpper(llList2String(items,i)) == cmd)
                {
                    string stuff =  llGetSubString(lookingFor, 3, llStringLength(lookingFor));
                    psys(NULL_KEY);
                    postMessage("task=sold&data1=" + (string)userToPay + "&data2=Sold_" + " " + stuff + "&data3=" + itemPrice);
                    status = "verifying-soldpnt";
                    return;
                }
            }
        }
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("LISTEN_CHAN="+(string)c +" MSG=" +m +" (status= " +status +")");
        if (m == TXT_CLOSE)
        {
            llListenRemove(listener);
            listener = -1;
            return;
        }
        else if (m == TXT_SELL)
        {
            llSetColor(GREEN, 4);
            status = "SellGoods";
            //userToPay = id;
            postMessage("task=getmenu&data1=" + (string)id +"&data2=" +marketType);
        }
        else if (m == TXT_BUY)
        {
            llSetColor(GREEN, 4);
            status = "BuyGoods";
            //userToPay = id;
            postMessage("task=getmenu&data1=" + (string)id +"&data2=" +marketType);
            return;
        }
        else if (m == TXT_PRICES)
        {
            llSetColor(GREEN, 4);
            llListenRemove(listener);
            listener = -1;
            prices = [];
            status = "priceReq";
            postMessage("task=getmenu&data1=" + (string)id +"&data2=" +marketType);
            return;
        }
        else if (m == TXT_ACTIVATE)
        {
            activate();
        }
        else if (m == TXT_OPTIONS)
        {
            list opts = [TXT_FARM_NAME, TXT_EX_TYPE, TXT_CLOSE, TXT_ACCESS_LEVEL, TXT_OPERATION_MODE];
            startListen();
            string tmpStr = "\n" + TXT_ACCESS_LEVEL +":" + llList2String(modeNames, accessMode) + "\t" + TXT_OPERATION_MODE + ":";
            if (opMode == 1) tmpStr += TXT_ALWAYS_SELL; else tmpStr += TXT_BUY_SELL;
            llDialog(userToPay, "\n" + TXT_SELECT + tmpStr , opts, chan(llGetKey()));
            llSetTimerEvent(300);
        }
        else if (m == TXT_ACCESS_LEVEL)
        {
            list opts = [TXT_EVERYONE, TXT_GROUP, TXT_LOCAL, TXT_CLOSE];
            startListen();
            string tmpStr = "\n" + TXT_ACCESS_LEVEL +":" + llList2String(modeNames, accessMode);
            llDialog(userToPay, "\n" + TXT_SELECT + tmpStr , opts, chan(llGetKey()));
            llSetTimerEvent(300);
        }
        else if (m == TXT_FARM_NAME)
        {
            startListen();
            llTextBox(userToPay, TXT_FARM_NAME, chan(llGetKey()));
            status = "getName";
            llSetTimerEvent(300);
        }
        else if (m == TXT_EX_TYPE)
        {
            list opts = [TXT_GROCERY, TXT_BAZAAR, TXT_CONCESSIONS, TXT_HARDWARE, TXT_CLOSE];
            startListen();
            llDialog(userToPay, "\n" + TXT_SELECT , opts, chan(llGetKey()));
            llSetTimerEvent(300);
        }
        else if (m == TXT_GROCERY)
        {
            exchangeType = "grocery";
            messageScreen(TXT_READY +"...");
            llOwnerSay(TXT_EX_TYPE + ": " + TXT_GROCERY);
        }
        else if (m == TXT_HARDWARE)
        {
            exchangeType = "hardware";
            messageScreen(TXT_READY +"...");
            llOwnerSay(TXT_EX_TYPE + ": " + TXT_HARDWARE);
        }
        else if (m == TXT_CONCESSIONS)
        {
            exchangeType = "concessions";
            messageScreen(TXT_READY +"...");
            llOwnerSay(TXT_EX_TYPE + ": " + TXT_CONCESSIONS);
        }
        else if (m == TXT_BAZAAR)
        {
            exchangeType = "bazaar";
            messageScreen(TXT_READY +"...");
            llOwnerSay(TXT_EX_TYPE + ": " + TXT_BAZAAR);
        }

        else if (m == TXT_EVERYONE)
        {
            accessMode = 0;
            llOwnerSay(TXT_ACCESS_LEVEL + ": " + TXT_EVERYONE);
        }
        else if (m == TXT_GROUP)
        {
            accessMode = 1;
            llOwnerSay(TXT_ACCESS_LEVEL + ": " + TXT_GROUP);
        }
        else if (m == TXT_LOCAL)
        {
            accessMode = 2;
            llOwnerSay(TXT_ACCESS_LEVEL + ": " + TXT_LOCAL);
        }
        else if (m == TXT_OPERATION_MODE)
        {
            list opts = [TXT_ALWAYS_SELL, TXT_BUY_SELL, TXT_CLOSE];
            startListen();
            llDialog(userToPay, "\n" + TXT_SELECT , opts, chan(llGetKey()));
            llSetTimerEvent(300);
        }
        else if (m == TXT_ALWAYS_SELL)
        {
            opMode = 1;
            stockItems = [];
            showPrices();
            llOwnerSay(TXT_OPERATION_MODE + ": " + TXT_ALWAYS_SELL);
        }
        else if (m == TXT_BUY_SELL)
        {
            opMode = 0;
            loadStock();
            showPrices();
            llOwnerSay(TXT_OPERATION_MODE + ": " + TXT_BUY_SELL);
        }
        else if (m == TXT_POINTS)
        {
            llSetColor(GREEN, 4);
            llMessageLinked(LINK_SET, 1, "CMD_CLEAR", "");
            llRegionSayTo(userToPay, 0, TXT_CHECKING_POINTS);loadStock();
            status = "pointsQuery";
            postMessage("task=points&data1=" + (string)id);
            userToPay = id;
        }

        else if (m == TXT_COINS)
        {
            llSetColor(GREEN, 4);
            llRegionSayTo(userToPay, 0, TXT_CHECKING_POINTS);
            status = "coinsQuery";
            postMessage("task=coins&data1=" + (string)id);
            //userToPay = NULL_KEY;
        }

        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (m == ">>")
        {
            startOffset += 10;
            if (status == "SellGoods")
            {
                //if (startOffset >llGetListLength(sellItems)) startOffset=0;
                multiPageMenu(id, TXT_SELL, sellItems);
            }
            else
            {
                //if (startOffset >llGetListLength(items)) startOffset=0;
                multiPageMenu(id, TXT_BUY, items);
            }
        }
        // Run out of buttons, check status
        else if (status == "getName")
        {
            farmName = m;
            status = "";
            messageScreen(TXT_READY +"...");
        }
        else if (status == "SellGoods")
        {
            string what = llGetSubString(m, 4,-1);
            integer idx = llListFindList(items, m);
            if (idx>=0)
            {
                itemPrice  = llList2String(prices, idx);
            //    userToPay = id;
                lookingFor = "SF " + llList2String(items,idx);
                llSensor(lookingFor, "",SCRIPTED,  SENSOR_DISTANCE, PI);
            }
            status = "WaitItem";
        }
        else if (status == "BuyGoods")
        {
            llSetColor(GREEN, 4);
            integer idx = llListFindList(items, m);
            itemPrice = llList2String(prices, idx);
            lookingFor = m;
            // Check they have enough points
            status = "balCheck";
            // postMessage("task=points&data1=" + (string)userToPay);
            postMessage("task=coins&data1=" + (string)userToPay);
            // userToPay = NULL_KEY;
        }
        else if (status == "WaitItem")
        {
            debug("status = WaitItem");
        }
        else
        {
            // FARM_CHANNEL message ?
            list tk = llParseString2List(m, ["|"], []);
            string cmd = llList2String(tk, 0);
            if (llList2String(tk, 1) == PASSWORD)
            {
                if (cmd == "INV_QRY")
                {
                    string object = "SF " + llList2String(tk, 3);
                    if (llGetInventoryType(object) == INVENTORY_OBJECT)
                    {
                        llRegionSay(FARM_CHANNEL, "INV_AVAIL|" +PASSWORD +"|" +(string)ownKey +"|" +object);
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
        saveToDesc();
    }

    sensor(integer n)
    {
        if (lookingFor == "all")
        {
            sellItems = [];
            while (n--)
            {
                string name = llGetSubString(llKey2Name(llDetectedKey(n)), 3, -1);
                if (llListFindList(items, [name]) != -1 && llListFindList(sellItems, [name]) == -1)
                {
                    sellItems += [name];
                }
            }
            if (sellItems == [])
            {
                if (sellItems == [])
                {
                    if (status != "SellGoodsRepeat") llRegionSayTo(userToPay, 0, TXT_NOT_FOUND);
                }
                checkListen(TRUE);
            }
            else
            {
                status = "SellGoods";
                //dlgBuySell(userToPay);
                multiPageMenu(userToPay, TXT_SELL, sellItems);
            }
            return;
        }
        //get first product that isn't already selected and has enough percentage
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (llListFindList(sellItems, [obj]) == -1 && (have_percent == 100 || have_percent == 0))
            {
                ready_obj = llDetectedKey(c);
            }
        }
        if (ready_obj == NULL_KEY)
        {
            llRegionSayTo(userToPay, 0, lookingFor + " " + TXT_NOT_FOUND100);
            return;
        }
        sellItems += [ready_obj];
        llRegionSayTo(userToPay, 0, TXT_FOUND +"  " +lookingFor + ", " + TXT_EMPTYING);
        messageObj(ready_obj, "DIE|"+llGetKey());
    }

    no_sensor()
    {
        if (lookingFor == "all" && sellItems == [])
        {
            if (status != "SellGoodsRepeat") llRegionSayTo(userToPay, 0, TXT_NOT_FOUND);
        }
        else
        {
            llRegionSayTo(userToPay, 0, lookingFor +" " + TXT_NOT_FOUND_ITEM);
        }
        checkListen(TRUE);
    }

    object_rez(key id)
    {
        llSleep(.5);
        messageObj(id, "INIT|"+PASSWORD);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg + " From:" + (string)sender_num);
        list tk = llParseString2List(msg, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "TOPTEN_ERROR")
        {
            if (llGetInventoryType("poster") == INVENTORY_TEXTURE) llSetLinkTexture(3, "poster", FACE); else llSetLinkTexture(3, "cdf521e1-f3d7-4e3b-ab32-34c3b268cba9", FACE);
            slaveState = 0;
        }
        else if (cmd == "TOPTEN_OK")
        {
            slaveState = 1;
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            messageScreen(TXT_READY +"...");
            llMessageLinked(LINK_SET, 1, "LANG|" +TXT_NAME +"|" +TXT_SCORE +"|" +TXT_TOPTEN +"|", "");
            saveToDesc();
            llSleep(0.5);
            llMessageLinked(LINK_SET, 1, "CMD_REFRESH|", "");
        }
        else if (cmd == "PRODUCT_FOUND")
        {
            //status = "";
            llRegionSayTo(userToPay, 0, TXT_NOW_AVAILABLE + ": " +lookingFor);
            showPrices();
            llSetTimerEvent(60.0);
        }
        else if (cmd == "NO_PRODUCT")
        {
            llRegionSayTo(userToPay, 0, TXT_NOT_FOUND_INV);
            messageScreen(lookingFor + "\n \n  " +TXT_NOT_FOUND_INV);
            llSetTimerEvent(60);
        }
    }

    http_response(key request_id, integer HStatus, list metadata, string body)
    {
        debug("http_response - HStatus: "+HStatus +"\nStatus="+status +"opMode:"+(string)opMode +"\nbody: "+body);
        if (request_id == farmHTTP)
        {
            llSetColor(WHITE, 4);
            list tok = llParseStringKeepNulls(body, ["|"], []);
            string cmd = llList2String(tok, 0);

            if (cmd == "DISABLE")
            {
                llRegionSayTo(userToPay, 0, TXT_ERROR_DISABLED);
                llMessageLinked(LINK_SET, 0, "CMD_STOP", "");
                llResetScript();
            }
            else if (cmd == "2017053016xR")
            {
                status = "";
                quinActive = TRUE;
                messageScreen(TXT_CLICK_FOR_MENU);
                llMessageLinked(LINK_SET, 1, "CMD_INIT|" + PASSWORD, "");
                llSleep(2.0);
            }
            else if (cmd == "REJECT")
            {
                llRegionSayTo(userToPay, 0, TXT_INFO_MSG1 + " " +REGURL +"\n");
                status = "";
            }
            else if (cmd == "MENU")
            {
                list data = llParseString2List(llList2String(tok, 1), [";", "\n"], []);
                items = [];
                prices = [];
                integer i;
                integer j = llGetListLength(data);
                for( i = 0; i < j; i = i+2 )
                {
                    items += llList2String(data, i);
                    prices += llList2Integer(data, i+1);
                }
                if (status == "priceReq")
                {
                    status = "";
                    showPrices();
                }
                else if (status == "BuyGoods")
                {
                    if (opMode == 0)
                    {
                        list newItems = [];
                        list newPrices = [];
                        // take out items not in stock
                        integer count = llGetListLength(items);
                        for (i=0; i < count; i++)
                        {
                            if (llListFindList(stockItems, ["SF " +llList2String(items, i)]) != -1)
                            {
                                newItems += [llList2String(items, i)];
                                newPrices += [llList2Integer(prices, i)];
                            }
                        }
                        items = [] + newItems;
                        prices = [] + newPrices;
                    }
                    startOffset = 0;
                    multiPageMenu(userToPay, TXT_BUY, items);
                }
                else
                {
                    startOffset = 0;
                    lookingFor = "all";
                    llSensor("", "", SCRIPTED, SENSOR_DISTANCE, PI);
                }
            }
            else if (cmd == "PLUSQP")
            {
                if (status == "verifying-soldpnt")
                {
                    llRegionSayTo(userToPay, 0, TXT_CREDITED + " " + llList2String(tok,2) + " " + TXT_COINS);
                    llPlaySound("ching", 1.0);
                    llMessageLinked(LINK_SET, 1, "CMD_REFRESH", "");
                    status = "";
                    llRegionSay(FARM_CHANNEL, "COINCHK|" +PASSWORD +"|" +(string)userToPay);
                    if (opMode == 0)
                    {
                        saveStock(lookingFor, CREDIT);
                        setImage();
                    }
                    items = [];
                    checkListen(TRUE);
                    startListen();
                    status = "SellGoodsRepeat";
                    postMessage("task=getmenu&data1=" + (string)userToPay +"&data2=" +marketType);

                }
                else if (status == "verifying-buypnt")
                {
                    // Points deducted okay so give them item    "SF " + lookingFor
                    psys(userToPay);
                    llMessageLinked(LINK_SET, 1, "CMD_REFRESH", "");
                    string what = "SF " + lookingFor;
                    llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)userToPay +"|" +what, NULL_KEY);
                    llRegionSayTo(userToPay, 0, TXT_GIVE_PURCHASE + " " + lookingFor + ".\n" + TXT_CHARGED + " " + itemPrice + " " + TXT_COINS);
                    llPlaySound("ching", 1.0);
                    status = "";
                    if (opMode == 0)
                    {
                        saveStock(what, DEBIT);
                        setImage();
                    }
                    llRegionSay(FARM_CHANNEL, "COINCHK|" +PASSWORD +"|" +(string)userToPay);
                }
            }
            else if ((cmd == "POINTTALLY") || (cmd == "COINTALLY"))
            {
                if (status == "pointsQuery")
                {
                    string tmpStr = TXT_YOU_HAVE + " " + (string)llList2Integer(tok,1) + " " + TXT_POINTS + ", " +TXT_RANK + ": " + llList2String(tok,2);
                    llMessageLinked(LINK_SET, 1, "CMD_SHOW_ACTIVITY|" +tmpStr , userToPay);
                    llRegionSayTo(userToPay, 0, tmpStr);
                }
                else if (status == "coinsQuery")
                {
                    string tmpStr = TXT_YOU_HAVE + " " + (string)llList2Integer(tok,1) +TXT_COIN_SYMBOL;
                    llRegionSayTo(userToPay, 0, tmpStr);
                }
                else if (status == "balCheck")
                {
                    integer pointsBal = llList2Integer(tok,1);
                    integer cost = (integer)itemPrice;
                    if ( (pointsBal - cost)  < 0)
                    {
                        llRegionSayTo(userToPay, 0, TXT_INSUFFICIENT_POINTS);
                    }
                    else
                    {
                        string what = "SF " + lookingFor;
                        if (llGetInventoryType(what) != INVENTORY_OBJECT)
                        {
                            llRegionSayTo(userToPay, 0, TXT_NO_STOCK +" " +lookingFor +"\n" +TXT_CHECKING);
                            llMessageLinked(LINK_SET, 0, "GET_PRODUCT|" +PASSWORD +"|" +what, NULL_KEY);
                            messageScreen(TXT_NO_STOCK +" " +lookingFor +"\n \n  " +TXT_CHECKING);
                            status = "waitNewItem";
                            llSetTimerEvent(15);
                        }
                        else
                        {
                            // Deduct points then give them item if deduct went okay
                            cost = cost * -1;
                            postMessage("task=sold&data1=" + (string)userToPay + "&data2=Bought_" + lookingFor + "&data3=" + (string)cost);
                            status = "verifying-buypnt";
                        }
                    }
                }
            }

            else
            {
              debug(" == "+llList2String(tok,1));
            }
        }
        else
        {
            // Response not for this script
        }
    }

}
