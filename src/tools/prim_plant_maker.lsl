// prim_plant_maker.lsl
// Ver 1.0  24 May 2020
// Place this script in you prim based plant - it will disable the plant script and set all prims to no transparency.
// Touch plant for menu - adjust to get the stating (smallest) size then select SET to set this save then SAVE to create the scales notecard
// When done select DELETE to remove this script and re-enable the plant script

float DialogTimeout = 180; // how many seconds before removing the listener
integer handle = 0;
integer menuChan;

list  link_scales = [];
list  link_num = [];
float max_scale;
float min_scale;
float cur_scale = 1.0;
integer ncSaved = FALSE;

makeMenu()
{
    if (!handle)
    {
        menuChan = 500000 + (integer)llFrand(500000);
        handle = llListen(menuChan, "", llGetOwner(), "");
    }
    llSetTimerEvent(DialogTimeout);
    llDialog(llGetOwner(), "Max scale: " + (string)max_scale + "\nMin scale: " + (string)min_scale
        + "\n\nCurrent scale: "+ (string)cur_scale,
        ["SET", "SAVE", "DELETE", "-0.05", "-0.10", "-0.25", "+0.05", "+0.10", "+0.25", "RESTORE", "CLOSE"],
        menuChan);
}

scanLinkset()
{
    link_scales = [];
    link_num = [];
    integer link_qty = llGetNumberOfPrims();
    integer link_idx;
    list params;
    list primNames;
    for (link_idx = 0; link_idx < link_qty; ++link_idx)
    {
        // Prim name can be one or more of New, Growing and Ripe  e.g 'Ripe' or 'New;Growing;Ripe' etc
        primNames = llParseString2List(llList2String(llGetLinkPrimitiveParams(link_idx + 1, [PRIM_NAME]),0), [";"], []);
        // We only grow the 'Growing' prims
        if (llListFindList(primNames, ["Growing"]) != -1)
        {
            params = llGetLinkPrimitiveParams(link_idx + 1, [PRIM_SIZE]);
            link_scales    += llList2Vector(params, 0);
            link_num       += link_idx + 1;
        }
    }
    max_scale = llGetMaxScaleFactor() * 0.999999;
    min_scale = llGetMinScaleFactor() * 1.000001;
}

resizeObject(float scale)
{
    integer link_qty = llGetListLength(link_scales);
    integer link_idx;
    for (link_idx = 0; link_idx < link_qty; ++link_idx)
    {
        llSetLinkPrimitiveParamsFast(llList2Integer(link_num, link_idx),    [PRIM_SIZE, scale * llList2Vector(link_scales, link_idx) ]);
    }
}


default
{
    state_entry()
    {
        ncSaved = FALSE;
        llSetScriptState("plant", FALSE);
        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        llSetText("", ZERO_VECTOR, 0.0);
        scanLinkset();
    }

    touch_start(integer total)
    {
        if (llDetectedKey(0) == llGetOwner())
            makeMenu();
    }

    timer()
    {
        llListenRemove(handle);
        handle = 0;
        llSetTimerEvent(0);
    }

    listen(integer channel, string name, key id, string msg)
    {
        if (msg == "RESTORE")
        {
            cur_scale = 1.0;
        }
        else if (msg == "MIN SIZE")
        {
            cur_scale = min_scale;
        }
        else if (msg == "MAX SIZE")
        {
            cur_scale = max_scale;
        }
        else if (msg == "CANCEL")
        {
            // ignore but it will re-show the menu as it falls through
        }
        else if (msg == "SET")
        {
            ncSaved = FALSE;
            scanLinkset();
            cur_scale = 1.0;
            llOwnerSay("Set this as the starting prim size");
        }
        else if (msg == "CLOSE")
        {
            llListenRemove(handle);
            handle = 0;
            llSetTimerEvent(0);
            return; // prevents the menu from showing
        }
        else if (msg == "SAVE")
        {
            integer i;
            list c = [];
            integer indx = llGetListLength(link_scales);

            for (i=0; i < indx; i++)
            {
                c += [llList2Vector(link_scales, i), llList2Integer(link_num, i)];
            }
            if (llGetInventoryType("scales") == INVENTORY_NOTECARD)
            {
                llRemoveInventory("scales");
                llSleep(0.2);
            }
            osMakeNotecard("scales", llDumpList2String(c, "|") +"|" +(string)max_scale +"|" +(string)min_scale);
            llSay(0, "Notecard scales written");
            ncSaved = TRUE;
        }
        else if ((msg == "DELETE") || (msg == "YES"))
        {
            if ((ncSaved == TRUE) || (msg == "YES"))
            {
                llSetScriptState("plant", TRUE);
                llOwnerSay("Deleting this script and setting plant script active...");
                llRemoveInventory(llGetScriptName());
                return; // prevents the menu from showing as llRemoveInventory is not instant
            }
            else
            {
                llDialog(llGetOwner(),"Are you sure you want to delete this script as you haven't saved the scales notecard yet?",
                ["YES","NO"],menuChan);
                llSetTimerEvent(DialogTimeout);
            return;
            }
        }
        else
        {
            cur_scale += (float)msg;
        }
        //check that the scale doesn't go beyond the bounds
        if (cur_scale > max_scale) { cur_scale = max_scale; }
        if (cur_scale < min_scale) { cur_scale = min_scale; }
        resizeObject(cur_scale);
        makeMenu();
    }
}
