typedef struct {
	int sig;
	int icon_x;
	int icon_w;
	int u_x;
	int u_w;
	int hit_x0;
	int hit_x1;
} StatusBlock;

static int width_status2d(Bar *bar, BarArg *a);
static int draw_status2d(Bar *bar, BarArg *a);
static int width_status2d_center(Bar *bar, BarArg *a);
static int draw_status2d_center(Bar *bar, BarArg *a);
static int drawstatusbar(BarArg *a, char *text);
static int status2dtextlength(char *stext);
static int parse_status_blocks(const char *rawtext, int bar_start_x, int bh, StatusBlock *blocks, int max_blocks);
static int find_block_at(int rel_x, const char *rawtext, int bar_start_x, int bh, int *out_ux, int *out_uw);
static int calblockpos(Monitor *m, int sig, int *out_screen_x, int *out_w);

