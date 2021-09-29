// Version 1.1  4 March 2020
// Satyr Farm NPC controller - this is worn by the NPC farmer

key controllerKey = NULL_KEY;
string lookingFor;

integer RADIUS = 90;
string sense;
list dialogOpts;
string dialogTitle;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

list objProps(key id)
{
    return llParseString2List( llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0),  [";"], []);
}


integer listener=-1;
integer listenTs;

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


list decodeList(list tokens)
{
    integer i;
    list out =[];
    for (i=0; i < llGetListLength(tokens); i+=2)
    {
        string tp = llList2String(tokens, i);
        if (tp =="I") out += llList2Integer(tokens, i+1);
        else if (tp =="V") out += llList2Vector(tokens, i+1);
        else if (tp =="R") out += llList2Rot(tokens, i+1);
        else if (tp =="K") out += llList2Key(tokens, i+1);
        else if (tp =="F") out += llList2Float(tokens, i+1);
        else  out += llList2String(tokens, i+1);
    }
    return out;
}

integer chatListener = -1;

stopChatListen()
{
    if (chatListener != -1) llListenRemove(chatListener);
    chatListener = -1;
}

string anim = "";


default
{
    dataserver(key kk, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        string cmd = llList2Key(tk,0);

        if (cmd == "CONTROLLERKEY")
        {
            controllerKey = llList2Key(tk,1);
            llOwnerSay("Master's key="+(string)controllerKey);
            // osMessageObject(controllerKey,"KEYS|"+ (string)llGetKey()+"|"+llGetOwner() );
        }
        else if (cmd == "SETRADIUS")
        {
            RADIUS = llList2Integer(tk,1);
            llSay(0, "Radius="+(string)RADIUS);
        }
        else if (cmd == "STOPLISTENCHAT")
            stopChatListen();
        else if (cmd == "LISTENCHAT")
        {
            stopChatListen();
            chatListener = llListen(0, "", "", "");
        }
        else if (cmd == "LISTENCHATREGEX")
        {
            stopChatListen();
            string regex = llGetSubString(m, 16,-1);
            listener = osListenRegex(0, "", "", regex, OS_LISTEN_REGEX_MESSAGE);
        }
        else if (cmd == "SETTEXT")
        {
            llSetText( llList2String(tk, 1), llList2Vector(tk, 2), llList2Float(tk, 3) );
        }
        else if (cmd == "TRIGGERSOUND")
        {
            llTriggerSound( llList2Key(tk, 1), llList2Float(tk, 2) );
        }
        else if (cmd == "ANIM")
        {
            llStopAnimation(anim);
            anim = llList2Key(tk, 1);
            llStartAnimation( anim );
        }
        else if (cmd  == "SENSOR")
        {
            sense = "";
            lookingFor = llList2Key(tk, 1);
            float distance = llList2Float(tk, 2);
            float arc = llList2Float(tk, 3);
            llSensor(lookingFor, "", SCRIPTED, distance, arc);
        }
        else if (cmd  == "STOPPARTICLESYSTEM")
        {
               llParticleSystem( [] );
        }
        else if (cmd  == "PARTICLESYSTEM")
        {
            integer i;
            list out = decodeList(llList2List(tk, 1, -1));
            llParticleSystem( out );
        }
        else if (cmd  == "SETPRIMITIVEPARAMS")
        {
            integer i;
            list out = decodeList(llList2List(tk, 1, -1));
            llSetPrimitiveParams( out );
        }
        else if (cmd == "SETDIALOGOPTS")
        {
            dialogTitle = llList2String(tk, 1);
            dialogOpts  = llParseString2List(llList2String(tk, 2), [","], []) ;
        }
    }

    state_entry()
    {
        llParticleSystem([]);
        llSetText("",<1,1,1>,1.0);
        llSensor("SF NPC Controller", "", SCRIPTED, 5, PI);
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    sensor(integer n)
    {
        integer i;
        string s;
        if (controllerKey == NULL_KEY)
        {
            if (llDetectedName(0) == "SF NPC Controller")
            {
                osMessageObject(llDetectedKey(0), "LISTENERKEY|"+(string)llGetKey()+"|"+(string)llGetOwner());
            }
            return;
        }
        else
        {
            s = "SENSOR";
            for (i=0;i < n; i++) s += "|"+ (string)llDetectedKey(i);
            osMessageObject(controllerKey, s);
        }
    }

    touch_start(integer n)
    {
        if (llGetListLength(dialogOpts)>0)
        {
            startListen();
            llSetTimerEvent(300);
            llDialog(llDetectedKey(0), dialogTitle, dialogOpts, chan(llGetKey()));
        }
    }

    listen(integer c, string nm, key id, string m)
    {
        if (controllerKey != NULL_KEY)
            osMessageObject(controllerKey, "DIALOGCMD|"+(string)id+"|"+m);
    }

    no_sensor()
    {
        if (controllerKey != NULL_KEY)
            osMessageObject(controllerKey,  "NOSENSE");
    }

    timer()
    {
        checkListen();
        if (listener <0)
            llSetTimerEvent(0);
    }
}
