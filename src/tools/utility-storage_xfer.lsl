// storage_xfer.lsl
//
// Process is:
// Touch this box to initiate a scan for nearest item
// Send command to item for it to initiate the transfer sequence
// Uset either touches the item to confirm or touches this to abort

float VERSION = 1.0;    // BETA 12 October 2020

//
integer DEBUGMODE = FALSE;    // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}

//
// config notecard can overide the following:
string  storeName = "SF Store Barrel";    // STORE_NAME=SF Store Barrel
string  languageCode = "en-GB";           // LANG=en-GB
//
// Multilingual support
string TXT_TRYING="Touch store to confirm";
string TXT_ABORT="Touch this box to abort";
string TXT_NOT_FOUND="Not found";
string TXT_INFO="Transfer stored items";
string TXT_CANCELLED="Cancelled";
string TXT_FAILED = "Something went wrong, aborting";
string TXT_PHASE2 = "Remove old store and bring new store and this box close together";
string TXT_TOUCH_START = "Touch this box to start transfer";
string TXT_RETRY  = "Please bring new store and box closer together";
string TXT_COMPLETE = "Transfer complete!";
string TXT_LANGUAGE="@";
//
string  SUFFIX = "U1";
string  PASSWORD="*";
string  STORAGENC = "storagenc";
vector  BLUE = <0.224, 0.800, 0.800>;
integer scanRange = 10;
string  status;
key     storeID;
key     userID = NULL_KEY;
integer tryCount =0;
string  txtMessage;
vector  txtColour;


loadConfig()
{
    //sfp Notecard
    PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    //config Notecard
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        string line;
        list tok;
        string cmd;
        string val;
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            line = llStringTrim(llList2String(lines, i), STRING_TRIM);
            if (llGetSubString(line, 0, 0) != "#")
            {
                tok = llParseStringKeepNulls(line, ["="], []);
                cmd = llList2String(tok, 0);
                val = llList2String(tok, 1);
                     if (cmd == "STORE_NAME") storeName = val;
                else if (cmd == "LANG") languageCode = val;
            }
        }
    }

}

loadLanguage(string langCode)
{
    // optional language notecard
    string languageNC = langCode + "-lang" + SUFFIX;
    debug("loadLanguage asked for " + TXT_LANGUAGE + " " +languageNC);
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
                         if (cmd == "TXT_TRYING")   TXT_TRYING = val;
                    else if (cmd == "TXT_ABORT")    TXT_ABORT = val;
                    else if (cmd == "TXT_NOT_FOUND")   TXT_NOT_FOUND = val;
                    else if (cmd == "TXT_INFO")  TXT_INFO = val;
                    else if (cmd == "TXT_CANCELLED")  TXT_CANCELLED = val;
                    else if (cmd == "TXT_FAILED") TXT_FAILED  = val;
                    else if (cmd == "TXT_PHASE2")  TXT_PHASE2 = val;
                    else if (cmd == "TXT_TOUCH_START") TXT_TOUCH_START  = val;
                    else if (cmd == "TXT_RETRY") TXT_RETRY  = val;
                    else if (cmd == "TXT_COMPLETE") TXT_COMPLETE  = val;
                    else if (cmd == "TXT_LANGUAGE") TXT_LANGUAGE = val;
                }
            }
        }
    }
}

psys(key k)
{
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE,
                    PSYS_SRC_ANGLE_BEGIN, 0.0,
                    PSYS_SRC_ANGLE_END, 0.0,

                    PSYS_SRC_TARGET_KEY, k,
                    PSYS_PART_TARGET_LINEAR_MASK, 1,

                    PSYS_PART_START_COLOR,<1.0, 0.8, 0.8>,
                    PSYS_PART_END_COLOR,<1.0, 1.0, 1.0>,

                    PSYS_PART_START_ALPHA,0.5,
                    PSYS_PART_END_ALPHA,1.0,

                    PSYS_PART_START_GLOW,0.05,
                    PSYS_PART_END_GLOW,0.1,

                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                    PSYS_PART_START_SCALE,<0.20, 0.20, 0>,
                    PSYS_PART_END_SCALE,<0.75, 0.75, 0>,

                    PSYS_SRC_TEXTURE,"fx",

                    PSYS_SRC_MAX_AGE, 0.5,
                    PSYS_PART_MAX_AGE, 2,
                    PSYS_SRC_BURST_RATE, 0.1,
                    PSYS_SRC_BURST_PART_COUNT, 3,
                    PSYS_SRC_BURST_SPEED_MIN, 2.0,
                    PSYS_SRC_BURST_SPEED_MAX, 2.0,

                    PSYS_SRC_ACCEL,<0.00, 0.10, 0.00>,
                    PSYS_SRC_OMEGA,<0.00, 0.00, 0.00>,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                       PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
}

messageObj(key objId, string msg)
{
    list check = llGetObjectDetails(objId, [OBJECT_NAME]);
    if (llList2String(check, 0) != "") osMessageObject(objId, msg); else debug("messageObj failed sending " + msg + " to:"+(string)objId);
}

default
{

    timer()
    {
        llSetTimerEvent(0);
        llSetText(TXT_INFO +"\n" +storeName, <1,1,1>, 1.0);
        llParticleSystem([]);
        status = "idle";
    }

    touch_start(integer n)
    {
        debug("touch:status="+status +" (storeName="+storeName+")");
        if (status == "idle")
        {
            userID = llDetectedKey(0);
            if (llGetOwner() == userID)
            {
                status = "phase1start";
                llSensor(storeName, "", SCRIPTED, scanRange, PI);
            }
        }
        else if (status == "waitTargetConfirm")
        {
            // abort!
            messageObj(storeID, "REQUEST-INV-ABORT|" +PASSWORD);
            txtMessage = TXT_CANCELLED;
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
            llSleep(2.0);
            llResetScript();
        }
        else if (status == "phase2start")
        {
            llSensor(storeName, "", SCRIPTED, scanRange, PI);
        }
        else if (status == "waitGiveConfirm")
        {
            // abort!
            messageObj(storeID, "REQUEST-INV-ABORT|" +PASSWORD);
            status = "phase2start";
            txtMessage = TXT_PHASE2 +"\n" +TXT_TOUCH_START;
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
        }
    }

    state_entry()
    {
        llParticleSystem([]);
        loadConfig();
        loadLanguage(languageCode);
        llSetText(TXT_INFO +"\n" +storeName, <1,1,1>, 1.0);
        status = "idle";
        if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD)
        {
            status = "phase2start";
            txtMessage = TXT_PHASE2 +"\n" +TXT_TOUCH_START;
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
            llSetColor(BLUE, ALL_SIDES);
        }
        else llSetColor(<1,1,1>,ALL_SIDES);
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    sensor(integer n)
    {
        debug("sensor:status="+status +"  Detected="+llDetectedKey(0));
        if (status == "phase1start")
        {
            storeID = llDetectedKey(0);
            messageObj(storeID, "REQUEST-INV-START|" +PASSWORD);
            status = "waitTargetConfirm";
            llSetText(TXT_TRYING+"\n"+TXT_ABORT, <1.000, 0.522, 0.106>,1.0);
        }
        else if (status == "phase2start")
        {
            storeID = llDetectedKey(0);
            messageObj(storeID, "STOCK-XFER-CHECK|" +PASSWORD);
            txtMessage = TXT_TRYING +"\n" + TXT_ABORT;
            txtColour = <0.180, 0.800, 0.251>;
            llSetText(txtMessage, txtColour, 1.0);
            llSetColor(BLUE, ALL_SIDES);
            status = "waitGiveConfirm";
        }
    }

    no_sensor()
    {
        if (status == "phase1start")
        {
            llOwnerSay(TXT_NOT_FOUND);
            llSetTimerEvent(15);
        }
        else
        {
            llOwnerSay(TXT_RETRY +"\n" +TXT_TOUCH_START);
        }
    }

    dataserver(key id, string m)
    {
        debug("dataserver:"+m);
        list tk = llParseString2List(m, ["|"], []);
        if (llList2String(tk,1) != PASSWORD)
        {
            return;
        }
        string cmd = llList2String(tk, 0);
        key kobject = llList2Key(tk, 2);

        if (cmd == "REQUEST-INV-OKAY")
        {
            txtMessage = "";
            txtColour = ZERO_VECTOR;
            llSetText(txtMessage, txtColour, 1.0);
            status = "";
            storeID = id;
            if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD) llRemoveInventory(STORAGENC);
            messageObj(storeID, "REQUEST-INV-CONFIRM|" +PASSWORD);
        }
        else if (cmd == "REQUEST-INV-SENT")
        {
            llSleep(1.0);
            if (llGetInventoryType(STORAGENC) != INVENTORY_NOTECARD)
            {
                llSleep(3.0);
                if (llGetInventoryType(STORAGENC) != INVENTORY_NOTECARD)
                {
                    messageObj(storeID, "REQUEST-INV-ABORT|" +PASSWORD);
                    txtMessage = TXT_FAILED;
                    txtColour = <1,0,0>;
                    llSetText(txtMessage, txtColour, 1.0);
                    llSleep(5);
                    llResetScript();
                }
            }
            messageObj(storeID, "REQUEST-INV-DONE|" +PASSWORD);
            // now give notecard to new store
            status = "phase2start";
            txtMessage = TXT_PHASE2+ "\n"+TXT_TOUCH_START;
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
        }
        else if (cmd == "REQUEST-INV-FAIL")
        {
            llOwnerSay(TXT_NOT_FOUND);
            txtMessage = TXT_NOT_FOUND;
            txtColour = <1,0,0>;
            llSetText(txtMessage, txtColour, 1.0);
            llSleep(2);
            llResetScript();
        }
        else if (cmd == "XFER-READY")
        {
            txtMessage = "...";
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
            storeID = id;
            llGiveInventory(storeID, STORAGENC);
            llSleep(1);
            messageObj(storeID, "REQUEST-XFER-CONFIRM|" +PASSWORD);
            status = "waitXferConfirm";
        }
        else if (cmd == "XFER-CONFIRM-OKAY")
        {
            txtMessage = TXT_COMPLETE;
            txtColour = <1,1,1>;
            llSetText(txtMessage, txtColour, 1.0);
            if (llGetInventoryType(STORAGENC) == INVENTORY_NOTECARD) llRemoveInventory(STORAGENC);
            llSetColor(<1,1,1>, ALL_SIDES);
            llSetTimerEvent(10);
        }
        else if (cmd == "XFER-CONFIRM-FAIL")
        {
            llSleep(2);
            tryCount +=1;
            if (tryCount > 3)
            {
                llGiveInventory(storeID, STORAGENC);
                llSleep(2);
                messageObj(storeID, "REQUEST-XFER-CONFIRM|" +PASSWORD);
            }
            else
            {
                txtMessage = TXT_FAILED;
                txtColour = <1,0,0>;
                llSetText(txtMessage, txtColour, 1.0);
                llSleep(2);
                llResetScript();
            }
        }
    }


    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            loadConfig();
            loadLanguage(languageCode);
            llSetText(txtMessage, txtColour, 1.0);
        }
        if (change & CHANGED_OWNER) llResetScript();
    }

}
