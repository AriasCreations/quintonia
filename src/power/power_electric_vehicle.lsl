// power_electric_vehicle.lsl
//  Vehicle that  uses power from SF power controller. Must be charged in a charging station
float VERSION = 2.0;     //    30 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// can be overridden by config notecard
integer V_TYPE = VEHICLE_TYPE_CAR;      // V_TYPE=VEHICLE_TYPE_CAR
float   BUOYANCY = 1.0;                 // VEHICLE_BUOYANCY=1.0
integer autoReturn = 0;                 // AUTORETURN=0
float   soundVolume = 1.0;              // VOLUME=10
string  languageCode = "";              // LANG=en-GB
integer FX_PRIM=7;                      // Which prim to emit particles
vector  SIT_TARGET = <-1.2, 0.0, 1.0>;  // SIT_TARGET=<-1.2, 0.0, 1.0>
vector  SIT_ROT = <0.0, 0.0, 0.0>;      // SIT_ROT=<0.0, 0.0, 0.0>
vector  WHEEL_ROTATION=<0,0,PI/2>;      // Optional rotation in case the wheels do not spin across the X axis
float   FWD_POWER = 12.0;               //
float   REV_POWER = -5.0;               //
float   VERTICAL_THRUST = 5.0;          // VERTICAL_THRUST=5.0
float   turning_ratio = 0.5;            // TURN_RATION=0.5     Less is sharper range 0 to 10
// link numbers for rotating wheels
integer FL=13;                          // front left
integer FR=14;                          // front right
integer BL=15;                          // back left
integer BR=16;                          // back-right
//
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
string SF_KWH="SF kWh";
//
string DRIVE_ANIM= "driveS";            // animation for sitting driving straight
string DRIVELEFT_ANIM= "driveL";        // Turning left
string DRIVERIGHT_ANIM = "driveR";      // Turning right
string SITMESSAGE = "DRIVE";            // Pie menu Sit text
string TOUCHMESSAGE = "ADD kWh";        // Pie menu Touch text
string ENGINE_SOUND = "engine";         // Looping engine sound
string START_SOUND = "enginestart";     // startup sound
string ACCEL_SOUND = "hitgas_sound";    // acceleerator sound
string SCREECH_SOUND = "screech";       // screeching sound when turning
string FX_TEXTURE = "fx";               // For effects;
//
//////////////////////////////////////////////////////////////////////////////////////////

string SUFFIX = "V1";
string PASSWORD = "*";
float power=10.0;
integer lastTs;
string status = "";
vector homePosition;
rotation homeRotation;
string driveAnim;
float linear;

integer seated = 0;
float turn =0;
float oldTurn =0;
float speedMult =1.0;

string physEngine;

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
                string val=llList2String(tok, 1);
                if (cmd == "AUTORETURN")  autoReturn = (integer)val;
                else if (cmd == "V_TYPE")
                {
                    if (llToLower(val) == "car") V_TYPE = VEHICLE_TYPE_CAR;
                     else if (llToLower(val) == "boat") V_TYPE = VEHICLE_TYPE_BOAT;
                      else if (llToLower(val) == "plane") V_TYPE = VEHICLE_TYPE_AIRPLANE;
                    else V_TYPE = VEHICLE_TYPE_CAR;
                }
                else if (cmd == "VEHICLE_BUOYANCY") BUOYANCY = (float)val;
                else if (cmd == "LANG") languageCode = val;
                else if (cmd == "FL") FL = (integer)val;
                else if (cmd == "FR") FR = (integer)val;
                else if (cmd == "BL") BL = (integer)val;
                else if (cmd == "BR") BR = (integer)val;
                else if (cmd == "FX_PRIM") FX_PRIM = (integer)val;
                else if (cmd == "SIT_TARGET") SIT_TARGET = (vector)val;
                else if (cmd == "SIT_ROT") SIT_ROT = (vector)val;
                else if (cmd == "WHEEL_ROTATION") WHEEL_ROTATION = (vector)val;
                else if (cmd == "FWD_POWER") FWD_POWER = (float)val;
                else if (cmd == "REV_POWER") REV_POWER = (float)val;
                else if (cmd == "VOLUME")
                {
                    if ((integer)val != 0)
                    {
                        soundVolume = (integer)val/ 10.0;
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
                    else if (cmd == "TXT_FOUND") TXT_FOUND = val;
                    else if (cmd == "TXT_CLOSE") TXT_CLOSE = val;
                    else if (cmd == "TXT_BAD_PASSWORD") TXT_BAD_PASSWORD = val;
                    else if (cmd == "TXT_ERROR_GROUP") TXT_ERROR_GROUP = val;
                    else if (cmd == "TXT_ERROR_NOT_FOUND") TXT_ERROR_NOT_FOUND = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                    else if (cmd == "SF_KWH") SF_KWH = val;
                }
            }
        }
    }
}

psystem(integer lnk)
{
     llLinkParticleSystem(lnk,
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_RADIUS,0.5,
            PSYS_SRC_ANGLE_BEGIN,PI,
            PSYS_SRC_ANGLE_END,PI+0.1,
            PSYS_PART_START_COLOR,<1.0, 1.0, 1.0>,
            PSYS_PART_END_COLOR,<1.0, 1.0, 1.0>,
            PSYS_PART_START_ALPHA,0.1,
            PSYS_PART_END_ALPHA,0.01,
            PSYS_PART_START_GLOW,0.01,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<0.5, 0.5, 1>,
            PSYS_PART_END_SCALE,<2.0, 2.0, 1>,
            PSYS_SRC_TEXTURE,  FX_TEXTURE,
            PSYS_SRC_MAX_AGE,2,
            PSYS_PART_MAX_AGE,3,
            PSYS_SRC_BURST_RATE,0.1,
            PSYS_SRC_BURST_PART_COUNT,1,
            PSYS_SRC_ACCEL,<0.000000,0.000000,.00000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.1,
            PSYS_SRC_BURST_SPEED_MAX,0.5,
            PSYS_PART_FLAGS,
                0
                | PSYS_PART_EMISSIVE_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_INTERP_COLOR_MASK
        ]);
}

init()
{
    llLinkParticleSystem(FX_PRIM, []);
    loadConfig();
    loadLanguage(languageCode);
    llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
    llSetSitText(SITMESSAGE);
    llSetTouchText(TOUCHMESSAGE);
    // forward-back,left-right,updown
    llSitTarget(SIT_TARGET, llEuler2Rot(SIT_ROT) );
    llSetCameraEyeOffset(<-10, -1.0, 3.0>);

    llSetVehicleFlags(0);
    llSetVehicleType(V_TYPE);
    llSetVehicleFlags(VEHICLE_FLAG_HOVER_UP_ONLY );
    llSetVehicleVectorParam( VEHICLE_LINEAR_FRICTION_TIMESCALE, <.5, .1, .1> );
    llSetVehicleFloatParam( VEHICLE_ANGULAR_FRICTION_TIMESCALE, 1 );

    llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, .5);
    llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.05);

    llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1 );
    llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 5 );
    llSetVehicleFloatParam( VEHICLE_HOVER_HEIGHT, 0.15);
    llSetVehicleFloatParam( VEHICLE_HOVER_EFFICIENCY,.5 );
    llSetVehicleFloatParam( VEHICLE_HOVER_TIMESCALE, 2.0 );
    if (V_TYPE != VEHICLE_TYPE_CAR) llSetVehicleFloatParam( VEHICLE_BUOYANCY, BUOYANCY );
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
    homePosition = llGetPos();
    homeRotation = llGetRot();
}

refresh()
{
    if (power <=0)
        llSetText("Out of energy!\nTouch to charge me", <1,0,0> , 1.0);
    else
        llSetText("Charge: "+(string)llRound(power)+"%\n" +TXT_GEAR +": " +(string)llRound(speedMult), <1,1,1>, 1.0);

    llSetObjectDesc("V;" +llRound(power) +";" +languageCode);
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
        refresh();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();

        if ((change & CHANGED_LINK) == CHANGED_LINK)
        {

            key agent = llAvatarOnLinkSitTarget(1);
            if (agent != NULL_KEY)
            {
                llTriggerSound(START_SOUND, soundVolume);
                init();
                llSleep(0.3);
                llSetStatus(STATUS_PHYSICS, TRUE);
                llSleep(0.5);
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA);
                seated = 1;
            }
            else
            {
                llSetStatus(STATUS_PHYSICS, FALSE);
                llSleep(0.2);
                llReleaseControls();
                llTargetOmega(<0,0,0>,PI,0);
                llClearCameraParams();
                seated = 0;
                llStopSound();
                llStopAnimation(DRIVE_ANIM);

                llSetRot(homeRotation);
                llLinkParticleSystem(FX_PRIM, []);
                if (autoReturn == TRUE)
                {
                    // Teleport home won't work if object is phantom
                    llSetStatus(STATUS_PHANTOM, FALSE);
                    status = "waitReturn";
                    // Wait 5 minutes before returning home
                    llSetTimerEvent(300.0);
                }
                else llSetTimerEvent(0);

            }
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm)
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
        llStopAnimation("sit");
        llStartAnimation(DRIVE_ANIM);
        llLoopSound(ENGINE_SOUND, soundVolume);
        llSleep(0.5);
    }

    control(key id, integer level, integer edge)
    {
        integer dir=0;
        vector angular_motor;
        oldTurn = turn;
        float speed = llGetVel()* (<1,0,0>*llGetRot());
        turn = 0.;
        linear  = 0;

        if (power<=0)
        {
            return;
        }
        else if (power<7)
        {
            speedMult=1;
        }

        if(level & CONTROL_FWD)
        {
            if (edge&CONTROL_FWD)
                llTriggerSound(ACCEL_SOUND, soundVolume);
            linear = FWD_POWER;
            turn = 2;
            dir =1;
        }

        if(level & CONTROL_BACK)
        {
            linear = REV_POWER;
            dir = -1;
            turn = -2;
            speedMult = 1.0;
        }

        if (V_TYPE != VEHICLE_TYPE_AIRPLANE)
        {
            if(level &(CONTROL_RIGHT|CONTROL_ROT_RIGHT))
            {
                turn = -0.1;
                angular_motor.z -= speed / turning_ratio ;
                linear *=0.7; //slow down a bit
            }
            if(level &(CONTROL_LEFT|CONTROL_ROT_LEFT))
            {
                turn = 0.1;
                angular_motor.z += speed / turning_ratio ;
                linear *=0.7;
            }
            if(level &edge & (CONTROL_UP) && speedMult < 5.)
            {
                speedMult += 1.0;
                llTriggerSound(ACCEL_SOUND , soundVolume);
            }
            else if(level &edge & (CONTROL_DOWN) && speedMult > 1.)
            {
                speedMult -= 1.0;
            }
        }
        else
        {
            if(level &edge & CONTROL_ROT_RIGHT)
            {
                turn = -0.5;
                angular_motor.z -= speed / turning_ratio ;
                linear *=0.7; //slow down a bit
            }
            if(level &edge & CONTROL_ROT_LEFT)
            {
                turn = 0.5;
                angular_motor.z += speed / turning_ratio ;
                linear *=0.7;
            }
            if(level &edge & CONTROL_RIGHT)
            {
                speedMult += 1.0;
                llTriggerSound(ACCEL_SOUND , soundVolume);
            }
            if(level &edge & CONTROL_LEFT)
            {
                speedMult -= 1.0;
            }
            // going up or stop going up
            if(level & CONTROL_UP)
            {
                llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,VERTICAL_THRUST>);
                angular_motor.y = -5;
                llTriggerSound(ACCEL_SOUND , soundVolume);
            }
            // going down or stop going down
            if(level & CONTROL_DOWN)
            {
                llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,-VERTICAL_THRUST>);
                angular_motor.y = 1 ;
            }
        }

        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <llPow(speedMult, .9)*linear,0,0>);

        if (oldTurn != turn)
        {
             string nanim = DRIVE_ANIM;
             if (turn <0) nanim = DRIVERIGHT_ANIM;
             else if (turn >0) nanim=(DRIVELEFT_ANIM);
             if (driveAnim != nanim)
             {
                 llStopAnimation(driveAnim);
                 driveAnim = nanim;
                 llStartAnimation(driveAnim);
             }

            llSetLinkPrimitiveParamsFast(BL, [PRIM_OMEGA, <0,1,0>, dir*6, 1.0]);
            llSetLinkPrimitiveParamsFast(BR, [PRIM_OMEGA, <0,1,0>,dir*6, 1.0]);

            if (turn == 1 || turn == -1)
            {
                rotation ax = llEuler2Rot(<0,0, turn/3.>)*llEuler2Rot(WHEEL_ROTATION);

                llSetLinkPrimitiveParamsFast(FL, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>*llEuler2Rot(<0,0,turn/3.>) , speedMult*3., .2]);
                llSetLinkPrimitiveParamsFast(FR, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>*llEuler2Rot(<0,0,turn/3.>) , speedMult*3., .2]);
                if (speed>15.)
                {
                    psystem(FX_PRIM);
                    llPlaySound(SCREECH_SOUND, soundVolume);
                }
            }
            else
            {
                rotation ax = llEuler2Rot(<0,0,PI/2>);
                llStopSound();
                llSetLinkPrimitiveParamsFast(FL, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>, speedMult*3, 1.]);
                llSetLinkPrimitiveParams(FR, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir* <0,1,0>, speedMult*3, 1.]);
                llLinkParticleSystem(FX_PRIM, []);
                llLoopSound(ENGINE_SOUND, soundVolume);
            }
        }

        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);

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
            psystem(FX_PRIM);
        }
        else
        {
            llLinkParticleSystem(FX_PRIM, []);
        }
        refresh();
    }

    dataserver(key id, string m)
    {
      debug("dataserver: " +m);
      list tk = llParseStringKeepNulls(m, ["|"], []);
      if (llList2String(tk, 1) != PASSWORD) return;
      string cmd = llList2String(tk,0);
      integer i;

      if (cmd == "KWH" ) // Add water
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
              llMessageLinked(LINK_SET, 0, "UPDATE-FAILED", "");
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
    }

    timer()
    {
        if (status == "waitReturn")
        {
            integer result = osTeleportObject(llGetKey(), homePosition, homeRotation, 1);
            if (result !=1 )
            {
                llSetTimerEvent(30);
            }
            else
            {
                llSetTimerEvent(10);
                status = "waitReset";
            }
        }
        else if (status == "waitReset")
        {
            llSetRot(homeRotation);
            status = "";
        }
    }

    touch_start(integer n)
    {
        if (power<90) llSensor("SF kWh", "",SCRIPTED,  5, PI);
    }

    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llSay(0, "Found kWh , charging...");
        osMessageObject(id, "DIE|"+(string)llGetKey());
    }

    no_sensor()
    {
        llSay(0, "Error! kWh not found nearby! You must bring it near me!");
    }

}
