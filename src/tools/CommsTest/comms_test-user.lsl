// comms_test-user.lsl
// -------------------------------------------
//  QUINTONIA COMMS TEST - Check user account
// -------------------------------------------
//
float   VERSION = 5.0;     // 6 August 2021
integer RSTATE = 1;        // RSTATE = 1 for release, 0 for beta, -1 for Release candidate
//
integer DEBUGMODE = TRUE;  // Set this if you want to force startup in debug mode
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DB_" + llToUpper(llGetScriptName()) + " " + text);
}

string TXT_MSG_A = "This avatar is linked to Quintopia.org account ending in ";
string TXT_MSG_B = "Can't find matching account";
string TXT_MSG_C = "Sorry, something went wrong on our systems - please contact us or wait a while and try again";

vector RED      = <1.000, 0.255, 0.212>;
vector YELLOW   = <1.000, 0.863, 0.000>;
vector PURPLE   = <0.694, 0.051, 0.788>;
vector WHITE    = <1.000, 1.000, 1.000>;

string URL = "";
key farmHTTP = NULL_KEY;

postMessage(string msg)
{
    debug("postMessage '"+msg +"' TO " +URL);
    if (URL != "")
    {
        farmHTTP = llHTTPRequest(URL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded"], msg);
    }
    else
    {
        llOwnerSay("URL ERROR!");
    }
}

floatText(string msg, vector colour)
{
    llMessageLinked(LINK_SET, 1 , "TEXT|" + msg , NULL_KEY);
}



// --- STATE DEFAULT -- //

default
{

    on_rez(integer n)
    {
        llResetScript();
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " +msg);
        list tok = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tok, 0);

        if (cmd == "CMD_URL")
        {
            URL = llList2String(tok, 1);
        }
        else if (cmd == "CMD_USERCHK")
        {         
            llSleep(1.0);
            // Send command to check user details
            postMessage("task=chkuser&data1=" + (string)id);
        }
    }


    http_response(key request_id, integer Status, list metadata, string body)
    {
        debug("http_response: " +body);
        if (request_id == farmHTTP)
        {
            list tok = llParseStringKeepNulls(body, ["|"], []);
            string cmd = llList2String(tok, 0);
            
            if (cmd == "REJECT")
            {
                floatText(TXT_MSG_B, YELLOW);
            }
            else if (cmd == "USERINFO")
            {
                integer foundID = llList2Integer(tok, 1);
                if (foundID >0)
                {
                    floatText(TXT_MSG_A +string(foundID) +"\nSee https://quintonia.net/profile/edit-profile", WHITE);
                }
                else
                {
                    if (foundID == -99) floatText(TXT_MSG_B +string(foundID), RED); else floatText(TXT_MSG_C +string(foundID), RED);
                }
                
            }
            else
            {
              // debug(" == "+llList2String(tok,1));
            }
        }
        else
        {
            // Response not for this script
        }
    }

}
