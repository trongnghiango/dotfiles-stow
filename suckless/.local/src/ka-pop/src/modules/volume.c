/* ==============================================================================
 * ka-pop: Volume Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static GtkWidget *g_vol_scale = NULL;
static GtkWidget *g_vol_percent = NULL;
static guint g_vol_timeout_id = 0;
static int g_target_vol = -1;

static gboolean apply_volume_timeout(gpointer data) {
    (void)data;
    if (g_target_vol >= 0) {
        char vol_str[16];
        snprintf(vol_str, sizeof(vol_str), "%d%%", g_target_vol);
        pid_t pid = fork();
        if (pid == 0) {
            setsid();
            execlp("wpctl", "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol_str, (char *)NULL);
            _exit(0);
        }
    }
    g_vol_timeout_id = 0;
    return G_SOURCE_REMOVE;
}

static void on_vol_changed(GtkRange *range, gpointer user_data) {
    (void)user_data;
    int vol = (int)gtk_range_get_value(range);
    char buf[16];
    snprintf(buf, sizeof(buf), "%d%%", vol);
    if (g_vol_percent) {
        gtk_label_set_text(GTK_LABEL(g_vol_percent), buf);
    }

    g_target_vol = vol;
    if (g_vol_timeout_id == 0) {
        g_vol_timeout_id = g_timeout_add(50, apply_volume_timeout, NULL);
    }
}

static void on_vol_mute_toggle(GtkButton *btn, gpointer user_data) {
    (void)btn;
    (void)user_data;
    char *args[] = {(char *)"wpctl", (char *)"set-mute", (char *)"@DEFAULT_AUDIO_SINK@", (char *)"toggle", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

static gboolean on_vol_scroll(GtkWidget *widget, GdkEventScroll *event, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (!g_vol_scale) return FALSE;
    double val = gtk_range_get_value(GTK_RANGE(g_vol_scale));
    if (event->direction == GDK_SCROLL_UP) {
        val = (val + 2.0 > 100.0) ? 100.0 : val + 2.0;
    } else if (event->direction == GDK_SCROLL_DOWN) {
        val = (val - 2.0 < 0.0) ? 0.0 : val - 2.0;
    }
    gtk_range_set_value(GTK_RANGE(g_vol_scale), val);
    return TRUE;
}

static void on_vol_destroy(GtkWidget *widget, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (g_vol_timeout_id > 0) {
        g_source_remove(g_vol_timeout_id);
        g_vol_timeout_id = 0;
    }
    g_vol_scale = NULL;
    g_vol_percent = NULL;
}

GtkWidget* build_volume_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("volume", 340, &main_box);

    int current_vol = 50;
    int is_muted = 0;
    char buf[128] = {0};
    char *args[] = {(char *)"wpctl", (char *)"get-volume", (char *)"@DEFAULT_AUDIO_SINK@", NULL};
    if (exec_capture(args, buf, sizeof(buf)) == 0) {
        float v = 0.5f;
        if (sscanf(buf, "Volume: %f", &v) >= 1) {
            current_vol = (int)(v * 100.0f + 0.5f);
        }
        if (strstr(buf, "[MUTED]")) is_muted = 1;
    }

    GtkWidget *mute_btn = gtk_button_new_with_label(is_muted ? "󰝟 UNMUTE" : "󰕾 MUTE");
    gtk_style_context_add_class(gtk_widget_get_style_context(mute_btn), "action-btn");
    g_signal_connect(mute_btn, "clicked", G_CALLBACK(on_vol_mute_toggle), NULL);

    build_header(main_box, "Âm lượng hệ thống", "Master Output (PipeWire)", mute_btn);

    GtkWidget *slider_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
    GtkWidget *icon_lbl = gtk_label_new(is_muted ? "󰝟" : (current_vol >= 70 ? "󰕾" : (current_vol >= 30 ? "󰖀" : "󰕿")));
    gtk_style_context_add_class(gtk_widget_get_style_context(icon_lbl), "metric-big");
    gtk_box_pack_start(GTK_BOX(slider_box), icon_lbl, FALSE, FALSE, 0);

    g_vol_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
    gtk_scale_set_draw_value(GTK_SCALE(g_vol_scale), FALSE);
    gtk_range_set_value(GTK_RANGE(g_vol_scale), current_vol);
    g_signal_connect(g_vol_scale, "value-changed", G_CALLBACK(on_vol_changed), NULL);
    gtk_box_pack_start(GTK_BOX(slider_box), g_vol_scale, TRUE, TRUE, 0);

    char p_buf[16];
    snprintf(p_buf, sizeof(p_buf), "%d%%", current_vol);
    g_vol_percent = gtk_label_new(p_buf);
    gtk_style_context_add_class(gtk_widget_get_style_context(g_vol_percent), "stat-val");
    gtk_box_pack_end(GTK_BOX(slider_box), g_vol_percent, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(main_box), slider_box, FALSE, FALSE, 0);
    build_footer(main_box, "Cuộn chuột để tăng/giảm • Esc để đóng");

    gtk_widget_add_events(win, GDK_SCROLL_MASK);
    g_signal_connect(win, "scroll-event", G_CALLBACK(on_vol_scroll), NULL);
    g_signal_connect(win, "destroy", G_CALLBACK(on_vol_destroy), NULL);

    return win;
}
