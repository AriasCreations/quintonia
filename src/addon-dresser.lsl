integer current_anim;
list anims;
key sitter;
integer numAnims = 0;


get_anims()
{
    anims = [];
    integer i;
    integer anim_count = llGetInventoryNumber(INVENTORY_ANIMATION);
    for(i=0;i<anim_count;++i)
    {
        anims = anims + [llGetInventoryName(INVENTORY_ANIMATION,i)];
    }
    numAnims = i-1;
}

default
{
    state_entry()
    {
        get_anims();
        current_anim = 0;
        llSitTarget( <0.0, 0.0, 0.25>, ZERO_ROTATION);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }


    link_message(integer sender_num, integer num, string str, key id)
    {
        list tok = llParseString2List(str, ["|"], []);
        string cmd = llList2String(tok, 0);

        if (cmd == "STARTCOOKING")
        {
            llResetTime();
            current_anim = 0;
            llStartAnimation(llList2String(anims, current_anim));
            llSetLinkPrimitiveParamsFast(7, [PRIM_POINT_LIGHT, TRUE, <1,1,1>, 1.0, 0.7, 2.0]);

            llSetLinkPrimitiveParamsFast(5, [PRIM_COLOR, 1, <0,0,0>, 1,
                                             PRIM_FULLBRIGHT, 1, 1,
                                             PRIM_BUMP_SHINY, 1, PRIM_SHINY_HIGH, PRIM_BUMP_NONE]);
        }

        if (cmd == "PROGRESS")
        {
            if (llGetTime() > 5)
            {
                llStopAnimation(llList2String(anims, current_anim));
                current_anim +=1;
                if (current_anim > numAnims) current_anim=0;
                llStartAnimation(llList2String(anims, current_anim));
                llResetTime();
            }
        }
        else if (cmd == "ENDCOOKING")
        {
            llStopAnimation(llList2String(anims, current_anim));
            current_anim = 0;
            llSetLinkPrimitiveParamsFast(7, [PRIM_POINT_LIGHT, FALSE, <1,1,1>, 1.0, 0.7, 2.0]);

            llSetLinkPrimitiveParamsFast(5, [PRIM_COLOR, 1, <0.820, 0.820, 0.820>, 1,
                                                         PRIM_FULLBRIGHT, 1, 0,
                                                         PRIM_BUMP_SHINY, 1, PRIM_SHINY_LOW, PRIM_BUMP_NONE]);
        }
    }


    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            sitter = llAvatarOnSitTarget();
            if(sitter != NULL_KEY)
            {
                llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
            }
            else
            {
                sitter = NULL_KEY;
                if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                {
                    llStopAnimation(llList2String(anims, current_anim));
                }
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation(llList2String(anims, current_anim));
        }
        else
        {
            llSay(0,"Permission denied, please resit on me.");
        }
    }
}
