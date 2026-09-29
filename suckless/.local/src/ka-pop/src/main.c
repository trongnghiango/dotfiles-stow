#include <gdk/gdkx.h>
#include <X11/Xatom.h>
/* ==============================================================================
 * ka-pop: Ultra-Fast Native C / GTK3 Popover Cards for Omarchy-X11
 * ============================================================================== */

#include "common.h"
#include "theme.h"
#include "modules.h"

int main(int argc, char *argv[]) {
    signal(SIGCHLD, SIG_IGN);
    g_set_prgname("dwm-dropdown");
    g_set_application_name("dwm-dropdown");

    if (argc > 1 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
        printf("Sử dụng: ka-pop [volume|battery|clock|cpu|memory|network|notify|forecast|clip]\n");
        return 0;
    }

    gtk_init(&argc, &argv);
    load_theme_colors(&g_theme);

    const char *target = (argc > 1) ? argv[1] : "volume";
    GtkWidget *win = NULL;

    if (strcmp(target, "volume") == 0 || strcmp(target, "audio") == 0 || strcmp(target, "vol") == 0) {
        win = build_volume_window();
    } else if (strcmp(target, "battery") == 0 || strcmp(target, "bat") == 0 || strcmp(target, "power") == 0) {
        win = build_battery_window();
    } else if (strcmp(target, "clock") == 0 || strcmp(target, "time") == 0 || strcmp(target, "calendar") == 0) {
        win = build_clock_window();
    } else if (strcmp(target, "cpu") == 0) {
        win = build_cpu_window();
    } else if (strcmp(target, "memory") == 0 || strcmp(target, "mem") == 0 || strcmp(target, "ram") == 0) {
        win = build_memory_window();
    } else if (strcmp(target, "network") == 0 || strcmp(target, "net") == 0 || strcmp(target, "wifi") == 0) {
        win = build_network_window();
    } else if (strcmp(target, "notify") == 0 || strcmp(target, "nc") == 0) {
        win = build_notify_window();
    } else if (strcmp(target, "forecast") == 0 || strcmp(target, "weather") == 0 || strcmp(target, "weath") == 0) {
        win = build_forecast_window();
    } else if (strcmp(target, "clip") == 0 || strcmp(target, "clipboard") == 0) {
        win = build_clip_window();
    } else {
        win = build_volume_window();
    }

    if (win) {
        gtk_widget_realize(win);
        GdkWindow *gdk_win = gtk_widget_get_window(win);
        if (gdk_win) {
            Display *xdisplay = GDK_WINDOW_XDISPLAY(gdk_win);
            Window xid = GDK_WINDOW_XID(gdk_win);
            int sig = 0;
            if (!strcmp(target, "clock") || !strcmp(target, "time") || !strcmp(target, "calendar")) sig = 1;
            else if (!strcmp(target, "forecast") || !strcmp(target, "weather") || !strcmp(target, "weath")) sig = 14;
            else if (!strcmp(target, "volume") || !strcmp(target, "audio") || !strcmp(target, "vol")) sig = 11;
            else if (!strcmp(target, "battery") || !strcmp(target, "bat") || !strcmp(target, "power")) sig = 30;
            else if (!strcmp(target, "network") || !strcmp(target, "net") || !strcmp(target, "wifi")) sig = 4;
            else if (!strcmp(target, "cpu")) sig = 15;
            else if (!strcmp(target, "memory") || !strcmp(target, "mem") || !strcmp(target, "ram")) sig = 10;
            else if (!strcmp(target, "notify") || !strcmp(target, "nc")) sig = 8;

            if (sig > 0) {
                Atom sig_atom = XInternAtom(xdisplay, "_KA_BLOCK_SIGNAL", False);
                uint32_t val = (uint32_t)sig;
                XChangeProperty(xdisplay, xid, sig_atom, XA_CARDINAL, 32,
                                PropModeReplace, (unsigned char *)&val, 1);
            }
        }
        gtk_widget_show_all(win);
        gtk_main();
        gtk_widget_destroy(win);
    }

    return 0;
}
