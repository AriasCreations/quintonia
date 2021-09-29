// oscheck.lsl
//  Checks the avialability of the OSSL functions needed for SatyrFarm
//   Version 2.0  21 September 2020


integer WhichProbeFunction; // to tell us which function we're probing
integer NumberOfFunctionsToCheck; // how many functions are we probing?
key npcKey;
list FunctionNames = [ "osMakeNotecard", "osGetNotecard", "osMessageObject", "osSetDynamicTextureDataBlendFace"];
list FunctionPermitted = [0, 0, 0, 0]; // 0 = not permitted, 1 = permitted
string thisRegion;
// isFunctionAvailable() takes the name of a function, and returns 1 if it is available, and 0 if
// it is forbidden or has not been tested.
//
integer isFunctionAvailable( string whichFunction )
{
    integer index = llListFindList( FunctionNames, whichFunction );
    if (index == -1) return 0; // Return FALSE if the function name wasn't one of the ones we checked.
    return llList2Integer( FunctionPermitted, index ); // return the appropriate availability flag.
}

setText(string msg)
{
    string commandList = "";
    commandList = osMovePen(commandList, 10, 10);
    commandList = osSetFontName(commandList,  "Arial");
    commandList = osSetFontSize(commandList, 50);
    commandList = osDrawText(commandList, msg);
    osSetDynamicTextureDataBlendFace("", "vector", commandList, "width:256,height:256", FALSE, 2, 0, 255, 5);
}

// The default state uses the timer to call all the OSSL functions we're interested in using, in turn.
// If the function call fails, the timer event handler will abend, but the script doesn't crash. We can
// use this fact to check all of our desired functions in turn, and then pass control to the Running
// state once we've checked them all.
//
default
{
    state_entry()
    {
        thisRegion = llGetRegionName();
        if (llGetInventoryType("ostest") == INVENTORY_NOTECARD) llRemoveInventory("ostest");
        NumberOfFunctionsToCheck = llGetListLength( FunctionNames );
        WhichProbeFunction = -1;
        llSetTimerEvent( 0.25 ); // check only four functions a second, just to be nice.
    }

    timer()
    {
        string s; // for storing the result of string functions
        list l; // for storing the result of list functions
        vector dummy;
        if (++WhichProbeFunction == NumberOfFunctionsToCheck) // Increment WhichProbeFunction; exit if we're done
        {
            llSetTimerEvent( 0.0 ); // stop the timer
            state Running; // switch to the Running state
        }
        // osMakeNotecard"
        if (WhichProbeFunction == 0)
        {
            osMakeNotecard("ostest", "*");
        }
        // osGetNotecard
        else if (WhichProbeFunction == 1)
        {
            s = osGetNotecard("ostest");
        }
        // osMessageObject
        else if (WhichProbeFunction == 2)
        {
            osMessageObject(llGetKey(), "*");
        }
        // osSetDynamicTextureDataBlendFace
        else if (WhichProbeFunction == 3)
        {
            setText(".");
        }
        // If we got here, then the timer() handler didn't crash, which means the function it checked for
        // was actually permitted. So we update the list to indicate that we can use that particular function.
        FunctionPermitted = llListReplaceList( FunctionPermitted, [ 1 ], WhichProbeFunction, WhichProbeFunction );
    }

    changed(integer change)
    {
        if ((change & CHANGED_REGION) || (thisRegion != llGetRegionName()))
        {
            thisRegion = llGetRegionName();
            llResetScript();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "DO_OS_CHK") llResetScript();
    }

}
//

state Running
{

     state_entry()
     {
        integer canDo = 0;
        integer i = llGetListLength( FunctionNames );
        while (i--)
            if (llList2Integer( FunctionPermitted, i ))
            {
                canDo ++;
            }
            else
            {
                //t += llList2String( FunctionNames, i ) + "\n";
            }

        if (canDo == llGetListLength(FunctionNames)) llMessageLinked(LINK_THIS, 1, "OSCHECK", ""); else llMessageLinked(LINK_THIS, 0, "OSCHECK", "");
    }

    changed(integer change)
    {
        if ((change & CHANGED_REGION) || (thisRegion != llGetRegionName()))
        {
            thisRegion = llGetRegionName();
            llResetScript();
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str == "DO_OS_CHK") llResetScript();
    }

}
