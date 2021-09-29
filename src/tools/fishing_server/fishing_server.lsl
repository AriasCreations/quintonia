// fishing_server-server.lsl

integer FARM_CHANNEL = -911201;
integer listenerFarm;
string PASSWORD="*";
key avatarID;


default
{
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        listenerFarm = llListen(FARM_CHANNEL, "", "", "");
    }

    listen(integer c, string nm, key id, string m)
    {
        if (c == FARM_CHANNEL)
        {
            llOwnerSay("DEBUG: Server heard " + m);
            list cmd = llParseStringKeepNulls(m, ["|"] , []);
            if (llList2String(cmd,1) != PASSWORD ) return;
            string item = llList2String(cmd,0);

            if (item == "FISHREQ")
            {
                osForceAttachToOtherAvatarFromInventory(llList2Key(cmd,2), "FishingRodX", ATTACH_LHAND);
            }
            if (item == "ENDFISH")
            {
                osTeleportObject(llList2Key(cmd,2), <94,174,22.5>, ZERO_ROTATION, 1);
                llSleep(30);
                llOwnerSay("OSDIE From server: " + llList2String(cmd,2));
                osDie(llList2Key(cmd,2));
            }
        }
    }

}
