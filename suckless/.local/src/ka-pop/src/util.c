/* ==============================================================================
 * ka-pop: Utility Functions
 * ============================================================================== */

#include "util.h"
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>

void spawn_async(const char *cmd) {
    if (!cmd) return;
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        _exit(127);
    }
}

void spawn_cmd(char *const argv[]) {
    if (!argv || !argv[0]) return;
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        execvp(argv[0], argv);
        _exit(127);
    }
}

int exec_capture(char *const argv[], char *output, size_t max_len) {
    if (!argv || !argv[0] || !output || max_len == 0) return -1;
    int pfd[2];
    if (pipe(pfd) != 0) return -1;

    pid_t pid = fork();
    if (pid < 0) {
        close(pfd[0]);
        close(pfd[1]);
        return -1;
    }
    if (pid == 0) {
        close(pfd[0]);
        dup2(pfd[1], STDOUT_FILENO);
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        close(pfd[1]);
        execvp(argv[0], argv);
        _exit(127);
    }

    close(pfd[1]);
    ssize_t total = 0;
    while (total < (ssize_t)max_len - 1) {
        ssize_t r = read(pfd[0], output + total, max_len - 1 - total);
        if (r <= 0) break;
        total += r;
    }
    output[total] = '\0';
    close(pfd[0]);
    return 0;
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
