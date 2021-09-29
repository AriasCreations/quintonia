// sundial.lsl
// ---------------------------------------
//  QUINTONIA FARM HUD - Sundial display
// ---------------------------------------
float version = 5.1;  //   15 December 2020

// INFO
// Shows as a dial that indicates how much of the day or night is left
// Also sends a link message so other scripts are in sync with day/night mode.

float suntime;
integer day;
integer isDay;
vector dialcolour;
integer debugMode;

vector GRAY      = <0.667, 0.667, 0.667>;
vector YELLOW    = <1.000, 0.912, 0.359>;
vector ORANGE    = <1.000, 0.522, 0.106>;
vector NAVY      = <0.380, 0.650, 0.667>;
vector TEAL      = <0.183, 0.466, 0.338>; //<0.239, 0.600, 0.439>;

DayNight(integer sayIt)
{
    string imgMsg;
    suntime = osGetCurrentSunHour();
    // We display 12 hour slots so take away 12 if needed
    if (suntime > 12) suntime = suntime -12;
    // Now divide into hours for the display
    suntime = suntime / 12;   // 0.0 to 1.0

    // Check with lsl functions if sun above or below horizon
    vector sun = llGetSunDirection();
    day = llRound(sun.z);
    if(day == 1)
    {
        if (sayIt == FALSE)
        {
            isDay = TRUE;
            dialcolour = YELLOW;
        }
        imgMsg = "DAY";
    }
    else if (sun.z <-0.5)
    {
        if (sayIt == FALSE)
        {
            isDay = FALSE;
            dialcolour = NAVY;
        }
        imgMsg = "NIGHT";
    }
    else if ((sun.z <0.3) && (isDay == TRUE))
    {
        dialcolour = ORANGE;
        imgMsg = "SUNSET";
    }
    else if ((sun.z >0.0) && (isDay == FALSE))
    {
        dialcolour = TEAL;
        imgMsg = "SUNRISE";
    }
    else
    {
        imgMsg = "NOTIME";
    }
    if (debugMode == TRUE) imgMsg = "DEBUG";

    if (sayIt == FALSE)
    {
        llMessageLinked(LINK_SET, 1, imgMsg, "");
        llSetColor(dialcolour, ALL_SIDES);
        llSetPrimitiveParams([PRIM_TYPE,
                            PRIM_TYPE_CYLINDER,
                            PRIM_HOLE_DEFAULT,  // hole_shape
                            <suntime, 1, 1>,    // cut
                            0.7,                // hollow
                            <0.0, 0.0, 0.0>,    // twist
                            <1.0, 1.0, 0.0>,    // top_size
                            <0.0, 0.0, 0.0>     // top_Shear
                      ]);
    }
    else
    {
        llOwnerSay("Phase="+imgMsg);
    }
}


default
{
    on_rez(integer start_param)
    {
      llResetScript();
    }

    state_entry()
    {
        debugMode = FALSE;
        dialcolour = GRAY;
        // do a check now
        vector sunPos1 = llGetSunDirection();
        if (llRound(sunPos1.z) == 1) isDay = TRUE;
        else if (sunPos1.z >0)
        {
            // work out of sun going up or down
            llSleep(60.0);
            vector sunPos2 = llGetSunDirection();
            if (sunPos1.z > sunPos2.z) isDay = TRUE; else isDay = FALSE;
        }
        else
        {
            isDay = FALSE;
        }
        DayNight(FALSE);
        // Set further checks at 1 minute intervals.
        llSetTimerEvent(60);
    }

    changed(integer change)
    {
        if (change & CHANGED_REGION)
        {
            llResetScript();
        }
    }

    timer()
    {
        DayNight(FALSE);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "STARTUP")
        {
            llResetScript();
        }
        else if (cmd == "SAY_TIME")
        {
            DayNight(TRUE);
        }
        else if (cmd == "CMD_DEBUG")
        {
            if (llList2Integer(tk, 1) == 1) debugMode = TRUE; else debugMode = FALSE;
            DayNight(FALSE);
        }
    }
}
