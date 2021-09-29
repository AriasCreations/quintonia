// CHANGE LOG
// Merged in autoharvest plugin (so this script will delete the 'plugin-auto_harvest' script if present in the plant)
// By-products - can use this instead of or as well as 'wood'   specifiy items that are produced during the growin process such as petals, branches, roots etc
// Changed notecard so now you have setting for SF_PREFIX and don't use it for product names e.g.  was 'SF Wood' now is 'Wood'
// Added Replant option to menu
// NEW/CHANGED TEXT
string TXT_REPLANT = "Replanting";
string TXT_REPLANT_ON = "Replanting is On";
string TXT_REPLANT_OFF = "Replanting is Off";
string TXT_GET="Get";
string TXT_ERROR_GROUP="Error: not in the same group";
// REMOVE this
//   string  TXT_GIVE_WOOD="Here is your pile of wood";

//   plant.lsl   //

/**
This script is common for trees, plant fields, grapes etc.  It supports multiple plants.
To add a new text based plant, e.g. Mango:
1. Create 3 textures, 'Mango-New' for the new plant, 'Mango-Growing' for the growing phase, 'Mango-Ripe' for the ripe phase.
2. Create an SF Mango object by copying another product, changing its Object name to "SF Mango", or by creating one from scratch (See the prod_gen_multi script)
3. Add the textures and the SF Mango object inside the plant's contents.
4. Add the product in the 'config' notecard (see below)
5. Set the name of the prim that is the plant texture to 'Foliage'
OR
To add a new prim based plant, e.g. Mushroom:
/ Prim name can be one or more of New, Growing and Ripe  e.g 'Ripe' or 'New;Growing;Ripe' etc
  Prims with Growing in their name grow if growPrims is TRUE
#
**/
float  VERSION = 4.6;     // RC-1 18 April 2021
integer RSTATE  = -1;     // RSTATE: 1=release, 0=beta, -1=RC

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

//variables that get set in config notecard
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
//
// Language support
string  TXT_PLANTED = " Planted!";
string  TXT_EMPTYING = "Emptying..."  ;
string  TXT_HARVETS_READY = "Congratulations! Your harvest is ready!";
string  TXT_FOUND_WATER="Found water";
string  TXT_AUTOWATER="AutoWater";
string  TXT_AUTOWATERING_OFF="Auto watering is Off";
string  TXT_AUTOWATERING_ON="Auto watering is On";
string  TXT_AUTO_HARVEST = "AutoHarvest";
string  TXT_AUTOHARVESTING_OFF="Auto harvesting is Off";
string  TXT_AUTOHARVESTING_ON="Auto harvesting is On";
string  TXT_NEEDS_WATER="NEEDS WATER";
string  TXT_SEEK_WT="Looking for water tower...";
string  TXT_HARVEST="Harvest";
string  TXT_CLEANUP="Cleanup";
string  TXT_PLANT="Plant";
string  TXT_WATER_PLANT="Water plant";
string  TXT_ADD="Add";
string  TXT_BUTTON_CLOSE="CLOSE";
string  TXT_MENU_OPTIONS="Options";
string  TXT_STATUS="Status:";
string  TXT_CLICK_TO_PLANT = "Click to plant";
string  TXT_CLICK_TO_CLEANUP = "Click to cleanup";
string  TXT_LOW_ENERGY="Not enough energy for task";
string  TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string  TXT_ERROR_LOCKED="Error: I am locked, did you try to copy me? To unlock me without losing any progress, just ask the farm manager";
string  TXT_ERROR_NO_CONFIG="Error: No config Notecard found. I can't work without one";
string  TXT_ERROR_AUTO_WATER="Error! Water tower not found within 96m. Auto-watering NOT working!";
string  TXT_ERROR_NOT_FOUND="Error! Not found! You must bring it near me!";
string  TXT_LANGUAGE="@";
//
string  TXT_EMPTY="Empty";
string  TXT_NEW="New";
string  TXT_GROWING="Growing";
string  TXT_RIPE="Ripe";
string  TXT_DEAD="Dead";
//
// Commands from NPC are always these words
string NPC_WATER_PLANT  = "Water";
string NPC_HARVEST      = "Harvest";
string NPC_PLANT        = "Plant";
//
string SUFFIX = "P1";
//
vector WHITE  = <1.000, 1.000, 1.000>;
vector BROWN  = <0.333, 0.237, 0.160>;
vector BLACK  = <0.048, 0.034, 0.023>;
vector LEMON  = <1.000, 0.900, 0.600>;
vector YELLOW = <1.000, 0.863, 0.000>;
vector GREEN  = <0.180, 0.800, 0.251>;
vector RED    = <1.000, 0.000, 0.000>;
//
string FOLIAGE_TEXTURE = "Foliage";
string PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer INTERVAL = 300;
string PRODUCT_NAME;
//for AddOns
list customOptions = [];
list customText = [];
list statusOptions = [];
// for primbased plants
list  link_scales = [];
list  link_num = [];
float max_scale;
float min_scale;
//status and temporary variables
integer statusLeft;
integer statusDur;
string status = "";
string plant = "";
float water = 10.;
float wood = 0;
list byProdLevels = [];
integer energy;
string mode = "";
integer autoWater = 0;
integer autoHarvest;
string sense = "";
string season = "";
float trans = 1.0;
key lastUser;

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
    }
}


loadConfig(integer checkForReset)
{
    integer index;
    integer count;
    string cmd;
    string val;
    string line;
    list tok;
    //sfp notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    if (osGetNumberOfNotecardLines("sfp") >= 2) doReset = (integer)osGetNotecardLine("sfp", 1);
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        count = llGetListLength(lines);
        for (index = 0; index < count; index++)
        {
            line = llList2String(lines, index);
            if (llGetSubString(line, 0, 0) != "#")
            {
                tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    val=llStringTrim(llList2String(tok, 1), STRING_TRIM);

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
    }
    else
    {
        llSay(0, TXT_ERROR_NO_CONFIG);
    }
    SF_PREFIX = SF_PREFIX +" ";

    // Zero by-product levels if used
    count = llGetListLength(BY_PRODUCTS);
    if (count > 0)
    {
        byProdLevels = [];
        for (index = 0; index < count; index++)
        {
            byProdLevels += 0.0;
        }
    }
    debug("ByProducts:"+llDumpList2String(BY_PRODUCTS, "|"));

    //state by description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "T")
    {
        if ((llList2String(desc, 7) != (string)chan(llGetKey())) && doReset && checkForReset)
        {
            if (doReset == 1)
            {
                llSetObjectDesc("");
            }
            else
            {
                doReset = -1;
            }
        }
        else
        {
            PRODUCT_NAME = llList2String(desc, 1);
            status = llList2String(desc, 2);
            statusLeft = llList2Integer(desc, 3);
            water = llList2Float(desc, 4);
            wood = llList2Float(desc, 5);
            plant = llList2String(desc, 6);
            autoWater = llList2Integer(desc, 8);
            languageCode = llList2String(desc, 9);
            autoHarvest = llList2Integer(desc, 10);
            if (status == "New")
            {
                statusDur = (integer)(LIFETIME / 3);
            }
            else
            {
                statusDur = (integer)LIFETIME;
            }
            // Check for any by-product levels
            if (llList2String(desc, 11) != "")
            {
                byProdLevels = [];
                count = llGetListLength(desc);
                for (index = 11; index < count; index++)
                {
                    byProdLevels += llList2Float(desc, index);
                }
            }
            debug("by-prods:"+llDumpList2String(byProdLevels, "|"));
        }
    }
}

save2Desc()
{
    string codedDesc = "T;"+PRODUCT_NAME+";"+status+";"+(string)(statusLeft)+";"+(string)llRound(water)+";"+(string)llRound(wood)+";"+plant+";"+(string)chan(llGetKey())+";"+(string)autoWater + ";"+languageCode +";"+(string)autoHarvest;
    if (llGetListLength(byProdLevels) != 0) codedDesc  += ";"+llDumpList2String(byProdLevels, ";");
    llSetObjectDesc(codedDesc);
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
                         if (cmd == "TXT_PLANTED")  TXT_PLANTED = val;
                    else if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_HARVETS_READY") TXT_HARVETS_READY = val;
                    else if (cmd == "TXT_FOUND_WATER") TXT_FOUND_WATER = val;
                    else if (cmd == "TXT_AUTOWATER") TXT_AUTOWATER = val;
                    else if (cmd == "TXT_AUTOWATERING_OFF") TXT_AUTOWATERING_OFF = val;
                    else if (cmd == "TXT_AUTOWATERING_ON") TXT_AUTOWATERING_ON = val;
                    else if (cmd == "TXT_AUTO_HARVEST")  TXT_AUTO_HARVEST = val;
                    else if (cmd == "TXT_AUTOHARVESTING_OFF") TXT_AUTOHARVESTING_OFF = val;
                    else if (cmd == "TXT_AUTOHARVESTING_ON") TXT_AUTOHARVESTING_ON = val;
                    else if (cmd == "TXT_NEEDS_WATER") TXT_NEEDS_WATER = val;
                    else if (cmd == "TXT_SEEK_WT") TXT_SEEK_WT = val;
                    else if (cmd == "TXT_HARVEST") TXT_HARVEST = val;
                    else if (cmd == "TXT_CLEANUP") TXT_CLEANUP = val;
                    else if (cmd == "TXT_PLANT") TXT_PLANT = val;
                    else if (cmd == "TXT_WATER_PLANT") TXT_WATER_PLANT = val;
                    else if (cmd == "TXT_GET") TXT_GET = val;
                    else if (cmd == "TXT_BUTTON_CLOSE") TXT_BUTTON_CLOSE = val;
                    else if (cmd == "TXT_MENU_OPTIONS") TXT_MENU_OPTIONS = val;
                    else if (cmd == "TXT_EMPTY") TXT_EMPTY = val;
                    else if (cmd == "TXT_NEW") TXT_NEW = val;
                    else if (cmd == "TXT_GROWING") TXT_GROWING = val;
                    else if (cmd == "TXT_RIPE") TXT_RIPE = val;
                    else if (cmd == "TXT_DEAD") TXT_DEAD = val;
                    else if (cmd == "TXT_STATUS") TXT_STATUS = val;
                    else if (cmd == "TXT_CLICK_TO_PLANT") TXT_CLICK_TO_PLANT = val;
                    else if (cmd == "TXT_CLICK_TO_CLEANUP") TXT_CLICK_TO_CLEANUP = val;
                    else if (cmd == "TXT_REPLANT_OFF") TXT_REPLANT_OFF = val;
                    else if (cmd == "TXT_REPLANT_ON") TXT_REPLANT_ON = val;
                    else if (cmd == "TXT_REPLANT") TXT_REPLANT = val;
                    else if (cmd == "TXT_LOW_ENERGY") TXT_LOW_ENERGY = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_LOCKED") TXT_ERROR_LOCKED = val;
                    else if (cmd == "TXT_ERROR_NO_CONFIG") TXT_ERROR_NO_CONFIG = val;
                    else if (cmd == "TXT_ERROR_AUTO_WATER") TXT_ERROR_AUTO_WATER = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

psys()
{
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    //PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<.4000000,.900000,.400000>,
                    PSYS_PART_END_COLOR,<8.000000,1.00000,8.800000>,

                    PSYS_PART_START_ALPHA,.6,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<.5000000,.5000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 100,
                    PSYS_SRC_BURST_PART_COUNT, 10,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                       // PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
}

string setByProdLevels()
{
    integer index;
    float result;
    string progress = "";
    integer count = llGetListLength(BY_PRODUCTS);
    if (count >0)
    {
        integer amount;
        string bpText = TXT_RIPE+":\n";
        for (index = 0; index < count; index++)
        {
            result = llFloor(llList2Float(byProdLevels, index));
            if (result >= 100.0) bpText += llList2String(BY_PRODUCTS, index)+"\n"; else progress += llList2String(BY_PRODUCTS, index) +": " +(string)(llFloor(llList2Float(byProdLevels, index)))+"%\n";
        }
        if (bpText != TXT_RIPE+":\n") llMessageLinked(LINK_SET, 1, "BP_READY|"+bpText, ""); else llMessageLinked(LINK_SET, 1, "BP_READY|"+"", "");
    }
    return progress;
}

refresh()
{
    string progress = "";
    vector color = LEMON;
    string customStr = "";
    float result;
    integer count;
    integer index = llGetListLength(customText);
    while (index--)
    {
        customStr = llList2String(customText, index) + "\n";
    }

    if (status == "New" || status == "Growing" || status == "Ripe")
    {
        progress = plant+"\n";
        if (llGetAndResetTime() >= (INTERVAL - 20))
        {
            // Update water level
            water -= (float)(INTERVAL / LIFETIME * WATER_TIMES) * 100.0;

            // Update Wood level
            wood += (float)(INTERVAL / LIFETIME * WOOD_TIMES) * 100.0;
            if (wood > 100.0) wood = 100.0;

            // Update by-product levels
            float times;
            count = llGetListLength(BY_PRODUCTS);
            for (index = 0; index < count; index++)
            {
                result = llList2Float(byProdLevels, index);
                times = llList2Float(BY_PRODUCT_TIMES, index);
                result += (float)(INTERVAL / LIFETIME * times) * 100.0;
                if (result > 100.0) result = 100.0;
                byProdLevels = llListReplaceList(byProdLevels, [result], index, index);
            }

            // Check plant health
            if (water <= -50.)
            {
                status = "Dead";
            }
            else if (water > 3.)
            {
                statusLeft -= INTERVAL;
                if ( statusLeft <=0)
                {
                    if (status == "New")
                    {
                        status = "Growing";
                        statusLeft = statusDur =  (integer) (LIFETIME);
                    }
                    else if (status == "Growing")
                    {
                        status = "Ripe";
                        statusLeft = statusDur =  (integer) (LIFETIME);
                    }
                    else if (status == "Ripe")
                    {
                        if (AUTOREPLANT)
                        {
                            status = "New";
                            statusLeft   = statusDur =  (integer) LIFETIME/3;
                        }
                        else
                        {
                            status = "Dead";
                        }
                    }
                }
            }
        }
        //
        setFoliage(TRUE, WHITE);
        if (water <= 5.0)
        {
            if (autoWater)
            {
                sense = "AutoWater";
                llSensor(SF_WATER_TOWER, "", SCRIPTED, 96, PI);
                llSay(0, TXT_SEEK_WT);
            }
            progress += TXT_NEEDS_WATER+"!\n";
            setFoliage(TRUE, BROWN);
            color = RED;
        }
        else if (status == "Growing" && statusLeft <= 86400)
        {
            color = YELLOW;
            llMessageLinked(LINK_SET, 1, "STAGE|GROWING", NULL_KEY);
        }
        else if (status == "Ripe")
        {
            color = GREEN;
            llMessageLinked(LINK_SET, 1, "STAGE|RIPE", NULL_KEY);
        }
        else if (status == "New")
        {
            llMessageLinked(LINK_SET, 1, "STAGE|NEW", NULL_KEY);
        }
        //
        float p = 1- ((float)(statusLeft)/(float)statusDur);

        progress += TXT_STATUS+": ";
             if (status == "Empty") progress += TXT_EMPTY;
        else if (status == "New") progress += TXT_NEW;
        else if (status == "Growing") progress += TXT_GROWING;
        else if (status == "Ripe") progress += TXT_RIPE;
        else if (status == "Dead") progress += TXT_DEAD;
        progress += " ("+(string)((integer)(p*100.))+"%)\n---\n";
        progress += SF_WATER+" "+(string)((integer)osMax(0.0, water))+ "%\n";
        if (HAS_WOOD)
        {
            progress += WOOD_OBJECT+" "+(string)(llFloor(wood))+"%\n";
        }
        progress += setByProdLevels();
    }

    if (status == "Dead")
    {
        setFoliage(TRUE, BLACK);
        progress = TXT_DEAD +" "+ TXT_CLICK_TO_CLEANUP;
        color = RED;
    }
    else if (status == "Empty")
    {
        setFoliage(FALSE, ZERO_VECTOR);
        llMessageLinked(LINK_SET, 1, "STAGE|EMPTY", NULL_KEY);
        progress = TXT_EMPTY + "\n" + TXT_CLICK_TO_PLANT;
    }

    debug(customStr + progress);
    psys();

    if (RSTATE == 0) progress+= "\n-B-"; else if (RSTATE == -1) progress+= "\n-RC-";
    if (floatText == TRUE) llSetText(customStr + progress, color, 1.0); else llSetText("",ZERO_VECTOR,0.0);
    llMessageLinked(LINK_SET, 92, "STATUS|"+status+"|"+(string)statusLeft+"|WATER|"+(string)water+"|PRODUCT|"+PRODUCT_NAME+"|PLANT|"+plant+"|LIFETIME|"+(string)LIFETIME, NULL_KEY);
    save2Desc();
}

doHarvest()
{
    if (status == "Ripe")
    {
        llMessageLinked(LINK_SET, 1, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PREFIX+PRODUCT_NAME, NULL_KEY);
        llRegionSayTo(lastUser, 0, TXT_HARVETS_READY);

         if (AUTOREPLANT)
         {
            statusDur = statusLeft = (integer)(LIFETIME/3.);
            status = "New";
         }
         else
            status = "Empty";

         refresh();
         llTriggerSound("lap", 1.0);
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

// return a list of elements common to both lists
list ListXandY(list lx, list ly)
{

    list lz = []; integer x;
    for (x = 0; x < llGetListLength(ly); x++)
    {
        if (~llListFindList(lx,llList2List(ly,x,x)))
        {
            lz = lz + llList2List(ly,x,x);
        }
        else
        {
            //
        }
    }
    return lz;
}

setFoliage(integer visible, vector colour)
{
    string texture;
    if (visible == FALSE)
    {
        if (plantPrims == FALSE)
        {
            llSetLinkTexture(getLinkNum(FOLIAGE_TEXTURE), TEXTURE_TRANSPARENT, ALL_SIDES);
        }
        else
        {
            list primNames = [];
            integer i;
            for (i=1; i <=llGetNumberOfPrims(); i++)
            {
                // Prim name can be one or more of New, Growing and Ripe  e.g 'Ripe' or 'New;Growing;Ripe' etc
                primNames = llParseString2List(llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]), 0), [";"], []);
                if (llGetListLength(ListXandY(primNames, ["New", "Growing", "Ripe"])) != 0)
                {
                    llSetLinkAlpha(i, 0.0, ALL_SIDES);
                }
            }
        }
    }
    else
    {
        if (plantPrims == FALSE)
        {
            texture = season + plant + "-" + status;
            if (llGetInventoryType(texture) == INVENTORY_TEXTURE)
            {
                llSetLinkTexture(getLinkNum(FOLIAGE_TEXTURE), texture, ALL_SIDES);
            }
            llSetLinkColor(getLinkNum(FOLIAGE_TEXTURE), colour, ALL_SIDES);
        }
        else
        {
            list primNames = [];
            integer i;
            for (i=1; i <=llGetNumberOfPrims(); i++)
            {
                // Prim name can be one or more of New, Growing and Ripe  e.g 'Ripe' or 'New;Growing;Ripe' etc
                primNames = llParseString2List(llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]), 0), [";"], []);

                if (llGetListLength(ListXandY(primNames, ["New", "Growing", "Ripe"])) != 0)
                {
                    if (llListFindList(primNames, [status]) != -1)
                    {
                        debug("plant_prim="+(string)i);
                        llSetLinkAlpha(i, 1.0, ALL_SIDES);
                        if ((status == "Growing") && (growPrims == TRUE))
                        {
                            float percentGrowth = (1- ((float)(statusLeft)/(float)statusDur)) * 100;
                            debug("Progress:"+ llRound(percentGrowth) +"\nstatusLeft:" +(string)statusLeft + "   statusDur:" +(string)statusDur);
                            resizeObject(percentGrowth/scaleFactor);
                        }
                    }
                    else
                    {
                        llSetLinkAlpha(i, 0.0, ALL_SIDES);
                    }
                }
            }
        }
    }
}

resizeObject(float scale)
{
    integer link_qty = llGetListLength(link_scales);
    integer link_idx;
    for (link_idx = 0; link_idx < link_qty; ++link_idx)
    {
        llSetLinkPrimitiveParamsFast(llList2Integer(link_num, link_idx),    [PRIM_SIZE, scale * llList2Vector(link_scales, link_idx) ]);
    }
}

default
{
    on_rez(integer n)
    {
        llSetObjectDesc(" ");
        llSleep(0.5);
        llResetScript();
    }

    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD);
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id, NULL_KEY);
    }

    state_entry()
    {
        season = "";
        link_scales = [];
        link_num = [];
        if (llGetInventoryType("scales") == INVENTORY_NOTECARD)
        {
            list lst = llParseString2List(osGetNotecard("scales"), ["|"], []);
            integer c = llGetListLength(lst) - 2;
            integer indx;
            for (indx=0; indx<c; indx+=2)
            {
                link_scales += llList2Vector(lst, indx);
                link_num += llList2Integer(lst, indx+1);
            }
            max_scale = llList2Float(lst, -2);
            min_scale = llList2Float(lst, -1);
        }
        llSleep(2.0);
        //for updates
        if (llSubStringIndex(llGetObjectName(), "Update")>=0 || llSubStringIndex(llGetObjectName(), "Rezz")>=0)
        {
            string me = llGetScriptName();
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        //
        status = "Empty";
        loadConfig(TRUE);
        loadLanguage(languageCode);
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
        setFoliage(FALSE, ZERO_VECTOR);
        refresh();
        llSetTimerEvent(1);
    }

    touch_start(integer n)
    {
        if (!llSameGroup(llDetectedKey(0)) && !osIsNpc(llDetectedKey(0)))
        {
            llRegionSayTo(llDetectedKey(0), 0, TXT_ERROR_GROUP);
            return;
        }
        if (doReset == -1)
        {
            llRegionSayTo(llDetectedKey(0), 0,TXT_ERROR_LOCKED);
            return;
        }
        lastUser = llDetectedKey(0);
        energy = -1;
        llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|CQ");
        llSleep(0.25);
        list opts = [];
        if (status == "Ripe")  opts += TXT_HARVEST;
        else if (status == "Dead" || (status == "New" && AUTOREPLANT))  opts += TXT_CLEANUP;
        else if (status == "Empty")  opts += TXT_PLANT;
        //
        if (water < 90) opts += TXT_WATER_PLANT;
        if (autoWater) opts += "-"+TXT_AUTOWATER;
        else opts += "+"+TXT_AUTOWATER;
        //
        if (HAS_WOOD && wood >= 100.0) opts += TXT_GET+" "+WOOD_OBJECT;
        //
        // Add buttons for 100% by-products
        integer index;
        float result;
        integer count = llGetListLength(BY_PRODUCTS);
        for (index = 0; index < count; index++)
        {
            result = llList2Float(byProdLevels, index);
            if (result >= 100.0) opts += TXT_GET+" "+llList2String(BY_PRODUCTS, index);
        }
        //
        if (status == "Growing") opts += TXT_ADD+" "+ SF_MANURE;

        if (autoHarvest == TRUE)
        {
            opts += "-"+TXT_AUTO_HARVEST;
        }
        else
        {
            opts += "+"+TXT_AUTO_HARVEST;
            if (AUTOREPLANT == TRUE) opts += "-"+TXT_REPLANT; else opts += "+"+TXT_REPLANT;
        }
        opts += customOptions;
        opts += TXT_LANGUAGE;
        opts += TXT_BUTTON_CLOSE;
        //
        string customStr = "";
        integer i = llGetListLength(statusOptions);
        while (i--)
        {
            customStr = llList2String(statusOptions, i) + "\n";
        }
        if (autoHarvest) customStr += TXT_AUTOHARVESTING_ON; else customStr += TXT_AUTOHARVESTING_OFF;
        customStr += "\t";
        if (AUTOREPLANT) customStr += TXT_REPLANT_ON; else customStr += TXT_REPLANT_OFF;
        customStr += "\n";
        if (autoWater) customStr += TXT_AUTOWATERING_ON; else customStr += TXT_AUTOWATERING_OFF;
        startListen();
        llDialog(lastUser, "\n" +TXT_MENU_OPTIONS +"\n \n" +customStr, opts, chan(llGetKey()));
    }

    listen(integer c, string n ,key id , string m)
    {
        debug("listen: " +m +" mode="+mode);
        if (m == TXT_BUTTON_CLOSE)
        {
            refresh();
        }
        else if ((m == TXT_WATER_PLANT) || (m == NPC_WATER_PLANT))
        {
            if ((energy >= 1) || (energy == -1))
            {
                llSensor(SF_PREFIX+SF_WATER, "", SCRIPTED, 5, PI);
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
            }
        }
        else if (m == (TXT_ADD+" "+ SF_MANURE))
        {
            if ((energy >= 1) || (energy == -1))
            {
                llSensor(SF_PREFIX+SF_MANURE, "", SCRIPTED, 5, PI);
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
            }
        }
        else if (m == TXT_CLEANUP)
        {
            if ((energy >= 2) || (energy == -1))
            {
                setFoliage(FALSE, ZERO_VECTOR);
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PREFIX+SF_COMPOSTABLE, NULL_KEY);
                status="Empty";
                llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Hygiene|-5|Energy|-2");
                lastUser = NULL_KEY;
                refresh();
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
            }
        }
        else if ((m == TXT_HARVEST) || (m == NPC_HARVEST))
        {
            if ((energy >= 2) || (energy == -1))
            {
                doHarvest();
                llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Hygiene|-1|Health|5|Energy|-2");
                lastUser = NULL_KEY;
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
            }
        }
        else if ((m == TXT_PLANT) || (m == NPC_PLANT))
        {
            if ((energy >= 1) || (energy == -1))
            {
                mode = "SelectPlant";
                llDialog(id, TXT_MENU_OPTIONS, PLANTS+[TXT_BUTTON_CLOSE], chan(llGetKey()));
                return;
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
                return;
            }
        }
        else if (m == "+"+TXT_AUTOWATER || m == "-"+TXT_AUTOWATER)
        {
            autoWater =  ! autoWater;
            if (autoWater == 0) llRegionSayTo(id, 0, TXT_AUTOWATERING_OFF); else llRegionSayTo(id, 0, TXT_AUTOWATERING_ON);
            llSetTimerEvent(1);
        }
        else if (m == "+"+TXT_AUTO_HARVEST || m == "-"+TXT_AUTO_HARVEST)
        {
            autoHarvest =  ! autoHarvest;
            if (autoHarvest == 0)
            {
                llRegionSayTo(id, 0, TXT_AUTOHARVESTING_OFF);
            }
            else
            {
                llRegionSayTo(id, 0, TXT_AUTOHARVESTING_ON);
                //AUTOREPLANT = TRUE;
            }
            llSetTimerEvent(1);
        }
        else if (m == "+"+TXT_REPLANT || m == "-"+TXT_REPLANT)
        {
            AUTOREPLANT =  !AUTOREPLANT;
            if (AUTOREPLANT == 0) llRegionSayTo(id, 0, TXT_REPLANT_OFF); else llRegionSayTo(id, 0, TXT_REPLANT_ON);
            llSetTimerEvent(1);
        }
        else if (m == (TXT_GET+" "+WOOD_OBJECT))
        {
            if (wood >=100.)
            {
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PREFIX+WOOD_OBJECT, NULL_KEY);
                wood =0;
                refresh();
                llTriggerSound("lap", 1.0);
                llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Hygiene|-1|Health|2");
            }
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (mode == "SelectPlant")
        {
            integer idx = llListFindList(PLANTS, [m]);
            if (idx>=0)
            {
                plant = llStringTrim(llList2String(PLANTS, idx), STRING_TRIM);
                PRODUCT_NAME = llStringTrim(llList2String(PRODUCTS, idx) , STRING_TRIM);
                statusLeft = statusDur = (integer)(LIFETIME/3.);
                status="New";
                if (water <0) water =0;
                llRegionSayTo(lastUser, 0, m+" " + TXT_PLANTED);
                llTriggerSound("lap", 1.0);
                llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Hygiene|-1|Health|5|Energy|-1");
                refresh();
            }
            mode = "";
        }
        else if (llListFindList(BY_PRODUCTS, llGetSubString(m, 4, -1)) != -1)
        {
            // String would be  'Get Sticks' etc so remove the Get part so we just have by-product name
            string mm = llGetSubString(m, 4, -1);
            integer index;
            integer count = llGetListLength(BY_PRODUCTS);
            for (index = 0; index < count; index++)
            {
                if (mm == llList2String(BY_PRODUCTS, index))
                {
                     llTriggerSound("lap", 1.0);
                    llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +SF_PREFIX+mm, NULL_KEY);
                    byProdLevels = llListReplaceList(byProdLevels, [0.0], index, index);
                }
            }
            setByProdLevels();
            refresh();
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        checkListen(TRUE);
    }

    dataserver(key k, string m)
    {
        debug("dataserver: " +m);
        list cmd = llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(cmd,1) != PASSWORD)
        {
            return;
        }
        string command = llList2String(cmd, 0);

        if (command == "INIT")
        {
            doReset = 2;
            loadConfig(FALSE);
            llSetRemoteScriptAccessPin(0);
            refresh();
        }
        else if (command == "WATER")
        {
            water=100.0;
            if (sense != "AutoWater")
            {
                llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Health|5|Energy|-1");
                lastUser = NULL_KEY;
            }
            refresh();
        }
        else if (command == "MANURE")
        {
            statusLeft -= 86400;
            if (statusLeft<0) statusLeft=0;
            llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Hygiene|-1|Health|5|Energy|-1");
            refresh();
        }
        else if (command == "HAVEWATER")
        {
             // found water
            if (sense == "WaitTower")
            {
                llSay(0, TXT_FOUND_WATER);
                water=100.;
                refresh();
                sense = "";
            }
        }
        else if (command == "HEALTH")
        {
            if ((llList2String(cmd, 2) == "ENERGY") && (llList2Key(cmd, 3) == lastUser))
            {
                energy = llList2Integer(cmd, 4);
                return;
            }
        }
        //for updates
        else if (command == "VERSION-CHECK")
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
            osMessageObject(llList2Key(cmd, 2), answer);
        }
        else if (command == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, TXT_ERROR_UPDATE);
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(cmd, 3);
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
            osMessageObject(llList2Key(cmd, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        //
    }


    timer()
    {
        llSetTimerEvent(INTERVAL);
        if (doReset == -1)
          return;
        refresh();
        checkListen(FALSE);
    }

    sensor(integer n)
    {
        if (sense == "AutoWater")
        {
            key id = llDetectedKey(0);
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
            sense = "WaitTower";
        }
        else
        {
            // Manure / water
            llRegionSayTo(lastUser, 0, TXT_EMPTYING);
            key id = llDetectedKey(0);
            osMessageObject(id,  "DIE|"+(string)llGetKey());
        }
    }

    no_sensor()
    {
        if (sense == "AutoWater")
           llSay(0, TXT_ERROR_AUTO_WATER);
        else
           llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND);
        sense = "";
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " +m);
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "ADD_MENU_OPTION")  // Add custom dialog menu options.
        {
            customOptions += [llList2String(tok,1)];
        }
        else if (cmd == "REM_MENU_OPTION")
        {
            integer findOpt = llListFindList(customOptions, [llList2String(tok,1)]);
            if (findOpt != -1)
            {
                customOptions = llDeleteSubList(customOptions, findOpt, findOpt);
            }
        }
        if (cmd == "ADD_STATUS_OPTION")  // Add custom dialog menu options.
        {
            statusOptions += [llList2String(tok,1)];
        }
        else if (cmd == "REM_STATUS_OPTION")
        {
            integer findOpt = llListFindList(statusOptions, [llList2String(tok,1)]);
            if (findOpt != -1)
            {
                statusOptions = llDeleteSubList(statusOptions, findOpt, findOpt);
            }
        }
        else if (cmd == "ADD_TEXT")
        {
            customText += [llList2String(tok,1)];
        }
        else if (cmd == "REM_TEXT")
        {
            integer findTxt = llListFindList(customText, [llList2String(tok,1)]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
        }
        else if (cmd == "SETSTATUS")    // Change the status of this plant
        {
            status = llList2String(tok, 1);
            statusLeft = statusDur = llList2Integer(tok, 2);
            refresh();
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            refresh();
        }
        else if (cmd == "HARVEST")    // Change the status of this plant
        {
            doHarvest();  // Status must be "Ripe"
        }

        else if (cmd == "STATUS")
        {
            string status = llList2String(tok,1);
            if (status == "Ripe")
            {
                if (autoHarvest) // If autoharvest is on, send message to harvest
                {
                    integer TIME = 300;
                    integer found = llListFindList(tok, ["LIFETIME"]) + 1;
                    if (found)
                    {
                        TIME = llList2Integer(tok, found) / 3;
                    }
                    llMessageLinked(LINK_THIS, 1, "HARVEST", NULL_KEY);
                    llSleep(1.0);
                    llMessageLinked(LINK_THIS, 1, "SETSTATUS|New|" + (string)TIME, NULL_KEY);
                }
            }
        }
        else if (cmd == "WINTER")
        {
            season = "W";
            trans = 0.5;
            refresh();
        }
        else if (cmd == "GROWING")
        {
            season = "";
            trans = 1.0;
            refresh();
        }
    }
}
