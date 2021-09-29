// nc_manager-plugin.lsl
//

string cardsServerURL = "https://quintonia.net/components/com_quinty/cards.php";
key     req_id2 = NULL_KEY;

postMessage(string msg, string url)
{
    req_id2 = llHTTPRequest( url, [HTTP_METHOD,"POST",HTTP_MIMETYPE,"application/x-www-form-urlencoded",HTTP_BODY_MAXLENGTH,16384], msg);
}

integer getNotecardVer(string ncName)
{
    integer noteCardVer = -1;
    if (llGetInventoryType(ncName) == INVENTORY_NOTECARD)
    {
        list ltok = llParseString2List(osGetNotecard(ncName), ["\n"], []);
        integer l;
        for (l=0; l < llGetListLength(ltok); l++)
        {
            string line = llList2String(ltok, l);
            if (llGetSubString(line, 0, 0) == "@")
            {
                noteCardVer = llList2Integer(llParseString2List(line, ["="], []), 1);
                return noteCardVer;
            }
        }
    }
    return noteCardVer;
}


default
{
    state_entry()
    {
        // postMessage("task=VER-REQ&ncname="+values_nc, cardsServerURL);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);
        debug("link_message: {" + msg + "}\ncmd: {" + cmd + "}");

        if (cmd == "XXX")
        {

        }
    }

    http_response(key request_id, integer httpstatus, list metadata, string body)
    {
        if (request_id != req_id2)
        {
           // response not for this script
        }
        else
        {
            if (httpstatus == 200)
            {
                debug("http_response: " +body);
                floatText(TXT_GETTING_INFO +"\n \n", PURPLE);
                if (status == "waitvaluesver")
                {
                    integer serverVer = (integer)llGetSubString(body, 5, -1);
                    integer ourVer = getNotecardVer(values_nc);
                    if (serverVer > ourVer)
                    {
                        postMessage("task=DUMP&ncname="+values_nc, cardsServerURL);
                        status = "waitvalues";
                    }
                }

                else
                {
                    string tmpName;
                    if (status == "waitinfo")
                    {
                        tmpName = info_nc + "_" + llGetDate();
                    }
                    else if (status == "waitrecipes")
                    {
                        tmpName = recipes_nc + "_" + llGetDate();
                    }
                    if (tmpName != "NC")
                    {
                        osMakeNotecard(tmpName,body);    // Create notecard with data from server
                        llSleep(0.5);
                        txt_off();
                        llGiveInventory(ownerID, tmpName);  // Gives the notecard to the person.
                        llRemoveInventory(tmpName);         // Now remove it as we create fresh each time
                    }
                    status = "";
                }
            }
            else
            {
                floatText(TXT_DATA_ERROR +"\n \n", RED);
            }
            txt_off();
        }
    }


}
