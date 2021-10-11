#include "MasterFile.lsl"


integer ZNI_CHANNEL = 0x9f99F;
stopOthers(){
    integer i=0;
    llSetRemoteScriptAccessPin(0);
    integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
    for(i=0;i<end;i++){
        string script = llGetInventoryName(INVENTORY_SCRIPT,i);
        integer iPercent = (i*100/end);
        llSetText("Stopping scripts: "+script+"\n"+(string)iPercent+"%", <1,1,1>,1);
        if(script!=llGetScriptName())llSetScriptState(script,FALSE);
    }
    llSetText("Version Control Server",<1,0,0>,1);
}

key g_kLock;
string g_sLockRetry;
string g_sLockScript;
PROCESS(key kID, string sItem, string sItemDesc, string sItemLoc, string object, string sItemHash, integer iInstallPin, key kItemID, string sItemType)
{
    if(sItemType == "notecard"){
        // Get the location
        if(sItemLoc == "global"){
            // This is object specific
            // Object.ItemName
            string sActualHash = llMD5String(osGetNotecard(object+"."+sItem),0);
            if(sActualHash != sItemHash)
            {
                osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "remove_item", "items", llList2Json(JSON_ARRAY, [sItem])]));
                llSleep(3);
                //llGiveInventory(kID, sItem);
                list lLines = [];
                integer iNCLine;
                string sNCLine;
                integer iTotalNC = osGetNumberOfNotecardLines(object+"."+sItem);
                for(iNCLine=0;iNCLine<iTotalNC;iNCLine++){
                    sNCLine=osGetNotecardLine(object+"."+sItem, iNCLine);
                    lLines += llStringToBase64(sNCLine);
                    //llSay(0, "NCLINE : '"+sNCLine+"'");
                    //string sNCLines = llStringTrim(sNCLine,STRING_TRIM);
                    //llSay(0, "NCLINE : '"+sNCLines+"'");
                }
                llSay(0, "Sending the notecard recreation instructions for item '"+sItem+"'");
                osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd","make_notecard", "name", sItem, "contents", llList2Json(JSON_ARRAY,lLines)]));
                llSleep(2);
                osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
                llSleep(3);
            }
        } else if(sItemLoc == "inventory")
        {
            if(kItemID != llGetInventoryKey(sItem)){
                // Give the inventory, not any other way to handle this
                llSay(0, "giving notecard : "+sItem);
                osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "remove_item","items", llList2Json(JSON_ARRAY, [sItem])]));
                llSleep(3);
                llGiveInventory(kID, sItem);
                llSleep(2);
                osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
                llSleep(3);
                                        
            }
        } else if(sItemLoc == "ignore"){
            llSay(0, "Ignore any existing, or not existing notecard named : "+sItem);
        }else {
            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "remove_item", "items", llList2Json(JSON_ARRAY, [sItem])]));
            llSleep(3);
            //llGiveInventory(kID, sItem);
            list lLines = [];
            integer iNCLine;
            string sNCLine;
            integer iTotalNC = osGetNumberOfNotecardLines(sItemLoc+"."+sItem);
            for(iNCLine=0;iNCLine<iTotalNC;iNCLine++){
                sNCLine=osGetNotecardLine(sItemLoc+"."+sItem, iNCLine);
                lLines += llStringToBase64(sNCLine);
                //llSay(0, "NCLINE : '"+sNCLine+"'");
                //string sNCLines = llStringTrim(sNCLine,STRING_TRIM);
                //llSay(0, "NCLINE : '"+sNCLines+"'");
            }
            llSay(0, "Sending the notecard recreation instructions for item '"+sItem+"'");
            osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd","make_notecard", "name", sItem, "contents", llList2Json(JSON_ARRAY,lLines)]));
            llSleep(2);
            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
            llSleep(3);
        }
    }else if(sItemType == "other")
    {
        // Give the inventory, not any other way to handle this
        if(kItemID != llGetInventoryKey(sItem)){
            llSay(0, "giving misc item : "+sItem);
            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "remove_item","items", llList2Json(JSON_ARRAY, [sItem])]));
            llSleep(3);
            llGiveInventory(kID, sItem);
            llSleep(2);
            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
            llSleep(3);
        }
    } else if(sItemType == "script")
    {
        if(sItemLoc == "ignore")jump justover;
        if(sItemDesc != osGetInventoryDesc(sItem)){
            llSay(0, "Installing script : "+sItem);
            llRemoteLoadScriptPin(kID, sItem, iInstallPin,TRUE, iInstallPin);
            llSay(0, "Installed Script : "+sItem+" : "+sItemDesc+" -> "+osGetInventoryDesc(sItem));
            llSleep(2);
            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
            llSleep(3);
        }
        @justover;
    }
}
default
{
    state_entry()
    {
        if(llGetObjectDesc()=="KAUTO"){
            llSetObjectDesc("");
            state VCSOn;
        }
        state VCSOff;
    }
}
state VCSWaitDrop /// The purpose of this state is to try to let the engine drop all the other messages occuring in the channel
{
    state_entry()
    {
        if(llGetFreeMemory()<=200000){
            llSetObjectDesc("KAUTO");
            llResetScript();
        }
        llSleep(10);
        state VCSOn;
    }
}
state VCSOn
{
    state_entry(){
        g_kLock=NULL;
        stopOthers();
        //llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","clearack"])); // Temporarily, do NOT clear this
        llListen(ZNI_CHANNEL, "", "", "");
        llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","versions"]));
        llSetTimerEvent(60);
        llSetText("Version Control Server\n[ZNI]\n \nV"+osGetInventoryDesc(llGetScriptName())+"\n \n"+(string)llGetFreeMemory(),<1,0,0>,1);
        
        llListen(0, "", "", "");
    }
    touch_start(integer t){
        stopOthers();
        if(g_kLock!=NULL){
            switch(g_sLockRetry){
                case "pin":{
                    osMessageObject(g_kLock, llList2Json(JSON_OBJECT,["cmd","set_pin","script",g_sLockScript]));
                    llSay(0, "Reask for pin-set");
                    break;
                }
                case "manifest":{
                    llSay(0, "Reask for manifest");
                    osMessageObject(g_kLock,llList2Json(JSON_OBJECT,["cmd","get_manifest"]));
                    break;
                }
            }
        } else {
            // Send the versions command, we're not locked.
            llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","versions"]));
        }
        //
    }
    listen(integer c,string n,key i,string m){
        if(c==0){
            if(m == "0x9f auth set off"){
                llSay(0, "VCS Disabling...");
                state VCSOff;
            }
            return;
        }
        if(llJsonGetValue(m,["cmd"])=="ready4vcs"){
            llRegionSayTo(i,c,llList2Json(JSON_OBJECT,["cmd","clearack"]));
            llSleep(10); // Wait 10 seconds to allow for other scripts to take any necessary actions on the target object.
            llRegionSayTo(i,c,llList2Json(JSON_OBJECT,["cmd","versions"]));
        }
    }
    timer(){
        stopOthers();
        if(g_kLock!=NULL){
            switch(g_sLockRetry){
                case "pin":{
                    osMessageObject(g_kLock, llList2Json(JSON_OBJECT,["cmd","set_pin","script",g_sLockScript]));
                    break;
                }
                case "manifest":{
                    osMessageObject(g_kLock,llList2Json(JSON_OBJECT,["cmd","get_manifest"]));
                    break;
                }
            }
        } else {
            // Send the versions command, we're not locked.
            llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","versions"]));
        }
    }
    changed(integer i){
        if(i&CHANGED_REGION_START){
            stopOthers();
            llSleep(60); // Sleep!
            llResetScript();
        } else if(i&CHANGED_INVENTORY){
            stopOthers();
            llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT,["cmd","versions"]));
        }
    }
    dataserver(key kID, string sData){
        //llSay(0, "DATASERVER : "+llKey2Name(kID)+"; ("+(string)llStringLength(sData)+"); "+sData);
        if(llGetSubString(sData,0,0)=="{" && llGetSubString(sData,-1,-1) == "}"){
        }else{
            llSay(0, "FATAL : Likely truncated response");
            state VCSOff;
        }
        vector pos = llList2Vector(llGetObjectDetails(kID,[OBJECT_POS]),0);
        if(pos==ZERO_VECTOR){
            if(HasDSRequest(kID)!=-1){
                // Handle my own request
            }
        }else {
            // Handle osMsgObj
            if(llJsonGetValue(sData, ["cmd"])=="version_reply"){
                if(g_kLock != NULL && g_kLock!=kID)return;
                string script = llJsonGetValue(sData,["script"]);
                if(script != "VCSSlave[ZNI]" && script != "- FARM SCRIPT TEMPLATE -"){
                    //osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","setack", "script", script]));
                    return; // We're ignoring this because they are implemented badly.
                }
                string ver = llJsonGetValue(sData,["version"]);
                if(llGetInventoryType(script)==INVENTORY_NONE){
                    llSay(0, "ERROR: This VCS unit does not contain the item '"+script+"'; "+llKey2Name(kID));
                }else {
                    llSay(0, "Version check for : "+llKey2Name(kID));
                    if(osGetInventoryDesc(script)!=ver){
                        llSay(0, "Informing the recipient to enable script loading permissions");
                        osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd","set_pin", "script", script]));
                        g_sLockScript=script;
                        g_kLock = kID;
                        g_sLockRetry = "pin";
                    }else{
                        llSay(0, "The script is already up to date. Telling the script to ignore further checks from me for the next hour");
                        osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","setack", "script", script]));
                        if(script=="VCSSlave[ZNI]"){
                            llSay(0, "Retrieving the manifest - ");
                            osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "get_manifest"]));
                            g_kLock = kID;
                            g_sLockRetry = "manifest";
                        }
                    }
                }
            } else if(llJsonGetValue(sData,["cmd"]) == "pin_ready"){
                // Check the item type!
                string script = llJsonGetValue(sData,["script"]);
                integer TYPE = 0;
                while(TYPE != INVENTORY_SCRIPT){
                    TYPE = llGetInventoryType(script);
                    if(TYPE == INVENTORY_NOTECARD){
                        string newscript = osGetInventoryDesc(script); // This allows for more than a single deprecation!
                        
                        osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","deprecate","script",script]));
                        llSay(0, "DEPRECATE : "+script+" -> "+newscript);
                        script=newscript;
                    }
                }
                llSay(0, "Install : "+script);
                llRemoteLoadScriptPin(kID,script, (integer)llJsonGetValue(sData,["pin"]), TRUE, ZNI_CHANNEL);
                llSay(0, "Installed : "+ script);
                g_kLock=NULL;
                llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","versions"]));
            } else if(llJsonGetValue(sData, ["cmd"]) == "manifest_response"){
                if(g_kLock != kID)return;
                string object = llJsonGetValue(sData,["object"]);
                integer iInstallPin = (integer)llJsonGetValue(sData,["pin"]);
                @returnCodeToL138;
                if(llGetInventoryType(object+".Manifest") != INVENTORY_NONE){
                    string objectManifest= llJsonGetValue(sData,["manifest"]);
                    string currentManifest = osGetNotecard(object+".Manifest");
                    
                    if(object != llJsonGetValue(currentManifest,["object"])){
                        osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd", "rename_object", "name", llJsonGetValue(currentManifest,["object"])]));
                        // Return to the top of this code section
                        object= llJsonGetValue(currentManifest,["object"]);
                        jump returnCodeToL138;
                    }else {
                        // Now, start the parse loop of the manifest
                        llSay(0, "Starting to parse manifest for : "+object+"...");
                        //llSay(0, "OBJECT : "+objectManifest);
                        //llSay(0, "CURRENT : "+currentManifest);
                        
                        list lManifestInventory = llJson2List(llJsonGetValue(objectManifest, ["inventory"]));
                        lManifestInventory += ["VCSSlave[ZNI]", llList2Json(JSON_OBJECT,["type","script", "location", "ignore"])];
                        list lActualManifest = llJson2List(llJsonGetValue(currentManifest, ["inventory"]));
                        lActualManifest += ["VCSSlave[ZNI]", llList2Json(JSON_OBJECT,["type","script", "location", "ignore"])];
                        
                        // Iterate over the Inventory Manifest, compare against the actual manifest
                        integer ix =0;
                        integer ixend = llGetListLength(lManifestInventory);
                        llSleep(1);
                        osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
                        llSleep(1);
                        for(ix=0;ix<ixend;ix+=2)
                        {
                            string sItem = llList2String(lManifestInventory,ix);
                            string sItemJson = llList2String(lManifestInventory,ix+1);
                            
                            string sItemType = llJsonGetValue(sItemJson, ["type"]);
                            string sItemLoc = llJsonGetValue(sItemJson,["location"]);
                            string sItemDesc = llJsonGetValue(sItemJson,["D"]);
                            string sItemHash = llJsonGetValue(sItemJson,["hash"]);
                            key kItemID = (key)llJsonGetValue(sItemJson, ["key"]);
                            
                            
                            // Now, compare it against the actual manifest.
                            integer ixx =0;
                            integer iFound = FALSE;
                            integer ixxend = llGetListLength(lActualManifest);
                            integer iActualIndex=-1;
                            for(ixx=0;ixx<ixxend;ixx+=2)
                            {
                                string sItemX = llList2String(lActualManifest,ixx);
                                if(sItemX==sItem)
                                {
                                    iFound=TRUE;
                                    iActualIndex=ixx;
                                    sItemLoc = llJsonGetValue(llList2String(lActualManifest,ixx+1), ["location"]);
                                }
                            }
                            if(iFound)
                            {
                                // Begin checks of type, and the location
                               PROCESS( kID,  sItem,  sItemDesc,  sItemLoc,  object,  sItemHash,  iInstallPin,  kItemID,  sItemType);
                                if(iActualIndex!=-1)
                                    lActualManifest = llDeleteSubList(lActualManifest, iActualIndex, iActualIndex+1);
                            } else {

                                llSay(0, "ITEM : "+sItem+" : does not exist in the Assertion Manifest. If this item is required, please add a ignore location entry for it to avoid it being deleted");
                                osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd","remove_item","items",llList2Json(JSON_ARRAY,[sItem])]));
                            }
                            
                        }
                        llSay(0, "> Completed parsing of the object's current contents.");
                        llSay(0, "> Start parsing any missing items");
                        llSleep(1);
                        osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","reassert_pin", "pin", iInstallPin]));
                        llSleep(1);
                        ix=0;
                        ixend = llGetListLength(lActualManifest);
                        for(ix=0;ix<ixend;ix+=2)
                        {
                            string sItem = llList2String(lActualManifest,ix);
                            string sItemJson = llList2String(lActualManifest,ix+1);
                            
                            string sItemType = llJsonGetValue(sItemJson, ["type"]);
                            string sItemLoc = llJsonGetValue(sItemJson,["location"]);
                            
                            PROCESS( kID,  sItem,  "",  sItemLoc,  object,  "",  iInstallPin,  "",  sItemType);
                            
                        }
                        llSay(0, "DONE WITH OBJECT : "+object);
                        llSay(0, "FMEM: "+(string)llGetFreeMemory());
                        osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd","done"]));
                        llSleep(1);
                        g_kLock = NULL;
                        llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd", "autoack", "product", object, "hash", llMD5String(objectManifest, 0x9f)]));
                        llSleep(1);
                        state VCSWaitDrop;
                    }
                }else{
                    llSay(0, "ERROR : NO MANIFEST FOUND FOR "+object+"\n[ Refusing to run updates ]");
                }
            }
        }
    }
}
state VCSOff{
    state_entry(){
        //llSleep(30);
        stopOthers();
        llSetTexture(TEXTURE_BLANK, ALL_SIDES);
        //llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT,["cmd","setack","script","VCSSlave[ZNI]"]));
        //llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","clearack"]));
        llSetText("Version Control Server\n[ZNI]\nTotal Inventory : "+(string)llGetInventoryNumber(INVENTORY_ALL)+"\n \n* OFF *\n"+(string)llGetFreeMemory(), <1,1,1>,1);
    }
    touch_start(integer t){
        llResetTime();
    }
    touch_end(integer t){
        if(llGetTime()>=5.0){
            llSay(0, "Telling all VCSSlaves to clear acknowledgement");
            llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","clearack"]));
        }
        llSay(0, "VCS now getting ready...please wait");
        state VCSOn;
    }
    changed(integer i){
        if(i&CHANGED_INVENTORY){
            stopOthers();
        }else if(i&CHANGED_REGION_START){
            llSleep (60);
            llResetScript();
        }
    }
    dataserver(key k,string d){
        llSay(0, "DROP : "+d);
    }
}