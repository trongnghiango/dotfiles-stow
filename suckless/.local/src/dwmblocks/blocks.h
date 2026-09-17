// Modify this file to change what commands output to your statusbar, and
// recompile using the make command.
static const Block blocks[] = {
    /*Icon*/ /*Command*/ /*Update Interval*/ /*Update Signal*/
                                             /*	{"",		"vap-volume",		1,			10},
                                                     {"",		"vap-clock",		60,
                                                1},
                                                     {"",		"vap-internet",		5,
                                                4},
                                                     {"",		"sb-doppler",		0,
                                                13},
                                                     {"",		"sb-mailbox",		180,		12},
                                             */
    {"", "ka-forecast", 1800, 14},
    {"", "ka-memory", 10, 10},
    {"", "ka-cpu", 2, 15},
    {"", "ka-network", 10, 4},
    {"", "ka-battery", 60, 30},
    {"", "ka-volume", 60, 11},
    {"", "sb-record", 0, 9},
    {"", "ka-clock", 60, 1}

};

// sets delimiter between status commands. NULL character ('\0') means no
// delimiter.
static char delim[] = "  ";
static unsigned int delimLen = 7;
