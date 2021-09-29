// comms_test-main.lsl
// -----------------------------------------
//  QUINTONIA COMMS TEST - Main code
// -----------------------------------------
//
float   VERSION = 5.0;    // 6 August 2021
integer RSTATE = 1;       // RSTATE = 1 for release, 0 for beta, -1 for Release candidate
//
integer DEBUGMODE = TRUE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG:" + text);
}
//
string  BASEURL   = "quintonia.net";
string  ULR_comms = "/index.php?option=com_quinty&format=raw&";
string  URL_testA = "/components/com_quinty/qtest.php";

string  test_result_A = "QUIN-CONTABO";
integer test_count = 1;
string  testingURL;

key     req_id2 = NULL_KEY;
key     userKey;

string  status = "";
string  results = "";

vector  PURPLE = <0.694, 0.051, 0.788>;
vector  RED = <1.000, 0.255, 0.212>;
vector  WHITE = <1.0, 1.0, 1.0>;


postMessage(string msg, string URL)
{
    debug("postMessage '"+msg +"' TO " +URL);
    if (URL != "")
    {
        req_id2 = llHTTPRequest(URL, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded"], msg);
    }
    else
    {
        llOwnerSay("URL ERROR!");
    }
}

floatText(string msg, vector colour)
{
    llSetText(msg+"\n \n \n \n \n", colour, 1);
    llOwnerSay("================\n" +msg +"\n================\n");
}


default
{
    on_rez( integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        floatText("Click to start testing", <0.8,1.0,0.8>);
    }

    touch_start( integer num_detected )
    {
        userKey = llDetectedKey(0);
        results = "";
        testingURL = "http://" + BASEURL + URL_testA;
        status = "test_A1";
        floatText("Running tests...", PURPLE);
        postMessage("response=" + userKey, testingURL);
    }   

    http_response(key request_id, integer httpstatus, list metadata, string body)
    {
        if (request_id != req_id2)
        {
           // response not for this script
        }
        else
        {
            string tmpName;
            #
            if (httpstatus == 200)
            {
                debug("http_response: " +body + "\nTest:" + (string)test_count + " Results:"+results + "\nStatus="+status);
                list tok = [];
                if (status == "test_A1")
                {
                    results += ("Test 1 (http url) - ");
                    tmpName = llGetSubString(body, 0, llStringLength(test_result_A)-1);
                    if (tmpName == test_result_A) results += ("PASS"); else results += ("FAIL");
                    results += "\n";
                    testingURL = "https://" + BASEURL + URL_testA;
                    status = "test_A2";
                    postMessage("response=" + userKey, testingURL);
                }
                else if (status == "test_A2")
                {
                    results += ("Test 2 (https url) - ");
                    tmpName = llGetSubString(body, 0, llStringLength(test_result_A)-1);
                    if (tmpName == test_result_A) results += ("PASS"); else results += ("FAIL");
                    results += "\n";
                    testingURL = "http://" + BASEURL + ULR_comms;
                    status = "test_B1";
                    // Check PHP coms is okay with http 
                    postMessage("task=activq327&data1=1", testingURL);
                }
                else if (status == "test_B1")
                {
                    results += ("Test 3 (http comms) - ");
                    tok = llParseStringKeepNulls(body, ["|"], []);
                    tmpName = llList2String(tok, 0);
                    if (tmpName == "2017053016xR") results += ("PASS"); else results += ("FAIL");
                    results += "\n";
                    testingURL = "https://" + BASEURL + ULR_comms;
                    status = "test_B2";
                    // Check PHP coms is okay with https
                    postMessage("task=activq327&data1=1", testingURL);
                    
                }
                else if (status == "test_B2")
                {
                    results += ("Test 4 (https comms) - ");
                    tok = llParseStringKeepNulls(body, ["|"], []);
                    tmpName = llList2String(tok, 0);
                    if (tmpName == "2017053016xR") results += ("PASS"); else results += ("FAIL");
                    results += "\n";
                    testingURL = "https://" + BASEURL + ULR_comms;
                    status = "test_C1";
                    llMessageLinked(LINK_THIS, 1, "CMD_URL|"+testingURL, userKey);
                    llMessageLinked(LINK_THIS, 1, "CMD_USERCHK|"+(string)userKey, userKey);

                }
            }
            else
            {
                tmpName = "ERROR: ";
                if (httpstatus == 499) tmpName += "Timeout"; else tmpName += "Code=" + (string)httpstatus;
                floatText(tmpName, RED);
            }
        }
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message: " +msg);
        list tok = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tok, 0);

        if (cmd == "TEXT")
        {
            results += "\n"+llList2String(tok, 1);
            floatText(results, WHITE);
            status = "DONE";
        }
    }

}

