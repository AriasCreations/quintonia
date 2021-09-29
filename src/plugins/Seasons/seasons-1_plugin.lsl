// SEASONS MONITOR - Sinlge prim plant
//  
float version = 1.1;     // 9 January 2020

integer FARM_CHANNEL = -911201;

list setSpring =  [ <0.719, 1.000, 0.719>, 1];
list setSummer =  [ <1.0, 1.0, 1.0>, 1];
list setAutumn =  [ <0.443, 0.432, 0.323>,1]; 
list setWinter =  [ <0.0, 0.0, 0.0>, 0];

integer faceNumber = 0;

string season;

setConfig(string str)
{
    list tok = llParseString2List(str, ["="], []);
    if (llList2String(tok,0) != "")
    {
            string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
            string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
            if (cmd == "FACE") faceNumber = (integer)val;
    }
}

loadConfig()
{
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
        if (llGetSubString(llList2String(lines,i), 0, 0) !="#")
            setConfig(llList2String(lines,i));
}

default
{
   
    state_entry()
    {
        season = "";
        llListen(FARM_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == FARM_CHANNEL)
        {
            if ( message == "Spring" || message == "Summer" || message == "Autumn" || message == "Winter")
            {
                float sAlpha;
                vector sColour;
                integer doChange = FALSE;

                if ( message == "Spring")
                {
                    if (season != message)
                    {
                        season = message;
                        sColour = llList2Vector(setSpring, 0);
                        sAlpha =  llList2Float(setSpring, 1);
                        doChange = TRUE;
                    }
                }
                else if (message == "Summer")
                {
                    if (season != message)
                    {
                        season = message;
                        sColour = llList2Vector(setSummer, 0);
                        sAlpha =  llList2Float(setSummer, 1);
                        doChange = TRUE;
                    } 
                }
                else if (message == "Autumn")
                {
                    if (season != message)
                    {
                        season = message;
                        sColour = llList2Vector(setAutumn, 0);
                        sAlpha =  llList2Float(setAutumn, 1);
                        doChange = TRUE;
                    }
                }
                else if (message == "Winter")
                {
                    if (season != message)
                    {
                        season = "Winter";
                        sColour = llList2Vector(setWinter, 0);
                        sAlpha =  llList2Float(setWinter, 1);
                        doChange = TRUE;
                    }
                }
                if (doChange == TRUE)
                {
                    llSetAlpha(sAlpha, faceNumber);
                    llSetColor(sColour, faceNumber);
                }
            }
            
        }
    }

}