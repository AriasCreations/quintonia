// ossl_check.lsl
//  Checks the avialability of the OSSL functions needed for SatyrFarm
//   Version 3.1    20 November 2020

string TXT_ALL_GOOD = "All okay";
string TXT_NOT_GOOD = "ISSUES\nFOUND";
string TXT_ISSUES = "== FUNCTIONS WITH PERMISSION ISSUES ==";
string TXT_MAIN = "Problem with these esssential functions:";
string TXT_ASK_NPC = "Check NPC functions?";
string TXT_YES = "Yes";
string TXT_NO = "No";

integer WhichProbeFunction; // to tell us which function we're probing
integer NumberOfFunctionsToCheck; // how many functions are we probing?
key     npcKey;
key     thisAvatar;
key     boxOwner;
integer msgChan = -28651;
integer msgListen;
integer chkMain;
integer chkNPC;
integer chkBaby;
string  floatMsg = "";
list    FunctionNames = ["osMakeNotecard", "osGetNotecard", "osMessageObject", "osSetDynamicTextureDataBlendFace",
"osSetSpeed", "osAgentSaveAppearance", "osNpcMoveToTarget", "osNpcStopMoveToTarget", "osNpcGetPos", "osNpcPlayAnimation", "osNpcStopAnimation", "osNpcWhisper", "osNpcSay", "osNpcCreate", "osNpcRemove", "osNpcTouch", "osNpcSetProfileAbout", "osNpcSetProfileImage",
 "osDropAttachment"];

// 0 to 3 ARE NEEDED FOR ALL  4 to 17 ARE NEEDED FOR NPC FARMER    18 NEEDED FOR BABY

list FunctionPermitted = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // 0 = not permitted, 1 = permitted

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
    commandList = osSetFontSize(commandList, 45);
    commandList = osDrawText(commandList, msg);
    osSetDynamicTextureDataBlendFace("", "vector", commandList, "width:256,height:256", FALSE, 2, 0, 255, ALL_SIDES);
}

integer listener=-1;
integer listenTs;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

startListen()
{
    if (listener<0)
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
}

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
    {
        llListenRemove(listener);
        listener = -1;
        llSetTimerEvent(0);
    }
}

doSay(string msg)
{
    if (osIsNpc(thisAvatar) == FALSE) llRegionSayTo(thisAvatar, 0, msg); else llRegionSay(msgChan, msg);
}

// The default state uses the timer to call all the OSSL functions we're interested in using, in turn.
// If the function call fails, the timer event handler will abend, but the script doesn't crash. We can
// use this fact to check all of our desired functions in turn, and then pass control to the Running
// state once we've checked them all.
//
default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        llSetTexture(TEXTURE_BLANK, ALL_SIDES);
        llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, ALL_SIDES,1,1,0, 4.0, 2.1);
        llSetColor(<1.000, 0.863, 0.000>, ALL_SIDES);
        llSetText("",ZERO_VECTOR,0);
        thisAvatar = llGetOwner();
        if (osIsNpc(thisAvatar) == FALSE) boxOwner = llGetOwner();
    //    if (osIsNpc(thisAvatar) == FALSE) llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        if (llGetInventoryType("bogus") == INVENTORY_NOTECARD) llRemoveInventory("bogus");
        doSay("Probing OSSL functions to see what we can use");
        NumberOfFunctionsToCheck = llGetListLength( FunctionNames);
        WhichProbeFunction = -1;
        llSetTimerEvent( 0.25 ); // check only four functions a second, just to be nice.
    }

    touch_start(integer num)
    {
        llResetScript();
    }

    timer()
    {
        string BogusKey = "12345678-1234-1234-1234-123456789abc"; // it doesn't need to be valid
        string s; // for storing the result of string functions
        list l; // for storing the result of list functions
        vector dummy;
        if (++WhichProbeFunction == NumberOfFunctionsToCheck) // Increment WhichProbeFunction; exit if we're done
        {
            llSetTimerEvent( 0.0 ); // stop the timer
            state Running; // switch to the Running state
        }
        doSay("Checking function " + llList2String( FunctionNames, WhichProbeFunction )); // say status
        // osMakeNotecard"
        if (WhichProbeFunction == 0)
        {
            osMakeNotecard( "bogus", "*" );
        }
        // osGetNotecard
        else if (WhichProbeFunction == 1)
        {
            s = osGetNotecard( "bogus" );
        }
        // osMessageObject
        else if (WhichProbeFunction == 2)
        {
            osMessageObject(llGetKey(), "*");
        }
        // osSetDynamicTextureDataBlendFace
        else if (WhichProbeFunction == 3)
        {
            setText("TEST...");
        }
        // osAgentSaveAppearance
        else if (WhichProbeFunction == 5)
        {
          osAgentSaveAppearance(llGetOwner(), "bogus");
        }
        // osNpcCreate
        else if (WhichProbeFunction == 13)
        {
            if (osIsNpc(thisAvatar) == FALSE) npcKey = osNpcCreate("Test", "NPC", llGetPos(), "npc-test"); else npcKey = thisAvatar;
        }
        // osNpcSetProfileAbout
        else if (WhichProbeFunction == 16)
        {
            osNpcSetProfileAbout(npcKey, "I'm a test NPC");
        }
        // osNpcSetProfileImage
        else if (WhichProbeFunction == 17)
        {
            osNpcSetProfileImage(npcKey, "TEXTURE_PLYWOOD");
        }
        // osSetSpeed
        else if (WhichProbeFunction == 4)
        {
          osSetSpeed(npcKey, 1);
        }
        // osDropAttachment
        else if (WhichProbeFunction == 18)
        {
            //if (osIsNpc(thisAvatar) == FALSE) osDropAttachment();
        }
        // osNpcMoveToTarget
        else if (WhichProbeFunction == 6)
        {
            osNpcMoveToTarget(npcKey, llGetPos(), 0);
        }
        // osNpcStopMoveToTarget
        else if (WhichProbeFunction == 7)
        {
            osNpcStopMoveToTarget(npcKey);
        }
        // osNpcGetPos
        else if (WhichProbeFunction == 8)
        {
            dummy = osNpcGetPos(npcKey);
        }
        // osNpcPlayAnimation
        else if (WhichProbeFunction == 9)
        {
            osNpcPlayAnimation(npcKey, "flip");
        }
        // osNpcStopAnimation
        else if (WhichProbeFunction == 10)
        {
            osNpcStopAnimation(npcKey, "flip");
        }
        // osNpcWhisper
        else if (WhichProbeFunction == 11)
        {
            osNpcWhisper(npcKey, 1, "Testing 'Whisper'");
        }
        // osNpcSay
        else if (WhichProbeFunction == 12)
        {
            osNpcSay(npcKey, 1, "Testing 'Say'");
        }
        // osNpcTouch
        else if (WhichProbeFunction == 15)
        {
            osNpcTouch(npcKey, (key)BogusKey, 0);
        }
        // osNpcRemove
        else if (WhichProbeFunction == 14)
        {
            osNpcRemove(npcKey);
        }
        // If we got here, then the timer() handler didn't crash, which means the function it checked for
        // was actually permitted. So we update the list to indicate that we can use that particular function.
        FunctionPermitted = llListReplaceList( FunctionPermitted, [ 1 ], WhichProbeFunction, WhichProbeFunction );
    }

}

//

state Running
{
    touch_start(integer num)
    {
        llResetScript();
    }

    state_entry()
    {
        llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 1.0);
        llListen(msgChan, "", "", "");
        // 0 to 3 ARE NEEDED FOR ALL  4 to 17 ARE NEEDED FOR NPC FARMER    18 NEEDED FOR BABY
        chkNPC = TRUE;
        chkBaby = TRUE;
        chkMain = TRUE;
        string floatTxt = "";
        string statusMsg = "";
        integer canDo = 0;
        integer index;
        integer count = llGetListLength( FunctionNames );
        for (index; index < count; index+=1)
        {
            if (llList2Integer(FunctionPermitted, index))
            {
                canDo ++;
            }
            else
            {
                if (llListFindList([0,1,2,3], [index]) != -1)
                {
                    if (chkMain == TRUE)
                    {
                        floatTxt += TXT_MAIN+"\n";
                        chkMain = FALSE;
                    }
                    floatTxt += "\t" +llList2String(FunctionNames, index) + "\n";
                }
                else if (llListFindList([18], [index]) != -1)
                {
                    if (chkBaby == TRUE)
                    {
                        floatTxt += "\n Problem with osDropAttachment (Baby)\n \n";
                        chkBaby = FALSE;
                    }
                }
                else if (llListFindList([4, 5, 6, 7, 8, 8, 10, 11, 12, 13, 14, 15, 16, 17], [index]) != -1)
                {
                    if (chkNPC == TRUE)
                    {
                        floatTxt += "\n \nProblem with NPC functions\n \n";
                        chkNPC = FALSE;
                    }
                }
                statusMsg += llList2String( FunctionNames, index) + "\n";
            }
        }

        string info;
        key avatarID = llGetOwner();
        if (canDo == llGetListLength(FunctionNames))
        {
            if (osIsNpc(avatarID) == FALSE)
            {
                llOwnerSay("\n----------------------\n" +TXT_ALL_GOOD +"\n----------------------\n");
                floatMsg = TXT_ALL_GOOD;
                llSetText(floatMsg+"\n", <1,1,1>, 1);
            }
            else
            {
                llRegionSay(msgChan+1, TXT_ALL_GOOD);
            }
            setText(TXT_ALL_GOOD);
            llSetColor(<0,1,0>, ALL_SIDES);
        }
        else
        {
            if (osIsNpc(avatarID) == FALSE)
            {
                llOwnerSay("\n----------------------\n" +TXT_ISSUES +"----------------------\n \n" +statusMsg +"\n---------------------------------------------\n");
                floatMsg = TXT_ISSUES+":\n \n\t" +floatTxt;
                llSetText(floatMsg, <1,1,1>, 1.0);
            }
            else
            {
                llRegionSay(msgChan+1, TXT_ISSUES+":\n" +floatTxt);
            }
            setText(TXT_NOT_GOOD);
            llSetColor(<1,0,0>, ALL_SIDES);
        }
        // Now ask if they want to check NPC
        if (osIsNpc(avatarID) == FALSE)
        {
            startListen();
            llSetTimerEvent(180);
            llDialog(llGetOwner(), TXT_ASK_NPC, [TXT_YES, TXT_NO], chan(llGetKey()));
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == msgChan)
        {
            llOwnerSay(message);
        }
        else if (channel == msgChan+1)
        {
            llOwnerSay(floatMsg +"\n" +"NPC Results: "+message);
            llSetText(floatMsg +"\n" +"NPC Results: "+message, <0.0, 1.0, 0.5>, 1.0);
        }
        else if (message == TXT_YES)
        {
            npcKey = osNpcCreate("Farmer", "Test", llGetPos(), "npc-ossl_test", 8); // 8 = OS_NPC_GROUP
        }
        else checkListen(TRUE);
    }

    timer()
    {
        checkListen(FALSE);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }

}
