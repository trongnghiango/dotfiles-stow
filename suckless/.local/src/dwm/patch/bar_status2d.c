static char termcol0[]  = "#000000"; /* black   */
static char termcol1[]  = "#ff0000"; /* red     */
static char termcol2[]  = "#33ff00"; /* green   */
static char termcol3[]  = "#ff0099"; /* yellow  */
static char termcol4[]  = "#0066ff"; /* blue    */
static char termcol5[]  = "#cc00ff"; /* magenta */
static char termcol6[]  = "#00ffff"; /* cyan    */
static char termcol7[]  = "#d0d0d0"; /* white   */
static char termcol8[]  = "#808080"; /* black   */
static char termcol9[]  = "#ff0000"; /* red     */
static char termcol10[] = "#33ff00"; /* green   */
static char termcol11[] = "#ff0099"; /* yellow  */
static char termcol12[] = "#0066ff"; /* blue    */
static char termcol13[] = "#cc00ff"; /* magenta */
static char termcol14[] = "#00ffff"; /* cyan    */
static char termcol15[] = "#ffffff"; /* white   */
static char *termcolor[] = {
	termcol0, termcol1, termcol2, termcol3, termcol4, termcol5, termcol6, termcol7,
	termcol8, termcol9, termcol10, termcol11, termcol12, termcol13, termcol14, termcol15,
};

int
width_status2d(Bar *bar, BarArg *a)
{
	int width;
	width = status2dtextlength(rawstext_right[0] ? rawstext_right : rawstext);
	return width ? width + lrpad : 0;
}

int
draw_status2d(Bar *bar, BarArg *a)
{
	return drawstatusbar(a, rawstext_right[0] ? rawstext_right : rawstext);
}

int
width_status2d_center(Bar *bar, BarArg *a)
{
	int width;
	width = status2dtextlength(rawstext_center);
	return width ? width + lrpad : 0;
}

int
draw_status2d_center(Bar *bar, BarArg *a)
{
	if (!rawstext_center[0])
		return 0;
	return drawstatusbar(a, rawstext_center);
}

int
drawstatusbar(BarArg *a, char* stext)
{
	int i, w, len;
	int x = a->x;
	int y = a->y;
	short isCode = 0;
	char stack_buf[1024];
	char *text;
	char *p;
	Clr oldbg, oldfg;
	len = strlen(stext);
	if (len + 1 <= sizeof(stack_buf))
		text = stack_buf;
	else if (!(text = (char*) malloc(sizeof(char)*(len + 1))))
		die("malloc");
	p = text;
	copyvalidchars(text, stext);

	x += lrpad / 2;
	drw_setscheme(drw, scheme[LENGTH(colors)]);
	drw->scheme[ColFg] = scheme[SchemeNorm][ColFg];
	drw->scheme[ColBg] = scheme[SchemeNorm][ColBg];

	/* process status text */
	i = -1;
	while (text[++i]) {
		if (text[i] == '^' && !isCode) {
			isCode = 1;

			text[i] = '\0';
			w = TEXTWM(text) - lrpad;
			drw_text(drw, x, y, w, bh, 0, text, 0, True);

			x += w;

			/* process code */
			while (text[++i] != '^') {
				if (text[i] == 'c') {
					char buf[8];
					if (i + 7 >= len) {
						i += 7;
						len = 0;
						break;
					}
					memcpy(buf, (char*)text+i+1, 7);
					buf[7] = '\0';
					drw_clr_create(drw, &drw->scheme[ColFg], buf);
					i += 7;
				} else if (text[i] == 'b') {
					char buf[8];
					if (i + 7 >= len) {
						i += 7;
						len = 0;
						break;
					}
					memcpy(buf, (char*)text+i+1, 7);
					buf[7] = '\0';
					drw_clr_create(drw, &drw->scheme[ColBg], buf);
					i += 7;
				} else if (text[i] == 'C') {
					int c = atoi(text + ++i) % 16;
					drw_clr_create(drw, &drw->scheme[ColFg], termcolor[c]);
				} else if (text[i] == 'B') {
					int c = atoi(text + ++i) % 16;
					drw_clr_create(drw, &drw->scheme[ColBg], termcolor[c]);
				} else if (text[i] == 'd') {
					drw->scheme[ColFg] = scheme[SchemeNorm][ColFg];
					drw->scheme[ColBg] = scheme[SchemeNorm][ColBg];
				} else if (text[i] == 'w') {
					Clr swp;
					swp = drw->scheme[ColFg];
					drw->scheme[ColFg] = drw->scheme[ColBg];
					drw->scheme[ColBg] = swp;
				} else if (text[i] == 'v') {
					oldfg = drw->scheme[ColFg];
					oldbg = drw->scheme[ColBg];
				} else if (text[i] == 't') {
					drw->scheme[ColFg] = oldfg;
					drw->scheme[ColBg] = oldbg;
				} else if (text[i] == 'r') {
					int rx = atoi(text + ++i);
					while (text[++i] != ',');
					int ry = atoi(text + ++i);
					while (text[++i] != ',');
					int rw = atoi(text + ++i);
					while (text[++i] != ',');
					int rh = atoi(text + ++i);

					if (ry < 0)
						ry = 0;
					if (rx < 0)
						rx = 0;

					drw_rect(drw, rx + x, y + ry, rw, rh, 1, 0);
				} else if (text[i] == 'f') {
					x += atoi(text + ++i);
				}
			}

			text = text + i + 1;
			len -= i + 1;
			i = -1;
			isCode = 0;
			if (len <= 0)
				break;
		}
	}
	if (!isCode && len > 0) {
		w = TEXTWM(text) - lrpad;
		drw_text(drw, x, y, w, bh, 0, text, 0, True);
		x += w;
	}
	if (p != stack_buf)
		free(p);

	if (active_block.win) {
		Client *dc = wintoclient(active_block.win);
		if (dc) {
			int dsig = dropdowntosig(dc->name);
			if (dsig > 0)
				active_block.sig = dsig;
		} else {
			active_block.win = 0;
			active_block.sig = 0;
			active_block.w = 0;
			active_block.screen_x = 0;
		}
	}
	if (active_block.sig > 0 && !active_block.win) {
		for (Client *k = selmon ? selmon->clients : NULL; k; k = k->next) {
			if (k->isdropdown) {
				active_block.win = k->win;
				active_block.sig = dropdowntosig(k->name);
				break;
			}
		}
	}

	/* Draw hover underline */
	if (hover_block.sig > 0 && hover_block.sig != active_block.sig && hover_block.w > 0) {
		drw_setscheme(drw, scheme[SchemeTagsNorm]);
		drw_rect(drw, hover_block.bar_x, bh - ulinestroke - ulinevoffset, hover_block.w, ulinestroke, 1, 0);
	}

	/* Draw active dropdown underline */
	if (active_block.sig > 0 && active_block.w > 0) {
		drw_setscheme(drw, scheme[LENGTH(colors)]);
		drw->scheme[ColFg] = scheme[SchemeTagsSel][ColBg];
		drw->scheme[ColBg] = scheme[SchemeTagsSel][ColBg];
		drw_rect(drw, active_block.bar_x, bh - ulinestroke - ulinevoffset, active_block.w, ulinestroke, 1, 0);
	}

	drw_setscheme(drw, scheme[SchemeNorm]);
	return 1;
}

int
status2dtextlength(char* stext)
{
	int i, w, len;
	short isCode = 0;
	char stack_buf[1024];
	char *text;
	char *p;

	len = strlen(stext) + 1;
	if (len <= sizeof(stack_buf))
		text = stack_buf;
	else if (!(text = (char*) malloc(sizeof(char)*len)))
		die("malloc");
	p = text;
	copyvalidchars(text, stext);

	/* compute width of the status text */
	w = 0;
	i = -1;
	while (text[++i]) {
		if (text[i] == '^') {
			if (!isCode) {
				isCode = 1;
				text[i] = '\0';
				w += TEXTWM(text) - lrpad;
				text[i] = '^';
				if (text[++i] == 'f')
					w += atoi(text + ++i);
			} else {
				isCode = 0;
				text = text + i + 1;
				i = -1;
			}
		}
	}
	if (!isCode)
		w += TEXTWM(text) - lrpad;
	if (p != stack_buf)
		free(p);
	return w;
}

int
parse_status_blocks(const char *rawtext, int bar_start_x, int bh, StatusBlock *blocks, int max_blocks)
{
	if (!rawtext || !blocks || max_blocks <= 0)
		return 0;

	char buf[1024];
	strncpy(buf, rawtext, sizeof(buf) - 1);
	buf[sizeof(buf) - 1] = '\0';

	char *p = buf;
	int count = 0;
	int cur_x = 0;

	while (*p && count < max_blocks) {
		if ((unsigned char)*p < ' ') {
			int sig = (unsigned char)*p;
			p++;
			char *start = p;
			while (*p && (unsigned char)*p >= ' ')
				p++;
			char saved = *p;
			*p = '\0';

			int full_w = status2dtextlength(start);

			char trimmed[1024];
			strncpy(trimmed, start, sizeof(trimmed) - 1);
			trimmed[sizeof(trimmed) - 1] = '\0';
			int tlen = strlen(trimmed);
			while (tlen > 0 && trimmed[tlen - 1] == ' ')
				trimmed[--tlen] = '\0';
			int icon_w = status2dtextlength(trimmed);

			*p = saved;

			if (icon_w > 0) {
				blocks[count].sig = sig;
				blocks[count].icon_x = cur_x;
				blocks[count].icon_w = icon_w;

				int uw = MAX(icon_w, bh);
				int ux = (bar_start_x + cur_x) - (uw - icon_w) / 2;
				blocks[count].u_x = ux;
				blocks[count].u_w = uw;

				cur_x += full_w;
				count++;
			}
		} else {
			p++;
		}
	}

	for (int i = 0; i < count; i++) {
		if (i == 0) {
			blocks[i].hit_x0 = -100;
		} else {
			int prev_icon_end = blocks[i - 1].icon_x + blocks[i - 1].icon_w;
			int cur_icon_start = blocks[i].icon_x;
			blocks[i].hit_x0 = (prev_icon_end + cur_icon_start) / 2;
			blocks[i - 1].hit_x1 = blocks[i].hit_x0;
		}
	}
	if (count > 0) {
		blocks[count - 1].hit_x1 = cur_x + 100;
	}

	return count;
}

int
find_block_at(int rel_x, const char *rawtext, int bar_start_x, int bh, int *out_ux, int *out_uw)
{
	StatusBlock blocks[16];
	int count = parse_status_blocks(rawtext, bar_start_x, bh, blocks, 16);

	for (int i = 0; i < count; i++) {
		if (rel_x >= blocks[i].hit_x0 && rel_x < blocks[i].hit_x1) {
			if (out_ux) *out_ux = blocks[i].u_x;
			if (out_uw) *out_uw = blocks[i].u_w;
			return blocks[i].sig;
		}
	}
	return 0;
}

int
calblockpos(Monitor *m, int sig, int *out_screen_x, int *out_w)
{
	if (!m || sig <= 0)
		return 0;

	StatusBlock blocks[16];

	/* 1. Thử tìm trong rawstext_center */
	if (rawstext_center[0]) {
		int bar_x = 0;
		for (Bar *bar = m->bar; bar; bar = bar->next) {
			for (int r = 0; r < LENGTH(barrules); r++) {
				if (barrules[r].drawfunc == draw_status2d_center) {
					bar_x = bar->x[r];
					break;
				}
			}
		}
		int bar_start_x = bar_x + (lrpad / 2);
		int count = parse_status_blocks(rawstext_center, bar_start_x, bh, blocks, 16);
		for (int i = 0; i < count; i++) {
			if (blocks[i].sig == sig) {
				active_block.bar_x = blocks[i].u_x;
				active_block.w = blocks[i].u_w;
				active_block.screen_x = (selmon ? selmon->wx : 0) + blocks[i].u_x;
				if (out_screen_x) *out_screen_x = active_block.screen_x;
				if (out_w) *out_w = blocks[i].u_w;
				return 1;
			}
		}
	}

	/* 2. Thử tìm trong rawstext_right (hoặc rawstext) */
	char *right_text = rawstext_right[0] ? rawstext_right : rawstext;
	if (right_text && right_text[0]) {
		int bar_x = 0;
		for (Bar *bar = m->bar; bar; bar = bar->next) {
			for (int r = 0; r < LENGTH(barrules); r++) {
				if (barrules[r].drawfunc == draw_status2d) {
					bar_x = bar->x[r];
					break;
				}
			}
		}
		int bar_start_x = bar_x + (lrpad / 2);
		int count = parse_status_blocks(right_text, bar_start_x, bh, blocks, 16);
		for (int i = 0; i < count; i++) {
			if (blocks[i].sig == sig) {
				active_block.bar_x = blocks[i].u_x;
				active_block.w = blocks[i].u_w;
				active_block.screen_x = (selmon ? selmon->wx : 0) + blocks[i].u_x;
				if (out_screen_x) *out_screen_x = active_block.screen_x;
				if (out_w) *out_w = blocks[i].u_w;
				return 1;
			}
		}
	}

	return 0;
}

