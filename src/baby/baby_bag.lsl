// baby_bag.lsl
//  Version 1.0   26 October 2020
//   Plays various baby sounds when baby is attached to same avatar as bag.

list    soundsList = [];
integer numberSounds = 0;
integer index = 0;

default
{
    state_entry()
    {
        integer i;
        numberSounds = llGetInventoryNumber(INVENTORY_SOUND);
        for (i = 0; i <= numberSounds; ++i)
        {
            soundsList += llGetInventoryName(INVENTORY_SOUND, i);
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "CRITTER_STATUS")
        {
            if (num != 0)
            {
                llSetTimerEvent(0.1);
            }
            else
            {
                llSetTimerEvent(0);
                llStopSound();
            }
        }
    }

    timer()
    {
        llSetTimerEvent(30.0);
        llPlaySound(llList2String(soundsList, index), 0.5);
        index +=1;
        if (index > numberSounds) index = 0;
    }

}
