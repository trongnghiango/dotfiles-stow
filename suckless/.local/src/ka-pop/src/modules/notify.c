/* ==============================================================================
 * ka-pop: Notification Module
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"

static void on_notif_dnd(GtkButton *b, gpointer u) { (void)b; (void)u; system("dunstctl set-paused toggle"); gtk_main_quit(); }
static void on_notif_clear(GtkButton *b, gpointer u) { (void)b; (void)u; system("dunstctl history-clear"); gtk_main_quit(); }

GtkWidget* build_notify_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("notify", 340, &main_box);

    build_header(main_box, "Trung tâm thông báo", "Dunst Notification Hub", NULL);

    GtkWidget *btn_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *btn_dnd = gtk_button_new_with_label("󰂛 Bật/Tắt DND");
    GtkWidget *btn_clear = gtk_button_new_with_label("󰆴 Xóa lịch sử");

    gtk_style_context_add_class(gtk_widget_get_style_context(btn_dnd), "action-btn");
    gtk_style_context_add_class(gtk_widget_get_style_context(btn_clear), "action-btn");

    g_signal_connect(btn_dnd, "clicked", G_CALLBACK(on_notif_dnd), NULL);
    g_signal_connect(btn_clear, "clicked", G_CALLBACK(on_notif_clear), NULL);

    gtk_box_pack_start(GTK_BOX(btn_box), btn_dnd, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(btn_box), btn_clear, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), btn_box, FALSE, FALSE, 0);

    build_footer(main_box, "Esc để đóng");
    return win;
}
