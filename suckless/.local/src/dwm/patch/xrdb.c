void
loadxrdb()
{
	XrmDatabase xrdb = NULL;
	char *type;
	XrmValue value;
	Atom actual_type;
	int actual_format;
	unsigned long nitems, bytes_after;
	unsigned char *resm = NULL;

	if (dpy != NULL) {
		/* Fetch fresh RESOURCE_MANAGER property from root window (bypasses stale XResourceManagerString cache) */
		if (XGetWindowProperty(dpy, RootWindow(dpy, 0),
		                       XA_RESOURCE_MANAGER, 0L, 100000L,
		                       False, XA_STRING, &actual_type, &actual_format,
		                       &nitems, &bytes_after, &resm) == Success && resm != NULL) {
			xrdb = XrmGetStringDatabase((char *)resm);
		} else {
			char *cached = XResourceManagerString(dpy);
			if (cached != NULL)
				xrdb = XrmGetStringDatabase(cached);
		}

		if (xrdb != NULL) {
			/* 1. Fallback base colors from dwm.color0..15 */
			XRDB_LOAD_COLOR("dwm.color6", normfgcolor);
			XRDB_LOAD_COLOR("dwm.color0", normbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", normbordercolor);
			XRDB_LOAD_COLOR("dwm.color8", normfloatcolor);
			XRDB_LOAD_COLOR("dwm.color0", selfgcolor);
			XRDB_LOAD_COLOR("dwm.color14", selbgcolor);
			XRDB_LOAD_COLOR("dwm.color8", selbordercolor);
			XRDB_LOAD_COLOR("dwm.color8", selfloatcolor);
			XRDB_LOAD_COLOR("dwm.color6", titlenormfgcolor);
			XRDB_LOAD_COLOR("dwm.color0", titlenormbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", titlenormbordercolor);
			XRDB_LOAD_COLOR("dwm.color0", titlenormfloatcolor);
			XRDB_LOAD_COLOR("dwm.color14", titleselfgcolor);
			XRDB_LOAD_COLOR("dwm.color0", titleselbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", titleselbordercolor);
			XRDB_LOAD_COLOR("dwm.color0", titleselfloatcolor);
			XRDB_LOAD_COLOR("dwm.color6", tagsnormfgcolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsnormbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsnormbordercolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsnormfloatcolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsselfgcolor);
			XRDB_LOAD_COLOR("dwm.color14", tagsselbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsselbordercolor);
			XRDB_LOAD_COLOR("dwm.color0", tagsselfloatcolor);
			XRDB_LOAD_COLOR("dwm.color6", hidnormfgcolor);
			XRDB_LOAD_COLOR("dwm.color0", hidnormbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", hidselfgcolor);
			XRDB_LOAD_COLOR("dwm.color14", hidselbgcolor);
			XRDB_LOAD_COLOR("dwm.color6", urgfgcolor);
			XRDB_LOAD_COLOR("dwm.color8", urgbgcolor);
			XRDB_LOAD_COLOR("dwm.color0", urgbordercolor);
			XRDB_LOAD_COLOR("dwm.color0", urgfloatcolor);

			/* 2. Specific semantic keys override defaults if present */
			XRDB_LOAD_COLOR("dwm.normfgcolor", normfgcolor);
			XRDB_LOAD_COLOR("dwm.normbgcolor", normbgcolor);
			XRDB_LOAD_COLOR("dwm.normbordercolor", normbordercolor);
			XRDB_LOAD_COLOR("dwm.normfloatcolor", normfloatcolor);
			XRDB_LOAD_COLOR("dwm.selfgcolor", selfgcolor);
			XRDB_LOAD_COLOR("dwm.selbgcolor", selbgcolor);
			XRDB_LOAD_COLOR("dwm.selbordercolor", selbordercolor);
			XRDB_LOAD_COLOR("dwm.selfloatcolor", selfloatcolor);
			XRDB_LOAD_COLOR("dwm.titlenormfgcolor", titlenormfgcolor);
			XRDB_LOAD_COLOR("dwm.titlenormbgcolor", titlenormbgcolor);
			XRDB_LOAD_COLOR("dwm.titlenormbordercolor", titlenormbordercolor);
			XRDB_LOAD_COLOR("dwm.titlenormfloatcolor", titlenormfloatcolor);
			XRDB_LOAD_COLOR("dwm.titleselfgcolor", titleselfgcolor);
			XRDB_LOAD_COLOR("dwm.titleselbgcolor", titleselbgcolor);
			XRDB_LOAD_COLOR("dwm.titleselbordercolor", titleselbordercolor);
			XRDB_LOAD_COLOR("dwm.titleselfloatcolor", titleselfloatcolor);
			XRDB_LOAD_COLOR("dwm.tagsnormfgcolor", tagsnormfgcolor);
			XRDB_LOAD_COLOR("dwm.tagsnormbgcolor", tagsnormbgcolor);
			XRDB_LOAD_COLOR("dwm.tagsnormbordercolor", tagsnormbordercolor);
			XRDB_LOAD_COLOR("dwm.tagsnormfloatcolor", tagsnormfloatcolor);
			XRDB_LOAD_COLOR("dwm.tagsselfgcolor", tagsselfgcolor);
			XRDB_LOAD_COLOR("dwm.tagsselbgcolor", tagsselbgcolor);
			XRDB_LOAD_COLOR("dwm.tagsselbordercolor", tagsselbordercolor);
			XRDB_LOAD_COLOR("dwm.tagsselfloatcolor", tagsselfloatcolor);
			XRDB_LOAD_COLOR("dwm.hidnormfgcolor", hidnormfgcolor);
			XRDB_LOAD_COLOR("dwm.hidnormbgcolor", hidnormbgcolor);
			XRDB_LOAD_COLOR("dwm.hidselfgcolor", hidselfgcolor);
			XRDB_LOAD_COLOR("dwm.hidselbgcolor", hidselbgcolor);
			XRDB_LOAD_COLOR("dwm.urgfgcolor", urgfgcolor);
			XRDB_LOAD_COLOR("dwm.urgbgcolor", urgbgcolor);
			XRDB_LOAD_COLOR("dwm.urgbordercolor", urgbordercolor);
			XRDB_LOAD_COLOR("dwm.urgfloatcolor", urgfloatcolor);

			/* 3. Terminal / status2d palette */
			XRDB_LOAD_COLOR("dwm.color0", termcol0);
			XRDB_LOAD_COLOR("dwm.color1", termcol1);
			XRDB_LOAD_COLOR("dwm.color2", termcol2);
			XRDB_LOAD_COLOR("dwm.color3", termcol3);
			XRDB_LOAD_COLOR("dwm.color4", termcol4);
			XRDB_LOAD_COLOR("dwm.color5", termcol5);
			XRDB_LOAD_COLOR("dwm.color6", termcol6);
			XRDB_LOAD_COLOR("dwm.color7", termcol7);
			XRDB_LOAD_COLOR("dwm.color8", termcol8);
			XRDB_LOAD_COLOR("dwm.color9", termcol9);
			XRDB_LOAD_COLOR("dwm.color10", termcol10);
			XRDB_LOAD_COLOR("dwm.color11", termcol11);
			XRDB_LOAD_COLOR("dwm.color12", termcol12);
			XRDB_LOAD_COLOR("dwm.color13", termcol13);
			XRDB_LOAD_COLOR("dwm.color14", termcol14);
			XRDB_LOAD_COLOR("dwm.color15", termcol15);

			XrmDestroyDatabase(xrdb);
		}

		if (resm != NULL)
			XFree(resm);
	}
}

void
xrdb(const Arg *arg)
{
	loadxrdb();
	int i;
	for (i = 0; i < LENGTH(colors) + 1; i++) {
		if (scheme[i])
			drw_scm_free(drw, scheme[i], ColCount);
	}
	scheme[LENGTH(colors)] = drw_scm_create(drw, colors[0], ColCount);
	for (i = 0; i < LENGTH(colors); i++)
		scheme[i] = drw_scm_create(drw, colors[i], ColCount);

	/* Synchronize window borders for all clients */
	Client *c;
	Monitor *m;
	for (m = mons; m; m = m->next) {
		for (c = m->clients; c; c = c->next) {
			XSetWindowBorder(dpy, c->win, scheme[c == selmon->sel ? SchemeSel : SchemeNorm][c->isfloating ? ColFloat : ColBorder].pixel);
		}
	}

	arrange(NULL);
	focus(NULL);
	drawbars();
}
