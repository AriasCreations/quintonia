// power_electric_boat.lsl

float VERSION = 1.0;     // 29 May 2020

// can be overridden by config notecard
integer autoReturn = 1;     // AUTORETURN=
float soundVolume = 1.0;    // VOLUME=
string languageCode = "en-GB";   // LANG=
// for multilingual notecard support
string SUFFIX = "V1";
string TXT_NO_ENERGY="Out of energy!";
string TXT_ERROR_NOT_FOUND="Energy not found nearby! You must bring it near me!";
string TXT_FOUND="Found energy, charging...";
string TXT_CHARGE="Charge";
string TXT_GEAR="Gear";
string TXT_SIT_TEXT="Ride me";
string TXT_TOUCH_TEXT="Add kWh";
string TXT_CLOSE="CLOSE";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
string TXT_BAD_PASSWORD="Bad password";
string SF_KWH="SF kWh";

string PASSWORD = "*";
integer FARM_CHANNEL = -911201;

integer effects =0;
float forward_power = 7; //Power used to go forward (1 to 30)
float reverse_power = -5; //Power ued to go reverse (-1 to -30)
float turning_ratio = 8.0; //How sharply the vehicle turns. Less is more sharply. (.1 to 10)
string drive_anim = "drive";
string WATER_SOUND = "water";
float curRot;
float speedMult = 1.0;
float topGear = 4.0;
integer shouldGoHome = FALSE;
integer treading=0;
vector myHome;
rotation myRotation;
integer lastTs;
float power=10.0;
key user = NULL_KEY;
integer bonus = 0;
string physEngine;




stoppsystem()
{
    llLinkParticleSystem(2, []);
}

psystem()
{
     llLinkParticleSystem(2,
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
            PSYS_SRC_BURST_RADIUS,.3,
            PSYS_SRC_ANGLE_BEGIN,PI/2,
            PSYS_SRC_ANGLE_END,PI/2 + 0.1,
            PSYS_SRC_TARGET_KEY,llGetKey(),
            PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_START_ALPHA,.7,
            PSYS_PART_END_ALPHA,0.,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<1.30000,1.00000,0.000000>,
            PSYS_PART_END_SCALE,<2,2, 0.000000>,
            PSYS_SRC_TEXTURE,"3a7ea058-e486-4d21-b2e6-8b47462bb45b",
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,6,
            PSYS_SRC_BURST_RATE,0.01,
            PSYS_SRC_BURST_PART_COUNT,4,
            PSYS_SRC_ACCEL,<0.000000,0.000000,-1.00000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.6,
            PSYS_SRC_BURST_SPEED_MAX,0.6,
            PSYS_PART_FLAGS,
                0
                | PSYS_PART_INTERP_COLOR_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_BOUNCE_MASK
                | PSYS_PART_EMISSIVE_MASK
        ]);
}

setVehicle()
{

        llSetCameraEyeOffset(<-14, 0.0, 3.0>);

        llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
        llSetVehicleFlags(0);
        llSetVehicleType(VEHICLE_TYPE_BOAT);
        llSetVehicleFlags(VEHICLE_FLAG_HOVER_UP_ONLY | VEHICLE_FLAG_HOVER_WATER_ONLY);
        llSetVehicleVectorParam( VEHICLE_LINEAR_FRICTION_TIMESCALE, <3.8, 1.8, 1> );
        llSetVehicleFloatParam( VEHICLE_ANGULAR_FRICTION_TIMESCALE, 3 );

        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
        llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, 1);
        llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.05);

        llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1 );
        llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 5 );
        llSetVehicleFloatParam( VEHICLE_HOVER_HEIGHT, 0.15);
        llSetVehicleFloatParam( VEHICLE_HOVER_EFFICIENCY,.5 );
        llSetVehicleFloatParam( VEHICLE_HOVER_TIMESCALE, 2.0 );
        llSetVehicleFloatParam( VEHICLE_BUOYANCY, 1 );
        llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.5 );
        llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 3 );
        llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.5 );
        llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 10 );
        llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 0.5 );
        llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 2 );
        llSetVehicleFloatParam( VEHICLE_BANKING_EFFICIENCY, 1 );
        llSetVehicleFloatParam( VEHICLE_BANKING_MIX, 0.1 );
        llSetVehicleFloatParam( VEHICLE_BANKING_TIMESCALE, .5 );
        llSetVehicleRotationParam( VEHICLE_REFERENCE_FRAME, ZERO_ROTATION );
}


refresh()
{
    if (power <=0)
    {
        llSetText(TXT_NO_ENERGY, <1,0,0> , 1.0);
        llParticleSystem([]);
    }
    else
        llSetText(TXT_CHARGE +": "+(string)llRound(power)+"%\n" +TXT_GEAR +": " +(string)llRound(speedMult), <1,1,1>, 1.);

    llSetObjectDesc("V;" +llRound(power) +";" +languageCode);
}

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
                if (cmd == "AUTORETURN")  autoReturn = (integer)val;
                else if (cmd == "LANG") languageCode = val;
                else if (cmd == "VOLUME")
                {
                    if ((integer)val != 0)
                    {
                        soundVolume = ((integer)val) / 10.0;
                        if (soundVolume >1) soundVolume = 1.0;
                    }
                    else
                    {
                        soundVolume = 0.0;
                    }
                }
            }
        }
    }
    list descValues = llParseString2List(llGetObjectDesc(), ";", "");
    if (llGetListLength(descValues) >0)
    {
        power = llList2Float(descValues, 1);
        languageCode = llList2String(descValues, 2);
    }
    physEngine = osGetPhysicsEngineType();
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" +SUFFIX;
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
                         if (cmd == "TXT_SIT_TEXT") TXT_SIT_TEXT = val;
                    else if (cmd == "TXT_TOUCH_TEXT") TXT_TOUCH_TEXT = val;
                    else if (cmd == "TXT_NO_ENERGY") TXT_NO_ENERGY = val;
                    else if (cmd == "TXT_CHARGE") TXT_CHARGE = val;
                    else if (cmd == "TXT_GEAR") TXT_GEAR = val;
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "SF_KWH") SF_KWH = val;
                }
            }
        }
    }
}

default
{

    on_rez(integer n)
    {
        llResetScript();
        shouldGoHome = FALSE;
        myHome = llGetPos();
        myRotation = llGetRot();
    }

    state_entry()
    {
        loadConfig();
        loadLanguage(languageCode);
        llSetSitText(TXT_SIT_TEXT);
        llSetTouchText(TXT_TOUCH_TEXT);
        myHome = llGetPos();
        myRotation = llGetRot();
        // forward-back,left-right,updown
        llSitTarget(<1.7,-0.6,.7>, llEuler2Rot(<0,0,0>) );
        llSetCameraEyeOffset(<-10, 0, 3>);
        llSetCameraAtOffset(<10, 0, 0>);
        setVehicle();
        shouldGoHome = FALSE;
        refresh();
        llOwnerSay(physEngine);  // 'ubODE'  'OpenDynamicsEngine' or 'BulletSim'
        llSetTimerEvent(300);
    }

    changed(integer change)
    {

        if (change & CHANGED_LINK)
        {
            key agent = llAvatarOnLinkSitTarget(1);
            if (agent != NULL_KEY)
            {
            // Check if member of group to be added...
                llSetTimerEvent(0);
                setVehicle();
                stoppsystem();
                llMessageLinked(LINK_ALL_CHILDREN , 0, "start", NULL_KEY);
                llMessageLinked(LINK_ALL_CHILDREN , 0, "aboard", NULL_KEY);
                llRequestPermissions(agent,  PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS| PERMISSION_CONTROL_CAMERA);
                llSetStatus(STATUS_PHYSICS, TRUE);
                llSleep(0.4);
                shouldGoHome = FALSE;
                lastTs = llGetUnixTime();
                bonus = 0;
                user = agent;
            }
            else
            {
                llStopSound();
                llSetStatus(STATUS_PHYSICS, FALSE);
                llSleep(.2);
                llReleaseControls();
                llTargetOmega(<0,0,0>,PI,0);
                llSetTimerEvent(0);
                llMessageLinked(LINK_ALL_CHILDREN , 0, "stop", NULL_KEY);
                llMessageLinked(LINK_ALL_CHILDREN , 0, "NoSpin", NULL_KEY);
                vector r = llRot2Euler(llGetRot());
                r.x =0;
                r.y =0;
                llSetRot(llEuler2Rot(r));
                stoppsystem();
                shouldGoHome = TRUE;
                llSetTimerEvent(300);
                user = NULL_KEY;
            }
        }
        else if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm&PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT |
                            CONTROL_LEFT | CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT, TRUE, FALSE);

            llSetCameraParams([
                       CAMERA_ACTIVE, 1,                     // 0=INACTIVE  1=ACTIVE
                       CAMERA_BEHINDNESS_ANGLE, 15.0,         // (0 to 180) DEGREES
                       CAMERA_BEHINDNESS_LAG, 1.0,           // (0 to 3) SECONDS
                       CAMERA_DISTANCE, 6.0,                 // ( 0.5 to 10) METERS
                       CAMERA_PITCH, 20.0,                    // (-45 to 80) DEGREES
                       CAMERA_POSITION_LOCKED, FALSE,        // (TRUE or FALSE)
                       CAMERA_POSITION_LAG, 0.05,             // (0 to 3) SECONDS
                       CAMERA_POSITION_THRESHOLD, 30.0,       // (0 to 4) METERS
                       CAMERA_FOCUS_LOCKED, FALSE,           // (TRUE or FALSE)
                       CAMERA_FOCUS_LAG, 0.01 ,               // (0 to 3) SECONDS
                       CAMERA_FOCUS_THRESHOLD, 0.01,          // (0 to 4) METERS
                       CAMERA_FOCUS_OFFSET, <0.0,0.0,0.0>   // <-10,-10,-10> to <10,10,10> METERS
                      ]);
        }
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation(drive_anim);
        }
    }

    control(key id, integer level, integer edge)
    {
        integer reverse=1;
        vector angular_motor;

        //get current speed
        vector vel = llGetVel();
        float speed = llVecMag(vel);
        integer moving=0;
        float newRot;

        if (power<=0)
        {
            llRegionSayTo(id, 0, TXT_NO_ENERGY);
            return;
        }

        if(level &edge & CONTROL_UP)
        {
            speedMult += 1.0;
            if (speedMult > topGear) speedMult -=1;
            refresh();
        }
        else if(level &edge & CONTROL_DOWN)
        {
            speedMult -= 1.0;
            if (speedMult <1.0) speedMult=1.0;
            refresh();
        }

        //car controls
        if(level & CONTROL_FWD)
        {
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <speedMult*forward_power,0,0>);
            reverse=1;
            llMessageLinked(LINK_ALL_CHILDREN , 5, "ForwardSpin", NULL_KEY);
            if (!(edge & CONTROL_FWD))
                moving=1;

        }
        if(level & CONTROL_BACK)
        {
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <reverse_power,0,0>);
            reverse = -1;
            llMessageLinked(LINK_ALL_CHILDREN , -4, "BackwardSpin", NULL_KEY);
        }

        if(level & (CONTROL_RIGHT|CONTROL_ROT_RIGHT))
        {
            angular_motor.z -= speed / turning_ratio * reverse;
            angular_motor.x += 2;
            newRot = 0.1;
        }

        if(level & (CONTROL_LEFT|CONTROL_ROT_LEFT))
        {
            angular_motor.z += speed / turning_ratio * reverse;
            angular_motor.x -= 2;

            newRot = -0.1;
        }

        if (newRot != curRot)
        {
            //curRot = newRot;
            //llSetLinkPrimitiveParamsFast(3, [PRIM_ROT_LOCAL, llEuler2Rot(<PI/2, PI*(1+curRot), 0>)]);
        }

        if (moving>0 && !effects)
        {
            effects=1;
            psystem();
            llLoopSound("engine", soundVolume);
        }
        else if (moving==0 && effects>0)
        {
            effects=0;
            stoppsystem();
        }

        if (speed > 0.1  ||   speed < -0.1)
        {
            integer ts = llGetUnixTime();
            if (ts > lastTs+10)
            {
                power -= 1*(speedMult/10.);
                if (power<0) power =0;
                lastTs = ts;
                bonus += 2;
                if (bonus >10)
                {
                    llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)user +"|Health|1");
                    bonus = 0;
                }
            }
        }
        else
        {
            llPlaySound(WATER_SOUND, 1.0);
            psystem();
        }
        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);
        refresh();
    }

    timer()
    {
        if( shouldGoHome == TRUE)
        {
            if (autoReturn == TRUE)
            {
                // RETURN BOAT HOME IF WE GET HERE
                shouldGoHome = FALSE;
                osTeleportObject(llGetKey(),myHome,myRotation,OSTPOBJ_SETROT);
            }
        }
    }

    dataserver(key id, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(tk,1) != PASSWORD ) { llOwnerSay(TXT_BAD_PASSWORD); return; }
        string cmd = llList2String(tk,0);

        if (cmd == "KWH" ) // Add power
        {
            power += 20;
            if (power>100) power = 100;
            refresh();
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
            if (llGetOwnerKey(id) != llGetOwner())
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
        refresh();
    }

    touch_start(integer n)
    {
        if (power<90) llSensor(SF_KWH, "",SCRIPTED,  5, PI);
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llSay(0, TXT_FOUND);
        osMessageObject(id, "DIE|"+(string)llGetKey());
    }

    no_sensor()
    {
        llSay(0, TXT_ERROR_NOT_FOUND);
    }

}
