// fishing_rod.lsl
// Fishing rod rezzed from fishing giver.
// Rezzed object auto-attaches as temporary if given permission
// If not attached for > 2 minutes will auto die
//
float VERSION = 4.0;        // BETA 27 April 2020

// Multilingual support
string languageCode = "en-GB";
//
string TXT_FISH_START = "Starting Fishing...";
string TXT_PROGRESS = "Fishing progress";
string TXT_ADD_FISH = "Adding fish to Barrel";
string TXT_NO_STORAGE = "Error! Fish store not found nearby. Throwing fish back into the water...";
string TXT_WRONG_PLACE_BEACON = "You must be near a fishing beacon to keep fishing!";
string TXT_WRONG_PLACE_WATER = "You must be near water to keep fishing!";
//
string SUFFIX = "F3";

// Can be changed via config notecard in fishing rod rezzer
string SF_FISH_STORE = "SF Fish Barrel";
integer forceWater = TRUE;
integer forceDetach = FALSE;

string PASSWORD="*";
integer FARM_CHANNEL = -911201;

integer flag = 0;
integer fish = 0;
string anim;
string status;
integer lastTs;
integer lifeTs;
key avatarID;
key beacon = NULL_KEY;
vector beaconPos = ZERO_VECTOR;

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
                         if (cmd == "TXT_FISH_START")            TXT_FISH_START = val;
                    else if (cmd == "TXT_PROGRESS")              TXT_PROGRESS = val;
                    else if (cmd == "TXT_ADD_FISH")              TXT_ADD_FISH = val;
                    else if (cmd == "TXT_NO_STORAGE")            TXT_NO_STORAGE = val;
                    else if (cmd == "TXT_WRONG_PLACE_BEACON")    TXT_WRONG_PLACE_BEACON = val;
                    else if (cmd == "TXT_WRONG_PLACE_WATER")    TXT_WRONG_PLACE_WATER = val;
                }
            }
        }
    }
}


default
{

    on_rez(integer st)
    {
        llSetText("",ZERO_VECTOR,0);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        lifeTs = llGetUnixTime();
        fish = 1;
        loadLanguage(languageCode);
        llSetTimerEvent(120);
    }

    run_time_permissions(integer parm)
    {
        if (parm & PERMISSION_ATTACH)
        {
            llAttachToAvatarTemp(ATTACH_LHAND);
            //rotate 90
            vector xyz_angles = <270,0,90>; // This is to define a 90 degree change
            vector angles_in_radians = xyz_angles*DEG_TO_RAD; // Change to Radians
            rotation rot_xyzq = llEuler2Rot(angles_in_radians); // Change to a Rotation
            llSetRot(llGetRot()*rot_xyzq); //Do the Rotation..
            avatarID = llGetOwner();
            fish =0;
            llRegionSay(FARM_CHANNEL, "FISHROD|" +PASSWORD +"|" +(string)avatarID);
            llSetTimerEvent(1);
            llRegionSayTo(avatarID, 0, TXT_FISH_START);
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY)
        {
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                llStopAnimation("S_Auto"); // stop if we have permission
        }
        else
        {
            fish =0;
        }
    }

    timer()
    {
        if (status == "DIE")
        {
            llDetachFromAvatar();
            llSleep(0.2);
            if (forceDetach == TRUE) osForceDetachFromAvatar();
        }

        integer ts = llGetUnixTime();
        if (llGetAttached()>0)
        {
            vector ourPos  = llGetRootPosition();
            integer fishOK = TRUE;
            // Check if near water
            if (forceWater == TRUE)
            {
                float water = llWater(ZERO_VECTOR);
                if (llFabs(ourPos.z - water) > 2.0) fishOK = FALSE;
            }
            else
            {
                // Check if near fishing beacon
                float offset = llVecDist(beaconPos, ourPos);
                if (offset > 3.0) fishOK = FALSE;
                if (beacon == NULL_KEY) fishOK = FALSE;
            }

            if (ts - lastTs > 1)
            {
                if (fishOK == TRUE)
                {
                    fish += 2;
                    llSetText(TXT_PROGRESS +": "+llRound(fish)+"% \n", <1,1,1> , 1.0);
                }
                else
                {
                    if (forceWater == TRUE) llSetText(TXT_WRONG_PLACE_WATER, <1,0,0>, 1.); else llSetText(TXT_WRONG_PLACE_BEACON, <1,0,0>, 1.);
                }

                if (fish >=100)
                {
                    llSensor(SF_FISH_STORE, "" , SCRIPTED, 30, PI);
                    status = "waitStore";
                    fish =0;
                }
            }
        }
        else
        {
            if (ts - lifeTs > 120)
            {
                // Not attached and 2 minutes passed so assume not being used
                llDie();
            }
        }
        llStopAnimation("S_Auto"); //animation to play
        llStartAnimation("S_Auto"); //animation to play
        lastTs = ts;
        llSetTimerEvent(10);
    }

    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }

    sensor(integer n)
    {
        if (status == "waitStore")
        {
            key id = llDetectedKey(0);
            llRegionSayTo(avatarID, 0, TXT_ADD_FISH);
            osMessageObject(id, "FISH|"+PASSWORD+"|"+llGetKey());
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)avatarID +"|health|20");
            llSleep(0.25);
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)avatarID +"|energy|2");
            status = "";
        }
    }

    no_sensor()
    {
        if (status == "waitStore")
        {
            llRegionSayTo(avatarID, 0, TXT_NO_STORAGE);
            status = "";
        }
    }

    dataserver(key query_id, string msg)
    {
        list tk = llParseStringKeepNulls(msg, ["|"], []);
        if (llList2String(tk, 1) != PASSWORD) return;

        string cmd = llList2String(tk, 0);
        if (cmd == "INIT")
        {
            // INIT|PASSWORD|avatarUUID|beaconKey|FISH_STORE|forceWater|forceDetach|languageCode
            avatarID = llList2Key(tk,2);
            beacon = llList2Key(tk,3);
            SF_FISH_STORE = llList2String(tk,4);
            forceWater = llList2Integer(tk,5);
            forceDetach = llList2Integer(tk,6);
            languageCode = llList2String(tk,7);
            loadLanguage(languageCode);
            list beaconInfo = llGetObjectDetails(beacon, [OBJECT_POS]);
            beaconPos = llList2Vector(beaconInfo, 0);
            llRequestPermissions(avatarID, PERMISSION_TRIGGER_ANIMATION | PERMISSION_ATTACH); //asks the owner's permission
        }
        else if (cmd == "LANGUAGE")
        {
            languageCode = llList2String(tk, 2);
            loadLanguage(languageCode);
            llSetTimerEvent(0.1);
        }
        else if (cmd == "FISHEND")
        {
            llSetTimerEvent(4);
            status = "DIE";
            llDetachFromAvatar();
        }

    }

}
