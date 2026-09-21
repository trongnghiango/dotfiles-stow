/* ==============================================================================
 * ka-pop: Network Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_dns_dhcp(GtkButton *b, gpointer u) { (void)b; (void)u; system("set-dns dhcp"); gtk_main_quit(); }
static void on_dns_cf(GtkButton *b, gpointer u) { (void)b; (void)u; system("set-dns cloudflare"); gtk_main_quit(); }
static void on_dns_gg(GtkButton *b, gpointer u) { (void)b; (void)u; system("set-dns google"); gtk_main_quit(); }

GtkWidget* build_network_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("network", 360, &main_box);

    build_header(main_box, "Kết nối mạng", "Wi-Fi, Ethernet & DNS", NULL);

    char ip_buf[64] = "127.0.0.1";
    FILE *p = popen("ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}'", "r");
    if (p) {
        if (fgets(ip_buf, sizeof(ip_buf), p)) {
            char *nl = strchr(ip_buf, '\n');
            if (nl) *nl = '\0';
        }
        pclose(p);
    }

    char net_info[128];
    snprintf(net_info, sizeof(net_info), "󰤨  IP: %s", ip_buf);
    GtkWidget *lbl_ip = gtk_label_new(net_info);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_ip), "metric-big");
    gtk_label_set_xalign(GTK_LABEL(lbl_ip), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), lbl_ip, FALSE, FALSE, 0);

    GtkWidget *dns_title = gtk_label_new("CHUYỂN ĐỔI NHANH DNS:");
    gtk_style_context_add_class(gtk_widget_get_style_context(dns_title), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(dns_title), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), dns_title, FALSE, FALSE, 0);

    GtkWidget *dns_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *btn_dhcp = gtk_button_new_with_label("DHCP");
    GtkWidget *btn_cf = gtk_button_new_with_label("Cloudflare (1.1.1.1)");
    GtkWidget *btn_gg = gtk_button_new_with_label("Google (8.8.8.8)");

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

    build_footer(main_box, "Esc để đóng");
    return win;
}
