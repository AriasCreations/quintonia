// Modifies glasses to match required drink

default
{
    link_message(integer ln, integer nv, string sv, key kv)
    {
        string pass = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);;
        if (nv == 91) //Rezzed
        {
            // eg.    REZZED|a7bf5668-16eb-4138-8d3d-371bd60a303b|Sunshine smoothie|<0.807, 0.622, 0.130>|0.8|cube|
            list tk = llParseString2List(sv,["|"], []);
            key   u = llList2Key(tk, 1);
            string prodName = llKey2Name(u);

            if (prodName == "SF ShortGlass" || prodName == "SF TallGlass" || prodName == "SF CocktailGlass" || prodName == "SF Jug")
            {
                string recipe = llList2Key(tk, 2);
                //list myParams = llParseString2List(getRecipeParams(recipe), ["|"],[]);
                list myParams = llList2List(tk, 3, llGetListLength(tk));
                if (llGetListLength(myParams))
                {
                    if (prodName == "SF Jug")
                    {
                        osMessageObject(u, "SETJUGCOLOR|"+pass+"|drink|"+"0"+"|"
                        +(string)llList2Vector(myParams, 0)+"|"+(string)llList2Float(myParams, 1));
                    }

                    osMessageObject(u, "SETOBJECTNAME|"+pass+"|SF "+recipe+"");
                    osMessageObject(u, "SETLINKNAMECOLOR|"+pass+"|drink|"+(string)ALL_SIDES+"|"
                        +(string)llList2Vector(myParams, 0)+"|"+(string)llList2Float(myParams, 1));

                    integer result;
                    list ext = ["cube", "straw", "olive", "lime"];
                    integer nn;
                    for (nn=0; nn < llGetListLength(myParams); nn++)
                    {
                        result = llListFindList(ext, llList2List(myParams, nn, nn));
                        if (result != -1)
                        {
                            osMessageObject(u, "SETLINKNAMECOLOR|"+pass+"|"+  llList2String(ext, result)   +"|"+(string)ALL_SIDES+"|<1,1,1>|1.0|");
                        }
                    }
                }
            }
        }
    }
}
