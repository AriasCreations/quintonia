// setpin.lsl
// Version 1.1  28 November 2020

default
{
    state_entry()
    {
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_TEXT, "", ZERO_VECTOR, 0.0]);
    }

    on_rez(integer n)
    {
        llSetRemoteScriptAccessPin(999);
    }

}
