// CHANGE LOG 
//  Added support fot NPC to play sounds - include them as firstName0  firstName1  firstName2   etc up to firstName5 
// farmer.lsl
// NPC Farmer for Satyr Farm
//  Part of the  SatyrFarm scripts.  This code is provided under a CC-BY-NC license
//  Mods by Cnayl Rainbow, hg.osgrid.org:80:mintor

// Used to check for updates from Quintonia product update server
float VERSION = 4.4;  // 15 February 2021
string NAME = "SF Farmer NPC";

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llSay(0, "DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}
// Can be overridden by config notecard
integer AUTO_REZ = 0;
integer CHATTY = TRUE;
integer doFX = TRUE;
integer RADIUS = 90;
integer ENABLE_COOKING = 1;
string  COOKED_STORE = "SF Fridge";
string  COOKED_ITEM = "SF Slop";
string  WATER_NAME = "SF Water";
list    INGREDIENTS = ["SF Potatoes", "SF Tomatoes", "SF Rice", "SF Apples"];
integer ENABLE_HARVESTING=1;
string  HARVEST_STORE = "SF Storage Rack";
string  SECONDARY_STORE = "SF Oast House";
list    SECONDARY_ITEMS = ["SF Barley", "SF Buckwheat", "SF Foxtail Millet", "SF Grain", "SF Oats"];
string  WELL = "SatyrFarm Well";
string  KITCHEN = "SatyrFarm Kitchen";
string  PROFILE="I help out around the farm, always on the go!  I tend to mostly talk to myself!";
string  firstName = "Farmer";
string  lastName = "NPC";
//
string languageCode = "";
string SUFFIX = "N1";
// Multilingual support
string TXT_YAY = "Yay!";
string TXT_GOING_TO ="Going to";
string TXT_STORAGE="This is storage...";
string TXT_ADDING="Adding";
string TXT_RIPE="This is Ripe!";
string TXT_EMPTY="This is empty";
string TXT_NEEDS_WATER="This needs water";
string TXT_CLEANUP="Cleaning up";
string TXT_CREATING="Creating npc.";
string TXT_WAITING="Waiting for npc ...";
string TXT_CONTROL="Touch to create / remove NPC";
string TXT_FOUND="NPC found!";
string TXT_READY="I am ready!";
string TXT_REZ_FENCE="Rez fence";
string TXT_REZZING_FENCE="Rezzing perimeter fence. Touch it to remove it.";
string TXT_NPC_SELECT = "Choose NPC";
string TXT_REZ_NPC="Rez NPC";
string TXT_REMOVE_NPC="Remove NPC";
string TXT_REMOVING="Removing npc";
string TXT_SAVE="Save Appearance";
string TXT_SAVED="Saved appearance";
string TXT_GET_NAME="What is the First name for this farmer?";
string TXT_ADD_IMAGE="'Ctrl Drag' an image onto me called";
string TXT_DEBUG="Debug";
string TXT_CLOSE="CLOSE";
string TXT_SELECT="Select";
string TXT_HELP="Help";
string TXT_HELP_MSG1="If you are having permission errors with the NPC in your region, it means you need to allow permissions for OSSL functions. You have to change the settings in your opensim.ini, or ask your sim host to change them for you. The settings you need to change are 'allow_osGetNotecard=true' and 'allow_osMessageObject=true'";
string TXT_HELP_MSG2="The NPC needs a Well within 96m from them. Occasionally they will also need to find a 'Kitchen', a 'Storage Rack' and a 'Fridge'";
string TXT_NPC_FARMER="NPC Farmer";
string TXT_ERROR_ITEMS = "Can't rez NPC as can't find the required farm items within range";
string TXT_ERROR_UPDATE = "Error, can not update as you are not my owner";
string TXT_LANGUAGE="@";
//
string PASSWORD = "*";
key masterKey;
key unpc = NULL_KEY;
key listenerKey;
key targetTree = NULL_KEY;
key lastTree;
string waitForItem;
key myWater = NULL_KEY;
key myPotatoes = NULL_KEY;
string myPotatoesName = "";
key mySlop = NULL_KEY;
string lastAnim;
integer tries;
integer running = 1;
integer walkTs;
string productName;
list TREENAMES = [];        // list of trees, plants & feeders to visit
list TREEPRODUCTS = [];     // list of items to plant
string postText;
string npcControllerName;
list treeLookup;
list myProducts;            // list of product Keys for main storage
list myProductsAlt;         // list of product Keys for secondary storage
string lookingFor;
list npcNames;
string status;
key toucher;

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

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    TREENAMES = [];
    TREEPRODUCTS= [];
    treeLookup = [];
    for (i=0; i < llGetListLength(lines); i++)
    {
        string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseStringKeepNulls(llList2String(lines,i), ["="], []);
            string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
            string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
            if (cmd == "LAST_NAME") lastName = val;
            else if (cmd == "RADIUS") RADIUS = (integer)val;
            else if (cmd == "CHATTY") CHATTY = (integer)val;
            else if (cmd == "SOUNDS") doFX = (integer)val;
            else if (cmd == "ENABLE_HARVESTING") ENABLE_HARVESTING = (integer)val;
            else if (cmd == "HARVEST_STORE") HARVEST_STORE = val;
            else if (cmd == "ENABLE_COOKING") ENABLE_COOKING = (integer)val;
            else if (cmd == "COOKED_ITEM") COOKED_ITEM = val;
            else if (cmd == "WATER_NAME") WATER_NAME = val;
            else if (cmd == "INGREDIENTS") INGREDIENTS = llParseStringKeepNulls(val, [","], [""]);
            else if (cmd == "COOKED_STORE") COOKED_STORE = val;
            else if (cmd == "SECONDARY_ITEMS") SECONDARY_ITEMS = llParseStringKeepNulls(val, [","], [""]);
            else if (cmd == "SECONDARY_STORE") SECONDARY_STORE = val;
            else if (cmd == "WELL") WELL = val;
            else if (cmd == "KITCHEN") KITCHEN = val;
            else if (cmd == "AUTO_REZ") AUTO_REZ = (integer)val;
            else if (cmd == "LANG") languageCode = val;
            else if (cmd == "PROFILE") PROFILE = val;
            else if (cmd == "TREE")
            {
                list tk = llParseStringKeepNulls(val, ["|"], []);
                integer  freq = llList2Integer(tk, 1);
                while(freq-- > 0) treeLookup += llGetListLength(TREENAMES);

                TREENAMES += llList2String(tk, 0);
                TREEPRODUCTS  += llList2String(tk, 2);
            }
        }
    }

    // load NPC config info
    npcNames = [];
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    for (i=0; i<count; i+=1)
    {
        if (llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, i), 0, 3) == "npc-")
        {
            npcNames += llGetSubString(llGetInventoryName(INVENTORY_NOTECARD, i), 4, -1);
        }
    }
    firstName = llList2String(npcNames, 0);
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "N")
    {
        languageCode = llList2String(desc, 1);
        // npc UUID = llList2Integer(desc, 2);
        firstName = llList2String(desc, 3);
    }
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
                        if (cmd == "TXT_YAY") TXT_YAY = val;
                    else if (cmd == "TXT_GOING_TO") TXT_GOING_TO = val;
                    else if (cmd == "TXT_STORAGE") TXT_STORAGE = val;
                    else if (cmd == "TXT_ADDING") TXT_ADDING = val;
                    else if (cmd == "TXT_RIPE") TXT_RIPE = val;
                    else if (cmd == "TXT_EMPTY") TXT_EMPTY = val;
                    else if (cmd == "TXT_NEEDS_WATER") TXT_NEEDS_WATER = val;
                    else if (cmd == "TXT_CLEANUP") TXT_CLEANUP = val;
                    else if (cmd == "TXT_CREATING") TXT_CREATING = val;
                    else if (cmd == "TXT_WAITING") TXT_WAITING = val;
                    else if (cmd == "TXT_CONTROL") TXT_CONTROL = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_READY") TXT_READY = val;
                    else if (cmd == "TXT_REZ_FENCE") TXT_REZ_FENCE = val;
                    else if (cmd == "TXT_REZZING_FENCE") TXT_REZZING_FENCE = val;
                    else if (cmd == "TXT_REZ_NPC") TXT_REZ_NPC = val;
                    else if (cmd == "TXT_REMOVE_NPC") TXT_REMOVE_NPC = val;
                    else if (cmd == "TXT_REMOVING") TXT_REMOVING = val;
                    else if (cmd == "TXT_SAVE") TXT_SAVE = val;
                    else if (cmd == "TXT_SAVED") TXT_SAVED = val;
                    else if (cmd == "TXT_GET_NAME") TXT_GET_NAME = val;
                    else if (cmd == "TXT_ADD_IMAGE") TXT_ADD_IMAGE = val;
                    else if (cmd == "TXT_DEBUG") TXT_DEBUG = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_HELP") TXT_HELP = val;
                    else if (cmd == "TXT_HELP_MSG1") TXT_HELP_MSG1 = val;
                    else if (cmd == "TXT_HELP_MSG2") TXT_HELP_MSG2 = val;
                    else if (cmd == "TXT_NPC_FARMER") TXT_NPC_FARMER = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_ITEMS") TXT_ERROR_ITEMS = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

integer startOffset=0;

multiPageMenu(key id, string message, list opt)
{
    integer l = llGetListLength(opt);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, [TXT_CLOSE]+opt, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(opt, startOffset, startOffset + 9);
    llDialog(id, message, [TXT_CLOSE]+its+[">>"], ch);
}

list objProps(key id)
{
    return llParseStringKeepNulls( llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0),  [";"], []);
}

float walkTime(vector p , vector v)
{
    return llVecDist(p,  v) * .5 + 2;;
}

doWalk(vector v)
{
    if (unpc==NULL_KEY) return;
    osNpcStopMoveToTarget(unpc);
    osSetSpeed(unpc, 0.5); // slow
    vector pos = osNpcGetPos(unpc);
    vector tgt = v - 2.0*llVecNorm(v-pos) + <0,0,.5>;
    osNpcMoveToTarget(unpc, tgt  , OS_NPC_NO_FLY );
    integer wt = (integer) walkTime(pos, v);
    walkTs = llGetUnixTime() + wt;
    llSetTimerEvent(5);
}

anim(string an)
{
    osNpcStopAnimation(unpc, lastAnim);
    lastAnim = an;
    osNpcPlayAnimation(unpc, lastAnim);
}

sound()
{
    if (doFX == TRUE)
    {
        string fn = firstName+(string)llFloor(llFrand(6));
        fn = llToLower(fn);     
        if (llGetInventoryType(fn) == INVENTORY_SOUND)
        {
            if (llKey2Name(listenerKey) != "") osMessageObject(listenerKey, "TRIGGERSOUND|"+(string)llGetInventoryKey(fn)+ "|1.0");
        }
    }
}

doTouch(key u)
{
    debug("doTouch:" + (string)u);
    osNpcTouch(unpc, u, LINK_THIS);
}

whisper(string w)
{
   osNpcWhisper(unpc,0 , w);
}

say(string w)
{
    if (CHATTY == TRUE)
    {
        osNpcSay(unpc, w);
    }
    sound();
}

chanSay(integer c, string w)
{
    say(">> "+w);
    osNpcSay(unpc, c, w);
}

msgListener(string m)
{
    if (llKey2Name(listenerKey) != "")
        osMessageObject(listenerKey,m);
}

handleTree(key u)
{
    string device = llKey2Name(u);
    debug("handleTree_device='" + device +"'\nmySlop:'" +(string)mySlop +"'\nMyProducts=" + llDumpList2String(myProducts, "|") + "\nMyProductsAlt=" + llDumpList2String(myProductsAlt, "|"));

    if ((device == COOKED_STORE) && (mySlop != NULL_KEY))
    {
        doTouch(u);
        llSleep(1);
        chanSay(chan(u), "Add Product");
        llSleep(1);
        chanSay(chan(u), "Slop");
        llSleep(1);
        mySlop = NULL_KEY;
    }
    else if (device == HARVEST_STORE)
    {
        if (llGetListLength(myProducts)>0 )
        {
            say(TXT_STORAGE);
            integer ip;
            for (ip=0; ip < llGetListLength(myProducts); ip++)
            {
                doTouch(u);
                say(TXT_ADDING+" "+llKey2Name( llList2Key(myProducts,ip)));
                llSleep(1.);
                chanSay(chan(u), "Add Product");
                llSleep(1.);
                chanSay(chan(u), llGetSubString( llKey2Name( llList2Key(myProducts,ip)), 3, -1) ); // Product name
                llSleep(2.);
            }
            myProducts = [];
        }
    }
    else if (device == SECONDARY_STORE)
    {
        if (llGetListLength(myProductsAlt)>0 )
        {
            say(TXT_STORAGE);
            integer ip;
            for (ip=0; ip < llGetListLength(myProductsAlt); ip++)
            {
                doTouch(u);
                say(TXT_ADDING+" "+llKey2Name( llList2Key(myProductsAlt,ip)));
                llSleep(1.);
                chanSay(chan(u), "Add Product");
                llSleep(1.);
                chanSay(chan(u), llGetSubString( llKey2Name( llList2Key(myProductsAlt,ip)), 3, -1) ); // Product name
                llSleep(2.);
            }
            myProductsAlt = [];
        }
    }
    else if (device == WELL)
    {
        if (myWater == NULL_KEY)
        {
            doTouch(u);
            llSleep(1);
            tries = 2;
            waitForItem = WATER_NAME;
            llSetTimerEvent(5);
        }
    }
    else if (device == KITCHEN)
    {
        if (myWater != NULL_KEY && myPotatoes != NULL_KEY)
        {
            llSetTimerEvent(0);
            doTouch(u);
            llSleep(1);
            chanSay(chan(u), "ABORT"); // Just in case
            llSleep(1);
            doTouch(u);
            llSleep(1);
            chanSay(chan(u), "Make...");
            llSleep(1);
            doTouch(u);
            llSleep(1);
            chanSay(chan(u), "Slop");
            llSleep(1);
            doTouch(u);
            llSleep(1);
            chanSay(chan(u), myPotatoesName);
            llSleep(1);
            doTouch(u);
            llSleep(2);
            chanSay(chan(u), "Water");
            llSleep(1);
            anim("clap");
            walkTs = llGetUnixTime() + 110;
            llSetTimerEvent(5);
            tries = 10;
            waitForItem = COOKED_ITEM;
            myWater = NULL_KEY;
            myPotatoes = NULL_KEY;
        }
    }
    else
    {
        list p = objProps(u);
     //   llOwnerSay("This is "+llList2String(p,2)+" ...");
        if (ENABLE_HARVESTING && llList2String(p,0) == "T" && llList2String(p,2) == "Ripe")
        {
            say (TXT_RIPE);
            productName = llList2String(p,1);
            doTouch(u);
            llSleep(1.);
            chanSay(chan(u), "Harvest");
            llSetTimerEvent(10);
            tries = 2;
            waitForItem = productName;
        }
        else if (llList2String(p,0) == "T" && llList2String(p,2) == "Empty")
        {
            string what = "Olive Tree";
            say (TXT_EMPTY);
            integer idx = llListFindList(TREENAMES, [llKey2Name(u)]);
            if (idx>=0)
            {
                list pr = llParseString2List( llList2String(TREEPRODUCTS, idx) , [","], []);
                what = llStringTrim(llList2String(pr, (integer)llFrand(llGetListLength(pr)) ), STRING_TRIM);
            }
            if (what !="")
            {
                doTouch(u);
                llSleep(1.);
                chanSay(chan(u), "Plant");
                llSleep(1.);
                chanSay(chan(u), what);
                llSleep(1.);
            }
       }
       else if (llList2String(p,0) == "F" && llList2Integer(p,2) <30) // Feeder
       {
           if (myWater != NULL_KEY)
           {
                say(TXT_NEEDS_WATER);
                myWater = NULL_KEY;
                doTouch(u);
                llSleep(1.);
                chanSay(chan(u), "Add Water");
                llSleep(2.);
           }
       }
       else if (llList2String(p,0) == "T" && llList2Integer(p,4) <30)  // Plant
       {
           if (myWater != NULL_KEY)
           {
                say(TXT_NEEDS_WATER);
                myWater = NULL_KEY;
                doTouch(u);
                llSleep(1.);
                chanSay(chan(u), "Water");
                llSleep(2.);
           }
       }
    }
}

doCleanup()
{
    llSay(0, TXT_CLEANUP);
    if (myWater != NULL_KEY)
    {
        osMessageObject(myWater, "DIE|"+(string)llGetKey());
        myWater = NULL_KEY;
    }

    if (myPotatoes!= NULL_KEY)
    {
        osMessageObject(myPotatoes, "DIE|"+(string)llGetKey());
        myPotatoes = NULL_KEY;
    }
    if (mySlop!= NULL_KEY)
    {
        osMessageObject(mySlop, "DIE|"+(string)llGetKey());
        mySlop= NULL_KEY;
    }
}

doRezNpc()
{
    // Load settings from description
    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "N")
    {
        osNpcRemove(llList2Key(desc, 2));
    }
    else
    {
        osNpcRemove((key)llGetObjectDesc());
    }
    llSay(0, TXT_CREATING);
    llSetObjectName("SF NPC Controller");
    llSleep(1.);
    unpc = osNpcCreate(firstName, lastName,  llGetPos()+<2,0,1>, "npc-"+firstName,  8);  // 8 = OS_NPC_GROUP
    llSay(0, TXT_WAITING);
    llSetObjectDesc("N;" + languageCode + ";" + (string)unpc + ";" +firstName);
    osNpcSetProfileAbout(unpc, PROFILE);
    osNpcSetProfileImage(unpc, "image-"+firstName);
    llSetColor(<0,1,0>, ALL_SIDES);
    llSetTexture("image-"+firstName, 0);
    llSetColor(<1,1,1>,0);
}

doWander(integer forceAway)
{
        string rand;
        lookingFor = "";
        if  (mySlop != NULL_KEY)
        {
            lookingFor = COOKED_STORE;
        }
        else if (myWater == NULL_KEY)
        {
            lookingFor = WELL;
        }
        else if (myWater != NULL_KEY && myPotatoes != NULL_KEY)
        {
            lookingFor = KITCHEN;
        }
        else if (llGetListLength(myProducts)>0)
        {
            lookingFor = HARVEST_STORE;
        }
        else if (llGetListLength(myProductsAlt)>0)
        {
            lookingFor = SECONDARY_STORE;
        }

        if (lookingFor == "" || forceAway)
        {
            integer idx = llList2Integer(treeLookup,  (integer)llFrand(llGetListLength(treeLookup)));
            lookingFor = llList2String(TREENAMES, idx);
        }

        msgListener("SENSOR|"+lookingFor+"|"+(string)RADIUS+"|"+(string)PI);
}

string qsFixPrecision(float input, integer precision)
{
    precision = precision - 7 - (precision < 1);
    if(precision < 0)
        return llGetSubString((string)input, 0, precision);
    return (string)input;
}

string showVer()
{
    return qsFixPrecision(VERSION, 2);        
}

default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        masterKey = llGetOwner();
        llSay(0, TXT_CONTROL);
        llSetText(TXT_NPC_FARMER +"\n" + firstName + " " + lastName, <1,1,1>, 0.5);
        llSetColor(<0.65, 0.00, 0.00>, ALL_SIDES);
        llSetTexture("npc-image", 0);
        llSetColor(<1,1,1>,0);
    }

    dataserver(key kk, string m)
    {
        debug("dataserver: " + m + " key " +(string)kk);
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2Key(tk,0);

        if (cmd == "SENSOR")
        {
            integer i;
            key u;
            if (waitForItem != "")
            {
                // Found a product
                string name = llKey2Name( llList2Key(tk, 1) );
                if (name == waitForItem)
                {
                    osNpcTouch(unpc, llList2Key(tk,1), LINK_THIS);
                    anim("fist_pump");
                    say(TXT_YAY);
                    if (name == WATER_NAME)
                    {
                        myWater = llList2Key(tk, 1);
                    }
                    // else if (ENABLE_COOKING && (name == "SF Potatoes" || name == "SF Tomatoes" || name == "SF Rice" || name == "SF Apples"))
                    else if (ENABLE_COOKING && (llListFindList(INGREDIENTS, [name]) != -1))
                    {
                        myPotatoes = llList2Key(tk, 1);
                        myPotatoesName = llGetSubString( name, 3, -1);
                    }
                    else if (llKey2Name( llList2Key(tk, 1) ) == COOKED_ITEM)
                    {
                        mySlop = llList2Key(tk, 1);
                    }
                    else  // Should be harvest item
                    {
                        string crop = llKey2Name(llList2Key(tk, 1));
                        if (llListFindList(SECONDARY_ITEMS, [crop]) != -1) myProductsAlt += llList2Key(tk, 1); else myProducts += llList2Key(tk, 1);
                        debug(llDumpList2String("Crop:" + crop + "\nAlt:" +myProductsAlt, "|") + "\nMain:" + llDumpList2String(myProducts, "|"));
                    }
                }
                waitForItem = "";
            }
            else  // List of possible targets
            {
                integer idx = 1+ (integer)llFrand( llGetListLength(tk)-1);
                u = llList2Key(tk, idx);
                if (u != NULL_KEY)
                {
                    say(TXT_GOING_TO +": "+llKey2Name(u));
                    targetTree = u;
                    vector v = llList2Vector( llGetObjectDetails(u , [OBJECT_POS]), 0);
                    v += <0,0,0>;
                    doWalk(v);
                }
                else
                    llOwnerSay("ERROR-This should never happen!");
            }
        }
        else if (cmd == "LISTENERKEY")
        {
            listenerKey = llList2Key(tk, 1);
            key npcSender = llList2Key(tk, 2);
            if (npcSender == unpc)
            {
                llSay(0, TXT_FOUND);
                osMessageObject(listenerKey, "CONTROLLERKEY|"+(string)llGetKey());
                osMessageObject(listenerKey, "SETRADIUS|"+(string)RADIUS);
                anim("backflip");
                say(TXT_READY);
                npcControllerName = "SF NPC-" + firstName + " Controller";
                llSetObjectName(npcControllerName);
                llSetTimerEvent(4);
            }
        }
        else if (cmd == "NOSENSE")
        {
            /* Something expected was not found */
            anim("backflip");
            if (waitForItem != "")
            {
                if (tries--<=0)
                {
                   // say("I can't find the "+waitForItem+". Giving up!");
                    waitForItem = "";
                }
                llSetTimerEvent(5);
                return;
            }
            else
            {
                if (lookingFor != "")
                {
                //    say("I can't find a "+lookingFor+" around here, I will go somewhere else.");
                    targetTree = NULL_KEY;
                }
                doWander(TRUE);
            }
        }
        // for updates
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
            osMessageObject(llList2Key(tk, 2), answer);
            //Send a message to other prim with script
            osMessageObject(llGetLinkKey(3), "VERSION-CHECK|" + PASSWORD + "|" + llList2String(tk, 2));
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(kk) != llGetOwner())
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
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("listen: " + m + " from " +(string)id);
        if (m == TXT_CLOSE)
        {
            status = "";
        }
        else if (m == TXT_REZ_FENCE)
        {
            llSay(0, TXT_REZZING_FENCE);
            llRezObject("fence", llGetPos() + <0.0,0.0,-0.5>, <0.0,0.0,0.0>, <0.0,0.0,0.0,1.0>, RADIUS*2);
            doWander(TRUE);
            return;
        }
        else if (m == TXT_REZ_NPC)
        {
            // First check there is a well close by before rezzing farmer
            status = "waitWell";
            llSensor(WELL, "", SCRIPTED, RADIUS, PI);
        }
        else if (m ==TXT_SAVE)
        {
            llTextBox(toucher, TXT_GET_NAME, chan(llGetKey()));
            status = "getName";
        }
        else if (m == TXT_HELP)
        {
            llSay(0, TXT_HELP_MSG1);
            llSay(0, TXT_HELP_MSG2);
        }
        else if (m == TXT_REMOVE_NPC)
        {
            llSay(0, TXT_REMOVING);
            llSetTimerEvent(0);
            running = 0;
            doCleanup();
            osNpcRemove(unpc);
            unpc = NULL_KEY;
            llSleep(1);
            llSetObjectDesc("N;" + languageCode +";" +";"+firstName);
            llResetScript();
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else if (m == TXT_DEBUG)
        {
            llOwnerSay("waitForItem="+waitForItem+" targetTree="+(string)targetTree+" lookingFor="+lookingFor+" listenerKey=" + (string)listenerKey);
            llOwnerSay(llList2CSV(TREENAMES));
            llOwnerSay(llList2CSV(TREEPRODUCTS));
            llOwnerSay("V:" + showVer());
        }
        else if (m == TXT_NPC_SELECT)
        {
            llSetTimerEvent(300);
            startListen();
            status = "npcSelect";
            multiPageMenu(toucher, "\n"+TXT_SELECT, npcNames);
        }
        else if (m ==">>")
        {
            startOffset += 10;
            multiPageMenu(id, "\n"+TXT_SELECT, npcNames);
        }
        else if (status == "npcSelect")
        {
            firstName = m;
            status = "";
            if (llGetInventoryType("image-"+firstName) == INVENTORY_NONE)
            {
                llSetTexture("image-Default", 0);
            }
            else
            {
                llSetTexture("image-"+firstName, 0);
            }
            llSetText(TXT_NPC_FARMER+"\n" + firstName + " " + lastName, <1,1,1>, 0.5);
            // Save settings to description
            llSetObjectDesc("N;" + languageCode + ";" + (string)unpc + ";" +firstName);
        }
        else if (status == "getName")
        {
            status = "";
            osAgentSaveAppearance(toucher, "npc-"+m);
            llRegionSayTo(toucher, 0, TXT_SAVED + ": " + m + "\n" + TXT_ADD_IMAGE + " image-"+m);
        }
    }

    touch_start(integer n)
    {
        toucher = llDetectedKey(0);
        if (toucher != masterKey) return;
        list opts = [];
        opts += TXT_HELP;
        opts += TXT_DEBUG;
        opts += TXT_CLOSE;
        opts += TXT_REZ_FENCE;
        opts += TXT_SAVE;
        opts += TXT_LANGUAGE;
        if (unpc != NULL_KEY)
        {
            opts += TXT_REMOVE_NPC;
        }
        else
        {
            opts += TXT_REZ_NPC;
            opts += TXT_NPC_SELECT;
        }
        llSetTimerEvent(300);
        startListen();
        llDialog(toucher,  llGetObjectName() +  " V:"+showVer()+"\n \n" +TXT_SELECT, opts, chan(llGetKey()));
    }

    timer()
    {
        integer ts = llGetUnixTime();
        if (ts > listenTs + 200)
        {
            checkListen();
        }

        if ( running && (ts > walkTs + 1) && (unpc != NULL_KEY))
        {
            if (waitForItem != "") // Wait for item to appear
            {
                debug("waitForItem=" +waitForItem);
                msgListener("SENSOR|"+waitForItem+"|10|"+(string)PI );
                return;
            }

            if (targetTree != NULL_KEY ) // we are supposed to reach a target
            {
                if (llKey2Name(targetTree) != "")
                {
                    vector v = llList2Vector(llGetObjectDetails(targetTree, [OBJECT_POS]), 0);
                    if (llVecDist( osNpcGetPos(unpc), v) < 5)
                    {
                        anim("point_you");
                        handleTree(targetTree);
                    }
                    else
                    {
                        anim("express_shrug");
                    }
                    if (llFrand(1.)<.5) 
                    {
                       sound();
                    }
                }
                targetTree = NULL_KEY;
                llSetTimerEvent(5);
                return;
            }

            doWander(FALSE);
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetText(TXT_NPC_FARMER+"\n" + firstName + " " + lastName, <1,1,1>, 0.5);
            // Save settings to description
            llSetObjectDesc("N;" + languageCode + ";" + (string)unpc + ";" +firstName);
        }
    }

    sensor(integer index)
    {
        if (status == "waitWell")
        {
            status = "waitTree";
            // found a well so now check there is a 'tree' also near by
            llSensor(llList2String(TREENAMES,0), "", SCRIPTED, RADIUS, PI);
        }
        else if (status == "waitTree")
        {
            //found both well and tree so okay to rez NPC
            doRezNpc();
        }
    }

    no_sensor()
    {
        //DANGER! No well so NPC wont work!
        string missing;
        if (status == "waitWell") missing = WELL; else missing = llList2String(TREENAMES,0);
        llRegionSayTo(toucher, 0, TXT_ERROR_ITEMS +" (" + RADIUS + "m radius" +") : " + missing);
    }

    changed (integer c)
    {
        if (c & CHANGED_INVENTORY)
        {
            llResetScript();
        }

        if (c & (CHANGED_REGION_START | CHANGED_OWNER | CHANGED_REGION))
        {
            if (AUTO_REZ)
            {
                doCleanup();
                doRezNpc();
            }
        }
    }
}
