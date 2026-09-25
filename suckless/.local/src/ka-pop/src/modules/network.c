/* ==============================================================================
 * ka-pop: Network Module — Comprehensive Wi-Fi & DNS Control Center
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

    /* 1. Lấy thông tin kết nối hiện tại */
    char active_ssid[64] = "Chưa kết nối Wi-Fi";
    char active_freq[32] = "N/A";
    char active_signal[16] = "0%";
    char active_bars[16] = "____";
    char ip_buf[64] = "127.0.0.1";
    char gw_buf[64] = "N/A";
    int is_connected = 0;

    char out_buf[1024] = {0};
    char *active_args[] = {(char *)"nmcli", (char *)"-t", (char *)"-f", (char *)"active,ssid,signal,bars,freq", (char *)"dev", (char *)"wifi", NULL};
    if (exec_capture(active_args, out_buf, sizeof(out_buf)) == 0) {
        char *line = strtok(out_buf, "\n");
        while (line) {
            if (strncmp(line, "yes:", 4) == 0) {
                is_connected = 1;
                char yes_tag[8], s_name[64], s_sig[16], s_bars[16], s_freq[32];
                if (sscanf(line, "%7[^:]:%63[^:]:%15[^:]:%15[^:]:%31s", yes_tag, s_name, s_sig, s_bars, s_freq) >= 2) {
                    strncpy(active_ssid, s_name, sizeof(active_ssid) - 1);
                    if (s_sig[0]) snprintf(active_signal, sizeof(active_signal), "%s%%", s_sig);
                    if (s_bars[0]) strncpy(active_bars, s_bars, sizeof(active_bars) - 1);
                    if (s_freq[0]) {
                        int f_mhz = atoi(s_freq);
                        if (f_mhz > 4000) snprintf(active_freq, sizeof(active_freq), "5 GHz (%d MHz)", f_mhz);
                        else snprintf(active_freq, sizeof(active_freq), "2.4 GHz (%d MHz)", f_mhz);
                    }
                }
                break;
            }
            line = strtok(NULL, "\n");
        }
    }

    /* Lấy IP và Gateway */
    char ip_out[256] = {0};
    char *ip_args[] = {(char *)"ip", (char *)"-4", (char *)"route", (char *)"get", (char *)"1.1.1.1", NULL};
    if (exec_capture(ip_args, ip_out, sizeof(ip_out)) == 0) {
        char *p_src = strstr(ip_out, "src ");
        if (p_src) sscanf(p_src + 4, "%63s", ip_buf);
        char *p_via = strstr(ip_out, "via ");
        if (p_via) sscanf(p_via + 4, "%63s", gw_buf);
    }

    /* Header */
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

    /* 2. Thống kê IP & Gateway */
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

    /* 3. Nút tác vụ điều khiển nhanh (Thay thế hoàn toàn nmtui) */
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

    /* 4. Quét danh sách 5 mạng Wi-Fi mạnh nhất gần đây để click kết nối nhanh */
    GtkWidget *wifi_title = gtk_label_new("MẠNG WI-FI KHẢ DỤNG GẦN ĐÂY:");
    gtk_style_context_add_class(gtk_widget_get_style_context(wifi_title), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(wifi_title), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), wifi_title, FALSE, FALSE, 4);

    char scan_buf[2048] = {0};
    char *scan_args[] = {(char *)"nmcli", (char *)"-t", (char *)"-f", (char *)"SSID,SIGNAL,BARS,SECURITY", (char *)"dev", (char *)"wifi", (char *)"list", NULL};
    if (exec_capture(scan_args, scan_buf, sizeof(scan_buf)) == 0) {
        char *line = strtok(scan_buf, "\n");
        int count = 0;
        char seen_ssids[6][64] = {{0}};

        while (line && count < 5) {
            char ssid_cand[64] = {0};
            char sig_cand[16] = {0};
            char bars_cand[16] = {0};
            char sec_cand[32] = {0};

            if (sscanf(line, "%63[^:]:%15[^:]:%15[^:]:%31s", ssid_cand, sig_cand, bars_cand, sec_cand) >= 2) {
                if (ssid_cand[0] && strcmp(ssid_cand, "--") != 0) {
                    /* Kiểm tra trùng lặp */
                    int dup = 0;
                    for (int k = 0; k < count; k++) {
                        if (strcmp(seen_ssids[k], ssid_cand) == 0) { dup = 1; break; }
                    }

                    if (!dup) {
                        strncpy(seen_ssids[count], ssid_cand, sizeof(seen_ssids[count]) - 1);
                        int is_current = (strcmp(ssid_cand, active_ssid) == 0);
                        const char *lock_ico = (strstr(sec_cand, "WPA") || strstr(sec_cand, "WEP")) ? "🔒" : "🔓";

                        char btn_label[128];
                        if (is_current) {
                            snprintf(btn_label, sizeof(btn_label), "✔ %s (%s%%) [Đang dùng]", ssid_cand, sig_cand);
                        } else {
                            snprintf(btn_label, sizeof(btn_label), "󰤨 %s (%s%%) %s", ssid_cand, sig_cand, lock_ico);
                        }

                        GtkWidget *net_btn = gtk_button_new_with_label(btn_label);
                        gtk_style_context_add_class(gtk_widget_get_style_context(net_btn), "badge");
                        gtk_widget_set_halign(net_btn, GTK_ALIGN_FILL);

                        /* Gán con trỏ chuỗi SSID cho handler click */
                        char *ssid_heap = strdup(ssid_cand);
                        g_signal_connect_data(net_btn, "clicked", G_CALLBACK(on_connect_network), ssid_heap, (GClosureNotify)free, 0);

                        gtk_box_pack_start(GTK_BOX(main_box), net_btn, FALSE, FALSE, 0);
                        count++;
                    }
                }
            }
            line = strtok(NULL, "\n");
        }
    }

    /* 5. Bộ đổi nhanh DNS */
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
