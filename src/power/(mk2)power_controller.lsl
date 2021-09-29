
string TXT_SAME_GROUP  = "Both controllers are in the same group";
string TXT_BOTH_OPEN   = "At least one controller needs to have 'ONLY_GROUP=1' in config file";
string TXT_DELETE_LOGS = "Delete logs";

// power_controller.lsl
//  Region-wide power grid controller. Accepts energy from wind turbines and also can receive and give 'kWh' objects. Uses a region-wide channel.

float   VERSION = 5.2;     // Beta  14 December 2020
integer  RSTATE = 0;       // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

vector  rezzPosition = <1,0,0>; // REZ_POS= offset for rezzing items
integer sensorRadius = 10;      // SENSOR_RADIUS=   How far to search (radius) when searching for items to add
integer onePart = 1;            // ONE_PART=        How much 1 unit of energy is
integer dropTime = 0;           // DROP_TIME=        How often in days the stored energy drops by (ONE_PART/10)
float   energy = 0.0;           // INITIAL_LEVEL=   How much kWh to start with on rez
integer maxEnergy = 2000;       // MAX_ENERGY=      Maximum  storage capacity for the region in kWh
integer minLevel = 1;           // MIN_LEVEL=       Below this level, the controller won't allow avatars to take SF kWh directly from it.
string  name = "";              // NAME=            If specified use this name rather than region name on the controller display
integer logging = 1;            // logging=1        Set to 0 to disable logging
string  SF_KWH = "SF kWh";      // SF_KWH=SF kWh    Name of energy product to rez (must be in objects inventory)
string  languageCode = "en-GB"; // LANG=en-GB

// For multilingual support
string    TXT_INIT="Initialising...";
string    TXT_WAITING="Waiting";
string    TXT_ZERO_ENERGY="Energy reserves at zero";
string    TXT_MAX_ENERGY="Energy reserves at max. capacity";
string    TXT_NO_ENERGY="Sorry, not enough energy reserves at present";
string    TXT_HEADING="Energy Controller";
string    TXT_GENERATED="Energy generated:";
string    TXT_CONSUMED="Energy consumed:";
string    TXT_TOTAL_ENERGY="Total Energy reserves";
string    TXT_TOTAL_KWH="Total kWh";
string    TXT_KWH="kWh";
string    TXT_MWH="MWh";
string    TXT_ADD="Add kWh";
string    TXT_GET="Get kWh";
string    TXT_CLOSE="CLOSE";
string    TXT_RESET="RESET";
string    TXT_PREVIOUS="< PREV";
string    TXT_NAME="Name";
string    TXT_NEXT="NEXT >";
string    TXT_DONE ="DONE";
string    TXT_SHOW_LOG="Show log";
string    TXT_ZERO_STATS="Zero stats";
string    TXT_RESETTING_STATS="Resetting statistics";
string    TXT_SELECT="Select";
string    TXT_STATUS_ACTIVE="ACTIVE";
string    TXT_FOUND_ENERGY="Found kWh, absorbing...";
string    TXT_MONTH_STATS="Statistics for the month";
string    TXT_TOTAL_CONSUMERS="Total consumer requests";
string    TXT_UNIQUE_LOCS="Unique locations";
string    TXT_OFFLINE="OFFLINE";
string    TXT_MASTER="Master controller found";
//
string    TXT_LOG_ENABLE="Enable logs";
string    TXT_LOG_DISABLE="Disable logs";

// Three letter abbreviations for days of week
string    TXT_DAYS="Days";
string    TXT_SUN="Sun";
string    TXT_MON="Mon";
string    TXT_TUE="Tue";
string    TXT_WED="Wed";
string    TXT_THU="Thu";
string    TXT_FRI="Fri";
string    TXT_SAT="Sat";
// Months
string    TXT_MONTHS="months";
string    TXT_JANUARY="January";
string    TXT_FEBRUARY="February";
string    TXT_MARCH="March";
string    TXT_APRIL="April";
string    TXT_MAY="May";
string    TXT_JUNE="June";
string    TXT_JULY="July";
string    TXT_AUGUST="August";
string    TXT_SEPTEMBER="September";
string    TXT_OCTOBER="October";
string    TXT_NOVEMBER="November";
string    TXT_DECEMBER="December";
//
string    TXT_ERROR_NOTFOUND="ERROR: could not find that card....rebuilding card list";
string    TXT_ERROR_NO_ENERGY="Error! Energy not found nearby.";
string    TXT_BAD_PASSWORD="Bad password";
string    TXT_ERROR_GROUP="Error, we are not in the same group";
string    TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string    TXT_LANGUAGE="@";
//
string SUFFIX = "C4";
//
integer face = 4;
string  fontName = "Courier New";   
integer fontSize = 14;          
string  logScript = "power_controller_log";
list    generators;       // [(string)description, (integer)current_efficiency%, (integer)avg%, (integer)total_energykWh, (key)uuid]
integer energyGenerated;
integer energyConsumed;
string  regionName;
string  statusMessage;
integer energy_channel = -321321;
string  PASSWORD="*";
integer lastTs;
integer lastRefresh;
string  status;
integer dataToggle;
key     owner;
key     myGroup;
integer master = FALSE;  // We will check on startup to confirm no other controllers exist
key     theMaster;       // Holds the uuid of the regions master power controller

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
                    PSYS_SRC_TEXTURE,"img",
                    PSYS_SRC_MAX_AGE,30,
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

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

integer checkAllowed(key keyCheck)
{
    key theirGroup = llList2Key(llGetObjectDetails(keyCheck, [OBJECT_GROUP]), 0);
    if (theirGroup == myGroup) return TRUE; else return FALSE;
}

loadConfig()
{
    PASSWORD = osGetNotecardLine("sfp", 0);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                if      (cmd == "SENSOR_DISTANCE") sensorRadius = (integer)val;
                else if (cmd == "REZ_POSITION")    rezzPosition = (vector)val;
                else if (cmd == "INITIAL_LEVEL")   energy = (float)val;
                else if (cmd == "ONE_PART")        onePart = (integer)val;
                else if (cmd == "DROP_TIME")       dropTime = (integer)val * 86400;
                else if (cmd == "MAX_ENERGY")      maxEnergy = (integer)val;
                else if (cmd == "MIN_LEVEL")       minLevel = (integer)val;
                else if (cmd == "NAME")            name = val;
                else if (cmd == "LOGGING")         logging = (integer)val;
                else if (cmd == "SF_KWH")          SF_KWH = val;
                else if (cmd == "LANG")            languageCode = val;
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
                         if (cmd == "TXT_INIT") TXT_INIT  = val;
                    else if (cmd == "TXT_WAITING") TXT_WAITING = val;
                    else if (cmd == "TXT_ZERO_ENERGY") TXT_ZERO_ENERGY  = val;
                    else if (cmd == "TXT_MAX_ENERGY")  TXT_MAX_ENERGY = val;
                    else if (cmd == "TXT_NO_ENERGY")  TXT_NO_ENERGY = val;
                    else if (cmd == "TXT_HEADING") TXT_HEADING = val;
                    else if (cmd == "TXT_GENERATED") TXT_GENERATED = val;
                    else if (cmd == "TXT_CONSUMED") TXT_CONSUMED = val;
                    else if (cmd == "TXT_TOTAL_ENERGY") TXT_TOTAL_ENERGY = val;
                    else if (cmd == "TXT_TOTAL_KWH") TXT_TOTAL_KWH = val;
                    else if (cmd == "TXT_KWH") TXT_KWH = val;
                    else if (cmd == "TXT_MWH") TXT_MWH = val;
                    else if (cmd == "TXT_NAME") TXT_NAME = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_GET") TXT_GET = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_RESET") TXT_RESET = val;
                    else if (cmd == "TXT_PREVIOUS") TXT_PREVIOUS = val;
                    else if (cmd == "TXT_NEXT") TXT_NEXT = val;
                    else if (cmd == "TXT_DONE") TXT_DONE = val;
                    else if (cmd == "TXT_SHOW_LOG") TXT_SHOW_LOG = val;
                    else if (cmd == "TXT_LOG_DISABLE") TXT_LOG_DISABLE = val;
                    else if (cmd == "TXT_LOG_ENABLE") TXT_LOG_ENABLE = val;
                    else if (cmd == "TXT_DELETE_LOGS") TXT_DELETE_LOGS = val;
                    else if (cmd == "TXT_ZERO_STATS") TXT_ZERO_STATS = val;
                    else if (cmd == "TXT_RESETTING_STATS") TXT_RESETTING_STATS = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_STATUS_ACTIVE") TXT_STATUS_ACTIVE = val;
                    else if (cmd == "TXT_FOUND_ENERGY") TXT_FOUND_ENERGY = val;
                    else if (cmd == "TXT_MONTH_STATS") TXT_MONTH_STATS = val;
                    else if (cmd == "TXT_TOTAL_CONSUMERS") TXT_TOTAL_CONSUMERS = val;
                    else if (cmd == "TXT_UNIQUE_LOCS") TXT_UNIQUE_LOCS = val;
                    else if (cmd == "TXT_OFFLINE") TXT_OFFLINE = val;
                    else if (cmd == "TXT_MASTER") TXT_MASTER = val;
                    else if (cmd == "TXT_DAYS")  TXT_DAYS = val;
                    else if (cmd == "TXT_SUN") TXT_SUN = val;
                    else if (cmd == "TXT_MON") TXT_MON = val;
                    else if (cmd == "TXT_TUE") TXT_TUE = val;
                    else if (cmd == "TXT_WED") TXT_WED = val;
                    else if (cmd == "TXT_THU") TXT_THU = val;
                    else if (cmd == "TXT_FRI") TXT_FRI = val;
                    else if (cmd == "TXT_SAT") TXT_SAT = val;
                    else if (cmd == "TXT_MONTHS") TXT_MONTHS = val;
                    else if (cmd == "TXT_JANUARY") TXT_JANUARY = val;
                    else if (cmd == "TXT_FEBRUARY") TXT_FEBRUARY = val;
                    else if (cmd == "TXT_MARCH") TXT_MARCH = val;
                    else if (cmd == "TXT_APRIL") TXT_APRIL = val;
                    else if (cmd == "TXT_MAY") TXT_MAY = val;
                    else if (cmd == "TXT_JUNE") TXT_JUNE = val;
                    else if (cmd == "TXT_JULY") TXT_JULY = val;
                    else if (cmd == "TXT_AUGUST") TXT_AUGUST = val;
                    else if (cmd == "TXT_SEPTEMBER") TXT_SEPTEMBER = val;
                    else if (cmd == "TXT_OCTOBER") TXT_OCTOBER = val;
                    else if (cmd == "TXT_NOVEMBER") TXT_NOVEMBER = val;
                    else if (cmd == "TXT_DECEMBER") TXT_DECEMBER = val;
                    else if (cmd == "TXT_ERROR_NOTFOUND") TXT_ERROR_NOTFOUND = val;
                    else if (cmd == "TXT_ERROR_NO_ENERGY") TXT_ERROR_NO_ENERGY = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_SAME_GROUP") TXT_SAME_GROUP = val;
                    else if (cmd == "TXT_BOTH_OPEN") TXT_BOTH_OPEN = val;
                    else if (cmd == "LANG") languageCode = val;
                }
            }
        }
    }
}

saveStateToDesc()
{
    string codedDesc = "E;"+(string)energyGenerated+";"+(string)energyConsumed+";"+(string)llRound(energy)+";"+ (string)logging +";" +(string)languageCode;
    llSetObjectDesc(codedDesc);
}

loadStateByDesc()
{
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "E")
    {
        energyGenerated = llList2Integer(desc, 1);
        energyConsumed  = llList2Integer(desc, 2);
        energy          = llList2Float(desc, 3);
        logging         = llList2Integer(desc, 4);
        languageCode    = llList2String(desc, 5);
    }
    else
    {
        saveStateToDesc();
    }
}

string fixedPrecision(float input, integer precision)
{
    precision = precision - 7 - (precision < 1);
    if(precision < 0)
        return llGetSubString((string)input, 0, precision);
    return (string)input;
}

string fixedStrLen(string value, integer length)
{
    string returnStr = value;

    while (llStringLength(returnStr) < length)
    {
        returnStr = " " + returnStr;
    }
    if (llStringLength(returnStr) > length)
    {
        returnStr = llGetSubString(value, 0, length-1);
    }
    return returnStr;
}

string neatVector(vector input)
{
    string output = "<";
    output += fixedPrecision(input.x, 2) +", ";
    output += fixedPrecision(input.y, 2) +", ";
    output += fixedPrecision(input.z, 2) +">";
    return output;
}

setStatusMsg(string msg)
{
    if (name == "") statusMessage = regionName + msg; else statusMessage = name + msg;
}

displayData(integer forceUpdate)
{
    // Only update display around every 2 minutes
    integer ts = llGetUnixTime();
    if (((ts - lastRefresh) > 120) || (forceUpdate == TRUE))
    {
        lastRefresh = ts;
        string body = "width:512,height:512,aplha:FALSE,bgcolour:darkslategray";    
        string draw = "";  // Storage for our drawing commands
        string tmpStr = "";
        // Draw horizontal line 1
        draw = osSetPenSize(draw, 6);
        draw = osSetPenColor(draw, "gray" );
        draw = osDrawLine(draw, 6, 35, 510, 35);
        // Draw horizontal line 2
        draw = osSetPenSize(draw, 2 );
        draw = osSetPenColor(draw, "gray" );
        draw = osDrawLine(draw, 6, 70, 510, 70);
        // Draw a border
        draw = osSetPenSize(draw, 9);
        if (status == "wait1ping")
        {
            draw = osSetPenColor(draw, "mediumpurple");
            setStatusMsg(" - " + TXT_INIT + "...");
        }
        else if (energy > 0.0)
        {
            draw = osSetPenColor(draw, "darkcyan");
        }
        else
        {
            draw = osSetPenColor(draw, "brown");
            if (energy <= 0) setStatusMsg(" - " + TXT_ZERO_ENERGY);
        }
        draw = osMovePen(draw, 1,1);
        draw = osDrawRectangle(draw, 510,500);
        // Status message on first line
        draw = osSetFontName(draw, fontName);
        draw = osSetFontSize(draw, fontSize);
        draw = osMovePen(draw, 7, 8);
        draw = osSetPenColor(draw, "bisque");
        draw = osDrawText(draw, statusMessage + "\n");
        // Stats box text
        string statusText = TXT_NAME + "\t \t \t%\tavg%\t" + TXT_TOTAL_KWH + "\n \n";
        integer i = 0;
        for (0; i < llGetListLength(generators); i = i+5)
        {
            if (llList2Key(generators, i+4) != NULL_KEY)
            {
                statusText += fixedStrLen(llList2String(generators, i), 12) + "\t" + fixedStrLen(llList2String(generators, i+1), 3) + "\t" + fixedStrLen(llList2String(generators, i+2), 3) + "\t  " + fixedStrLen(llList2String(generators, i+3), 3) + "\n";
            }
        }
        i = llListFindList(generators, [NULL_KEY]);
        if (i != -1)
        {
           statusText += "\n" + fixedStrLen(SF_KWH, 12) + "\t  -\t  -\t  " +fixedStrLen(llList2String(generators, i-1), 3) + "\n";
        }
        draw = osMovePen(draw, 6, 45);
        draw = osSetPenColor(draw, "white");
        draw = osDrawText(draw, statusText);
        // Totals text
        statusText = "\n\n"  + TXT_GENERATED    + "\t" + fixedStrLen((string)energyGenerated, 3) + " " + TXT_KWH;
        statusText += "\n "  + TXT_CONSUMED     + "\t" + fixedStrLen((string)energyConsumed, 3)  + " " + TXT_KWH;
        statusText += "\n\n" + TXT_TOTAL_ENERGY + " ";
        if (master == TRUE)
        {
            if (RSTATE == 0) tmpStr = "\n-B-"; else if (RSTATE == -1) tmpStr += "\n-RC-";
            if (energy <1000)
            {
                statusText += fixedPrecision((string)energy, 1) + " " + TXT_KWH + "\n";
                llSetText(TXT_HEADING + "\n" + TXT_TOTAL_ENERGY + " " + fixedPrecision((string)energy, 1) + " " + TXT_KWH + "\n" +tmpStr, <1,1,1>, 1.0);
            }
            else
            {
                statusText += fixedPrecision((string)(energy/1000), 2) + " " + TXT_MWH + "\n";
                llSetText(TXT_HEADING + "\n" + TXT_TOTAL_ENERGY + " " + fixedPrecision((string)(energy/1000), 2)  + " " + TXT_MWH  + "\n" +tmpStr, <1,1,1>, 1.0);
            }
        }
        draw = osMovePen(draw, 20, 380);
        draw = osSetFontSize(draw, fontSize+1);
        draw = osDrawText(draw, statusText);
        // Put it all onto the display screen
        osSetDynamicTextureDataBlendFace("", "vector", draw, body, TRUE, 2, 0, 255, face);
    }
    saveStateToDesc();
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

refresh()
{
    if ( llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == myGroup)
    {
        if (dropTime != 0)
        {
            integer ts = llGetUnixTime();
            if (ts - lastTs > dropTime)
            {
                energy -= (onePart/10);
                if (energy < 0) energy = 0;
                lastTs = ts;
                energyConsumed += (onePart/10);
                displayData(1);
            }
            else
            {
                displayData(0);
            }
        }
    }
    else
    {
        llResetScript();
    }
}


default
{

    state_entry()
    {
        llSetClickAction(CLICK_ACTION_NONE);
        llSetText("",ZERO_VECTOR,0);
        llSetColor(<1,1,1>, face);
        if (llGetInventoryType(logScript) != INVENTORY_SCRIPT) logging = FALSE;
        energyGenerated = 0;
        energyConsumed = 0;
        owner = llGetOwner();
        regionName = llGetRegionName();
        myGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0);
        loadConfig();
        loadLanguage(languageCode);
        loadStateByDesc();
        // create an entry to store energy added/taken as 'SF kWh' objects
        generators = [] + ["ZZZ999", 0, 0, 0, NULL_KEY];
        llListen(energy_channel, "", "", "");
        lastTs = llGetUnixTime();
        lastRefresh = lastTs;
        status = "wait1ping";
        displayData(1);
        llRegionSay(energy_channel, "PING|" +PASSWORD);
        setStatusMsg("");
        llMessageLinked(LINK_SET, logging, "INIT|"+PASSWORD+"|"+statusMessage, "");
        llMessageLinked(LINK_SET, 1, "OFFLINE", "");
        llSetTimerEvent(5);
    }

    on_rez(integer n)
    {
        llSetObjectDesc("---");
        llSetColor(<1,0,0>, face);
        llMessageLinked(LINK_SET, 1, "LOG_RESET", "");
        llSleep(1.0);
        llResetScript();
    }

    timer()
    {
        if (status == "wait1ping")
        {
            status = "wait2ping";
            llSetTimerEvent(4);
            displayData(0);
        }
        else if (status == "wait2ping")
        {
            status = "wait3ping";
            llSetTimerEvent(4);
        }
        else if (status == "wait3ping")
        {
            // timed out waiting for reply to our ping so we must be only active controller
            master = TRUE;
            status ="";
            setStatusMsg(" ^ " + TXT_WAITING + " ^ ");
            llSetClickAction(CLICK_ACTION_TOUCH);
            refresh();
            displayData(1);
            llSetTimerEvent(900);
        }
        else
        {
            refresh();
            checkListen();
        }
    }

    touch_start(integer n)
    {
        if (master == TRUE)
        {
            if (llSameGroup(llDetectedKey(0)))
            {
                startListen();
                list opts = [];
                if (llDetectedKey(0) == owner)
                {
                    if (logging == TRUE) opts += [TXT_RESET, TXT_DELETE_LOGS, TXT_CLOSE, TXT_SHOW_LOG, TXT_ZERO_STATS]; else opts += [TXT_LOG_ENABLE];
                    opts += [TXT_LOG_DISABLE];
                    if (energy < maxEnergy) opts += TXT_ADD;
                    if (energy>minLevel) opts += TXT_GET;
                    opts += [TXT_LANGUAGE];
                }
                else
                {
                    if (energy < maxEnergy) opts += TXT_ADD;
                    if (energy>minLevel) opts += TXT_GET;
                    opts += [TXT_LANGUAGE, TXT_CLOSE];
                }
                llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
                llSetTimerEvent(300);
            }
            else
            {
                llRegionSayTo(llDetectedKey(0), 0, TXT_ERROR_GROUP);
            }
        }
        else
        {
            if (llDetectedKey(0) == owner)
            {
                startListen();
                list opts = [TXT_CLOSE, TXT_RESET];
                llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
                llSetTimerEvent(300);
            }
        }
    }

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|"+PASSWORD);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == energy_channel)
        {
            debug("energy-listen:" +message +" MasterMode="+(string)master);
             // Ignore commands if we are not in master mode or in a different group
            if ((master == TRUE) && (checkAllowed(id) == TRUE))
            {
                list tk = llParseStringKeepNulls(message, ["|"] , []);
                string cmd = llList2String(tk,0);
                if (llList2String(tk,1) == PASSWORD)
                {
                    // Do fx showing data activity
                    dataToggle = !dataToggle;
                    llMessageLinked(LINK_SET, dataToggle, "DATAPULSE", "");
                    //
                    if (cmd == "PING")
                    {
                        // A ping from another controller - if they are the same group as us and we are already master, they must be backup
                        if (llSameGroup(llList2Key(llGetObjectDetails(id, [OBJECT_GROUP]), 0)) == TRUE)
                        {
                            if (master == TRUE)
                            {
                                messageObj(id, "PONG|" + PASSWORD +"|0");
                                theMaster = llGetKey();
                            }
                        }
                    }
                    else if (cmd == "ADDENERGY") // Add energy from generators
                    {
                        if (checkAllowed(id) == TRUE)
                        {
                            integer index;
                            integer genEnergy;
                            integer newValue;
                            if ((energy + onePart) <= maxEnergy)
                            {
                                energy += onePart;
                                energyGenerated += onePart;
                                index = llListFindList(generators, [id]);
                                if (index != -1)
                                {
                                    // Add to energy generated tally
                                    genEnergy = llList2Integer(generators, index-1) + onePart;
                                    // Log updated energy tally for this generator
                                    generators = llListReplaceList(generators, [genEnergy], index-1, index-1);
                                }
                                else
                                {
                                    // If we get here, generator must be an intermittent source
                                    // so add energy from the 'SF kWh' object to our tally slot
                                    index = llListFindList(generators, [NULL_KEY]);
                                    if (index != -1)
                                    {
                                        newValue = llList2Integer(generators, index-1);
                                        newValue += onePart;
                                        generators = llListReplaceList(generators, [newValue], index-1, index-1);
                                    }
                                }
                                setStatusMsg(" - " + TXT_STATUS_ACTIVE);
                            }
                            else
                            {
                                setStatusMsg(" - " + TXT_MAX_ENERGY);
                            }
                            displayData(1);
                        }
                    }
                    else if (cmd == "GIVEENERGY")  // Give energy to consumers
                    {
                        if (checkAllowed(id) == TRUE)
                        {
                            if (energy - onePart >= 0)
                            {
                                energy -= onePart;
                                if (energy <0 ) energy =0; else setStatusMsg(" - " + TXT_STATUS_ACTIVE);
                                energyConsumed += onePart;
                                messageObj(id, "HAVEENERGY|"+PASSWORD);
                                psys(id);
                                if (logging == TRUE) llMessageLinked(LINK_THIS, 1, "LOG_CONSUMER", id);
                            }
                            else
                            {
                                messageObj(id, "NOENERGY|"+PASSWORD);
                            }
                            displayData(1);
                        }
                    }
                    else if (cmd == "ENERGYSTATS")
                    {
                        if (checkAllowed(id) == TRUE)
                        {
                            //  ENERGYSTATS|PASSWORD|llGetObjectDesc()|(string)effi
                            integer index = llListFindList(generators, [id]);
                            if (index == -1)
                            {
                                // new generator so add to statistics log   [(string)description, (integer)current_efficiency%, (integer)avg%, (integer)total_energykWh, (key)uuid]
                                generators = generators + [llList2String(tk, 2), llList2Integer(tk, 3), llList2Integer(tk, 3), 0, id];
                            }
                            else
                            {
                                index -= 4;
                                // Get and store current efficiency value
                                integer currentEfi = llList2Integer(tk, 3);
                                generators = llListReplaceList(generators, [currentEfi], index+1, index+1);
                                // Work out 2 point rolling average
                                //  New average = (old average * 0.5) + (new value * 0.5)
                                float newAverage = llList2Integer(generators, index+2) * 0.5;
                                newAverage += (currentEfi * 0.5);
                                // Update the stat for this generator
                                generators = llListReplaceList(generators, [(integer)newAverage], index+2, index+2);
                            }
                            // Sort list by description
                            generators = [] + llListSort(generators,5,TRUE);
                            setStatusMsg(" - ACTIVE");
                            displayData(0);
                        }
                    }
                }
            }
        }
        else    // dialog message
        {
            if (message == TXT_ADD)
            {
                status = "WaitItem";
                llSensor(SF_KWH, "",SCRIPTED,  sensorRadius, PI);
            }
            else if (message == TXT_GET)
            {
                if ( energy-onePart >= 0)
                {
                    energy -= onePart;
                    energyConsumed += onePart;
                    llRezObject(llGetInventoryName(INVENTORY_OBJECT,0), llGetPos() + rezzPosition*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                    setStatusMsg(" - " + TXT_STATUS_ACTIVE);
                }
                else
                {
                    llRegionSayTo(id, 0, TXT_NO_ENERGY);
                }
                displayData(1);
            }
            else if (message == TXT_ZERO_STATS)
            {
                llRegionSayTo(id, 0, TXT_RESETTING_STATS);
                generators = [];
                setStatusMsg(" - " + TXT_STATUS_ACTIVE);
                displayData(1);
            }
            else if (message == TXT_SHOW_LOG)
            {
                llMessageLinked(LINK_THIS, 1, "SHOW_LOG", id);
            }
            else if (message == TXT_DELETE_LOGS)
            {
                llMessageLinked(LINK_THIS, 1, "DEL_LOG", id);
            }
            else if (message == TXT_LOG_DISABLE)
            {
                logging = FALSE;
                llMessageLinked(LINK_SET, logging, "LOGSET", "");
            }
            else if (message == TXT_LOG_ENABLE)
            {
                logging = TRUE;
                llMessageLinked(LINK_SET, logging, "LOGSET", "");
            }
            else if (message == TXT_LANGUAGE)
            {
                llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
            }
            else if(message == TXT_RESET)
            {
                energyConsumed = 0;
                energyGenerated = 0;
                saveStateToDesc();
                llResetScript();
            }
        }
        saveStateToDesc();
    }

    sensor(integer n)
    {
        if ( status == "WaitItem")
        {
            key id = llDetectedKey(0);
            if ((energy + onePart) <= maxEnergy)
            {
                psys(id);
                llSay(0, TXT_FOUND_ENERGY);
                messageObj(id, "DIE|"+(string)llGetKey());
            }
            else
            {
                setStatusMsg(" - " + TXT_MAX_ENERGY);
            }
            displayData(1);
        }
    }

    no_sensor()
    {
        if (status == "WaitItem") llSay(0, TXT_ERROR_NO_ENERGY);
    }

    dataserver(key k, string m)
    {
        debug("dataserver:" +m);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(tk,1) == PASSWORD)
        {
            string cmd = llList2String(tk,0);
            if (cmd == "KWH" ) // Add enegy from the 'SF kWh' product
            {
                if ((energy + onePart) <= maxEnergy)
                {
                    energy += onePart;
                    energyGenerated += onePart;
                    // add energy from the 'SF kWh' object to our tally slot
                    integer index = llListFindList(generators, [NULL_KEY]);
                    if (index != -1)
                    {
                        integer newValue = llList2Integer(generators, index-1);
                        newValue += onePart;
                        generators = llListReplaceList(generators, [newValue], index-1, index-1);
                    }
                    statusMessage = regionName + " - " + TXT_STATUS_ACTIVE;
                }
                else
                {
                    statusMessage = regionName + " - " + TXT_MAX_ENERGY;
                }
                displayData(1);

            }
            else if (cmd == "GIVEWATER")  // Give 'SF kWh' to avatar
            {
                if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == llList2Key(llGetObjectDetails(llList2Key(cmd, 2), [OBJECT_GROUP]), 0))
                {
                    if (energy-onePart > 0)
                    {
                        energy -= onePart;
                        if (energy<0) energy =0;
                        energyConsumed += onePart;
                        messageObj(llList2Key(tk, 2),  "HAVEWATER|"+PASSWORD);
                        psys(llList2Key(tk, 2));
                        statusMessage = regionName + " - " + TXT_STATUS_ACTIVE;
                    }
                    else
                    {
                        statusMessage = regionName + " - " + TXT_ZERO_ENERGY;
                    }
                    displayData(1);
                }
                else llOwnerSay(TXT_ERROR_GROUP + " " +(llList2String(tk, 2)) );
            }
            else if (cmd == "PONG")
            {
                // a pong from another controller so we have to be a backup
                theMaster = k;
                string reason;
                if (llList2Integer(tk, 2) == 0) reason = TXT_SAME_GROUP; else reason = TXT_BOTH_OPEN;
                reason = TXT_MASTER +" @ " +neatVector(llList2Vector(llGetObjectDetails(k, [OBJECT_POS]),0)) +"\n \n " +reason;
                llOwnerSay(reason);
                llSetText(reason, <1,0,0>, 1.0);
                llSetColor(<1,0,0>, face);
                state backup;
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
                    if (item == me)
                    {
                        delSelf = TRUE;
                    }
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
    }

    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            displayData(1);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
            displayData(0);
        }
    }

}


//// STATE BACKUP \\\\

state backup
{
    state_entry()
    {
        status = "BACKUP-MODE";
        llMessageLinked(LINK_SET, 0, "OFFLINE", "");
        setStatusMsg(" : " + TXT_OFFLINE);
        displayData(1);
        llSetTimerEvent(300);
    }

    touch_start(integer num)
    {
        if (llDetectedKey(0) == owner)
        {
            llOwnerSay(TXT_INIT);
            llResetScript();
        }
        else
        {
            llRegionSayTo(llDetectedKey(0), 0, TXT_ERROR_UPDATE);
        }
    }

    timer()
    {
        llResetScript();
    }

}
