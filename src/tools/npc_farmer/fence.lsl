default
{
    on_rez(integer start_param)
    {
        if (start_param == 0) start_param = 1;
        llSetPrimitiveParams( [ PRIM_SIZE, <start_param, start_param, 0.5> ] );
    }

   touch_end(integer num)
    {
        llSay(0, "Good bye!");
        llDie();
    }
}
