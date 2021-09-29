// power_lighting_switch_rocker.lsl

default
{

    state_entry()
    {
        llSetLocalRot(<-0.026177, 0.000000, 0.000000, 0.999657>);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "STARTCOOKING")
        {
            // <3.0, 0.0, 0.0>
            // Switch: <0.026177, 0.000000, 0.000000, 0.999657>
            llSetLocalRot(<0.026177, 0.000000, 0.000000, 0.999657>);
        }
        else if (cmd == "ENDCOOKING")
        {
            // <357.0, 0.0, 0.0>
            // Switch: <-0.026177, 0.000000, 0.000000, 0.999657>
            llSetLocalRot(<-0.026177, 0.000000, 0.000000, 0.999657>);
        }
    }

}
