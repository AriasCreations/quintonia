// -------------------------------------------
//  QUINTONIA FARM - Recent activity display
//  activity_display.lsl
// -------------------------------------------

float VERSION = 5.1;    // 20 October 2020

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + llToUpper(llGetScriptName()) + " " + text);
}

// Server URL
string webURL  = "quintonia.net/index.php?option=com_quinty&format=raw&";
string BASEURL;

string txt_heading = "Your Recent Activity";
string txt_activity = "Activity";
string txt_details = "Details";
string txt_score = "Points";

vector GREEN       = <0.180, 0.800, 0.251>;
vector YELLOW      = <1.000, 0.863, 0.000>;
vector WHITE       = <1.0, 1.0, 1.0>;

key farmHTTP = NULL_KEY;
key owner;
key toucher;
integer FACE = 4;
string rank;
string PASSWORD = "*";
integer useHTTPS;

showActivity(list activity)
{
    string body = "width:1024,height:1024,Alpha:0";
    string CommandList = "";  // Storage for our drawing commands
    string statusColour;
    string tmpStr;
    // Draw a border
    CommandList = osSetPenSize(CommandList, 20 );
    CommandList = osSetPenColor(CommandList, "chartreuse");
    CommandList = osMovePen(CommandList, 1,1);
    CommandList = osDrawRectangle(CommandList, 1020,1020);
    // Put header
    CommandList = osSetPenColor(CommandList, "green");
    CommandList = osSetFontSize(CommandList, 30);
    vector Extents = osGetDrawStringSize( "vector", txt_heading, "Arial", 30);
    integer xpos = 512 - ((integer) Extents.x >> 1);        // Center the text horizontally
    CommandList = osMovePen(CommandList, xpos, 30);         // Position the text
    CommandList = osDrawText(CommandList, txt_heading);      // Place the text
    // Put column names
    CommandList = osSetPenColor(CommandList, "oldlace");
    CommandList = osSetFontSize(CommandList, 24);
    CommandList = osMovePen(CommandList, 75,100);
    CommandList = osDrawText(CommandList, txt_activity);
    CommandList = osMovePen(CommandList, 260,100);
    CommandList = osDrawText(CommandList, txt_details);
    CommandList = osMovePen(CommandList, 850,100);
    CommandList = osDrawText(CommandList, txt_score);
    // Draw horizontal seperator line
    CommandList = osSetPenSize(CommandList, 3);
    CommandList = osDrawLine(CommandList, 60, 150, 990, 150);
    // Display table
    integer offset = 0;
    integer i;
    for (0; i<llGetListLength(activity)-1; i+=3)
    {
        //   1.00|Thank You XP|Received Thank You From: Shadows Myst
        // Points  Rule  Ref
        // Rule
        CommandList = osMovePen(CommandList, 70, (165 + offset));
        CommandList = osDrawText(CommandList, llGetSubString(llList2String(activity, i+1),0, 10));
        // Ref
        CommandList = osMovePen(CommandList, 260, (165 + offset));
        // <a rel="nofollow" href="/">Some text</a>
        tmpStr = llList2String(activity, i+2);
        if (llSubStringIndex(tmpStr, "<a rel=") != -1) tmpStr = llGetSubString(tmpStr, 27, -5);
        CommandList = osDrawText(CommandList, llGetSubString(tmpStr, 0, 30));
        // Points
        CommandList = osMovePen(CommandList, 850, (165 + offset));
        CommandList = osDrawText(CommandList, llGetSubString(llList2String(activity, i),0, 28));
        offset += 62;
    }
    // Show their ranking info
    CommandList = osSetFontSize(CommandList, 30);
    CommandList = osSetPenColor(CommandList, "green");
    CommandList = osMovePen(CommandList, 75, 925);
    CommandList = osDrawText(CommandList, rank);
    // Put it all together and display on the prim face
    osSetDynamicTextureDataBlendFace("", "vector", CommandList, body, FALSE, 2, 0, 255, FACE);
    llSetColor(WHITE, FACE);
    llSetTimerEvent(45);
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

    timer()
    {
        llMessageLinked(LINK_SET, 1, "CMD_REFRESH", "");
        llSetTimerEvent(0);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg +"  Num="+(string)num);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk,0);

        if (cmd == "LANG_ACTIVITY")
        {
            txt_heading = llList2String(tk, 1);
            txt_activity = llList2String(tk, 2);
            txt_details = llList2String(tk, 3);
            txt_score = llList2String(tk, 4);
        }
        else if (cmd == "CMD_INIT")
        {
            PASSWORD = llList2String(tk, 1);
        }
        else if (cmd == "CMD_CLEAR")
        {
            llSetTexture(TEXTURE_BLANK, FACE);
            llSetColor(GREEN, FACE);
        }
        else if (cmd == "CMD_SHOW_ACTIVITY")
        {
            rank = llList2String(tk,1);
            toucher = id;
            postMessage("task=recentActivity&data1=" + (string)id);
        }
        else if (cmd == "SETHTTPS")
        {
            useHTTPS = num;
            if (useHTTPS == 1) BASEURL = "https://" +webURL; else BASEURL = "http://" +webURL;
        }
        else if (cmd == "RESET")
        {
            llResetScript();
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

            if (cmd == "ACTIVITY")
            {
                llMessageLinked(LINK_SET, 1, "ACTIVITY_OK", "");
                list results = llList2List(tok, 1, -1);
                showActivity(results);
            }
            else if (cmd == "ACTIVITYFAIL")
            {
                llMessageLinked(LINK_SET, 0, "ACTIVITY_ERROR", "");
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
