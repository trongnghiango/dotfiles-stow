/* ==============================================================================
 * ka-pop: Utility Functions
 * ============================================================================== */

#include "util.h"

void spawn_async(const char *cmd) {
    if (!cmd) return;
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        _exit(0);
    }
}

int read_int_from_file(const char *path, int fallback) {
    if (!path) return fallback;
    FILE *f = fopen(path, "r");
    if (!f) return fallback;
    int val = fallback;
    if (fscanf(f, "%d", &val) != 1) {
        val = fallback;
    }
    fclose(f);
    return val;
}

int read_str_from_file(const char *path, char *buf, size_t buf_size) {
    if (!path || !buf || buf_size == 0) return -1;
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    if (!fgets(buf, (int)buf_size, f)) {
        fclose(f);
        return -1;
    }
    char *nl = strchr(buf, '\n');
    if (nl) *nl = '\0';
    fclose(f);
    return 0;
}
