// Version 1.1  24 May 2020
//

string textureDry = "wetlands";
string textureWet = "water";

string stage;

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
        {   if (stage == "RIPE")
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
        else if (cmd == "STAGE")
        {
            integer ln = getLinkNum("Water");
            stage = llList2String(tok, 1);
            if (stage == "EMPTY")
            {
                llSetLinkPrimitiveParamsFast(ln, [ PRIM_TEXTURE, ALL_SIDES, textureDry, <1,1,1>, <0,0,0>, 0.0] );
                llSetLinkTextureAnim(ln, FALSE, ALL_SIDES, 0, 0, 0.0,0.0, 1.0);
            }
            else if (stage == "NEW")
            {
                llSetLinkPrimitiveParamsFast(ln, [ PRIM_TEXTURE, ALL_SIDES, textureWet, <1,1,1>, <0,0,0>, 0.0] );
                llSetLinkTextureAnim(ln, ANIM_ON | SMOOTH | ROTATE | LOOP, ALL_SIDES, 1, 1, 0, TWO_PI, 0.01);
            }
            else if (stage == "GROWING")
            {
                llSetLinkPrimitiveParamsFast(ln, [ PRIM_TEXTURE, ALL_SIDES, textureDry, <1,1,1>, <0,0,0>, 0.0] );
                llSetLinkTextureAnim(ln, FALSE, ALL_SIDES, 0, 0, 0.0,0.0, 1.0);
            }
            else if (stage == "RIPE")
            {
                llSetLinkPrimitiveParamsFast(ln, [ PRIM_TEXTURE, ALL_SIDES, textureWet, <1,1,1>, <0,0,0>, 0.0] );
                llSetLinkTextureAnim(ln, ANIM_ON | SMOOTH | ROTATE | LOOP, ALL_SIDES, 1, 1, 0, TWO_PI, 0.01);
            }
            else stage = "";
        }

    }
}
