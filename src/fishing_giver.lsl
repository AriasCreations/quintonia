// fishing_giver.lsl
// When touched asks user if they want a fishing rod and rezzes one if they do, then sits them as per anim in contents
//
float VERSION = 4.0;    // BETA 27 April 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

// Can be overidden by config notecard
vector  TEXTCOLOR = <1.0, 1.0, 1.0>;    // TEXTCOLOR=<1.0,1.0,1.0>      If set to  ZERO_VECTOR no float text will be shown
string  FISH_STORE = "SF Fish Barrel";  // FISH_STORE=SF Fish Barrel    Set to name of storage item fishing rod will send caught fish to
vector  sitPos = <-0.8, 0.0, 0.5>;      // SIT_POS=<-0.45, 0.0, 0.15>   Offset for sitting position
integer forceWater = TRUE;              // FORCE_WATER=1                If 1, fishing rod will only work when close to water level
integer forceDetach = FALSE;            // FORCE_DETACH=0               If 1, will use osForceDetachFromAvatar()
string  languageCode = "en-GB";         // LANG="en-GB"
//
// Multilingual support
string TXT_TOUCH_TEXT = "Language";
string TXT_FISH = "Fish";
string TXT_ASK_ROD = "Do you want to fish?";
string TXT_YES = "Yes";
string TXT_NO = "No";
string TXT_NOT_GROUP = "Sorry, this spot is for group members, please try another";
string TXT_BAD_PASSWORD = "Bad password";
string TXT_ERROR_UPDATE = "Error: unable to update - you are not my Owner";
string TXT_LANGUAGE="🌐";
//
string SUFFIX = "F4";


string sitAnimation;
string PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer gListener;
key avatar;
key rodID;
integer rodGiven;
integer saveNC;

loadConfig()
{
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
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
                         if (cmd == "LANG") languageCode = val;
                    else if (cmd == "FORCE_WATER") forceWater = (integer)val;
                    else if (cmd == "FORCE_DETACH") forceDetach = (integer)val;
                    else if (cmd == "FISH_STORE") FISH_STORE = val;
                    else if (cmd == "SIT_POS") sitPos = (vector)val;
                    else if (cmd == "TEXTCOLOR")
                    {
                        if (val == "ZERO_VECTOR") TEXTCOLOR = ZERO_VECTOR; else TEXTCOLOR = (vector) val;
                    }
                }
            }
        }
    }
    // Get vars from description
    list descValues = llParseString2List(llGetObjectDesc(), ";", "");
    if (llGetListLength(descValues) >0)
    {
        languageCode = llList2String(descValues, 1);
    }
    else
    {
        llSetObjectDesc("LANG;" +languageCode);
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
                         if (cmd == "TXT_FISH") TXT_FISH = val;
                    else if (cmd == "TXT_TOUCH_TEXT") TXT_TOUCH_TEXT = val;
                    else if (cmd == "TXT_NOT_GROUP ") TXT_NOT_GROUP  = val;
                    else if (cmd == "TXT_ASK_ROD") TXT_ASK_ROD = val;
                    else if (cmd == "TXT_YES") TXT_YES = val;
                    else if (cmd == "TXT_NO") TXT_NO = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

// Returns the number of prims in the object, ignoring seated avatars
integer getNumberOfPrims()
{
    if (llGetObjectPrimCount(llGetKey()) == 0 ) return llGetNumberOfPrims(); // attachment
  return llGetObjectPrimCount(llGetKey());   // non-attachment
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
        loadLanguage(languageCode);
        llSetClickAction(CLICK_ACTION_SIT);
        llSetSitText(TXT_FISH);
        llSetTouchText(TXT_TOUCH_TEXT);
        llSetText(TXT_FISH, TEXTCOLOR, 1);
        llSitTarget(sitPos, llEuler2Rot( <0.0, 0.0, 180.0> * DEG_TO_RAD ));
        sitAnimation = llGetInventoryName(INVENTORY_ANIMATION, 0);
        // oops, use default
        if (sitAnimation == "")
        {
            sitAnimation = "tpose";
        }
        rodGiven = FALSE;
        rodID = NULL_KEY;
        avatar = NULL_KEY;
    }

    touch_start(integer index)
    {
        avatar = llDetectedKey(0);
        llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, avatar);
    }

    // Using state to control sitting
    // If you're in this state, no one is sitting
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            avatar = llAvatarOnSitTarget();
            if (avatar == NULL_KEY) avatar = llGetLinkKey( (1 + getNumberOfPrims()) );
            debug("changed_default:LINK_Avatar=" + (string)avatar);
            if ( avatar != NULL_KEY )
            {
                if (!llSameGroup(avatar))
                {
                    llRegionSayTo(avatar, 0, TXT_NOT_GROUP);
                    llStopAnimation(sitAnimation);
                    llUnSit(avatar);
                    llResetScript();
                }
                llRequestPermissions(avatar,PERMISSION_TRIGGER_ANIMATION);
            }
            else
            {
                llStopAnimation(sitAnimation);
                llUnSit(avatar);
                if (llGetListLength(llGetObjectDetails(rodID, [OBJECT_NAME])) != 0)
                {
                    osMessageObject(rodID,  "FISHEND|"+PASSWORD+"|" + (string)avatar +"|" );
                    rodGiven = FALSE;
                }
                llResetScript();
            }
        }

        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    run_time_permissions(integer parm)
    {
        if(parm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("sit");
            llStartAnimation(sitAnimation);
            gListener = llListen(chan(llGetKey()), "", avatar, "");
            llDialog(avatar, TXT_ASK_ROD, [TXT_YES, TXT_NO, TXT_LANGUAGE] , chan(llGetKey()));
            // Start a one-minute timer, after which we will stop listening for responses
            llSetTimerEvent(10.0);
        }
    }

    listen(integer chan, string name, key id, string msg)
    {
        debug("listen: " + msg);
        // If the user clicked the "Yes" button, rez a rod for them
        if (msg == TXT_YES)
        {
           llRezObject("FishingRod", llGetPos() + <0.0,0.0,-1.0>, <0.0,0.0,0.0>, <0.0,0.0,0.0,1.0>, 0);
        }
        else if (msg == TXT_NO)
        {
            llStopAnimation(sitAnimation);
            llUnSit(id);
            avatar = NULL_KEY;
        }
        if (msg == TXT_LANGUAGE)
        {
            llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, avatar);
        }
    }

    timer()
    {
        // Stop listening. It's wise to do this to reduce lag
        llListenRemove(gListener);
        // Stop the timer now that its job is done
        llSetTimerEvent(0.0);// you can use 0 as well to save memory
        state sitting;
    }

    object_rez(key id)
    {
        debug("object_rez");
        llSleep(.5);
        rodID = id;
        rodGiven = TRUE;
        // INIT|PASSWORD|avatarUUID|beaconKey|FISH_STORE|forceWater|forceDetach|languageCode
        osMessageObject(rodID,  "INIT|"+PASSWORD+"|" + (string)avatar +"|" +(string)llGetKey() +"|" +FISH_STORE +"|" +(string)forceWater +"|" +(string)forceDetach +"|" +languageCode);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg);
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetSitText(TXT_FISH);
            llSetTouchText(TXT_TOUCH_TEXT);
            llSetText(TXT_FISH, TEXTCOLOR, 1);
            llSetObjectDesc("LANG;" +languageCode);
            avatar = NULL_KEY;
        }
    }

    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD )
        {
            llOwnerSay(TXT_BAD_PASSWORD);
            return;
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
            osMessageObject(llList2Key(tk, 2), answer);
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
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }

}

// ====== STATE SITTING =====

state sitting
{

    state_entry()
    {
        llSetText("", ZERO_VECTOR,0.0);
        llSetClickAction(CLICK_ACTION_TOUCH);
    }

    touch_start(integer index)
    {
        avatar = llDetectedKey(0);
        llMessageLinked(LINK_THIS, 1, "LANG_MENU|" + languageCode, avatar);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message[sitting]: " + msg);
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
            llSetSitText(TXT_FISH);
            llSetTouchText(TXT_TOUCH_TEXT);
            osMessageObject(rodID,  "LANGUAGE|"+PASSWORD+"|" +languageCode);
            llSetObjectDesc("LANG;" +languageCode);
        }
    }

    // Assume sitting, thus any CHANGED_LINK means standing.
    changed(integer change)
    {
        debug("changed_sitting");
        if (change & CHANGED_LINK)
        {
            llStopAnimation(sitAnimation);
            // Message rod to detach
            if (rodGiven == TRUE)
            {
                if (llGetListLength(llGetObjectDetails(rodID, [OBJECT_NAME])) != 0)
                {
                    osMessageObject(rodID,  "FISHEND|"+PASSWORD+"|" + (string)avatar +"|" );
                    rodGiven = FALSE;
                }
            }
            //llResetScript();
            state default;
        }
    }

}
