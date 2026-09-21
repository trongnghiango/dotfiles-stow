/* ==============================================================================
 * ka-pop: Memory Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_open_btop_mem(GtkButton *btn, gpointer user_data) {
    (void)btn;
    (void)user_data;
    if (fork() == 0) {
        setsid();
        execlp("st", "st", "-e", "btop", NULL);
        _exit(0);
    }
    gtk_main_quit();
}

GtkWidget* build_memory_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("memory", 360, &main_box);

    GtkWidget *btop_btn = gtk_button_new_with_label("󰘚 BTOP");
    gtk_style_context_add_class(gtk_widget_get_style_context(btop_btn), "action-btn");
    g_signal_connect(btop_btn, "clicked", G_CALLBACK(on_open_btop_mem), NULL);

    build_header(main_box, "Bộ nhớ RAM & Swap", "Memory Allocation", btop_btn);

    unsigned long total_ram = 0, avail_ram = 0;
    FILE *f_m = fopen("/proc/meminfo", "r");
    if (f_m) {
        char key[64];
        unsigned long val;
        while (fscanf(f_m, "%63s %lu kB", key, &val) == 2) {
            if (strcmp(key, "MemTotal:") == 0) total_ram = val;
            else if (strcmp(key, "MemAvailable:") == 0) avail_ram = val;
        }
        fclose(f_m);
    }

    unsigned long used_ram = (total_ram > avail_ram) ? (total_ram - avail_ram) : 0;
    char ram_str[64];
    snprintf(ram_str, sizeof(ram_str), "RAM: %lu MB / %lu MB", used_ram / 1024, total_ram / 1024);
    GtkWidget *lbl_ram = gtk_label_new(ram_str);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_ram), "metric-big");
    gtk_label_set_xalign(GTK_LABEL(lbl_ram), 0.0f);
    gtk_box_pack_start(GTK_BOX(main_box), lbl_ram, FALSE, FALSE, 0);

    /* Top Memory Processes */
    GtkWidget *procs_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 4);
    GtkWidget *p_header = gtk_label_new("TOP TIẾN TRÌNH RAM:");
    gtk_style_context_add_class(gtk_widget_get_style_context(p_header), "subtitle-label");
    gtk_label_set_xalign(GTK_LABEL(p_header), 0.0f);
    gtk_box_pack_start(GTK_BOX(procs_box), p_header, FALSE, FALSE, 0);

    FILE *p_ps = popen("ps -eo comm,%mem --sort=-%mem | head -n 5 | tail -n 4", "r");
    if (p_ps) {
        char line[128];
        while (fgets(line, sizeof(line), p_ps)) {
            char comm[64];
            float mem_p = 0;
            if (sscanf(line, "%63s %f", comm, &mem_p) >= 2) {
                char row_str[128];
                snprintf(row_str, sizeof(row_str), "  %-20s %5.1f%%", comm, mem_p);
                GtkWidget *lbl_r = gtk_label_new(row_str);
                gtk_label_set_xalign(GTK_LABEL(lbl_r), 0.0f);
                gtk_box_pack_start(GTK_BOX(procs_box), lbl_r, FALSE, FALSE, 0);
            }
        }
        pclose(p_ps);
    }
    gtk_box_pack_start(GTK_BOX(main_box), procs_box, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    return win;
}
