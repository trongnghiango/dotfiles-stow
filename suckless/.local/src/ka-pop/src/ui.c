/* ==============================================================================
 * ka-pop: UI Base Components & Event Handling
 * ============================================================================== */

#include "ui.h"
#include "theme.h"

gboolean on_key_press(GtkWidget *widget, GdkEventKey *event, gpointer user_data) {
    (void)widget;
    (void)user_data;
    if (event->keyval == GDK_KEY_Escape || event->keyval == GDK_KEY_q) {
        gtk_main_quit();
        return TRUE;
    }
    return FALSE;
}

GtkWidget* create_base_window(const char *name, int min_width, GtkWidget **main_box) {
    GtkWidget *win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    char title_buf[64];
    snprintf(title_buf, sizeof(title_buf), "dwm-dropdown-%s", name);
    gtk_window_set_title(GTK_WINDOW(win), title_buf);
    gtk_window_set_decorated(GTK_WINDOW(win), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(win), FALSE);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(win), TRUE);
    gtk_window_set_skip_pager_hint(GTK_WINDOW(win), TRUE);
    gtk_window_set_type_hint(GTK_WINDOW(win), GDK_WINDOW_TYPE_HINT_DIALOG);

    apply_theme_css(win, &g_theme);

    *main_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 12);
    gtk_style_context_add_class(gtk_widget_get_style_context(*main_box), "popover-box");
    gtk_widget_set_size_request(*main_box, min_width, -1);
    gtk_container_add(GTK_CONTAINER(win), *main_box);

    g_signal_connect(win, "key-press-event", G_CALLBACK(on_key_press), NULL);
    g_signal_connect(win, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    return win;
}

void build_header(GtkWidget *box, const char *title, const char *subtitle, GtkWidget *action) {
    GtkWidget *h_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
    GtkWidget *v_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);

    GtkWidget *lbl_t = gtk_label_new(title);
    gtk_label_set_xalign(GTK_LABEL(lbl_t), 0.0f);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl_t), "title-label");
    gtk_box_pack_start(GTK_BOX(v_box), lbl_t, FALSE, FALSE, 0);

    if (subtitle && strlen(subtitle) > 0) {
        GtkWidget *lbl_s = gtk_label_new(subtitle);
        gtk_label_set_xalign(GTK_LABEL(lbl_s), 0.0f);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_s), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(v_box), lbl_s, FALSE, FALSE, 0);
    }

    gtk_box_pack_start(GTK_BOX(h_box), v_box, TRUE, TRUE, 0);
    if (action) {
        gtk_box_pack_end(GTK_BOX(h_box), action, FALSE, FALSE, 0);
    }
    gtk_box_pack_start(GTK_BOX(box), h_box, FALSE, FALSE, 0);
}

void build_footer(GtkWidget *box, const char *hint) {
    GtkWidget *lbl = gtk_label_new(hint ? hint : "Esc để đóng");
    gtk_label_set_xalign(GTK_LABEL(lbl), 0.0f);
    gtk_style_context_add_class(gtk_widget_get_style_context(lbl), "subtitle-label");
    gtk_box_pack_start(GTK_BOX(box), lbl, FALSE, FALSE, 0);
}
