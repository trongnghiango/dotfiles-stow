/* ==============================================================================
 * ka-pop: CPU Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_open_btop_cpu(GtkButton *btn, gpointer user_data) {
    (void)btn;
    (void)user_data;
    char *args[] = {(char *)"st", (char *)"-e", (char *)"btop", NULL};
    spawn_cmd(args);
    gtk_main_quit();
}

GtkWidget* build_cpu_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("cpu", 360, &main_box);

    GtkWidget *btop_btn = gtk_button_new_with_label("󰍛 BTOP");
    gtk_style_context_add_class(gtk_widget_get_style_context(btop_btn), "action-btn");
    g_signal_connect(btop_btn, "clicked", G_CALLBACK(on_open_btop_cpu), NULL);

    build_header(main_box, "Hiệu năng CPU", "Hardware & Processes", btop_btn);

    /* Temperature from sysfs (zero fork) */
    int temp = 45;
    FILE *f_t = fopen("/sys/class/thermal/thermal_zone0/temp", "r");
    if (f_t) {
        int raw_t = 0;
        if (fscanf(f_t, "%d", &raw_t) == 1) temp = raw_t / 1000;
        fclose(f_t);
    }

    char stat_str[64];
    snprintf(stat_str, sizeof(stat_str), "Nhiệt độ: %d°C", temp);
    GtkWidget *lbl_stat = gtk_label_new(stat_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_stat), "stat-val");
    gtk_label_set_xalign(GTK_LABEL(lbl_stat), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), lbl_stat, FALSE, FALSE, 0);

    /* Top CPU Processes */
    GtkWidget *procs_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 4);
    GtkWidget *p_header = gtk_label_new("TOP TIẾN TRÌNH CPU:");
    gtk_style_context_add_class(gtk_widget_get_style_context(p_header), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(p_header), 0.0f);
    gtk_box_pack_start(GTK_BOX(procs_box), p_header, FALSE, FALSE, 0);

    char ps_buf[1024] = {0};
    char *ps_args[] = {(char *)"ps", (char *)"-eo", (char *)"comm,%cpu", (char *)"--sort=-%cpu", NULL};
    if (exec_capture(ps_args, ps_buf, sizeof(ps_buf)) == 0) {
        char *line = ps_buf;
        char *next_line = strchr(line, '\n');
        if (next_line) line = next_line + 1; // Skip header

        int count = 0;
        while (line && *line && count < 4) {
            next_line = strchr(line, '\n');
            if (next_line) *next_line = '\0';

            char comm[64];
            float cpu_p = 0;
            if (sscanf(line, "%63s %f", comm, &cpu_p) >= 2) {
                char row_str[128];
                snprintf(row_str, sizeof(row_str), "  %-20s %5.1f%%", comm, cpu_p);
                GtkWidget *lbl_r = gtk_label_new(row_str);
                gtk_label_set_xalign(GTK_LABEL(lbl_r), 0.0f);
                gtk_box_pack_start(GTK_BOX(procs_box), lbl_r, FALSE, FALSE, 0);
                count++;
            }
            line = next_line ? next_line + 1 : NULL;
        }
    }
    gtk_box_pack_start(GTK_BOX(main_box), procs_box, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    return win;
}
