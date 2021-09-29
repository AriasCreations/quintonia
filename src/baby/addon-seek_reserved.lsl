// addon-seek_reserved.lsl
//  Version 1.0      25 October 2020
//   Allows items to go to the special 'reserved' prim(s) on surface items

string   TARGET;
key      currentTargetID;
key      newTargetID;
integer  locIndex;
rotation myRezRot;
string   status;

string downTarget = "SF Baby Rug";



messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

emptyTarget(key targetID)
{
    if (targetID != NULL_KEY)
    {
        // Let reserved target know it's empty again
        messageObj(targetID, "EMPTY_RESERVED|" + (string)locIndex);
        locIndex = -1;
    }
}

invalidateTargets()
{
    status = "";
    llSetTimerEvent(0);
    // We didn't find an empty target so tell old location we have moved
    if (currentTargetID != NULL_KEY) emptyTarget(currentTargetID);
    // Now just go to the ground & invalidate target ID's
    currentTargetID = NULL_KEY;
    newTargetID = NULL_KEY;
    llSetPos(llGetPos()- <0,0, -0.2>);
    llMessageLinked(LINK_SET, 1, "MY_LOCATION|AM_DOWN", "");
}


default
{
    on_rez(integer start_param)
    {
        myRezRot = llGetRot();
        currentTargetID = NULL_KEY;
        newTargetID = NULL_KEY;
    }

    sensor( integer num_detected )
    {
        if (status == "seekRug")
        {
            vector rugLocation = llList2Vector(llGetObjectDetails(llDetectedKey(0), [OBJECT_POS]), 0);
            rugLocation.z -= 0.3;
            if (llSetRegionPos(rugLocation) == TRUE)
            {
                // we got to the rug!
            }
            invalidateTargets();
        }
        else
        {
            // We found an empty reserved target so ask it where to land
            newTargetID  = llDetectedKey(0);
            messageObj(newTargetID, "WHERE_RESERVED");
            llSetTimerEvent(3.0);
        }
    }

    no_sensor()
    {
        if (status == "firstLook")
        {
            status = "secondLook";
            llSensor(TARGET+"-FULL", NULL_KEY, PASSIVE | SCRIPTED, 20.0, PI);
        }
        else
        {
            invalidateTargets();
        }
    }

    dataserver(key id, string msg)
    {
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk, 0);
        //
        if (cmd == "LAND_HERE")
        {
            // Tell old location we have moved
            emptyTarget(currentTargetID);
            llSetTimerEvent(0);
            if (llSetRegionPos(llList2Vector(tk,1)) == TRUE)
            {
                // we got to the new target, so now its our current one!
                currentTargetID = newTargetID;
                newTargetID = NULL_KEY;
                llSetRot(llList2Rot(tk,3));
                string m = "";
                integer count;
                integer i;
                locIndex = llList2Integer(tk, 2);
                messageObj(currentTargetID, "VIP|" +(string)locIndex);
                llMessageLinked(LINK_SET, 1, "MY_LOCATION|"+llKey2Name(currentTargetID), "");
            }
            else
            {
                invalidateTargets();
            }
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        //
        if (cmd == "SEEK_SURFACE")
        {
            // llSetKeyframedMotion( [], []);
            TARGET = llList2String(tk, 1);
            status = "firstLook";
            // Look for an empty target
            llSensor(TARGET, NULL_KEY, PASSIVE | SCRIPTED, 20.0, PI);
        }
        else if (cmd == "PUT_DOWN")
        {
            status = "seekRug";
            TARGET = downTarget;
            llSensor(TARGET, NULL_KEY, PASSIVE | SCRIPTED, 20.0, PI);
        }
    }

    timer()
    {
        invalidateTargets();
    }

}
