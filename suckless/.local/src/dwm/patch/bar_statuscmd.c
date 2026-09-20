int
getsigbypos(int rel_x, char *text)
{
	int i = -1, x = 0;
	char ch;
	int sig = -1;

	if (rel_x < 0 || !text)
		return 0;

	while (text[++i]) {
		if ((unsigned char)text[i] < ' ') {
			ch = text[i];
			text[i] = '\0';
			int w = status2dtextlength(text);
			x += w;
			text[i] = ch;
			text += i + 1;
			i = -1;
			if (x >= rel_x && sig != -1)
				break;
			sig = ch;
		}
	}
	if (sig > 0) {
		int w = status2dtextlength(text);
		x += w;
		if (rel_x > x)
			sig = 0;
	} else {
		sig = 0;
	}
	return sig > 0 ? sig : 0;
}

int
click_statuscmd_text(Arg *arg, int rel_x, char *text)
{
	statussig = getsigbypos(rel_x, text);
	return ClkStatusText;
}
int
click_statuscmd(Bar *bar, Arg *arg, BarArg *a)
{
	int res = click_statuscmd_text(arg, a->x - (lrpad / 2), rawstext_right[0] ? rawstext_right : rawstext);
	if (statussig > 0) {
		/* Toggle: Nếu click vào block đang mở dropdown (hoặc đang mở), đóng nó và trả về -1 */
		if (active_block.sig == statussig) {
			if (active_block.win)
				killdropdown(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			drawbar(bar->mon);
			return -1;
		}

		/* Nếu đang mở dropdown của block khác, đóng cái cũ */
		if (active_block.win) {
			Window old_win = active_block.win;
			active_block.win = 0;
			killdropdown(old_win);
		}

		/* Ghi nhận signal của block và vẽ lại statusbar */
		active_block.sig = statussig;
		drawbar(bar->mon);
	}
	return res;
}

int
click_statuscmd_center(Bar *bar, Arg *arg, BarArg *a)
{
	int res = click_statuscmd_text(arg, a->x - (lrpad / 2), rawstext_center);
	if (statussig > 0) {
		if (active_block.sig == statussig) {
			if (active_block.win)
				killdropdown(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			drawbar(bar->mon);
			return -1;
		}

		if (active_block.win) {
			Window old_win = active_block.win;
			active_block.win = 0;
			killdropdown(old_win);
		}

		active_block.sig = statussig;
		drawbar(bar->mon);
	}
	return res;
}

void
copyvalidchars(char *text, char *rawtext)
{
	int i = -1, j = 0;

	while (rawtext[++i]) {
		if ((unsigned char)rawtext[i] >= ' ') {
			text[j++] = rawtext[i];
		}
	}
	text[j] = '\0';
}

int
hover_statuscmd(Bar *bar, BarArg *a, XMotionEvent *ev)
{
	return getsigbypos(a->x - (lrpad / 2), rawstext_right[0] ? rawstext_right : rawstext) > 0;
}

int
hover_statuscmd_center(Bar *bar, BarArg *a, XMotionEvent *ev)
{
	return getsigbypos(a->x - (lrpad / 2), rawstext_center) > 0;
}

