/*

Animal pose maker script Version 1.5   7 September 2020

INSTRUCTIONS

The easiest way is to take an existing animal out of the rezzer and then bring the two animals near, and make them face the same direction.  Unlink the root prim from the existing animal, move it under the new animal, and link the new animal with the root prim.

Next, insert this script into the new animal. Click on the animal for the menu and then click "Save Scales" to save the scales notecard.

Next set up each pose for the animal and save using the corresponding buttons.
 walkl & walkr - these are the poses used when walking
The other poses can be anything you like but correspond to:
 rest - The resting position
 down - Animal laying
 eat  - Animal eating

HINT: I find the easiest way to do this is to do the "Save Scales" and the Rest pose, then copy the animal so you have 5 identical copies. On the first animal (your master animal)copy it's location, move it to one side and move the second animal to that spot. Repeat so that each animal gets set to one pose in that same location.
When all animals are done, copy the contents of the walkl, walkr, down and eat out of each of the corresponding copies and paste into that notecard on your master animal.

After you have completed the above, on your master animal click RESET (at this point you may want to take a copy just in case...!) Now click on START to test the animal. You can let it run and also click on it to select poses.
When you're happy, remove this script from the animal.

Now insert sound files for the animal as baby and adult. They should be named baby1,baby2, and adult1,adult2, adult3, adult4 respectively.   If you animal can have different skins, add the texture files (see https://quintonia.net/forum/development/35-genetics-part-2)

Change the an_config notecard to match your animal's properties.  Make sure your animals contains any products listed in the configuration notecard such as SF Wool, SF Milk, SF Skin, SF Manure etc (they should be all set as full perms)

You can hide/show prims in animals according to these conventions:
 Prims named adult_prim are only shown in adult animals
 Prims named child_prim are only shown in child animals
 Prims named egg_prim are only shown if the animal is in Egg state
 Prims named adult_male_prim are only shown in adult male animals. Similarly for adult_female_prim
 Prims named adult_random_prim will be visible with 50% probability when the animal becomes adult(for non-standard features like horns)


Rename your animal object such as "SF Elephant" and take it into inventory
Place it inside the animal rezzer. You should be able to rez it now.


*/

// SCRIPT \\

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

integer BUILDING=0;
list rest;
list walkl;
list walkr;
list eat;
list down;
list link_scales;
integer RADIUS=10;
integer TIMER = 5;
integer tail;
vector initpos;
integer isOn=0;
integer posed=0;

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
            llOwnerSay("Pose: Rest");
            setpose(rest);
        }
        else if (rnd==1)
        {
            llOwnerSay("Pose: Down");
            setpose(down);
        }
        else if (rnd==2)
        {
            llOwnerSay("Pose: Eat");
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
                        llOwnerSay("Pose: Walk left");
                        setpose(walkl);
                    }
                    else
                    {
                        llOwnerSay("Pose: Walk right");
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
            llOwnerSay("Pose: Rest");
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
        if (!BUILDING)
        {
            rest = getnc("rest");
            down = getnc("down");
            eat = getnc("eat");
            walkl = getnc("walkl");
            walkr = getnc("walkr");
            link_scales = getnc("scales");
            llSay(0, "Touch to start/stop");
        }
        initpos = llGetPos();
        llSetText("", <1,1,1>, 1.0);
        posed = FALSE;
    }

    on_rez(integer n)
    {
        llResetScript();
    }

    touch_start(integer n)
    {
        list opts = [];
        if ((isOn == FALSE) && (posed == FALSE))
        {
            opts += "Save scales";
            opts += "Save walkr";
            opts += "Save walkl";
            opts += "Save rest";
            opts += "Save eat";
            opts += "Save down";
            opts += "START";
        }
        else
        {
            opts += "POSE walkr";
            opts += "POSE walkl";
            opts += "POSE rest";
            opts += "POSE eat";
            opts += "POSE down";
            opts += "STOP";
        }
        opts += "RESET";
        opts += "CLOSE";
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()) );
    }

    listen(integer chan, string nm, key id, string m)
    {
        if (m == "Save walkr"  || m == "Save walkl" || m == "Save rest"|| m == "Save eat"|| m == "Save down")
        {
            string nc = llGetSubString(m, 5,-1);
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);

            llRemoveInventory(nc);
            llSleep(.2);
            osMakeNotecard(nc, llDumpList2String(c, "|"));
            llSay(0, "Pose Notecard '"+nc+"' written.");
        }
        else if (m == "Save scales")
        {
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_SIZE]);

            llRemoveInventory("scales");
            llSleep(.2);
            osMakeNotecard("scales", llDumpList2String(c, "|"));
            llSay(0, "Notecard scales written. ");
        }
        else if (m == "START" || m == "STOP")
        {
            initpos=llGetPos();
            isOn= (m == "START");
            if (m == "STOP") posed = FALSE;
            llSetTimerEvent(isOn*TIMER);

            llSay(0, "Active="+(string)isOn);
            if (isOn)
            {
                posed = FALSE;
                changepose();
            }
        }
        else if (m == "RESET")
        {
            isOn = 0;
            llSetRot(ZERO_ROTATION);
            setpose(rest);
            llResetScript();
        }
        else if (m == "POSE walkr"  || m == "POSE walkl" || m == "POSE rest"|| m == "POSE eat"|| m == "POSE down")
        {
            initpos=llGetPos();
            isOn=FALSE;
            posed = TRUE;
            llSetTimerEvent(0);
            llSetRot(ZERO_ROTATION);
            if (m == "POSE rest") setpose(rest);
            else if (m == "POSE down") setpose(down);
            else if (m == "POSE eat") setpose(eat);
            else if (m == "POSE walkl") setpose(walkl);
            else if (m == "POSE walkr") setpose(walkr);
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
