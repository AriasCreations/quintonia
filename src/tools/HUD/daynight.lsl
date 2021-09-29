// daynight.lsl
//  QUINTONIA FARM HUD - Day/Night display//
//  INFO
//   Displys images for day, night, sunrise & sunset for the region
//
float version = 5.2;   // 15 December 2020

vector YELLOW    = <0.602, 0.517, 0.000>;
vector ORANGE    = <0.594, 0.276, 0.000>;
vector NAVY      = <0.139, 0.252, 0.259>;
vector TEAL      = <0.239, 0.600, 0.439>;
vector GRAY      = <0.667, 0.667, 0.667>;
vector BLACK     = <0.0, 0.0, 0.0>;

default
{

    link_message(integer sender_num, integer num, string msg, key id)
    {
        if (msg == "DAY")
        {
            llSetTexture("day", 0);
            llSetColor(YELLOW,1);
        }
        else if (msg =="SUNSET")
        {
            llSetTexture("sunset", 0);
            llSetColor(ORANGE,1);
        }
        else if (msg == "NIGHT")
        {
            llSetTexture("night", 0);
            llSetColor(NAVY,1);
        }
        else if (msg == "SUNRISE")
        {
            llSetTexture("sunrise", 0);
            llSetColor(TEAL,1);
        }
        else if (msg == "DEBUG")
        {
            llSetTexture("debug", 0);
            llSetColor(GRAY,1);
        }
        else if (msg == "NOTIME")
        {
            llSetTexture("time", 0);
            llSetColor(GRAY,1);
        }
        else if (msg == "AM_DEAD")
        {
            llSetTexture("RIP", 0);
            llSetColor(BLACK,1);
        }
        else if (msg == "RESET")
        {
            llResetScript();
        }
    }

    state_entry()
    {
        llSetTexture("time", 0);
        llSetColor(GRAY,1);
    }

    touch_end(integer num_detected)
    {
        llMessageLinked(LINK_SET, 1, "SAY_TIME", "");
    }
}
