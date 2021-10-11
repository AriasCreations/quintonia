#include "MasterFile.lsl"


integer ZNI_CHANNEL = 0x9f99F;
key g_kAcked;
integer g_iAcked=0;
key g_kAssert;

SetRunning(){
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
    for(i=0;i<end;i++){
        string script =llGetInventoryName(INVENTORY_SCRIPT,i);
        if(!llGetScriptState(script)){
            llSetScriptState(script,TRUE);
        }
    }
}
ResetScripts()
{
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
    for(i=0;i<end;i++){
        string script = llGetInventoryName(INVENTORY_SCRIPT,i);
        if(script!=llGetScriptName())llResetOtherScript(script);
    }
}

string GetManifest()
{
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_ALL);
    string Manifest;
    for(i=0;i<end;i++){
        string item = llGetInventoryName(INVENTORY_ALL, i);
        if(item!=llGetScriptName()){
            string sType = "other";
            string sLoc = "inventory";
            string sHash = "";
            integer iType = llGetInventoryType(item);
            if(iType == INVENTORY_SCRIPT) {
                sType = "script";
            }else if(iType == INVENTORY_NOTECARD){
                sType = "notecard";
                sLoc = "global";
                sHash = llMD5String(osGetNotecard(item), 0);
            }
            key kInv = llGetInventoryKey(item);
            string ItemJson = llList2Json(JSON_OBJECT,["type", sType,"location",sLoc,"key",kInv, "D", osGetInventoryDesc(item), "hash", sHash]);
            Manifest = llJsonSetValue(Manifest,["inventory", item], ItemJson);
        }
    }
    
    return Manifest;
}
default
{
    state_entry()
    {
        if(llGetStartParameter()!=0){
            llSay(0, "Install/Update completed");
            llSetRemoteScriptAccessPin(0);
        }
        llListen(ZNI_CHANNEL, "", "", "");
        // Now send a signal to the VCS
        llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","ready4vcs"]));
        
    }
    on_rez(integer t){
        g_kAcked=NULL; // Expire ack as we've been rezzed.
        // Now send a signal to the VCS
        llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","ready4vcs"]));
    }
    dataserver(key kID, string sData){
        //llSay(0, "DATASERVER : "+(string)kID+"; "+sData);
        vector pos = llList2Vector(llGetObjectDetails(kID,[OBJECT_POS]),0);
        if(pos==ZERO_VECTOR){
            if(HasDSRequest(kID)!=-1){
                // Handle my own request
            }
        }else {
            // Handle osMsgObj
            if(llJsonGetValue(sData, ["cmd"])=="setack"){
                if(llJsonGetValue(sData,["script"])==llGetScriptName()){
                    g_kAcked = kID;
                    g_iAcked=llGetUnixTime();
                }
            } else if(llJsonGetValue(sData,["cmd"])=="set_pin"){
                if(llJsonGetValue(sData,["script"])==llGetScriptName()){
                    integer pin = llRound(llFrand(ZNI_CHANNEL)); // use this as the seed!
                    llSetRemoteScriptAccessPin(pin);
                    llAllowInventoryDrop(TRUE);
                    osMessageObject(kID, llList2Json(JSON_OBJECT, ["cmd", "pin_ready", "pin", pin, "script", llGetScriptName()]));
                }
            } else if(llJsonGetValue(sData,["cmd"])=="deprecate"){
                if(llGetScriptName()==llJsonGetValue(sData,["script"])){
                    llRemoveInventory(llGetScriptName()); // Dont unset the pin!
                }
            } else if(llJsonGetValue(sData,["cmd"])=="get_manifest"){
                // Make the manifest of the current inventory
                llAllowInventoryDrop(TRUE);
                integer pin = llRound(llFrand(ZNI_CHANNEL));
                llSetRemoteScriptAccessPin(pin);

                
                osMessageObject(kID, llList2Json(JSON_OBJECT,["cmd","manifest_response", "script", llGetScriptName(), "manifest", GetManifest(), "object", llGetObjectName(), "pin", pin]));
            } else if(llJsonGetValue(sData,["cmd"])=="remove_item"){
                // this will not include a script ID, as it is targetted at the entire object
                list items = llJson2List(llJsonGetValue(sData,["items"]));
                integer i=0;
                integer end = llGetListLength(items);
                for(i=0;i<end;i++){
                    string itemName = llList2String(items,i);
                    if(itemName!=llGetScriptName()){
                        llRemoveInventory(itemName);
                    }
                }
            } else if(llJsonGetValue(sData,["cmd"])=="done"){
                llAllowInventoryDrop(FALSE);
                llSetRemoteScriptAccessPin(0);
                g_kAssert=(NULL)+(string)(llFrand(5478374)); // ensure no one can guess this to be able to run reassert_pin as a backdoor!
                SetRunning();
                ResetScripts();
            } else if(llJsonGetValue(sData,["cmd"])=="rename_object"){
                llSetObjectName(llJsonGetValue(sData,["name"]));
                llSleep(2);
                llRegionSay(ZNI_CHANNEL, llList2Json(JSON_OBJECT, ["cmd","ready4vcs"]));
            } else if(llJsonGetValue(sData,["cmd"])=="make_notecard"){
                list lLines = llJson2List(llJsonGetValue(sData,["contents"]));
                integer x=0;
                integer xe = llGetListLength(lLines);
                for(x=0;x<xe;x++){
                    lLines[x] = llBase64ToString(llList2String(lLines,x));
                }
                osMakeNotecard(llJsonGetValue(sData,["name"]), lLines);
            } else if(llJsonGetValue(sData,["cmd"])=="reassert_pin"){
                llSetRemoteScriptAccessPin((integer)llJsonGetValue(sData,["pin"]));
                llAllowInventoryDrop(TRUE);
            }
        }
    }
    listen(integer c,string n,key i,string m){
        if(llJsonGetValue(m,["cmd"])=="versions"){
            if(g_kAcked!=NULL){
                return; // For now just exit this code.. don't auto expire the ack.
                if(llGetUnixTime()>=g_iAcked+(12*(60*60))){
                    g_kAssert=i;
                    g_kAcked=NULL;
                    g_iAcked=0;
                }else return;
            }
            osMessageObject(i,llList2Json(JSON_OBJECT,["cmd","version_reply","script",llGetScriptName(),"version",osGetInventoryDesc(llGetScriptName())]));
        } else if(llJsonGetValue(m,["cmd"])=="clearack"){
            g_kAcked=NULL;
            g_iAcked=0;
            g_kAssert=(NULL)+(string)(llFrand(5483547));
        } else if(llJsonGetValue(m,["cmd"])=="autoack")
        {
            if(llJsonGetValue(m,["product"])==llGetObjectName())
            {
                sHash = llJsonGetValue(m,["hash"]);
                if(llMD5String(GetManifest(),0x9f) == sHash)
                {
                    g_kAcked = i;
                    g_iTicked=llGetUnixTime();
                    
                }
            }
        }
    }
}