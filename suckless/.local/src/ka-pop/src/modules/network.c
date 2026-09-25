/* ==============================================================================
 * ka-pop: Network Module — Ultra-Fast Wi-Fi & DNS Control Center (< 80ms)
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_dns_dhcp(GtkButton *b, gpointer u) { (void)b; (void)u; char *args[] = {(char *)"set-dns", (char *)"dhcp", NULL}; spawn_cmd(args); gtk_main_quit(); }
static void on_dns_cf(GtkButton *b, gpointer u) { (void)b; (void)u; char *args[] = {(char *)"set-dns", (char *)"cloudflare", NULL}; spawn_cmd(args); gtk_main_quit(); }
static void on_dns_gg(GtkButton *b, gpointer u) { (void)b; (void)u; char *args[] = {(char *)"set-dns", (char *)"google", NULL}; spawn_cmd(args); gtk_main_quit(); }

static void on_open_wifi_manager(GtkButton *b, gpointer u) {
    (void)b; (void)u;
    char *args[] = {(char *)"ka-wifi", (char *)"menu", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

static void on_open_wifi_qr(GtkButton *b, gpointer u) {
    (void)b; (void)u;
    char *args[] = {(char *)"ka-wifi", (char *)"qr", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

static void on_wifi_toggle(GtkButton *b, gpointer u) {
    (void)b; (void)u;
    char *args[] = {(char *)"ka-wifi", (char *)"toggle", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

static void on_connect_network(GtkButton *b, gpointer u) {
    (void)b;
    char *ssid = (char *)u;
    if (ssid && ssid[0]) {
        char *args[] = {(char *)"ka-wifi", (char *)"connect", ssid, NULL};
        spawn_cmd(args);
    }
    gtk_main_quit();
}

GtkWidget* build_network_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("network", 380, &main_box);

    /* 1. Độc nhất 1 lệnh nmcli thu thập cả mạng hiện tại và mạng xung quanh trong ~70ms */
    char active_ssid[64] = "Chưa kết nối Wi-Fi";
    char active_freq[32] = "N/A";
    char active_signal[16] = "0%";
    char ip_buf[64] = "127.0.0.1";
    char gw_buf[64] = "N/A";
    int is_connected = 0;

    typedef struct {
        char ssid[64];
        char signal[16];
        char sec[32];
        int is_active;
    } NetCandidate;

    NetCandidate candidates[5];
    int candidate_count = 0;

    char scan_buf[4096] = {0};
    char *scan_args[] = {(char *)"nmcli", (char *)"-t", (char *)"-f", (char *)"IN-USE,SSID,SIGNAL,BARS,SECURITY,FREQ", (char *)"dev", (char *)"wifi", (char *)"list", (char *)"--rescan", (char *)"no", NULL};
    if (exec_capture(scan_args, scan_buf, sizeof(scan_buf)) == 0) {
        char *saveptr = NULL;
        char *line = strtok_r(scan_buf, "\n", &saveptr);

        while (line) {
            char in_use[8] = {0};
            char s_name[64] = {0};
            char s_sig[16] = {0};
            char s_bars[16] = {0};
            char s_sec[32] = {0};
            char s_freq[32] = {0};

            /* Định dạng: IN-USE:SSID:SIGNAL:BARS:SECURITY:FREQ */
            if (sscanf(line, "%7[^:]:%63[^:]:%15[^:]:%15[^:]:%31[^:]:%31s", in_use, s_name, s_sig, s_bars, s_sec, s_freq) >= 2) {
                if (s_name[0] && strcmp(s_name, "--") != 0) {
                    int active_flag = (in_use[0] == '*');

                    if (active_flag && !is_connected) {
                        is_connected = 1;
                        strncpy(active_ssid, s_name, sizeof(active_ssid) - 1);
                        if (s_sig[0]) snprintf(active_signal, sizeof(active_signal), "%s%%", s_sig);
                        if (s_freq[0]) {
                            int f_mhz = atoi(s_freq);
                            if (f_mhz > 4000) snprintf(active_freq, sizeof(active_freq), "5 GHz (%d MHz)", f_mhz);
                            else snprintf(active_freq, sizeof(active_freq), "2.4 GHz (%d MHz)", f_mhz);
                        }
                    }

                    /* Thu thập tối đa 5 mạng độc nhất để tạo nút bấm nhanh */
                    if (candidate_count < 5) {
                        int dup = 0;
                        for (int k = 0; k < candidate_count; k++) {
                            if (strcmp(candidates[k].ssid, s_name) == 0) { dup = 1; break; }
                        }
                        if (!dup) {
                            strncpy(candidates[candidate_count].ssid, s_name, sizeof(candidates[candidate_count].ssid) - 1);
                            strncpy(candidates[candidate_count].signal, s_sig[0] ? s_sig : "50", sizeof(candidates[candidate_count].signal) - 1);
                            strncpy(candidates[candidate_count].sec, s_sec, sizeof(candidates[candidate_count].sec) - 1);
                            candidates[candidate_count].is_active = active_flag;
                            candidate_count++;
                        }
                    }
                }
            }
            line = strtok_r(NULL, "\n", &saveptr);
        }
    }

    /* 2. Lấy IP và Gateway nội bộ */
    char ip_out[256] = {0};
    char *ip_args[] = {(char *)"ip", (char *)"-4", (char *)"route", (char *)"get", (char *)"1.1.1.1", NULL};
    if (exec_capture(ip_args, ip_out, sizeof(ip_out)) == 0) {
        char *p_src = strstr(ip_out, "src ");
        if (p_src) sscanf(p_src + 4, "%63s", ip_buf);
        char *p_via = strstr(ip_out, "via ");
        if (p_via) sscanf(p_via + 4, "%63s", gw_buf);
    }

    /* 3. Header hiển thị trạng thái Wi-Fi */
    char subtitle[128];
    if (is_connected) {
        snprintf(subtitle, sizeof(subtitle), "󰤨 %s • %s", active_freq, active_signal);
    } else {
        snprintf(subtitle, sizeof(subtitle), "󰤮 Thiết bị ngoại tuyến");
    }

    GtkWidget *btn_toggle = gtk_button_new_with_label(is_connected ? "󰤮 Tắt Wi-Fi" : "󰤨 Bật Wi-Fi");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_toggle), "badge");
    g_signal_connect(btn_toggle, "clicked", G_CALLBACK(on_wifi_toggle), NULL);

    build_header(main_box, is_connected ? active_ssid : "Mạng không dây", subtitle, btn_toggle);

    /* 4. Thống kê IP & Gateway */
    GtkWidget *stat_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 12);
    char ip_lbl[128], gw_lbl[128];
    snprintf(ip_lbl, sizeof(ip_lbl), "IP: %s", ip_buf);
    snprintf(gw_lbl, sizeof(gw_lbl), "Gateway: %s", gw_buf);

    GtkWidget *lbl_i = gtk_label_new(ip_lbl);
    GtkWidget *lbl_g = gtk_label_new(gw_lbl);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_i), "subtitle-label");
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_g), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(lbl_i), 0.0f);
    gtk_label_set_xalign(GTK_LABEL(lbl_g), 0.0f);
    gtk_box_pack_start(GTK_BOX(stat_box), lbl_i, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(stat_box), lbl_g, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), stat_box, FALSE, FALSE, 0);

    /* 5. Nút tác vụ điều khiển nhanh (Thay thế hoàn toàn nmtui) */
    GtkWidget *action_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *btn_manager = gtk_button_new_with_label("󱚽 Chọn mạng (Rofi)");
    GtkWidget *btn_qr = gtk_button_new_with_label("󰐲 Mã QR");

    gtk_style_context_add_class(gtk_widget_get_style_context(btn_manager), "action-btn");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_qr), "action-btn");

    g_signal_connect(btn_manager, "clicked", G_CALLBACK(on_open_wifi_manager), NULL);
    g_signal_connect(btn_qr, "clicked", G_CALLBACK(on_open_wifi_qr), NULL);

    gtk_box_pack_start(GTK_BOX(action_box), btn_manager, TRUE, TRUE, 0);
    if (is_connected) {
        gtk_box_pack_start(GTK_BOX(action_box), btn_qr, FALSE, FALSE, 0);
    }
    gtk_box_pack_start(GTK_BOX(main_box), action_box, FALSE, FALSE, 0);

    /* 6. Danh sách 5 mạng Wi-Fi mạnh nhất gần đây để click kết nối nhanh */
    if (candidate_count > 0) {
        GtkWidget *wifi_title = gtk_label_new("MẠNG WI-FI KHẢ DỤNG GẦN ĐÂY:");
        gtk_style_context_add_class(gtk_widget_get_style_context(wifi_title), "subtitle-label");
        gtk_label_set_xalign(GTK_LABEL(wifi_title), 0.0f);
        gtk_box_pack_start(GTK_BOX(main_box), wifi_title, FALSE, FALSE, 4);

        for (int i = 0; i < candidate_count; i++) {
            const char *lock_ico = (strstr(candidates[i].sec, "WPA") || strstr(candidates[i].sec, "WEP")) ? "🔒" : "🔓";
            char btn_label[128];
            if (candidates[i].is_active) {
                snprintf(btn_label, sizeof(btn_label), "✔ %s (%s%%) [Đang dùng]", candidates[i].ssid, candidates[i].signal);
            } else {
                snprintf(btn_label, sizeof(btn_label), "󰤨 %s (%s%%) %s", candidates[i].ssid, candidates[i].signal, lock_ico);
            }

            GtkWidget *net_btn = gtk_button_new_with_label(btn_label);
            gtk_style_context_add_class(gtk_widget_get_style_context(net_btn), "badge");
            gtk_widget_set_halign(net_btn, GTK_ALIGN_FILL);

            char *ssid_heap = strdup(candidates[i].ssid);
            g_signal_connect_data(net_btn, "clicked", G_CALLBACK(on_connect_network), ssid_heap, (GClosureNotify)free, 0);

            gtk_box_pack_start(GTK_BOX(main_box), net_btn, FALSE, FALSE, 0);
        }
    }

    /* 7. Bộ đổi nhanh DNS */
    GtkWidget *dns_title = gtk_label_new("CHUYỂN ĐỔI MÁY CHỦ DNS:");
    gtk_style_context_add_class(gtk_widget_get_style_context(dns_title), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(dns_title), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), dns_title, FALSE, FALSE, 4);

    GtkWidget *dns_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    GtkWidget *btn_dhcp = gtk_button_new_with_label("DHCP");
    GtkWidget *btn_cf = gtk_button_new_with_label("Cloudflare");
    GtkWidget *btn_gg = gtk_button_new_with_label("Google");

    gtk_style_context_add_class(gtk_widget_get_style_context(btn_dhcp), "action-btn");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_cf), "action-btn");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_gg), "action-btn");

    g_signal_connect(btn_dhcp, "clicked", G_CALLBACK(on_dns_dhcp), NULL);
    g_signal_connect(btn_cf, "clicked", G_CALLBACK(on_dns_cf), NULL);
    g_signal_connect(btn_gg, "clicked", G_CALLBACK(on_dns_gg), NULL);

    gtk_box_pack_start(GTK_BOX(dns_box), btn_dhcp, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(dns_box), btn_cf, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(dns_box), btn_gg, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), dns_box, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng • Click chuột phải icon bar để mở nhanh");
    return win;
}
