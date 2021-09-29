
// Drivable vehicle for Satyr Farm
//

float VERSION = 1.1;        // 26 January 2020
string  PASSWORD = "*";

string ENGINE_SOUND = "tractor_running";
string START_SOUND = "tractor_idle";
string      gDrivingAnim = "drive forward";
string      gReverseAnim = "drive reverse";
string      gSitMessage = "Drive tractor";
string      gTouchMessage =  "ADD FUEL";

integer infoPrim = 1;
float   power = 10.0;
integer lastTs;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

integer listener=-1;
integer listenTs;
float   speedMult =1.0;

integer DEBUG = FALSE;

integer     xlimit;
integer     ylimit;
vector      gSitTarget_Pos = <-1.2, 0, 1.4>;
key         gAgent;
integer     gRun;     //ENGINE RUNNING

float       gVerticalThrust=10.0;
integer     gGear;
float       gGearPower;
float       gReversePower = -5;
float       gTurnMulti = 1;
float       gTurnRatio;
integer     numGears;
string      animation;
list        gGearPowerList = [ 5, 15, 30, 45, 65, 90 ];
list        gTurnRatioList = [ 1, 1, 1, 1, 1, 1 ];


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

refresh()
{
    if (power <=0)
    {   
        llSetLinkPrimitiveParamsFast(infoPrim, [PRIM_TEXT, "Out of fuel!\nTouch to refuel me", <1,0,0> , 1.0]);
    }
    else
    {
        llSetLinkPrimitiveParamsFast(infoPrim, [PRIM_TEXT, "Speed = " + (string)( gGear+1 ) + "\nFuel: "+(string)llRound(power)+"%", <1,1,1>, 1.0]);
    }
}

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return 1;
}


// TRACTOR SCRIPT //
init_engine()
{
    gRun = 0;
    numGears = llGetListLength( gGearPowerList );
    llSetSitText(gSitMessage);
    llSetTouchText(gTouchMessage);
    vector gSitTarget_Rot = llRot2Euler( llGetRootRotation() ); // SIT TARGET IS BASED ON VEHICLE'S ROTATION.
    llSitTarget(gSitTarget_Pos, llEuler2Rot(DEG_TO_RAD * gSitTarget_Rot));
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
}

gearshift()
{
    gGearPower = llList2Float(gGearPowerList, gGear);  
    refresh();
}

init_followCam()
{
    llSetCameraParams([
                       CAMERA_ACTIVE, 1,                 // 0=INACTIVE  1=ACTIVE
                       CAMERA_BEHINDNESS_ANGLE, 2.5,     // (0 to 180) DEGREES
                       CAMERA_BEHINDNESS_LAG, 0.3,       // (0 to 3) SECONDS
                       CAMERA_DISTANCE, 5.0,             // ( 0.5 to 10) METERS
                       CAMERA_PITCH, 15.0,               // (-45 to 80) DEGREES
                       CAMERA_POSITION_LOCKED, FALSE,    // (TRUE or FALSE)
                       CAMERA_POSITION_LAG, 0.0,         // (0 to 3) SECONDS
                       CAMERA_POSITION_THRESHOLD, 0.0,   // (0 to 4) METERS
                       CAMERA_FOCUS_LOCKED, FALSE,       // (TRUE or FALSE)
                       CAMERA_FOCUS_LAG, 0.0,            // (0 to 3) SECONDS
                       CAMERA_FOCUS_THRESHOLD, 0.0,      // (0 to 4) METERS
                       CAMERA_FOCUS_OFFSET, <-3, 0, 0>   // <-10,-10,-10> to <10,10,10> METERS
                      ]);
    llForceMouselook(FALSE);
}

set_engine()
{
    llSetVehicleType(VEHICLE_TYPE_BOAT);
// default rotation of local frame
    llSetVehicleRotationParam(VEHICLE_REFERENCE_FRAME, <0.00000, 0.00000, 0.00000, 0.00000>); 
// linear motor wins after about five seconds, decays after about a minute 
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, 0.90);
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 1.0);
// least for forward-back, most friction for up-down   ( matched lsl gives much slower control response )
    llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <1.0,1.0,1.0> );
// uniform angular friction (setting it as a scalar rather than a vector)  ( matched lsl gives a compile error )
    llSetVehicleVectorParam(VEHICLE_ANGULAR_FRICTION_TIMESCALE, <1.0,1000.0,1000.0> );
// agular motor wins after four seconds, decays in same amount of time   ( matched lsl turning almost non existent )
    llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_TIMESCALE, 0.20);
    llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 0.10);
// halfway linear deflection with timescale of 3 seconds  ( matched lsl turning is slower )
    llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.10);
    llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 10.00);
// angular deflection ( matched lsl without any visable change )
    llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.10);
    llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 10.00);
// somewhat bounscy vertical attractor ( changing gives very bad results )
    llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 0.5);
    llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 2.00);
// hover ( matched lsl without any visable change )
    llSetVehicleFloatParam(VEHICLE_HOVER_HEIGHT, 0.1); 
    llSetVehicleFloatParam(VEHICLE_HOVER_EFFICIENCY, 0.5);
    llSetVehicleFloatParam(VEHICLE_HOVER_TIMESCALE, 250.0);
    llSetVehicleFloatParam(VEHICLE_BUOYANCY, 1.0 );
// weak negative damped banking  ( matched lsl without any visable change )
    llSetVehicleFloatParam( VEHICLE_BANKING_EFFICIENCY, 1.0 );
    llSetVehicleFloatParam( VEHICLE_BANKING_MIX, 1.0 );
    llSetVehicleFloatParam( VEHICLE_BANKING_TIMESCALE, 0.5 );
// remove these flags
    llRemoveVehicleFlags( VEHICLE_FLAG_HOVER_TERRAIN_ONLY
        | VEHICLE_FLAG_LIMIT_ROLL_ONLY
        | VEHICLE_FLAG_HOVER_GLOBAL_HEIGHT);
// set these flags
    llSetVehicleFlags( VEHICLE_FLAG_NO_DEFLECTION_UP
        | VEHICLE_FLAG_HOVER_WATER_ONLY
        | VEHICLE_FLAG_HOVER_UP_ONLY
        | VEHICLE_FLAG_LIMIT_MOTOR_UP );
}

default
{
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        llSetClickAction(CLICK_ACTION_TOUCH);
        infoPrim = getLinkNum("Wheel");
        llSetLinkPrimitiveParamsFast(infoPrim, [PRIM_TEXT, "Touch to initialise...", <1,1,1>,1.0]);
    }

    touch_start(integer num_detected)
    {
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", ZERO_VECTOR, 0]);
        vector vTarget = llGetPos();
        vTarget.z = llGround( ZERO_VECTOR );
        float fWaterLevel = llWater( ZERO_VECTOR );
        if( vTarget.z < fWaterLevel )
        {
            vTarget.z = fWaterLevel;
        }
        llSetRegionPos(vTarget + <0,0,0.1>);
        init_engine();
        refresh();
        llSetClickAction(CLICK_ACTION_SIT);
        state Ground;
    }

}


// ---   STATE GROUND    ---  \\
 
state Ground
{

    on_rez(integer param)
    {
        llResetScript();
    }

    touch_start(integer n)
    {
        if (power<90);
         llSensor("SF Fuel", "",SCRIPTED,  5, PI);   
    }

changed(integer change)
    {
        if ((change & CHANGED_LINK) == CHANGED_LINK)
        {
            gAgent = llAvatarOnSitTarget();
            if (gAgent != NULL_KEY){ // we have a driver
                llSetStatus(STATUS_PHYSICS, TRUE);
                llSetStatus(STATUS_ROTATE_Y,TRUE);
                llSetStatus(STATUS_ROTATE_Z,TRUE);
                llTriggerSound(START_SOUND, 1.0);
                set_engine();
                vector regionsize = osGetRegionSize();
                xlimit = (integer)regionsize.x - 15;
                ylimit = (integer)regionsize.y - 15;
                llRequestPermissions(gAgent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA);
                gRun = 1; // set running
            }
            else { // driver got off
                llSetStatus(STATUS_PHYSICS, FALSE); //SHOULD THIS BE THE LAST THING YOU SET??
                gRun = 0; // turn off running
                init_engine();
                llStopAnimation( animation );
                llStopSound();
                llPushObject(gAgent, <3,3,21>, ZERO_VECTOR, FALSE);
                llReleaseControls();
                llClearCameraParams();
                llSetCameraParams([CAMERA_ACTIVE, 0]);
                llMessageLinked(LINK_SET, 0, "aboard", NULL_KEY);     // driver got off
            }
        }
    }

    run_time_permissions(integer perm){
        if (perm) {
            gGear = 0;
            gearshift(); 
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT | CONTROL_LEFT | CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT, TRUE, FALSE);
            init_followCam();
            llStopAnimation("sit");
            llStartAnimation(gDrivingAnim);
            animation = gDrivingAnim;
            llMessageLinked(LINK_SET, 1, "aboard", NULL_KEY);     // driver aboard
            llLoopSound(ENGINE_SOUND,1.0);
            llSleep(1.5);
        }
    }
 
    control(key id, integer held, integer change)
    {
        if(gRun == 0){
            return;
        }

        float speed = llGetVel()* (<1,0,0>*llGetRot());

        if (power<=0)
        {
            return;
        }
        else if (power<7)
        {
            speedMult=1;
        }

        integer reverse = 1;
        gTurnRatio = llList2Float(gTurnRatioList, gGear);  
        vector vel = llGetVel();
        float gSpeed = llVecMag(vel);
        vector speedvec = llGetVel() / llGetRot();
        vector AngularMotor;
        vector pos = llGetPos();
        vector newPos = pos;


        if( (held & change & CONTROL_UP) || ((gGear >= 11) && (held & CONTROL_UP)) ||
            (held & change & CONTROL_RIGHT) || ((gGear >= 11) && (held & CONTROL_RIGHT)) )
        {
            gGear=gGear+1;
            if (gGear > numGears-1) gGear = numGears-1;
            gearshift();
        }
        
        if( (held & change & CONTROL_DOWN) || ((gGear >= 11) && (held & CONTROL_DOWN)) ||
            (held & change & CONTROL_LEFT) || ((gGear >= 11) && (held & CONTROL_LEFT)) )
        {
            gGear=gGear-1;
            if (gGear < 0) gGear = 0;
            gearshift();
        }
        
        if (held & CONTROL_FWD)
        {
//            llSay(0,"held & CONTROL_FWD");
            reverse = 1;
            // if near region edge, slow down, and veer to the right
           // if (newPos.x > xlimit || newPos.x < 0.1 || newPos.y > ylimit || newPos.y < 15.0) 
            {
               // llWhisper(0, "");
            }
            if( !DEBUG ) llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <gGearPower,0,0>);
            llMessageLinked(LINK_SET, (integer)gSpeed, "ForwardSpin", NULL_KEY);
            if( animation == gReverseAnim )
            {
                llStopAnimation( animation );
                animation = gDrivingAnim;
            }
        }
 
        if (held & CONTROL_BACK)
        {
            if( !DEBUG ) llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <gReversePower, 0, 0>);
            llSetCameraParams([CAMERA_BEHINDNESS_ANGLE,-45.0]);
            llSetCameraParams([CAMERA_DISTANCE,8.0]);
            gTurnRatio = -1.0;
            reverse = -1;
            speedMult = 1.0;
            llMessageLinked(LINK_SET, (integer)gSpeed, "BackwardSpin", NULL_KEY);
            if( animation == gDrivingAnim )
            {
                animation = gReverseAnim;
                llStartAnimation( animation );
            }
        }

        if (~held & change & CONTROL_FWD)
        {
            llMessageLinked(LINK_SET, (integer)gSpeed, "NoSpin", NULL_KEY);             
        }
        
        if (~held & change & CONTROL_BACK)
        {
            llMessageLinked(LINK_SET, (integer)gSpeed, "NoSpin", NULL_KEY);             
        }
        
        // vector AngularMotor;
        // AngularMotor.y = 0;  
        if (held & (CONTROL_ROT_RIGHT))
        {
            if( reverse == 1 )
            {
                AngularMotor.x += ( gTurnRatio * 0.3 );  //1
                AngularMotor.y -= ( gTurnRatio * 0.3 );  //0.3
            }
            AngularMotor.z -= ( gTurnRatio * 1 );
        }
 
        if (held & (CONTROL_ROT_LEFT))
        {
            if( reverse == 1 )
            {
                AngularMotor.x -= ( gTurnRatio * 0.3 );
                AngularMotor.y -= ( gTurnRatio * 0.3 );
            }
            AngularMotor.z += ( gTurnRatio * 1);
        }
        if( !DEBUG ) llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, AngularMotor);

        if (speed > 0.1  ||   speed < -0.1)
        {
            integer ts = llGetUnixTime();
            if (ts > lastTs+10)
            {
                power -= 1*(speedMult/10.);
                if (power<0) power =0;
                refresh();
                lastTs = ts;
            }
        }
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llSay(0, "Found fuel, charging...");
        osMessageObject(id, "DIE|"+llGetKey());
    }

    no_sensor()
    {
        llSay(0, "Error! Fuel not found nearby! You must bring it near me!");
    }

    dataserver(key id, string m)
    {
        list tk = llParseStringKeepNulls(m , ["|"], []);
        if (llList2String(tk,1) != PASSWORD)  { llSay(0, "Password mismatch"); return;  } 
        
        string cmd = llList2String(tk,0);
        llOwnerSay("DEBUG: CMD is " + cmd);
        //for updates
        if (cmd == "VERSION-CHECK")
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
        else if (cmd == "STATS-CHECK")
        {
            string answer = "STATS-REPLY|" + PASSWORD + "|";
            // answer is amount of fuel
            answer += (string)power + "|";
            osMessageObject(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(id) != llGetOwner())
            {
                llSay(0, "Reject Update, because you are not my Owner.");
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
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|" + PASSWORD + "|" + (string)llGetKey() + "|" + (string)pin + "|" + sRemoveItems);
            if (delSelf)
            {
                llSay(0, "Removing myself for update.");
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
        else if (cmd == "FUEL" )
        {
            power = 100;
            if (power>100) power = 100;
            refresh();
        }

    }

}