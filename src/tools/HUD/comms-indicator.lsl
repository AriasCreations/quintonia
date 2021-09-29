
// comms-indicator.lsl
//  QUINTONIA FARM HUD - Comms indicator
// -------------------------------------------
// 'led' style comms indicators for HUD indicator & weblink

float version = 5.0;    // 21 September 2020

integer faceIndicator = 3;
integer faceWeb  = 1;

vector faceIndicator_off = <0.403, 0.003, 0.237>;
vector faceIndicator_on  = <0.000, 0.609, 0.306>;
vector faceWeb_off       = <0.360, 0.004, 0.488>;
vector faceWeb_on        = <0.000, 0.408, 0.000>;
vector debug_active      = <0.941, 0.071, 0.745>;
vector init_colour       = <1.000, 0.502, 0.000>;

integer webConnected = FALSE;
integer indyConnected = FALSE;

integer DEBUGMODE = FALSE;

debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

default
{
    on_rez(integer start_param)
    {
        llSetColor(init_colour, faceWeb);
        llSetColor(init_colour, faceIndicator);
    }

    state_entry()
    {
        llSetColor(faceIndicator_off, faceIndicator);
        llSetColor(faceWeb_off, faceWeb);
    }

    touch_end(integer index)
    {
        integer touched = llDetectedTouchFace(0);
        if (touched == faceWeb) llOwnerSay("Internet:"+(string)webConnected);
        else if (touched == faceIndicator) llOwnerSay("StatusHUD:"+(string)indyConnected);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " + msg + " Num: "+(string)num);
        list tk = llParseStringKeepNulls(msg, ["|", ":"], []);
        string cmd = llList2String(tk,0);

        if (cmd == "COMMS")
        {
            string ledName = llList2String(tk,1);
            integer ledState = llList2Integer(tk,2);

            if (ledName == "WEB")
            {
                webConnected = ledState;
                if (ledState == 1)
                {
                    llSetColor(faceWeb_on, faceWeb);
                }
                else
                {
                    llSetColor(faceWeb_off, faceWeb);
                }
            }
            else if (ledName == "INDICATOR")
            {
                indyConnected = ledState;
                if (ledState == 1)
                {
                    llSetColor(faceIndicator_on, faceIndicator);
                }
                else
                {
                    llSetColor(faceIndicator_off, faceIndicator);
                }
            }
        }
        else if (cmd == "STARTUP")
        {
            llSetColor(faceIndicator_off, faceIndicator);
            llSetColor(faceWeb_off, faceWeb);
            webConnected = FALSE;
            indyConnected = FALSE;

        }
        else if (cmd == "DEBUG")
        {
            DEBUGMODE = llList2Integer(tk, 1);
            if (DEBUGMODE == TRUE) llSetColor(debug_active, faceWeb); else llSetColor(<0.8, 0.8, 0.8>, faceWeb);
        }
    }
}
