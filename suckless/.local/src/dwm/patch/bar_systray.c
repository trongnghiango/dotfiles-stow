static Systray *systray = NULL;
static unsigned long systrayorientation = _NET_SYSTEM_TRAY_ORIENTATION_HORZ;
static int systraycollapsed = 1;
#ifndef SYSTRAY_MAX_ICONS
#define SYSTRAY_MAX_ICONS 0
#endif

static inline const char *
systray_btn_text(void)
{
	return systraycollapsed
		? (systray_icon_collapsed ? systray_icon_collapsed : "")
		: (systray_icon_expanded  ? systray_icon_expanded  : "");
}

int
width_systray(Bar *bar, BarArg *a)
{
	unsigned int w = 0;
	Client *i;
	int n = 0, count = 0, tw = 0;
	if (!systray)
		return 1;
	if (showsystray) {
		for (i = systray->icons; i; i = i->next) n++;
		if (n > SYSTRAY_MAX_ICONS) {
			tw = drw_fontset_getwidth(drw, systray_btn_text(), False);
		}
		for (i = systray->icons; i; i = i->next) {
			if (systraycollapsed && count >= SYSTRAY_MAX_ICONS)
				break;
			w += i->w + systrayspacing;
			count++;
		}
		if (w > 0)
			w -= systrayspacing;
		if (tw > 0 && w > 0)
			w += systrayspacing;
		w += tw;
		if (!w)
			XMoveWindow(dpy, systray->win, -systray->h, bar->by);
	}
	return w;
}

int
draw_systray(Bar *bar, BarArg *a)
{
	if (!showsystray)
		return 0;

	XSetWindowAttributes wa;
	XWindowChanges wc;
	Client *i;
	unsigned int w;
	int n = 0, count = 0, tw = 0;
	unsigned int visible_w = 0;

	if (!systray) {
		/* init systray */
		if (!(systray = (Systray *)calloc(1, sizeof(Systray))))
			die("fatal: could not malloc() %u bytes\n", sizeof(Systray));

		wa.override_redirect = True;
		wa.event_mask = ButtonPressMask|ExposureMask;
		wa.border_pixel = 0;
		systray->h = a->h;
		wa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
		systray->win = XCreateSimpleWindow(dpy, root, bar->bx + a->x, -systray->h, MIN(a->w, 1), systray->h, 0, 0, scheme[SchemeNorm][ColBg].pixel);
		XChangeWindowAttributes(dpy, systray->win, CWOverrideRedirect|CWBackPixel|CWBorderPixel|CWEventMask, &wa);

		XSelectInput(dpy, systray->win, SubstructureNotifyMask);
		XChangeProperty(dpy, systray->win, netatom[NetSystemTrayOrientation], XA_CARDINAL, 32,
				PropModeReplace, (unsigned char *)&systrayorientation, 1);
		XChangeProperty(dpy, systray->win, netatom[NetWMWindowType], XA_ATOM, 32,
				PropModeReplace, (unsigned char *)&netatom[NetWMWindowTypeDock], 1);
		Visual *v = DefaultVisual(dpy, screen);
		XChangeProperty(dpy, systray->win, netatom[NetSystemTrayVisual], XA_VISUALID, 32,
				PropModeReplace, (unsigned char *)&v->visualid, 1);
		XMapRaised(dpy, systray->win);
		XSetSelectionOwner(dpy, netatom[NetSystemTray], systray->win, CurrentTime);
		if (XGetSelectionOwner(dpy, netatom[NetSystemTray]) == systray->win) {
			sendevent(root, xatom[Manager], StructureNotifyMask, CurrentTime, netatom[NetSystemTray], systray->win, 0, 0);
			XSync(dpy, False);
		} else {
			fprintf(stderr, "dwm: unable to obtain system tray.\n");
			free(systray);
			systray = NULL;
			return 0;
		}
	} else {
		systray->h = a->h;
	}

	systray->bar = bar;

	wc.stack_mode = Above;
	wc.sibling = bar->win;
	XConfigureWindow(dpy, systray->win, CWSibling|CWStackMode, &wc);

	/* Synchronize systray container background with bar SchemeNorm only on color change */
	static unsigned long last_systray_bg = 0;
	if (last_systray_bg != scheme[SchemeNorm][ColBg].pixel) {
		last_systray_bg = scheme[SchemeNorm][ColBg].pixel;
		wa.background_pixel = last_systray_bg;
		XChangeWindowAttributes(dpy, systray->win, CWBackPixel, &wa);
		XSetWindowBackground(dpy, systray->win, last_systray_bg);
		XClearWindow(dpy, systray->win);
	}

	/* Broadcast tray colors for monochrome/symbolic icon tinting */
	XColor norm_fg;
	norm_fg.pixel = scheme[SchemeNorm][ColFg].pixel;
	XQueryColor(dpy, DefaultColormap(dpy, screen), &norm_fg);
	uint32_t tray_colors[4] = {
		((norm_fg.red >> 8) << 16) | ((norm_fg.green >> 8) << 8) | (norm_fg.blue >> 8),
		0xcc241d,
		0xd79921,
		0x98971a
	};
	Atom net_systray_colors = XInternAtom(dpy, "_NET_SYSTEM_TRAY_COLORS", False);
	XChangeProperty(dpy, systray->win, net_systray_colors, XA_CARDINAL, 32,
	                PropModeReplace, (unsigned char *)tray_colors, 4);

	for (i = systray->icons; i; i = i->next) n++;
	if (n > SYSTRAY_MAX_ICONS) {
		const char *btn = systray_btn_text();
		tw = drw_fontset_getwidth(drw, btn, False);
		drw_setscheme(drw, scheme[SchemeNorm]);
		drw_text(drw, a->x, a->y, tw, a->h, 0, btn, 0, False);
	}

	drw_setscheme(drw, scheme[SchemeNorm]);
	for (w = 0, i = systray->icons; i; i = i->next) {
		wa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
		XChangeWindowAttributes(dpy, i->win, CWBackPixel, &wa);
		XMapRaised(dpy, i->win);
		i->x = w;
		XMoveResizeWindow(dpy, i->win, i->x, (systray->h - i->h) / 2, i->w, i->h);
		w += i->w;
		if (i->next)
			w += systrayspacing;
		if (i->mon != bar->mon)
			i->mon = bar->mon;
	}

	for (i = systray->icons; i; i = i->next) {
		if (systraycollapsed && count >= SYSTRAY_MAX_ICONS)
			break;
		visible_w += i->w;
		if (i->next && (!systraycollapsed || count + 1 < SYSTRAY_MAX_ICONS))
			visible_w += systrayspacing;
		count++;
	}

	int sx = bar->bx + a->x + tw + (tw && visible_w ? systrayspacing : 0);
	XMoveResizeWindow(dpy, systray->win, sx, (w ? bar->by + a->y + (a->h - systray->h) / 2: -systray->h), MAX(visible_w, 1), systray->h);
	return visible_w + tw + (tw && visible_w ? systrayspacing : 0);
}

int
click_systray(Bar *bar, Arg *arg, BarArg *a)
{
	int n = 0;
	Client *i;
	for (i = systray ? systray->icons : NULL; i; i = i->next) n++;
	if (n > SYSTRAY_MAX_ICONS) {
		int tw = drw_fontset_getwidth(drw, systray_btn_text(), False) + systrayspacing / 2;
		if (a->x <= tw) {
			systraycollapsed = !systraycollapsed;
			drawbarwin(bar);
		}
	}
	return -1;
}

int
hover_systray(Bar *bar, BarArg *a, XMotionEvent *ev)
{
	int n = 0;
	Client *i;
	for (i = systray ? systray->icons : NULL; i; i = i->next) n++;
	if (n > SYSTRAY_MAX_ICONS) {
		int tw = drw_fontset_getwidth(drw, systray_btn_text(), False) + systrayspacing / 2;
		if (a->x <= tw)
			return 1;
	}
	return 0;
}

void
removesystrayicon(Client *i)
{
	Client **ii;

	if (!showsystray || !i)
		return;
	for (ii = &systray->icons; *ii && *ii != i; ii = &(*ii)->next);
	if (ii)
		*ii = i->next;
	XReparentWindow(dpy, i->win, root, 0, 0);
	free(i);
	drawbarwin(systray->bar);
}

void
resizerequest(XEvent *e)
{
	XResizeRequestEvent *ev = &e->xresizerequest;
	Client *i;

	if ((i = wintosystrayicon(ev->window))) {
		updatesystrayicongeom(i, ev->width, ev->height);
		drawbarwin(systray->bar);
	}
}

void
updatesystrayicongeom(Client *i, int w, int h)
{
	if (!systray)
		return;

	int icon_height = systrayiconsize ? systrayiconsize : (drw->fonts && drw->fonts->h ? drw->fonts->h : 15);
	if (systray->h && icon_height > systray->h - 4)
		icon_height = systray->h - 4;
	if (i) {
		i->h = icon_height;
		if (w == h)
			i->w = icon_height;
		else if (h == icon_height)
			i->w = w;
		else
			i->w = (int) ((float)icon_height * ((float)w / (float)h));
		applysizehints(i, &(i->x), &(i->y), &(i->w), &(i->h), False);
		/* force icons into the systray dimensions if they don't want to */
		if (i->h > icon_height) {
			if (i->w == i->h)
				i->w = icon_height;
			else
				i->w = (int) ((float)icon_height * ((float)i->w / (float)i->h));
			i->h = icon_height;
		}
		if (i->w > 2 * icon_height)
			i->w = icon_height;
	}
}

void
updatesystrayiconstate(Client *i, XPropertyEvent *ev)
{
	long flags;
	int code = 0;

	if (!showsystray || !systray || !i || ev->atom != xatom[XembedInfo] ||
			!(flags = getatomprop(i, xatom[XembedInfo], xatom[XembedInfo])))
		return;

	if (flags & XEMBED_MAPPED && !i->tags) {
		i->tags = 1;
		code = XEMBED_WINDOW_ACTIVATE;
		XMapRaised(dpy, i->win);
		setclientstate(i, NormalState);
	}
	else if (!(flags & XEMBED_MAPPED) && i->tags) {
		i->tags = 0;
		code = XEMBED_WINDOW_DEACTIVATE;
		XUnmapWindow(dpy, i->win);
		setclientstate(i, WithdrawnState);
	}
	else
		return;
	sendevent(i->win, xatom[Xembed], StructureNotifyMask, CurrentTime, code, 0,
			systray->win, XEMBED_EMBEDDED_VERSION);
}

Client *
wintosystrayicon(Window w)
{
	if (!systray)
		return NULL;
	Client *i = NULL;
	if (!showsystray || !w)
		return i;
	for (i = systray->icons; i && i->win != w; i = i->next);
	return i;
}

