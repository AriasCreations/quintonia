    // prod-get_plugin.lsl
// Used to add a product to this items inventory if available in a region store
//
float VERSION = 4.0;    // 29 May 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

integer FARM_CHANNEL = -911201;
string PASSWORD="*";
key ownKey;
string status;
string lookingFor;
integer listener=-1;


// --- STATE DEFAULT -- //

default
{
    state_entry()
    {
        //sfp notecard
        PASSWORD = osGetNotecardLine("sfp", 0);
        ownKey = llGetKey();
        llListenRemove(listener);
    }

    listen(integer c, string nm, key id, string m)
    {
        debug("LISTEN: " +m +" (status= " +status +")");
        if (c == FARM_CHANNEL)
        {
            list tk = llParseString2List(m, ["|"], []);
            string cmd = llList2String(tk, 0);
            if (llList2String(tk, 1) != PASSWORD) return;
            if (cmd == "INV_AVAIL")
            {
                if (status == "waitNewItem")
                {
                    lookingFor = llList2String(tk, 3);
                    llRegionSay(FARM_CHANNEL, "INV_REQ|" +PASSWORD +"|" +(string)id +"|" +lookingFor);
                    status = "";
                    llMessageLinked(LINK_SET, 1, "PRODUCT_FOUND|" +PASSWORD +"|" +lookingFor, NULL_KEY);
                }
            }
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg + " From:" + (string)sender_num);
        list tk = llParseString2List(msg, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd == "GET_PRODUCT")
        {
            llListenRemove(listener);
            listener = llListen(FARM_CHANNEL, "", "", "");
            // GET-PRODUCT|PASSWORD|ITEM
            lookingFor = llList2String(tk, 2);
            // Assume product names are always 'AB xxx' eg SF Apples, DF Grapes etc.
            lookingFor = llGetSubString(lookingFor, 3, -1);
            llRegionSay(FARM_CHANNEL, "INV_QRY|" +PASSWORD +"|" +(string)ownKey +"|" +lookingFor);
            status = "waitNewItem";
            llSetTimerEvent(10);
        }
    }

    timer()
    {
        if (status == "waitNewItem")
        {
            llListenRemove(listener);
            llMessageLinked(LINK_SET, 0, "NO_PRODUCT|" +PASSWORD, NULL_KEY);
            status = "";
        }
    }

    dataserver( key id, string m)
    {
        debug("dataserver: " + m);
        list tk = llParseStringKeepNulls(m, ["|"], []);
        string cmd = llList2String(tk,0);
        integer i;
        if (llList2String(tk,1) != PASSWORD) return;
        //for updates
        if (cmd == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)((integer)(VERSION*10)) + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            string me = llGetScriptName();
            while (len--)
            {
                string item = llGetInventoryName(INVENTORY_SCRIPT, len);
                if (item != me)
                {
                    answer += item + ",";
                }
            }
            answer += me;
            osMessageObject(llList2Key(tk, 2), answer);
            //Send a message to other prim with script
            osMessageObject(llGetLinkKey(3), "VERSION-CHECK|" + PASSWORD + "|" + llList2String(tk, 2));
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(id) != llGetOwner())
            {
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(tk, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer delSelf = FALSE;
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item == me) delSelf = TRUE;
                else if (llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
            }
            integer pin = llRound(llFrand(1000.0));
            llSetRemoteScriptAccessPin(pin);
            osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) llResetScript();
    }

}
