int
getsigbypos(int rel_x, char *text)
{
	return find_block_at(rel_x, text, 0, 0, NULL, NULL);
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
	int rel_x = a->x - (lrpad / 2);
	int bar_start_x = a->bar_x + (lrpad / 2);
	int ux = 0, uw = 0;
	statussig = find_block_at(rel_x, rawstext_right[0] ? rawstext_right : rawstext, bar_start_x, bar->bh, &ux, &uw);
	if (statussig > 0) {
		/* Toggle: Nếu click vào block đang mở dropdown, đóng nó và trả về -1 */
		if (active_block.sig == statussig) {
			if (active_block.win)
				killdropdown(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			active_block.screen_x = 0;
			active_block.bar_x = 0;
			drawbar(bar->mon);
			return -1;
		}

		/* Nếu đang mở dropdown của block khác, đóng cái cũ */
		if (active_block.win) {
			Window old_win = active_block.win;
			active_block.win = 0;
			killdropdown(old_win);
		}

		/* Ghi nhận signal và tính toán ngay tọa độ của block */
		active_block.sig = statussig;
		active_block.bar_x = ux;
		active_block.w = uw;
		active_block.screen_x = bar->mon->wx + ux;
		drawbar(bar->mon);
	}
	return ClkStatusText;
}

int
click_statuscmd_center(Bar *bar, Arg *arg, BarArg *a)
{
	int rel_x = a->x - (lrpad / 2);
	int bar_start_x = a->bar_x + (lrpad / 2);
	int ux = 0, uw = 0;
	statussig = find_block_at(rel_x, rawstext_center, bar_start_x, bar->bh, &ux, &uw);
	if (statussig > 0) {
		if (active_block.sig == statussig) {
			if (active_block.win)
				killdropdown(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			active_block.screen_x = 0;
			active_block.bar_x = 0;
			drawbar(bar->mon);
			return -1;
		}

		if (active_block.win) {
			Window old_win = active_block.win;
			active_block.win = 0;
			killdropdown(old_win);
		}

		active_block.sig = statussig;
		active_block.bar_x = ux;
		active_block.w = uw;
		active_block.screen_x = bar->mon->wx + ux;
		drawbar(bar->mon);
	}
	return ClkStatusText;
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
	int rel_x = a->x - (lrpad / 2);
	int bar_start_x = a->bar_x + (lrpad / 2);
	int ux = 0, uw = 0;
	int sig = find_block_at(rel_x, rawstext_right[0] ? rawstext_right : rawstext, bar_start_x, bar->bh, &ux, &uw);

	if (sig > 0 && uw > 0) {
		if (hover_block.sig != sig || hover_block.bar_x != ux || hover_block.w != uw) {
			hover_block.sig = sig;
			hover_block.bar_x = ux;
			hover_block.w = uw;
			drawbar(bar->mon);
		}
		return 1;
	} else if (hover_block.sig > 0) {
		hover_block.sig = 0;
		hover_block.bar_x = 0;
		hover_block.w = 0;
		drawbar(bar->mon);
	}
	return 0;
}

int
hover_statuscmd_center(Bar *bar, BarArg *a, XMotionEvent *ev)
{
	int rel_x = a->x - (lrpad / 2);
	int bar_start_x = a->bar_x + (lrpad / 2);
	int ux = 0, uw = 0;
	int sig = find_block_at(rel_x, rawstext_center, bar_start_x, bar->bh, &ux, &uw);

	if (sig > 0 && uw > 0) {
		if (hover_block.sig != sig || hover_block.bar_x != ux || hover_block.w != uw) {
			hover_block.sig = sig;
			hover_block.bar_x = ux;
			hover_block.w = uw;
			drawbar(bar->mon);
		}
		return 1;
	} else if (hover_block.sig > 0) {
		hover_block.sig = 0;
		hover_block.bar_x = 0;
		hover_block.w = 0;
		drawbar(bar->mon);
	}
	return 0;
}
