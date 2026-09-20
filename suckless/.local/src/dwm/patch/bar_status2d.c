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
	char *text;
	char *p;
	Clr oldbg, oldfg;
	len = strlen(stext);
	if (!(text = (char*) malloc(sizeof(char)*(len + 1))))
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
	free(p);

	if (active_block.win) {
		Client *dc = wintoclient(active_block.win);
		if (dc) {
			int dsig = dropdowntosig(dc->name);
			if (dsig > 0)
				active_block.sig = dsig;
		}
	}

	if (active_block.sig > 0) {
		char rtext[1024];
		strncpy(rtext, stext, sizeof(rtext) - 1);
		rtext[sizeof(rtext) - 1] = '\0';
		char *t = rtext;
		int bx = 0, ti = -1, cur_sig = -1;
		int found = 0, ab_x = 0, ab_w = 0;
		int bar_start_x = a->x + (lrpad / 2);

		while (t[++ti]) {
			if ((unsigned char)t[ti] < ' ') {
				char ch = t[ti];
				t[ti] = '\0';
				if (cur_sig > 0) {
					int tw = status2dtextlength(t);
					if (cur_sig == active_block.sig) {
						char trimmed[1024];
						strncpy(trimmed, t, sizeof(trimmed) - 1);
						trimmed[sizeof(trimmed) - 1] = '\0';
						int tlen = strlen(trimmed);
						while (tlen > 0 && trimmed[tlen - 1] == ' ')
							trimmed[--tlen] = '\0';
						ab_x = bx;
						ab_w = status2dtextlength(trimmed);
						found = 1;
						break;
					}
					bx += tw;
				}
				t[ti] = ch;
				t += ti + 1;
				ti = -1;
				cur_sig = (unsigned char)ch;
			}
		}
		if (!found && cur_sig > 0) {
			if (cur_sig == active_block.sig) {
				char trimmed[1024];
				strncpy(trimmed, t, sizeof(trimmed) - 1);
				trimmed[sizeof(trimmed) - 1] = '\0';
				int tlen = strlen(trimmed);
				while (tlen > 0 && trimmed[tlen - 1] == ' ')
					trimmed[--tlen] = '\0';
				ab_x = bx;
				ab_w = status2dtextlength(trimmed);
				found = 1;
			}
		}
		if (found && ab_w > 0) {
			int uw = MAX(ab_w, bh);
			int ux = (bar_start_x + ab_x) - (uw - ab_w) / 2;
			active_block.bar_x = ux;
			active_block.w = uw;
			active_block.screen_x = (selmon ? selmon->wx : 0) + active_block.bar_x;
			drw_setscheme(drw, scheme[LENGTH(colors)]);
			drw->scheme[ColFg] = scheme[SchemeTagsSel][ColBg];
			drw->scheme[ColBg] = scheme[SchemeTagsSel][ColBg];
			drw_rect(drw, ux, bh - ulinestroke - ulinevoffset, uw, ulinestroke, 1, 0);

			if (active_block.win) {
				Client *dc = wintoclient(active_block.win);
				if (dc && dc->mon) {
					int drop_x = active_block.screen_x;
					int max_x = dc->mon->wx + dc->mon->ww - WIDTH(dc);
					if (drop_x > max_x)
						drop_x = max_x;
					if (drop_x < dc->mon->wx)
						drop_x = dc->mon->wx;
					if (dc->x != drop_x && drop_x > 0) {
						dc->x = drop_x;
						XMoveWindow(dpy, dc->win, dc->x, dc->y);
					}
				}
			}
		}
	}

	drw_setscheme(drw, scheme[SchemeNorm]);
	return 1;
}

int
status2dtextlength(char* stext)
{
	int i, w, len;
	short isCode = 0;
	char *text;
	char *p;

	len = strlen(stext) + 1;
	if (!(text = (char*) malloc(sizeof(char)*len)))
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
	free(p);
	return w;
}

