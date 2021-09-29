// --------------------------------------
//  QUINTONIA FARM HUD - Animal scanner
// --------------------------------------
// INFO
// Scans and queries animals to get statistics for numbers of male & female as well as overall hunger, thirst and happiness levels
//
float version = 5.0;   // 21 September 2020

string animalName;
string PASSWORD;

integer animalCount;
integer totalAnimals;
integer maleCount;
integer femaleCount;
integer happyCount;
integer foodCount;
integer waterCount;

float scanRadius;

giveStats()
{

    if (animalCount != totalAnimals)
    {
        llSetTimerEvent(2.0);
        return;
    }
    llSetTimerEvent(0);

    string response = "SCAN_REPLY|";

    response += (string)totalAnimals + "|";
    response += (string)femaleCount + "|";
    response += (string)maleCount + "|";

    integer happy = (happyCount/totalAnimals);
    integer food = 100 - (foodCount/totalAnimals);
    integer water =100 - (waterCount/totalAnimals);

    response += (string)happy + "|";
    response += (string)food + "|";
    response += (string)water + "|";

    llMessageLinked(LINK_SET, 1, response, "");
    happyCount = 0;
    foodCount = 0;
    waterCount = 0;
}


// ========== //

default
{
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        scanRadius = 96.0;
    }

    link_message(integer sender_num, integer num, string msg, key id)
    {
        list tk = llParseStringKeepNulls(msg , ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "CMD_SCAN")
        {
            totalAnimals = 0;
            animalCount = 0;
            maleCount = 0;
            femaleCount = 0;
            happyCount = 0;
            foodCount = 0;
            waterCount = 0;
            animalName = llList2String(tk,1);
            scanRadius = llList2Float(tk,2);
            if (animalName == "SF DEAD") animalName = "DEAD";
            llSensor(animalName, "", SCRIPTED, scanRadius, PI);
        }
    }


    dataserver(key id, string msg)
    {
        list res = llParseString2List(msg, ["|"], []);
        if (llList2String(res,1) != PASSWORD)
        {
            return;
        }

        string command = llList2String(res, 0);

        if (command == "STATS-REPLY")
        {
            animalCount++;
            // answer is:  CMD|P/W|sex|happy|food|water
            string  sex   = llList2String(res, 2);
            integer happy = llList2Integer(res, 3);
            if (happy <0) happy = 0;
            integer food  = llList2Integer(res, 4);
            if (food <0) food = 0;
            integer water = llList2Integer(res, 5);
            if (water <0) water = 0;
            if (sex == "Male") maleCount++; else femaleCount++;
            happyCount += happy;
            foodCount += food;
            waterCount += water;
            giveStats();
        }
    }

    sensor(integer n)
    {
        totalAnimals = n;
        integer i;
        if (animalName != "DEAD")
        {
            for (i=0; i < n; i++)
            {
                key u = llDetectedKey(i);
                list desc = llParseString2List(llList2String(llGetObjectDetails(u, [OBJECT_DESC]) , 0) , [";"], []);
                llSay(0, "--> " + llList2String(desc, 10)+ " " + (string)(i+1));
                osMessageObject(u, "STATS-CHECK|"+PASSWORD+"|"+(string)llGetKey()+"|animal");
                llSleep(2);
            }
        }
        else
        {
            femaleCount = 0;
            maleCount = 0;
            for (i=0; i < n; i++)
            {
                key u = llDetectedKey(i);
                list desc = llParseString2List(llList2String(llGetObjectDetails(u, [OBJECT_DESC]) , 0) , [";"], []);
                if (llList2Integer(desc, 1) == 1) femaleCount +=1; else maleCount +=1;
            }
            totalAnimals = n;
            animalCount = n;
            happyCount = 0;
            foodCount = 0;
            waterCount = 0;
            giveStats();
        }
    }

    no_sensor()
    {
        llSay(0, animalName + "=0");
        llMessageLinked(LINK_SET, 0, "SCAN_REPLY|", "");
    }

    timer()
    {
        llSetTimerEvent(0);
        giveStats();
    }

}
