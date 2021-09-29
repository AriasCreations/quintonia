// addon-fx_bees.lsl
//  addon to generate effects for insect farm items
// Version 1.0      10 October 2020

swarm(integer time, float rate, integer angry, string image, key k)
{
    llParticleSystem([
                    //PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,2,
                    PSYS_SRC_ANGLE_BEGIN,PI/2,
                    PSYS_SRC_ANGLE_END,PI/2+.3,
                    PSYS_SRC_TARGET_KEY, k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,

                    PSYS_PART_START_ALPHA,1.,
                    PSYS_PART_END_ALPHA,0.3,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.070000,0.070000,0.000000>,
                    PSYS_PART_END_SCALE,<.0700000,.07000000,0.000000>,
                    PSYS_SRC_TEXTURE,image,
                    PSYS_SRC_MAX_AGE,time,
                    PSYS_PART_MAX_AGE,6,
                    PSYS_SRC_BURST_RATE, rate,
                    PSYS_SRC_BURST_PART_COUNT, angry+1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,.5000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,2.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.5,
                    PSYS_SRC_BURST_SPEED_MAX, 4,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |PSYS_PART_WIND_MASK |
                        PSYS_PART_INTERP_SCALE_MASK |
                        PSYS_PART_BOUNCE_MASK |
                        PSYS_PART_FOLLOW_VELOCITY_MASK
                    ]);
}

default
{
    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        llParticleSystem([]);
    }

    link_message(integer sender, integer val, string m, key id)
    {
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "FX")
        {
            float rate = llList2Float(tk, 2);
            integer angry = llList2Integer(tk, 3);
            string image = llList2String(tk, 4);
            key target = llList2Key(tk, 5);
            swarm(val, rate, angry, image, target);
        }
    }

}
