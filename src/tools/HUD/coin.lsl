// messenger.lsl
//
float version = 5.0;   //  21 September 2020
//
integer DEBUGMODE = FALSE;
debug(string text)
{
    if (DEBUGMODE == TRUE) llOwnerSay("DEBUG_" + llToUpper(llGetScriptName()) + " " + text);
}

integer COIN_FACE  = 0;
integer coinTotal;

showCoins(string total, integer FACE)
{
    string sData = "";
    integer fontSize;
    sData = osSetPenColor(sData, "mistyrose");
    sData = osSetFontName(sData, "Arial");
    if ((integer)total >9999) fontSize = 26; else fontSize = 29;
    sData = osSetFontSize(sData, fontSize);
    sData += "FontProp B;";
    vector Extents = osGetDrawStringSize( "vector", total, "Arial", fontSize);
    integer xpos = 64 - ((integer) Extents.x >> 1);  // Center the text horizontally
    sData = osMovePen(sData, xpos, 43);
    sData = osDrawText(sData, total);
    // Now draw it out
    osSetDynamicTextureDataBlendFace("", "vector", sData, "width:128,height:128,Alpha:32", FALSE, 2, 0, 255, FACE);
}

indicatorReset()
{
    llSetAlpha(0.25, COIN_FACE);
    llSetTexture("quintoCoin", COIN_FACE);
}

default
{

    attach(key id)
    {
        indicatorReset();
        llSetTimerEvent(10);
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        debug("link_message:" + msg);
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        string cmd = llList2String(tk,0);

        if (cmd == "CMD_COINS")
        {
            showCoins(llList2String(tk, 1), COIN_FACE);
            coinTotal = llList2Integer(tk,1);
            llSetObjectDesc((string)coinTotal + ";" + (string)llGetUnixTime());
            llSetAlpha(0.9, COIN_FACE);
        }
        else if (cmd == "COIN_CLEAR")
        {
            indicatorReset();
        }
    }

    timer()
    {
        llSetTimerEvent(0);
        llMessageLinked(LINK_ALL_OTHERS, 0, "CMD_COIN_CHECK|*|" +(string)llGetOwner(), "");
    }

}
