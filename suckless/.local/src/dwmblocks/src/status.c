#include "status.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "block.h"
#include "config.h"
#include "util.h"
#include "x11.h"

static bool has_status_changed(const status *const status) {
    return strcmp(status->current, status->previous) != 0;
}

status status_new(const block *const blocks,
                  const unsigned short block_count) {
    status status = {
        .current = {[0] = '\0'},
        .previous = {[0] = '\0'},

        .blocks = blocks,
        .block_count = block_count,
    };

    return status;
}

bool status_update(status *const status) {
    memcpy(status->previous, status->current, sizeof(status->previous));
    status->current[0] = '\0';

    size_t cur_len = 0;
    const size_t max_len = sizeof(status->current) - 1;
    bool center_has_content = false;
    bool right_has_content = false;

    // Phân đoạn Center (giữa): ka-forecast, ka-clock
    for (unsigned short i = 0; i < status->block_count && i < CENTER_BLOCK_COUNT; ++i) {
        const block *const block = &status->blocks[i];
        if (block->output[0] == '\0')
            continue;

        if (center_has_content && cur_len + strlen(DELIMITER) < max_len) {
            strcat(status->current, DELIMITER);
            cur_len += strlen(DELIMITER);
        }

#if CLICKABLE_BLOCKS
        if (block->signal > 0 && cur_len + 1 < max_len) {
            status->current[cur_len++] = (char)block->signal;
            status->current[cur_len] = '\0';
        }
#endif

        size_t icon_len = strlen(block->icon);
        size_t out_len = strlen(block->output);
        if (cur_len + icon_len + out_len < max_len) {
            strcat(status->current, block->icon);
            strcat(status->current, block->output);
            cur_len += icon_len + out_len;
        }
        center_has_content = true;
    }

    // Dấu phân cách ';' giữa Center và Right
    if (cur_len < max_len) {
        status->current[cur_len++] = ';';
        status->current[cur_len] = '\0';
    }

    // Phân đoạn Right: sb-record, ka-volume, ka-battery, ka-network, ka-cpu, ka-memory, sb-notify
    for (unsigned short i = CENTER_BLOCK_COUNT; i < status->block_count; ++i) {
        const block *const block = &status->blocks[i];
        if (block->output[0] == '\0')
            continue;

        if (right_has_content && cur_len + strlen(DELIMITER) < max_len) {
            strcat(status->current, DELIMITER);
            cur_len += strlen(DELIMITER);
        }

#if CLICKABLE_BLOCKS
        if (block->signal > 0 && cur_len + 1 < max_len) {
            status->current[cur_len++] = (char)block->signal;
            status->current[cur_len] = '\0';
        }
#endif

        size_t icon_len = strlen(block->icon);
        size_t out_len = strlen(block->output);
        if (cur_len + icon_len + out_len < max_len) {
            strcat(status->current, block->icon);
            strcat(status->current, block->output);
            cur_len += icon_len + out_len;
        }
        right_has_content = true;
    }

    return has_status_changed(status);
}

int status_write(const status *const status, const bool is_debug_mode,
                 x11_connection *const connection) {
    if (is_debug_mode) {
        (void)printf("%s\n", status->current);
        return 0;
    }

    if (x11_set_root_name(connection, status->current) != 0) {
        return 1;
    }

    return 0;
}
