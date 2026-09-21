/* ==============================================================================
 * ka-pop: Theme Loading & CSS Generation
 * ============================================================================== */

#ifndef KA_POP_THEME_H
#define KA_POP_THEME_H

#include "common.h"

void load_theme_colors(ThemeColors *colors);
void apply_theme_css(GtkWidget *window, const ThemeColors *c);

#endif /* KA_POP_THEME_H */
