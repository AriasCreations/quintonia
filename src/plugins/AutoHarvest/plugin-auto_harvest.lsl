// autoHarvest_plugin.lsl

// This is a PlugIn that works with the 'plant'lsl' script.
// It automatically harvests products when they are ripe and then re-plants them.
//
// Version 4.0     13 May 2020

string TXT_AUTO_HARVEST = "AutoHarvest";
string TXT_AUTOHARVESTING_OFF="Auto harvesting is Off";
string TXT_AUTOHARVESTING_ON="Auto harvesting is On";

string languageCode = "en-GB";          //  LANG=en-GB
string SUFFIX = "P1";

integer autoHarvest;

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
                        if (cmd == "TXT_AUTO_HARVEST")  TXT_AUTO_HARVEST = val;
                    else if (cmd == "TXT_AUTOHARVESTING_OFF") TXT_AUTOHARVESTING_OFF = val;
                    else if (cmd == "TXT_AUTOHARVESTING_ON") TXT_AUTOHARVESTING_ON = val;
                }
            }
        }
    }
}

doReset()
{
    loadLanguage(languageCode);
    // Add our menu options
    if (autoHarvest)
    {
        llMessageLinked(LINK_THIS, 1, "ADD_MENU_OPTION|-"+TXT_AUTO_HARVEST, NULL_KEY);
        llMessageLinked(LINK_THIS, 1, "ADD_STATUS_OPTION|"+TXT_AUTOHARVESTING_ON, NULL_KEY);
    }
    else
    {
        llMessageLinked(LINK_THIS, 1, "ADD_MENU_OPTION|+"+TXT_AUTO_HARVEST, NULL_KEY);
        llMessageLinked(LINK_THIS, 1, "ADD_STATUS_OPTION|"+TXT_AUTOHARVESTING_OFF, NULL_KEY);
    }
}


default
{
    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "STATUS")
        {
            string status = llList2String(tok,1);
            if (status == "Ripe")
            {
                if (autoHarvest) // If autoharvest is on, send message to harvest
                {
                    integer TIME = 300;
                    integer found = llListFindList(tok, ["LIFETIME"]) + 1;
                    if (found)
                    {
                        TIME = llList2Integer(tok, found) / 3;
                    }
                    llMessageLinked(LINK_THIS, 1, "HARVEST", NULL_KEY);
                    llSleep(1.0);
                    llMessageLinked(LINK_THIS, 1, "SETSTATUS|New|" + (string)TIME, NULL_KEY);
                }
            }
        }
        else if (cmd == "RESET") // Main script reset
        {
            doReset();
        }

        else if (cmd == "SET-LANG")
        {
            // Remove current language items
            llMessageLinked(LINK_THIS, 1, "REM_MENU_OPTION|+"+TXT_AUTO_HARVEST, NULL_KEY);
            llMessageLinked(LINK_THIS, 1, "REM_STATUS_OPTION|"+TXT_AUTOHARVESTING_OFF, NULL_KEY);
            // Now load and set up new language items
            languageCode = llList2String(tok, 1);
            doReset();
        }

        else if (cmd == "MENU_OPTION")
        {
            string option = llList2String(tok, 1);
            if (option == "+"+TXT_AUTO_HARVEST)
            {
                autoHarvest = TRUE;
                llMessageLinked(LINK_THIS, 1, "REM_MENU_OPTION|+"+TXT_AUTO_HARVEST, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "ADD_MENU_OPTION|-"+TXT_AUTO_HARVEST, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "REM_STATUS_OPTION|"+TXT_AUTOHARVESTING_OFF, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "ADD_STATUS_OPTION|"+TXT_AUTOHARVESTING_ON, NULL_KEY);
                llRegionSayTo(id, 0, TXT_AUTOHARVESTING_ON);
            }
            else if (option == "-"+TXT_AUTO_HARVEST)
            {
                autoHarvest = FALSE;
                llMessageLinked(LINK_THIS, 1, "REM_MENU_OPTION|-"+TXT_AUTO_HARVEST, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "ADD_MENU_OPTION|+"+TXT_AUTO_HARVEST, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "REM_STATUS_OPTION|"+TXT_AUTOHARVESTING_ON, NULL_KEY);
                llMessageLinked(LINK_THIS, 1, "ADD_STATUS_OPTION|"+TXT_AUTOHARVESTING_OFF, NULL_KEY);
                llRegionSayTo(id, 0, TXT_AUTOHARVESTING_OFF);
            }
        }
    }
}
