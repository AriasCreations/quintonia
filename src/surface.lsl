// surface.lsl
// Product holder for things like food, flowers etc
// Name for decoration prim (table cloth etc) should be 'Decor'
// Name for extra holders (such as plates etc) should be 'EMPTY'
//

float   VERSION = 4.3;    // Beta 7 December 2020
integer RSTATE  = 0;      // RSTATE = 1 for release, 0 for beta, -1 for Release candidate

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be set via config notecard
vector  CLOTHCOLOR = ZERO_VECTOR;   //  CLOTHCOLOR=     Set as a colour vector or the word  random
integer ROOT_SURFACE = FALSE;       //  ROOT_SURFACE=0  Is the root object a surface, 1=yes  0=no
integer EXPIRES = -1;               //  EXPIRES=        If specified, item will 'wear out' and need to be replaced
integer isMade = FALSE;             //  MANUFACTURED=0  If TRUE, item must be rezzed via kitchen.lsl script in order to work
integer embedded = TRUE;            //  EMBEDDED=1      If TRUE, then the surface functions are part of another item, so don't respond to touch
string  languageCode = "en-GB";     //  LANG=en-GB      etc
//
// Multilingual support

string TXT_FOLLOW_ME="Follow me";
string TXT_STOP="STOP";
string TXT_SELECT="Select";
string TXT_CLOSE="CLOSE";
string TXT_RESET="RESET";
string TXT_CONFIG_ERROR="Configuration error - please check config notecard";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_ERROR_GROUP="Error, we are not in the same group";
string TXT_LANGUAGE="@";

string  SUFFIX = "S2";
string  PASSWORD;
vector  GRAY = <0.207, 0.214, 0.176>;
vector  RED = <1.0, 0.0, 0.0>;
string  DECOR = "Decor";
integer decorPrim;
integer numberOfSurfaces;
integer usedCount;
integer lastTs;
key     followUser=NULL_KEY;
float   uHeight=0;
//
string  emptyName;
string  specialName;
list    customOptions = [];


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

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
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
            list tok = llParseString2List(llList2String(lines,i), ["="], []);
            if (llList2String(tok,1) != "")
            {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llList2String(tok, 1);
                if (cmd =="CLOTHCOLOR")
                {
                    if ((vector)val != ZERO_VECTOR) CLOTHCOLOR = (vector)val;
                }
                else if (cmd == "NAME")
                {
                    emptyName = val;
                    if (val != "") llSetObjectName(emptyName); else llSetObjectName("SF Surface");
                }
                else if (cmd == "EXPIRES") EXPIRES = (integer)val;
                else if (cmd == "MANUFACTURED") isMade = (integer)val;
                else if (cmd == "ROOT_SURFACE") ROOT_SURFACE = (integer)val;
                else if (cmd == "EMBEDDED") embedded = (integer)val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }
    if (isMade == FALSE) PASSWORD = osGetNotecardLine("sfp", 0);
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
                    else if (cmd == "TXT_RESET") TXT_RESET = val;
                    else if (cmd == "TXT_SELECT") TXT_SELECT = val;
                    else if (cmd == "TXT_FOLLOW_ME") TXT_FOLLOW_ME = val;
                    else if (cmd == "TXT_STOP") TXT_STOP = val;
                    else if (cmd == "TXT_CONFIG_ERROR") TXT_CONFIG_ERROR = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
    llMessageLinked(LINK_SET, 1, "LANG|SELECT|"+TXT_SELECT, "");
    llMessageLinked(LINK_SET, 1, "LANG|CLOSE|"+TXT_CLOSE, "");
 }


integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

resetObject()
{
    llSetObjectName(emptyName);
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
    {
        if (llGetLinkName(i) == ("FULL")) llSetLinkPrimitiveParamsFast(i, [PRIM_NAME, "EMPTY"]);
        if (llGetLinkName(i) == ("R-FULL")) llSetLinkPrimitiveParamsFast(i, [PRIM_NAME, "RESERVED"]);
    }
    usedCount = 0;
    if (decorPrim != -1) llSetLinkAlpha(decorPrim, 0.0, ALL_SIDES);
    lastTs = llGetUnixTime();
    llOwnerSay(TXT_RESET);
}

doDie(key objectKey)
{
    if (llGetListLength(llGetObjectDetails(objectKey, [OBJECT_NAME])) != 0)
    {
        llSetLinkColor(LINK_SET, GRAY, ALL_SIDES);
        osMessageObject(objectKey, "DIE|"+llGetKey()+"|100");
        llSleep(2.5);
    }
    llDie();
}

refresh()
{
    integer days = llFloor((llGetUnixTime()- lastTs)/86400);
    if (EXPIRES>0)
    {
        if (EXPIRES > 1 && (EXPIRES-days) < 2)
        {
            llSetLinkColor(LINK_SET, GRAY, ALL_SIDES);
        }
        if (days >= EXPIRES)
        {
            doDie(NULL_KEY);
        }
    }
    if (RSTATE == 0) llSetText("Beta", <0.522, 0.078, 0.294>, 1.00); else if (RSTATE == -1) llSetText("RC", <0.224, 0.800, 0.800>, 1.0); else llSetText("", ZERO_VECTOR, 0);
}



default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        loadConfig();
        if (emptyName == "") emptyName = "SF Surface";
        decorPrim = getLinkNum(DECOR);
        resetObject();
        if (ROOT_SURFACE == TRUE) numberOfSurfaces = 1; else numberOfSurfaces = 0;
        integer i;
        for (i=1; i <=llGetNumberOfPrims(); i++)
        {
            if (llGetLinkName(i) == "EMPTY") numberOfSurfaces +=1;
        }
        if (numberOfSurfaces <1)
        {
            // Something is not right!
            llOwnerSay(TXT_CONFIG_ERROR);
        }
        if (embedded == TRUE) llMessageLinked(LINK_SET, 99, "ADD_MENU_OPTION|"+TXT_RESET, "");
        llMessageLinked(LINK_SET, 99, "RESET", "");
    }

    touch_end(integer numb)
    {
        if (embedded == FALSE)
        {
            if (llDetectedKey(0) == llGetOwner())
            {
                list opts = [];
                if (followUser == NULL_KEY) opts += TXT_FOLLOW_ME; else opts += TXT_STOP;
                opts += [TXT_RESET, TXT_LANGUAGE];
                if (llGetListLength(customOptions) != 0) opts += customOptions;
                opts += [TXT_CLOSE];
                startListen();
                llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
                llSetTimerEvent(300);
            }
        }
    }

    listen(integer c, string nm, key id, string m)
    {
        //llSetTimerEvent(0);

        if (m == TXT_CLOSE)
        {
            checkListen(TRUE);
        }
        else if (m == TXT_FOLLOW_ME)
        {
            followUser = id;
        }
        else if (m == TXT_STOP)
        {
            followUser = NULL_KEY;
            // No target so just go to ground
            llSetPos( llGetPos()- <0,0, uHeight-.2> );
            checkListen(TRUE);
            llSetTimerEvent(0);
            return;
        }
        else if (m == TXT_RESET)
        {
            resetObject();
        }
        else if (m == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, id);
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        llSetTimerEvent(1.0);
    }


    timer()
    {
        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
            }
            else
            {
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector size  = llGetAgentSize(followUser);
                uHeight = size.z;
                vector v = llList2Vector(userData, 1)+ <2.1, -1.0, 1.0> * llList2Rot(userData,2);

                float t = llVecDist(mypos, v)/10;
                if (t > .1)
                {
                    if (t > 5) t = 5;
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    //rotation r2 = llRotBetween(<1,0,0>,vn);
                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += t;
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    llSetTimerEvent(t+1);
                }
            }
           return;
        }
        refresh();
        llSetTimerEvent(900);
    }


    dataserver(key query_id, string msg)
    {
        debug("dataserver: " + msg);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "INIT")
        {
            loadConfig();
            PASSWORD = llList2String(tk,1);
            resetObject();
            return;
        }

        if (PASSWORD == "")
        {
            doDie(query_id);
        }

        if (cmd == "DIE")
        {
            key u = llList2Key(tk,1);
            llSetRot(llEuler2Rot(<0,PI/1.4, 0>));
            llSleep(1);
            string myName = llGetSubString(llGetObjectName(), 3, -1);
            osMessageObject(u, llToUpper(myName)+"|"+PASSWORD +"|100|");
            llDie();
            return;
        }
        else if (cmd == "LAND_WHERE")
        {
            vector landPoint;
            integer primNum;
            if ((usedCount == 0) && (ROOT_SURFACE == TRUE))
            {
                landPoint = llGetPos();
                primNum = llGetLinkNumber();
            }
            else
            {
                primNum = getLinkNum("EMPTY");
                if (primNum != -1)
                {
                    landPoint = llList2Vector(llGetLinkPrimitiveParams(getLinkNum("EMPTY"), [PRIM_POSITION]),0);
                }
                else
                {
                    landPoint = llGetPos();
                }
            }
            if (landPoint != ZERO_VECTOR)
            {
                rotation ourRot = llGetRot();
                osMessageObject(query_id, "LAND_HERE|" +(string)landPoint +"|" +(string)primNum +"|" +(string)ourRot);
                debug("landPoint=" +(string)landPoint +"  primNum=" +(string)primNum +" rotation=" +(string)ourRot);
            }
        }
        else if (cmd == "WHERE_RESERVED")
        {
            vector landPoint;
            rotation ourRot;
            integer primNum = getLinkNum("RESERVED");
            if (primNum != -1)
            {
                list results = llGetLinkPrimitiveParams(getLinkNum("RESERVED"), [PRIM_POSITION, PRIM_ROTATION]);
                landPoint = llList2Vector(results, 0);
                ourRot = llList2Rot(results, 1);
            }
            else
            {
                landPoint = ZERO_VECTOR;
            }
            if (landPoint != ZERO_VECTOR)
            {
                osMessageObject(query_id, "LAND_HERE|" +(string)landPoint +"|" +(string)primNum +"|" +(string)ourRot);
                debug("landPoint=" +(string)landPoint +"  primNum=" +(string)primNum +" rotation=" +(string)ourRot);
            }
            else
            {

            }
        }
        else if (cmd == "FOOD")
        {
            if (usedCount == 0)
            {
                if (decorPrim != -1)
                {
                    if (CLOTHCOLOR == ZERO_VECTOR)
                    {
                        llSetLinkColor(decorPrim, <llFrand(1.0), llFrand(1.0), llFrand(1.0)>, ALL_SIDES);
                    }
                    else
                    {
                        llSetLinkColor(decorPrim, CLOTHCOLOR, ALL_SIDES);
                    }
                    llSetLinkAlpha(decorPrim, 1.0, ALL_SIDES);
                }
            }
            if (llList2Integer(tk, 1) !=1) llSetLinkPrimitiveParamsFast(llList2Integer(tk, 1), [PRIM_NAME, "FULL"]);
            usedCount +=1;
            if (usedCount >= numberOfSurfaces)
            {
                llSetObjectName(emptyName + "-FULL");
            }
        }
        else if (cmd == "VIP")
        {
            if (llList2Integer(tk, 1) != 1) llSetLinkPrimitiveParamsFast(llList2Integer(tk, 1), [PRIM_NAME, "R-FULL"]);
        }
        else if (cmd == "EMPTY")
        {
            llSetObjectName(emptyName);
            if (llList2String(llGetLinkPrimitiveParams(llList2Integer(tk, 1), [PRIM_NAME]), 0) == "FULL") llSetLinkPrimitiveParamsFast(llList2Integer(tk, 1), [PRIM_NAME, "EMPTY"]);
            usedCount -=1;
            if (usedCount <=0)
            {
                usedCount = 0;
                if (decorPrim != -1) llSetLinkAlpha(decorPrim, 0.0, ALL_SIDES);
            }
        }
        else if (cmd == "EMPTY_RESERVED")
        {
            if (llList2String(llGetLinkPrimitiveParams(llList2Integer(tk, 1), [PRIM_NAME]), 0) == "R-FULL") llSetLinkPrimitiveParamsFast(llList2Integer(tk, 1), [PRIM_NAME, "RESERVED"]);
        }
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
            answer += me;
            osMessageObject(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(query_id) != llGetOwner())
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
        //
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        debug("link_message:"+str +"  num="+(string)num);
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            refresh();
        }
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
        else if (cmd == "MENU_OPTION")
        {
            if (llList2String(tk, 1) == "RESET") resetObject();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
