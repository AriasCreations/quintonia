// animal-heaven.lsl
// Version 2.0    5 December 2020

key toucher;
integer dead = FALSE;
integer FARM_CHANNEL = -911201;
string PASSWORD;

toHeaven()
{
    list particle_parameters = [
       PSYS_SRC_TEXTURE, "angel",
       PSYS_PART_START_SCALE, <0.25,0.25,FALSE>,  PSYS_PART_END_SCALE, <2.5, 2.5, FALSE>,
       PSYS_PART_START_COLOR, <1,1,0>,    PSYS_PART_END_COLOR, <1.0, 0.8, 0.0>,
       PSYS_PART_START_ALPHA, .8,            PSYS_PART_END_ALPHA, .0,
       PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
       PSYS_SRC_BURST_PART_COUNT, 10,
       PSYS_SRC_BURST_RATE, 0.2,
       PSYS_PART_MAX_AGE, 20.0,
       PSYS_SRC_MAX_AGE, 5.0,
       PSYS_SRC_PATTERN, 1,
       PSYS_SRC_BURST_SPEED_MIN, (float).1,   PSYS_SRC_BURST_SPEED_MAX, (float).3,
       PSYS_SRC_ANGLE_BEGIN, (float) .03*PI,     PSYS_SRC_ANGLE_END, (float)0.00*PI,
       PSYS_SRC_ACCEL, <0.0,0.0,1.5>,
       PSYS_PART_FLAGS, (integer)( 0
                            | PSYS_PART_INTERP_COLOR_MASK
                            | PSYS_PART_INTERP_SCALE_MASK
                            | PSYS_PART_EMISSIVE_MASK
                            | PSYS_PART_FOLLOW_VELOCITY_MASK
                            | PSYS_PART_WIND_MASK
                            | PSYS_PART_BOUNCE_MASK
                        )
    ];
    llParticleSystem(particle_parameters);
}

default
{

    link_message(integer ln, integer nv, string sv, key kv)
    {
        list tk = llParseString2List(sv,["|"], []);
        string cmd =llList2String(tk,0);

        if (cmd == "HEAVEN")
        {
            dead = TRUE;
            PASSWORD = (string)kv;
        }
    }

    touch_end(integer index)
    {
        if ((dead == TRUE) || (llGetInventoryType("animal") != INVENTORY_SCRIPT))
        {
            toucher = llDetectedKey(0);
            if (toucher == llGetOwner())
            {
                toHeaven();
                llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)toucher +"|Health|5");
                llSleep(10.0);
                llDie();
            }
        }
    }

}
