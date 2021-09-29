// B-expressions.lsl
// Version 2.2  3 December 2020

string  FACE_TEX;
integer doFX = TRUE;
float   volume = 1.0;
string  laughSound = "laugh";
string  crySound = "cry";
string  mood;                     // Moods are SLEEP, WAKE, LAUGH, CRY
list expressions = [ 0.25, -0.75, // Asleep 0
                    -0.25,  0.25, // Awake  2
                    -0.25, -0.25, // Laugh  4
                     0.25, -0.25  // Cry    6
                    ];


default
{

    state_entry()
    {
        FACE_TEX = llGetTexture(ALL_SIDES);
        llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, FACE_TEX, <0.5, 0.5, 1>, <llList2Float(expressions, 2),llList2Float(expressions, 3),1>,  0.0 ]);
        mood = "WAKE";
    }

    link_message(integer sender_num, integer number, string message,key id)
    {
        list tk = llParseString2List(message, ["|"], []);
        string cmd = llList2String(tk, 0);

        if (cmd == "EXPRESSION")
        {
            number = -1;
            string expression = llList2String(tk, 1);
            if (expression == "SLEEP")
            {
                if (mood != "SLEEP")
                {
                    number = 0;
                    mood = "SLEEP";
                }
            }
            else if (expression == "WAKE")
            {
                if (mood != "WAKE")
                {
                    number = 2;
                    mood = "WAKE";
                }
            }
            else if (expression == "LAUGH")
            {
                if (mood != "LAUGH")
                {
                    number = 4;
                    mood = "LAUGH";
                    if (doFX == TRUE) llTriggerSound(laughSound, volume);
                }
            }
            else if (expression == "CRY")
            {
                if (mood != "CRY")
                {
                    number =  6;
                    mood = "CRY";
                    if (doFX == TRUE) llTriggerSound(crySound, volume);
                }
            }
            else
            {
                number = 2;
            }
            if (number != -1) llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, FACE_TEX, <0.5, 0.5, 1>, <llList2Float(expressions, number),llList2Float(expressions, number+1),1>,  0.0 ]);
            llSleep(2.0);
        }
        else if ((cmd == "HUNGER") || (cmd == "THIRST"))
        {
            if (mood != "SLEEP")
            {
                if (number > 50)
                {
                    if (mood != "CRY")
                    {
                        llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, FACE_TEX, <0.5, 0.5, 1>, <llList2Float(expressions, 6),llList2Float(expressions, 7),1>,  0.0 ]);
                        mood = "CRY";
                        if (doFX == TRUE) llTriggerSound(crySound, volume);
                    }
                }
                else if (number < 5)
                {
                    if (mood != "LAUGH")
                    {
                        llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, FACE_TEX, <0.5, 0.5, 1>, <llList2Float(expressions, 4),llList2Float(expressions, 5),1>,  0.0 ]);
                        mood = "LAUGH";
                        if (doFX == TRUE) llTriggerSound(laughSound, volume);
                    }
                }
                else
                {
                    if (mood != "WAKE")
                    {
                        llSetPrimitiveParams([PRIM_TEXTURE, ALL_SIDES, FACE_TEX, <0.5, 0.5, 1>, <llList2Float(expressions, 2),llList2Float(expressions, 3),1>,  0.0 ]);
                        mood = "WAKE";
                    }
                }
            }
        }
        else if (cmd == "CMD_CHATTY")
        {
            doFX = number;
            volume = 0.1 * llList2Float(tk, 1);
        }
    }


}
