/* ==============================================================================
 * ka-pop: Theme Loading & CSS Provider
 * ============================================================================== */

#include "theme.h"

ThemeColors g_theme;

void load_theme_colors(ThemeColors *colors) {
    if (!colors) return;

    /* Defaults: Nord Palette */
    strncpy(colors->bg, "2e3440", sizeof(colors->bg) - 1);
    strncpy(colors->fg, "d8dee9", sizeof(colors->fg) - 1);
    strncpy(colors->card_bg, "3b4252", sizeof(colors->card_bg) - 1);
    strncpy(colors->accent, "88c0d0", sizeof(colors->accent) - 1);
    strncpy(colors->border, "4c566a", sizeof(colors->border) - 1);
    strncpy(colors->red, "bf616a", sizeof(colors->red) - 1);
    strncpy(colors->green, "a3be8c", sizeof(colors->green) - 1);
    strncpy(colors->yellow, "ebcb8b", sizeof(colors->yellow) - 1);
    strncpy(colors->subtext, "rgba(216, 222, 233, 0.70)", sizeof(colors->subtext) - 1);

    const char *home = getenv("HOME");
    if (!home) return;

    char path[512];
    snprintf(path, sizeof(path), "%s/.config/theme/colors/current.conf", home);

    FILE *f = fopen(path, "r");
    if (!f) return;

    char line[256];
    while (fgets(line, sizeof(line), f)) {
        char *eq = strchr(line, '=');
        if (!eq) continue;
        *eq = '\0';
        char *key = line;
        char *val = eq + 1;

        /* Trim spaces from key */
        while (*key == ' ' || *key == '\t') key++;
        char *end_k = key + strlen(key) - 1;
        while (end_k > key && (*end_k == ' ' || *end_k == '\t' || *end_k == '\n' || *end_k == '\r')) {
            *end_k = '\0';
            end_k--;
        }

        /* Trim spaces and quotes from value */
        while (*val == ' ' || *val == '\t' || *val == '"' || *val == '\'') val++;
        char *hash = strchr(val, '#');
        if (hash) *hash = '\0';
        char *end_v = val + strlen(val) - 1;
        while (end_v > val && (*end_v == ' ' || *end_v == '\t' || *end_v == '\n' || *end_v == '\r' || *end_v == '"' || *end_v == '\'')) {
            *end_v = '\0';
            end_v--;
        }

        if (strcmp(key, "BG") == 0) strncpy(colors->bg, val, sizeof(colors->bg) - 1);
        else if (strcmp(key, "FG") == 0) strncpy(colors->fg, val, sizeof(colors->fg) - 1);
        else if (strcmp(key, "COLOR0") == 0 || strcmp(key, "SURFACE") == 0) strncpy(colors->card_bg, val, sizeof(colors->card_bg) - 1);
        else if (strcmp(key, "ACCENT") == 0) strncpy(colors->accent, val, sizeof(colors->accent) - 1);
        else if (strcmp(key, "COLOR8") == 0 || strcmp(key, "BORDER") == 0) strncpy(colors->border, val, sizeof(colors->border) - 1);
        else if (strcmp(key, "COLOR1") == 0) strncpy(colors->red, val, sizeof(colors->red) - 1);
        else if (strcmp(key, "COLOR2") == 0) strncpy(colors->green, val, sizeof(colors->green) - 1);
        else if (strcmp(key, "COLOR3") == 0) strncpy(colors->yellow, val, sizeof(colors->yellow) - 1);
    }
    fclose(f);
}

void apply_theme_css(GtkWidget *window, const ThemeColors *c) {
    if (!c) return;

    char css[3072];
    snprintf(css, sizeof(css),
        "* {"
        "  font-family: 'JetBrains Mono', 'Symbols Nerd Font', sans-serif;"
        "}"
        "window {"
        "  background-color: transparent;"
        "}"
        ".popover-box {"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border: 2px solid #%s;"
        "  border-radius: 0px;"
        "  padding: 16px 18px;"
        "}"
        ".title-label {"
        "  font-size: 13px;"
        "  font-weight: 700;"
        "  color: #%s;"
        "}"
        ".subtitle-label {"
        "  font-size: 11px;"
        "  font-weight: 500;"
        "  color: %s;"
        "}"
        ".metric-big {"
        "  font-size: 22px;"
        "  font-weight: 800;"
        "  color: #%s;"
        "}"
        ".metric-sub {"
        "  font-size: 12px;"
        "  color: %s;"
        "}"
        ".stat-val {"
        "  font-size: 13px;"
        "  font-weight: 700;"
        "  color: #%s;"
        "}"
        ".badge {"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border: 1px solid #%s;"
        "  border-radius: 0px;"
        "  padding: 4px 8px;"
        "  font-size: 11px;"
        "  font-weight: 600;"
        "}"
        ".action-btn {"
        "  background-image: none;"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border: 1px solid #%s;"
        "  border-radius: 0px;"
        "  padding: 5px 12px;"
        "  font-size: 11px;"
        "  font-weight: 600;"
        "}"
        ".action-btn:hover {"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border-color: #%s;"
        "}"
        "scale trough {"
        "  min-height: 8px;"
        "  border-radius: 0px;"
        "  background-color: rgba(255, 255, 255, 0.15);"
        "}"
        "scale highlight {"
        "  border-radius: 0px;"
        "  background-color: #%s;"
        "}"
        "scale slider {"
        "  min-width: 14px;"
        "  min-height: 18px;"
        "  margin: -5px 0;"
        "  border-radius: 0px;"
        "  background-color: #%s;"
        "  border: 1px solid #%s;"
        "}"
        "calendar {"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border: 1px solid #%s;"
        "  border-radius: 0px;"
        "}"
        "treeview {"
        "  background-color: #%s;"
        "  color: #%s;"
        "  border: 1px solid #%s;"
        "}"
        "treeview:selected {"
        "  background-color: #%s;"
        "  color: #%s;"
        "}"
        "textview {"
        "  background-color: #%s;"
        "  color: #%s;"
        "}"
        "textview text {"
        "  background-color: #%s;"
        "  color: #%s;"
        "}",
        c->bg, c->fg, c->accent,
        c->fg, c->subtext,
        c->accent, c->subtext, c->accent,
        c->card_bg, c->accent, c->border,
        c->card_bg, c->fg, c->border,
        c->accent, c->bg, c->accent,
        c->accent, c->accent, c->bg,
        c->card_bg, c->fg, c->border,
        c->card_bg, c->fg, c->border,
        c->accent, c->bg,
        c->card_bg, c->fg,
        c->card_bg, c->fg
    );

    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    if (window) {
        GtkStyleContext *context = gtk_widget_get_style_context(window);
        gtk_style_context_add_provider(context, GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);
}
