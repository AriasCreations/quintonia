// prod-rez_plugin.lsl
// plugin for all items that rez products (kitchen, plant, storage, well etc)

float VERSION = 5.0;      // 22 August 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Default values, can be changed via config notecard
vector  rezzPosition = <0.0, 1.5, 2.0>;     // REZ_POSITION=<0.0, 1.5, 2.0>
string  provBoxName = "Provisions Box";     // BOX_NAME            Provisions box name

// Multilingual
string TXT_PROVISIONS_TRANSFERRED="Provisions transferred to";
string TXT_NOT_STORED="not in my Inventory";
string TXT_ERROR_UPDATE="Error: unable to update - you are not my Owner";
//
string languageCode = "en-GB";
string SUFFIX = "*";
vector PURPLE    = <0.694, 0.051, 0.788>;
//
string  PASSWORD="*";
integer FARM_CHANNEL = -911201;
key     toucher = NULL_KEY;
key     myKey;
string  product = "";
string  extraParams = "";
integer provLocked = 0;
string  pubKey = "";
integer prodScriptVer = 0;
string  prodScriptName = "";
string  existingScript = "";


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
                if (cmd == "REZ_POSITION") rezzPosition = (vector)val;
            }
        }
    }
}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    if (llGetInventoryType(languageNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseStringKeepNulls(osGetNotecard(languageNC), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    // Remove start and end " marks
                    val = llGetSubString(val, 1, -2);
                    // Now check for language translations
                         if (cmd == "TXT_NOT_STORED") TXT_NOT_STORED = val;
                         else if (cmd == "TXT_PROVISIONS_TRANSFERRED") TXT_PROVISIONS_TRANSFERRED = val;
                    else if (cmd == "TXT_ERROR_UPDATE") TXT_ERROR_UPDATE = val;
                }
            }
        }
    }
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg);
}

floatText(string msg, vector colour)
{
    llMessageLinked(LINK_SET, 1 , "TEXT|" + msg + "|" + (string)colour + "|", NULL_KEY);
}

default
{

    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2String(tk, 0);
        debug("dataserver: " + m + "  (cmd: " + cmd +")");
        if (llList2String(tk,1) != PASSWORD ) return;

        if (cmd == "SCRIPT_GIVEN")
        {
            if ((existingScript !="") && (llGetInventoryType(existingScript) == INVENTORY_SCRIPT)) llRemoveInventory(existingScript);
            existingScript = "";
            llResetScript();
        }

        //for updates
        else if (cmd == "VERSION-CHECK")
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
            messageObj(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, TXT_ERROR_UPDATE);
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
            messageObj(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
            if (delSelf)
            {
                llRemoveInventory(me);
            }
            llSleep(10.0);
            llResetScript();
        }
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    state_entry()
    {
        myKey = llGetKey();
        loadConfig();
        loadLanguage(languageCode);
        string itemName;
        string itemVer;
        integer i;
        integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (i=0; i < count; i++)
        {
            itemName = llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 6);
            itemVer  = llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 7, -1);

            if (itemName == "product")
            {
                prodScriptName = llGetInventoryName(INVENTORY_SCRIPT, i);
                prodScriptVer = (integer)itemVer;
            }
        }
        debug("prodScriptName=" +prodScriptName);
        llSetTimerEvent(5);
    }

    link_message(integer sender, integer val, string m, key id)
    {
        debug("link_message: " + m);
        list tk = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "REZ_PRODUCT")
        {
            //REZ_PRODUCT|PASSWORD|TOUCHER|PRODUCT|EXTRAPARAMS
            if (llList2String(tk, 1) != PASSWORD) return;
            provLocked = val;
            pubKey = id;
            if (provLocked != 1) provLocked =0;
            toucher = llList2Key(tk, 2);
            product = llList2String(tk, 3);
            if (llList2String(tk, 4) != "")
            {
                extraParams = llDumpList2String(llList2List(tk, 4, -1), "|");
            }

            if (llGetInventoryType(product) != INVENTORY_OBJECT)
            {
                llRegionSayTo(toucher, 0, product + " " + TXT_NOT_STORED);
                llMessageLinked(LINK_SET, 0, "PROD_NOT_FOUND|" + PASSWORD +"|" +(string)toucher +"|" + product, NULL_KEY);
                return;
            }
            llRezObject(product, llGetPos() + rezzPosition*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
        }
        else if (cmd == "LANG_MENU")
        {
            SUFFIX = llList2String(tk, 1);
            loadLanguage(languageCode);
        }
        else if (cmd == "SET-LANG")
        {
            languageCode = llList2String(tk, 1);
            loadLanguage(languageCode);
        }
        else if (cmd == "RELOAD")
        {
            llResetScript();
        }
        if (cmd == "CMD_DEBUG")
        {
            DEBUGMODE = llList2Integer(tk, 2);
            return;
        }
    }

    object_rez(key id)
    {
        if (llKey2Name(id) == ("SF " + provBoxName))
        {
            llSleep(0.1);
            llRemoteLoadScriptPin(id, prodScriptName, 999, TRUE, 1);
            messageObj(id, "INIT|" +PASSWORD +"|STOREVALS|" +extraParams);

            if (provLocked == TRUE)
            {
                llSleep(0.25);
                messageObj(id,  "LOCK|" +PASSWORD+"|" +pubKey);
            }

            floatText("\n" +TXT_PROVISIONS_TRANSFERRED +" " +provBoxName +"\n ", PURPLE);
        }
        else
        {
            llSleep(0.1);
            if (llGetInventoryType(prodScriptName) == INVENTORY_SCRIPT)
            {
                llRemoteLoadScriptPin(id, prodScriptName, 999, TRUE, 1);
                if (toucher != NULL_KEY)
                {
                    if (llGetListLength(llGetObjectDetails(id, [OBJECT_NAME])) !=0)  messageObj(id, "INIT|" +PASSWORD +"|" +(string)toucher);
                }
                else
                {
                    if (llGetListLength(llGetObjectDetails(id, [OBJECT_NAME])) !=0) messageObj(id, "INIT|" +PASSWORD);
                }
                llMessageLinked(LINK_SET, 99, "REZZEDPRODUCT|" + PASSWORD +"|" +(string)id +"|" + product, NULL_KEY);
            }
            else
            {
                llRegionSayTo(toucher, 0, "'product' " +TXT_NOT_STORED);
            }
        }
        if (languageCode != "")
        {
            llSleep(0.5);
            messageObj(id,  "LANG|" +PASSWORD+"|" +llGetKey()+"|" +languageCode);
        }
    }

    timer()
    {
        existingScript = "product";
        if (prodScriptVer != 0) existingScript += (string)prodScriptVer;
        llRegionSay(FARM_CHANNEL, "SCRIPT_REQ|" +PASSWORD +"|" +(string)myKey +"|" +"PRODUCT" +"|" +(string)prodScriptVer);
        llSetTimerEvent(3600);
    }

}
