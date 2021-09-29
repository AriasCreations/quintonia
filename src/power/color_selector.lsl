
vector NAVY      = <0.000, 0.122, 0.247>;
string TXT_NAVY = "Navy";
vector BLUE         = <0.000, 0.455, 0.851>;
string TXT_BLUE = "Blue";
vector AQUA      = <0.498, 0.859, 1.000>;
string TXT_AQUA = "Aqua";
vector TEAL      = <0.224, 0.800, 0.800>;
string TXT_TEAL = "Teal";
vector OLIVE      = <0.239, 0.600, 0.439>;
string TXT_OLIVE = "Olive";
vector MOSS = <0.102, 0.365, 0.000>;
string TXT_MOSS = "Moss";
vector GREEN      = <0.180, 0.800, 0.251>;
string TXT_GREEN = "Green";
vector LIME      = <0.004, 1.000, 0.439>;
string TXT_LIME = "Lime";
vector YELLOW      = <1.000, 0.863, 0.000>;
string TXT_YELLOW = "Yellow";
vector ORANGE      = <1.000, 0.522, 0.106>;
string TXT_ORANGE = "Orange";
vector RED          = <1.000, 0.255, 0.212>;
string TXT_RED = "Red";
vector MAROON      = <0.522, 0.078, 0.294>;
string TXT_MAROON = "Maroon";
vector PINK      = <0.941, 0.071, 0.745>;
string TXT_PINK = "Pink";
vector PURPLE      = <0.694, 0.051, 0.788>;
string TXT_PURPLE = "Purple";
vector WHITE      = <1.000, 1.000, 1.000>;
string TXT_WHITE = "White";
vector SILVER      = <0.867, 0.867, 0.867>;
string TXT_SILVER = "Silver";
vector GRAY      = <0.667, 0.667, 0.667>;
string TXT_GRAY = "Gray";
vector BLACK      = <0.000, 0.000, 0.000>;
string TXT_BLACK = "Black";
vector BROWN      = <0.365, 0.312, 0.228>;
string TXT_BROWN = "Brown";
list colourNames = [];
list colourVectors = [];

string TXT_SELECT = "Select colour";
string TXT_CLOSE = "CLOSE";

key toucher;
integer listener=-1;
integer listenTs;
integer startOffset=0;
key ownKey;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(ownKey), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

// Function to put buttons in "correct" human-readable order
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(ownKey);
    if (l < 12)
    {
        llDialog(id, message, order_buttons(buttons) +[TXT_CLOSE], ch);
    }
    else
    {
        if (startOffset >= l) startOffset = 0;
        list its = llList2List(buttons, startOffset, startOffset + 9);
        its = llListSort(its, 1, 1);
        llDialog(id, message, order_buttons(its)+[TXT_CLOSE]+[">>"], ch);
    }
}


default
{
    state_entry()
    {
        ownKey = llGetKey();
        colourNames = [TXT_NAVY, TXT_BLUE, TXT_AQUA, TXT_TEAL, TXT_OLIVE, TXT_MOSS, TXT_GREEN, TXT_LIME, TXT_YELLOW, TXT_ORANGE, TXT_RED, TXT_MAROON, TXT_PINK, TXT_PURPLE ,TXT_WHITE ,TXT_SILVER ,TXT_GRAY ,TXT_BLACK ,TXT_BROWN];
        colourVectors = [<0.000, 0.122, 0.247>, <0.000, 0.455, 0.851>, <0.498, 0.859, 1.000>, <0.224, 0.800, 0.800>, <0.239, 0.600, 0.439>, <0.102, 0.365, 0.000>, <0.180, 0.800, 0.251>, <0.004, 1.000, 0.439>, <1.000, 0.863, 0.000>, <1.000, 0.522, 0.106>, <1.000, 0.255, 0.212>, <0.522, 0.078, 0.294>, <0.941, 0.071, 0.745>, <0.694, 0.051, 0.788>, <1.000, 1.000, 1.000>, <0.867, 0.867, 0.867>, <0.667, 0.667, 0.667>, <0.000, 0.000, 0.000>, <0.365, 0.312, 0.228>];
    }

   touch_end(integer num)
   {
       toucher = llDetectedKey(0);
       startListen();
       multiPageMenu(toucher, TXT_SELECT, colourNames);
   }

   listen(integer c, string nm, key id, string m)
   {
       //parse buttons
       if (m == TXT_CLOSE)
       {
           checkListen();
       }
       else if (m == ">>")
       {
           startOffset += 10;
           multiPageMenu(toucher, TXT_SELECT, colourNames);
       }
       else
       {
           vector colr = <1,1,1>;
           integer index = llListFindList(colourNames, [m]);
           if (index != -1 ) colr = llList2Vector(colourVectors, index);
           llSetColor(colr, 0);
       }
   }

}
