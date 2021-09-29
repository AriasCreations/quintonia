// config_updater-storage.lsl
// Version 1.2   6 May 2021 
// Checks for old script values in notecard and if present updates notecard

// Default values, if not overridden in config notecard
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
string  languageCode = "en-GB";             // LANG=en-GB

string fixedPrecision(float input, integer precision)
{
    precision = precision - 7 - (precision < 1);
    if(precision < 0)
        return llGetSubString((string)input, 0, precision);
    return (string)input;
}

string neatVector(vector input)
{
    string output = "<";
    output += fixedPrecision(input.x, 2) +", ";
    output += fixedPrecision(input.y, 2) +", ";
    output += fixedPrecision(input.z, 2) +">";
    return output;
}

loadConfig()
{
    integer i;
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
    // Check if in old config notecard and if so update 
    string oldCard = osGetNotecard("config");
    if (llGetInventoryType("config-old") == INVENTORY_NOTECARD) llRemoveInventory("config-old");
    llSleep(0.1);
    osMakeNotecard("config-old", oldCard);
    llSleep(0.1);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD) llRemoveInventory("config");
    llSleep(0.1);
    list newContents = [];
    newContents += ["# What level should storage start at when rezzed"];
    newContents += ["INITIAL_LEVEL="+(string)initialLevel+"\n#"];
    newContents += ["# How much is taken/added on use"];
    newContents += ["ONE_PART="+(string)singleLevel+"\n#"];
    newContents += ["# How many days before level drops 1 part"];
    newContents += ["DROP_TIME="+(string)llRound(dropTime/86400)+"\n#"];
    newContents += ["# What is the maximum this store can hold (100 gives stock levels in %, greater than 100 gives levels as e.g.  25/110 )"];
    newContents += ["MAX_FILL="+(string)maxFill+"\n#"];
    newContents += ["# ASC for ascending (A to Z) or DEC for descending (Z to A) sorting"];
    if (SORTDIR == 1) newContents += ["SORTDIR=ASC"+"\n#"]; else newContents += ["SORTDIR=DEC"+"\n#"];
    newContents += ["# Offset to rez item"];
    newContents += ["REZ_POSITION="+neatVector(rezzPosition)+"\n#"];
    newContents += ["# How far to scan for items"];
    newContents += ["SENSOR_DISTANCE="+(string)SENSOR_DISTANCE+"\n#"];
    newContents += ["# Region product share. All shares with everyone,  Group only with same group, None  no sharing"];
    if (shareMode == "all") newContents += ["SHARE_MODE=All"+"\n#"]; else if (shareMode == "group")  newContents+= ["SHARE_MODE=Group"+"\n#"]; else newContents+= ["SHARE_MODE=None"+"\n#"]; 
    newContents += ["# Set to 1 to allow any member of the group to use the 'Add Stock' menu button, 0 to only allow owner"];
    newContents += ["GROUP_STOCK_ADD="+(string)groupAddStock+"\n#"];
    newContents += ["#Float text colour - set as color vector or use  OFF  for no float text"];
    if (TXT_COLOR == ZERO_VECTOR) newContents += ["TXT_COLOR=OFF"+"\n#"]; else newContents += ["TXT_COLOR="+neatVector(TXT_COLOR)+"\n#"];
    newContents += ["# Brightness of text 1 to 10 (10 is maximum brightness)"];
    newContents += ["TXT_BRIGHT="+(string)llRound(10*textBrightness)+"\n#"];
    newContents += ["# If your products start with a different prefix set it here"];
    newContents += ["SF_PREFIX="+SF_PREFIX+"\n#"];
    newContents += ["# Default language"];
    newContents += ["LANG="+languageCode+"\n"];
    osMakeNotecard("config",newContents);
}

default
{
    state_entry()
    {
        // Don't run this in the updater
        if (llGetInventoryType("FARM-UPDATER") != INVENTORY_SCRIPT)
        {
            llOwnerSay("Updating config notecard...");
            // Update the config notecard
            if (llGetInventoryType("config") == INVENTORY_NOTECARD)
            {
                loadConfig();
                llSleep(2.0);
                // All done so can delete this script
                llRemoveInventory(llGetScriptName());
            }
        }
        else
        {
            llSetScriptState(llGetScriptName(), FALSE);
        }
    }

    on_rez( integer start_param)
    {
        llResetScript();
    }

}