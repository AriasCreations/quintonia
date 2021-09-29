// config_updater-plant.lsl
// Version 1.0   15 December 2020 
// Checks for old script values in notecard and if present updates notecard

// default variables that get set in config notecard
float LIFETIME = 172800.0;                  // LIFEDAYS=3                                 days in growing period. Plant spends LIFEDAYS/3 time in 'New' so total days to be ripe is LIFEDAYS*1.3)
float WATER_TIMES = 2.0;                    // WATER_TIMES=2                              how many times to water the plant during the growing phase
integer AUTOREPLANT=0;                      // AUTOREPLANT                                if 1, will auto plant same again when harvested
list BY_PRODUCTS = [];                      // BY_PRODUCTS=Leaves,Twigs,Branches,Logs      Products produced during growing cycle. Can use as well as or instead of 'WOOD' settings
list BY_PRODUCT_TIMES = [];                 // BY_PRODUCT_TIMES=4,3,2,1                    how many times to give by-product during the growing phase
integer HAS_WOOD = 0;                       // HAS_WOOD=0                                 whether this plant gives a wood product. If yes, the product must be in the contents
float WOOD_TIMES = 2.0;                     // WOOD_TIMES=2                               how many times to give wood during the growing phase
string WOOD_OBJECT = "Wood";                // WOOD_OBJECT=Wood                           Short name of 'wood' product
list PLANTS = [];                           // PLANTLIST=Orange Tree,Apple Tree etc       Short names names of supported plants, separated with comma
list PRODUCTS = [];                         // PRODUCTLIST=SF Oranges,SF Apples etc       Full names of products each plant rezzes
vector  rezzPosition = <0.0, 1.5, 2.0>;     // REZ_POSITION=<0.0, 1.5, 2.0>               where to rez harvested item
integer doReset = 1;                        // RESET_ON_REZ=1                             if 1 will do hard reset on rez
integer floatText = TRUE;                   // FLOAT_TEXT=1                               set to 0 to not show the status float text
integer plantPrims = FALSE;                 // PLANT_PRIMS=0                              set to 1 to use prims rather than texture for the stages of plant growth
integer growPrims = FALSE;                  // GROW_PRIMS=0                               if PLANT_PRIMS = 1, set this to 1 to increase the size of the prim as the plant grows
integer scaleFactor = 50;                   // SCALE=50                                   For primplants
string  SF_WATER_TOWER = "SF Water Tower";  // WELL=SF Water Tower                        Full name of place to get water in auto water mode
string  SF_WATER="Water";                   // WATER_OBJECT=Water                         Short name of water product to accept for manual watering
string  SF_MANURE="Manure";                 // MANURE_OBJECT=Manure                       Short name of product to accept as manure
string  SF_COMPOSTABLE="Compostable";       // COMPOSTABLE_OBJECT                         Short name of product to give as compostable product
string  SF_PREFIX = "SF";                   // SF_PREFIX=SF                               If your products start with a different prefix set it here
string  languageCode = "en-GB";             // LANG=en-GB

loadConfig()
{
    string line;
    string cmd;
    string val;
    integer index;
    list tok;
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer count = llGetListLength(lines);
    for (index = 0; index < count; index++)
    {
        line = llList2String(lines, index);
        if (llGetSubString(line, 0, 0) != "#")
        {
            tok = llParseString2List(line, ["="], []);
            if (llList2String(tok,1) != "")
            {
                cmd = llStringTrim(llList2String(tok, 0), STRING_TRIM);
                val = llStringTrim(llList2String(tok, 1), STRING_TRIM);

                     if (cmd == "HAS_WOOD")       HAS_WOOD= (integer)val;
                else if (cmd == "LIFEDAYS")       LIFETIME= 86400.*(float)val;
                else if (cmd == "WATER_TIMES")    WATER_TIMES = (float)val;
                else if (cmd == "AUTOREPLANT")    AUTOREPLANT = (integer)val;
                else if (cmd == "WOOD_TIMES")     WOOD_TIMES  = (float)val;
                else if (cmd == "RESET_ON_REZ")   doReset = (integer)val;
                else if (cmd == "REZ_POSITION")   rezzPosition = (vector)val;
                else if (cmd == "FLOAT_TEXT")     floatText = (integer)val;
                else if (cmd == "PLANT_PRIMS")    plantPrims = (integer)val;
                else if (cmd == "GROW_PRIMS")     growPrims = (integer)val;
                else if (cmd == "WOOD_OBJECT")    WOOD_OBJECT = val;
                else if (cmd == "WELL")           SF_WATER_TOWER = val;
                else if (cmd == "WATER_OBJECT")   SF_WATER = val;
                else if (cmd == "MANURE_OBJECT")  SF_MANURE = val;
                else if (cmd == "SF_COMPOSTABLE") SF_COMPOSTABLE = val;
                else if (cmd == "SF_PREFIX")      SF_PREFIX = val;
                else if (cmd == "LANG")           languageCode = val;
                else if (cmd == "PLANTLIST")
                {
                    PLANTS = llParseString2List(val, [","], []);
                }
                else if (cmd == "PRODUCTLIST")
                {
                    PRODUCTS = llParseString2List(val, [","], []);
                }
                else if (cmd == "BY_PRODUCTS")
                {
                    BY_PRODUCTS = llParseString2List(val, [","], []);
                }
                else if (cmd == "BY_PRODUCT_TIMES")
                {
                    BY_PRODUCT_TIMES = llParseString2List(val, [","], []);
                }
            }
        }
    }
    // Check if old config notecard and if so update
    SF_PREFIX = SF_PREFIX +" ";
    if (llGetSubString(WOOD_OBJECT, 0, 2) == SF_PREFIX) WOOD_OBJECT = llGetSubString(WOOD_OBJECT, 3, -1);
    if (llGetSubString(SF_WATER, 0, 2) == SF_PREFIX) SF_WATER = llGetSubString(SF_WATER, 3, -1);
    if (llGetSubString(SF_MANURE, 0, 2) == SF_PREFIX) SF_MANURE = llGetSubString(SF_MANURE, 3, -1);
    if (llGetSubString(SF_COMPOSTABLE, 0, 2) == SF_PREFIX) SF_COMPOSTABLE = llGetSubString(SF_COMPOSTABLE, 3, -1);    
    string oldCard = osGetNotecard("config");
    if (llGetInventoryType("config-old") == INVENTORY_NOTECARD) llRemoveInventory("config-old");
    llSleep(0.1);
    osMakeNotecard("config-old", oldCard);
    llSleep(0.1);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD) llRemoveInventory("config");
    llSleep(0.1);
    list newContents = [];
    newContents += ["# Short names names of supported plants, separated with comma"];
    newContents += ["PLANTLIST="+llDumpList2String(PLANTS, ",")+"\n"];
    newContents += ["# Full names of products each plant rezzes"];
    newContents += ["PRODUCTLIST="+llDumpList2String(PRODUCTS, ",")+"\n"];
    newContents += ["# Days in growing period. Plant spends LIFEDAYS/3 time in 'New' so total days to be ripe is LIFEDAYS*1.3)"];
    newContents += ["LIFEDAYS="+(string)llRound(LIFETIME/86400)+"\n"];
    newContents += ["# How many times to water the plant during the growing phase"];
    newContents += ["WATER_TIMES="+(string)llRound(WATER_TIMES)+"\n"];
    newContents += ["# If 1, will auto plant same again when harvested"];
    newContents += ["AUTOREPLANT="+(string)AUTOREPLANT+"\n"];
    newContents += ["# Whether this plant gives a wood product. If yes, the product must be in the contents"];
    newContents += ["HAS_WOOD="+(string)HAS_WOOD+"\n"];
    newContents += ["# How many times to give wood during the growing phase"];
    newContents += ["WOOD_TIMES="+(string)llRound(WOOD_TIMES)+"\n"];
    newContents += ["# Short name of 'wood' product"];
    newContents += ["WOOD_OBJECT="+WOOD_OBJECT+"\n"];
    newContents += ["# Products produced during growing cycle. Can use as well as or instead of 'WOOD' settings"];
    newContents += ["BY_PRODUCTS="+llDumpList2String(BY_PRODUCTS, ",")+"\n"]; 
    newContents += ["# How many times to give by-product during the growing phase"];
    newContents += ["BY_PRODUCT_TIMES="+llDumpList2String(BY_PRODUCT_TIMES, ",")+"\n"];
    newContents += ["# Where to rez harvested items"];
    newContents += ["REZ_POSITION="+(string)rezzPosition+"\n"];
    newContents += ["# Set to 0 to not show the status float text"];
    newContents += ["FLOAT_TEXT="+(string)floatText+"\n"];
    newContents += ["# Full name of place to get water in auto water mode"];
    newContents += ["WELL="+SF_WATER_TOWER+"\n"];
    newContents += ["# Short name of water product to accept for manual watering"];
    newContents += ["WATER_OBJECT="+SF_WATER+"\n"];
    newContents += ["# Short name of product to accept as manure"];
    newContents += ["MANURE_OBJECT="+SF_MANURE+"\n"];
    newContents += ["# Short name of product to give as compostable product"];
    newContents += ["COMPOSTABLE_OBJECT="+SF_COMPOSTABLE+"\n"];
    newContents += ["# Set to 1 to use prims rather than texture for the stages of plant growth"];
    newContents += ["PLANT_PRIMS="+(string)plantPrims+"\n"];
    newContents += ["# If PLANT_PRIMS = 1, set this to 1 to increase the size of the prim as the plant grows"];
    newContents += ["GROW_PRIMS="+(string)growPrims+"\n"];
    newContents += ["# For primplants"];
    newContents += ["SCALE="+(string)scaleFactor+"\n"];
    newContents += ["# If your products start with a different prefix set it here"];
    newContents += ["SF_PREFIX="+SF_PREFIX+"\n"];
    newContents += ["# Default language"];                 
    newContents += ["LANG="+languageCode+"\n"];
    newContents += ["# If 1 will do hard reset on rez"];
    newContents += ["RESET_ON_REZ="+(string)doReset+"\n"];
    osMakeNotecard("config",newContents);        
}

default
{
    state_entry()
    {
        // Don't run this in the updater
        if (llGetInventoryType("FARM-UPDATER") != INVENTORY_SCRIPT)
        {
            // This version of plant script merges in the auto-harvest plugin so get rid of it now!
            if (llGetInventoryType("auto-harvest_plugin") == INVENTORY_SCRIPT) llRemoveInventory("auto-harvest_plugin");
            // Now update the config notecard
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