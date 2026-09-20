#ifndef NATIVE_BLOCKS_H
#define NATIVE_BLOCKS_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef void (*native_block_fn)(char *output, size_t max_len, uint8_t button);

native_block_fn get_native_block_fn(const char *command);

#endif  // NATIVE_BLOCKS_H
