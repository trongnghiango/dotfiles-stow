static Systray *systray = NULL;
static unsigned long systrayorientation = _NET_SYSTEM_TRAY_ORIENTATION_HORZ;
static int systraycollapsed = 1;
#ifndef SYSTRAY_MAX_ICONS
#define SYSTRAY_MAX_ICONS 1
#endif

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
			tw = TEXTW(systraycollapsed ? "<" : ">") - lrpad / 2;
		}
		for (i = systray->icons; i; i = i->next) {
			if (systraycollapsed && count >= SYSTRAY_MAX_ICONS)
				break;
			w += i->w + systrayspacing;
			count++;
		}
		if (w > 0)
			w -= systrayspacing;
		w += tw;
		if (!w)
			XMoveWindow(dpy, systray->win, -systray->h, bar->by);
	}
	return w ? w + lrpad : 0;
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
		systray->h = MAX(drw->fonts->h, 24);
		systray->h = MIN(a->h, systray->h);
		wa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
		systray->win = XCreateSimpleWindow(dpy, root, bar->bx + a->x + lrpad / 2, -systray->h, MIN(a->w, 1), systray->h, 0, 0, scheme[SchemeNorm][ColBg].pixel);
		XChangeWindowAttributes(dpy, systray->win, CWOverrideRedirect|CWBackPixel|CWBorderPixel|CWEventMask, &wa);

		XSelectInput(dpy, systray->win, SubstructureNotifyMask);
		XChangeProperty(dpy, systray->win, netatom[NetSystemTrayOrientation], XA_CARDINAL, 32,
				PropModeReplace, (unsigned char *)&systrayorientation, 1);
		XChangeProperty(dpy, systray->win, netatom[NetWMWindowType], XA_ATOM, 32,
				PropModeReplace, (unsigned char *)&netatom[NetWMWindowTypeDock], 1);
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
	}

	systray->bar = bar;

	wc.stack_mode = Above;
	wc.sibling = bar->win;
	XConfigureWindow(dpy, systray->win, CWSibling|CWStackMode, &wc);

	for (i = systray->icons; i; i = i->next) n++;
	if (n > SYSTRAY_MAX_ICONS) {
		tw = TEXTW(systraycollapsed ? "<" : ">") - lrpad / 2;
		drw_setscheme(drw, scheme[SchemeNorm]);
		drw_text(drw, bar->bx + a->x, a->y, tw, a->h, lrpad / 4, (systraycollapsed ? "<" : ">"), 0, False);
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

	XMoveResizeWindow(dpy, systray->win, bar->bx + a->x + tw, (w ? bar->by + a->y + (a->h - systray->h) / 2: -systray->h), MAX(visible_w, 1), systray->h);
	return visible_w + tw;
}

int
click_systray(Bar *bar, Arg *arg, BarArg *a)
{
	int n = 0;
	Client *i;
	for (i = systray->icons; i; i = i->next) n++;
	if (n > SYSTRAY_MAX_ICONS) {
		int tw = TEXTW(systraycollapsed ? "<" : ">") - lrpad / 2;
		if (a->x <= tw) {
			systraycollapsed = !systraycollapsed;
			drawbarwin(bar);
		}
	}
	return -1;
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

	int icon_height = systray->h;
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

