// weather_plugin.lsl
// Version 1.1      14 December 2020
// Weather system controler driven by link messages

float TEXTURE_INTERVAL = 20;
//
// List of links and priority levels for weather prims
list cloudLinks;
list cloudLevels;
list rainLinks;
list lightningLinks;
//
integer cloudCount;
string  cloudBaseName = "cloud-";
integer cloudTextureCount;
integer darkCloud1 = -1;
integer darkCloud2 = -1;
string  rainPrimName = "rain";
string  rainSound = "RAIN";
string  thunderBaseName = "thunder-";
integer maxThunderLevel;
string  lightningBaseName = "lightning-";
string  fogTexture = "fog";
//
integer priority = 0;       // 0 is off, then levels 1, 2, 3, 4 (4 is max clouds)
integer index;
integer thunderLevel;
integer fxRadius;
float   volume = 0;
string  status = "";
integer rainState;
integer debugMode = 0;
integer FARM_CHANNEL = -911201;
string  PASSWORD;


makeDarkClouds(integer lnkNum)
{
    string cloudTex = "5b9295d0-791f-4fa2-ba37-f16a73f3b2c6";
    llLinkParticleSystem(lnkNum,
    [
        PSYS_SRC_PATTERN,
        PSYS_SRC_PATTERN_ANGLE,
        PSYS_SRC_BURST_RATE, 0.01,                  // How long before the next particle is emited (in seconds)
        PSYS_SRC_BURST_RADIUS, 0.1,                 // How far from the source to start emiting particles
        PSYS_SRC_BURST_PART_COUNT, 100,             // How many particles to emit per BURST
        PSYS_SRC_OUTERANGLE, 3.14,                  // The area that will be filled with particles
        PSYS_SRC_INNERANGLE, 0.00,                  // A slice of the circle (hole) where particles will not be created
        PSYS_SRC_MAX_AGE, 0.0,                      // How long in seconds the system will make particles, 0 means no time limit.
        PSYS_PART_MAX_AGE, 120.0,                   // How long each particle will last before dying
        PSYS_SRC_BURST_SPEED_MAX, 2.0,              // Max speed each particle can travel at
        PSYS_SRC_BURST_SPEED_MIN, 0.5,              // Min speed each particle can travel at
        PSYS_SRC_TEXTURE, cloudTex,                 // Texture used as a particle.  For no texture use null string ""
        PSYS_PART_START_ALPHA, 1.0,                 // Alpha (transparency) value at birth
        PSYS_PART_END_ALPHA, 0.0,                   // Alpha (transparency) value at death
        PSYS_PART_START_SCALE, <15.0, 15.0, 1>,     // Start size of particles
        PSYS_PART_END_SCALE, <25.0, 25.0, 1>,       // End size (--requires PSYS_PART_INTERP_SCALE_MASK)
        PSYS_PART_START_COLOR, <0.6, 0.6, 0.6>,      // Start color of particles <R,G,B>
        PSYS_PART_END_COLOR, <1.0, 1.0, 1.0>,        // End color <R,G,B> (--requires PSYS_PART_INTERP_COLOR_MASK)
        PSYS_PART_FLAGS,
        PSYS_PART_EMISSIVE_MASK                     // Make the particles glow
        | PSYS_PART_BOUNCE_MASK                     // Make particles bounce on Z plan of object
        | PSYS_PART_INTERP_SCALE_MASK               // Change from starting size to end size
        | PSYS_PART_INTERP_COLOR_MASK               // Change from starting color to end color
        //| PSYS_PART_WIND_MASK                     // Particles effected by wind
    ]);
}

makeClouds(integer lnkNum, string cloudTex)
{
    llOwnerSay("cloudTex="+cloudTex);
        llLinkParticleSystem(lnkNum,
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_ANGLE_BEGIN,0,
            PSYS_SRC_ANGLE_END,1,
            PSYS_SRC_TARGET_KEY,llGetKey(),
            PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_START_ALPHA,0.75,
            PSYS_PART_END_ALPHA,1,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<5.00,5.00,0>,
            PSYS_PART_END_SCALE,<20.00,20.00,0>,
            PSYS_SRC_TEXTURE,cloudTex,
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,30,
            PSYS_SRC_BURST_RATE,0.5,
            PSYS_SRC_BURST_PART_COUNT,1,
            PSYS_SRC_ACCEL,<0.005000,0.000000,0.000000>,
            PSYS_SRC_OMEGA,<0.00000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.05,
            PSYS_SRC_BURST_SPEED_MAX,0.1,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_INTERP_SCALE_MASK
        ]);

}

makeRain(integer radius)
{
    llStopSound();
    rainState = TRUE;
    llSensor("", NULL_KEY, AGENT_BY_LEGACY_NAME, 96.0, PI);
    llLoopSound(rainSound, volume);
    llParticleSystem( [
      PSYS_SRC_TEXTURE,
      NULL_KEY,
      PSYS_PART_START_SCALE, <0.1,0.5, 0>,
      PSYS_PART_END_SCALE, <0.05,1.5, 0>,
      PSYS_PART_START_COLOR, <1,1,1>,
      PSYS_PART_END_COLOR, <1,1,1>,
      PSYS_PART_START_ALPHA, 0.7,
      PSYS_PART_END_ALPHA, 0.5,
      PSYS_SRC_BURST_PART_COUNT, 5,
      PSYS_SRC_BURST_RATE, 0.00,
      PSYS_PART_MAX_AGE, 10.00,
      PSYS_SRC_MAX_AGE, 0.0,
      PSYS_SRC_PATTERN, 8,
      PSYS_SRC_ACCEL, <0.0,0.0, -7.2>,
      PSYS_SRC_BURST_RADIUS, 20.0,          // falling the rain 20m * 20m now
      PSYS_SRC_BURST_SPEED_MIN, 0.0,
      PSYS_SRC_BURST_SPEED_MAX, 0.0,
      PSYS_SRC_ANGLE_BEGIN, 0*DEG_TO_RAD,
      PSYS_SRC_ANGLE_END, 180*DEG_TO_RAD,
      PSYS_SRC_OMEGA, <0,0,0>,
      PSYS_PART_FLAGS, ( 0
           | PSYS_PART_INTERP_COLOR_MASK
           | PSYS_PART_INTERP_SCALE_MASK
           | PSYS_PART_WIND_MASK
      ) ] );
}

makeFog()
{
    integer flags;
    flags = flags | PSYS_PART_EMISSIVE_MASK;
    flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    flags = flags | PSYS_PART_FOLLOW_SRC_MASK;
    flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    flags = flags | PSYS_PART_TARGET_POS_MASK;
    llParticleSystem(
    [  PSYS_PART_MAX_AGE, 100,
        PSYS_PART_FLAGS,flags,
        PSYS_PART_START_COLOR, <0.8, 0.8, 0.8>,
        PSYS_PART_END_COLOR, <0.7, 0.7, 0.7>,
        PSYS_PART_START_SCALE, <2, 2, 2>,
        PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_SRC_BURST_RATE, 0.5,
        PSYS_SRC_ACCEL, <0,0,0>,
        PSYS_SRC_BURST_PART_COUNT, 10,
        PSYS_SRC_BURST_RADIUS, 3,
        PSYS_SRC_BURST_SPEED_MIN, 1,
        PSYS_SRC_BURST_SPEED_MAX, 1,
        PSYS_SRC_TARGET_KEY, llGetKey(),
        PSYS_SRC_ANGLE_BEGIN, 1.58,
        PSYS_SRC_ANGLE_END, 1.57,
        PSYS_SRC_OMEGA, <0,0,1>,
        PSYS_SRC_MAX_AGE, 0,
        PSYS_SRC_TEXTURE, fogTexture,
        PSYS_PART_START_ALPHA, 0.4,
        PSYS_PART_END_ALPHA, 0.05
 ]);
}

doLightning(integer active)
{
    integer index;
    integer count = llGetListLength(lightningLinks);
    for (index = 0; index < count; index++)
    {
        llMessageLinked(llList2Integer(lightningLinks, index), active, "STRIKE", "");
        llSleep(2.0);
    }
}

fxOff()
{
    llSetTimerEvent(0);
    llLinkParticleSystem(LINK_SET, []);
    llStopSound();
    rainState = FALSE;
    llSensor("", NULL_KEY, AGENT_BY_LEGACY_NAME, 96.0, PI);
}

darkCloudsOff()
{
    llLinkParticleSystem(darkCloud1, []);
    llSleep(1);
    llLinkParticleSystem(darkCloud2, []);
}

init()
{
    fxOff();
    llSetLinkAlpha(LINK_ALL_CHILDREN, 0.0, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
    PASSWORD = osGetNotecardLine("sfp", 0);
    //
    // Check how many cloud textures we have
    integer length = llGetInventoryNumber(INVENTORY_TEXTURE);
    integer strLength = llStringLength(cloudBaseName)-1;
    string name;
    cloudTextureCount = 0;
    for (index = 0 ; index < length; index++)
    {
        name = llGetInventoryName(INVENTORY_TEXTURE, index);
        if (llGetSubString(name, 0, strLength) == cloudBaseName)
        {
            cloudTextureCount++;
        }
    }
    //
    // Build list of cloud prims
    cloudLinks = [];
    cloudLevels = [];
    length = llStringLength(cloudBaseName) -1;
    for (index = 1; index <= llGetNumberOfPrims(); index++)
    {
       name = llGetLinkName(index);
            if (name == "darkCloud-1") darkCloud1 = index;
       else if (name == "darkCloud-2") darkCloud2 = index;
       else if (llGetSubString(name, 0, length) == cloudBaseName)
       {
           cloudLinks += index;
           cloudLevels += llGetSubString(name, length+1, -1);
       }
    }
    cloudCount = llGetListLength(cloudLinks);
    //
    // Build list of rain prims
    rainLinks = [];
    for (index = 1; index <= llGetNumberOfPrims(); index++)
    {
       if (llGetLinkName(index) == rainPrimName) rainLinks += index;
    }
    //
    // Build list of lightning prims
    lightningLinks = [];
    length = llStringLength(lightningBaseName) -1;
    for (index = 1; index <= llGetNumberOfPrims(); index++)
    {
        name = llGetLinkName(index);
        if (llGetSubString(name, 0, length) == lightningBaseName)
        {
           lightningLinks += index;
        }
    }
    //
    // Count how many thunder sounds we have
    length = llGetInventoryNumber(INVENTORY_SOUND);
    strLength = llStringLength(thunderBaseName)-1;
    maxThunderLevel = 0;
    for (index = 0 ; index < length; index++)
    {
        name = llGetInventoryName(INVENTORY_SOUND, index);
        if (llGetSubString(name, 0, strLength) == thunderBaseName)
        {
            maxThunderLevel++;
        }
    }
}


default
{
    on_rez(integer p)
    {
        llResetScript();
    }

    state_entry()
    {
        init();
    }

    timer()
    {
        if (debugMode == TRUE) llOwnerSay("timer:status="+status +"  priority="+(string)priority +"  thunderLevel="+(string)thunderLevel);
        if (status == "rainStart")
        {
            if (maxThunderLevel > 0) llSetTimerEvent(30/maxThunderLevel); else llSetTimerEvent(10);
            thunderLevel++;
            if (thunderLevel > maxThunderLevel)
            {
                status = "buildRainSound";
                volume += 0.1;
                makeRain(fxRadius);

            }
            else
            {
                if (debugMode == TRUE) llOwnerSay("playSound:"+ thunderBaseName+(string)thunderLevel);
                llPlaySound(thunderBaseName + (string)thunderLevel, 1.0);
            }
        }
        else if (status == "buildRainSound")
        {
            volume += 0.2;
            if (volume < 1.0)
            {
                makeRain(fxRadius);
            }
            else
            {
                volume =1.0;
                status = "";
                makeRain(fxRadius);
                llSetTimerEvent(TEXTURE_INTERVAL);
            }
        }
        else
        {
             llSetTimerEvent(TEXTURE_INTERVAL);
        }
        if (priority == 0)
        {
            fxOff();
        }
        else
        {
            if (cloudTextureCount > 0)
            {
                string cloudToUse = cloudBaseName + (string)((integer)llFrand(cloudTextureCount));
                for (index = 1; index < cloudCount; index++)
                {
                    if (priority <= llList2Integer(cloudLevels, index)) makeClouds(llList2Integer(cloudLinks, index), cloudToUse);
                }
            }
            if (priority <4)
            {
                doLightning(0);
                darkCloudsOff();
            }
            else
            {
                doLightning(1);
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (debugMode == TRUE) llOwnerSay("link_message:"+str +"  num=" +(string)num);

        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "START_CLOUDS")
        {
            priority = num;
            llSetTimerEvent(0.1);
        }
        else if (cmd == "END_CLOUDS")
        {
            fxOff();
        }
        else if (cmd == "START_RAIN")
        {
            fxRadius = num;
            thunderLevel = 0;
            status = "rainStart";
            priority = 4;
            makeDarkClouds(darkCloud1);
            makeDarkClouds(darkCloud2);
            llSetTimerEvent(0.1);
        }

        else if (cmd == "RESET")
        {
            init();
        }

        else if (cmd == "DEBUG")
        {
            if (num == 1)
            {
                debugMode = TRUE;
                string primText;
                llSetLinkAlpha(LINK_ALL_CHILDREN, 1.0, ALL_SIDES);
                integer primNum;
                for (index = 0; index < cloudCount; index++)
                {
                    primNum = llList2Integer(cloudLinks, index);
                    primText = llList2String(llGetLinkPrimitiveParams(primNum, [PRIM_DESC]), 0);
                    llSetLinkPrimitiveParamsFast(primNum, [PRIM_TEXT, primText, <0, 0, 1>, 1.0]);
                }
                llOwnerSay("cloudCount="+(string)cloudCount +"  cloudTextureCount="+(string)cloudTextureCount   +"  maxThunderLevel="+(string)maxThunderLevel +"  priority="+(string)priority);
            }
            else
            {
                debugMode = FALSE;
                llSetLinkAlpha(LINK_ALL_CHILDREN, 0.0, ALL_SIDES);
                llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
            }
        }
    }

    sensor(integer count)
    {
        integer index;
        for (index = 0; index < count; index++)
        {
            llRegionSay(FARM_CHANNEL, "FX_RAIN|" +PASSWORD+"|" +(string)llDetectedKey(index)+"|" +(string)rainState+"|" +(string)llGetInventoryKey(rainSound));
        }
    }

}
