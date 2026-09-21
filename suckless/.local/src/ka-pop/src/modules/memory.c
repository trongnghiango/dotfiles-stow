/* ==============================================================================
 * ka-pop: Memory Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"
#include <dirent.h>

static void on_open_btop_mem(GtkButton *btn, gpointer user_data) {
    (void)btn;
    (void)user_data;
    char *args[] = {(char *)"st", (char *)"-e", (char *)"btop", NULL};
    spawn_cmd(args);
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

    /* Native C /proc memory scanner (Zero-Fork, Zero-Shell, 0.002s) */
    typedef struct {
        char comm[64];
        unsigned long rss_pages;
    } ProcMem;

    ProcMem top[4] = {{{0}, 0}};
    DIR *dir = opendir("/proc");
    if (dir) {
        struct dirent *ent;
        while ((ent = readdir(dir))) {
            if (ent->d_name[0] >= '0' && ent->d_name[0] <= '9') {
                char path[128];
                snprintf(path, sizeof(path), "/proc/%s/statm", ent->d_name);
                FILE *f = fopen(path, "r");
                if (!f) continue;
                unsigned long total_p = 0, rss = 0;
                if (fscanf(f, "%lu %lu", &total_p, &rss) == 2 && rss > 0) {
                    fclose(f);
                    snprintf(path, sizeof(path), "/proc/%s/comm", ent->d_name);
                    f = fopen(path, "r");
                    char comm[64] = "unknown";
                    if (f) {
                        if (fgets(comm, sizeof(comm), f)) {
                            char *nl = strchr(comm, '\n');
                            if (nl) *nl = '\0';
                        }
                        fclose(f);
                    }

                    for (int i = 0; i < 4; i++) {
                        if (rss > top[i].rss_pages) {
                            for (int j = 3; j > i; j--) top[j] = top[j-1];
                            top[i].rss_pages = rss;
                            strncpy(top[i].comm, comm, sizeof(top[i].comm)-1);
                            top[i].comm[sizeof(top[i].comm)-1] = '\0';
                            break;
                        }
                    }
                } else {
                    fclose(f);
                }
            }
        }
        closedir(dir);
    }

    for (int i = 0; i < 4; i++) {
        if (top[i].rss_pages > 0) {
            unsigned long rss_mb = (top[i].rss_pages * 4) / 1024;
            float mem_p = total_ram > 0 ? ((float)(top[i].rss_pages * 4) * 100.0f / (float)total_ram) : 0.0f;
            char row_str[128];
            snprintf(row_str, sizeof(row_str), "  %-18s %4lu MB (%4.1f%%)", top[i].comm, rss_mb, mem_p);
            GtkWidget *lbl_r = gtk_label_new(row_str);
            gtk_label_set_xalign(GTK_LABEL(lbl_r), 0.0f);
            gtk_box_pack_start(GTK_BOX(procs_box), lbl_r, FALSE, FALSE, 0);
        }
    }
    gtk_box_pack_start(GTK_BOX(main_box), procs_box, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    return win;
}
