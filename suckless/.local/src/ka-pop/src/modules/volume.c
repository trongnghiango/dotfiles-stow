/* ==============================================================================
 * ka-pop: Volume Module — Ultra-Fast Master Output, Input Mic & App Streams (< 50ms)
 * Fully synchronized in real-time with dwmblocks (Signal 11, < 10µs IPC)
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"
#include <sys/types.h>
#include <signal.h>

#define MAX_AUDIO_DEVS 4
#define MAX_APP_STREAMS 6

typedef struct {
    int id;
    char name[64];
    int is_active;
    int vol;
} AudioDev;

typedef struct {
    int id;
    char name[48];
    int vol;
    int target_vol;
    guint timeout_id;
    GtkWidget *lbl_val;
    GtkWidget *scale;
} AppStream;

static GtkWidget *g_out_scale = NULL;
static GtkWidget *g_out_lbl = NULL;
static GtkWidget *g_in_scale = NULL;
static GtkWidget *g_in_lbl = NULL;
static GtkWidget *g_mute_btn = NULL;
static int g_is_out_muted = 0;

static guint g_out_timeout_id = 0;
static int g_target_out_vol = -1;

static guint g_in_timeout_id = 0;
static int g_target_in_vol = -1;

static AppStream g_streams[MAX_APP_STREAMS];
static int g_stream_count = 0;

/* Bắn tín hiệu SIGRTMIN+11 trực tiếp trong C tới dwmblocks (< 10µs, 0 fork, 0 subshell) */
static void signal_dwmblocks_volume(void) {
    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    char pid_file[128];
    if (runtime_dir && runtime_dir[0]) {
        snprintf(pid_file, sizeof(pid_file), "%s/dwmblocks.pid", runtime_dir);
    } else {
        snprintf(pid_file, sizeof(pid_file), "/tmp/dwmblocks-%d.pid", getuid());
    }

    FILE *f = fopen(pid_file, "r");
    if (f) {
        pid_t pid = 0;
        if (fscanf(f, "%d", &pid) == 1 && pid > 0) {
            kill(pid, SIGRTMIN + 11);
        }
        fclose(f);
        return;
    }

    /* Fallback chỉ khi không tìm thấy file PID */
    char *args[] = {(char *)"pkill", (char *)"-RTMIN+11", (char *)"-x", (char *)"dwmblocks", NULL};
    spawn_cmd(args);
}

/* Debounce điều khiển Master Output (30ms = 33 fps mượt mà, chống nghẽn PipeWire) */
static gboolean apply_output_vol_timeout(gpointer data) {
    (void)data;
    if (g_target_out_vol >= 0) {
        char vol_str[16];
        snprintf(vol_str, sizeof(vol_str), "%d%%", g_target_out_vol);
        char *args[] = {(char *)"wpctl", (char *)"set-volume", (char *)"@DEFAULT_AUDIO_SINK@", vol_str, NULL};
        spawn_cmd(args);
        signal_dwmblocks_volume();
    }
    g_out_timeout_id = 0;
    return G_SOURCE_REMOVE;
}

static void on_out_vol_changed(GtkRange *range, gpointer user_data) {
    (void)user_data;
    int vol = (int)gtk_range_get_value(range);
    char buf[16];
    snprintf(buf, sizeof(buf), "%d%%", vol);
    if (g_out_lbl) {
        gtk_label_set_text(GTK_LABEL(g_out_lbl), buf);
    }

    g_target_out_vol = vol;
    if (g_out_timeout_id == 0) {
        g_out_timeout_id = g_timeout_add(30, apply_output_vol_timeout, NULL);
    }
}

/* Debounce điều khiển Microphone Input */
static gboolean apply_input_vol_timeout(gpointer data) {
    (void)data;
    if (g_target_in_vol >= 0) {
        char vol_str[16];
        snprintf(vol_str, sizeof(vol_str), "%d%%", g_target_in_vol);
        char *args[] = {(char *)"wpctl", (char *)"set-volume", (char *)"@DEFAULT_AUDIO_SOURCE@", vol_str, NULL};
        spawn_cmd(args);
    }
    g_in_timeout_id = 0;
    return G_SOURCE_REMOVE;
}

static void on_in_vol_changed(GtkRange *range, gpointer user_data) {
    (void)user_data;
    int vol = (int)gtk_range_get_value(range);
    char buf[16];
    snprintf(buf, sizeof(buf), "%d%%", vol);
    if (g_in_lbl) {
        gtk_label_set_text(GTK_LABEL(g_in_lbl), buf);
    }

    g_target_in_vol = vol;
    if (g_in_timeout_id == 0) {
        g_in_timeout_id = g_timeout_add(30, apply_input_vol_timeout, NULL);
    }
}

/* Debounce điều khiển App Stream riêng biệt (chống flood fork khi kéo nhanh) */
static gboolean apply_stream_vol_timeout(gpointer data) {
    AppStream *st = (AppStream *)data;
    if (st && st->target_vol >= 0) {
        char id_str[16], vol_str[16];
        snprintf(id_str, sizeof(id_str), "%d", st->id);
        snprintf(vol_str, sizeof(vol_str), "%d%%", st->target_vol);
        char *args[] = {(char *)"wpctl", (char *)"set-volume", id_str, vol_str, NULL};
        spawn_cmd(args);
    }
    if (st) st->timeout_id = 0;
    return G_SOURCE_REMOVE;
}

static void on_stream_vol_changed(GtkRange *range, gpointer user_data) {
    AppStream *st = (AppStream *)user_data;
    if (!st) return;
    int vol = (int)gtk_range_get_value(range);
    char buf[16];
    snprintf(buf, sizeof(buf), "%d%%", vol);
    if (st->lbl_val) {
        gtk_label_set_text(GTK_LABEL(st->lbl_val), buf);
    }

    st->target_vol = vol;
    if (st->timeout_id == 0) {
        st->timeout_id = g_timeout_add(30, apply_stream_vol_timeout, st);
    }
}

static void on_switch_default_device(GtkButton *btn, gpointer user_data) {
    (void)btn;
    int id = GPOINTER_TO_INT(user_data);
    if (id > 0) {
        char id_str[16];
        snprintf(id_str, sizeof(id_str), "%d", id);
        char *args[] = {(char *)"wpctl", (char *)"set-default", id_str, NULL};
        spawn_cmd(args);
        signal_dwmblocks_volume();
    }
    gtk_main_quit();
}

static void on_master_mute_toggle(GtkButton *btn, gpointer user_data) {
    (void)user_data;
    char *args[] = {(char *)"wpctl", (char *)"set-mute", (char *)"@DEFAULT_AUDIO_SINK@", (char *)"toggle", NULL};
    spawn_cmd(args);
    signal_dwmblocks_volume();

    g_is_out_muted = !g_is_out_muted;
    gtk_button_set_label(btn, g_is_out_muted ? "󰝟 TẮT TIẾNG" : "󰕾 BẬT");

    GtkStyleContext *ctx = gtk_widget_get_style_context(GTK_WIDGET(btn));
    gtk_style_context_remove_class(ctx, "btn-active");
    gtk_style_context_remove_class(ctx, "badge");
    gtk_style_context_add_class(ctx, g_is_out_muted ? "btn-active" : "badge");
}

static gboolean on_vol_scroll(GtkWidget *widget, GdkEventScroll *event, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (!g_out_scale) return FALSE;
    double val = gtk_range_get_value(GTK_RANGE(g_out_scale));
    if (event->direction == GDK_SCROLL_UP) {
        val = (val + 2.0 > 100.0) ? 100.0 : val + 2.0;
    } else if (event->direction == GDK_SCROLL_DOWN) {
        val = (val - 2.0 < 0.0) ? 0.0 : val - 2.0;
    }
    gtk_range_set_value(GTK_RANGE(g_out_scale), val);
    return TRUE;
}

/* Giải phóng triệt để toàn bộ bộ định thời (Timer) khi đóng cửa sổ */
static void on_vol_destroy(GtkWidget *widget, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (g_out_timeout_id > 0) {
        g_source_remove(g_out_timeout_id);
        g_out_timeout_id = 0;
    }
    if (g_in_timeout_id > 0) {
        g_source_remove(g_in_timeout_id);
        g_in_timeout_id = 0;
    }
    for (int i = 0; i < g_stream_count; i++) {
        if (g_streams[i].timeout_id > 0) {
            g_source_remove(g_streams[i].timeout_id);
            g_streams[i].timeout_id = 0;
        }
    }
    g_out_scale = NULL;
    g_out_lbl = NULL;
    g_in_scale = NULL;
    g_in_lbl = NULL;
    g_mute_btn = NULL;
}

GtkWidget* build_volume_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("volume", 380, &main_box);

    int master_out_vol = 50;
    int is_out_muted = 0;
    int master_in_vol = 100;

    AudioDev sinks[MAX_AUDIO_DEVS]; int sink_count = 0;
    AudioDev sources[MAX_AUDIO_DEVS]; int source_count = 0;
    g_stream_count = 0;

    /* Tối ưu hóa tối đa: Đúng 1 lần truy vấn wpctl status trích xuất đồng thời Sinks, Sources và Streams */
    char status_buf[4096] = {0};
    char *status_args[] = {(char *)"wpctl", (char *)"status", NULL};
    if (exec_capture(status_args, status_buf, sizeof(status_buf)) == 0) {
        char *saveptr = NULL;
        char *line = strtok_r(status_buf, "\n", &saveptr);
        int section = 0;

        while (line) {
            if (strstr(line, "Sinks:")) section = 1;
            else if (strstr(line, "Sources:")) section = 2;
            else if (strstr(line, "Filters:")) section = 3;
            else if (strstr(line, "Streams:")) section = 4;
            else if (strstr(line, "Video") || strstr(line, "Settings")) section = 0;

            char *dot = strstr(line, ". ");
            if (dot && dot > line && section > 0) {
                char *start = dot - 1;
                while (start > line && *(start - 1) >= '0' && *(start - 1) <= '9') start--;
                if (*start >= '0' && *start <= '9') {
                    int id = atoi(start);
                    int is_active = (strchr(line, '*') != NULL && strchr(line, '*') < dot);
                    int is_audio_source = (section == 2 || (section == 3 && strstr(line, "[Audio/Source]")));

                    /* Đọc âm lượng đính kèm nếu có [vol: 0.18] */
                    int item_vol = -1;
                    char *p_vol = strstr(line, "[vol:");
                    if (p_vol) {
                        float vf = 0.5f;
                        if (sscanf(p_vol, "[vol: %f", &vf) >= 1) {
                            item_vol = (int)(vf * 100.0f + 0.5f);
                        }
                    }

                    char name[64] = {0};
                    char *src_name = dot + 2;
                    while (*src_name == ' ') src_name++;
                    strncpy(name, src_name, sizeof(name) - 1);
                    char *vol_t = strstr(name, "[vol:");
                    if (vol_t) *vol_t = '\0';
                    char *tag_t = strchr(name, '[');
                    if (tag_t) *tag_t = '\0';
                    char *end_t = name + strlen(name) - 1;
                    while (end_t > name && (*end_t == ' ' || *end_t == '\t' || *end_t == '\r')) *end_t-- = '\0';

                    if (section == 1 && sink_count < MAX_AUDIO_DEVS) {
                        sinks[sink_count].id = id;
                        strncpy(sinks[sink_count].name, name, sizeof(sinks[sink_count].name) - 1);
                        sinks[sink_count].is_active = is_active;
                        sinks[sink_count].vol = (item_vol >= 0) ? item_vol : 50;
                        if (is_active) {
                            master_out_vol = sinks[sink_count].vol;
                            if (strstr(line, "[MUTED]")) is_out_muted = 1;
                        }
                        sink_count++;
                    } else if (is_audio_source && source_count < MAX_AUDIO_DEVS) {
                        sources[source_count].id = id;
                        strncpy(sources[source_count].name, name, sizeof(sources[source_count].name) - 1);
                        sources[source_count].is_active = is_active;
                        sources[source_count].vol = (item_vol >= 0) ? item_vol : 100;
                        if (is_active && item_vol >= 0) {
                            master_in_vol = item_vol;
                        }
                        source_count++;
                    } else if (section == 4 && g_stream_count < MAX_APP_STREAMS && !strstr(name, "output_")) {
                        /* Chỉ lưu tối đa 1 luồng đại diện cho mỗi ứng dụng */
                        int dup = 0;
                        for (int k = 0; k < g_stream_count; k++) {
                            if (strcmp(g_streams[k].name, name) == 0) { dup = 1; break; }
                        }
                        if (!dup) {
                            g_streams[g_stream_count].id = id;
                            strncpy(g_streams[g_stream_count].name, name, sizeof(g_streams[g_stream_count].name) - 1);
                            g_streams[g_stream_count].vol = (item_vol >= 0) ? item_vol : 70;
                            g_streams[g_stream_count].target_vol = -1;
                            g_streams[g_stream_count].timeout_id = 0;
                            g_stream_count++;
                        }
                    }
                }
            }
            line = strtok_r(NULL, "\n", &saveptr);
        }
    }

    /* Kiểm tra thêm trạng thái MUTE nếu chưa thấy trong status */
    char mute_chk[128] = {0};
    char *mute_args[] = {(char *)"wpctl", (char *)"get-volume", (char *)"@DEFAULT_AUDIO_SINK@", NULL};
    if (exec_capture(mute_args, mute_chk, sizeof(mute_chk)) == 0) {
        if (strstr(mute_chk, "[MUTED]")) is_out_muted = 1;
        float v_chk = 0.5f;
        if (sscanf(mute_chk, "Volume: %f", &v_chk) >= 1) {
            master_out_vol = (int)(v_chk * 100.0f + 0.5f);
        }
    }

    /* 4. Header: Audio • Mute Switch */
    g_is_out_muted = is_out_muted;
    g_mute_btn = gtk_button_new_with_label(is_out_muted ? "󰝟 TẮT TIẾNG" : "󰕾 BẬT");
    gtk_style_context_add_class(gtk_widget_get_style_context(g_mute_btn), is_out_muted ? "btn-active" : "badge");
    g_signal_connect(g_mute_btn, "clicked", G_CALLBACK(on_master_mute_toggle), NULL);

    build_header(main_box, "Âm thanh (Audio)", "PipeWire • WirePlumber", g_mute_btn);

    /* 5. OUTPUT SECTION */
    GtkWidget *out_head_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *lbl_out_t = gtk_label_new("OUTPUT");
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_out_t), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(lbl_out_t), 0.0f);
    gtk_box_pack_start(GTK_BOX(out_head_box), lbl_out_t, TRUE, TRUE, 0);

    char out_p_str[16];
    snprintf(out_p_str, sizeof(out_p_str), "%d%%", master_out_vol);
    g_out_lbl = gtk_label_new(out_p_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(g_out_lbl), "stat-val");
    gtk_box_pack_end(GTK_BOX(out_head_box), g_out_lbl, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), out_head_box, FALSE, FALSE, 0);

    /* Slider Output */
    g_out_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
    gtk_scale_set_draw_value(GTK_SCALE(g_out_scale), FALSE);
    gtk_range_set_value(GTK_RANGE(g_out_scale), master_out_vol);
    g_signal_connect(g_out_scale, "value-changed", G_CALLBACK(on_out_vol_changed), NULL);
    gtk_box_pack_start(GTK_BOX(main_box), g_out_scale, FALSE, FALSE, 0);

    /* Danh sách Sinks (Output Devices) */
    for (int i = 0; i < sink_count; i++) {
        char dev_lbl[128];
        snprintf(dev_lbl, sizeof(dev_lbl), "%s 󰓃 %s", sinks[i].is_active ? "✔" : " ", sinks[i].name);
        GtkWidget *btn_sink = gtk_button_new_with_label(dev_lbl);
        gtk_style_context_add_class(gtk_widget_get_style_context(btn_sink), sinks[i].is_active ? "btn-active" : "badge");
        gtk_widget_set_halign(btn_sink, GTK_ALIGN_FILL);
        if (!sinks[i].is_active) {
            g_signal_connect(btn_sink, "clicked", G_CALLBACK(on_switch_default_device), GINT_TO_POINTER(sinks[i].id));
        }
        gtk_box_pack_start(GTK_BOX(main_box), btn_sink, FALSE, FALSE, 0);
    }

    /* 6. INPUT SECTION (Microphone) */
    GtkWidget *in_head_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *lbl_in_t = gtk_label_new("INPUT");
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_in_t), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(lbl_in_t), 0.0f);
    gtk_box_pack_start(GTK_BOX(in_head_box), lbl_in_t, TRUE, TRUE, 0);

    char in_p_str[16];
    snprintf(in_p_str, sizeof(in_p_str), "%d%%", master_in_vol);
    g_in_lbl = gtk_label_new(in_p_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(g_in_lbl), "stat-val");
    gtk_box_pack_end(GTK_BOX(in_head_box), g_in_lbl, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), in_head_box, FALSE, FALSE, 4);

    /* Slider Input */
    g_in_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
    gtk_scale_set_draw_value(GTK_SCALE(g_in_scale), FALSE);
    gtk_range_set_value(GTK_RANGE(g_in_scale), master_in_vol);
    g_signal_connect(g_in_scale, "value-changed", G_CALLBACK(on_in_vol_changed), NULL);
    gtk_box_pack_start(GTK_BOX(main_box), g_in_scale, FALSE, FALSE, 0);

    /* Danh sách Sources (Input Mics) */
    for (int i = 0; i < source_count; i++) {
        char dev_lbl[128];
        snprintf(dev_lbl, sizeof(dev_lbl), "%s 󰍬 %s", sources[i].is_active ? "✔" : " ", sources[i].name);
        GtkWidget *btn_src = gtk_button_new_with_label(dev_lbl);
        gtk_style_context_add_class(gtk_widget_get_style_context(btn_src), sources[i].is_active ? "btn-active" : "badge");
        gtk_widget_set_halign(btn_src, GTK_ALIGN_FILL);
        if (!sources[i].is_active) {
            g_signal_connect(btn_src, "clicked", G_CALLBACK(on_switch_default_device), GINT_TO_POINTER(sources[i].id));
        }
        gtk_box_pack_start(GTK_BOX(main_box), btn_src, FALSE, FALSE, 0);
    }

    /* 7. SOURCES SECTION (App Streams) */
    if (g_stream_count > 0) {
        GtkWidget *st_head_lbl = gtk_label_new("SOURCES (ỨNG DỤNG ĐANG PHÁT)");
        gtk_style_context_add_class(gtk_widget_get_style_context(st_head_lbl), "subtitle-label");
        gtk_label_set_xalign(GTK_LABEL(st_head_lbl), 0.0f);
        gtk_box_pack_start(GTK_BOX(main_box), st_head_lbl, FALSE, FALSE, 4);

        for (int i = 0; i < g_stream_count; i++) {
            GtkWidget *app_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);

            GtkWidget *app_row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
            char app_name_lbl[64];
            snprintf(app_name_lbl, sizeof(app_name_lbl), "󰕾 %s", g_streams[i].name);
            GtkWidget *lbl_app = gtk_label_new(app_name_lbl);
            gtk_style_context_add_class(gtk_widget_get_style_context(lbl_app), "metric-sub");
            gtk_label_set_xalign(GTK_LABEL(lbl_app), 0.0f);
            gtk_box_pack_start(GTK_BOX(app_row), lbl_app, TRUE, TRUE, 0);

            char app_vol_str[16];
            snprintf(app_vol_str, sizeof(app_vol_str), "%d%%", g_streams[i].vol);
            g_streams[i].lbl_val = gtk_label_new(app_vol_str);
            gtk_style_context_add_class(gtk_widget_get_style_context(g_streams[i].lbl_val), "stat-val");
            gtk_box_pack_end(GTK_BOX(app_row), g_streams[i].lbl_val, FALSE, FALSE, 0);
            gtk_box_pack_start(GTK_BOX(app_box), app_row, FALSE, FALSE, 0);

            GtkWidget *app_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
            gtk_scale_set_draw_value(GTK_SCALE(app_scale), FALSE);
            gtk_range_set_value(GTK_RANGE(app_scale), g_streams[i].vol);
            g_streams[i].scale = app_scale;
            g_signal_connect(app_scale, "value-changed", G_CALLBACK(on_stream_vol_changed), &g_streams[i]);
            gtk_box_pack_start(GTK_BOX(app_box), app_scale, FALSE, FALSE, 0);

            gtk_box_pack_start(GTK_BOX(main_box), app_box, FALSE, FALSE, 2);
        }
    }

    build_footer(main_box, "Cuộn chuột để tăng/giảm • Esc để đóng");

    gtk_widget_add_events(win, GDK_SCROLL_MASK);
    g_signal_connect(win, "scroll-event", G_CALLBACK(on_vol_scroll), NULL);
    g_signal_connect(win, "destroy", G_CALLBACK(on_vol_destroy), NULL);

    return win;
}
