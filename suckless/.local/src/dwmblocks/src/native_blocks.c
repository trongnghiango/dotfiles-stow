#include "native_blocks.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/types.h>

/* Direct async spawn without /bin/sh (1 fork, 0 subshells) */
static void spawn_cmd(char *const argv[]) {
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

/* Fast popover launcher */
static void spawn_pop(const char *module) {
    char *args[] = {(char *)"ka-pop", (char *)module, NULL};
    spawn_cmd(args);
}

/* Direct stdout capture without /bin/sh or popen (1 fork, 0 shell pipes) */
static int exec_capture(char *const argv[], char *output, size_t max_len) {
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

// -----------------------------------------------------------------------------
// 1. CPU BLOCK (Zero-Fork / Zero-Sleep Delta via /proc/stat)
// -----------------------------------------------------------------------------
static void native_cpu(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("cpu");
    } else if (button == 3) {
        spawn_pop("cpu");
    }

    static unsigned long long prev_total = 0, prev_idle = 0;
    FILE *f = fopen("/proc/stat", "r");
    if (!f) {
        snprintf(output, max_len, "󰍛");
        return;
    }

    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
    int items = fscanf(f, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
                       &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal);
    fclose(f);

    if (items < 4) {
        snprintf(output, max_len, "󰍛");
        return;
    }

    unsigned long long total = user + nice + system + idle + (items > 4 ? iowait : 0) +
                               (items > 5 ? irq : 0) + (items > 6 ? softirq : 0) + (items > 7 ? steal : 0);
    unsigned long long total_idle = idle + (items > 4 ? iowait : 0);

    int cpu_usage = 0;
    if (prev_total > 0 && total > prev_total) {
        unsigned long long diff_total = total - prev_total;
        unsigned long long diff_idle = total_idle - prev_idle;
        if (diff_total > 0 && diff_total >= diff_idle) {
            cpu_usage = (int)(100 * (diff_total - diff_idle) / diff_total);
        }
    }

    prev_total = total;
    prev_idle = total_idle;

    if (cpu_usage >= 80) {
        snprintf(output, max_len, "^C1^󰍛^d^");
    } else {
        snprintf(output, max_len, "󰍛");
    }
}

// -----------------------------------------------------------------------------
// 2. MEMORY BLOCK
// -----------------------------------------------------------------------------
static void native_memory(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("memory");
    } else if (button == 2) {
        char *args[] = {(char *)"st", (char *)"-e", (char *)"btop", NULL};
        spawn_cmd(args);
    }

    snprintf(output, max_len, "󰘚");
}

// -----------------------------------------------------------------------------
// 3. BATTERY BLOCK
// -----------------------------------------------------------------------------
static void native_battery(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("battery");
    } else if (button == 4) {
        char *args[] = {(char *)"brightnessctl", (char *)"-q", (char *)"set", (char *)"+1%", NULL};
        spawn_cmd(args);
    } else if (button == 5) {
        char *args[] = {(char *)"brightnessctl", (char *)"-q", (char *)"set", (char *)"1%-", NULL};
        spawn_cmd(args);
    }

    const char *bat_paths[] = {
        "/sys/class/power_supply/BAT0",
        "/sys/class/power_supply/BAT1"
    };

    const char *bat_base = NULL;
    for (size_t i = 0; i < sizeof(bat_paths)/sizeof(bat_paths[0]); ++i) {
        if (access(bat_paths[i], F_OK) == 0) {
            bat_base = bat_paths[i];
            break;
        }
    }

    if (!bat_base) {
        snprintf(output, max_len, "󰁹");
        return;
    }

    char cap_path[64], stat_path[64];
    snprintf(cap_path, sizeof(cap_path), "%s/capacity", bat_base);
    snprintf(stat_path, sizeof(stat_path), "%s/status", bat_base);

    int cap = 100;
    FILE *f_cap = fopen(cap_path, "r");
    if (f_cap) {
        fscanf(f_cap, "%d", &cap);
        fclose(f_cap);
    }

    char stat[32] = "Unknown";
    FILE *f_stat = fopen(stat_path, "r");
    if (f_stat) {
        fscanf(f_stat, "%31s", stat);
        fclose(f_stat);
    }

    if (strcmp(stat, "Charging") == 0) {
        snprintf(output, max_len, "󰂄");
    } else if (strcmp(stat, "Full") == 0) {
        snprintf(output, max_len, "󰁹");
    } else if (strcmp(stat, "Discharging") == 0) {
        if (cap >= 90) snprintf(output, max_len, "󰁹");
        else if (cap >= 70) snprintf(output, max_len, "󰂁");
        else if (cap >= 50) snprintf(output, max_len, "󰁿");
        else if (cap >= 30) snprintf(output, max_len, "󰁽");
        else if (cap >= 15) snprintf(output, max_len, "󰁻");
        else snprintf(output, max_len, "^C1^󰁺^d^");
    } else {
        snprintf(output, max_len, "󰂃");
    }
}

// -----------------------------------------------------------------------------
// 4. NETWORK BLOCK
// -----------------------------------------------------------------------------
static void native_network(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("network");
    } else if (button == 3) {
        char *args[] = {(char *)"st", (char *)"-e", (char *)"nmtui", NULL};
        spawn_cmd(args);
    }

    const char *wifi_icon = NULL;
    const char *net_icon = NULL;
    const char *tun_icon = "";

    // Check Wi-Fi link quality via /proc/net/wireless
    FILE *f_wl = fopen("/proc/net/wireless", "r");
    if (f_wl) {
        char line[256];
        // Skip header lines
        if (fgets(line, sizeof(line), f_wl) && fgets(line, sizeof(line), f_wl)) {
            while (fgets(line, sizeof(line), f_wl)) {
                char ifname[32];
                int status;
                float link;
                if (sscanf(line, "%31s %d %f", ifname, &status, &link) >= 3) {
                    int sig = (int)(link * 100.0f / 70.0f);
                    if (sig >= 75) wifi_icon = "󰤨";
                    else if (sig >= 50) wifi_icon = "󰤥";
                    else if (sig >= 25) wifi_icon = "󰤢";
                    else wifi_icon = "󰤟";
                    break;
                }
            }
        }
        fclose(f_wl);
    }

    // Check ethernet and tun via /sys/class/net
    DIR *dir = opendir("/sys/class/net");
    if (dir) {
        struct dirent *ent;
        while ((ent = readdir(dir)) != NULL) {
            if (ent->d_name[0] == 'e') {
                char op_path[280];
                snprintf(op_path, sizeof(op_path), "/sys/class/net/%s/operstate", ent->d_name);
                FILE *f_op = fopen(op_path, "r");
                if (f_op) {
                    char state[16];
                    if (fscanf(f_op, "%15s", state) == 1 && strcmp(state, "up") == 0) {
                        net_icon = "󰈀";
                    }
                    fclose(f_op);
                }
            } else if (strncmp(ent->d_name, "tun", 3) == 0 || strncmp(ent->d_name, "wg", 2) == 0) {
                char op_path[280];
                snprintf(op_path, sizeof(op_path), "/sys/class/net/%s/operstate", ent->d_name);
                FILE *f_op = fopen(op_path, "r");
                if (f_op) {
                    char state[16];
                    if (fscanf(f_op, "%15s", state) == 1 && strcmp(state, "up") == 0) {
                        tun_icon = " 󰌾";
                    }
                    fclose(f_op);
                }
            }
        }
        closedir(dir);
    }

    if (!wifi_icon && !net_icon) {
        snprintf(output, max_len, "󰤮");
    } else {
        snprintf(output, max_len, "%s%s", wifi_icon ? wifi_icon : net_icon, tun_icon);
    }
}

// -----------------------------------------------------------------------------
// 5. CLOCK BLOCK
// -----------------------------------------------------------------------------
static void native_clock(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("clock");
    }

    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char buf[64];
    strftime(buf, sizeof(buf), "%a · %H:%M", tm_info);
    snprintf(output, max_len, "%s", buf);
}

// -----------------------------------------------------------------------------
// 6. VOLUME BLOCK (In-Process Native C - Zero Shell)
// -----------------------------------------------------------------------------
static void native_volume(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("volume");
    } else if (button == 2) {
        char *args[] = {(char *)"wpctl", (char *)"set-mute", (char *)"@DEFAULT_AUDIO_SINK@", (char *)"toggle", NULL};
        spawn_cmd(args);
    } else if (button == 4) {
        char *args[] = {(char *)"wpctl", (char *)"set-volume", (char *)"@DEFAULT_AUDIO_SINK@", (char *)"1%+", NULL};
        spawn_cmd(args);
    } else if (button == 5) {
        char *args[] = {(char *)"wpctl", (char *)"set-volume", (char *)"@DEFAULT_AUDIO_SINK@", (char *)"1%-", NULL};
        spawn_cmd(args);
    }

    int vol = 50;
    int is_muted = 0;
    char buf[128] = {0};
    char *get_vol_args[] = {(char *)"wpctl", (char *)"get-volume", (char *)"@DEFAULT_AUDIO_SINK@", NULL};
    if (exec_capture(get_vol_args, buf, sizeof(buf)) == 0) {
        float v = 0.5f;
        if (sscanf(buf, "Volume: %f", &v) >= 1) {
            vol = (int)(v * 100.0f + 0.5f);
        }
        if (strstr(buf, "[MUTED]")) is_muted = 1;
    }

    if (is_muted) {
        snprintf(output, max_len, "󰝟");
    } else if (vol >= 70) {
        snprintf(output, max_len, "󰕾");
    } else if (vol >= 30) {
        snprintf(output, max_len, "󰖀");
    } else {
        snprintf(output, max_len, "󰕿");
    }
}

// -----------------------------------------------------------------------------
// 7. FORECAST BLOCK (In-Process Native C)
// -----------------------------------------------------------------------------
static void native_forecast(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("forecast");
    }

    const char *home = getenv("HOME");
    char cache_path[512];
    snprintf(cache_path, sizeof(cache_path), "%s/.cache/weatherreport", home ? home : "/tmp");

    FILE *f = fopen(cache_path, "r");
    if (!f) {
        snprintf(output, max_len, "󰖕");
        return;
    }

    char buf[2048];
    char icon_code[16] = "01d";
    if (fgets(buf, sizeof(buf), f)) {
        char *p_icon = strstr(buf, "\"icon\":\"");
        if (p_icon) {
            sscanf(p_icon + 8, "%15[^\"]", icon_code);
        }
    }
    fclose(f);

    int is_night = (strchr(icon_code, 'n') != NULL);
    int code_num = atoi(icon_code);

    const char *ico = "󰖕";
    switch (code_num) {
        case 1:  ico = is_night ? "󰖔" : "󰖙"; break;
        case 2:  ico = is_night ? "󰼱" : "󰖕"; break;
        case 3:
        case 4:  ico = "󰖐"; break;
        case 9:
        case 10: ico = "󰖖"; break;
        case 11: ico = "󰖓"; break;
        case 13: ico = "󰖘"; break;
        case 50: ico = "󰖑"; break;
        default: ico = is_night ? "󰖔" : "󰖙"; break;
    }
    snprintf(output, max_len, "%s", ico);
}

// -----------------------------------------------------------------------------
// 8. NOTIFY BLOCK (In-Process Native C - Zero Shell)
// -----------------------------------------------------------------------------
static void native_notify(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_pop("notify");
    } else if (button == 2) {
        char *args[] = {(char *)"dunstctl", (char *)"history-clear", NULL};
        spawn_cmd(args);
    } else if (button == 3) {
        char *args[] = {(char *)"dunstctl", (char *)"set-paused", (char *)"toggle", NULL};
        spawn_cmd(args);
    }

    int is_paused = 0;
    int hist_count = 0;
    char buf[32] = {0};

    char *paused_args[] = {(char *)"dunstctl", (char *)"is-paused", NULL};
    if (exec_capture(paused_args, buf, sizeof(buf)) == 0 && strstr(buf, "true")) {
        is_paused = 1;
    }

    if (is_paused) {
        snprintf(output, max_len, "󰂛");
        return;
    }

    char *hist_args[] = {(char *)"dunstctl", (char *)"count", (char *)"history", NULL};
    if (exec_capture(hist_args, buf, sizeof(buf)) == 0) {
        hist_count = atoi(buf);
    }

    if (hist_count > 0) {
        snprintf(output, max_len, "󰂞");
    } else {
        snprintf(output, max_len, "󰂚");
    }
}

// -----------------------------------------------------------------------------
// 9. RECORD BLOCK (In-Process Native C)
// -----------------------------------------------------------------------------
static void native_record(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        char *args[] = {(char *)"record", (char *)"stop", NULL};
        spawn_cmd(args);
    }

    if (access("/tmp/omarecord.pid", F_OK) == 0) {
        snprintf(output, max_len, "^C1^🔴 REC^d^");
    } else {
        output[0] = '\0';
    }
}

// -----------------------------------------------------------------------------
// REGISTRY / ROUTER
// -----------------------------------------------------------------------------
native_block_fn get_native_block_fn(const char *command) {
    if (!command) return NULL;

    if (strcmp(command, "ka-cpu") == 0 || strcmp(command, "native:cpu") == 0) {
        return native_cpu;
    }
    if (strcmp(command, "ka-memory") == 0 || strcmp(command, "native:memory") == 0) {
        return native_memory;
    }
    if (strcmp(command, "ka-battery") == 0 || strcmp(command, "native:battery") == 0) {
        return native_battery;
    }
    if (strcmp(command, "ka-network") == 0 || strcmp(command, "native:network") == 0) {
        return native_network;
    }
    if (strcmp(command, "ka-clock") == 0 || strcmp(command, "native:clock") == 0) {
        return native_clock;
    }
    if (strcmp(command, "ka-volume") == 0 || strcmp(command, "native:volume") == 0) {
        return native_volume;
    }
    if (strcmp(command, "ka-forecast") == 0 || strcmp(command, "native:forecast") == 0) {
        return native_forecast;
    }
    if (strcmp(command, "sb-notify") == 0 || strcmp(command, "native:notify") == 0) {
        return native_notify;
    }
    if (strcmp(command, "sb-record") == 0 || strcmp(command, "native:record") == 0) {
        return native_record;
    }

    return NULL;
}
