// horse_npc.lsl
// Version 1.2   29 November 2020

// config notecard settings
string firstName = "Wild";      // FIRST_NAME=Wild
string lastName =  "Wonder";    // LAST_NAME=Wonder
integer horseReturn = TRUE;     // AUTO_RETURN=1
integer idleTime = 300;         // IDLE_TIME=5
integer allowGroup = FALSE;     // ALLOW_GROUP=0
//
// Language support
string TXT_MENU = "MENU";
string TXT_RIDE = "RIDE";
string TXT_ERROR_USE="Sorry, you are not allowed to use this";
//
integer avatarLink = 1;
integer horseLink = 2;
key     userID = NULL_KEY;
integer forceRemove;

key uNPC;

loadConfig()
{
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        integer i;
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                     if (cmd == "FIRST_NAME")  firstName = val;
                else if (cmd == "LAST_NAME")   lastName = val;
                else if (cmd == "AUTO_RETURN") horseReturn = (integer)val;
                else if (cmd == "IDLE_TIME")   idleTime = (integer)val*60;
                else if (cmd == "ALLOW_GROUP") allowGroup = (integer)val;
            }
        }
    }
    if (idleTime < 2) idleTime =2;
    if (firstName == "") firstName = "NPC";
    if (lastName == "") lastName = "Horse";
}

refresh()
{
    llSetSitText(TXT_RIDE);
    llSetTouchText(TXT_MENU);
}

default
{

    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        forceRemove = FALSE;
        loadConfig();
        refresh();
        llSetTimerEvent(idleTime);
    }

    touch_end(integer index)
    {
        llMessageLinked(LINK_SET, 1, "WAS_TOUCHED", llDetectedKey(0));
    }

    changed(integer c)
    {
         if (c & CHANGED_LINK)
         {
            userID = llAvatarOnLinkSitTarget(avatarLink);
            if ((allowGroup == TRUE) || (userID == llGetOwner()))
            {
                if (userID != NULL_KEY)
                {
                    key horse = llAvatarOnLinkSitTarget(horseLink);
                    if (horse == NULL_KEY)
                    {
                        uNPC = osNpcCreate(firstName, lastName, llGetPos()+<0,0,2>, "appearance",  OS_NPC_NOT_OWNED | OS_NPC_SENSE_AS_AGENT);
                        llSleep(3);
                        osNpcSit(uNPC, llGetLinkKey(horseLink), OS_NPC_SIT_NOW);
                        llSleep(.5);
                        osNpcPlayAnimation(uNPC, "horse-stop");
                    }
                    llSetTimerEvent(0);
                    llMessageLinked(LINK_SET, 1, "USER_SIT", userID);
                }
                else
                {
                    llMessageLinked(LINK_SET, 0, "USER_SIT", userID);
                    llSetTimerEvent(idleTime);
                }
            }
            else
            {
                llRegionSayTo(userID, 0, TXT_ERROR_USE);
                llUnSit(userID);
            }
        }
        else if (c & CHANGED_INVENTORY)
        {
            loadConfig();
        }
    }

    timer()
    {
        if ((horseReturn == TRUE) || (forceRemove == TRUE))
        {
            if (llAvatarOnLinkSitTarget(avatarLink) == NULL_KEY)
            {
                key u2 = llAvatarOnLinkSitTarget(horseLink);
                if (u2 != NULL_KEY)
                {
                    llSay(0, "Removing NPC...");
                    osNpcStand(u2);
                    llSleep(1.0);
                    osNpcRemove(u2);
                    llSleep(2);
                    forceRemove = FALSE;
                }
            }
        }
        else llSetTimerEvent(0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "REMOVE_NPC")
        {
            forceRemove = TRUE;
            llSetTimerEvent(0.2);
        }
        else if (cmd == "LANGTEXT")
        {
                 if (llList2String(tk, 2) == "TXT_MENU")        TXT_MENU = llList2String(tk, 3);
            else if (llList2String(tk, 2) == "TXT_RIDE")        TXT_RIDE = llList2String(tk, 3);
            else if (llList2String(tk, 2) == "TXT_ERROR_USE")   TXT_ERROR_USE = llList2String(tk, 3);
            //
            refresh();
        }
    }

}
