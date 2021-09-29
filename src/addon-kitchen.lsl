    // addon-kitchen.lsl
    //  Set the texture of the prim called 'product' to the one specified by the TEXTURE setting in recipe
    //  makes it visible during cooking and transparent rest of time.
    //  Version 2.2  23 May 2020

    integer lnkProduct;
    string  productTexture;

    integer getLinkNum(string name)
    {
        integer i;
        for (i=1; i <=llGetNumberOfPrims(); i++)
            if (llGetLinkName(i) == name) return i;
        return -1;
    }


    default
    {
        link_message(integer l, integer n, string m, key id)
        {
            // If using a product prim it may also be the level prim
            lnkProduct = getLinkNum("product");
            if (lnkProduct == -1) lnkProduct = getLinkNum("level");

            list tok = llParseString2List(m, ["|"], []);
            string cmd = llList2String(tok, 0);

            if (cmd == "SELECTEDRECIPE")
            {
                productTexture = "";
                integer found_texture = llListFindList(tok, ["TEXTURE"]) + 1;
                if (found_texture)
                    productTexture = llList2String(tok, found_texture);
            }
            else if (cmd == "STARTCOOKING")
            {
                if ((productTexture != "") && (lnkProduct != -1))
                {
                    llSetLinkPrimitiveParamsFast(lnkProduct, [PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0, PRIM_TEXTURE, ALL_SIDES, productTexture, <3.0, 2.0, 0.0>, ZERO_VECTOR, 0.0]);
                }
            }
            else if (cmd == "PROGRESS")
            {
                integer lnkLevel = getLinkNum("level");
                list pstate = llGetLinkPrimitiveParams(lnkLevel, [PRIM_POS_LOCAL, PRIM_DESC]);
                vector p = llList2Vector(pstate, 0);
                list desc = llParseStringKeepNulls(llList2String(pstate, 1), [","], []);
                if (llGetListLength(desc) == 2)
                {
                    float minHeight = llList2Float(desc, 0);
                    float maxHeight = llList2Float(desc, 1);
                    integer lev = n;
                    p.z = minHeight + (maxHeight-minHeight) * 0.99 * (float)(lev) / 100;
                    llSetLinkPrimitiveParamsFast(lnkLevel, [PRIM_POS_LOCAL, p]);
                }
            }
            else if (cmd == "ENDCOOKING")
            {
                if ((productTexture != "") && (lnkProduct != -1)) llSetLinkAlpha(lnkProduct, 0.0, ALL_SIDES);
            }
        }

    }
