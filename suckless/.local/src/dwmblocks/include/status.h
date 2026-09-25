#ifndef STATUS_H
#define STATUS_H

#include <stdbool.h>

#include "block.h"
#include "config.h"
#include "main.h"
#include "util.h"
#include "x11.h"

typedef struct {
#define STATUS_LENGTH 1024
    char current[STATUS_LENGTH];
    char previous[STATUS_LENGTH];
#undef STATUS_LENGTH

    const block* const blocks;
    const unsigned short block_count;
} status;

status status_new(const block* const blocks, const unsigned short block_count);
bool status_update(status* const status);
int status_write(const status* const status, const bool is_debug_mode,
                 x11_connection* const connection);

#endif  // STATUS_H
