// fishing_server-rodX.lsl
// Fishing rod rezzed from fishing server.
// Rezzed object auto-attaches as temporary if given permission
// If not attached for > 2 minutes will auto die
//
float VERSION = 3.0;        // 24 April 2020

string SUFFIX = "";

string PASSWORD="*";
integer FARM_CHANNEL = -911201;

vector dropPos = <94,174,22.5>;

integer flag = 0;
integer fish=0;
string anim ;
integer lastTs;
integer listenerFarm;
integer listener=-1;
integer listenTs;
key ownerID;
list opts = ["YES", "NO"];

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

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
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

destruct()
{
    key objectID = llGetKey();
    llWhisper(0, "Throwing any caught fish back into the water.");
    llRegionSay(FARM_CHANNEL, "ENDFISH|" + PASSWORD + "|" + objectID);
    llSleep(10);
    osDie(objectID);
}

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_ATTACH); //asks the owner's permission
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        ownerID = llGetOwner();
        listenerFarm = llListen(FARM_CHANNEL, "", "", "");
    }

    run_time_permissions(integer parm)
    {
        if(parm & PERMISSION_TRIGGER_ANIMATION) //triggers animation
        {
            fish =0;
            llSetTimerEvent(1);
            llSay(0,"Starting Fishing...");
        }
    }

    on_rez(integer st)
    {
        llResetScript();
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

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            //if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)            llStopAnimation("hold_R_handgun"); // stop if we have permission
            llResetScript(); // re-initialize with new owner
        }
    }

    timer()
    {
        checkListen();

        if (llGetAttached()>0)
        {
            float v = llWater(ZERO_VECTOR);
            vector l  = llGetPos();

            integer ts = llGetUnixTime();
            if (ts - lastTs > 1)
            {

                if (llFabs(l.z - v) < 3.)
                {
                    fish += 2;
                    llSetText("Fishing progress: "+llRound(fish)+"% \n", <1,1,1> , 1.0);
                }
                else
                {
                    llSetText("You must be near water level to keep fishing!", <1,0,0>, 1.);
                }

                if (fish >=100)
                {
                    llSensor("SF Fish Barrel", "" , SCRIPTED, 30, PI);
                    fish =0;
                }
            }
        }
        llStopAnimation("S_Auto"); //animation to play
        llStartAnimation("S_Auto"); //animation to play
        llSetTimerEvent(10);
    }


    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }

    sensor(integer n)
    {
            key id = llDetectedKey(0);
            llSay(0, "Adding fish to Barrel");
            osMessageObject(id, "FISH|"+PASSWORD+"|"+llGetKey());
            llSay(FARM_CHANNEL, "HEALTH|" +PASSWORD+"|" +(string)ownerID +"|health|20");
    }

    no_sensor()
    {

        llSay(0, "Error! SF Fish Barrel not found nearby. Throwing the fish back in the water ..");
    }

    listen(integer c, string nm, key id, string m)
    {
        if (c == FARM_CHANNEL)
        {
            list cmd = llParseStringKeepNulls(m, ["|"] , []);
            if (llList2String(cmd,1) != PASSWORD ) { llSay(0, "Bad password"); return; }
            string item = llList2String(cmd,0);

            if (item == "PING")
            {
                // if rod is not attached don't reply to PING
                if (llGetAttached()>0)
                {
                    llRegionSay(FARM_CHANNEL, "PONG|" + PASSWORD + "|" + ownerID);
                }
            }
            else if (item == "DIE")
            {
                if (llList2Key(cmd,2) == ownerID)
                {
                    if ( fish <50)
                    {
                        destruct();
                    }
                    else
                    {
                        // over 50% on fishing so ask if they really want to stop
                        startListen();
                        llDialog(ownerID, "You are more than half way to next catch, are you sure you want to stop?", opts, chan(llGetKey()));
                        llSetTimerEvent(300);
                    }
                }
            }
        }
        else if (m == "YES")
        {
            destruct();
        }
    }

}
