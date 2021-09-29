// quincom.lsl
//
float version = 5.1;   //  23 September 2020
//

string URL="quintonia.net/index.php?option=com_quinty&format=raw&";
string BASEURL;
integer useHTTPS;

integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

key farmHTTP = NULL_KEY;

postMessage(string msg)
{
    debug("postMessage:"+msg +"\nTO " +BASEURL);
    if (BASEURL != "")
    {
        farmHTTP = llHTTPRequest(BASEURL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded"], msg);
    }
    else
    {
        llOwnerSay("QUINCOM ERROR!");
    }
}


default
{
    state_entry()
    {
        if (useHTTPS == TRUE) BASEURL = "https://"+URL; else BASEURL = "http://"+URL;
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk,0);

        if ( (cmd == "CMD_POST") || (cmd == "SETHTTPS")) debug("link_message:" + msg);

        if (cmd == "CMD_POST")
        {
            postMessage(llList2String(tk,1));
        }
        else if (cmd == "SETHTTPS")
        {
            if (num == 1) BASEURL = "https://"+URL; else BASEURL = "http://"+URL;
        }
    }

    http_response(key request_id, integer Status, list metadata, string body)
    {
        debug("http:_response:" + body);
        if (request_id == farmHTTP)
        {
            llMessageLinked(LINK_SET, 1, "HTTP_RESPONSE|"+body, "");
        }
    }

}

for (start; condition; step)
{

}
