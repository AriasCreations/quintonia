// addon-labeler.lsl
//  version 1.1     30 January 2020
//
default
{
    link_message(integer ln, integer nv, string sv, key kv)
    {
        string pass = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);;
        if (nv == 91)
        {
            list tk = llParseString2List(sv,["|"], []);
            key u = llList2Key(tk, 1);
            
            if ( (llKey2Name(u) == "SF EmptyContainer") || (llKey2Name(u) == "SF Barrel") )
            {
                string recipe = llList2Key(tk, 2);
                osMessageObject(u, "SETOBJECTNAME|"+pass+"|SF "+recipe+"");
                osMessageObject(u, "SETLINKTEXTURE|"+pass+"|3|"+llGetInventoryKey("Label-"+recipe)+"|"+(string)ALL_SIDES);
            }
        }
    }
}