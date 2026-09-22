int
find_block_at(int rel_x, const char *rawtext, int *out_x, int *out_w)
{
	if (!rawtext || rel_x < 0)
		return 0;

	char buf[1024];
	strncpy(buf, rawtext, sizeof(buf) - 1);
	buf[sizeof(buf) - 1] = '\0';

	char *p = buf;
	int cur_x = 0;
	int cur_sig = 0;

	while (*p) {
		if ((unsigned char)*p < ' ') {
			cur_sig = (unsigned char)*p;
			p++;
			char *start = p;
			while (*p && (unsigned char)*p >= ' ')
				p++;
			char saved = *p;
			*p = '\0';
			int w = status2dtextlength(start);
			*p = saved;

			if (rel_x >= cur_x && rel_x < cur_x + w) {
				if (out_x) *out_x = cur_x;
				if (out_w) *out_w = w;
				return cur_sig;
			}
			cur_x += w;
		} else {
			p++;
		}
	}
	return 0;
}

int
getsigbypos(int rel_x, char *text)
{
	return find_block_at(rel_x, text, NULL, NULL);
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
		/* Toggle: Nếu click vào block đang mở dropdown, đóng nó và trả về -1 */
		if (active_block.sig == statussig) {
			if (active_block.win)
				killdropdown(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			active_block.screen_x = 0;
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
		calblockpos(bar->mon, statussig, &active_block.screen_x, &active_block.w);
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
			active_block.screen_x = 0;
			drawbar(bar->mon);
			return -1;
		}

		if (active_block.win) {
			Window old_win = active_block.win;
			active_block.win = 0;
			killdropdown(old_win);
		}

		active_block.sig = statussig;
		calblockpos(bar->mon, statussig, &active_block.screen_x, &active_block.w);
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
	int bx = 0, bw = 0;
	int rel_x = a->x - (lrpad / 2);
	char *text = rawstext_right[0] ? rawstext_right : rawstext;
	int sig = find_block_at(rel_x, text, &bx, &bw);

	if (sig > 0 && bw > 0) {
		int uw = MAX(bw, bar->bh);
		int bar_module_x = ev->x - a->x;
		int final_bar_x = bar_module_x + (a->x - rel_x + bx) - (uw - bw) / 2;

		if (hover_block.sig != sig || hover_block.bar_x != final_bar_x || hover_block.w != uw) {
			hover_block.sig = sig;
			hover_block.bar_x = final_bar_x;
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
	int bx = 0, bw = 0;
	int rel_x = a->x - (lrpad / 2);
	char *text = rawstext_center;
	int sig = find_block_at(rel_x, text, &bx, &bw);

	if (sig > 0 && bw > 0) {
		int uw = MAX(bw, bar->bh);
		int bar_module_x = ev->x - a->x;
		int final_bar_x = bar_module_x + (a->x - rel_x + bx) - (uw - bw) / 2;

		if (hover_block.sig != sig || hover_block.bar_x != final_bar_x || hover_block.w != uw) {
			hover_block.sig = sig;
			hover_block.bar_x = final_bar_x;
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

