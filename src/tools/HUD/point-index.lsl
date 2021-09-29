// -------------------------------------------
//  QUINTONIA FARM HUD - Point index display
// -------------------------------------------
//
float version = 5.0;    // 21 September 2020

// INFO
// Shows percentage level for collecting points


string cmd = "POINT";
float level;

default
{

    state_entry()
    {
        llSetLinkPrimitiveParams(LINK_THIS,[PRIM_SLICE,<0.0, 0.0, 0.0>]);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        if (msg == cmd)
        {
            level = num / 100.0;
            llSetLinkPrimitiveParams(LINK_THIS,[PRIM_SLICE,<0.0, level, 0.0>]);
        }
    }
}
