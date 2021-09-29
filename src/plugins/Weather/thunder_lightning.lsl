// Thunder * lightning effects
// Based on Fader by Mitzpatrick Fitzsimmons

integer fadeset = 0;
integer fade = 100;
float glow = .1;
vector fullSize = <26.18600, 33.48831, 27.01003>;
integer colsound = 0;
string thunderClap = "d1d567a1-2162-4990-b42b-6d124f164e79";
string thunderSound = "7d996f07-e4f0-4ac9-9888-4d554b090d3d";

fade_up()
{
    float i;
    for (i =fadeset; i < fade; i++)
    {
        float v = i * 0.01;
        llSetAlpha(v, ALL_SIDES);
    }
}

fade_down()
{
    float i;
    for (i =fadeset; i > fade; i--)
    {
        float v = i * 0.01;
        llSetAlpha(v, ALL_SIDES);
    }
}

turnOff()
{
    llSetTimerEvent(0);
    llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
    llStopSound();
    fade_down();
    llSetScale(<0.01, 0.01, 0.01>);
}

doFX()
{
    fadeset = 0;
    fade = (integer)100 ;
    if(fadeset < fade)
    {
        fade_up();
        llTriggerSound(thunderClap, 1.0);
        llSetTextureAnim( ANIM_ON | PING_PONG | LOOP, ALL_SIDES, 2, 2, 0, 4, 4 );
        llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.15]);
        llSleep(10);
        llTriggerSound(thunderClap, 1.0);
        llSleep(7);
        //shutting down now
        fadeset = fade;
        fade = (integer)0;
        if(fadeset < fade)
        {
            //
        }
        else
        {
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
            fade_down();
        }
    }
}


default
{
    state_entry()
    {
        llSetScale(<0.01, 0.01, 0.01>);
        llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
    }

    on_rez(integer num)
    {
        llResetScript();
    }

    link_message(integer sender_num, integer num, string message, key id)
    {
        if (message == "STRIKE")
        {
            if (num == 1)
            {
                if (llFrand(5.0)>3)
                {
                    llSetScale(fullSize);
                    doFX();
                }
                else
                {
                    turnOff();
                }
                llSetTimerEvent(60);
            }
            else
            {
                turnOff();
            }
        }
        else if (message == "RESET")
        {
            llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
            llSetScale(<0.01, 0.01, 0.01>);
            llStopSound();
        }
        else if (message == "DEBUG")
        {
            if (num == 1) llSetScale(fullSize);
        }
    }

    timer()
    {
        turnOff();
        //doFX();
    }

}
