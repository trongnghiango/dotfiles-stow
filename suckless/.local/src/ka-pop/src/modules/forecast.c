/* ==============================================================================
 * ka-pop: Forecast Module — Vi khí hậu & Radar mưa tức thời (Nowcasting 1km²)
 * Đồng bộ 100% biểu tượng thời tiết với statusbar dwmblocks
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_refresh_weather(GtkButton *b, gpointer u) {
    (void)b; (void)u;
    char *args[] = {(char *)"ka-weather", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

GtkWidget* build_forecast_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("forecast", 380, &main_box);

    const char *home = getenv("HOME");
    char cache_path[512];
    snprintf(cache_path, sizeof(cache_path), "%s/.cache/weatherreport", home ? home : "/tmp");

    FILE *f = fopen(cache_path, "r");
    if (!f) {
        f = fopen("/tmp/weatherreport", "r");
    }

    char city_str[64] = "Gò Vấp, TP.HCM";
    char temp_str[32] = "--°C";
    char feels_str[64] = "Cảm giác như --°C";
    char desc_str[64] = "Chưa có dữ liệu thời tiết";
    char icon_str[16] = "󰖕";
    int humidity = 80;
    int wind_speed = 5;
    int rain_soon = 0;
    char rain_time[16] = "";
    int rain_prob = 0;
    float rain_mm = 0.0f;

    typedef struct {
        char time[16];
        char icon[16];
        float mm;
    } TimeStep;
    TimeStep steps[4];
    int step_count = 0;

    if (f) {
        char buf[4096] = {0};
        size_t n = fread(buf, 1, sizeof(buf) - 1, f);
        buf[n] = '\0';
        fclose(f);

        char *p_city = strstr(buf, "\"city\":\"");
        if (p_city) sscanf(p_city + 8, "%63[^\"]", city_str);

        char *p_temp = strstr(buf, "\"temp\":");
        if (p_temp) {
            int t = 0;
            if (sscanf(p_temp + 7, "%d", &t) == 1) snprintf(temp_str, sizeof(temp_str), "%d°C", t);
        }

        char *p_feels = strstr(buf, "\"feels_like\":");
        if (p_feels) {
            int fl = 0;
            if (sscanf(p_feels + 13, "%d", &fl) == 1) snprintf(feels_str, sizeof(feels_str), "Cảm giác như %d°C", fl);
        }

        char *p_desc = strstr(buf, "\"desc\":\"");
        if (p_desc) sscanf(p_desc + 8, "%63[^\"]", desc_str);

        char *p_icon = strstr(buf, "\"icon\":\"");
        if (p_icon) sscanf(p_icon + 8, "%15[^\"]", icon_str);

        char *p_hum = strstr(buf, "\"humidity\":");
        if (p_hum) sscanf(p_hum + 11, "%d", &humidity);

        char *p_wind = strstr(buf, "\"wind_speed\":");
        if (p_wind) sscanf(p_wind + 13, "%d", &wind_speed);

        char *p_rsoon = strstr(buf, "\"rain_soon\":");
        if (p_rsoon) sscanf(p_rsoon + 12, "%d", &rain_soon);

        char *p_rtime = strstr(buf, "\"rain_soon_time\":\"");
        if (p_rtime) sscanf(p_rtime + 18, "%15[^\"]", rain_time);

        char *p_rprob = strstr(buf, "\"rain_soon_prob\":");
        if (p_rprob) sscanf(p_rprob + 17, "%d", &rain_prob);

        char *p_rmm = strstr(buf, "\"rain_soon_mm\":");
        if (p_rmm) sscanf(p_rmm + 15, "%f", &rain_mm);

        /* Bóc tách các mốc 15 phút từ timeline */
        char *p_tl = strstr(buf, "\"timeline\":[");
        if (p_tl) {
            char *cur = p_tl + 12;
            while (step_count < 4) {
                char *item = strstr(cur, "{\"time\":\"");
                if (!item) break;
                sscanf(item + 9, "%15[^\"]", steps[step_count].time);

                char *p_mm = strstr(item, "\"mm\":");
                if (p_mm) sscanf(p_mm + 5, "%f", &steps[step_count].mm);

                char *p_ico = strstr(item, "\"icon\":\"");
                if (p_ico) sscanf(p_ico + 8, "%15[^\"]", steps[step_count].icon);
                else strncpy(steps[step_count].icon, "󰖕", sizeof(steps[step_count].icon) - 1);

                step_count++;
                cur = item + 10;
            }
        }
    }

    /* 1. Header: Vị trí & Nút làm mới */
    GtkWidget *btn_ref = gtk_button_new_with_label("🔄 Cập nhật");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_ref), "action-btn");
    g_signal_connect(btn_ref, "clicked", G_CALLBACK(on_refresh_weather), NULL);

    build_header(main_box, city_str, "Dự báo vi khí hậu • Radar mưa 15 phút", btn_ref);

    /* 2. Tile nhiệt độ & Biểu tượng chính (Đồng bộ tuyệt đối với dwmblocks) */
    GtkWidget *tile = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 14);
    GtkWidget *lbl_ico = gtk_label_new(icon_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_ico), "metric-big");
    gtk_box_pack_start(GTK_BOX(tile), lbl_ico, FALSE, FALSE, 0);

    GtkWidget *t_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    GtkWidget *lbl_t = gtk_label_new(temp_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_t), "metric-big");
    gtk_label_set_xalign(GTK_LABEL(lbl_t), 0.0f);
    gtk_box_pack_start(GTK_BOX(t_box), lbl_t, FALSE, FALSE, 0);

    char sub_stat[128];
    snprintf(sub_stat, sizeof(sub_stat), "%s • %s", feels_str, desc_str);
    GtkWidget *lbl_d = gtk_label_new(sub_stat);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_d), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(lbl_d), 0.0f);
    gtk_box_pack_start(GTK_BOX(t_box), lbl_d, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(tile), t_box, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), tile, FALSE, FALSE, 0);

    /* 3. Phân vùng Radar mưa tức thời (Nowcasting 1km²) */
    GtkWidget *rain_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
    if (rain_soon && rain_time[0]) {
        char rain_warn[256];
        snprintf(rain_warn, sizeof(rain_warn), "🌧 SẮP CÓ MƯA VÀO LÚC %s\nXác suất: %d%% • Dự kiến: %.1f mm", rain_time, rain_prob, rain_mm);
        GtkWidget *lbl_warn = gtk_label_new(rain_warn);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_warn), "btn-active");
        gtk_label_set_xalign(GTK_LABEL(lbl_warn), 0.0f);
        gtk_box_pack_start(GTK_BOX(rain_box), lbl_warn, FALSE, FALSE, 0);
    } else {
        char rain_ok[256];
        snprintf(rain_ok, sizeof(rain_ok), "󰖙 KHÔNG CÓ MƯA TRONG 2 GIỜ TỚI\nĐộ ẩm: %d%% • Gió: %d km/h • Xác suất mưa: %d%%", humidity, wind_speed, rain_prob);
        GtkWidget *lbl_ok = gtk_label_new(rain_ok);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_ok), "badge");
        gtk_label_set_xalign(GTK_LABEL(lbl_ok), 0.0f);
        gtk_box_pack_start(GTK_BOX(rain_box), lbl_ok, FALSE, FALSE, 0);
    }
    gtk_box_pack_start(GTK_BOX(main_box), rain_box, FALSE, FALSE, 2);

    /* 4. Biểu đồ mưa mốc 15 phút (Nowcasting Timeline) */
    if (step_count > 0) {
        GtkWidget *tl_title = gtk_label_new("DỰ BÁO LƯỢNG MƯA 15 PHÚT TỚI (1 KM²):");
        gtk_style_context_add_class(gtk_widget_get_style_context(tl_title), "subtitle-label");
        gtk_label_set_xalign(GTK_LABEL(tl_title), 0.0f);
        gtk_box_pack_start(GTK_BOX(main_box), tl_title, FALSE, FALSE, 2);

        GtkWidget *tl_row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
        for (int i = 0; i < step_count; i++) {
            GtkWidget *step_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
            gtk_style_context_add_class(gtk_widget_get_style_context(step_box), (steps[i].mm > 0.1f) ? "btn-active" : "action-btn");

            GtkWidget *l_time = gtk_label_new(steps[i].time);
            gtk_style_context_add_class(gtk_widget_get_style_context(l_time), "stat-val");

            GtkWidget *l_ico = gtk_label_new(steps[i].icon);
            gtk_style_context_add_class(gtk_widget_get_style_context(l_ico), "metric-sub");

            char mm_str[16];
            snprintf(mm_str, sizeof(mm_str), "%.1fmm", steps[i].mm);
            GtkWidget *l_mm = gtk_label_new(mm_str);
            gtk_style_context_add_class(gtk_widget_get_style_context(l_mm), "subtitle-label");

            gtk_box_pack_start(GTK_BOX(step_box), l_time, FALSE, FALSE, 0);
            gtk_box_pack_start(GTK_BOX(step_box), l_ico, FALSE, FALSE, 0);
            gtk_box_pack_start(GTK_BOX(step_box), l_mm, FALSE, FALSE, 0);

            gtk_box_pack_start(GTK_BOX(tl_row), step_box, TRUE, TRUE, 0);
        }
        gtk_box_pack_start(GTK_BOX(main_box), tl_row, FALSE, FALSE, 0);
    }

    build_footer(main_box, "Esc để đóng • Click chuột phải icon bar để cập nhật nhanh");
    return win;
}
