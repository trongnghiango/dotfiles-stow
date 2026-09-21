/* ==============================================================================
 * ka-pop: UI Base Window & Common Layout Components
 * ============================================================================== */

#ifndef KA_POP_UI_H
#define KA_POP_UI_H

#include "common.h"

GtkWidget* create_base_window(const char *name, int min_width, GtkWidget **main_box);
void build_header(GtkWidget *box, const char *title, const char *subtitle, GtkWidget *action);
void build_footer(GtkWidget *box, const char *hint);
gboolean on_key_press(GtkWidget *widget, GdkEventKey *event, gpointer user_data);

#endif /* KA_POP_UI_H */
