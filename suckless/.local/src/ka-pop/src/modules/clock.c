/* ==============================================================================
 * ka-pop: Clock & Calendar Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

GtkWidget* build_clock_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("clock", 340, &main_box);

    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);

    char time_str[32], date_str[64];
    strftime(time_str, sizeof(time_str), "%H:%M", tm_info);
    strftime(date_str, sizeof(date_str), "%A, %d %B %Y", tm_info);

    build_header(main_box, "Thời gian & Lịch", date_str, NULL);

    GtkWidget *lbl_big = gtk_label_new(time_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_big), "metric-big");
    gtk_box_pack_start(GTK_BOX(main_box), lbl_big, FALSE, FALSE, 0);

    GtkWidget *calendar = gtk_calendar_new();
    gtk_box_pack_start(GTK_BOX(main_box), calendar, TRUE, TRUE, 0);

    double uptime_sec = 0;
    FILE *f_up = fopen("/proc/uptime", "r");
    if (f_up) {
        fscanf(f_up, "%lf", &uptime_sec);
        fclose(f_up);
    }
    int hours = (int)(uptime_sec / 3600);
    int mins = ((int)uptime_sec % 3600) / 60;
    char up_str[64];
    snprintf(up_str, sizeof(up_str), "Uptime: %d giờ %d phút", hours, mins);

    build_footer(main_box, up_str);
    return win;
}
