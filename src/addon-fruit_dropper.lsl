// addon-fruit_dropper.lsl
//Rezzes a self destructing coconut fruit every 1 to 3 minutes when plant is ripe

float gRandomFloat;
integer ripe;

default
{

    state_entry()
    {
        ripe = FALSE;
    }

    timer()
    {
        if (ripe == TRUE)
        {
            // This line will pick the first object out of the container and rez it
            llRezObject(llGetInventoryName(INVENTORY_OBJECT,0), llGetPos()+<0,0,.5>,ZERO_VECTOR,ZERO_ROTATION,0);
            //Generate a new random fruiting time of between 1 and 3 minutes
            gRandomFloat = 3.0 - llFrand(2.0);
            llSetTimerEvent(gRandomFloat * 60);
        }
        else llSetTimerEvent(0);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tok = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "STAGE")
        {
            if (llList2String(tok, 1) == "RIPE")
            {
                ripe = TRUE;
                llSetTimerEvent(1.0);
            }
            else
            {
                ripe = FALSE;
                llSetTimerEvent(0);
            }
        }
    }

}
