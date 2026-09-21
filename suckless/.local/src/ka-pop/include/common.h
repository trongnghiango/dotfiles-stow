/* ==============================================================================
 * ka-pop: Common Definitions & Safety Macros
 * ============================================================================== */

#ifndef KA_POP_COMMON_H
#define KA_POP_COMMON_H

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <dirent.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>

#define SAFE_FREE(p) do { if (p) { free(p); (p) = NULL; } } while(0)
#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

typedef struct {
    char bg[8];
    char fg[8];
    char card_bg[8];
    char accent[8];
    char border[8];
    char red[8];
    char green[8];
    char yellow[8];
    char subtext[32];
} ThemeColors;

extern ThemeColors g_theme;

#endif /* KA_POP_COMMON_H */
