//
// Seasons enviromental control box
//
float version = 1.2;   //  7 January 2020

// ====== SEASONS ===========================
// Nov, Dec, Jan, Feb    Winter     11, 12, 1, 2
// Mar, Apr, May        Spring     3, 4, 5
// Jun, Jul, Aug        Summer     6, 7, 8
// Sep, Oct             Autumn     9, 10

integer FARM_CHANNEL = -911201;

string Season;
key dlgUser;
key owner;
integer auto = TRUE;

list tex_spring = ["spring1", "spring2", "rock", "mountain"];
list tex_summer = ["summer1", "summer2", "rock", "mountain"];
list tex_autumn = ["autumn1", "autumn2", "rock", "mountain"];
list tex_winter = ["winter1", "winter2", "winter3", "winter4"];

vector YELLOW   = <1.000, 0.863, 0.000>;
vector PINK     = <0.941, 0.071, 0.745>;
vector GREEN    = <0.180, 0.800, 0.251>;
vector BLUE     = <0.000, 0.455, 0.851>;
vector ORANGE   = <1.000, 0.522, 0.106>;
vector SILVER   = <0.867, 0.867, 0.867>;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}
 
integer listener=-1;
integer listenTs;

integer doTerrain;
string mode;


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 30)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

updateText()
{
    string tmp;
    if (auto == TRUE) tmp = "Auto seasons"; else tmp = "Manual seasons"; 
    llSetText("Season set: " + Season + "\n \n" + mode + "\n \n" + tmp, SILVER, 1.0);
}

string findSeason()
{
    string  date  = llGetDate();
    list    date_info = llParseString2List(date,["-"],[" "]);
    integer month = llList2Integer(date_info,1);
    string isNow;
    if(~llListFindList([3,4,5], (list)month))
    {
        // Spring
        isNow = "Spring";
    }
    else if(~llListFindList([6,7,8], (list)month)) 
    {
        // Summer
        isNow = "Summer";
    }
    else if(~llListFindList([9,10], (list)month)) 
    {
        // Autumn
        isNow = "Autumn";
    }
    else 
    {
        // Winter
        isNow = "Winter";
    }
    return isNow;
}

setSeason(string nowIs)
{
    if (nowIs != Season)
    {
        key texKey;
        integer i;

        llSetText("Season change to " + nowIs + "\n \nis now in progress for plants...", YELLOW, 1.0);
        llSetColor(BLUE, ALL_SIDES);
        llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, ALL_SIDES,1,1,0, TWO_PI, PI);
        llRegionSay(FARM_CHANNEL, nowIs);
        llSleep(3.0);
        if(doTerrain) llSetText("Season change to " + nowIs + "\n \nis now in progress for terrain...", ORANGE, 1.0);

        if(nowIs == "Spring")
        {
            llSetColor(PINK, ALL_SIDES);
            if ( doTerrain == TRUE)
            {
                for(i = 0; i < 4; ++i)
                {
                    texKey =llGetInventoryKey( llList2String(tex_spring, i) );
                    osSetTerrainTexture(i, texKey);
                }
            }
        }
        else if(nowIs == "Summer")
        {
            // Summer
            llSetColor(GREEN, ALL_SIDES);
            if ( doTerrain == TRUE)
            {
                for(i = 0; i < 4; ++i)
                {
                    texKey =llGetInventoryKey( llList2String(tex_summer, i) );
                    osSetTerrainTexture(i, texKey);
                }
            }
        }
        else if(nowIs == "Autumn")
        {
            llSetColor(ORANGE, ALL_SIDES);
             if ( doTerrain == TRUE)
             {
                 for(i = 0; i < 4; ++i)
                {
                    texKey =llGetInventoryKey( llList2String(tex_autumn, i) );
                    osSetTerrainTexture(i, texKey);
                }
            }
        }
        else 
        {
            llSetColor(SILVER, ALL_SIDES);
            if ( doTerrain == TRUE)
            {
                for(i = 0; i < 4; ++i)
                {
                    texKey =llGetInventoryKey( llList2String(tex_winter, i) );
                    osSetTerrainTexture(i, texKey);
                }
            }
        }       
        llSleep(5.0);
        Season = nowIs;
        updateText();
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
    }
}


default
{
   
    state_entry()
    {
        owner = llGetOwner();
        doTerrain = TRUE;
        mode = "Do terrain ON";
        llSetText("* READY *", YELLOW,1);
        llSetColor(BLUE, ALL_SIDES);
        llSetTimerEvent(2);
    }
    
    touch_start(integer n)
    {
        if (llDetectedKey(0) == owner)
        {
            dlgUser = llDetectedKey(0);
            list opts = [];            
            opts += "Winter";
            opts += "AUTO";
            opts += "CLOSE";
            opts += "Spring";
            opts += "Summer";
            opts += "Autumn"; 
            opts += "MODE";
            startListen();
            llDialog(dlgUser, "Mode: " + mode + "\nChoose option", opts, chan(llGetKey()));
            llSetTimerEvent(30);
        }
    }


    listen(integer c, string nm, key id, string m)
    {
        
        if (m == "CLOSE") 
        {
            return;
        }
        else if (m == "AUTO")
        {
            auto = TRUE;
            llSetText("Finding season...",PINK,1.0);
            llSleep(1);
            Season = "";
            setSeason(findSeason());
        }

        else if (m == "MODE")
        {
            if (doTerrain == TRUE)
            {
                doTerrain = FALSE;
                mode = "Do terrain OFF";
            }
            else
            {
                doTerrain = TRUE;
                mode = "Do terrain ON";
            }
            updateText();
        }

        else
        {
            auto = FALSE;
            Season = "";
            setSeason(m);
        }
    }


    timer()
    {
        llSetTimerEvent(43200);  // 12 hours
        checkListen();
        if (auto == TRUE)
        {
            Season = findSeason();
            setSeason(Season);
        }
    }
}   

