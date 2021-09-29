// addon-manure.lsl
// Version 1.0    21 January 2020

integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

showPiles(integer level)
{
    integer i;    
    string texPrim;
    level = (level/22);
            
    for (i=1; i<5; i++)
    {
        texPrim = "pile" + (string)i;
        if (i <= level)
        {
            llSetLinkAlpha(getLinkNum(texPrim), 1.0, ALL_SIDES);
        }
        else
        {
            llSetLinkAlpha(getLinkNum(texPrim), 0.0, ALL_SIDES);
        }
    }
}

default
{
    link_message(integer ln, integer nv, string sv, key kv)
    {
        list tk = llParseString2List(sv,["|"], []);
        string cmd =llList2String(tk,0);
        
        if (cmd == "GOTLEVEL")
        {
            integer i;    
            string texPrim;
            showPiles(llList2Integer(tk,2));
        }    
        else if (cmd == "STORESTATUS")
        {
            showPiles(llList2Integer(tk,3));
        }
        else if (cmd == "RESET")
        {
            //
        }
    }

}