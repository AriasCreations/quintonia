// addon-byprod.lsl

// This is an addon that works with the 'plant'lsl' script.
// It displays float text showing all by-products that are at 100%
//
// Version 1.0     23 November 2020

vector GREEN = <0.180, 0.800, 0.251>;

default
{
    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "BP_READY")
        {
            llSetText(llList2String(tok,1), GREEN, 1.0);
        }
        else if (cmd == "RESET") // Main script reset
        {
            llSetText("", ZERO_VECTOR, 0.0);
        }
    }

}
