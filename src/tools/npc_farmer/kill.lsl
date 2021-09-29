default
{
    on_rez(integer start_param)
    {
        if (start_param == 0) start_param = 1;
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                        PRIM_SIZE, <start_param, start_param, 2.0>]);
        llScaleTexture(3*start_param, 2.0, 1);
        llScaleTexture(3*start_param, 2.0, 2);
    }

   touch_end(integer num)
    {
        llSay(0, "Good bye!");
        llDie();
    }
}
