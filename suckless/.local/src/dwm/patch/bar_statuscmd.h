static int click_statuscmd(Bar *bar, Arg *arg, BarArg *a);
static int click_statuscmd_center(Bar *bar, Arg *arg, BarArg *a);
static int click_statuscmd_text(Arg *arg, int rel_x, char *text);
static int getsigbypos(int rel_x, char *text);
static int hover_statuscmd(Bar *bar, BarArg *a, XMotionEvent *ev);
static int hover_statuscmd_center(Bar *bar, BarArg *a, XMotionEvent *ev);
static void copyvalidchars(char *text, char *rawtext);

typedef struct {
	const char *cmd;
	int id;
} StatusCmd;

