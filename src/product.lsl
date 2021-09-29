// CHANGE LOG
//  Added extra check on touch for checking if script is not in a product and hence shouldn't run

/** #product.lsl

 For Text and Flow colour, can specify ZERO_VECTOR or OFF as the colour to make it 'invisible'
 Drop a sound inside the product object that will be played when using the object
 Drop a texture inside the product for the particles rezzed when used

**/
float  VERSION = 5.1;   // 28 November 2020
integer RSTATE = 1;     // RSTATE: 1=release, 0=beta, -1=RC
//
integer DEBUGMODE = FALSE;    // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}
//
// Config notecard can overide these:
vector  FLOWCOLOR = <1.0, 0.805, 0.609>;    // FLOWCOLOR=<1.0, 0.805, 0.609>
vector  TEXTCOLOR = <1.0, 1.0, 1.0>;        // TEXTCOLOR=<1.0, 1.0, 1.0>
integer DRINKABLE = -1;                     // MATURATION=
string  extraParam;                         // Params to be passed from config notecard to the target object
integer RANDOMIZE = 0;                      // RANDOMIZE=
string  TARGET;                             // TARGET=
integer EXPIRES = 7;                        // EXPIRES=-7
string  languageCode = "en-GB";             // LANG=en-GB
string  SUFFIX = "P1";
// Multilingual defaults
string TXT_EXPIRES_IN="Expires in";
string TXT_DAYS="days";
string TXT_EXPIRED="I have expired! Removing...";
string TXT_NOT_READY="Not ready yet...";
string TXT_I_NOT_READY="I am not ready yet";
string TXT_DAYS_LEFT="days left";
string TXT_LEFT="left";
string TXT_LOOKING_FOR="Looking for";
string TXT_NOT_ENOUGH="There is not enough left";
string TXT_NOT_FOUND="not found";
string TXT_UNABLE_TO_GET="Unable to get to any";
string TXT_FOOD="Food";
string TXT_DRINK="Drink";
string TXT_BOOZE="Booze";
string TXT_MEDICINE="Medicine";
string TXT_LOCKED="Locked";
string TXT_NO_KEY="Sorry, you don't have the key";
//
list colorList = [<1,1,1>, <0.292, 0.229, 0.210>, <0.406, 1.000, 0.704>, <1.000, 0.794, 0.586>, <1.000, 1.000, 0.502>, <1.000, 0.555, 1.000>];
key targetID = NULL_KEY;
key     followUser=NULL_KEY;
key     healthUser;
list    healthInfo;
float   uHeight=0;
integer lastTs;
integer initTs;
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer percent  = 100;
string  pubKey = "#";
integer locked = FALSE;
integer locIndex;
string  status;
list    extraInfo;  // For things like provisions box etc

string myName()
{
    return llGetSubString(llGetObjectName(), 3, -1);
}

list decodeList(list tokens)
{
    integer i;
    list out =[];
    for (i=0; i < llGetListLength(tokens); i+=2)
    {
        string tp = llList2String(tokens, i);
        if (tp =="I") out += llList2Integer(tokens, i+1);
        else if (tp =="V") out += llList2Vector(tokens, i+1);
        else if (tp =="R") out += llList2Rot(tokens, i+1);
        else if (tp =="K") out += llList2Key(tokens, i+1);
        else if (tp =="F") out += llList2Float(tokens, i+1);
        else if (tp =="S") out += llList2String(tokens, i+1);
    }
    return out;
}

emptyTarget()
{
    if (targetID != NULL_KEY)
    {
        // Let target know it's empty again
        messageObj(targetID, "EMPTY|" + (string)locIndex);
        locIndex = -1;
        targetID = NULL_KEY;
    }
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

refresh()
{
    vector textColor = TEXTCOLOR;
    integer days = llFloor((llGetUnixTime()- initTs)/86400);
    string str = myName();
    if (locked == TRUE) str += " [" +TXT_LOCKED +"]";
    str += "\n";
    string extraStr = "";
    if (EXPIRES>0)
    {
        if (EXPIRES > 1 && (EXPIRES-days) < 2)
        {
            textColor = <1.000, 0.255, 0.212>;
        }
        str += TXT_EXPIRES_IN + " "+(string)(EXPIRES-days)+ " " +TXT_DAYS + "\n";
        if (days >= EXPIRES)
        {
            llSay(0, TXT_EXPIRED);
            emptyTarget();
            llDie();
        }
    }

    if ((DRINKABLE-days)>0)
    {
        textColor = <1.000, 0.863, 0.000>;
        str += TXT_NOT_READY +"..." +(string)(DRINKABLE-days)+" " +TXT_DAYS_LEFT +"\n";
    }
    else
    {
        if (percent<100)
        {
           str += (string)percent+ "% "+TXT_LEFT+"\n";
        }
    }

    if (llGetListLength(extraInfo) >0)
    {

        str += TXT_FOOD+"\t"+TXT_DRINK+"\t"+TXT_BOOZE+"\t"+TXT_MEDICINE+"\n";
        integer i;
        for (i=0; i < llGetListLength(extraInfo); i++)
        {
            str += llList2String(extraInfo, i) + "\t \t";
            extraStr += llList2String(extraInfo, i) +";";
        }
    }
    if (RSTATE == 0) str+= "\n-B-"; else if (RSTATE == -1) str+= "\n-RC-";
    if (TEXTCOLOR != ZERO_VECTOR)
    {
        llSetText(str, textColor, 1.0);
    }
    else
    {
        if (percent <100) llSetText((string)percent+ "% "+TXT_LEFT, <0.169, 0.206, 0.181>, 0.25); else llSetText("", ZERO_VECTOR, 0.0);
    }
    llSetObjectDesc("P;" +(string)percent+";" +(string)(EXPIRES-days)+";" +(string)(DRINKABLE-days)+";" +languageCode+";" +pubKey+";" +(string)initTs+";" +extraStr);
}

water(key u)
{
    if (FLOWCOLOR != ZERO_VECTOR)
    {
        llParticleSystem(
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_BURST_RADIUS,.2,
            PSYS_SRC_ANGLE_BEGIN,0.,
            PSYS_SRC_ANGLE_END,.5,
            PSYS_PART_START_COLOR,FLOWCOLOR,
            PSYS_PART_END_COLOR,FLOWCOLOR,
            PSYS_PART_START_ALPHA,.9,
            PSYS_PART_END_ALPHA,.0,
            PSYS_PART_START_GLOW,0.0,
            PSYS_PART_END_GLOW,0.0,
            PSYS_PART_START_SCALE,<.1000000,.1000000,0.00000>,
            PSYS_PART_END_SCALE,<.9000000,.9000000,0.000000>,
            PSYS_SRC_TEXTURE,llGetInventoryName(INVENTORY_TEXTURE,0),
            PSYS_SRC_TARGET_KEY, u,
            PSYS_SRC_MAX_AGE,3,
            PSYS_PART_MAX_AGE,4,
            PSYS_SRC_BURST_RATE, .01,
            PSYS_SRC_BURST_PART_COUNT,3,
            PSYS_SRC_ACCEL,<0.000000,0.000000,-1.1>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,1,
            PSYS_SRC_BURST_SPEED_MAX,2,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_TARGET_POS_MASK |
                PSYS_PART_INTERP_COLOR_MASK |
                PSYS_PART_INTERP_SCALE_MASK
        ] );
    }
    llTriggerSound(llGetInventoryName(INVENTORY_SOUND,0), 1.0);
}

reset()
{
    initTs = llGetUnixTime();
    lastTs = -1;
    llParticleSystem([]);
    llSetTimerEvent(900);
    refresh();
}

setConfig(string line)
{
    list tok = llParseString2List(line, ["="], []);
    if (llList2String(tok,1) != "")
    {
        string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
        string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
             if (cmd == "EXPIRES")     EXPIRES = (integer)val;
        else if (cmd == "MATURATION")  DRINKABLE = (integer)val;
        else if (cmd == "EXTRAPARAM")  extraParam = val;
        else if (cmd == "RANDOMIZE")   RANDOMIZE = (integer)val;
        else if (cmd == "TARGET")      TARGET = val;
        else if (cmd == "LANG")        languageCode = val;
        else if (cmd == "FLOWCOLOR")
        {
            if ((val == "ZERO_VECTOR") || (val == "OFF")) FLOWCOLOR = ZERO_VECTOR; else FLOWCOLOR = (vector)val;
        }
        else if (cmd == "TEXTCOLOR")
        {
            if ((val == "ZERO_VECTOR") || (val == "OFF")) TEXTCOLOR = ZERO_VECTOR; else TEXTCOLOR = (vector)val;
        }
    }
}

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        if (llGetSubString(llList2String(lines,i), 0, 0) != "#")
        {
            setConfig(llList2String(lines,i));
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
                         if (cmd == "TXT_EXPIRES_IN")  TXT_EXPIRES_IN = val;
                    else if (cmd == "TXT_DAYS")       TXT_DAYS = val;
                    else if (cmd == "TXT_EXPIRED") TXT_EXPIRED = val;
                    else if (cmd == "TXT_NOT_READY") TXT_NOT_READY = val;
                    else if (cmd == "TXT_I_NOT_READY") TXT_I_NOT_READY = val;
                    else if (cmd == "TXT_DAYS_LEFT") TXT_DAYS_LEFT = val;
                    else if (cmd == "TXT_LEFT") TXT_LEFT = val;
                    else if (cmd == "TXT_LOOKING_FOR") TXT_LOOKING_FOR = val;
                    else if (cmd == "TXT_NOT_ENOUGH") TXT_NOT_ENOUGH = val;
                    else if (cmd == "TXT_NOT_FOUND") TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_UNABLE_TO_GET") TXT_UNABLE_TO_GET = val;
                    else if (cmd == "TXT_FOOD") TXT_FOOD = val;
                    else if (cmd == "TXT_DRINK") TXT_DRINK = val;
                    else if (cmd == "TXT_BOOZE") TXT_BOOZE = val;
                    else if (cmd == "TXT_MEDICINE") TXT_MEDICINE = val;
                    else if (cmd == "TXT_LOCKED") TXT_LOCKED = val;
                    else if (cmd == "TXT_NO_KEY") TXT_NO_KEY = val;
                }
            }
        }
    }
}

integer inProduct()
{
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    if ((llGetInventoryType("prod-rez_plugin") == INVENTORY_SCRIPT) ||  (llGetSubString(llGetObjectName(), 0, 9) == "SF Updater") ||  (llGetObjectName() == "SF Resource Manager"))
    {
        llSetScriptState(llGetScriptName(), FALSE);
        llSleep(0.2);
        return FALSE;
    }
    else return TRUE;
}


default
{

    on_rez(integer n)
    {
        llSetObjectDesc("");
        llResetScript();
    }

    state_entry()
    {
        // Dont run this script in rezzer, updaters or the resource manager
        if (inProduct() == FALSE) llWhisper(0, "self check");
        integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
        if ((llGetInventoryType("prod-rez_plugin") == INVENTORY_SCRIPT) ||  (llGetSubString(llGetObjectName(), 0, 9) == "SF Updater") ||  (llGetObjectName() == "SF Resource Manager"))
        {
            llSetScriptState(llGetScriptName(), FALSE);
            return;
        }
        // If object description is blank, assume item not rezzed by prod-rez_plugin
        list descValues = llParseString2List(llGetObjectDesc(), ";", "");
        if (llGetListLength(descValues) == 0)
        {
            llSetText("", ZERO_VECTOR, 0.0);
            llSetRemoteScriptAccessPin(0);
        }
        else
        {
            string data = llList2String(descValues, 6);
            initTs = (integer)data;
        }

        loadConfig();
        loadLanguage(languageCode);
        if (RANDOMIZE != 0)
        {
            count = llCeil(llFrand(llGetListLength(colorList)));
            llSetLinkColor(RANDOMIZE, llList2Vector(colorList, count-1), ALL_SIDES);
        }

        if (TARGET != "")
        {
            if (llToLower(TARGET) != "avatar")
            {
                targetID = NULL_KEY;
                llSetKeyframedMotion( [], []);
                llSleep(2.0);
                // Look for an empty target
                llOwnerSay(TXT_LOOKING_FOR+" " + TARGET);
                llSensor(TARGET, NULL_KEY, PASSIVE | SCRIPTED, 20.0, PI );
            }
        }
        else
        {
            targetID = NULL_KEY;
        }
    }

    timer()
    {
        float t;
        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails(followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
            }
            else
            {
                llSetKeyframedMotion( [], []);
                llSleep(0.2);
                list kf;
                vector mypos = llGetPos();
                vector size  = llGetAgentSize(followUser);
                uHeight = size.z;
                vector v = llList2Vector(userData, 1)+ <2.1, -1.0, 1.0> * llList2Rot(userData,2);
                t = llVecDist(mypos, v)/10;
                if (t > 0.1)
                {
                    if (t > 5) t = 5;
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    //rotation r2 = llRotBetween(<1,0,0>,vn);
                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += t;
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    t+=1;
                }
                else t = 5.0;
            }
        }
        else
        {
            refresh();
            t = 900.0;
        }
        llSetTimerEvent(t);
    }

    touch_start(integer n)
    {
        llParticleSystem([]);
        // Sometimes this script has started running when it shouldn't so re-check!
        if (inProduct() == FALSE) llWhisper(0, "self check");

        if (llSameGroup(llDetectedKey(0))|| osIsNpc(llDetectedKey(0)))
        {
            if ((locked == TRUE) && (llDetectedKey(0) != llGetOwner()))
            {
                llRegionSayTo(llDetectedKey(0), 0, TXT_NO_KEY);
                return;
            }

            if (followUser == NULL_KEY)
            {
                followUser = llDetectedKey(0);
                // Following you so sending 'Empty Target' message
                emptyTarget();
                llSetTimerEvent(1.);
            }
            else
            {
                followUser = NULL_KEY;
                targetID = NULL_KEY;

                if (TARGET != "")
                {
                    llSetKeyframedMotion( [], []);
                    llSleep(.2);
                    // Look for an empty target
                    llOwnerSay(TXT_LOOKING_FOR+" "+TARGET);
                    llSensor(TARGET, NULL_KEY, PASSIVE | SCRIPTED, 20.0, PI );
                }
                else
                {
                    // No target so just go to ground
                    llSetPos( llGetPos()- <0,0, uHeight-.2> );
                }
            }
        }
    }

    dataserver(key id, string msg)
    {
        debug("dataserver:"+msg);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "DIE")
        {
            refresh();
            integer days = llFloor((llGetUnixTime()- initTs)/86400);
            if (DRINKABLE>0 && days < DRINKABLE)
            {
                llSay(0, TXT_I_NOT_READY);
                return;
            }

            integer consume = 100;// Default consume 100%
            if (llList2Integer(tk,2)>0)
                consume = llList2Integer(tk,2);

            if (percent < consume -1) //allow 1% more
            {
                llSay(0, TXT_NOT_ENOUGH);
                return;
            }

            key u = llList2Key(tk,1);
            rotation myRot = llGetRot();
            llSetRot(llEuler2Rot(<0, 45, 0>*DEG_TO_RAD) * myRot);

            if (llList2Integer(llGetObjectDetails(u, [OBJECT_ATTACHED_POINT]), 0)>0)
                water(llGetOwnerKey(u));
            else
                water(u);

            llSleep(2);
            percent -= consume;
            messageObj(u, llToUpper(myName())+"|"+PASSWORD +"|"+(string)percent+"|"+extraParam);
            if (percent <= 0)
            {
                emptyTarget();
                llDie();
                return;
            }
            llSleep(1);
            llParticleSystem([]);
            llSetRot(myRot);
            refresh();
        }
        else if (cmd == "INIT")
        {
            loadConfig();
            loadLanguage(languageCode);
            PASSWORD = llList2String(tk,1);
            llRemoveInventory("setpin");
            // newer systems also send the uuid of the user that was interacting with them
            if (llGetListLength(tk) > 2)
            {
                integer count;
                string tmpStr;
                integer i;

                if (llList2String(tk,2) == "STOREVALS")
                {
                    // foodStore|drinkStore|boozeStore|medicineStore|
                    tmpStr = "";
                    extraInfo = [];
                    for (i=0; i < llGetListLength(tk)-3; i++)
                    {
                        extraInfo += llList2Integer(tk, i+3);
                        tmpStr += "\n" +llList2String(tk, i+3);
                    }
                }
                // If not a command in (tk,2) assume is avatar uuid
                else
                {
                    healthUser = llList2String(tk,2);

                    if (llToLower(TARGET) == "avatar")
                    {
                        // kitchen.lsl can send params included in recipe
                        if (llList2String(tk,3) == "HEALTHPARAMS")
                        {
                            healthInfo = [];
                            // list tk   INIT|farm|e9623cc3-4a82-4685-b5a5-1bd500fe2af9|HEALTHPARAMS|Bladder:-30|Hygiene:-10
                            for (i=4; i<llGetListLength(tk); i ++)
                            {
                                healthInfo += llParseString2List(llList2String(tk,i), [":","|"], []);
                            }
                        }
                        else
                        {
                            // otherwise check this products config notecard
                            healthInfo = llParseString2List(extraParam, [":","|"], []);
                        }
                        if (llGetListLength(healthInfo) !=0)
                        {
                            llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)healthUser +"|" +llDumpList2String(healthInfo, "|"));
                            water(healthUser);
                            llSleep(0.5);
                            llDie();
                            return;
                        }
                        else
                        {
                            // avatar target but no extra params found...
                            reset();
                            return;
                        }
                    }
                }
            }
            reset();
        }
        else if (cmd == "LAND_HERE")
        {
            if (llSetRegionPos(llList2Vector(tk,1)) == TRUE)
            {
                llSetRot(llList2Rot(tk,3));
                string m = "";
                integer count;
                integer i;
                locIndex = llList2Integer(tk, 2);
                messageObj(targetID, "FOOD|" +(string)locIndex);
                healthInfo = llParseString2List(extraParam, [":","|"], []);
                count = llGetListLength(healthInfo);
                if (count !=0 )
                {
                    for (0; i<count; i+=2)
                    {
                        m += llList2String(healthInfo, i) +"|" + llList2String(healthInfo, i+1) +"|";
                    }
                    if ((lastTs == -1) || ( (llGetUnixTime()-lastTs) >60))
                    {
                        llRegionSay(FARM_CHANNEL, "HEALTH|" +PASSWORD +"|" +(string)healthUser +"|" +m);
                        water(healthUser);
                        lastTs = llGetUnixTime();
                    }
                }
            }
            else
            {
                // We coudn't find one we can get to
                llOwnerSay(TXT_UNABLE_TO_GET +" "+TARGET );
                targetID = NULL_KEY;
                llSetPos( llGetPos()- <0,0, uHeight-.2> );
            }
            llSleep(1);
        }
        //following commands require correct password
        if(llList2String(tk, 1) != PASSWORD)
        {
            return;
        }
        integer dayse = llFloor((llGetUnixTime()- initTs)/86400);

        if (cmd == "LANG")
        {
            if (llGetInventoryType(llList2String(tk,3)+"-lang-P") != -1)
            {
                llRemoveInventory(llList2String(tk,3)+"-lang-P");
                llSleep(0.1);
            }
            messageObj(llList2String(tk,2), "LANG_REPLY|" +PASSWORD+"|" + llGetKey() + "|"+llList2String(tk,3));
        }
        else if (cmd == "SETLANG")
        {
            languageCode = llList2String(tk,2);
            loadLanguage(languageCode);
            refresh();
            return;
        }
        else if (cmd == "LOCK")
        {
            pubKey = llList2String(tk, 2);
            locked = TRUE;
            refresh();
        }
        else if (cmd == "ACCESS")
        {
            messageObj(llList2Key(tk,2), "KEYCODE|" +PASSWORD+"|" +llGetKey()+"|" +pubKey);
        }
        else if (cmd == "RETRIEVE")
        {
            messageObj(llList2Key(tk,2), "fullProvisionsBox|" +PASSWORD+"|"+llDumpList2String(extraInfo, "|"));
            water(llList2Key(tk, 1));
            emptyTarget();
            llDie();
        }
        else if (cmd == "USE")
        {
            string consumeType = llList2String(tk, 2);
            integer val;

            if (consumeType == "Food")
            {
                val = llList2Integer(extraInfo, 0);
                if ( (val - 20) >= 0 )
                {
                    messageObj(llList2Key(tk,3), "CONFIRMPROV|" +PASSWORD +"|" +consumeType);
                    val -= 20;
                    extraInfo = [val, llList2Integer(extraInfo, 1), llList2Integer(extraInfo, 2), llList2Integer(extraInfo, 3)];
                    refresh();
                    return;
                }
            }
            else if (consumeType == "Drink")
            {
                val = llList2Integer(extraInfo, 1);
                if ( (val - 20) >= 0 )
                {
                    messageObj(llList2Key(tk,3), "CONFIRMPROV|" +PASSWORD +"|" +consumeType);
                    val -= 20;
                    extraInfo = [llList2Integer(extraInfo, 0), val, llList2Integer(extraInfo, 2), llList2Integer(extraInfo, 3)];
                    refresh();
                    return;
                }
            }
            else if (consumeType == "Booze")
            {
                val = llList2Integer(extraInfo, 2);
                if ( (val - 20) >= 0 )
                {
                    messageObj(llList2Key(tk,3), "CONFIRMPROV|" +PASSWORD +"|" +consumeType);
                    val -= 20;
                    extraInfo = [llList2Integer(extraInfo, 0), llList2Integer(extraInfo, 1), val, llList2Integer(extraInfo, 3)];
                    refresh();
                    return;
                }
            }
            else if (consumeType == "Medicine")
            {
                val = llList2Integer(extraInfo, 3);
                if ( (val - 20) >= 0 )
                {
                    messageObj(llList2Key(tk,3), "CONFIRMPROV|" +PASSWORD +"|" +consumeType);
                    val -= 20;
                    extraInfo = [llList2Integer(extraInfo, 0), llList2Integer(extraInfo, 1), llList2Integer(extraInfo, 2), val];
                    refresh();
                    return;
                }
            }
            messageObj(llList2Key(tk,3), "NOPROV|" +PASSWORD +"|" +consumeType);
        }
        else if (cmd == "QUERYVALUES")
        {
            messageObj(llList2Key(tk,2), "MYVALS|" +PASSWORD +"|" +extraParam);
        }
        else if (cmd =="SETOBJECTNAME")
        {
            llSetObjectName( llList2String(tk, 2) );
        }
        else if (cmd == "SETJUGCOLOR")
        {
            llSetLinkColor(2, llList2Vector(tk, 4), 0) ;
        }
        else if (cmd == "SETLINKNAMECOLOR")
        {
            integer i;
            for (i=1; i <= llGetNumberOfPrims(); i++)
            if (llGetLinkName(i) == llList2String(tk, 2))
            {
                llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, llList2Integer(tk, 3),
                    llList2Vector(tk, 4), llList2Float(tk, 5) ]);
            }
        }
        else if (cmd == "SETCONFIG")
        {
            setConfig(llList2String(tk, 2));
        }
        else if (cmd == "SETLINKPRIMITIVEPARAMS")
        {
            integer lnk = llList2Integer(tk, 2);
            list l = decodeList(llList2List(tk, 3, -1) );
            llSetLinkPrimitiveParamsFast(lnk, l);
        }
        else if (cmd == "SETLINKPARTICLESYSTEM")
        {
            integer lnk = llList2Integer(tk, 2);
            list l = decodeList(llList2List(tk, 3, -1) );
            llLinkParticleSystem(lnk, l);
        }
        else if (cmd == "SETLINKTEXTURE")
        {
            llSetLinkTexture( llList2Integer(tk, 2), llList2String(tk, 3), llList2Integer(tk, 4));
        }
        refresh();
    }

    no_sensor()
    {
        // We didn't find an empty target so just go to the ground
        llOwnerSay(TARGET +" - " + TXT_NOT_FOUND);
        targetID = NULL_KEY;
        llSetPos( llGetPos()- <0,0, uHeight-.2> );
    }

    sensor( integer num_detected )
    {
        // We found an empty target so ask it where to land
        targetID  = llDetectedKey(0);
        messageObj(targetID, "LAND_WHERE");
    }

}
