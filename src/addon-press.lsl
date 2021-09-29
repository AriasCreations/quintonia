//### press.lsl
// Version 1.2    // 27 January 2020

default
{
    changed(integer change)
    {
        if (llGetObjectPrimCount(llGetKey()) != llGetNumberOfPrims())
        {
            llTargetOmega(<0,0,1>, -.4, 1.0);
            llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, <0,0,1>, -.4, 1.0]);
            llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, <0,0,1>, .4, 1.0]);
            llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, <1,0,0>, -.4, 1.0]);
        }
        else
        {
            llTargetOmega(<0,0,1>*0, 1.0, 1.0);
            llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, 0* <0,0,1>, -.4, 1.0]);
            llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
            llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
        }
    }
}
