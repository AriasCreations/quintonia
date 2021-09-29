    // universal_electric_vehicle.lsl
    //  Vehicle that  uses power from SF power controller. Must be charged in a charging station
    float VERSION = 2.0;     //    30 May 2020

    integer DEBUGMODE = FALSE;
    debug(string text)
    {
        if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
    }

    // sound files:  engine running, engine running2, engine start, engine stop, engine wind down, engine wind down 1 (think last 2 the same!)
    // anim file:  vb-pilot-vs-pr4
    //-----------------------------------------------------------------
    // Car vehicle script, original code given by Caro Fayray
    // added sections - threshold for preventing crossing limits, speed options (gearings) and procedure to make vehicle
    // go back to initial position if user leaves it
    // Jeff Hall, February 2015
    // Works for both Bullet and UBode engines
    // Update January 2016:
    // option to specify number of desired gears
    // constant turning force with all speeds defined by turning_ratio only
    // added code at [control] section for playing sound since llStopSound may not start at [run_time_permissions] section
    // Update February 2018:
    // Script adapted for enabling car or boat usage
    //-----------------------------------------------------------------

    // can be overridden by config notecard
    integer avoidCrossing = FALSE;  // NO_CROSSING=1  default TRUE; set to FALSE for permitting crossing sim limit but at date January 2015 its not possible
    float maxXY = 240;              // MAX_XY=240     255 max for regular region, more for VAR
    float minXY = 10;               // MIN_XY=10      get no closer than 10 meters to any edge
    integer autoReturn = TRUE;      //AUTORETURN=1  option to make vehicle return go to its initial position if users stands  (MakePoof below must be set to FALSE in order to enable the goHome option (when true))
    float   soundVolume = 1.0;      // VOLUME=10
    integer FX_PRIM = 19;           // Which prim to emit particles. Set to -1 for none
    string  languageCode = "";      // LANG=en-GB

    string soundEngine = "engine running"; //option for playing an engine sound with vehicle, leave blank or with no sounds in prim for disabling
    string soundStart  = "engine start";   //option for playing an engine start sound, leave blank or with no sounds in prim for disabling
    string soundStop   = "engine stop";    //option for playing an engine stop sound, leave blank or with no sounds in prim for disabling
    string soundIdle   = "engine idle";    //option for playing an engine idle sound, leave blank or with no sounds in prim for disabling

    //NOTE: for adding anim just include it in object's content (vehicle)

    // for multilingual notecard support
    string TXT_SIT_TEXT="Ride me";
    string TXT_TOUCH_TEXT="Add kWh";
    string TXT_NO_ENERGY="Out of energy!";
    string TXT_CHARGE="Charge:";
    string TXT_FOUND="Found energy, charging...";
    string TXT_GEAR="Gear";
    string TXT_CLOSE="CLOSE";
    string TXT_BAD_PASSWORD="Bad password";
    string TXT_ERROR_GROUP="Error, we are not in the same group";
    string TXT_ERROR_NOT_FOUND="Energy not found nearby! You must bring it near me!";
    string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
    string TXT_NOT_OWNER = "You are not the owner of this vehicle";

    string SF_KWH="SF kWh";

    float forward_power = 32.0; //28;    //16.0;
    float reverse_power = -12;  //-10.0; //-6;
    float turning_ratio = 2;    //2.0;   //4.0;

    vector CameraEyeOffset = <-6.0, 0,2>;
    vector CameraAtOffset = <10, 0, 1.50>;

    integer useGear = TRUE;     //option for using gears - number of speeds defined in GearNumber below (page up - page down) if TRUE; if FALSE then vehicle will have a single speed
    integer GearNumber = 3;     //default 3; specify the desired numbers of gears (if useGear TRUE)


    integer MakePoof = FALSE;   //**** Default FALSE- option for making object poofing after someone has sit and then stood or rezzed for a longer period without using; change to TRUE for enabling

    vector target =<0.0,0,0.8>; //<0,0,0.2>;

    integer isBoat = FALSE; //default FALSE; if FALSE vehicle will use llSetVehicleType(VEHICLE_TYPE_CAR); if TRUE vehicle will use llSetVehicleType(VEHICLE_TYPE_BOAT);
    float boatHoverHeight = 1.75; //default 0.75 meter; used when having boat (isBoat = TRUE); sets the height over water of the main prim containing this script


    //------------ CODE -----------------------\\

    integer Gear;
    integer soundRunning = FALSE;
    vector gVecPos;
    vector positionAct;
    float  gFltXact;
    float  gFltYact;
    float  gFltZact;
    vector positionInit;    // initial position of object
    rotation rotationInit;  // initial rotation of object
    integer owner = 0;
    vector eul = <0,0,0>;

    key agent;
    key oldagent;
    string animation;

    integer gearFactor = 1;
    float gearFactorTmp = 0.15;
    float Speed;
    integer Run;
    integer iStep=0;
    string FX_TEXTURE = "fx";               // For effects;

    setCamera(float degrees)
    {
        rotation sitRot = llAxisAngle2Rot(<0, 0, 1>, degrees * PI);
        llSetCameraEyeOffset(CameraEyeOffset * sitRot);
        llSetCameraAtOffset(CameraAtOffset  * sitRot);
        llForceMouselook(FALSE);
    }

    setVehicle()
    {
        if (isBoat == TRUE)
        {
            llSetVehicleType(VEHICLE_TYPE_BOAT);
            llSetVehicleFloatParam( VEHICLE_HOVER_HEIGHT, boatHoverHeight );
        }
        else
        {
           llSetVehicleType(VEHICLE_TYPE_CAR);
        }

        llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.2);
        llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.75);
        llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 0.20);
        llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 0.10);
        llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, 2.0);
        llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.5);
        llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_TIMESCALE, 0.1);
        llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 0.1);
        llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <2.0, 2.0, 1000.0>);
        llSetVehicleVectorParam(VEHICLE_ANGULAR_FRICTION_TIMESCALE, <0.1, 0.1, 0.1>);
        llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 0.5);
        llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 1.0);
        llSetVehicleFloatParam(VEHICLE_BUOYANCY, 0.2 );
        llSetVehicleFloatParam( VEHICLE_BANKING_EFFICIENCY, -0.05 );
        llSetVehicleFloatParam( VEHICLE_BANKING_MIX, 1 );
        llSetVehicleFloatParam( VEHICLE_BANKING_TIMESCALE, 1 );
    }

    Init()
    {
        llSetStatus(STATUS_PHYSICS, FALSE);
        soundRunning = FALSE;
        //llStopSound();
    }

    psystem(integer lnk)
    {
         llLinkParticleSystem(lnk,
            [
           PSYS_SRC_TEXTURE, llGetInventoryName(INVENTORY_TEXTURE, 0),
           PSYS_PART_START_SCALE, <.5,0.5, FALSE>,  PSYS_PART_END_SCALE, <.0,2.0, FALSE>,
           PSYS_PART_START_COLOR, <.2,.2,1>,       PSYS_PART_END_COLOR, <.5,1,1>,
           PSYS_PART_START_ALPHA, (float)1.0,            PSYS_PART_END_ALPHA, (float)0.0,
           PSYS_PART_BLEND_FUNC_DEST, PSYS_PART_BF_ONE,
           PSYS_SRC_BURST_PART_COUNT, (integer) 1,
           PSYS_SRC_BURST_RATE, (float) 0.01,
           PSYS_PART_MAX_AGE, (float)0.4,
           PSYS_SRC_MAX_AGE,(float) 0.0,
           PSYS_SRC_PATTERN, (integer)8, // 1=DROP, 2=EXPLODE, 4=ANGLE, 8=ANGLE_CONE,
           PSYS_SRC_BURST_SPEED_MIN, (float).01,   PSYS_SRC_BURST_SPEED_MAX, (float)3.01,
        // PSYS_SRC_BURST_RADIUS, 0.0,
           PSYS_SRC_ANGLE_BEGIN, (float) 0.01*PI,        PSYS_SRC_ANGLE_END,(float) 0.0*PI,
           PSYS_SRC_OMEGA, <0,0,0>,
           PSYS_SRC_ACCEL, <0.0,0.0,0.0>,
        // PSYS_SRC_TARGET_KEY,      llGetLinkKey(llGetLinkNumber() + 1),

           PSYS_PART_FLAGS, (integer)( 0
                                | PSYS_PART_INTERP_COLOR_MASK
                                | PSYS_PART_INTERP_SCALE_MASK
                                | PSYS_PART_EMISSIVE_MASK
                                | PSYS_PART_FOLLOW_VELOCITY_MASK
                            )
            //end of particle settings
        ]);
    }

    default
    {
        state_entry()
        {
            Init();
            llSetSoundQueueing(TRUE);
            animation = llGetInventoryName(INVENTORY_ANIMATION,0);
            rotation rot = llEuler2Rot(eul*DEG_TO_RAD);
            llSitTarget(target,rot);
            setCamera(0);
            llSetSitText(TXT_SIT_TEXT);
            llOwnerSay("Initialized");
            gearFactor = 1;
            Gear = 1;
            soundRunning = FALSE;
            //initial wanted position when you stand
            positionInit = llGetPos();
            rotationInit = llGetRot();
            if (MakePoof == FALSE)  //timer required for poofing a rezzed but never used vehicle
            {
                llSetTimerEvent(0.0);
            }
            else
            {
                llSetTimerEvent(0.3);
            }
            llSetPrimitiveParams([PRIM_PHANTOM, TRUE]);

        }
        on_rez(integer start_param)
        {
            llResetScript();
        }

        changed(integer change)
        {
            if ((change & CHANGED_LINK) == CHANGED_LINK)
            {
                agent = llAvatarOnSitTarget();
                if (agent != NULL_KEY)
                {
                    if ((agent != llGetOwner()) && (owner == 1))
                    {
                        llSay(0, TXT_NOT_OWNER);
                        llUnSit(agent);
                        llSetPrimitiveParams([PRIM_PHANTOM, TRUE]);
                    }
                    else
                    {
                        llSetPrimitiveParams([PRIM_PHANTOM, FALSE]);
                        oldagent = agent;
                        setVehicle();
                        llPlaySound(soundStart, soundVolume);
                        llSleep(0.5);
                        llSetStatus(STATUS_PHYSICS, TRUE);
                        llSleep(0.5);
                        soundRunning = FALSE;
                        Run = 1;
                        llSetTimerEvent(0.5);
                        llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
                        gearFactor = 1;
                        gearFactorTmp = 1;
                        llLoopSound(soundIdle, soundVolume);
                    }
                }
                else
                {
                    llStopSound();
                    llPlaySound(soundStop, soundVolume);
                    Init();
                    llSleep(.4);
                    llReleaseControls();
                    llStopAnimation(animation);
                    llSetPrimitiveParams([PRIM_PHANTOM, TRUE]);
                    llLinkParticleSystem(FX_PRIM, []);
                    if (autoReturn==TRUE && MakePoof == FALSE)
                    {
                        llSleep(10);
                        llSetRegionPos(positionInit);
                        llSetRot(rotationInit);
                    }

                    if (MakePoof == TRUE)
                    {
                        llDie();
                    }

                }
            }
        }
        run_time_permissions(integer perm)
        {
            if (perm)
            {
                llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT | CONTROL_LEFT | CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT, TRUE, FALSE);
                llSetPos(llGetPos() + <0,0,0.5>);
                llStopAnimation("sit");
                llStartAnimation(animation);
                if (useGear == TRUE)
                {
                    llSay(0,"You are ready! Use Arrows:\n-Page Up/ Page Down for changing gears \n-Up/Down for Forward/Reverse\n-Left/Right for Turning");
                }
                else
                {
                    llSay(0,"You are ready! Use Arrows:\n-Up/Down for Forward/Reverse\n-Left/Right for Turning");
                }

            }
        }

        control(key id, integer level, integer edge)
        {
            integer direction=1;
            vector angular_motor;
            vector vel = llGetVel();
            Speed = llVecMag(vel);

            if (soundRunning == FALSE) // code only executed once
            {
                llStopSound();
                llSleep(0.1);
                llLoopSound(soundEngine, soundVolume);
                soundRunning = TRUE;
            }

            if (useGear == TRUE)
            {
                if (level & edge & CONTROL_UP ) //only on keypress and not on holding
                {
                    gearFactor = gearFactor + 1;
                    if (gearFactor > GearNumber)
                    {
                        gearFactor = GearNumber;
                    }

                    llSay(0,"Gear: " + gearFactor);
                }
                if (level & edge & CONTROL_DOWN )

                {
                    gearFactor = gearFactor - 1;
                    if (gearFactor < 1)
                    {
                        gearFactor = 1;
                    }
                    llSay(0,"Gear: " + gearFactor);
                }
            }

            if (level & CONTROL_FWD)
            {
                llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <Gear*forward_power*gearFactor*gearFactorTmp,0,0>);
                direction = 1;
                psystem(FX_PRIM);
            }

            if (level & CONTROL_BACK)
            {
                llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <Gear*reverse_power*gearFactor*gearFactorTmp,0,0>);
                direction = -1;
            }

            if (level & (CONTROL_RIGHT|CONTROL_ROT_RIGHT))
            {
                angular_motor.z -=  (turning_ratio) * direction;
                psystem(FX_PRIM);
            }

            if (level & (CONTROL_LEFT|CONTROL_ROT_LEFT))
            {
                angular_motor.z +=  (turning_ratio) * direction;
                psystem(FX_PRIM);
            }

            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);
        }

        timer()
        {
            if (Run == 1)
            {
                vector vel = llGetVel();
                Speed = llVecMag(vel);
                if(Speed > 0.0)
                {
                    llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <1.0, 2.0, 1000.0>);
                    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,0>);
                }

                if (avoidCrossing == TRUE)
                {
                    //checking if close to sim limit
                    positionAct = llGetPos();
                    gVecPos = positionAct;
                    gFltXact = positionAct.x;
                    gFltYact = positionAct.y;
                    gFltZact= positionAct.z;

                    if (gFltXact > maxXY || gFltYact > maxXY || gFltXact < minXY || gFltYact < minXY )
                    {
                        if (gFltXact > maxXY)
                        {
                            gFltXact = maxXY - 1;
                        }

                        if (gFltYact > maxXY)
                        {
                            gFltYact = maxXY - 1;
                        }

                        if (gFltXact < minXY)
                        {
                            gFltXact = minXY + 1;
                        }

                        if (gFltYact < minXY)
                        {
                            gFltYact = minXY + 1;
                        }

                        llSetPos (< gFltXact,gFltYact,gFltZact>);
                        gearFactorTmp = 0.15; //reduces strength as long as we are over limit
                    }

                    else
                    {
                        gearFactorTmp = 1; //back to normal
                    }
                }
                llSetTimerEvent(0.3);          // If restarted timer() appears to keep working
            }
            else if (MakePoof == FALSE)
            {
                    llSetTimerEvent(0.0);
            }
            else
            {
                iStep = iStep + 1;
            }

            if (iStep >= 50) //adjust for delay before poofing object after rezzing but no sitting
            {
                llSetTimerEvent(0);
                //llSay(0,"Poof unused!");
                llDie();  //deletion
            }

        }

    }
