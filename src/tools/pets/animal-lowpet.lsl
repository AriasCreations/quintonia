// animal-lowpet.lsl
// Version 1.0   25 September 2020
//

list rest;
list walkl;
list walkr;
list eat;
list down;
list link_scales;
integer RADIUS = 10;
integer TIMER = 5;
vector initpos;
integer isOn = FALSE;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
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

setpose(list pose)
{
    integer idx=0;
    integer i;
    float scale = 1.;
    for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, (i-1)*2-2)*scale, PRIM_ROT_LOCAL, llList2Rot(pose, (i-1)*2-1), PRIM_SIZE, llList2Vector(link_scales, i-2)*scale]);
    }
}

changepose()
{
        integer i;
        integer rnd = (integer)llFrand(5);
        if (rnd==0)
        {
            setpose(rest);
        }
        else if (rnd==1)
        {
            setpose(down);
        }
        else if (rnd==2)
        {
            setpose(eat);
        }
        else
        {
            float rz = .3-llFrand(.6);
            for (i=0; i < 6; i++)
            {
                vector cp = llGetPos();
                vector v = cp + <.4, 0, 0>*(llGetRot()*llEuler2Rot(<0,0,rz>));
                v.z = initpos.z;

                if ( llVecDist(v, initpos)< RADIUS)
                {
                    if (i%2==0)
                    {
                        setpose(walkl);
                    }
                    else
                    {
                        setpose(walkr);
                    }
                    llSetPrimitiveParams([PRIM_POSITION, v, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,rz>) ]);
                    llSleep(0.4);
                }
                else
                {
                    llSetPrimitiveParams([PRIM_POSITION, cp, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,PI/2>) ]);
                }
            }
            setpose(rest);
        }

}

list getnc(string name)
{
    list lst = llParseString2List(osGetNotecard(name), ["|"], []);
    return lst;
}


default
{

    state_entry()
    {
        rest = getnc("rest");
        down = getnc("down");
        eat = getnc("eat");
        walkl = getnc("walkl");
        walkr = getnc("walkr");
        link_scales = getnc("scales");
        llOwnerSay("Touch to start/stop");
        initpos = llGetPos();
        list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
        llSetText(llList2String(desc, 10), <0.224, 0.800, 0.800>, 1.0);
    }

    touch_start(integer n)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            list opts = [];
            if (isOn == FALSE) opts = ["START", "HOME", "CLOSE"]; else opts = ["STOP", "HOME", "CLOSE"];
            startListen();
            llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()) );
        }
    }

    listen(integer chan, string nm, key id, string m)
    {
        if (m == "START" || m == "STOP")
        {
            initpos=llGetPos();
            isOn= (m == "START");
            llSetTimerEvent(isOn*TIMER);

            llSay(0, "Active="+(string)isOn);
            if (isOn)
            {
                changepose();
            }
        }
        else if (m == "HOME")
        {
            llSetRot(ZERO_ROTATION);
            setpose(rest);
            initpos = llGetPos();
        }
    }

    timer()
    {
        if (llFrand(1)<.3)
            llTriggerSound(llGetInventoryName(INVENTORY_SOUND,  (integer)llFrand(llGetInventoryNumber(INVENTORY_SOUND))), 1.0);
        changepose();
        checkListen();
    }
}
