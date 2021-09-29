// power_wind_turbine-rotor.lsl

float vel = 1.0;

default
{
    state_entry()
    {
       llTargetOmega(<1,0,0>, vel, 1.0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "VELOCITY")
        {
            vel = (num * 5);
            vel = vel / 100;
            llTargetOmega(<1,0,0>, vel, 1.0);
        }
    }
}