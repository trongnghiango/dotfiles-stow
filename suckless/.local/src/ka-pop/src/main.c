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
        gtk_widget_show_all(win);
        gtk_main();
        gtk_widget_destroy(win);
    }

    return 0;
}
