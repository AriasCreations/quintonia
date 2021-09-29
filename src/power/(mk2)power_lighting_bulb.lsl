// power_lighting_bulb.lsl
// Lighting that uses power from the region grid and/or loacal SF kWh
//
float   VERSION = 5.1;    // Beta  5 November 2020
integer RSTATE = -1;      // RSTATE: 1=release, 0=beta, -1=RC
//
integer face = 3;
integer link = LINK_THIS;
//
// Can be overidden by config notecard
float  brightness = 1.0;
vector lightColour = <1.000, 1.000, 0.8>;
float  radius = 20.0;
float  falloff = 0.0;

integer channOffset = 0;    // CHAN=

integer comms_channel;
string PASSWORD="*";
integer listener=-1;

loadConfig()
{
    integer i;
    //sfp Notecard
    PASSWORD = osGetNotecardLine("sfp", 0);
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseStringKeepNulls(line, ["="], []);
                string cmd = llList2String(tok, 0);
                string val = llList2String(tok, 1);
                if (cmd == "CHAN") channOffset = (integer)val;
                else if (cmd == "COLOR") lightColour = (vector)val;
                else if (cmd == "BRIGHTNESS")
                {
                    brightness = (float)val/10;
                    if (brightness > 1.0) brightness = 1.0;
                }
                else if (cmd == "RADIUS")
                {
                    radius = (float)val;
                    if (radius > 20.0) radius = 20.0;
                    if (radius < 0.1) radius = 0.1;
                }
                else if (cmd == "FALLOFF")
                {
                    falloff = (float)val;
                    if (falloff > 2.0) falloff = 2.0;
                    if (falloff < 0.01) falloff = 0.01;
                }
            }
        }
    }
    comms_channel += channOffset;
    llSetObjectDesc("L;" + (string)channOffset);
}

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


default
{
    listen(integer c, string nm, key id, string m)
    {
        if (c == comms_channel)
        {
            list tk = llParseStringKeepNulls(m , ["|"], []);
            if (llList2String(tk,1) != PASSWORD)  { llOwnerSay("BAD PASSWORD"); return;  }
            string cmd = llList2String(tk,0);

            if (cmd == "OFF")
            {
                llSetLinkPrimitiveParams(LINK_THIS, [PRIM_COLOR, face, <1,1,1> , 1.0,
                                                     PRIM_GLOW, ALL_SIDES, 0.0,
                                                     PRIM_POINT_LIGHT, FALSE, <1.0, 1.0, 0.8>, 1.0, 15.0, 0.0 ]);
            }
            else if (cmd == "ON")
            {
                llSetLinkPrimitiveParams(LINK_THIS, [PRIM_COLOR, face, <0.789, 0.631, 0.211> , 1.0,
                                                     PRIM_GLOW, face, 0.5,
                                                     PRIM_POINT_LIGHT, TRUE, lightColour, brightness, radius, falloff]);
            }
        }
    }

    state_entry()
    {
        comms_channel = chan(llGetOwner());
        loadConfig();
        listener = llListen(comms_channel, "", "", "");
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY | CHANGED_OWNER) llResetScript();
        else if (change & CHANGED_REGION_START) loadConfig();
    }

}
