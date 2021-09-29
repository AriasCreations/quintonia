// addon-pmac_health.lsl
//  Plugin for MLP devices to link them to Health mode
//
// First add the notecard  sfp
// Then add this plugin

float VERSION = 4.0;     // 2 June 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// these can be overriden with config notecard
integer hygiene_value = 50;
integer  energy_value = 50;
integer  health_value = 50;
integer      duration = 180;
integer       autoEnd = 1;

string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
integer seated;
list    avatarIDs;
key     avatarID;
string  action = "";

loadConfig()
{
    //sfp notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            list tok = llParseString2List(llList2String(lines,i), ["="], []);
            if (llList2String(tok,1) != "")
            {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                     if (cmd == "HYGIENE") hygiene_value = (integer)val;
                else if (cmd == "HEALTH") health_value = (integer)val;
                else if (cmd == "ENERGY") energy_value = (integer)val;
                else if (cmd == "TIME") duration = (integer)val;
                else if (cmd == "AUTO_END") autoEnd = (integer)val;
            }
        }
    }
}

particles()
{
    integer flags = 0;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,2,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, <1.000, 0.800, 0.900>,
                        PSYS_PART_END_COLOR, <0.318, 0.000, 0.633>,
                        PSYS_PART_START_SCALE,<0.25, 0.25, 1>,
                        PSYS_PART_END_SCALE,<1.5, 1.5, 1>,
                        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                        PSYS_SRC_BURST_RATE,0.1,
                        PSYS_SRC_ACCEL, <0.0, 0.0, -0.5>,
                        PSYS_SRC_BURST_PART_COUNT,2,
                        PSYS_SRC_BURST_RADIUS,1.0,
                        PSYS_SRC_BURST_SPEED_MIN,0.0,
                        PSYS_SRC_BURST_SPEED_MAX,0.05,
                        PSYS_SRC_TARGET_KEY,llGetOwner(),
                        PSYS_SRC_INNERANGLE,0.65,
                        PSYS_SRC_OUTERANGLE,0.1,
                        PSYS_SRC_OMEGA, <0,0,0>,
                        PSYS_SRC_MAX_AGE, 2,
                        PSYS_SRC_TEXTURE, "",
                        PSYS_PART_START_ALPHA, 0.5,
                        PSYS_PART_END_ALPHA, 0.0
                    ]);
}

default
{
    state_entry()
    {
        loadConfig();
        seated = FALSE;
        avatarIDs = [];
        llMessageLinked(LINK_SET,0, "PROGRESS", "");
        llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
        llSetClickAction(CLICK_ACTION_TOUCH);
    }

    link_message(integer lnk, integer num, string msg, key id)
    {
        debug("link_message: " + msg);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk, 0);
        list ids = llParseStringKeepNulls(id, ["|"], []);
        integer i;
        integer j = llGetListLength(ids);

        if (cmd == "GLOBAL_START_USING")
        {
            //GLOBAL_START_USING  id:e9623cc3-4a82-4685-b5a5-1bd500fe2af9|00000000-0000-0000-0000-000000000000
            seated = TRUE;
            action = llList2String(tk, 1);
            llMessageLinked(LINK_SET,90, "STARTCOOKING", "");
            avatarID = llList2Key(ids, 0);
            avatarIDs = [avatarID, llGetUnixTime()];
            llSetTimerEvent(2);
            llSay(FARM_CHANNEL, "PROGRESS|" +PASSWORD+"|" +(string)avatarID+"|" +action +"|0");
            llSetTimerEvent(duration/20);
        }
        else if (cmd == "GLOBAL_NEXT_AN")
        {
            for (i=0; i<j; i+=1)
            {
                if (llListFindList(avatarIDs, [llList2Key(ids,i)] ) == -1)
                {
                    if (llList2Key(ids, i) != NULL_KEY) avatarIDs += [llList2Key(ids, i), llGetUnixTime()];
                }
            }
        }
        else if (cmd == "GLOBAL_USER_STOOD")
        {
            // Someone stood up
            //  GLOBAL_USER_STOOD|1|e9623cc3-4a82-4685-b5a5-1bd500fe2af9
            i = llListFindList(avatarIDs, llList2Key(tk,2));

            i = llListFindList(avatarIDs,[id]);
            if (i != -1)
            {
                avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
            }
        }
        else if (cmd == "GLOBAL_SYSTEM_GOING_DORMANT")
        {
            seated = FALSE;
            llMessageLinked(LINK_SET,90, "ENDCOOKING", "");
            avatarIDs = [];
            llSetTimerEvent(0);
        }
    }

    timer()
    {
        if (seated == TRUE)
        {
            integer i;
            integer j = llGetListLength(avatarIDs);
            float prog;

            for (i=0; i<j; i+=2)
            {
                avatarID = llList2Key(avatarIDs, i);

                prog = ((llGetUnixTime()-llList2Float(avatarIDs, i+1))*100.0)/duration;
                if (prog >=100.0)
                {
                    avatarID = llList2Key(avatarIDs, i);
                    llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)avatarID +"|Hygiene|" +(string)hygiene_value +"|Energy|" +(string)energy_value +"|Health|" +(string)health_value);

                    if (autoEnd == TRUE)
                    {
                        llUnSit(avatarID);
                    }
                    else
                    {
                        // Remove and then add back in so their timer starts again
                        i = llListFindList(avatarIDs,[avatarID]);
                        if (i != -1)
                        {
                            avatarIDs = llDeleteSubList(avatarIDs, i, i+1);
                            avatarIDs += [avatarID, llGetUnixTime()];
                        }
                    }
                }
                else
                {
                    llSay(FARM_CHANNEL, "PROGRESS|" +PASSWORD+"|" +(string)avatarID+"|" +action +"|" +(string)llRound(prog));
                }
            }
            particles();
            llSetTimerEvent(duration/20);
        }
        else
        {
            llSetTimerEvent(0.0);
            avatarIDs = [];
            llResetScript();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

}
