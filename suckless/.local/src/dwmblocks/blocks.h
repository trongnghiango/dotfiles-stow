//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
/*	{"",		"vap-volume",		1,			10},
	{"",		"vap-clock",		60,			1},
	{"",		"vap-internet",		5,			4},
	{"",		"sb-doppler",		0,			13},
	{"",		"sb-mailbox",		180,		12},
*/
	{"",		"vap-forecast",		1800,			14},
	{"",		"vap-memory",		9,			10},
	{"",		"vap-cpu",			1,			15},
	{"",		"sb-nettraf",		5,			18},
	{"",		"vap-volume",		10,			11},
	{"",		"sb-clock",			60,			1},
	{"",		"sb-internet",		15,			4}

	
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = "  ";
static unsigned int delimLen = 7;
