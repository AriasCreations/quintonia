default
{
    on_rez(integer start_param)
    {
        float dim;
        
        if (start_param == 0) dim =2.0; else dim = start_param * 2;
        llSay(0, "Matching scan radius of " + start_param + "m\n \nTouch to remove.");
        llSetPrimitiveParams([
                PRIM_TYPE, 
                    PRIM_TYPE_CYLINDER, 
                    PRIM_HOLE_DEFAULT,  // hole_shape
                    <0.00, 1.0, 0.0>,   // cut
                    0.25,                // hollow
                    <0.0, 0.0, 0.0>,    // twist
                    <1.0, 1.0, 0.0>,    // top_size
                    <0.0, 0.0, 0.0>,     // top_Shear ]); 
                    PRIM_SIZE, <dim, dim, 0.2>
                    ]); 
        llSetTimerEvent(300);
    }

    touch_end(integer num)
    {
        llDie();
    }

    timer()
    {
        llDie();
    }
}
