// messenger.lsl
//
float version = 5.1;   //  5 October 2020
//
integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

//
// multilingual support strings
string TXT_OPTION = "Messages";
string TXT_CLOSE = "CLOSE";
//
integer xpTotal;
integer lastMSgID = -1;
integer unread;
integer read;
list messageStore = [];    // [message, message id, read]
string status;
string msgNC = "DATA_MSGS";
string fxSound = "MapleLeafRag";
integer notified;
integer doFX = FALSE;
//
integer XP_FACE = 4;
integer MSG_FACE = 0;
vector GREEN = <0.136, 0.614, 0.193>;
vector GREY  = <0.502, 0.502, 0.502>;
vector CYAN = <0.498, 0.859, 1.000>;
//
string TXT_NEW_MSG = "*";
string TXT_OLD_MSG = " ";
string TXT_MSG = "MSG";
integer chan(key u)

{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

integer listener=-1;
integer listenTs;

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
    debug("startListen:"+(string)listenTs);
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

postMessage(string msg)
{
    llMessageLinked(LINK_SET, 1, "CMD_POST|"+msg, "");
}

floatText(string msg, vector colour)
{
    llMessageLinked(LINK_SET, 1 , "TEXT|" + msg + "|" + (string)colour + "|", NULL_KEY);
}

msgDialog()
{
    debug("messageStore:\n"+llDumpList2String(messageStore, "|"));
    integer i;
    integer count = read + unread;
    if (count >11) count = 11;
    list opts = [];
    integer msgIndex = 1;
    for (i=0; i < (count*3); i+=3)
    {
        if (llList2Integer(messageStore, i+2) ==  0) opts += TXT_NEW_MSG+" "+(string)msgIndex; else opts += TXT_OLD_MSG+" "+(string)msgIndex;
        msgIndex +=1;
    }
    opts += "CLOSE";
    status = "waitMsgSelect";
    startListen();
    llDialog(llGetOwner(), "\n"+TXT_OPTION, opts, chan(llGetKey()));
    llSetTimerEvent(300);
}

showXP(integer total)
{
    debug("showXP:"+(string)total);
    llSetTexture(TEXTURE_BLANK, XP_FACE);
    string body = "width:128, height:128, Alpha:64";
    string commandList = "";  // Storage for our drawing commands
    commandList = osSetPenColor(commandList, "Black");
    commandList = osSetFontSize(commandList, 36);
    vector Extents = osGetDrawStringSize( "vector", (string)total, "Arial", 36);
    integer xpos = 64 - ((integer) Extents.x >> 1);        // Center the text horizontally
    commandList = osMovePen(commandList, xpos, 25);         // Position the text
    commandList = osDrawText(commandList, (string)total);        // Place the text
    // Do it!
    osSetDynamicTextureDataBlendFace("", "vector", commandList, body, TRUE, 2, 0, 200, XP_FACE);
}

showMsgCount()
{
    llSetTexture(TEXTURE_BLANK, MSG_FACE);
    llSetAlpha(1.0, MSG_FACE);
    integer xpos;
    integer ypos;
    string text;
    vector size;
    string body = "width:512,height:256,Alpha:64";
    string commandList = "";
    string FontName = "Arial";
    integer FontSize = 128;
    commandList = osSetFontName(commandList, FontName);
    commandList = osSetFontSize(commandList, FontSize);
    commandList += "FontProp B;";
    // Show unread message count
    commandList = osSetPenColor(commandList, "greenyellow" );
    text = (string)unread;
    size = osGetDrawStringSize("vector", text, FontName, FontSize);
    xpos = 50;
    ypos = (256 - (integer)size.y) >> 1;
    commandList = osMovePen(commandList, xpos, ypos);
    commandList = osDrawText(commandList, text);
    // Show read message count
    commandList = osSetPenColor(commandList, "salmon" );
    text = (string)read;
    size = osGetDrawStringSize("vector", text, FontName, FontSize);
    xpos = 300;
    ypos = (256 - (integer)size.y) >> 1;
    commandList = osMovePen(commandList, xpos, ypos);
    commandList = osDrawText(commandList, text);
    // Output the result
    osSetDynamicTextureDataBlendFace("", "vector", commandList, body, FALSE, 2, 0, 255, MSG_FACE);
}

showMessage(integer msgNum)
{
    integer index = msgNum*3;
    integer ourNum = msgNum+1;
    floatText("("+(string)ourNum+") " +llList2String(messageStore, index)+"\n \n \n", GREY);
    // [message, message id, read]
    if (llList2Integer(messageStore, index+2) == FALSE)
    {
        messageStore = llListReplaceList(messageStore, [TRUE], index+2, index+2);
        unread-=1;
        read +=1;
    }
    if (llGetInventoryType(msgNC) == INVENTORY_NOTECARD)
    {
        llRemoveInventory(msgNC);
        llSleep(0.1);
    }
    osMakeNotecard(msgNC, llDumpList2String(messageStore, "|"));
    showMsgCount();
    llListenRemove(listener);
    listener = -1;
    msgDialog();
}

indicatorReset()
{
    llSetAlpha(0.5, XP_FACE);
    llSetAlpha(0.5, MSG_FACE);
    llSetTexture(TEXTURE_BLANK, XP_FACE);
    llSetTexture(TEXTURE_BLANK, MSG_FACE);
}

loadStoredMsgs()
{
    messageStore = [];
    if (llGetInventoryType(msgNC) == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard(msgNC), ["|"], []);
        integer count = llGetListLength(lines);
        if (count != 0)
        {
            integer i;
            for (i=0; i < count; i=i+3)
            {
                messageStore += [llList2String(lines, i), llList2Integer(lines, i+1), llList2Integer(lines, i+2)];
            }
            debug("MSGS:" + llDumpList2String(messageStore, ","));
        }
    }
}


default
{

    attach(key id)
    {
        status = "";
        indicatorReset();
        loadStoredMsgs();
        status = "startUp";
        notified = FALSE;
        llSetTimerEvent(6);
    }

    listen(integer channel, string name, key id, string m)
    {
        debug("listen:" +m);
        if (m == TXT_CLOSE)
        {
            listenTs = 0;
            checkListen();
            showMsgCount();
        }
        else if (status == "waitMsgSelect")
        {
            integer response = (integer)llGetSubString(m, 2, -1);
            showMessage(response-1);
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        //debug("link_message:" + msg);
        list tok = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tok,0);

        if (cmd == "CMD_XP")
        {
            llSetAlpha(1.0, XP_FACE);
            showXP(llList2Integer(tok, 1));
            xpTotal = llList2Integer(tok,1);
            llSetObjectDesc((string)xpTotal + ";" + (string)llGetUnixTime());
        }
        else if (cmd == "XP_CLEAR")
        {
            indicatorReset();
        }
        else if (cmd == "CMD_DOPOLL")
        {
            status = "";
            postMessage("task=msglist&data1=" +(string)id);
        }
        else if (cmd == "CHK_MSGS")
        {
            if (num != -1) status = "waitMsgRequest";
            postMessage("task=msglist&data1=" +(string)id);
        }
        else if (cmd == "DEL_MSGS")
        {

        }
        else if (cmd == "LANG_MESSENGER")
        {
            TXT_OPTION = llList2String(tok, 1);
            TXT_CLOSE  = llList2String(tok, 2);
        }
        else if (cmd == "CMD_CHATTY")
        {
            doFX = num;
        }
        else if (cmd == "HTTP_RESPONSE")
        {
            tok = llParseStringKeepNulls(msg, ["|"], []);
            tok = llDeleteSubList(tok, 0, 0);
            cmd = llList2String(tok, 0);
            if (cmd == "msg_list")
            {
                integer i;
                list newList = [];
                read = 0;
                unread = 0;
                integer msgID;
                integer msgIndex;
                integer newMsgs = 0;
                integer count = 2+(2*(llList2Integer(tok, 1)));
                if (count > 2)
                {
                    for (i=2; i<count; i+=2)
                    {
                        // Check if we have this message already
                        msgID =  llList2Integer(tok,i+1);
                        msgIndex = llListFindList(messageStore, [msgID]);
                        if (msgIndex != -1)
                        {
                            // we already have this message so check if read
                            if (llList2Integer(messageStore, msgIndex+1) == 1)
                            {
                                // We have read it
                                newList += [llList2String(tok, i) ,msgID, TRUE];
                                read += 1;
                            }
                            else
                            {
                                newList += [llList2String(tok, i) ,msgID, FALSE];
                                newMsgs = newMsgs + 1;
                                unread += 1;
                            }
                        }
                        else
                        {
                            // new message so add to our store
                            newList += [llList2String(tok, i) ,msgID, FALSE];
                            newMsgs = newMsgs + 1;
                            unread += 1;
                        }
                    }
                    showMsgCount();
                    messageStore = [] + newList;
                    messageStore = llListSort(messageStore, 3, TRUE);
                    if ((unread >0) && (notified == FALSE))
                    {
                        if (doFX == TRUE) llPlaySound(fxSound, 0.5);
                        notified = TRUE;
                    }
                    if (status == "startup")
                    {
                        status = "";
                        llSetTimerEvent(0);
                    }
                    else if (status == "waitMsgRequest")
                    {
                        msgDialog();
                    }
                }
                else
                {
                    // No messages so clear store
                    messageStore = [];
                    llSetTexture(TEXTURE_BLANK, MSG_FACE);
                    notified = FALSE;
                }
            }
        }
    }

    timer()
    {
        if (status == "startUp")
        {
            llMessageLinked(LINK_THIS, -1, "CHK_MSGS", "");
        }
        llSetTimerEvent(0);
        postMessage("task=points&data1=" + (string)llGetOwner());
    }


}
