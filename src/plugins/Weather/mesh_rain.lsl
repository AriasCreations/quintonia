
list effects = [SMOOTH,LOOP];
integer movement = 0;

initAnim(integer animOn)
{
    if (animOn == TRUE)
    {
        integer effectBits;
        integer i;
        for( i = 0; i < llGetListLength(effects); i++)
        {
            effectBits = (effectBits | llList2Integer(effects,i));
        }
        integer params = (effectBits|movement);
        llSetTextureAnim(ANIM_ON|params, ALL_SIDES, 1, 1, 0, 0.0, 1.5);
    }
    else
    {
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
    }
}


default
{
    state_entry()
    {
        initAnim(1);
    }
}
