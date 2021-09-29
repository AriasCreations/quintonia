// Version 1.1    1 August 2020
//

string TXT_SELECT = "Select updater:";
string TXT_CLOSE = "CLOSE";

//for listener and menus
integer listener=-1;
integer listenTs;

string prefix = "SF Updater-";
list updaters =[];

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
    }
}


default
{
    state_entry()
    {
        updaters = [];
        integer i;
        integer numObjects = llGetInventoryNumber(INVENTORY_OBJECT);
        for (0; i<numObjects; i+=1)
        {
            updaters += llGetInventoryName(INVENTORY_OBJECT, i);
        }
        llOwnerSay(llDumpList2String(updaters,", "));
    }

    touch_start(integer index)
    {
        list opts = [];
        string tmpStr;
        integer i;
        integer j = llGetListLength(updaters);
        for (0; i<j; i+=1)
        {
            tmpStr = llList2String(updaters, i);
            tmpStr = llGetSubString(tmpStr, 11, -1);
            opts += tmpStr;
        }
        opts += [TXT_CLOSE];
        startListen();
        llDialog(llDetectedKey(0), TXT_SELECT, opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == TXT_CLOSE)
        {
            checkListen(TRUE);
        }
        else
        {
            integer index = llListFindList(updaters, prefix + message);
            if (index != -1)
            {
                llGiveInventory(id, prefix + message);
            }
            checkListen(TRUE);
        }
    }

    timer()
    {
        checkListen(FALSE);
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
                llResetScript();
        }
    }


}
