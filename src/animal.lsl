// CHANGE LOG
//  State is now saved to a notecard as primary backup. Still uses description for legacy support but some newer params may get lost due to length limit of desc.
//  Added config options for manure (time and product)
//  Added extra config for FEMALE_SCALE so this way you can adjust all scales to get overall size of animals to your liking
//  Added new menu option to allow adjusting adult scale
//  Added multilingual support for animal responses to petting (TXT_PET_RESPONSEn)
//  integer AN_AUTO_POO     = 0;     // if 1, animal will rez poo when ready, if 0 then farmer needs to collect it.
//  Added pet heaven feature
//  Added support to make animal a pet and pet to animal
//  When mated wasn't sending correct HEALTH message to users HUD
//  Added new config option to specifiy if animal or human
//  If being touched by owner, won't bother to check is same group
//  Added sleep mode option

// animal.lsl
// Part of the  SatyrFarm scripts.  This code is provided under a CC-BY-NC license
// Mods by Cnayl Rainbow, hg.osgrid.org:80:Aquino
//
// NOTE: Versions before 4.1 can't be easily upgraded to version 5 due to all sorts of hardware differences
float    VERSION = 5.6;    // 5.6-RC-1214   (14 December 2020)
integer  RSTATE  = -1;     // RSTATE = 1 for release, 0 for beta, -1 for Release candidate
//
integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

vector   GREEN   = <0.180, 0.800, 0.251>;
vector   RED     = <1.000, 0.255, 0.212>;
vector   WHITE   = <1.000, 1.000, 1.000>;
vector   BLACK   = <0.000, 0.000, 0.000>;
vector   AQUA    = <0.498, 0.859, 1.000>;
vector   PINK    = <0.941, 0.071, 0.745>;
vector   BROWN   = <0.365, 0.312, 0.228>;
vector   PURPLE  = <0.790, 0.578, 1.000>;

// Set default config values - these can be overwritten by settings in 'an_config' notecard
string   AN_NAME             = "Animal";            //
string   SURFACE             = "flat";              // Read from config but assume flat if not ground or water
integer  FLOAT_PRIM          = 1;                   // For water animals, prim to set to water level
integer  CHATTY              = 1;                   // Animal can be 'Chatty, 'No chat', 'Silent' which is represented by  1, 0, -1
integer  SLEEP_MODE          = 0;                   // Set to 1 to have animal sleep at night (i.e. stay in down position and no sounds or chat)
integer  IMMOBILE            = 0;                   // Assume animal will move about
integer  RADIUS              = 10;                  // Assume 10m walk radius
string   AN_FEEDER           = "SF Animal Feeder";  //
string   AN_BAAH             = "Ah";                //
integer  AN_HASGENES         = 0;                   // 1 if animal passes genes through mating
integer  AN_HASMILK          = 0;                   // 1 if gives milk
integer  MILKTIME            = 86400;               //
string   MILK_OBJECT         = "SF Milk";           //
integer  AN_HASWOOL          = 0;                   // 1 if gives 'wool' product
integer  WOOLTIME            = 345600;              //
string   WOOL_OBJECT         = "SF Wool";           // Could also be feathers, crystals etc!
integer  AN_HASMANURE        = 0;                   // 1 if gives manure
integer  AN_AUTO_POO         = 0;                   // if 1, animal will rez poo when ready, if 0 then farmer needs to collect it.
integer  MANURETIME          = 172800;              //
string   MANURE_OBJECT       = "SF Manure";         //
integer  LAYS_EGG            = 0;                   // Reproduces with egg
integer  EGG_TIME            = 86400;               // Time until hatching
string   MEAT_OBJECT         = "SF Meat";           //
string   SKIN_OBJECT         = "SF Skin";           //
integer  MATE_INTERVAL       = 86400;               // how often to be mateable
float    CHILD_SCALE         = 0.5;                 // Initial scale as child
float    CHILD_MAX_SCALE     = 1.0;                 // Dont let the child grow beyond this scale
float    MALE_SCALE          = 1.05;                //
float    FEMALE_SCALE        = 1.00;                //
float    STEP_SIZE           = 0.4;                 //
float    CHILDHOOD_RATIO     = 0.15;                // How much of life to spend as child
list     ADULT_MALE_PRIMS    = [];                  //
list     ADULT_FEMALE_PRIMS  = [];                  // link numbers - Both sexes
list     ADULT_RANDOM_PRIMS  = [];                  // show randomly
list     CHILD_PRIMS         = [];                  // children only
integer  MULTI_SKIN          = 0;                   // Set to 1 if animal skin genetics uses different textures per prim
integer  LIFETIME            = 2592000;             //
float    WATERTIME           = 5000.0;              //
float    FEEDTIME            = 5900.0;              //
integer  PREGNANT_TIME       = 432000;              //
float    FEEDAMOUNT          = 1.0;                 //
float    WATERAMOUNT         = 1.0;                 //
integer  TOTAL_ADULTSOUNDS   = 4;                   //
integer  TOTAL_BABYSOUNDS    = 2;                   //
integer  TOUCH_ACTIVE        = TRUE;                // TOUCH_ACTIVE=1      Set to 0 if touch is handled by another script e.g. baby
integer  isHuman             = FALSE;               // HUMAN=0
string   languageCode        = "en-GB";             // LANG=en-GB
// END CONFIG NOTECARD //
//
// LANGUAGE NOTECARD DEFAULTS //
string   TXT_ADULTS_GIVE="Adults give ";
string   TXT_ALLOW_WALK="Allow walking";
string   TXT_ANIMAL_VERSION="Animal version";
string   TXT_AUTO_MANURE="AutoManure";
string   TXT_BUTCHER="Butcher";
string   TXT_CHATTY="Chatty";
string   TXT_CHILD="Child";
string   TXT_CLOSE="CLOSE";
string   TXT_DAYS="days";
string   TXT_DAYS_OLD="days old";
string   TXT_DEAD="DEAD";
string   TXT_DEHYDRATION="Death caused by dehydration";
string   TXT_DRINK="Aaah, refreshing!";
string   TXT_EAT="Yum yum, food!";
string   TXT_EAT_FROM=" and I eat from ";
string   TXT_EGG="Egg";
string   TXT_EGGS="Eggs";
string   TXT_EGGS_READY="Eggs ready";
string   TXT_ERROR_GROUP="Error, we are not in the same group";
string   TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string   TXT_EVERY="every";
string   TXT_FEMALE="Female";
string   TXT_FEMALES_GIVE="The females of my species give ";
string   TXT_FLAT="Flat";
string   TXT_FLOAT_FULL="Full text";
string   TXT_FLOAT_NONE="No text";
string   TXT_FLOAT_SHORT="Short text";
string   TXT_FLOAT_TEXT="Float text...";
string   TXT_FOLLOW_ME="Follow Me";
string   TXT_FOOD="FOOD";
string   TXT_GAVE_BIRTH="I had a baby!";
string   TXT_GET_="Get";
string   TXT_GET_MANURE="Get Manure";
string   TXT_GET_EGGS="Get eggs";
string   TXT_GIVE_MANURE="Here is my bag of shit!";
string   TXT_GOODBYE="Goodbye, cruel world...";
string   TXT_GREET_EGG="Hello! I 'm just an egg";
string   TXT_GREET_YOU="Hello! My name is";
string   TXT_GROUND="Ground";
string   TXT_HAPPY="Happy!";
string   TXT_HELLO="Hello!";
string   TXT_INFO="Info";
string   TXT_HERE_IS="Here is your";
string   TXT_HOURS="hours";
string   TXT_HUNGRY="HUNGRY";
string   TXT_HUNGER="I'm hungry!";
string   TXT_HUNGRY_THIRSTY="I'm hungry and thirsty!";
string   TXT_I_AM="I am a";
string   TXT_INCUBATING="Incubating...";
string   TXT_INFO_MSG="Visit https://quintonia.net/forum for more information.";
string   TXT_LAID_EGG="I laid an egg!";
string   TXT_LIVES="On average, we live";
string   TXT_MENU_MAIN="MAIN MENU";
string   TXT_MALE="Male";
string   TXT_MANURE_READY="Manure ready";
string   TXT_MATE="Mate";
string   TXT_MATE_ERROR1="Sorry, I'm still a child...";
string   TXT_MATE_ERROR2="Sorry, no males near me...";
string   TXT_NO_SPEAK="Animal won't speak";
string   TXT_NOT_HAPPY="No, I'm not happy";
string   TXT_OK_FLAT="Okay, I'll walk flat at whatever level I'm at now";
string   TXT_OK_GROUND="Okay, I'll walk along the ground";
string   TXT_OK_WATER="Okay, I'll stick to the water level";
string   TXT_OLD_AGE="Death caused by Old age";
string   TXT_OPTIONS="Options";
string   TXT_PET="Pet";
string   TXT_PET_RESPONSE1="I love you too, %NAME%!";
string   TXT_PET_RESPONSE2="Good good, master %NAME%";
string   TXT_PET_RESPONSE3="I'm happy now";
string   TXT_PET_RESPONSE4="Back at ya %NAME%";
string   TXT_PREGNANCY="Pregnancy lasts";
string   TXT_PREGNANT="PREGNANT!";
string   TXT_RANGE="Range";
string   TXT_RESETTING="Resetting animal..";
string   TXT_RESPONSE_MOVE="Alright, I won't go further than";
string   TXT_REZ="Rez";
string   TXT_SELECT="Select";
string   TXT_SELECT_SURFACE="Select walking type. Currently it is:";
string   TXT_SET_NAME="Set Name";
string   TXT_SETNAME_TO="Set name to:";
string   TXT_SPEAK="Animal will speak now";
string   TXT_STARVATION="Death caused by starvation";
string   TXT_HOME="Home";
string   TXT_HOME_REPLY="OK, home point set";
string   TXT_STOP="STOP";
string   TXT_STOP_REPLY="Thanks for the walk!";
string   TXT_THIRSTY="THIRSTY";
string   TXT_THIRST="I'm thirsty!";
string   TXT_UPDATE="Update";
string   TXT_UPDATE_REMOVE="Removing myself for update.";
string   TXT_WALK_OFF="Walking Off";
string   TXT_WALK_ON="Walking On";
string   TXT_WALK_ON_WHAT="Walk on...";
string   TXT_WATER="Water";
string   TXT_READY="ready";
string   TXT_NO_WATER="Help, please put me on some water!";
string   TXT_WOOL="Wool";
string   TXT_WOOL_READY="Wool ready";
string   TXT_GIVE_WOOL="Finally! I thought you'd never give me a haircut!";
string   TXT_MILK="Milk";
string   TXT_MILK_READY="Milk ready";
string   TXT_GIVE_MILK="Here is your milk";
string   TXT_LOW_ENERGY="Not enough energy for task";
string   TXT_SLEEP_MODE = "Sleeping";
string   TXT_SOUNDS = "Sounds";
string   TXT_QUIET = "No chat";
string   TXT_SILENT = "Silent";
string   TXT_SILENT_MODE = "Animal won't make any noises";
string   TXT_SLEEPING = "Animal is sleeping";
string   TXT_SCALE="Adjust Scale";
string   TXT_SET_SCALE="Set scale factor - Currently";
string   TXT_SET_RANGE="Set Walking range (meters) - Currently";
string   TXT_ON="ON";
string   TXT_OFF="OFF";
string   TXT_LANGUAGE="@";
string   TXT_FEMALE_SYMBOL="f";
string   TXT_MALE_SYMBOL="m";
//
string   SUFFIX;
list     colorable = [];
list     petResponses;
float    happy = 100.;
string   PASSWORD = "*";
integer  FARM_CHANNEL = -911201;
string   statusNC = "an_statusNC";
integer  deathFlags = 0;
integer  lastEggTs;
string   name;

integer  lifeTime;
integer  geneA=1;
integer  geneB=1;
integer  fatherGene;
list     rest;
list     walkl;
list     walkr;
list     eat;
list     down;
list     link_scales;
vector   initpos = ZERO_VECTOR;
integer  lastTs;
integer  createdTs;
integer  milkTs;
integer  woolTs;
integer  manureTs;
integer  labelType = 0; // 0= Long  1== short  2== off
float    food = 55.0;
float    water = 55.0;
string   status = "OK";
string   sex;        //  0 = "Male"  1 = "Female"
integer  sexToggle;
integer  lastSex;
integer  epoch = 0; // 0 = Egg, 1= Baby, 2 = Adult
integer  left;
key      followUser = NULL_KEY;
key      lastUser;
integer  pregnantTs;
integer  givenBirth =0;
string   fatherName;
integer  age;
integer  habitat;
integer  lifeFactor = 25;
float    scaleFactor = 1.0;
integer  isPet;
integer  feedPet;
integer  isAttached = FALSE;
rotation savedRot = ZERO_ROTATION;
vector   savedPos = ZERO_VECTOR;
integer  blockMove = FALSE;
float    moveAngle = 0.0;
integer  isMoving = 0;
//
integer  hudDetected;
integer  energy =-1;
integer  upgradeFlag = 0;
integer  upgradeHold;
integer  sleeping = FALSE;


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

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
             if (cmd == "NAME") AN_NAME = val;
        else if (cmd == "SURFACE") SURFACE = llToLower(val);
        else if (cmd == "CHATTY") CHATTY = (integer)val;
        else if (cmd == "SLEEP_MODE") SLEEP_MODE = (integer)val;
        else if (cmd == "FEEDER") AN_FEEDER = val;
        else if (cmd == "CRY") AN_BAAH = val;
        else if (cmd == "HASGENES") AN_HASGENES = (integer)val;
        else if (cmd == "HASMILK") AN_HASMILK= (integer)val;
        else if (cmd == "HASWOOL") AN_HASWOOL= (integer)val;
        else if (cmd == "HASMANURE") AN_HASMANURE = (integer)val;
        else if (cmd == "AUTO_POO") AN_AUTO_POO = (integer)val;
        else if (cmd == "MANURE_OBJECT") MANURE_OBJECT = val;
        else if (cmd == "MANURETIME") MANURETIME = (integer)val;
        else if (cmd == "ADULT_MALE_PRIMS") ADULT_MALE_PRIMS = llParseString2List(val, [","] , []);
        else if (cmd == "ADULT_FEMALE_PRIMS") ADULT_FEMALE_PRIMS = llParseString2List(val, [","] , []);
        else if (cmd == "CHILD_PRIMS") CHILD_PRIMS = llParseString2List(val, [","] , []);
        else if (cmd == "SKINABLE_PRIMS") colorable = llParseString2List(val, [","] , []);
        else if (cmd == "MULTI_SKIN") MULTI_SKIN = (integer)val;
        else if (cmd == "WOOLTIME") WOOLTIME= (integer)val;
        else if (cmd == "MILKTIME") MILKTIME= (integer)val;
        else if (cmd == "IMMOBILE") IMMOBILE = (integer)val;
        else if (cmd == "RADIUS")   RADIUS = (integer)val;
        else if (cmd == "LAYS_EGG") LAYS_EGG = (integer)val;
        else if (cmd == "PREGNANT_TIME") PREGNANT_TIME= (integer)val;
        else if (cmd == "EGG_TIME") EGG_TIME = (integer)val;
        else if (cmd == "MATE_INTERVAL") MATE_INTERVAL = (integer)val;
        else if (cmd == "FEEDAMOUNT") FEEDAMOUNT= (float)val;
        else if (cmd == "WATERAMOUNT") WATERAMOUNT= (float)val;
        else if (cmd == "WATERTIME") WATERTIME= (float)val;
        else if (cmd == "STEP_SIZE") STEP_SIZE= (float)val;
        else if (cmd == "FEEDTIME") FEEDTIME= (float)val;
        else if (cmd == "CHILDHOOD_RATIO") CHILDHOOD_RATIO = (float)val;
        else if (cmd == "CHILD_SCALE") CHILD_SCALE= (float)val;
        else if (cmd == "CHILD_MAX_SCALE") CHILD_MAX_SCALE= (float)val;
        else if (cmd == "MALE_SCALE") MALE_SCALE = (float)val;
        else if (cmd == "FEMALE_SCALE") FEMALE_SCALE = (float)val;
        else if (cmd == "SKIN_OBJECT") SKIN_OBJECT = val;
        else if (cmd == "MEAT_OBJECT") MEAT_OBJECT = val;
        else if (cmd == "MILK_OBJECT") MILK_OBJECT = val;
        else if (cmd == "WOOL_OBJECT") WOOL_OBJECT = val;
        //else if (cmd == "PET_SAY") petResponses += val;
        else if (cmd == "TOTAL_BABYSOUNDS") TOTAL_BABYSOUNDS = (integer)val;
        else if (cmd == "TOTAL_ADULTSOUNDS") TOTAL_ADULTSOUNDS = (integer)val;
        else if (cmd == "TOUCH_ACTIVE") TOUCH_ACTIVE = (integer)val;
        else if (cmd == "HUMAN")  isHuman = (integer)val;
        else if (cmd == "LANG") languageCode = val;
        else if (cmd == "LIFEDAYS")
        {
            lifeFactor = (integer)((float)val * 0.1);
            LIFETIME = (integer)(86400*(float)val);
        }
    }
    if (isHuman == TRUE) SUFFIX ="B1"; else SUFFIX = "A1";
}

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("an_config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
    if (llGetListLength(petResponses) ==0)
    {
        petResponses = ["I love you too, %NAME%!", "I'm happy now.", "Awww, thanks %NAME%!"];
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    debug("loadLanguage asked for " + TXT_LANGUAGE + " " +languageNC);
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
                         if (cmd == "TXT_ADULTS_GIVE")     TXT_ADULTS_GIVE = val;
                    else if (cmd == "TXT_AUTO_MANURE")     TXT_AUTO_MANURE = val;
                    else if (cmd == "TXT_BUTCHER")         TXT_BUTCHER     = val;
                    else if (cmd == "TXT_CHATTY")          TXT_CHATTY     = val;
                    else if (cmd == "TXT_CHILD")           TXT_CHILD     = val;
                    else if (cmd == "TXT_CLOSE")           TXT_CLOSE     = val;
                    else if (cmd == "TXT_DAYS")            TXT_DAYS     = val;
                    else if (cmd == "TXT_DAYS_OLD")        TXT_DAYS_OLD = val;
                    else if (cmd == "TXT_DEAD")            TXT_DEAD     = val;
                    else if (cmd == "TXT_DEHYDRATION")     TXT_DEHYDRATION     = val;
                    else if (cmd == "TXT_DRINK")           TXT_DRINK     = val;
                    else if (cmd == "TXT_EAT")             TXT_EAT     = val;
                    else if (cmd == "TXT_EAT_FROM")        TXT_EAT_FROM = val;
                    else if (cmd == "TXT_EGG")             TXT_EGG     = val;
                    else if (cmd == "TXT_EGGS")            TXT_EGGS     = val;
                    else if (cmd == "TXT_EGGS_READY")      TXT_EGGS_READY = val;
                    else if (cmd == "TXT_ERROR_GROUP")     TXT_ERROR_GROUP     = val;
                    else if (cmd == "TXT_ERROR_UPDATE")    TXT_ERROR_UPDATE     = val;
                    else if (cmd == "TXT_EVERY")           TXT_EVERY     = val;
                    else if (cmd == "TXT_FEMALE")          TXT_FEMALE     = val;
                    else if (cmd == "TXT_FEMALES_GIVE")    TXT_FEMALES_GIVE     = val;
                    else if (cmd == "TXT_FLAT")            TXT_FLAT     = val;
                    else if (cmd == "TXT_FLOAT_FULL")      TXT_FLOAT_FULL     = val;
                    else if (cmd == "TXT_FLOAT_NONE")      TXT_FLOAT_NONE     = val;
                    else if (cmd == "TXT_FLOAT_SHORT")     TXT_FLOAT_SHORT     = val;
                    else if (cmd == "TXT_FLOAT_TEXT")      TXT_FLOAT_TEXT     = val;
                    else if (cmd == "TXT_FOLLOW_ME")       TXT_FOLLOW_ME     = val;
                    else if (cmd == "TXT_GAVE_BIRTH")      TXT_GAVE_BIRTH     = val;
                    else if (cmd == "TXT_GET_EGGS")        TXT_GET_EGGS     = val;
                    else if (cmd == "TXT_FOOD")            TXT_FOOD= val;
                    else if (cmd == "TXT_GET_MANURE")      TXT_GET_MANURE     = val;
                    else if (cmd == "TXT_GIVE_MANURE")     TXT_GIVE_MANURE     = val;
                    else if (cmd == "TXT_GOODBYE")         TXT_GOODBYE     = val;
                    else if (cmd == "TXT_GREET_EGG")       TXT_GREET_EGG     = val;
                    else if (cmd == "TXT_GREET_YOU")       TXT_GREET_YOU     = val;
                    else if (cmd == "TXT_GROUND")          TXT_GROUND     = val;
                    else if (cmd == "TXT_HAPPY")           TXT_HAPPY     = val;
                    else if (cmd == "TXT_HELLO")           TXT_HELLO     = val;
                    else if (cmd == "TXT_INFO")            TXT_INFO     = val;
                    else if (cmd == "TXT_HERE_IS")         TXT_HERE_IS     = val;
                    else if (cmd == "TXT_HOURS")           TXT_HOURS     = val;
                    else if (cmd == "TXT_HUNGRY")          TXT_HUNGRY     = val;
                    else if (cmd == "TXT_HUNGER")          TXT_HUNGER     = val;
                    else if (cmd == "TXT_HUNGRY_THIRSTY")  TXT_HUNGRY_THIRSTY = val;
                    else if (cmd == "TXT_I_AM")            TXT_I_AM     = val;
                    else if (cmd == "TXT_INCUBATING")      TXT_INCUBATING     = val;
                    else if (cmd == "TXT_INFO_MSG")        TXT_INFO_MSG     = val;
                    else if (cmd == "TXT_LAID_EGG")        TXT_LAID_EGG     = val;
                    else if (cmd == "TXT_LIVES")           TXT_LIVES     = val;
                    else if (cmd == "TXT_LOW_ENERGY")      TXT_LOW_ENERGY = val;
                    else if (cmd == "TXT_MENU_MAIN")        TXT_MENU_MAIN = val;
                    else if (cmd == "TXT_MALE")            TXT_MALE     = val;
                    else if (cmd == "TXT_MANURE_READY")    TXT_MANURE_READY = val;
                    else if (cmd == "TXT_MATE")            TXT_MATE     = val;
                    else if (cmd == "TXT_MATE_ERROR1")     TXT_MATE_ERROR1     = val;
                    else if (cmd == "TXT_MATE_ERROR2")     TXT_MATE_ERROR2     = val;
                    else if (cmd == "TXT_MILK")            TXT_MILK     = val;
                    else if (cmd == "TXT_MILK_READY")      TXT_MILK_READY     = val;
                    else if (cmd == "TXT_NO_SPEAK")        TXT_NO_SPEAK     = val;
                    else if (cmd == "TXT_NOT_HAPPY")       TXT_NOT_HAPPY     = val;
                    else if (cmd == "TXT_OK_FLAT")         TXT_OK_FLAT     = val;
                    else if (cmd == "TXT_OK_GROUND")       TXT_OK_GROUND     = val;
                    else if (cmd == "TXT_OK_WATER")        TXT_OK_WATER     = val;
                    else if (cmd == "TXT_OLD_AGE")         TXT_OLD_AGE     = val;
                    else if (cmd == "TXT_OPTIONS")         TXT_OPTIONS     = val;
                    else if (cmd == "TXT_PET")             TXT_PET     = val;
                    else if (cmd == "TXT_PREGNANCY")       TXT_PREGNANCY     = val;
                    else if (cmd == "TXT_PREGNANT")        TXT_PREGNANT     = val;
                    else if (cmd == "TXT_QUIET")           TXT_QUIET = val;
                    else if (cmd == "TXT_RANGE")           TXT_RANGE = val;
                    else if (cmd == "TXT_READY")           TXT_READY = val;
                    else if (cmd == "TXT_RESETTING")       TXT_RESETTING     = val;
                    else if (cmd == "TXT_RESPONSE_MOVE")   TXT_RESPONSE_MOVE     = val;
                    else if (cmd == "TXT_REZ")             TXT_REZ     = val;
                    else if (cmd == "TXT_SCALE")           TXT_SCALE = val;
                    else if (cmd == "TXT_SELECT")          TXT_SELECT = val;
                    else if (cmd == "TXT_SELECT_SURFACE")  TXT_SELECT_SURFACE     = val;
                    else if (cmd == "TXT_SET_NAME")        TXT_SET_NAME = val;
                    else if (cmd == "TXT_SET_RANGE")       TXT_SET_RANGE = val;
                    else if (cmd == "TXT_SETNAME_TO")      TXT_SETNAME_TO = val;
                    else if (cmd == "TXT_SILENT")          TXT_SILENT = val;
                    else if (cmd == "TXT_SILENT_MODE")     TXT_SILENT_MODE = val;
                    else if (cmd == "TXT_SLEEPING")        TXT_SLEEPING = val;
                    else if (cmd == "TXT_SPEAK")           TXT_SPEAK    = val;
                    else if (cmd == "TXT_STARVATION")      TXT_STARVATION     = val;
                    else if (cmd == "TXT_HOME")            TXT_HOME = val;
                    else if (cmd == "TXT_HOME_REPLY")      TXT_HOME_REPLY     = val;
                    else if (cmd == "TXT_STOP")            TXT_STOP = val;
                    else if (cmd == "TXT_STOP_REPLY")      TXT_STOP_REPLY     = val;
                    else if (cmd == "TXT_THIRSTY")         TXT_THIRSTY  = val;
                    else if (cmd == "TXT_THIRST")          TXT_THIRSTY  = val;
                    else if (cmd == "TXT_UPDATE")          TXT_UPDATE     = val;
                    else if (cmd == "TXT_UPDATE_REMOVE")   TXT_UPDATE_REMOVE     = val;
                    else if (cmd == "TXT_WALK_OFF")        TXT_WALK_OFF = val;
                    else if (cmd == "TXT_WALK_ON")         TXT_WALK_ON     = val;
                    else if (cmd == "TXT_WALK_ON_WHAT")    TXT_WALK_ON_WHAT = val;
                    else if (cmd == "TXT_WATER")           TXT_WATER = val;
                    else if (cmd == "TXT_NO_WATER")        TXT_NO_WATER = val;
                    else if (cmd == "TXT_LANGUAGE")        TXT_LANGUAGE = val;
                    else if (cmd == "TXT_ERROR_GROUP")     TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_UPDATE")    TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_FEMALE_SYMBOL")   TXT_FEMALE_SYMBOL =val;
                    else if (cmd == "TXT_MALE_SYMBOL")     TXT_MALE_SYMBOL =val;
                    else if (cmd == "TXT_PET_REPONSE1")    TXT_PET_RESPONSE1 =val;
                    else if (cmd == "TXT_PET_REPONSE2")    TXT_PET_RESPONSE2 =val;
                    else if (cmd == "TXT_PET_REPONSE3")    TXT_PET_RESPONSE3 =val;
                    else if (cmd == "TXT_PET_REPONSE3")    TXT_PET_RESPONSE4 =val;
                    else if (cmd == "TXT_OFF")             TXT_OFF = val;
                    else if (cmd == "TXT_ON")              TXT_ON = val;
                }
            }
        }
    }
    // Remove the "SF " bit to get our objects
    TXT_WOOL = llGetSubString(WOOL_OBJECT, 3, llStringLength(WOOL_OBJECT));
    TXT_GIVE_WOOL = TXT_HERE_IS +" " +TXT_WOOL;
    TXT_WOOL_READY = TXT_WOOL +" " +TXT_READY;
    TXT_MILK = llGetSubString(MILK_OBJECT, 3, llStringLength(MILK_OBJECT));
    TXT_GIVE_MILK = TXT_HERE_IS +" " +TXT_MILK;
    TXT_MILK_READY = TXT_MILK +" " +TXT_READY;
    petResponses = [TXT_PET_RESPONSE1, TXT_PET_RESPONSE2, TXT_PET_RESPONSE3, TXT_PET_RESPONSE4];
}

saveState()
{
    // Do not attempt to save notecard if we are in process of doing a 'restore'
    if (status != "waitStatusNC")
    {
        integer scode = 0;
        if (sex == "Female") scode = 1;
        string codedDesc = (string)scode+";"+(string)llRound(water)+";"+(string)llRound(food)+";"+(string)createdTs+";"+(string)chan(llGetKey())+";"+(string)geneA+";"+(string)geneB+";"+(string)fatherGene+";"+(string)pregnantTs+";"+name+";";
        // as of version 5.5 onwards adds -   version;radius;surface;chatty;language;givenBirth;epoch;labelType;initpos;scaleFactor;AN_AUTO_POO;savedRot;savedPos;SLEEP_MODE;feedPet
        codedDesc += (string)(llRound(VERSION*10))+";" +(string)RADIUS+";" +SURFACE+";" +(string)CHATTY+";" +languageCode+";" +(string)givenBirth+";" +(string)epoch+";" +(string)labelType+";" +(string)initpos+";" +qsFloat2String(scaleFactor, 2, FALSE) +";" +(string)AN_AUTO_POO +";" +(string)savedRot +";" +(string)savedPos +";" +(string)SLEEP_MODE +";" +(string)feedPet;
        //
        if (isPet == TRUE) codedDesc = "X;"+codedDesc; else codedDesc = "A;"+codedDesc;
        //
        if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
        {
            if (llGetInventoryType(statusNC+"-OLD") == INVENTORY_NOTECARD) llRemoveInventory(statusNC+"-OLD");
            string tmpStr = osGetNotecard(statusNC);
            osMakeNotecard(statusNC+"-OLD", tmpStr);
            llSleep(0.2);
            llRemoveInventory(statusNC);
        }
        // save to notecard
        osMakeNotecard(statusNC, codedDesc);
        // also save to description for legacy support
        if (isHuman == FALSE) llSetObjectDesc(codedDesc);
    }
}

loadState()
{
    // Do not attempt to load notecard if we are in process of doing a 'restore'
    if (status != "waitStatusNC")
    {
        list desc = [];
        // first try notecard
        if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
        {
            desc = llParseStringKeepNulls(osGetNotecardLine(statusNC, 0), [";"], []);
        }
        else
        {
            // as backup try description
            if (isHuman == FALSE) desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
        }
        //
        if ((llList2String(desc, 0) == "A") || (llList2String(desc, 0) == "X"))
        {
            if (llList2String(desc, 0) == "X") isPet = TRUE; else isPet = FALSE;
            //
            if ((llList2String(desc, 5) != (string)chan(llGetKey())) && (isPet == FALSE) && (isHuman == FALSE)) //Also resets eggs!
            {
                llOwnerSay(TXT_RESETTING);
                llSetObjectDesc("");
                llSleep(1.0);
            }
            else
            {
                if (llList2Integer(desc,1) == 1) sex = "Female"; else sex = "Male";
                water = llList2Integer(desc, 2);
                food  = llList2Integer(desc, 3);
                epoch = 1; // Assume child
                createdTs = llList2Integer(desc, 4);
                geneA = llList2Integer(desc, 6);
                geneB = llList2Integer(desc, 7);
                fatherGene = llList2Integer(desc, 8);
                pregnantTs = llList2Integer(desc, 9);
                name = llList2String(desc, 10);
                // optional newer items so see if there is a version number stored next
                if (llList2Integer(desc, 11) != 0)
                {
                    RADIUS  = llList2Integer(desc, 12);
                    SURFACE = llList2String(desc, 13);
                    CHATTY  = llList2Integer(desc, 14);
                    languageCode = llList2String(desc, 15);
                    if (llList2Vector(desc, 19) != ZERO_VECTOR)
                    {
                        givenBirth = llList2Integer(desc, 16);
                        epoch = llList2Integer(desc, 17);
                        labelType = llList2Integer(desc, 18);
                        initpos = llList2Vector(desc, 19);
                        scaleFactor = llList2Float(desc, 20);
                        AN_AUTO_POO = llList2Integer(desc, 21);
                        savedRot = llList2Rot(desc, 22);
                        savedPos = llList2Vector(desc, 23);
                        SLEEP_MODE = llList2Integer(desc, 24);
                        feedPet = llList2Integer(desc, 25);
                    }
                }
            }
        }
        else
        {
            saveState();
        }
        // Check for invalid values
        if (RADIUS == 0) RADIUS = 10;
        if (scaleFactor == 0.0) scaleFactor = 1.0;
    }
}

backupNC()
{
    if (llGetInventoryType(statusNC+"-OLD") == INVENTORY_NOTECARD)
    {
        llRemoveInventory(statusNC+"-OLD");
        llSleep(0.2);
    }
    string tmpStr = osGetNotecard(statusNC);
    osMakeNotecard(statusNC+"-OLD", tmpStr);
}

setGenes()
{
    integer i;
    string tex;
    if (AN_HASGENES == TRUE)
    {
        if (geneA == geneB)
            tex = "goat"+(string)geneA;
        else if (geneA<geneB)
            tex = "goat"+(string)geneA+(string)geneB;
        else if (geneB<geneA)
            tex = "goat"+(string)geneB+(string)geneA;
        if (MULTI_SKIN == FALSE)
        {
            for (i=0; i < llGetListLength(colorable); i++)
            {
                integer lnk = llList2Integer(colorable, i);
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE, ALL_SIDES, tex, <1,1,1>, <0, 0, 0> , 0]);
            }
        }
        else
        {
            // new way  - 'colorable' is list of prim_number,texture_suffix,
            //  15,Tail, 13,BLeg, 14,BLeg, 3,FLeg, 4, FLeg, 12,Torso, 6,Mane, 5,Neck, 7,Face, 10,Ear, 11,Ear
            integer lnk;
            integer count = llGetListLength(colorable);       
            string texSuffix;
            for (i = 0; i < count; i+=2)
            {
                lnk = llList2Integer(colorable, i);
                texSuffix = llList2String(colorable, i+1);
                //llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE, ALL_SIDES, tex+"-"+texSuffix, <1,1,1>, <0, 0, 0> , 0]);
                llSetLinkPrimitiveParamsFast(lnk, [PRIM_TEXTURE, ALL_SIDES, tex+"-"+texSuffix, <1,1,1>, <0, 0, 0> , 0]);               
            }
        }
    }
}

say(integer whisper, string str, key id)
{
    if ((qlDayCheck()==TRUE) || (SLEEP_MODE == FALSE))
    {
        if (CHATTY == 1)
        {
            if (LAYS_EGG && epoch ==0)
            {
                if (id == NULL_KEY) llSay( 0, str);
                  else llRegionSayTo(id, 0, str);
            }
            else
            {
                string s = llGetObjectName();
                llSetObjectName(name);
                if (whisper)
                {
                    llWhisper(0, str);
                }
                else
                {
                    if (id == NULL_KEY) llSay(0, str);
                      else llRegionSayTo(id, 0, str);
                }
                llSetObjectName(s);
            }
        }
        baah();
    }
    else
    {
        llRegionSayTo(id, 0, TXT_SLEEPING);
    }
}

baah()
{
    // If chatty is 0 or 1 make animal sounds, if -1 keep silent. Also if sleep mode active and night, keep quiet
    if (CHATTY != -1)
    {
        if ((qlDayCheck() == TRUE) || (SLEEP_MODE == FALSE))
        {
            if (epoch ==1)        llTriggerSound("baby"+(string)(1+(integer)llFrand(TOTAL_BABYSOUNDS)), 1.0);
            else if (epoch == 2)  llTriggerSound("adult"+(string)(1+(integer)llFrand(TOTAL_ADULTSOUNDS)), 1.0);
        }
    }
}

death(integer keepBody)
{
    llSetTimerEvent(0);
    //Prepare for death
    deathFlags = keepBody; //Whether to keep the dead body or die()
    if (MEAT_OBJECT!= "")
    {
        llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)NULL_KEY +"|" +MEAT_OBJECT, NULL_KEY);
        llSleep(1);
    }
    if (SKIN_OBJECT != "") llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)NULL_KEY +"|" +SKIN_OBJECT, NULL_KEY);
}

hearts()
{
     llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_FOLLOW_VELOCITY_MASK|PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN,       PSYS_SRC_PATTERN_EXPLODE,
        PSYS_PART_START_SCALE,      <.1,.1,0.1>,
        PSYS_PART_START_ALPHA,      1.0,
        PSYS_PART_START_COLOR,      WHITE,
        PSYS_SRC_ACCEL,             <0,0,.1>,
        PSYS_SRC_TEXTURE ,          "heart",
        PSYS_PART_MAX_AGE,          8.0,
        PSYS_SRC_MAX_AGE,          3.0,
        PSYS_SRC_ANGLE_BEGIN,       0.0,
        PSYS_SRC_ANGLE_END,         0.2,
        PSYS_SRC_BURST_PART_COUNT,  36,
        PSYS_SRC_BURST_RATE,        .1,
        PSYS_SRC_BURST_SPEED_MIN,   0.5,
        PSYS_SRC_BURST_SPEED_MAX,   1.5]);
}

integer getLinkNum(string name)
{
    integer i;
    for (i=2; i <= llGetNumberOfPrims();i++)
        if (llGetLinkName(i) == name) return i;
    return 0;
}

seeMe()
{
    vector seeMeColour;
    if (sex == "Female") seeMeColour = PINK; else seeMeColour = AQUA;
    llSetLinkColor(LINK_ALL_OTHERS, seeMeColour, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_FULLBRIGHT, ALL_SIDES, 1]);
    status = "freeze";
    llSetTimerEvent(55.0);
}

setAlpha(list links, float vis)
{
    integer i;
    for (i=0; i < llGetListLength(links);i++)
        llSetLinkPrimitiveParamsFast(llList2Integer(links,i), [PRIM_COLOR, ALL_SIDES, WHITE, vis]);
}

setAlphaByName(string namea, float opacity)
{
    integer i;
    for (i=2; i <= llGetNumberOfPrims();i++)
        if (llGetLinkName(i) == namea)
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, WHITE, opacity]);
}

showAlphaSet(integer newEpoch)
{
    if (newEpoch == 0)
    {
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, WHITE, 0.]); // Hide all
        setAlphaByName("egg_prim", 1.);
    }
    else if (newEpoch == 1)
    {
        //show all but hide adult
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, WHITE, 1.]);
        setAlphaByName("egg_prim", 0.);
        setAlphaByName("adult_prim", 0.);
        setAlphaByName("adult_male_prim", 0.);
        setAlphaByName("adult_female_prim", 0.);
        setAlphaByName("adult_random_prim", 0.);
        setAlpha(ADULT_FEMALE_PRIMS+ADULT_MALE_PRIMS+ADULT_RANDOM_PRIMS, 0.);// Legacy
        setAlpha(CHILD_PRIMS, 1.);
        setAlphaByName("child_prim", 1.);
    }
    else if (newEpoch == 2)
    {
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, WHITE, 1.]);
        setAlpha(CHILD_PRIMS+ADULT_RANDOM_PRIMS+ADULT_FEMALE_PRIMS+ADULT_MALE_PRIMS, 0.);
        setAlphaByName("child_prim", 0.);
        setAlphaByName("egg_prim", 0.);
        if (llFrand(1.)<0.5)
        {
            setAlpha(ADULT_RANDOM_PRIMS, 1.);
            setAlphaByName("adult_random_prim", 1.);
        }
        setAlphaByName("adult_prim", 1.);
        if (sex == "Female")
        {
            setAlpha(ADULT_FEMALE_PRIMS, 1.);
            setAlphaByName("adult_female_prim", 1.);
            setAlphaByName("adult_male_prim", 0.);
        }
        else
        {
            setAlpha(ADULT_MALE_PRIMS, 1.);
            setAlphaByName("adult_male_prim", 1.);
            setAlphaByName("adult_female_prim", 0.);
        }
        llMessageLinked(LINK_SET, 1, "IS_ADULT", "");
    }
}

setPose(list pose)
{
    integer i;
    float scale;
    if (epoch == 1 )
    {
            scale = CHILD_SCALE + (1-CHILD_SCALE) * ((float)(age)/(float)(CHILDHOOD_RATIO*lifeTime));
            if (scale>CHILD_MAX_SCALE) scale = CHILD_MAX_SCALE;
            if (scale>1) scale = 1.0;
    }
    else if (sex=="Male") scale= MALE_SCALE; else scale = FEMALE_SCALE;
    scale = scale * scaleFactor;
    for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, (i-1)*2-2)*scale, PRIM_ROT_LOCAL, llList2Rot(pose, (i-1)*2-1), PRIM_SIZE, llList2Vector(link_scales, i-2)*scale]);
    }
}

move()
{
    if ((qlDayCheck() == TRUE) || (SLEEP_MODE == FALSE))
    {
        if (epoch != 0)
        {
            integer rnd = (integer)llFrand(5);
                 if (rnd == 0)      setPose(rest);
            else if (rnd == 1)      setPose(down);
            else if (rnd == 2)      setPose(eat);
            else if ((IMMOBILE <= 0) && (blockMove == FALSE))
            {
                isMoving = 7;
                moveAngle = 0.3-llFrand(0.6);
                llSetTimerEvent(0.5);
            }
            if (isHuman == TRUE)
            {
                if (llFrand(1.0)> 0.75) baah();
            }
            else
            {
                if (llFrand(1.0)< 0.5) baah();
            }
        }
    }
    else
    {
        setPose(down);
    }
}

refresh()
{
    if (status == "freeze")
    {
        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_FULLBRIGHT, ALL_SIDES, 0]);
        llSetLinkColor(LINK_ALL_OTHERS, WHITE, ALL_SIDES);
        status = "";
    }

    if (habitat == FALSE)
    {
        if (SURFACE == "water")
        {
            if (checkHabitat("water") == FALSE)
            {
                llSay(0, TXT_NO_WATER);
            }
            else habitat=TRUE;
        }
        else habitat = TRUE;
    }

    if (upgradeFlag == TRUE)
    {
        createdTs = upgradeHold;
        upgradeFlag = FALSE;
    }

    integer ts = llGetUnixTime();
    if (isPet == FALSE) age = (ts-createdTs);
    if (epoch == 0)
    {
        integer pc = llFloor(((float)age / (float)EGG_TIME)*100.);
        if (pc >99)
        {
            epoch = 1; //Egg --> child
            showAlphaSet(epoch);
            llSetTimerEvent(2);
            lastTs = ts;
            createdTs = ts;
        }
        else
        {
            llSetText(AN_NAME+" " + TXT_EGG + "\n" + TXT_INCUBATING + "..." +(string)pc+"%\n", WHITE, 1.0);
            llSetObjectDesc("A;EGG;"+(string)pc);
        }
        return;
    }

    if ((isPet == FALSE) || (isPet == TRUE && feedPet == TRUE))
    {
        food  -= (ts - lastTs) * (100.0/FEEDTIME);
        water -= (ts - lastTs) * (100.0/WATERTIME); // water consumption rate
        happy -= (ts - lastTs) * (100.0/4000.0);
    }
    else
    {
        food  = 100.0;
        water = 100.0;
        happy = 50.0;
    }

    if (happy < 2) happy = 25;

    if (food < 5 || water < 5)
    {
        status ="WaitFood";
        llSensor(AN_FEEDER, "", SCRIPTED, RADIUS * 2, PI);
    }

    float days = (age/86400.0);

    string str = "";
    if (isPet == TRUE) str += TXT_PET +" ";
    str += name;
    string strShort = name;
    string humanStr = name;
    vector color = WHITE;

    if (isHuman == FALSE)
    {
        if (sex == "Female")
        {
            str += " [" +TXT_FEMALE_SYMBOL +"] \n";
            strShort += " [" +TXT_FEMALE_SYMBOL +"] \n";
        }
        else
        {
            str += " [" +TXT_MALE_SYMBOL +"] \n";
            strShort += " [" +TXT_MALE_SYMBOL +"] \n";
        }
    }

    if (isPet == FALSE)
    {
        if (epoch ==1 && days  > (lifeTime*CHILDHOOD_RATIO/86400.))
        {
            epoch = 2; // Child --> adult
            FEEDAMOUNT  = 2.*FEEDAMOUNT;
            WATERAMOUNT = 2.*WATERAMOUNT;
            showAlphaSet(epoch);
        }
    }
    else
    {
        str += "\n";
        strShort += "\n";
    }

    if (food < 0 && water <0) say(0, AN_BAAH+", " +TXT_HUNGRY_THIRSTY, NULL_KEY);
     else if (food < 0) say( 0,AN_BAAH+", " +TXT_HUNGER, NULL_KEY);
      else if (water < 0) say( 0, AN_BAAH+", " +TXT_THIRST, NULL_KEY);

    if (isPet == FALSE)
    {
        str += "\n"+(string)((integer)days)+" " + TXT_DAYS_OLD + " ";
        humanStr += "\n"+(string)((integer)days)+" " + TXT_DAYS_OLD + " ";
    }
    if ((epoch == 1) && (isPet == FALSE))
    {
             str += " (" +TXT_CHILD +")\n";
        strShort += " (" +TXT_CHILD +")\n";
        humanStr += " (" +TXT_CHILD +")\n";
    }
    else
    {
        str += "\n";
        if (isPet == FALSE)
        {
            if (epoch >1)
            {
                float p = 100.*(ts - milkTs)/MILKTIME;
                if (p > 100) p = 100;
                // MILK OBJECT STATUS
                if (AN_HASMILK && sex == "Female")
                {
                    if (LAYS_EGG==1)
                    {
                        str += TXT_EGGS +": "+(string)((integer)p)+"%\n";
                        if (p >99) strShort += "\n" + TXT_EGGS_READY;
                    }
                    else if (givenBirth>0)
                    {
                        str += TXT_MILK + ": "+(string)((integer)p)+"%\n";
                        if (p >99) strShort += "\n" +TXT_MILK_READY;
                    }
                }
                // WOOL OBJECT STATUS
                p = 100.*(ts - woolTs)/WOOLTIME;
                if (p > 100) p = 100;
                if (AN_HASWOOL)
                {
                    str += TXT_WOOL + ": "+(string)((integer)p)+"%\n";
                    if (p >99)
                    {
                        strShort += "\n" + TXT_WOOL_READY;
                        humanStr += "\n" + TXT_WOOL_READY;
                    }
                }
                // MANURE OBJECT STATUS
                p = 100.*(ts - manureTs)/MANURETIME;
                if (p > 100) p = 100;
                if (AN_HASMANURE)
                {
                    str += llGetSubString(MANURE_OBJECT, 3, -1) + ": "+(string)((integer)p)+"%\n";
                    if (p >99)
                    {
                        if (AN_AUTO_POO  == TRUE)
                        {
                            rezManure(NULL_KEY);
                        }
                        else
                        {
                            strShort += "\n" + TXT_MANURE_READY;
                            humanStr += "\n" + TXT_MANURE_READY;
                        }
                    }
                }
            }
        }
    }

    // Age check
    if ((age > lifeTime || food < -20000 || water < -20000) &&  (isPet == FALSE))
    {
        death(1);
        return;
    }
    else
    {
        if (pregnantTs>0)
        {
            float perc = (float)(ts - pregnantTs)/PREGNANT_TIME;
            if (perc >.99)
            {
                string rezPoz = (string)(llGetPos() +<0,2,0>*llGetRot());
                llMessageLinked(LINK_SET, -1, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +"SF "+AN_NAME, NULL_KEY);

                pregnantTs =0;
                if (LAYS_EGG)
                {
                    say(0, TXT_LAID_EGG, NULL_KEY);
                    lastEggTs= ts;
                }
                else
                {
                    say(0, TXT_GAVE_BIRTH, NULL_KEY);
                    givenBirth++;
                }
            }
            else
            {
                str += TXT_PREGNANT +" ("+(string)((integer)(perc*100))+"%)\n";
                strShort += "\n" +TXT_PREGNANT +"("+(string)((integer)(perc*100))+"%)\n";
            }
        }

        if (food<0)
        {
            str += TXT_HUNGRY +"\n";
            happy = 0;
        }
        else if (food<50)
            str += TXT_FOOD +": "+(string)((integer)food)+"%\n";

        if (water<0)
        {
            str += TXT_THIRSTY +"\n";
            happy = 0;
        }
        else if (water <50)
            str += TXT_WATER +": "+(string)((integer)water)+"%\n";

        if (habitat == FALSE)
        {
            if (SURFACE == "water")
            {
                str+= "\n"+TXT_NO_WATER;
                strShort += "\n"+TXT_NO_WATER;
                happy = 0;
            }
        }

        if (happy >50)
        {
            if (isPet == FALSE)
            {
                str = TXT_HAPPY + "\n" + str;
                strShort = TXT_HAPPY + "\n" + strShort;
            }
            color = GREEN;
        }
        else if (happy >0) color = WHITE; else color = RED;

        string tmpStr;
        if (isHuman == FALSE)
        {
            if (RSTATE == 0)
            {
                str += "\n-B-";
                strShort += "\n-B-";
                tmpStr = "-B-";
            }
            else if (RSTATE == -1)
            {
                str += "\n-RC-";
                strShort += "\n-RC-";
                tmpStr = "-RC-";
            }

            if (labelType == 0)
            {
                llSetText(str , color, 1.0);
            }
            else if (labelType == 1)
            {
                    llSetText(strShort , color, 1.0);
            }
            else
            {
                llSetText(tmpStr, BLACK, 1.0);
            }
        }
        else
        {
            if (RSTATE == 0)
            {
                str += "\n-B-";
                humanStr += "\n-B-";
                tmpStr = "-B-";
            }
            else if (RSTATE == -1)
            {
                str += "\n-RC-";
                humanStr += "\n-RC-";
                tmpStr = "-RC-";
            }
            if (labelType == 2) llSetText(tmpStr, BLACK, 0.5); else if (labelType == 1) llSetText(humanStr, PURPLE, 1.0); else llSetText(str, PURPLE, 1.0);
        }
        if (isAttached == TRUE)
        {
            savedRot = llGetLocalRot();
            savedPos = llGetLocalPos();
        }
    }
    saveState();
}

list getNC(string ncname)
{
    list lst = llParseString2List(osGetNotecard(ncname), ["|"], []);
    return lst;
}

integer qlDayCheck()
{
    integer result;
    // Check with lsl functions if sun above or below horizon
    vector sun=llGetSunDirection();
    float time = sun.z;
    if (llRound(sun.z) == 1) result = 1; else result = 0;
    if (result == sleeping)  // transition over from sleep to wake and vice versa
    {
        sleeping = !sleeping;
        if (sleeping == TRUE) llMessageLinked(LINK_SET, 1, "EXPRESSION|SLEEP", ""); else llMessageLinked(LINK_SET, 1, "EXPRESSION|WAKE", "");
    }
    return result;
}

string qsFloat2String ( float num, integer places, integer rnd)
{  //rnd (rounding) should be set to TRUE for rounding, FALSE for no rounding
    if (rnd)
    {
        float f = llPow( 10.0, places );
        integer i = llRound(llFabs(num) * f);
        string s = "00000" + (string)i; // number of 0s is (value of max places - 1 )
        if(num < 0.0)
            return "-" + (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
        return (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
    }
    if (!places)
        return (string)((integer)num );
    if ( (places = (places - 7 - (places < 1) ) ) & 0x80000000)
        return llGetSubString((string)num, 0, places);
    return (string)num;
}

integer checkHabitat(string habitat)
{
    if (habitat == "water")
    {
        float fGround = llGround(ZERO_VECTOR);
        float fWater = llWater(ZERO_VECTOR);
        // This animals natural habitat is set to water
        if (llGround(ZERO_VECTOR) > llWater(ZERO_VECTOR))
        return FALSE; else return TRUE;
    }
    else return FALSE;
}

rezManure(key id)
{
    llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)id +"|" +MANURE_OBJECT, NULL_KEY);
    manureTs = llGetUnixTime();
}

showOptionsMenu(key id)
{
    list opts = [TXT_SET_NAME];
    if (IMMOBILE > 0)
    {
        if (isAttached == FALSE) opts += TXT_WALK_ON;
    }
    else
    {
        if (isAttached == FALSE) opts += TXT_WALK_OFF;
    }
    //
    opts += TXT_FLOAT_TEXT;
    if (IMMOBILE <= 0)
    {
        if (isAttached == FALSE) opts += [TXT_RANGE, TXT_WALK_ON_WHAT];
    }
    opts += TXT_SOUNDS;
    if (SLEEP_MODE == TRUE) opts += "-"+TXT_SLEEP_MODE; else opts +="+"+TXT_SLEEP_MODE;
    if ((epoch ==2) && (isPet == FALSE)) opts += TXT_BUTCHER;
    if (AN_HASMANURE)
    {
        if (AN_AUTO_POO == TRUE) opts += "-"+TXT_AUTO_MANURE; else opts += "+"+TXT_AUTO_MANURE;
    }
    if ((epoch == 2) || (isPet == TRUE) || (isHuman == TRUE)) opts += TXT_SCALE;
    opts += [TXT_CLOSE];

    string prompt = "\n" +TXT_OPTIONS + "\n";
    prompt += TXT_FLOAT_TEXT;
    if (labelType == 0) prompt += TXT_FLOAT_FULL; else if (labelType == 1) prompt += TXT_FLOAT_SHORT; else prompt +=TXT_FLOAT_NONE;
    prompt += "\t" +TXT_RANGE +" " +(string)RADIUS +"m\t" +TXT_WALK_ON_WHAT +SURFACE;
    prompt += "\n"+TXT_SOUNDS+": ";
    if (CHATTY == -1) prompt += TXT_SILENT; else if (CHATTY == 0) prompt += TXT_QUIET; else prompt += TXT_CHATTY;
    prompt += "\t \t"+TXT_SLEEP_MODE+": ";
    if (SLEEP_MODE == TRUE) prompt += TXT_ON; else prompt += TXT_OFF;
    llDialog(id, prompt, opts, chan(llGetKey()) );
}

doTouch(key toucher)
{
    if (epoch == 0)
    {
        llRegionSayTo(toucher, 0, TXT_GREET_EGG);
    }
    else if ((toucher == llGetOwner()) || (llSameGroup(toucher) == TRUE) || (osIsNpc(toucher) == TRUE))
    {
        lastUser = toucher;
        hudDetected = FALSE;
        energy = -1;
        llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|CQ");
        llSleep(0.25);

        list opts = [];
        if (IMMOBILE <= 0)
        {
            if (isAttached == FALSE)
            {
                opts += TXT_HOME;
                if (followUser == NULL_KEY) opts += TXT_FOLLOW_ME;
            }
        }
        if (followUser != NULL_KEY) opts+= TXT_STOP;
        opts += [TXT_PET, TXT_INFO,  TXT_OPTIONS, TXT_LANGUAGE, TXT_CLOSE];

       integer ts = llGetUnixTime();
       if ((sex == "Female" && epoch == 2) && (isHuman == FALSE))
       {
           if ( (LAYS_EGG==1 && ts> lastEggTs+MATE_INTERVAL) || (LAYS_EGG==0&& pregnantTs ==0) )
               opts +=  TXT_MATE;
       }
       if (epoch == 2)
       {
           if (sex == "Female" && AN_HASMILK)
           {
                if (  ts - milkTs > MILKTIME)
                {
                    if (LAYS_EGG==1) opts += TXT_GET_EGGS;
                    else if (givenBirth>0) opts += TXT_MILK;
                }
           }
           if ((ts - woolTs > WOOLTIME) && AN_HASWOOL >0) opts += TXT_WOOL;
           if ((ts - manureTs > MANURETIME) && AN_HASMANURE >0) opts += TXT_GET_MANURE;
       }
       startListen();
       llDialog(lastUser, "\n"+TXT_MENU_MAIN +" - " +AN_NAME+"\n \n" + TXT_SELECT, opts, chan(llGetKey()));
    }
    else
    {
        llRegionSayTo(toucher, 0, TXT_ERROR_GROUP);
    }
}


default
{
    state_entry()
    {
        isPet = FALSE;
        sexToggle = llGetStartParameter();
        llSetText("",ZERO_VECTOR, 0.0);
        if (llSubStringIndex(llGetObjectName(), "Update")>=0 || llSubStringIndex(llGetObjectName(), "Rezzer")>=0)
        {
            llSetScriptState(llGetScriptName(), FALSE); // Dont run in the rezzer
            return;
        }
        llSetRemoteScriptAccessPin(0);
        rest =  getNC("rest");
        down = getNC("down");
        eat = getNC("eat");
        walkl = getNC("walkl");
        walkr = getNC("walkr");
        link_scales = getNC("scales");
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        name = AN_NAME;
        llSetObjectName("SF "+AN_NAME);
        //Set Defaults
        energy =-1;
        llSetLinkColor(LINK_ALL_OTHERS, WHITE, ALL_SIDES);
        if (sexToggle == -1) sex = "Male";
         else if (sexToggle == 1) sex = "Female";
        else
        {
            if (llFrand(1.) < 0.5) sex = "Female";
            else sex = "Male";
        }
        geneA = 1+ (integer)llFrand(3);
        geneB = 1+ (integer)llFrand(3);
        lastTs = createdTs = llGetUnixTime()-200;
        if (LAYS_EGG) epoch =0; else epoch = 1;
        lifeTime = (integer) ( (float)LIFETIME*( 1.+llFrand(.1)) );
        //Load state after defaults
        loadState();
        loadLanguage(languageCode);
        if (initpos == ZERO_VECTOR) initpos = llGetPos();
        if (isAttached == TRUE)
        {
            llSetRot(savedRot);
            llSetPos(savedPos);
        }
        setGenes();
        setPose(rest);
        if (isHuman == FALSE) showAlphaSet(epoch);
        integer i;
        for(i = 2; i <= llGetNumberOfPrims(); ++i)
            llSetLinkPrimitiveParamsFast(i, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
        //
        if (SURFACE == "water")
        {
            FLOAT_PRIM = getLinkNum("float_prim");
            if (checkHabitat("water") == FALSE)
            {
                habitat=FALSE;
            }
            else habitat=TRUE;
        }
        else habitat=TRUE;
        if (llGetAttached() == 0) isAttached = FALSE; else isAttached = TRUE;
        llSetTimerEvent(2);
    }

    on_rez(integer n)
    {
        sexToggle = n;
        if (llGetObjectDesc() == "")
        {
            //llResetScript();
            state entry;
            return;
        }
        listener = -1;
        lastTs = llGetUnixTime();
        initpos = llGetPos();
    }

    object_rez(key id)
    {
        llSleep(.5);
        if (llKey2Name(id) == llGetObjectName()) //Child
        {
            string newName = AN_NAME;
            string genes = (string)geneA+"|"+(string)fatherGene;
            if (llFrand(1.0)<0.5) genes = (string)geneB+"|"+(string)fatherGene;

            if (AN_HASGENES == TRUE)
            {
                if (llFrand(2.0)<1) newName = name+" "+fatherName+"son"; else newName = fatherName +" Fitz" +llToLower(name);
                if (llStringLength(newName) > 21)
                {
                    newName = llGetSubString(name, 0, 6);
                    newName += " " +llGetSubString(fatherName, 0, 6);
                }
            }
            string babyParams = genes+"|"+newName;
            llGiveInventory(id, "sfp");
            string ncName;
            integer i;
            llGiveInventory(id, "SF "+AN_NAME);
            integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
            for (i=0; i<count; i+=1)
            {
                ncName = llGetInventoryName(INVENTORY_NOTECARD, i);
                if (llGetSubString(ncName, 5, 11) == "-langA1") llGiveInventory(id, ncName);
            }
            llSleep(0.5);
            llRemoteLoadScriptPin(id, "language_plugin", 999, TRUE, 1);
            llRemoteLoadScriptPin(id, "prod-rez_plugin", 999, TRUE, 1);
            llGiveInventory(id, "product");
            llRemoteLoadScriptPin(id, "animal", 999, TRUE, 0);
            llSleep(1);
            messageObj(id, "INIT|"+PASSWORD+"|"+babyParams+"|"+languageCode+"|"+SURFACE+"|"+(string)CHATTY+"|"+(string)labelType+"|"+(string)RADIUS);
        }
        else
        {
            messageObj(id, "INIT|"+PASSWORD);
            if (llKey2Name(id) == MEAT_OBJECT) deathFlags = deathFlags|2;
            if (llKey2Name(id) == SKIN_OBJECT) deathFlags = deathFlags|4;
            if ((MEAT_OBJECT=="" || (deathFlags&2)) && (SKIN_OBJECT=="" || (deathFlags&4)))
            {
                llSetTimerEvent(0);status = "waitStatusNC";
                if (deathFlags&1)
                {
                    llSetRot(llEuler2Rot(<PI/2,0,0>));
                    llSetLinkColor(LINK_ALL_OTHERS, BLACK, ALL_SIDES);
                    string cause;
                    if (age > lifeTime) cause = TXT_OLD_AGE;
                    else if (food < -20000) cause = TXT_STARVATION;
                    else cause = TXT_DEHYDRATION;
                    llSetText(name+"\n" + TXT_DEAD +"\n" + cause, BROWN, 1.0);
                    llSetObjectName("DEAD");
                    llSetObjectDesc(TXT_DEAD +" " +llGetObjectDesc());
                    llMessageLinked(LINK_SET, 1, "HEAVEN", (key)PASSWORD);
                    llSleep(0.5);
                    llRemoveInventory(llGetScriptName());
                }
                else
                    llDie();
            }
        }
    }

    timer()
    {
        if (status == "freeze")
        {
            llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_FULLBRIGHT, ALL_SIDES, 0]);
            llSetLinkColor(LINK_ALL_OTHERS, WHITE, ALL_SIDES);
            status = "";
        }
        //
        if (habitat == FALSE)
        {
            if (SURFACE == "water")
            {
                if (checkHabitat("water") == FALSE)
                {
                    llSay(0, TXT_NO_WATER);
                }
                else habitat=TRUE;
            }
            else habitat = TRUE;
        }

        if ((qlDayCheck() == TRUE) || (SLEEP_MODE == FALSE))
        {
            // only make animal walk if not attached to avatar (e.g. baby)
            if (isAttached == FALSE)
            {
                if ((isMoving > 0) && (habitat == TRUE))
                {
                    if (isMoving == 1)
                    {
                        setPose(rest);
                        llSetTimerEvent(11);
                    }
                    else
                    {
                        vector cp = llGetPos();
                        vector moveAmount = <STEP_SIZE, 0, 0>*(llGetRot()*llEuler2Rot(<0,0,moveAngle>));
                        vector v = cp + moveAmount;

                        if (SURFACE == "ground")
                        {
                            v.z = llGround(ZERO_VECTOR);
                            cp.z = llGround(ZERO_VECTOR);
                        }
                        else if (SURFACE == "water")
                        {
                            float fGround = llGround(moveAmount);
                            float fWater = llWater(moveAmount);
                            // Stop the animal from leaving the water
                            if (fGround > fWater)
                            {
                                v = cp;
                                llSetRot(llGetRot()*llEuler2Rot(<0,0,PI/2>));
                            }
                        }
                        else
                        {
                            v.z = cp.z;
                        }
                        if (llVecDist(v, initpos)< RADIUS)
                        {
                            left =!left;
                            if (left)   setPose(walkl);
                            else    setPose(walkr);
                            //if (isMoving == 0) setPose(walkl); else setPose(walkr);
                            llSetPrimitiveParams([PRIM_POSITION, v, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,moveAngle>) ]);
                        }
                        else
                        {
                            llSetPrimitiveParams([PRIM_POSITION, cp, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,PI/2>) ]);
                        }
                    }
                    isMoving--;
                    return;
                }

                if (followUser != NULL_KEY)
                {
                    list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                    if (llGetListLength(userData)==0)
                    {
                        followUser = NULL_KEY;
                        llSetTimerEvent(1);
                        return;
                    }
                    else
                    {
                        vector size = llGetAgentSize(followUser);
                        vector mypos = llGetPos();
                        vector v = llList2Vector(userData, 1) + <0.3, 1.5, (-size.z/2)-0.1> * llList2Rot(userData,2);
                        float d = llVecDist(mypos, v);
                        if (d>2)
                        {
                            vector vn = llVecNorm(v  - mypos );
                            vector fpos;
                            if (d>20) fpos = mypos + 2*vn;
                            else fpos = mypos + .7*vn;
                            vn.z =0;
                            rotation r2 = llRotBetween(<1,0,0>,vn);
                            left = !left;
                            llSetPrimitiveParams([PRIM_ROTATION,r2, PRIM_POSITION, fpos]);
                            if (left)   setPose(walkl);
                            else    setPose(walkr);
                            if (llFrand(1.)< 0.1) baah();
                            initpos = fpos;
                        }
                    }
                }
                integer ts = llGetUnixTime();
                if (ts > lastTs + 100)
                {
                    refresh();
                    lastTs = ts;
                }
                if (epoch == 0)  llSetTimerEvent(300);
                else
                {
                    if (status == "DEAD")
                    {
                        llSetTimerEvent(0);
                        return;
                    }
                    else if (followUser == NULL_KEY)
                    {
                        if (isHuman == TRUE) llSetTimerEvent(llFrand(10)); else llSetTimerEvent(lifeFactor+ (integer)llFrand(20));
                        move();
                    }
                }
                checkListen();
            }
        }
        else
        {
            setPose(down);
        }
    }

    listen(integer c, string n ,key id , string m)
    {
        if (m == TXT_MATE)
        {
            status = "WaitMate";
            lastUser = id;
            llSensor(llGetObjectName(), "", SCRIPTED, RADIUS*2, PI);
        }
        else if (m == TXT_FOLLOW_ME)
        {
            followUser = id;
            if (followUser != NULL_KEY)
            {
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|1");
                llSetTimerEvent(.5);
            }
            happy = 100;
        }
        else if (m == TXT_OPTIONS)
        {
            showOptionsMenu(id);
        }
        else if (m == TXT_CHATTY)
        {
            CHATTY = TRUE;
            llRegionSayTo(id, 0, TXT_SPEAK);
            showOptionsMenu(id);
        }
        else if (m == TXT_QUIET)
        {
            CHATTY = FALSE;
            llRegionSayTo(id, 0, TXT_NO_SPEAK);
            showOptionsMenu(id);
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + SUFFIX, id);
        }
        else if (m == TXT_INFO)
        {
            float days = (age/86400.0);
            string str = TXT_I_AM +" " +(integer)days +" " +TXT_DAYS_OLD +" ";
            if (isPet == TRUE) str+= TXT_PET+" ";
            str += AN_NAME;
            if (isHuman == FALSE)
            {
                str += " [";
                if (sex == "Female") str += TXT_FEMALE_SYMBOL; else str += TXT_MALE_SYMBOL;
                str += "] ";
            }
            if (isPet == FALSE)
            {
                if (isHuman == FALSE)
                {
                    str += TXT_EAT_FROM +" " +AN_FEEDER+". ";
                    if (AN_HASMILK) str += TXT_FEMALES_GIVE +" " +MILK_OBJECT+ " " +TXT_EVERY +" " +(string)llRound(MILKTIME/3600)+" " +TXT_HOURS + ". ";
                    if (AN_HASMANURE) str += TXT_ADULTS_GIVE +" " +MANURE_OBJECT +" " +TXT_EVERY + " "+(string)llRound(MANURETIME/3600)+" " +TXT_HOURS +". ";
                    if (LAYS_EGG==0) str += TXT_PREGNANCY +" " +(string)(PREGNANT_TIME/86400) +" " +TXT_DAYS +". ";
                    str += TXT_LIVES +" " +(string)(LIFETIME/86400) +" " +TXT_DAYS;
                }
                str += ". ";
                if (AN_HASWOOL) str += TXT_ADULTS_GIVE  +" " +WOOL_OBJECT +" " +TXT_EVERY +" " +(string)llRound(WOOLTIME/3600)+" " +TXT_HOURS + ". ";
            }
            str += "  " +TXT_INFO_MSG;
            str += "\n[" +TXT_ANIMAL_VERSION +" " +qsFloat2String(VERSION, 1, FALSE) +" ";
            if (RSTATE == 0) str+= " B"; else if (RSTATE == -1) str+= " RC";
            str += "]";
            string s = llGetObjectName();
            llSetObjectName(name);
            llRegionSayTo(id, 0, str);
            llSetObjectName(s);
        }
        else if (m == TXT_RANGE)
        {
            llTextBox(id, "\n"+TXT_SET_RANGE +" " +(string)RADIUS, chan(llGetKey()));
            status = "WaitRadius";
        }
        else if (m == TXT_SCALE)
        {
            llTextBox(id, "\n"+TXT_SET_SCALE +": " +qsFloat2String(scaleFactor, 2, FALSE), chan(llGetKey()));
            status = "WaitScale";
        }
        else if (m == TXT_WALK_ON_WHAT)
        {
            list opts = [TXT_FLAT, TXT_GROUND, TXT_WATER, TXT_CLOSE];
            llDialog(id, TXT_SET_RANGE +" " +SURFACE, opts, chan(llGetKey()) );
        }
        else if ((m == "-"+TXT_AUTO_MANURE) || (m == "+"+TXT_AUTO_MANURE))
        {
            AN_AUTO_POO = !AN_AUTO_POO;
            if (AN_AUTO_POO == TRUE) llRegionSayTo(id, 0, TXT_AUTO_MANURE +": " +TXT_ON); else llRegionSayTo(id, 0, TXT_AUTO_MANURE +": " +TXT_OFF);
            showOptionsMenu(id);
        }
        else if ((m == "-"+TXT_SLEEP_MODE) || (m == "+"+TXT_SLEEP_MODE))
        {
            SLEEP_MODE = !SLEEP_MODE;

            if (SLEEP_MODE == TRUE)
            {
                llRegionSayTo(id, 0, TXT_SLEEP_MODE +": " +TXT_ON);
                if (qlDayCheck() == FALSE) llMessageLinked(LINK_SET, 1, "EXPRESSION|SLEEP", ""); else llMessageLinked(LINK_SET, 1, "EXPRESSION|WAKE", "");
            }
            else
            {
                llRegionSayTo(id, 0, TXT_SLEEP_MODE +": " +TXT_OFF);
                llMessageLinked(LINK_SET, 1, "EXPRESSION|WAKE", "");
                sleeping = TRUE;
            }
            showOptionsMenu(id);
        }
        else if (m == TXT_FLAT || m == TXT_GROUND || m == TXT_WATER )
        {
            if (m == TXT_GROUND)
            {
                SURFACE = "ground";
                llRegionSayTo(id, 0, TXT_OK_GROUND);
                showOptionsMenu(id);
            }
            else if (m == TXT_WATER)
            {
                SURFACE = "water";
                llRegionSayTo(id, 0, TXT_OK_WATER);
                showOptionsMenu(id);
            }
            else
            {
                SURFACE = "flat";
                llRegionSayTo(id, 0, TXT_OK_FLAT);
                showOptionsMenu(id);
            }
        }
        else if (m == TXT_FLOAT_TEXT)
        {
            list opts = [TXT_FLOAT_FULL, TXT_FLOAT_SHORT, TXT_FLOAT_NONE, TXT_CLOSE];
            llDialog(id, "\n" +TXT_SELECT, opts, chan(llGetKey()) );
        }
        else if (m == TXT_SOUNDS)
        {
            list opts = [TXT_CHATTY, TXT_QUIET, TXT_SILENT, TXT_CLOSE];
            llDialog(id, "\n" +TXT_SELECT, opts, chan(llGetKey()) );
        }
        else if (m == TXT_SET_NAME)
        {
            llTextBox(id, TXT_SETNAME_TO, chan(llGetKey()));
            status = "WaitName";
        }
        else if (m == TXT_HOME)
        {
            initpos = llGetPos();
            llSetTimerEvent(5);
            llRegionSayTo(id, 0, TXT_HOME_REPLY);
            refresh();
        }
        else if (m == TXT_STOP)
        {
            followUser = NULL_KEY;
            llStopSound();
            setPose(down);
            initpos = llGetPos();
            llSetTimerEvent(5);
            llRegionSayTo(id, 0, TXT_STOP_REPLY);
        }
        else if (m == TXT_BUTCHER)
        {
            if ((energy >0) || (energy =-1))
            {
                say(0, TXT_GOODBYE, id);
                death(0);
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|-5");
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Energy|-1");
            }
            else
            {
                llRegionSayTo(lastUser, 0, TXT_LOW_ENERGY);
            }
            return;
        }
        else if (m == TXT_WALK_ON || m == TXT_WALK_OFF)
        {
            IMMOBILE = (m == TXT_WALK_OFF);
            llRegionSayTo(id, 0, TXT_ALLOW_WALK +"="+(string)(!IMMOBILE));
            showOptionsMenu(id);
        }

        else if (m == TXT_FLOAT_FULL || m == TXT_FLOAT_SHORT || m == TXT_FLOAT_NONE)
        {
            if      (m == TXT_FLOAT_SHORT) labelType = 1;
            else if (m == TXT_FLOAT_NONE)  labelType = 2;
            else if (m == TXT_FLOAT_FULL)  labelType = 0;
            refresh();
            showOptionsMenu(id);
        }
        else if (m == TXT_MILK || m == TXT_GET_EGGS)
        {
            if ( happy< 0)
            {
                say(0, TXT_NOT_HAPPY, id);
                return;
            }

            if (sex == "Female" && AN_HASMILK)
            {
                say(0, TXT_HERE_IS +" "+MILK_OBJECT, id);
                //llRezObject(MILK_OBJECT, llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +MILK_OBJECT, NULL_KEY);
                milkTs = llGetUnixTime();
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|5");
                refresh();
            }
        }
        else if (m == TXT_GET_MANURE)
        {
            rezManure(id);
            say(0, TXT_GIVE_MANURE, id);
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Hygiene|-1");
        }
        else if (m == TXT_WOOL && AN_HASWOOL)
        {
                say(0, TXT_GIVE_WOOL, id);
                //llRezObject(WOOL_OBJECT, llGetPos() +<0,0,1> , ZERO_VECTOR, ZERO_ROTATION, 1 );
                llMessageLinked(LINK_SET, 0, "REZ_PRODUCT|" +PASSWORD +"|" +(string)lastUser +"|" +WOOL_OBJECT, NULL_KEY);
                woolTs = llGetUnixTime();
                happy=100;
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|5");
                refresh();
        }
        else if (m == TXT_PET)
        {
            string str = llList2String(petResponses, (integer)llFrand(llGetListLength(petResponses)));
            str = osReplaceString(str, "%NAME%", llKey2Name(id), -1, 0 );
            str = osReplaceString(str, "%OWNER%", llKey2Name(llGetOwner()), -1, 0);
            say(0, str, id);
            integer chatState = CHATTY;
            CHATTY = TRUE;
            if (food < 0 && water <0) say(0, AN_BAAH+", " +TXT_HUNGRY_THIRSTY, id);
            else if (food < 0) say( 0,AN_BAAH+", " +TXT_HUNGRY, id);
            else if (water < 0) say( 0, AN_BAAH+", " +TXT_THIRSTY, id);
            CHATTY = chatState;
            if (happy < 90) llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|5");
            happy = 100;
            refresh();
        }
        else if (m == TXT_CHATTY)
        {
            CHATTY = 0;
            llRegionSayTo(id, 0, TXT_SPEAK);
            showOptionsMenu(id);
        }
        else if (m == TXT_QUIET)
        {
            CHATTY = 1;
            llRegionSayTo(id, 0, TXT_NO_SPEAK);
            showOptionsMenu(id);
        }
        else if (m == TXT_SILENT)
        {
            CHATTY = -1;
            llRegionSayTo(id, 0, TXT_SILENT_MODE);
            showOptionsMenu(id);
        }
        else if (status == "WaitRadius")
        {
            RADIUS = (integer)m;
            if (RADIUS<1) RADIUS = 1;
            llRegionSayTo(id, 0, TXT_RESPONSE_MOVE +" " +(string)RADIUS +" m");
            status = "OK";
            showOptionsMenu(id);
        }
        else if (status == "WaitScale")
        {
            scaleFactor = (float)m;
            if (scaleFactor < 0.1) scaleFactor = 0.1;
                else if (scaleFactor > 10) scaleFactor = 10;
            status = "OK";
            move();
            showOptionsMenu(id);
        }
        else if (status =="WaitName")
        {
            name = m;
            llRegionSayTo(id, 0, TXT_GREET_YOU+" " +name+"!");
            status ="OK";
            happy=100;
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)id +"|Health|1");
            refresh();
            showOptionsMenu(id);
        }
    }

    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m , ["|"], []);
        if (llList2String(tk,1) == PASSWORD)
        {
            string cmd = llList2String(tk,0);
            if (cmd == "HEALTH")
            {
                if ((llList2String(tk, 2) == "ENERGY") && (llList2Key(tk, 3) == lastUser))
                {
                    energy = llList2Integer(tk, 4);
                    hudDetected = TRUE;
                    return;
                }
            }
            //for updates
            if (cmd == "VERSION-CHECK")
            {
                string answer = "VERSION-REPLY|" + PASSWORD + "|";
                integer ver = (integer)(VERSION*10);
                answer += (string)llGetKey() + "|" + (string)ver + "|";
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
                answer += statusNC+"|" +me;
                messageObj(llList2Key(tk, 2), answer);
            }
            if (cmd == "SEND-STATUSNC")
            {
                if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
                {
                    backupNC();
                    llGiveInventory(llList2Key(tk, 2), statusNC);
                    llSleep(0.1);
                    messageObj(llList2Key(tk, 2), "STATUSNC-SENT|"+PASSWORD+"|"+llGetObjectDesc() +"|" +(string)savedRot +"|" +(string)savedPos);
                }
            }
            else if (cmd == "KILL-STATUSNC")
            {
                backupNC();
                if (llGetInventoryType(statusNC) == INVENTORY_NOTECARD)
                {
                    llRemoveInventory(statusNC);
                    llSleep(0.2);
                }
                status = "waitStatusNC";
                messageObj(llList2Key(tk, 2), "STATUSNC-DEAD|"+PASSWORD+"|"+llGetKey());
            }
            else if (cmd == "GET-STATUSNC")
            {
                string count = ".";
                do
                {
                    llSetText("", PINK, 1.0);
                    llSleep(1.0);
                    count += ".";
                }
                while (llGetInventoryType(statusNC) != INVENTORY_NOTECARD);
                //
                llSetText("---", PINK, 1.0);
                llSetObjectDesc(llList2String(tk, 2));
                llSleep(1.0);
                savedRot = llList2Rot(tk, 3);
                savedPos = llList2Vector(tk, 4);
                if (isAttached == TRUE)
                {
                    llSetRot(savedRot);
                    llSetPos(savedPos);
                }
                llSleep(0.5);
                llMessageLinked(LINK_SET, 1, "reset", "");
                llSleep(0.5);
                llSetText("", ZERO_VECTOR, 0.0);
                llResetScript();
            }
            else if (cmd == "STATS-CHECK")
            {
                string answer = "STATS-REPLY|" + PASSWORD + "|";
                // answer += sex|happy|food|water
                answer += sex + "|" + (string)happy + "|" + (string)food + "|" + (string)water + "|";
                messageObj(llList2Key(tk, 2), answer);
                seeMe();
                if (happy <0) llSetColor(<1,0,0>, ALL_SIDES);
            }
            else if (cmd == "DO-UPDATE")
            {
                if (llGetOwnerKey(kk) != llGetOwner())
                {
                    llSay(0, TXT_ERROR_UPDATE);
                    return;
                }
                upgradeFlag = TRUE;
                upgradeHold = createdTs;
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
                    llOwnerSay(TXT_UPDATE_REMOVE);
                    llRemoveInventory(me);
                }
                llSleep(10.0);
                llResetScript();
            }
            else if (cmd =="SETCONFIG")
            {
                if (llGetOwnerKey(kk) == llGetOwner())
                    setConfig(llList2String(tk,2));
            }
            else if (cmd == "MATEME" ) //Male part
            {
                    if (epoch != 2)
                    {
                        say(0,  TXT_MATE_ERROR1, NULL_KEY);
                        return;
                    }
                    else if (sex != "Male")
                    {
                        say(0, TXT_MATE_ERROR2, NULL_KEY);
                        return;
                    }

                    key partner = llList2Key(tk,2);

                    list ud =llGetObjectDetails(partner, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
                    llSetKeyframedMotion( [], []);
                    llSleep(.2);
                    list kf;
                    vector mypos = llGetPos();
                    vector v = llList2Vector(ud, 1) + <-.3,  .0, 0.3> * llList2Rot(ud,2);

                    rotation trot  =  llList2Rot(ud,2);
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;

                    kf += ZERO_VECTOR;
                    kf += (trot/llGetRot()) ;
                    kf += .4;
                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += 3;
                    kf += ZERO_VECTOR;
                    kf += llEuler2Rot(<0,-.3,0>);
                    kf += .4;

                    integer k = 7;
                    while (k-->0)
                    {
                        kf += <0.2, 0,0>*trot;
                        kf += ZERO_ROTATION;
                        kf += .6;

                        kf += <-0.2, 0,0>*trot;
                        kf += ZERO_ROTATION;
                        kf += .6;
                    }
                    kf += ZERO_VECTOR;
                    kf += llEuler2Rot(<0, .3, 0>);
                    kf += .3;
                    kf += <-1, 1, -0.3>*trot;
                    kf += ZERO_ROTATION;
                    kf += 2.;

                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    llSleep(5);
                    hearts();
                    llSleep(8);
                    llParticleSystem([]);
                    messageObj(partner, "BABY|"+PASSWORD+"|"+(string)llGetKey() +"|"+ (string)geneA + "|"+ (string)geneB+ "|" +name);
                    happy=100;
            }
            else if (cmd  == "BABY") //Female part
            {
                if (pregnantTs<=0)
                {
                    fatherName = llList2String(tk, 5);
                    fatherGene = (integer)llList2String( tk, 3 + (integer)llFrand(2) ) ; // 3 or 4
                    if (LAYS_EGG)
                    {
                        //Force egg by seting pregancy to last 1 second (not 0 as will make a n/zero sum)
                        PREGNANT_TIME=1;
                        pregnantTs = llGetUnixTime()-100;
                    }
                    else
                        pregnantTs = llGetUnixTime();
                    llSleep(2);
                    refresh();
                    happy=100;
                    llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)lastUser +"|Health|2");
                }
            }
            else if (cmd == "INIT")
            {
                // INIT|PASSWORD|geneA|fatherGene|newName|lang|SURFACE|CHATTY|labelType|RADIUS
                RADIUS = llList2Integer(tk, 9);
                labelType = llList2Integer(tk, 8);
                CHATTY = llList2Integer(tk, 7);
                SURFACE = llList2String(tk, 6);
                languageCode = llList2String(tk, 5);
                name = llList2String(tk, 4);
                geneA =  llList2Integer(tk, 2);
                geneB = llList2Integer(tk, 3);
                setGenes();
                llRemoveInventory("setpin");
                if (LAYS_EGG==0) say(0, TXT_HELLO, NULL_KEY);
                saveState();
                refresh();
                llSetTimerEvent(2);
            }
            else if (cmd == "WATER")
            {
                say(1, TXT_DRINK, NULL_KEY);
                water = 100.0;
                refresh();
            }
            else if (cmd == "FOOD")
            {
                say(1, TXT_EAT, NULL_KEY);
                food = 100.0;
                refresh();

            }
            else if (cmd == "ADDDAY")
            {
               createdTs -= 86400;
               refresh();
               llOwnerSay("CreatedTs="+(string)createdTs);
            }
            else if (cmd == "PETIFY")
            {
                //     (aniID, cmd+"|"+PASSWORD+"|"+(string)FORCE_ADULT+"|"+(string)requireFeeding);
                llSetColor(GREEN, ALL_SIDES);
                llSetAlpha(1.0, ALL_SIDES);
                isPet = TRUE;
                if (llList2Integer(tk, 2) == 1)
                {
                    epoch = 2;
                    if (age > lifeTime) age = lifeTime - 172800; // take off 2 days
                    showAlphaSet(epoch);
                }
                if (llList2Integer(tk, 3) == 1) feedPet = TRUE; else feedPet = FALSE;
                saveState();
                llSleep(2.0);
                refresh();
                llSetAlpha(0.0, ALL_SIDES);
            }
            else if (cmd == "DEPETIFY")
            {
                llSetColor(AQUA, ALL_SIDES);
                llSetAlpha(1.0, ALL_SIDES);
                isPet = FALSE;
                saveState();
                llSleep(2.0);
                refresh();
                llSetAlpha(0.0, ALL_SIDES);
            }
            //
            if ((food > 50) && (water > 50)) happy = 100.0;
        }
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if (status == "WaitMate")
        {
            string details;
            list desc;
            integer foundCheck = FALSE;
            integer i = 0;
            while (i < n)
            {
                id = llDetectedKey(i);
                details = llList2String(llGetObjectDetails(id,[OBJECT_DESC]), 0);
                desc = [] + llParseStringKeepNulls(details, [";"], []);
                // Check if animal is an adult male
                if ((llList2Integer(desc,1) == 0) && (llList2Integer(desc, 17) == 2))
                {
                    llSetTimerEvent(15); // dont move
                    messageObj(id,  "MATEME|"+PASSWORD+"|"+(string)llGetKey());
                    foundCheck = TRUE;
                    i = n;
                }
                i ++;
            }
            if (foundCheck == FALSE) say(0, TXT_MATE_ERROR2, NULL_KEY);
        }
        else //feeder
        {
            string desc;
            integer level;
            list enough_food = [];
            list enough_water = [];
            while (n--)
            {
                desc = llList2String(llGetObjectDetails(llDetectedKey(n), [OBJECT_DESC]), 0);
                // Very old grass feeders didn't store status in description
                if (llGetListLength(llParseString2List(desc, [";"], [])) <2)
                {
                    enough_water += [llDetectedKey(n)];
                    enough_food += [llDetectedKey(n)];
                }
                else
                {
                    level = llList2Integer(llParseString2List(desc, [";"], []), 2);
                    if (level >= WATERAMOUNT)
                    {
                        enough_water += [llDetectedKey(n)];
                    }
                    level = llList2Integer(llParseString2List(desc, [";"], []), 3);
                    if (level >= FEEDAMOUNT)
                    {
                        enough_food += [llDetectedKey(n)];
                    }
                }
            }

            integer length = llGetListLength(enough_food);
            if (food < 5 && length)
            {
                key rand_feeder = llList2Key(enough_food, llFloor(llFrand(length)));
                messageObj(rand_feeder, "FEEDME|"+PASSWORD+"|"+ llGetKey() + "|" + (string)FEEDAMOUNT);
            }

            length = llGetListLength(enough_water);
            if (water < 5 && length)
            {
                key rand_feeder = llList2Key(enough_water, llFloor(llFrand(length)));
                messageObj(rand_feeder, "WATERME|"+PASSWORD+"|"+ (string)llGetKey() + "|"+ (string)WATERAMOUNT);
            }
        }
    }

    no_sensor()
    {
        if (status == "WaitMate")
        {
            say(0, TXT_MATE_ERROR2, NULL_KEY);
        }
        status = "OK";
    }

    touch_start(integer n)
    {
        if (TOUCH_ACTIVE == TRUE)
        {
            doTouch(llDetectedKey(0));
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message: " + str);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh();
        }
        else if (cmd == "ANIMALTOUCH")
        {
            doTouch(id);
        }
        else if (cmd == "MOVEMENT_SET")
        {
            blockMove = num;
            refresh();
        }
        else if (cmd == "SAVE_POS")
        {
            llOwnerSay("SAVE_POS");
            //savedPos = llList2Vector(tk, 1);
        }
        else if (cmd == "SAVE_ROT")
        {
            "SAVE_ROT";
            //savedRot = llList2Rot(tk, 1);
        }
    }

    attach(key id)
    {
        if (id != NULL_KEY)
        {
            loadState();
            isAttached = TRUE;
            llSetRot(savedRot);
            llSetPos(savedPos);
            llMessageLinked(LINK_SET, 0, "FORCE_SLEEP", "");
            refresh();
        }
        else
        {
            isAttached = FALSE;
            llSetRot(ZERO_ROTATION);
        }
    }

}
