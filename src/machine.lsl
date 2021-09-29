//### machine.lsl
//
// Common script used by all processing machines, e.g. juice maker, oven, windmill etc
// Takes a list of ingredients and makes a product item.

float VERSION = 4.1;   // 22 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// Default Values - can be set in the config notecard

integer mustSit = 0;                    // MUST_SIT=0               If the Avatar is required to sit on the object to produce items
integer makeVerb = TRUE;                // MAKE_VERB=1              Use 1 for 'make' or 0 for 'do'
integer default_sensorRadius = 5;       // SENSOR_DISTANCE=10       How far to search (radius) when searching for ingredients to add
integer default_timeToCook = 60;        // DEFAULT_DURATION         Default cooking time if not specified in recipe
vector  default_rezzPosition = <1,0,0>; // REZ_POSITION=<1,1,1>     Default rez position. Can be overridden in the RECIPES notecard with the RezPos:<x,y,z> optional parameter
string languageCode = "en-GB";          // LANG=en-GB               Default language
string PREFIX = "";                     // RCODE=WINDMILL           For using networked recipe cards
// Multilingual support
string TXT_CLOSE = "CLOSE";
string TXT_ABORT="ABORT";
string TXT_RESUME="RESUME";
string TXT_MAKE="Make...";
string TXT_DO="Do...";
string TXT_MENU="Menu";
string TXT_SELECT="Select";
string TXT_RECIPE="Recipe";
string TXT_OK="OK";
string TXT_MISSING="Missing";
string TXT_FOUND="Found";
string TXT_EMPTYING="emptying";
string TXT_LOOKING_FOR="Looking for";
string TXT_LOW_ENERGY="Not enough energy for task";
string TXT_OR=" or ";
string TXT_ADD="Add an ingredient";
string TXT_ADD_INGREDIENTS="Click to add ingredients";
string TXT_SELECTED="Selected";
string TXT_PROGRESS="Progress";
string TXT_SELECTED_RECIPE="Selected recipe:";
string TXT_PREP="All set, preparing ...";
string TXT_SIT="Sit here to produce item";
string TXT_FINISHED="Your item is ready!";
string TXT_NO_PRODUCT="Caution, selected product not in inventory";
string TXT_CHECKING="Checking storage locations...";
string TXT_ERROR_READ="RECIPES Notecard parsing Error. Are ingredients and product set?";
string TXT_ERROR_NOT_FOUND="Error! Recipe not found:";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_ERROR_LOCKED="I am locked, did you try to copy me? You can still unlock me, without losing any progress by asking the farm manager";
string TXT_NOT_FOUND_ITEM="not found nearby. You must bring it closer";
string TXT_NOT_FOUND_ENOUGH="with enough percent not found nearby. You must bring it closer";
string TXT_NOT_FOUND_ITEM100=" with 100% not found nearby";
string TXT_LANGUAGE="@";
//
// NPC Farmer messages in English
string NPC_MAKE="Make...";
string NPC_ABORT="ABORT";
string NPC_WATER="Water";
string NPC_SLOP="Slop";
//
string SUFFIX = "M1";
//
vector YELLOW = <1.000, 0.863, 0.000>;
vector ORANGE = <1.000, 0.522, 0.106>;
//
integer energyRate = 20;    // For working out how much energy is required for task
//
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer doReset = 1;
//for listener and menus
integer listener=-1;
integer listenTs;
integer startOffset = 0;
string  status;
list customOptions = [];
list customText = [];
list recipeNames;
//cooking vars
string  recipeName;
list    ingredients;    // strided list with num, item, percent
integer timeToCook;     // in seconds
string  objectToGive;   // Name of the object to give after done cooking
string  textureName;    // Texture to show on 'product' prim
vector  rezzPosition;   // Position of the product to rezz
integer sensorRadius;   // radius to scan for items
string  objectParams;
//temp
integer saveNC = 0;
string  lookingFor;
integer lookingForPercent;
integer ingLength;
integer haveIngredients;
integer clickedButton;
key     lastUser;
integer energy = -1;
integer paused;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


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

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

integer ingredientsListFindString(list hay, string needle)
{
    integer found_pro = llGetListLength(hay) / 3;
    //just a fancy way of llListFindList that isn't case sensitive
    while (found_pro--)
    {
        if (llToUpper(llList2String(hay, found_pro * 3 + 1)) == needle)
        {
            return found_pro * 3;
        }
    }
    return -1;
}

loadConfig()
{
    PASSWORD = osGetNotecardLine("sfp", 0);
    if (osGetNumberOfNotecardLines("sfp") >= 2)
        doReset = (integer)osGetNotecardLine("sfp", 1);

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
                if (cmd == "SENSOR_DISTANCE") default_sensorRadius = (integer)val;
                else if (cmd == "REZ_POSITION") default_rezzPosition = (vector)val;
                else if (cmd == "DEFAULT_DURATION") default_timeToCook = (integer)val;
                else if (cmd == "MUST_SIT") mustSit = (integer)val;
                else if (cmd == "MAKE_VERB") makeVerb = (integer)val;
                else if (cmd == "LANG") languageCode = val;
                else if (cmd == "RCODE") PREFIX = val;
            }
        }
    }
    // Load config options stored in description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "M")
    {
        languageCode = llList2String(desc, 1);
    }
    else
    {
        saveToDesc();
    }
}

saveToDesc()
{
    llSetObjectDesc("M;" +languageCode);
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
                         if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_ABORT") TXT_ABORT = val;
                    else if (cmd == "TXT_RESUME") TXT_RESUME = val;
                    else if (cmd == "TXT_MAKE") TXT_MAKE = val;
                    else if (cmd == "TXT_DO") TXT_DO = val;
                    else if (cmd == "TXT_MENU") TXT_MENU = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_RECIPE") TXT_RECIPE = val;
                    else if (cmd == "TXT_OK") TXT_OK = val;
                    else if (cmd == "TXT_MISSING") TXT_MISSING = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_EMPTYING") TXT_EMPTYING = val;
                    else if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_LOW_ENERGY") TXT_LOW_ENERGY = val;
                    else if (cmd == "TXT_OR") TXT_OR = val;
                    else if (cmd == "TXT_ADD") TXT_ADD = val;
                    else if (cmd == "TXT_ADD_INGREDIENTS") TXT_ADD_INGREDIENTS = val;
                    else if (cmd == "TXT_SELECTED") TXT_SELECTED = val;
                    else if (cmd == "TXT_PROGRESS") TXT_PROGRESS = val;
                    else if (cmd == "TXT_SELECTED_RECIPE") TXT_SELECTED_RECIPE = val;
                    else if (cmd == "TXT_PREP") TXT_PREP = val;
                    else if (cmd == "TXT_SIT") TXT_SIT = val;
                    else if (cmd == "TXT_FINISHED") TXT_FINISHED = val;
                    else if (cmd == "TXT_NO_PRODUCT") TXT_NO_PRODUCT = val;
                    else if (cmd == "TXT_CHECKING") TXT_CHECKING = val;
                    else if (cmd == "TXT_ERROR_READ") TXT_ERROR_READ = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_LOCKED") TXT_ERROR_LOCKED = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM") TXT_NOT_FOUND_ITEM = val;
                    else if (cmd == "TXT_NOT_FOUND_ITEM100") TXT_NOT_FOUND_ITEM100 = val;
                    else if (cmd == "TXT_NOT_FOUND_ENOUGH") TXT_NOT_FOUND_ENOUGH = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}


multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, [TXT_CLOSE]+buttons, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(buttons, startOffset, startOffset + 9);
    startListen();
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}


setAnimations(integer level)
{
    integer i;
    for (i=0; i <= llGetNumberOfPrims(); i++)
    {
        if (llGetSubString(llGetLinkName(i),0,4) == "spin ")
        {
            list tk = llParseString2List(llGetLinkName(i), [" "], []);
            //if ((mustSit==0 && level==1) || (mustSit == 1 && level==2)) rate = 1.0;
            float rate = level *1.0;
            llSetLinkPrimitiveParamsFast(i, [PRIM_OMEGA, llList2Vector(tk, 1), rate, 1.0]);
        }
        else if (llGetSubString( llGetLinkName(i), 0, 17)  == "show_while_cooking")
        {
            vector color = llList2Vector(llGetLinkPrimitiveParams(i, [PRIM_COLOR, 0]), 0);
            float f = (float)llGetSubString( llGetLinkName(i), 18, -1);
            if (f ==0.) f= 1.0;
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, color, (level>0)*f]);
        }
    }
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
                    PSYS_PART_START_COLOR,<1.00,1.00,0.80>,
                    PSYS_PART_END_COLOR,<1.00,1.00,0.80>,

                    PSYS_PART_START_ALPHA,0.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.10,0.10,0.00>,
                    PSYS_PART_END_SCALE,<1.00,1.00,0.00>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 10,
                    PSYS_SRC_ACCEL,<0.00,0.00,0.00>,
                    PSYS_SRC_OMEGA,<0.00,0.00,0.00>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.0,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
}


refresh()
{
    string str = "";
    integer i = llGetListLength(customText);
    while (i--)
    {
        str = llList2String(customText, i) + "\n";
    }
    if (status == "Adding")
    {
        str += TXT_RECIPE + ":\t"+recipeName+"\n";
        integer missing=0;
        for (i=0; i < ingLength;i++)
        {
            integer length = llGetListLength(ingredients) / 3;
            list ingsep = [];
            while (length--)
            {
                if(llList2Integer(ingredients, length*3) == i)
                {
                    ingsep += [llList2String(ingredients, length*3 + 1)];
                }
            }
            str += llDumpList2String(ingsep, TXT_OR);
            if (haveIngredients & (0x01 << i))
            {
                str += ":\t" +TXT_OK + "\n";
            }
            else
            {
                str += ":\t" + TXT_MISSING +"\n";
                missing++;
            }
        }
        if (missing==0)
        {
            status = "Cooking";
            llRegionSayTo(lastUser, 0, TXT_PREP);
            llResetTime();
            llSetTimerEvent(2);
            llMessageLinked(LINK_SET,90, "STARTCOOKING", "");
        }
        else
        {
            str += TXT_ADD_INGREDIENTS +"\n";
        }
    }
    else if (status == "Cooking")
    {
        if (mustSit)
        {
            if (llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims())
            {
                llSetText(TXT_SIT, YELLOW, 1.0);
                llSetClickAction(CLICK_ACTION_SIT);
                setAnimations(0);
                llResetTime();
                return;
            }
        }
        if (llGetInventoryType("cooking") == INVENTORY_SOUND)
        {
            llLoopSound("cooking", 1.0);
        }
        setAnimations(1);
        float prog = (integer)((float)(llGetTime())*100./timeToCook);
        str = TXT_SELECTED +": "+recipeName+"\n" +TXT_PROGRESS + ": "+ (string)((integer)prog)+ " %";
        if (prog >=100.)
        {
            llStopSound();
            setAnimations(0);
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");

            status = "Empty";
            llRegionSayTo(lastUser, 0, TXT_FINISHED + " - " +recipeName);
            if (mustSit)
            {
                llUnSit(llGetLinkKey(llGetNumberOfPrims()));
                llSetClickAction(CLICK_ACTION_TOUCH);
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Health|20|Energy|" +(string)(-1*(timeToCook/energyRate)));
                debug("sending health to:" + (string)lastUser);
            }
            llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +objectToGive, NULL_KEY);
            ingredients = [];
            str = "";
            llMessageLinked(LINK_SET,0, "PROGRESS", "");
            llSetTimerEvent(1);
        }
        else
        {
            llMessageLinked(LINK_SET,llRound(prog), "PROGRESS", "");
        }
        psys(NULL_KEY);
        llSetTimerEvent(timeToCook/20);
    }
    else
    {
        if (listener<0)
            llSetTimerEvent(0.0);
        else
            llSetTimerEvent(300);
    }
    llSetText(str , <1,1,1>, 1.0);
}


getRecipeNames()
{
    list names = [];
    list ltok = [];
    if (PREFIX != "")
    {
        if (llGetInventoryType(PREFIX+"_RECIPES") == INVENTORY_NOTECARD)
        {
            ltok = llParseString2List(osGetNotecard(PREFIX+"_RECIPES"), ["\n"], []);
            integer l;
            for (l=0; l < llGetListLength(ltok); l++)
            {
                string line = llStringTrim(llList2String(ltok, l), STRING_TRIM);
                if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]" && line != "[END]")
                {
                    names += [llStringTrim(llGetSubString(line,1,-2), STRING_TRIM)];
                }
            }
        }
    }
    if (llGetInventoryType("RECIPES") == INVENTORY_NOTECARD)
    {
        ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
        integer l;
        for (l=0; l < llGetListLength(ltok); l++)
        {
            string line = llStringTrim(llList2String(ltok, l), STRING_TRIM);
            if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]" && line != "[END]")
            {
                names += [llStringTrim(llGetSubString(line,1,-2), STRING_TRIM)];
            }
        }
    }
    recipeNames = names;
    debug("RECIPES: " + llDumpList2String(names, "\n"));
}

setRecipe(string nm)
{
    recipeName = "";
    objectToGive = "";
    ingredients = [];
    timeToCook = default_timeToCook;
    rezzPosition = default_rezzPosition;
    sensorRadius = default_sensorRadius;
    if (nm == "")
    {
        return;
    }
    string ncData = osGetNotecard(PREFIX +"_RECIPES");
    if (llSubStringIndex(ncData, nm) == -1)
    {
        ncData = osGetNotecard("RECIPES");

        if (llSubStringIndex(ncData, nm) == -1)
        {
            status = "";
            llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND + ": " +nm);
            return;
        }
    }
    list ltok = llParseString2List(ncData, ["\n"], []);
    string stat = "SELECTEDRECIPE|" + nm + "|";
    integer rel = FALSE;
    integer l;
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llStringTrim(llList2String(ltok, l), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        {
            string name;
            if (!rel)
            {
                //skip lines till recipe is reached
                if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]")
                {
                    name = llStringTrim(llGetSubString(line,1,-2), STRING_TRIM);
                    if (name == nm)
                    {
                        rel = TRUE;
                        recipeName = name;
                    }
                }
            }
            else
            {
                //Notecard lines within the section of the selected recipe
                if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]")
                {
                    //finished reading relevant nc sections
                    //check values and launch "Adding" status
                    status = "Adding";
                    if (ingredients == [] || objectToGive == "")
                    {
                        llRegionSayTo(lastUser, 0, TXT_ERROR_READ);
                        status = "";
                        return;
                    }
                    llRegionSayTo(lastUser, 0, TXT_SELECTED_RECIPE + ": "+recipeName+ "\n"+ TXT_ADD_INGREDIENTS);
                    llMessageLinked(LINK_SET, 92, stat, "");
                    return;
                }
                //read key-value-pairs
                list tmp = llParseString2List(line, ["="], []);
                string tkey = llToUpper(llStringTrim(llList2String(tmp, 0), STRING_TRIM));
                string tval = llStringTrim(llList2String(tmp, -1), STRING_TRIM);
                stat += tkey + "|" + tval + "|";
                if (tkey == "DURATION") timeToCook = (integer)tval;
                else if (tkey == "INGREDIENTS") ingredients  = parseIngredients(tval);
                else if (tkey == "PRODUCT") objectToGive = tval;
                else if (tkey == "PRODUCT_PARAMS") objectParams= (string)tval; // Custom parameters to be passed to prod_gen
                else if (tkey == "TEXTURE") textureName = tval;
                else if (tkey == "REZ_POSITION") rezzPosition = (vector)tval;
                else if (tkey == "SENSOR_DISTANCE") sensorRadius = (integer)tval;
            }
        }
    }
    status = "";
    llRegionSayTo(lastUser, 0, TXT_ERROR_NOT_FOUND + ": " +nm);
}

list parseIngredients(string stringred)
{
    clickedButton = 0;
    haveIngredients = 0;
    list ing  = llParseString2List(stringred, [",", "+"], []);
    list ret = [];
    ingLength = llGetListLength(ing);
    integer i = ingLength;
    while (i--)
    {
        list possible = llParseString2List(llList2String(ing, i), [" or "], []);
        integer c = llGetListLength(possible);
        while (c--)
        {
            list itemper = llParseString2List(llList2String(possible, c), ["%"], []);
            integer perc;
            string item;
            if (llGetListLength(itemper) == 1)
            {
                perc = 100;
                item = llStringTrim(llList2String(possible, c), STRING_TRIM);
            }
            else
            {
                perc = llList2Integer(itemper, 0);
                item = llStringTrim(llList2String(itemper, 1), STRING_TRIM);
            }
            ret += [i, item, perc];
        }
    }
    return ret;
}

dlgIngredients(key u)
{
    lastUser = u;
    list opts = [];
    opts += [TXT_ABORT];

    string t = TXT_ADD;
    integer i = llGetListLength(ingredients) / 3;
    while (i--)
    {
        integer num = llList2Integer(ingredients, i*3);
        if ((~haveIngredients & (0x01 << num)) && (~clickedButton & (0x01 << num)))
        {
            opts +=  llList2String(ingredients, i*3 + 1);
            debug(llList2String(ingredients, i*3 + 1));
        }
    }
    if (llGetListLength(opts) > 1)
        multiPageMenu(u, t, opts);
    else
        checkListen(TRUE);
}

default
{

    object_rez(key id)
    {
        llSleep(0.4);
        messageObj(id, "INIT|" +PASSWORD +"|" +(string)lastUser +"|HEALTHPARAMS" +"|" +objectParams);
        // eg.    91  REZZED|a7bf5668-16eb-4138-8d3d-371bd60a303b|Sunshine smoothie|<0.807, 0.622, 0.130>|0.8|cube|
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id+"|"+recipeName+"|"+objectParams+"|", NULL_KEY);
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("listen:" + m);
        if (m == TXT_CLOSE)
        {
            //refresh();
        }
        else if ((m == TXT_ABORT ) || (m == NPC_ABORT))
        {
            recipeName = "";
            status = "";
            ingredients = [];
            setAnimations(0);
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");
            llUnSit(lastUser);
            llStopSound();
            llSetClickAction(CLICK_ACTION_TOUCH);
            integer findTxt = llListFindList(customText, [TXT_NO_PRODUCT+"\n  "+TXT_CHECKING +"\n "]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
            findTxt = llListFindList(customText, [TXT_NO_PRODUCT+"\n \n"]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
            refresh();
            llResetScript();
        }
        else if ((m == TXT_MAKE) || (m == NPC_MAKE) || (m == TXT_DO))
        {
            multiPageMenu(id, TXT_MENU, recipeNames);
            status = "Recipes";
            return;
        }
        else if (m == TXT_RESUME)
        {
            paused = FALSE;
            return;
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (status == "Recipes")
        {
            if (m == ">>")
            {
                startOffset += 10;
                multiPageMenu(id, TXT_MENU, recipeNames);
                return;
            }
            else
            {
                setRecipe(m);
                if (llGetInventoryType(objectToGive) != INVENTORY_OBJECT)
                {
                    llRegionSayTo(id, 0, TXT_CHECKING);
                    llMessageLinked(LINK_SET, 0, "GET_PRODUCT|" +PASSWORD +"|" +objectToGive, NULL_KEY);
                    customText += [TXT_NO_PRODUCT+"\n  "+TXT_CHECKING +"\n "];
                }
                refresh();
                debug("OUR_ENERGY="+llRound(energy) +" REQUIRED="  +llRound(timeToCook/energyRate));
                if (llRound(energy) >= llRound(timeToCook/energyRate) || (energy == -1) || (mustSit == FALSE))
                {
                    startOffset = 0;
                    dlgIngredients(id);
                    return;
                }
                else
                {
                    llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
                    llSetText(TXT_LOW_ENERGY +" : " + m, YELLOW, 1.0);
                    multiPageMenu(id, TXT_MENU, recipeNames);
                    llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|CQ");
                    return;
                }
            }
        }
        else if (status == "Adding")
        {
            if (m == ">>")
            {
                startOffset += 10;
                dlgIngredients(id);
                return;
            }

            lookingFor = "SF "+m;
            lookingForPercent = llList2Integer(ingredients, llListFindList(ingredients, [m]) + 1);

            llRegionSayTo(lastUser, 0, TXT_LOOKING_FOR +": " + lookingFor);
            llSensor(lookingFor , "",SCRIPTED,  sensorRadius, PI);
            refresh();
            return;
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        checkListen(TRUE);
    }

    dataserver(key k, string m)
    {
        debug("DATASERVER: " + m);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(tk,1) != PASSWORD) return;

        string cmd = llList2Key(tk,0);
        if (cmd == "INIT")
        {
            llSetObjectDesc((string)chan(llGetKey()));
            doReset = 2;
        }
        else if (cmd == "HEALTH")
        {
            if ((llList2String(tk, 2) == "ENERGY") && (llList2Key(tk, 3) == lastUser))
            {
                energy = llList2Integer(tk, 4);
                return;
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
                    ++saveNC;
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
        //
        else
        {
            //Add Ingredient
            integer found_pro = ingredientsListFindString(ingredients, cmd);
            integer i = llList2Integer(ingredients, found_pro);
            haveIngredients= haveIngredients | (0x01 << i);
            refresh();
        }
    }


    timer()
    {
        checkListen(FALSE);
        refresh();
    }

    touch_start(integer n)
    {
        key toucher = llDetectedKey(0);
        if (!(llSameGroup(toucher)  || osIsNpc(toucher)))
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
            return;
        }
        if (doReset == -1)
        {
            llRegionSayTo(toucher, 0, TXT_ERROR_LOCKED);
            return;
        }

        debug("touch_status=" +status);
        energy = -1;
        lastUser = toucher;
        if ((mustSit == TRUE) && (status == ""))
        {
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|CQ");
            llSleep(0.25);
        }

        list opts = [];
        string t = TXT_SELECT;
        if (status == "Adding")
        {
            startOffset = 0;
            clickedButton = 0;
            startListen();
            dlgIngredients(llDetectedKey(0));
            return;
        }
        else if (status == "Cooking")
        {
            opts += [TXT_ABORT, TXT_CLOSE];
        }
        else
        {
            opts += TXT_CLOSE;
            if (makeVerb == TRUE) opts += TXT_MAKE; else opts += TXT_DO;
            opts += customOptions;
        }
        opts += TXT_LANGUAGE;
        refresh();
        startListen();
        llDialog(toucher, t, opts, chan(llGetKey()));
    }

    sensor(integer n)
    {
        string name = llGetSubString(lookingFor, 3, -1);
        //get first product that has enough percent left
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (have_percent >= lookingForPercent || have_percent == 0)
            {
                ready_obj = llDetectedKey(c);
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llRegionSayTo(lastUser, 0, lookingFor+" " +TXT_NOT_FOUND_ENOUGH);
            dlgIngredients(lastUser);
            return;
        }
        messageObj( ready_obj,  "DIE|"+(string)llGetKey()+"|"+(string)lookingForPercent);
        //set button as pressed and launch menu again
        integer d = llList2Integer(ingredients, llListFindList(ingredients, [name]) - 1);
        clickedButton = clickedButton | (0x01 << d);
        startOffset = 0;
        dlgIngredients(lastUser);
    }

    no_sensor()
    {
        llRegionSayTo(lastUser, 0, lookingFor+" " +TXT_NOT_FOUND_ITEM100);
        dlgIngredients(lastUser);
    }

    state_entry()
    {
        llMessageLinked(LINK_SET,0, "PROGRESS", "");
        llSetClickAction(CLICK_ACTION_TOUCH);
        llSleep(2.0);
        energy =-1;
        //for updates
        if (llSubStringIndex(llGetObjectName(), "Update")>=0 || llSubStringIndex(llGetObjectName(), "Rezz")>=0)
        {
            string me = llGetScriptName();
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        //
        refresh();
        loadConfig();
        if (languageCode != "") loadLanguage(languageCode);
        getRecipeNames();
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (saveNC)
            {
                --saveNC;
            }
            else
            {
                getRecipeNames();
                loadConfig();
                customOptions = [];
                customText = [];
                llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
            }
        }

        if (status == "Cooking")
        {
            if (llGetObjectPrimCount(llGetKey()) != llGetNumberOfPrims())
            {
                llMessageLinked(LINK_SET,94, "SIT", "");
                setAnimations(1);
            }
            else
            {
                llMessageLinked(LINK_SET,94, "UNSIT", "");
                setAnimations(0);
            }
            refresh();
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
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
        else if (cmd == "SETRECIPE")
        {
            setRecipe(llList2String(tok, 1));
            refresh();
        }
        else if (cmd == "REZZEDPRODUCT")
        {
            llMessageLinked(LINK_SET, 91, "REZZED|"+llList2String(tok, 2)+"|"+recipeName+"|"+objectParams+"|", NULL_KEY);
        }
        else if (cmd == "PRODUCT_FOUND")
        {
            integer findTxt = llListFindList(customText, [TXT_NO_PRODUCT+"\n  "+TXT_CHECKING +"\n "]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
            findTxt = llListFindList(customText, [TXT_NO_PRODUCT+"\n \n"]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
            refresh();
        }
        else if (cmd == "NO_PRODUCT")
        {
            integer findTxt = llListFindList(customText, [TXT_NO_PRODUCT+"\n  "+TXT_CHECKING +"\n "]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
            customText += [TXT_NO_PRODUCT+"\n \n"];
            refresh();
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tok, 1);
            loadLanguage(languageCode);
            saveToDesc();
            refresh();
        }
    }
}
