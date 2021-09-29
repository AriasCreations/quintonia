
string TXT_MESSAGE = "Restoring life";

string  FX = "force";
integer FARM_CHANNEL = -911201;
string  PASSWORD = "farm";
key     toucher = NULL_KEY;
integer reset;


default
{
    state_entry()
    {
        llStopSound();
        llMessageLinked(LINK_SET, 0, "OFF", "");
        llSetText("", ZERO_VECTOR, 0.0);
    }

    touch_end(integer num)
    {
        toucher = llDetectedKey(0);
        llMessageLinked(LINK_SET, 0, "ON", "");
        llSetText(TXT_MESSAGE+".", <0.0, 0.6, 0.4>,1.0);
        llRegionSayTo(toucher, 0, TXT_MESSAGE);
        llLoopSound(FX, 1.0);
        reset = FALSE;
        llSetTimerEvent(10);
    }

    timer()
    {
        if (reset == FALSE)
        {
            llSetText(TXT_MESSAGE+". .", <0.0, 0.9, 0.2>,1.0);
            llRegionSay(FARM_CHANNEL, "MAGIC|"+PASSWORD+"|RESTORE_LIFE|"+(string)toucher +"|0");
            reset = TRUE;
        }
        else
        {
            llRegionSay(FARM_CHANNEL, "MAGIC|"+PASSWORD+"|RESTORE_LIFE|"+(string)toucher +"|1");
            llMessageLinked(LINK_SET, 0, "OFF", "");
            llSetText("", ZERO_VECTOR, 0.0);
            llSetTimerEvent(0);
            llStopSound();
        }
    }
}
