// horse_vehicle.lsl
// Version 1.0   8 November 2020

// Config notecard variables
vector  sitOffset = <1.9, 0, 0.3>;   // SIT_OFFSET=<1.9, 0, 0.3>

float   linear = 12;                 // Power used to go forward (1 to 30)
float   reverse_power = -5;          // Power used to go reverse (-1 to -30)
float   turning_ratio = 2.0;         // How sharply the vehicle turns. Less is more sharply. (.1 to 10)
//
float   speedmult = 1.0;
integer toggle;
integer seated = 0;
string  curstatus;
string  curanim;
string  anHorse;
string  anMan;

integer avatarLink = 1;
integer horseLink = 2;
string  wheelName = "wheel";

loadConfig()
{
    //config notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
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
                         if (cmd == "SIT_OFFSET")     sitOffset = (vector)val;
                }
            }
        }
        if (sitOffset == <0, 0, 0>) sitOffset = <0, 0, 0.1>;
    }
}


psystem()
{
     llParticleSystem(
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
            PSYS_SRC_BURST_RADIUS,.5,
            PSYS_SRC_ANGLE_BEGIN,PI,
            PSYS_SRC_ANGLE_END,PI+0.1,
            PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_START_ALPHA,.1,
            PSYS_PART_END_ALPHA,0,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<3.30000,3.00000,0.000000>,
            PSYS_PART_END_SCALE,<1,1, 0.000000>,
            //PSYS_SRC_TEXTURE,"3a7ea058-e486-4d21-b2e6-8b47462bb45b",
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,4,
            PSYS_SRC_BURST_RATE,0.1,
            PSYS_SRC_BURST_PART_COUNT,2,
            PSYS_SRC_ACCEL,<0.000000,0.000000,.100000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.0,
            PSYS_SRC_BURST_SPEED_MAX,0.0,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_INTERP_COLOR_MASK
        ]);
}


switchAnims(string status )
{
            key horse = llAvatarOnLinkSitTarget(horseLink);
            key man = llAvatarOnLinkSitTarget(avatarLink);
            string oMan = anMan;
            string oHorse = anHorse;
            anMan = "man-"+status;
            if (status == "stop")
            {
                anHorse = "horse-stop";
                anMan = "driveS";
            }
            else
            {
                if (status == "run")
                {
                     if (llFrand(1)<0.5) anHorse = "horse-run";
                     else  anHorse = "horse-run1";
                }
                anHorse = "horse-"+status;
                anMan = "driveS";

            }
            osAvatarPlayAnimation(horse, anHorse);
            osAvatarPlayAnimation(man, anMan);
            osAvatarStopAnimation(man, oMan);
            osAvatarStopAnimation(horse, oHorse);

            llStopSound();
            if (status == "walk") llLoopSound("gallup", 1.0);
                else if (status == "run") llLoopSound("gallup2", 1.0);
            if (llFrand(1.0) < 0.1) llTriggerSound("horse"+(integer)(1+llFrand(3)), 1.0);
}

init()
{
    loadConfig();
    // forward-back,left-right,updown
    llSitTarget(sitOffset, ZERO_ROTATION );

    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
    llSetVehicleFlags(0);
    llSetVehicleType(VEHICLE_TYPE_CAR);
    llSetVehicleFlags(VEHICLE_FLAG_HOVER_UP_ONLY );
    llSetVehicleVectorParam( VEHICLE_LINEAR_FRICTION_TIMESCALE, <.1, .1, 1> );
    llSetVehicleFloatParam( VEHICLE_ANGULAR_FRICTION_TIMESCALE, 1 );

    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, .2);
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.1);

    llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1 );
    llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 5 );

    llSetVehicleFloatParam( VEHICLE_HOVER_HEIGHT, 0.15);
    llSetVehicleFloatParam( VEHICLE_HOVER_EFFICIENCY,1. );
    llSetVehicleFloatParam( VEHICLE_HOVER_TIMESCALE, .1 );

    llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.5 );
    llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_TIMESCALE, .5 );

    llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.9 );
    llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, .1 );

    llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 1. );
    llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 1. );

    llSetVehicleFloatParam( VEHICLE_BANKING_EFFICIENCY, 1 );
    llSetVehicleFloatParam( VEHICLE_BANKING_MIX, 0.5 );
    llSetVehicleFloatParam( VEHICLE_BANKING_TIMESCALE, .5 );
    llSetVehicleRotationParam( VEHICLE_REFERENCE_FRAME, ZERO_ROTATION );
}



default
{

    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        init();
    }

    changed(integer change)
    {
        if ((change & CHANGED_LINK) == CHANGED_LINK)
        {
            key agent = llAvatarOnLinkSitTarget(avatarLink);
            if (agent != NULL_KEY)
            {
                    llRequestPermissions(agent, PERMISSION_CONTROL_CAMERA| PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
                    //llSetLinkAlpha(2, 0.0, ALL_SIDES);
                    init();
                    llSleep(0.3);
                    llSetStatus(STATUS_PHYSICS, TRUE);
                    llSleep(0.5);
                    seated = 1;
            }
            else
            {
                llSetStatus(STATUS_PHYSICS, FALSE);
                llSleep(.2);
                llReleaseControls();
                llTargetOmega(<0,0,0>, PI, 0);
                vector rr = llRot2Euler(llGetRot());
                rr.x = 0; rr.y =0;
                llSetRot(llEuler2Rot(rr));
                llClearCameraParams();
                seated = 0;
                key horse = llAvatarOnLinkSitTarget(horseLink);
                key man = llAvatarOnLinkSitTarget(avatarLink);
                osAvatarStopAnimation(man, anMan);
            }
        }
        if (change & CHANGED_INVENTORY) init();
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT |
                            CONTROL_LEFT| CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT , TRUE, FALSE);
        }
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStopAnimation("sit");
            switchAnims("stop");
        }
        if (perm & PERMISSION_CONTROL_CAMERA)
        {
            llSetCameraParams([
               CAMERA_ACTIVE, 1,                     // 0=INACTIVE  1=ACTIVE
               CAMERA_BEHINDNESS_ANGLE, 30.0,         // (0 to 180) DEGREES
               CAMERA_BEHINDNESS_LAG, 0.0,           // (0 to 3) SECONDS
               CAMERA_DISTANCE, 6.0,                 // ( 0.5 to 10) METERS
               CAMERA_PITCH, 30.0,                    // (-45 to 80) DEGREES
               CAMERA_POSITION_LOCKED, FALSE,        // (TRUE or FALSE)
               CAMERA_POSITION_LAG, 0.04,             // (0 to 3) SECONDS
               CAMERA_POSITION_THRESHOLD, 30.0,       // (0 to 4) METERS
               CAMERA_FOCUS_LOCKED, FALSE,           // (TRUE or FALSE)
               CAMERA_FOCUS_LAG, 0.01 ,               // (0 to 3) SECONDS
               CAMERA_FOCUS_THRESHOLD, 0.01,          // (0 to 4) METERS
               CAMERA_FOCUS_OFFSET, <0.0,0.0,0.0>   // <-10,-10,-10> to <10,10,10> METERS
              ]);
        }
    }

    control(key id, integer level, integer edge)
    {
        integer reverse=1;
        vector angular_motor;
        //get current speed
        vector vel = llGetVel();
        float speed = llVecMag(vel);
        //car controls
        string status = "stop";
        linear =0;
        //
        if (level & CONTROL_UP)     speedmult = 2.0;
        //
        if (level & CONTROL_DOWN)   speedmult = 1.0;
        //
        if (level & CONTROL_FWD)
        {
            linear = 6.;
            if (speedmult > 1.) status = "run";
                else status = "walk";
        }
        //
        if (level & CONTROL_BACK)
        {
            linear = reverse_power;
            reverse = -1;
            status = "walk";
        }

        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <speedmult*linear,0,0>);

        if (level & (CONTROL_RIGHT|CONTROL_ROT_RIGHT))  angular_motor.z -=  7+ speed/turning_ratio * reverse;
        //
        if (level & (CONTROL_LEFT|CONTROL_ROT_LEFT))    angular_motor.z +=  7 + speed/turning_ratio * reverse;

        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);

        if (curstatus != status)
        {
            curstatus = status;
            switchAnims(status);
            float spin =0;
            if (status == "run") spin = 4;  else if (status == "walk") spin = 2;
            spin *= reverse;
            integer count = llGetNumberOfPrims();
            integer index;
            for (index = 0; index < count; index++)
            {
                if (llGetLinkName(index) == wheelName) llSetLinkPrimitiveParamsFast(index, [PRIM_OMEGA, <0,1,0> , spin*1.0, 1.0]);
            }
        }
    }

}
