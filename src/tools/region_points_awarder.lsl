// HIGH VOLUME GREETER (OSSL)
// by Aine Caoimhe Feb 2015
// Version 2.4   -  Modified by Cnayl  11 February 2020

// Link messages: 0 is for gift giver to reset count, 1 is for gift give to give gift, 2 is for message recorder to take message
//
integer active = 1;  // Set to 1 for active, 0 for touch only mode

string landmark_name = "Mintor";
string notecard_name = "Quintonia";
string newscard_name = "Quintonia_News";

string newsMsg = "We are sending you a copy of the latest newsletter as a notecard so please do accept it, thankyou.";  // Message to say when handing out latest newsletter

// In the following stings, INSERT_NAME will be replaced by the avatar's name.
// Said to the avatar the FIRST time they visit the region (or if you've deleted the visitor log):
string welcomeFirstTimeMessage = "Welcome, INSERT_NAME. Thank you for visiting Mintor.\n We hope you enjoy your stay. Do look around as we have lots going on!";
// Message sent to the avatar on all subsequent visits:
string welcomeBackMessage = "Welcome back to Mintor INSERT_NAME. If you want to get the welcome menu again, just say  menu  or help  to the greeter in the welcome centre.";
// Message on welcome dialog box
string wlc_msg = "Welcome to Mintor";
// Menu items to show visitors
list menu_options1 = ["Feedback", "Subscribe", "CLOSE", "Freebies", "Join group", "Landmark", "Information", "Website"];
list menu_options2 = ["Feedback", "Un-Subscribe", "CLOSE", "Freebies", "Join group", "Landmark", "Information", "Website"];

string visitorLogNotecard="Visitor_log";    // name for the notecard to use as the visitor log (will be created if it doesn't exist)
string newsNC ="Quintonia_News";            // name for the notecard to use as the newsletter

integer includeTimes=TRUE;                  // include both date and time when logging their most recent visit

integer notifyOwner=TRUE;           // notify owner when someone is greeted
float checkTime=10.0;               // how often (in seconds) to check whether someone new has arrived in the region and also timer if using multiple animations for the NPC
integer rezNpcGreeter=TRUE;         // on region restart, rez an NPC greeter -- on script reset an existing NPC will be automatically "rescued"
vector npcSitPos=<0,0,0.75>;         // position for sit target of NPC (use Magic Sit kit to help you set these two values - one of them MUST be non-zero even if only tiny)
rotation npcSitRot=ZERO_ROTATION;   // rotation for sit target of NPC
string npcCardName="greeter_quinbot";       // name of the NPC notecard to use
string npcFirstName="Greeter";        // first name for NPC
string npcLastName="Quinbot";       // last name for NPC
string npcImage = "greeter_pic";    // image in inventory to use for the NPC profile pic
string npcDesc = "I am the greeter for this region.";   // description to put into NPC profile
// all animations found in inventory will be assumed to be for the NPC to play and you must include at least 1...if there is more than one, the NPC will cycle through them based on the checkTime timer
string animP1="*****base__stand priority 1"; // name of additional priority 1 animation that needs to be there to overcome a code bug
vector greetPos = <69, 205, 21.5>;

// # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
// main script stuff starts here
list visitorLog=[];     // lastvisit|name|UUID|subscriber|status
list regionLog=[];      // UUID|pos|name
key npc=NULL_KEY;
key owner;
key visitor;
list anims=[];
integer animIndex;
string currentAnim;
integer dlgListener=-1;
integer npcListener;
integer listenTs;
vector homePos;
integer shwDlg = FALSE;
integer newsMode;  // Set true when there is a newsletter to give to subscribers
list onoff = ["OFF", "ON"];


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (dlgListener<0)
    {
        dlgListener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen(integer force)
{
    if ((dlgListener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(dlgListener);
        dlgListener = -1;
    }
}


showDlg(integer channel)
{
    if (shwDlg == TRUE)
    {
        startListen();
        if (llList2Integer(subscriberCheck(),0) == FALSE)
        {
            llDialog(visitor, wlc_msg, menu_options1, channel);
        }
        else
        {
            llDialog(visitor, wlc_msg, menu_options2, channel);
        }
    }
    else
    {
        checkListen(1);
    }
}

saveLog()
{
    if (llGetInventoryType(visitorLogNotecard)==INVENTORY_NOTECARD)
    {
        llRemoveInventory(visitorLogNotecard);
        llSleep(0.2);   // need to delay briefly to give it time to remove the old one
    }
    // build new string to store
    string strToStore;
    integer i;
    integer l=llGetListLength(visitorLog);
    while (i<l)
    {
        strToStore+=llDumpList2String(llList2List(visitorLog,i,i+4),"|") + "\n";
        i+=5;
    }
    //store it
    osMakeNotecard(visitorLogNotecard,strToStore);
}

list subscriberCheck()   // returns list of boolean as [ subscriber, status ]
{
    integer visitorIndex = llListFindList(visitorLog,[visitor]);
    return [llList2Integer(visitorLog, visitorIndex+1), llList2Integer(visitorLog, visitorIndex+2)];

}

listSubscribers()
{
    list lines = llParseString2List(osGetNotecard(visitorLogNotecard), ["\n"], []);
    integer i;
    list subscriberList = [];
    for (i=0; i < llGetListLength(lines); i++)
    {
        list tok = llParseString2List(llList2String(lines,i), ["|"], []);
        if (llList2String(tok,1) != "")  // empty notecard
        {
            if (llList2Integer(tok, 3) == 1)
            {
                subscriberList += llStringTrim(llList2String(tok, 1), STRING_TRIM) + " - " + llStringTrim(llList2String(tok, 4), STRING_TRIM);  // name & status
            }
        }
    }
    llRegionSayTo(owner, 0, "Subscriber info - News mode is " + llList2String(onoff, newsMode) + "\n" + llDumpList2String(subscriberList, "\n"));
}

resetSubscribers()
{
    list lines = llParseString2List(osGetNotecard(visitorLogNotecard), ["\n"], []);
    list tmpLst = [];
    string tmpStr = "";
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        tmpStr = llGetSubString( llList2String(lines, i), 0, llStringLength(llList2String(lines, i))-2);
        tmpStr += "0";
        tmpLst += tmpStr + "\n";
    }
    visitorLog = tmpLst;
    saveLog();  // updatedLog
    llRegionSayTo(owner, 0, "Reset complete.");
}

welcome(key who,string name)
{
    // called when a new key is detected in the region
    // skip if this is the UUID of an NPC
    if (osIsNpc(who)) return;
    visitor = who;
    // find the index of the visitor in the visitor log
    integer visitorIndex=llListFindList(visitorLog,[who]);
    string strToSay=welcomeBackMessage;        // welcome message we're going to send - set to welcome back as default
    string timeStamp=llGetDate();
    if (includeTimes) // user wants timestamp instead so parse it into something readable
    {
        timeStamp=llGetTimestamp();
        timeStamp=llGetSubString(timeStamp,0,9)+" at "+llGetSubString(timeStamp,11,18);
    }

    if (visitorIndex==-1)
    {
        // this is a first time visitor and needs to be added to the visitor log as date|name|uuid|subscriber|status
        visitorLog=[]+visitorLog+[timeStamp,name,who,0,0];
        // and we want to send the first-time visitor message instead of the welcome back one
        strToSay=welcomeFirstTimeMessage;
        shwDlg = TRUE;
    }
    else
    {
        // repeat visitor
        visitorLog=[]+llListReplaceList(visitorLog,timeStamp,visitorIndex-2,visitorIndex-2); // this is a repeat visitor so we need to update the timestamp instead
        shwDlg = FALSE;
    }
    // sort the list
    visitorLog=llListSort(visitorLog,5,FALSE);
    // now send welcome message to the avi after parsing it to replace INSERT_NAME with the name
    while (llSubStringIndex(strToSay,"INSERT_NAME")>-1)
    {
        integer ind=llSubStringIndex(strToSay,"INSERT_NAME");
        strToSay=llDeleteSubString(strToSay,ind,ind+10);
        strToSay=llInsertString(strToSay,ind,name);
    }
    // When newsmode active, check if they are a subscriber and if they have yet to receive latest news
    if ( (newsMode == TRUE)  &  (llList2Integer(subscriberCheck(), 0) == TRUE) )
    {
        if (llList2Integer(subscriberCheck(), 1) == FALSE)
        {
            llRegionSayTo(visitor, 0, newsMsg);
            llSleep(1.0);
            llGiveInventory(visitor, newsNC);
            visitorIndex=llListFindList(visitorLog,[visitor]);
            visitorLog = []+llListReplaceList(visitorLog,"1",visitorIndex+2,visitorIndex+2); // update status setting to sent i.e.  n|1
            saveLog();
            if (notifyOwner && (who!= owner) && (llGetAgentSize(owner)!=ZERO_VECTOR)) llInstantMessage(owner ,name+" has been offered newsletter.");
        }
    }


    // if owner wants to be notified of visitors, send message (as long as it's not the owner being greeted)
    if (notifyOwner && (who!=owner) && (llGetAgentSize(owner)!=ZERO_VECTOR)) llInstantMessage(owner ,name+" has arrived in Mintor and been greeted.");
    // Only greet and show dialog if active not testing
    if (active == TRUE)
    {
        llRegionSayTo(who,0,strToSay);
        // Now show dialog box for first time visitors
        if (shwDlg == TRUE)
        {
            showDlg(chan(llGetKey()));
        }
    }
}

doNextAnim()
{
    if (npc==NULL_KEY) return;
    animIndex++;
    if (animIndex>=llGetListLength(anims)) animIndex=0;
    string nextAnim=llList2String(anims,animIndex);
    if (nextAnim!=currentAnim)
    {
        osAvatarPlayAnimation(npc,nextAnim);
        osAvatarStopAnimation(npc,currentAnim);
        currentAnim=nextAnim;
    }
}

rez_npc()
{
    npc=osNpcCreate(npcFirstName,npcLastName,homePos,npcCardName, OS_NPC_NOT_OWNED | 8);  // 8 = OS_NPC_GROUP);
    osNpcSetProfileImage(npc, npcImage);
    osNpcSetProfileAbout(npc, npcDesc);
    homePos = osNpcGetPos(npc);
    osNpcSit(npc,llGetKey(),OS_NPC_SIT_NOW);
}


StartSteam()
{
    llParticleSystem([]);
                                    // MASK FLAGS: set  to "TRUE" to enable
    integer glow = FALSE;           // Makes the particles glow
    integer bounce = FALSE;         // Make particles bounce on Z plane of objects
    integer interpColor = FALSE;    // Color - from start value to end value
    integer interpSize = FALSE;     // Size - from start value to end value
    integer wind = TRUE;            // Particles effected by wind
    integer followSource = TRUE;    // Particles follow the source
    integer followVel = TRUE;       // Particles turn to velocity direction

                                    // Choose a pattern from the following:
                                       // PSYS_SRC_PATTERN_EXPLODE
                                       // PSYS_SRC_PATTERN_DROP
                                       // PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY
                                       // PSYS_SRC_PATTERN_ANGLE_CONE
                                       // PSYS_SRC_PATTERN_ANGLE
    integer pattern = PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY;       // PSYS_SRC_PATTERN_EXPLODE;

                                    // Select a target for particles to go towards
                                    // "" for no target, "owner" will follow object owner
                                    //    and "self" will target this object
                                    //    or put the key of an object for particles to go to

     key target = visitor;
                                    // PARTICLE PARAMETERS

    float age = 5;                  // Life of each particle
    float maxSpeed = 0.05;          // Max speed each particle is spit out at
    float minSpeed = 0.05;          // Min speed each particle is spit out at
    string texture = "img";         // Texture used for particles, default used if blank
    float startAlpha = 0.8;         // Start alpha (transparency) value
    float endAlpha = 0.8;                   // End alpha (transparency) value
    vector startColor = <1,1,1>;      // Start color of particles <R,G,B>
    vector endColor = <1,1,1>;        // End color of particles <R,G,B> (if interpColor == TRUE)
    vector startSize = <0.5,0.5,0.5>;    // Start size of particles
    vector endSize = <1,1,1>;      // End size of particles (if interpSize == TRUE)
    vector push = <0.05,0.0,0.0>;           // Force pushed on particles

                                    // SYSTEM PARAMETERS

    float rate = 0.5;                       // How fast (rate) to emit particles
    float radius = 0.75;                    // Radius to emit particles for BURST pattern
    integer count = 4;                      // How many particles to emit per BURST
    float outerAngle = 3*PI;                // Outer angle for all ANGLE patterns   PI/4
    float innerAngle = 0.5;                 // Inner angle for all ANGLE patterns
    vector omega = <0,0,0>;                 // Rotation of ANGLE patterns around the source
    float life = 5;                         // Life in seconds for the system to make particles

                                    // SCRIPT VARIABLES
    integer flags = 0;

    if (glow) flags = flags | PSYS_PART_EMISSIVE_MASK;
    if (bounce) flags = flags | PSYS_PART_BOUNCE_MASK;
    if (interpColor) flags = flags | PSYS_PART_INTERP_COLOR_MASK;
    if (interpSize) flags = flags | PSYS_PART_INTERP_SCALE_MASK;
    if (wind) flags = flags | PSYS_PART_WIND_MASK;
    if (followSource) flags = flags | PSYS_PART_FOLLOW_SRC_MASK;
    if (followVel) flags = flags | PSYS_PART_FOLLOW_VELOCITY_MASK;
    if (target != "") flags = flags | PSYS_PART_TARGET_POS_MASK;

    llParticleSystem([  PSYS_PART_MAX_AGE,age,
                        PSYS_PART_FLAGS,flags,
                        PSYS_PART_START_COLOR, startColor,
                        PSYS_PART_END_COLOR, endColor,
                        PSYS_PART_START_SCALE,startSize,
                        PSYS_PART_END_SCALE,endSize,
                        PSYS_SRC_PATTERN, pattern,
                        PSYS_SRC_BURST_RATE,rate,
                        PSYS_SRC_ACCEL, push,
                        PSYS_SRC_BURST_PART_COUNT,count,
                        PSYS_SRC_BURST_RADIUS,radius,
                        PSYS_SRC_BURST_SPEED_MIN,minSpeed,
                        PSYS_SRC_BURST_SPEED_MAX,maxSpeed,
                        PSYS_SRC_TARGET_KEY,target,
                        PSYS_SRC_INNERANGLE,innerAngle,
                        PSYS_SRC_OUTERANGLE,outerAngle,
                        PSYS_SRC_OMEGA, omega,
                        PSYS_SRC_MAX_AGE, life,
                        PSYS_SRC_TEXTURE, texture,
                        PSYS_PART_START_ALPHA, startAlpha,
                        PSYS_PART_END_ALPHA, endAlpha
                            ]);
}


//state default //

default
{

    state_entry()
    {
        llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, 0,1,1,0, TWO_PI, -0.15);
        llVolumeDetect(TRUE);
        owner = llGetOwner();
        homePos = llGetPos()+<0.0,0.0,1.0>;
        npcListener = llListen(0, "", NULL_KEY,"");
        llMessageLinked(LINK_SET, 3, visitorLogNotecard, "");
        // zero the running visitor log and then read the stored notecard from memory if it exists to get previous visitors
        string logData;
        visitorLog=[];
        if (llGetInventoryType(visitorLogNotecard)==INVENTORY_NOTECARD) logData=osGetNotecard(visitorLogNotecard);
        visitorLog=llParseString2List(logData,["|","\n"],[]);
        visitorLog=llListSort(visitorLog,5,FALSE);
        // zero the in-region log as well
        regionLog=[];
        // if using NPC, see if there is one to rescue, else rez one
        if (rezNpcGreeter)
        {
            llSitTarget(npcSitPos,npcSitRot);
            key aviOnSitTarget=llAvatarOnSitTarget();
            if (aviOnSitTarget!=NULL_KEY) // someone sitting here already...if it's an NPC then "rescue" it
            {
                if (osIsNpc(aviOnSitTarget))
                {
                    npc=aviOnSitTarget;
                    osAvatarPlayAnimation(npc,animP1);
                }
                else
                {
                    llRegionSayTo(aviOnSitTarget,0,"This spot is reserved for the NPC greeter");
                    llUnSit(aviOnSitTarget);
                }
            }
            else // nobody seated so we need to rez NPC greeter
            {
                rez_npc();
                llSleep(0.25);  // annoying but necessary delay to allow NPC to register actually sitting
                osAvatarPlayAnimation(npc,animP1);
            }
            // build list of animations to play
            anims=[];
            integer a=llGetInventoryNumber(INVENTORY_ANIMATION);
            if (!a) llOwnerSay("ERROR!!!! Could not find any animations in inventory. You need to have the base P1 animation as well as at least 1 additional one for the avi to play");
            else if (a==1) llOwnerSay("WARNING!!!! With NPC greeter active I expected to find at least 1 animation other than the P1 base animation for that avi to play. Please add at least 1");
            while (--a>=0)
            {
                if (llGetInventoryName(INVENTORY_ANIMATION,a)!=animP1) anims=[]+[llGetInventoryName(INVENTORY_ANIMATION,a)]+anims;
            }
            animIndex=llGetListLength(anims);
            currentAnim="";
            doNextAnim();   // start first one
        }
        // start the timer
        llSetTimerEvent(checkTime);
    }

    on_rez(integer start)
    {
        // on first rez remove any existing visitor log
        if (llGetInventoryType(visitorLogNotecard)==INVENTORY_NOTECARD) llRemoveInventory(visitorLogNotecard);
        llResetScript();
    }

    changed (integer change)
    {
        // restart if the owner changes or any time the region is restarted
        if (change & CHANGED_OWNER)
        {
            // on owner change remove any existing visitor log
            if (llGetInventoryType(visitorLogNotecard)==INVENTORY_NOTECARD) llRemoveInventory(visitorLogNotecard);
            llResetScript();
        }
        else if (change & CHANGED_REGION_START) llResetScript();
    }

    listen(integer c, string nm, key id, string m)
    {
        if (c == 0)
        {
            llParticleSystem([]);
            if (id != npc)  // Don't reply to our talking!
            {
                string p = llStringTrim( llToLower(m), STRING_TRIM );
                // MESSAGE FOR NPC FROM VISITOR
                if (id != owner)
                {
                    // Respond to user
                    if ((p == "help" ) || (p == "menu") || (p == "hello"))
                    {
                        osNpcSay(npc, "Hello there " + llGetDisplayName(id) + ". Here is the Greeter menu for you.");
                        visitor = id;
                        shwDlg = TRUE;
                    }
                }
                else
                {
                    // respond to owner commands
                    if (p == "help")
                    {
                        llRegionSayTo(owner, 0, "You can say:\n  'menu'   'reset'   'log'   'news on'   'news off'   'subscribers'  'status'\n" );
                    }
                    else if (p == "menu")
                    {
                        visitor = id;
                        shwDlg = TRUE;
                    }
                    else if (p == "reset")
                    {
                        llMessageLinked(LINK_SET, 0, "", visitor);
                        visitor = NULL_KEY;
                        shwDlg = FALSE;
                        llRemoveInventory(visitorLogNotecard);
                        llSleep(1.0);
                        llOwnerSay("Visitor log now reset");
                        osMakeNotecard(visitorLogNotecard, []);
                        return;
                    }
                    else if (p == "log")
                    {
                        llGiveInventory(id, visitorLogNotecard);
                        shwDlg = FALSE;
                    }
                    else if (p == "news on")
                    {
                        newsMode = TRUE;
                        llRegionSayTo(owner, 0, "News mode now ON");
                    }
                    else if (p == "news off")
                    {
                        newsMode = FALSE;
                        llRegionSayTo(owner, 0, "News mode now OFF, resetting subscribers status");
                        resetSubscribers();
                    }
                    else if (p == "subscribers")
                    {
                        listSubscribers();
                    }
                    else if (p == "status")
                    {
                        llRegionSayTo(owner, 0, "Newsmode is " + llList2String(onoff, newsMode));
                    }
                }
            }
        }

        // Else assume dialog response:  CLOSE   Notecard   Join group   Landmark   Gift   Subscribe   Feedback
        if (m == "CLOSE")
        {
            checkListen(TRUE);
            return;
        }

        else if (m == "Website")
        {
            llLoadURL(visitor, "Sign up to start collecting Quintonia points!", "https://quintonia.net/register");
        }

        else if (m == "Information")
        {
            llGiveInventory(visitor, notecard_name);
        }
        else if (m == "Join group")
        {
            key groupKey=llList2Key(llGetObjectDetails(llGetKey(),[OBJECT_GROUP]),0);
            if (groupKey==NULL_KEY) llOwnerSay("Sorry, cannot send a group invite because there is no group set for this prim");
            else
            {
                //osInviteToGroup(visitor);
                llRegionSayTo(visitor, 0, "\nTo join the group, please click the link in your history window (ctrl-H)"
                +"\n secondlife:///app/group/"+groupKey+"/about");
            }
            showDlg(chan(llGetKey()));
        }
        else if (m == "Landmark")
        {
            llGiveInventory(visitor, landmark_name);
        }
        else if (m == "Freebies")
        {
            llRegionSayTo(visitor, 0, "Preparing gift package for you.");
            StartSteam();
            llMessageLinked(LINK_SET, 1, "", visitor );
        }
        else if (m == "Subscribe")
        {
            llInstantMessage(owner, "Subscription request from " + llGetDisplayName(visitor) + "|" + (string)visitor);
            llRegionSayTo(visitor, 0, "Thank you for subscribing, we will keep you up to date with what's going on in Mintor and Quintonia.");
            integer visitorIndex = llListFindList(visitorLog,[visitor]);
            visitorLog = []+llListReplaceList(visitorLog,"1",visitorIndex+1,visitorIndex+1); // update subscription setting to subscribed, not received i.e.   1|n
            saveLog();
        }
        else if (m == "Un-Subscribe")
        {
            llInstantMessage(owner, "Subscription removal request from " + llGetDisplayName(visitor) + "|" + (string)visitor);
            llRegionSayTo(visitor, 0, "Sorry to see you go - you can re-subscribe at any time.");
            integer visitorIndex = llListFindList(visitorLog,[visitor]);
            visitorLog = []+llListReplaceList(visitorLog,"0",visitorIndex+1,visitorIndex+1); // update subscription setting to un-subscribed   0|n
            saveLog();
        }
        else if (m == "Feedback")
        {
            llMessageLinked(LINK_SET, 2, "", visitor);
            if (visitor != owner)
            {
                llInstantMessage(owner, "Feedback request from " + llGetDisplayName(visitor) + "|" + (string)visitor);
            }
            else
            {
                shwDlg = FALSE;
                return;
            }
        }
        showDlg(chan(llGetKey()));
    }


    touch_start(integer num)
    {
        visitor = llDetectedKey(0);
        if (llDetectedTouchFace(0) == 5)
        {
            // Info box touched
            llGiveInventory(visitor, notecard_name);
            llGiveInventory(visitor, newscard_name);
        }
        else
        {
            if ( visitor == llGetOwner() )
            {
                if (npc!=NULL_KEY)
                {
                    osNpcRemove(npc);
                    npc=NULL_KEY;
                }
                else
                {
                    rez_npc();
                    llSleep(0.25);  // annoying but necessary delay to allow NPC to register actually sitting
                    osAvatarPlayAnimation(npc,animP1);
                    currentAnim="";
                    doNextAnim();
                }
            }
            else
            {
                checkListen(TRUE);
                startListen();
                showDlg(chan(llGetKey()));
            }
        }
    }

    timer()
    {
        checkListen(FALSE);
        // update the region log to reflect who is currently in the region. OSSL function doesn't include owner in results so also add them if present
        list oldRegionLog=regionLog;
        regionLog=osGetAvatarList();
        if (llGetAgentSize(llGetOwner())!=ZERO_VECTOR) regionLog+=[llGetOwner(),<1,2,3>,osKey2Name(llGetOwner())];   // we don't do anything with position so just give it any value
        // see if anyone new is in the updated log
        integer changes=0;
        integer checking;
        integer stop=llGetListLength(regionLog);
        while (checking<stop)
        {
            key who=llList2Key(regionLog,checking); // UUID of person to check against the old log
            if (llListFindList(oldRegionLog,[who])==-1)
            {
                changes++;
                welcome(who,llList2String(regionLog,checking+2));    // not in previous log so welcome them by passing UUID and name to UDF
            }
            checking +=3;   // stride of the regionLog list
        }
        if (changes)
        {
            saveLog();
        }
        if (npc!=NULL_KEY) doNextAnim();
        llSetTimerEvent(checkTime);
    }
}
