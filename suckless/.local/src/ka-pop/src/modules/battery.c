/* ==============================================================================
 * ka-pop: Battery & Brightness Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static GtkWidget *g_bri_scale = NULL;
static guint g_bri_timeout_id = 0;
static int g_target_bri = -1;

static gboolean apply_brightness_timeout(gpointer data) {
    (void)data;
    if (g_target_bri >= 0) {
        char bri_str[16];
        snprintf(bri_str, sizeof(bri_str), "%d%%", g_target_bri);
        pid_t pid = fork();
        if (pid == 0) {
            setsid();
            execlp("brightnessctl", "brightnessctl", "-q", "set", bri_str, (char *)NULL);
            _exit(0);
        }
    }
    g_bri_timeout_id = 0;
    return G_SOURCE_REMOVE;
}

static void on_bri_changed(GtkRange *range, gpointer user_data) {
    (void)user_data;
    int bri = (int)gtk_range_get_value(range);
    g_target_bri = bri;
    if (g_bri_timeout_id == 0) {
        g_bri_timeout_id = g_timeout_add(50, apply_brightness_timeout, NULL);
    }
}

static void on_battery_destroy(GtkWidget *widget, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (g_bri_timeout_id > 0) {
        g_source_remove(g_bri_timeout_id);
        g_bri_timeout_id = 0;
    }
    g_bri_scale = NULL;
}

GtkWidget* build_battery_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("battery", 340, &main_box);

    int cap = 100;
    char status[64] = "Full";
    FILE *f_cap = fopen("/sys/class/power_supply/BAT0/capacity", "r");
    if (!f_cap) f_cap = fopen("/sys/class/power_supply/BAT1/capacity", "r");
    if (f_cap) {
        fscanf(f_cap, "%d", &cap);
        fclose(f_cap);
    }
    FILE *f_st = fopen("/sys/class/power_supply/BAT0/status", "r");
    if (!f_st) f_st = fopen("/sys/class/power_supply/BAT1/status", "r");
    if (f_st) {
        if (fgets(status, sizeof(status), f_st)) {
            char *nl = strchr(status, '\n');
            if (nl) *nl = '\0';
        }
        fclose(f_st);
    }

    GtkWidget *badge = gtk_label_new(status);
    gtk_style_context_add_class(gtk_widget_get_style_context(badge), "badge");

    build_header(main_box, "Quản lý năng lượng", "ThinkPad Battery & Display", badge);

    GtkWidget *bat_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 12);
    char cap_str[32];
    snprintf(cap_str, sizeof(cap_str), "%s %d%%", strcmp(status, "Charging") == 0 ? "󰂄" : "󰁹", cap);
    GtkWidget *lbl_cap = gtk_label_new(cap_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_cap), "metric-big");
    gtk_box_pack_start(GTK_BOX(bat_box), lbl_cap, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), bat_box, FALSE, FALSE, 0);

    int current_bri = 50;
    FILE *p = popen("brightnessctl -m", "r");
    if (p) {
        char buf[128];
        if (fgets(buf, sizeof(buf), p)) {
            char *comma = strrchr(buf, ',');
            if (comma) {
                *comma = '\0';
                char *pct = strrchr(buf, ',');
                if (pct) sscanf(pct + 1, "%d%%", &current_bri);
            }
        }
        pclose(p);
    }

    GtkWidget *bri_title = gtk_label_new("󰃠  ĐỘ SÁNG MÀN HÌNH");
    gtk_label_set_xalign(GTK_LABEL(bri_title), 0.0f);
    gtk_style_context_add_class(gtk_widget_get_style_context(bri_title), "title-label");
    gtk_box_pack_start(GTK_BOX(main_box), bri_title, FALSE, FALSE, 0);

    g_bri_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 5, 100, 1);
    gtk_scale_set_draw_value(GTK_SCALE(g_bri_scale), FALSE);
    gtk_range_set_value(GTK_RANGE(g_bri_scale), current_bri);
    g_signal_connect(g_bri_scale, "value-changed", G_CALLBACK(on_bri_changed), NULL);
    gtk_box_pack_start(GTK_BOX(main_box), g_bri_scale, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    g_signal_connect(win, "destroy", G_CALLBACK(on_battery_destroy), NULL);

    return win;
}
