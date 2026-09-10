static int last_block_x = 0;
static int last_block_w = 0;

int
click_statuscmd_text(Arg *arg, int rel_x, char *text)
{
	int i = -1;
	int x = 0;
	int prev_x = 0;
	char ch;
	statussig = -1;
	last_block_x = 0;
	last_block_w = 0;

	while (text[++i]) {
		if ((unsigned char)text[i] < ' ') {
			ch = text[i];
			text[i] = '\0';
			int w = status2dtextlength(text);
			x += w;
			text[i] = ch;
			text += i+1;
			i = -1;
			if (x >= rel_x && statussig != -1) {
				last_block_x = prev_x;
				last_block_w = x - prev_x;
				break;
			}
			prev_x = x;
			statussig = ch;
		}
	}
	if (statussig != -1 && last_block_w == 0) {
		int w = status2dtextlength(text);
		x += w;
		if (x >= rel_x) {
			last_block_x = prev_x;
			last_block_w = x - prev_x;
		}
	}
	if (statussig == -1)
		statussig = 0;
	return ClkStatusText;
}

int
click_statuscmd(Bar *bar, Arg *arg, BarArg *a)
{
	int res = click_statuscmd_text(arg, a->x - (lrpad / 2), rawstext);
	if (statussig > 0 && last_block_w > 0) {
		/* Toggle: Nếu click vào block đang mở dropdown, đóng nó và trả về -1 */
		if (active_block.sig == statussig && active_block.win) {
			closewindow(active_block.win);
			active_block.sig = 0;
			active_block.win = 0;
			active_block.w = 0;
			drawbar(bar->mon);
			return -1;
		}

		/* Nếu đang mở dropdown của block khác, đóng cái cũ */
		if (active_block.win) {
			closewindow(active_block.win);
			active_block.win = 0;
		}

		/* Ghi nhận toạ độ và kích thước của block */
		active_block.sig = statussig;
		active_block.bar_x = a->bar_x + (lrpad / 2) + last_block_x;
		active_block.screen_x = bar->bx + active_block.bar_x;
		active_block.w = last_block_w;
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

