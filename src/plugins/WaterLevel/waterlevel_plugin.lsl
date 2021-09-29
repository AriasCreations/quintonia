
integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}


default
{
    state_entry()
    {
        //for updates
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1)
        {
            string me = llGetScriptName();
            llOwnerSay("Script " + me + " went to sleep inside Updater.");
            llSetScriptState(me, FALSE);
            return;
        }
    }

    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "STATUS") 
        {   
            integer ln = getLinkNum("Water");
            // position our water overlay according to water level
            float water = llList2Float(tok, 4);
            vector v ;
            v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_SIZE]), 0);
            v.z = 0.3* water/100.;
            llSetLinkPrimitiveParamsFast(ln, [PRIM_SIZE, v]);
        }

    }
}
