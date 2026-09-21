/* ==============================================================================
 * ka-pop: Utility Functions (Safe String, Process Spawning, File I/O)
 * ============================================================================== */

#ifndef KA_POP_UTIL_H
#define KA_POP_UTIL_H

#include "common.h"

void spawn_async(const char *cmd);
int read_int_from_file(const char *path, int fallback);
int read_str_from_file(const char *path, char *buf, size_t buf_size);

#endif /* KA_POP_UTIL_H */
