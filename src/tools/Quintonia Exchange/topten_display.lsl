    // ----------------------------------------
    //  QUINTONIA FARM - 'Top 10' Display board
    //  topten_display.lsl
    // ----------------------------------------

    float VERSION = 5.1;    // 20 October 2020

    integer DEBUGMODE = FALSE;
    debug(string text)
    {
        if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
    }

    // Server URL
    string webURL  = "quintonia.net/index.php?option=com_quinty&format=raw&";
    string BASEURL;

    string txt_name = "Name";
    string txt_score = "Score";
    string txt_topten = "Leaderboard";

    vector GREEN       = <0.180, 0.800, 0.251>;
    vector YELLOW      = <1.000, 0.863, 0.000>;
    vector WHITE       = <1.0, 1.0, 1.0>;

    integer quinActive;
    key farmHTTP = NULL_KEY;
    key owner;
    integer FACE = 4;
    string PASSWORD = "*";
    string MOTD;
    integer useHTTPS;


    showTopTen(list scores)
    {
        string body = "width:1024,height:1024,Alpha:0";
        string CommandList = "";  // Storage for our drawing commands
        string statusColour;
        // Draw a border
        if (quinActive == FALSE) {statusColour = "crimson";} else {statusColour = "chartreuse";}
        CommandList = osSetPenSize(CommandList, 50 );
        CommandList = osSetPenColor(CommandList, statusColour);
        CommandList = osMovePen(CommandList, 0,0);
        CommandList = osDrawRectangle(CommandList, 1020,1020);
        // Put header
        CommandList = osSetPenColor(CommandList, "green");
        CommandList = osSetFontSize(CommandList, 30);
        vector Extents = osGetDrawStringSize( "vector", txt_topten, "Arial", 30);
        integer xpos = 512 - ((integer) Extents.x >> 1);        // Center the text horizontally
        CommandList = osMovePen(CommandList, xpos, 30);         // Position the text
        CommandList = osDrawText(CommandList, txt_topten);      // Place the text
        //
        CommandList = osSetPenColor(CommandList, "oldlace");
        CommandList = osSetFontSize(CommandList, 26);
        CommandList = osMovePen(CommandList, 150,100);
        CommandList = osDrawText(CommandList, txt_name);
        CommandList = osMovePen(CommandList, 750,100);
        CommandList = osDrawText(CommandList, txt_score);
        CommandList = osSetFontSize(CommandList, 22);
        // Draw horizontal seperator line
        CommandList = osSetPenSize(CommandList, 3);
        CommandList = osDrawLine(CommandList, 60, 150, 990, 150);
        // Display table
    //    CommandList = osSetPenColor(CommandList, "black");
        integer offset = 0;
        integer i;
        for (0; i<llGetListLength(scores)-1; i+=3)
        {
            // Name
            CommandList = osMovePen(CommandList, 150, (165 + offset));
            CommandList = osDrawText(CommandList, llList2String(scores, i));
            // Score
            CommandList = osMovePen(CommandList, 760, (165 + offset));
            CommandList = osDrawText(CommandList, (string)llList2Integer(scores, i+1));
            // Icon
            CommandList = osMovePen(CommandList, 85, (162 + offset));
            CommandList = osDrawImage(CommandList, 54, 54, llList2String(scores, i+2));  // Display small logo
            offset += 62;
        }
        // Check if there is a MOTD to display
        if (MOTD != "")
        {
            // Show MOTD background box
            CommandList = osSetPenSize( CommandList, 3 );
            CommandList = osSetPenColor( CommandList, "antiquewhite" );
            CommandList = osMovePen( CommandList, 120, 800 );               // Upper left corner
            CommandList = osDrawFilledRectangle( CommandList, 800, 175 );  // Size in pixels
            // Show MOTD text
            CommandList = osSetFontSize(CommandList, 25);
            CommandList = osSetPenColor(CommandList, "olivedrab");
            CommandList = osMovePen(CommandList, 150, 825);
            CommandList = osDrawText(CommandList, MOTD);
        }
        // Put it all together and display on the prim face
        osSetDynamicTextureDataBlendFace("", "vector", CommandList, body, FALSE, 2, 0, 255, FACE);
    }

    postMessage(string msg)
    {
        debug("postMessage: " + msg +" to:"+BASEURL);
        farmHTTP = llHTTPRequest(BASEURL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded"], msg);
    }

    // --- STATE DEFAULT -- //

    default
    {

        on_rez(integer n)
        {
            llResetScript();
        }

        state_entry()
        {
            owner = llGetOwner();
            llPassTouches(1);
            if (useHTTPS == TRUE) BASEURL = "https://" +webURL; else BASEURL = "http://" +webURL;
        }

        link_message(integer sender_num, integer num, string msg, key id)
        {
            debug("link_message: " + msg);

            list tk = llParseStringKeepNulls(msg, ["|"], []);
            string cmd = llList2String(tk,0);

            if (cmd == "LANG_TOPTEN")
            {
                txt_name = llList2String(tk, 1);
                txt_score = llList2String(tk, 2);
                txt_topten = llList2String(tk, 3);
            }
            else if (cmd == "CMD_INIT")
            {
                quinActive = TRUE;
                PASSWORD = llList2String(tk, 1);
                llSetTimerEvent(1);
            }
            else if (cmd == "CMD_STOP")
            {
                quinActive = FALSE;
                llSetTimerEvent(0);
            }
            else if (cmd == "CMD_REFRESH")
            {
                // Call timer event right away to do a refresh
                llSetTimerEvent(0.1);
            }
            else if (cmd == "SETHTTPS")
            {
                useHTTPS = num;
                if (useHTTPS == TRUE) BASEURL = "https://" +webURL; else BASEURL = "http://" +webURL;
            }
            else if (cmd == "RESET")
            {
                llResetScript();
            }
        }

        timer()
        {
            if (quinActive == TRUE)
            {
                llSetTimerEvent(3500);
                postMessage("task=topten&data1=" + (string)owner);
            }
        }

        http_response(key request_id, integer Status, list metadata, string body)
        {
            debug("http_response - Status: " + Status + "\nbody: " + body);
            if (request_id == farmHTTP)
            {
                llSetColor(WHITE, 4);
                list tok = llParseStringKeepNulls(body, ["|"], []);
                string cmd = llList2String(tok, 0);

                if (cmd == "TOPTEN")
                {
                    llMessageLinked(LINK_SET, 1, "TOPTEN_OK", "");
                    MOTD = llList2String(tok, 1);
                    list results = llList2List(tok, 2, -1);
                    showTopTen(results);
                }
                else if (cmd == "TENFAIL")
                {
                    llMessageLinked(LINK_SET, 0, "TOPTEN_ERROR", "");
                    quinActive = FALSE;
                    llSetTimerEvent(0);
                }
                else
                {
                  debug(" == "+llList2String(tok,1));
                }
            }
            else
            {
                // Response not for this script
            }
        }

        dataserver( key id, string m)
        {
            debug("dataserver: " +m);
            list tk = llParseStringKeepNulls(m, ["|"], []);
            string cmd = llList2String(tk,0);
            integer i;
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
            }
            else if (cmd == "DO-UPDATE")
            {
                if (llGetOwnerKey(id) != llGetOwner())
                {
                    llMessageLinked(LINK_SET, 0, "UPDATE-FAILED", "");
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

    }
