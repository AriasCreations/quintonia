
// Water pump - supplies water to closest water tower

string PASSWORD="*";

integer VERSION = 2;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

integer createdTs =0;
integer lastTs=0;
integer WATERTIME = 1000;
integer fill=10;

integer totTime=1;


refresh()
{
    llParticleSystem([]);
    string progress = "";
    if (llGetUnixTime()-lastTs >  WATERTIME)
    {
        fill+=10;
        lastTs = llGetUnixTime();
    }
    
    if (fill>100) 
    {
        fill=100;
        llSensor("SF Water Tower", "", SCRIPTED, 96, PI);
    }
    
    llSetText("Water level: " + (string)fill+ "%\n", <1,1,1>, 1.0);
}

psys(key k)
{
 
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,
                        
                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 30,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
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
        fill = 20;
        lastTs = llGetUnixTime();
        createdTs = lastTs;
        refresh();
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        llSetTimerEvent(1);
    }
    
    sensor (integer n)
    {
        key id = llDetectedKey(0);
        psys(id);
        osMessageObject(id, "WATER|"+PASSWORD);
    }
    
   
    timer()
    {
        refresh();
        llSetTimerEvent(1000);
    }
    
}

