
rotation gateOpen = <0.000000, 0.000000, -0.888513, 0.458852>;
rotation gateClosed = <0.000000, 0.000000, 0.583368, 0.812208>;

rotation rot_xyzq1;
rotation rot_xyzq2;

default
{

    state_entry()
    {
        llSetLocalRot(gateClosed);
        vector xyz_angles = <0.0, 0.0, 3.0>; // This is to define a 2 degree change
        vector angles_in_radians = xyz_angles*DEG_TO_RAD; // Change to Radians
        rot_xyzq1 = llEuler2Rot(angles_in_radians); // Change to a Rotation
        xyz_angles = <0.0, 0.0, -3.0>; // This is to define a 2 degree change
        angles_in_radians = xyz_angles*DEG_TO_RAD; // Change to Radians
        rot_xyzq2 = llEuler2Rot(angles_in_radians); // Change to a Rotation
    }

   link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "STARTCOOKING")
        {
            rotation newRot;
            integer i = 0;
            do
            {
                newRot = llGetLocalRot()*rot_xyzq1;
                llSetLocalRot(newRot);
                i +=1;
            }
            while (i < 50);
            llSetLocalRot(gateOpen);
        }

        if (str == "ENDCOOKING")
        {
            rotation newRot;
            integer i = 0;
            do
            {
                newRot = llGetLocalRot()*rot_xyzq2;
                llSetLocalRot(newRot);
                i +=1;
            }
            while (i < 50);
            llSetLocalRot(gateClosed);
        }
    }
}
