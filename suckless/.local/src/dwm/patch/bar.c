void
barhover(XEvent *e, Bar *bar)
{
	const BarRule *br;
	Monitor *m = bar->mon;
	XMotionEvent *ev = &e->xmotion;
	BarArg barg = { 0, 0, 0, 0 };
	int r, hand = 0;

	for (r = 0; r < LENGTH(barrules); r++) {
		br = &barrules[r];
		if (br->bar != bar->idx || (br->monitor == 'A' && m != selmon))
			continue;
		if (br->monitor != 'A' && br->monitor != -1 && br->monitor != bar->mon->num)
			continue;
		if (bar->x[r] > ev->x || ev->x > bar->x[r] + bar->w[r])
			continue;

		barg.x = ev->x - bar->x[r];
		barg.y = ev->y - bar->borderpx;
		barg.w = bar->w[r];
		barg.h = bar->bh - 2 * bar->borderpx;
		barg.bar_x = bar->x[r];

		if (br->hoverfunc)
			hand = br->hoverfunc(bar, &barg, ev);
		break;
	}

	if (!hand && hover_block.sig > 0) {
		hover_block.sig = 0;
		hover_block.bar_x = 0;
		hover_block.w = 0;
		drawbar(bar->mon);
	}

	int cur = hand ? CurHand : CurNormal;
	if (bar->cursor != cur) {
		XDefineCursor(dpy, bar->win, cursor[cur]->cursor);
		bar->cursor = cur;
	}
}

Bar *
wintobar(Window win)
{
	Monitor *m;
	Bar *bar;
	for (m = mons; m; m = m->next)
		for (bar = m->bar; bar; bar = bar->next)
			if (bar->win == win)
				return bar;
	return NULL;
}
