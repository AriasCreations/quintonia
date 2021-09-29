// addon-textures.lsl
// Version 1.0   4 December 2020

string TXT_SELECT = "Select";
string TXT_CLOSE = "CLOSE";

string  status = "";
integer listener = -1;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


default
{

    on_rez(integer val)
    {
        llResetScript();
    }

    state_entry()
    {
        llMessageLinked(LINK_SET, 99, "ADD_MENU_OPTION|Texture", "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if (status == "waitTexture")
        {
            if (llGetInventoryType("TEX-"+message) == INVENTORY_TEXTURE) llSetTexture("TEX-"+message, ALL_SIDES);
            llSetTimerEvent(0.1);
        }
        else if (message == TXT_CLOSE) llSetTimerEvent(0.1);
    }

    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(listener);
        status = "";
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        list tk = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "MENU_OPTION")
        {
            if (llList2String(tk, 1) == "Texture")
            {
                list opts = TXT_CLOSE;
                integer index;
                string name;
                integer count = llGetInventoryNumber(INVENTORY_TEXTURE);
                for (index = 0; index < count; index++)
                {
                    name = llGetInventoryName(INVENTORY_TEXTURE, index);
                    if (llGetSubString(name, 0, 3) == "TEX-") opts += llGetSubString(name, 4, -1);
                }
                listener = llListen(chan(llGetKey()), "", "", "");
                status = "waitTexture";
                llSetTimerEvent(180);
                llDialog(id, TXT_SELECT, opts, chan(llGetKey()));
            }
        }
        else if (cmd == "LANG")
        {
                 if (llList2String(tk, 1) == "SELECT") TXT_SELECT = llList2String(tk, 2);
            else if (llList2String(tk, 1) == "CLOSE")  TXT_CLOSE = llList2String(tk, 2);
        }
        else if (cmd == "RESET")
        {
            llResetScript();
        }
    }

}
