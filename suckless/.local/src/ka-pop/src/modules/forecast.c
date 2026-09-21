/* ==============================================================================
 * ka-pop: Forecast Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

GtkWidget* build_forecast_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("forecast", 360, &main_box);

    build_header(main_box, "Dự báo thời tiết", "Govap, Ho Chi Minh City", NULL);

    const char *home = getenv("HOME");
    char cache_path[512];
    snprintf(cache_path, sizeof(cache_path), "%s/.cache/weatherreport", home ? home : "/tmp");

    char temp_str[32] = "--°C";
    char desc_str[64] = "Không có dữ liệu";
    FILE *f = fopen(cache_path, "r");
    if (f) {
        char buf[2048];
        if (fgets(buf, sizeof(buf), f)) {
            char *p_temp = strstr(buf, "\"temp\":");
            if (p_temp) {
                float t = 0;
                if (sscanf(p_temp, "\"temp\":%f", &t) == 1) {
                    snprintf(temp_str, sizeof(temp_str), "%.0f°C", t);
                }
            }
            char *p_desc = strstr(buf, "\"description\":\"");
            if (p_desc) {
                p_desc += 15;
                char *end = strchr(p_desc, '"');
                if (end) {
                    size_t len = (size_t)(end - p_desc);
                    if (len >= sizeof(desc_str)) len = sizeof(desc_str) - 1;
                    strncpy(desc_str, p_desc, len);
                    desc_str[len] = '\0';
                }
            }
        }
        fclose(f);
    }

    GtkWidget *tile = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 12);
    GtkWidget *lbl_ico = gtk_label_new("󰖕");
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_ico), "metric-big");
    gtk_box_pack_start(GTK_BOX(tile), lbl_ico, FALSE, FALSE, 0);

    GtkWidget *t_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    GtkWidget *lbl_t = gtk_label_new(temp_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_t), "metric-big");
    gtk_label_set_xalign(GTK_LABEL(lbl_t), 0.0f);
    gtk_box_pack_start(GTK_BOX(t_box), lbl_t, FALSE, FALSE, 0);

    GtkWidget *lbl_d = gtk_label_new(desc_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_d), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(lbl_d), 0.0f);
    gtk_box_pack_start(GTK_BOX(t_box), lbl_d, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(tile), t_box, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), tile, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    return win;
}
