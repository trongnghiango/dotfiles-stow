#include "native_blocks.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>

static void spawn_async(const char *cmd) {
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        _exit(0);
    }
}

// -----------------------------------------------------------------------------
// 1. CPU BLOCK (Zero-Fork / Zero-Sleep Delta via /proc/stat)
// -----------------------------------------------------------------------------
static void native_cpu(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_async("setsid -f ka-pop cpu >/dev/null 2>&1 || setsid -f dwm-dropdown cpu >/dev/null 2>&1");
    } else if (button == 3) {
        spawn_async("INFO=$(sensors 2>/dev/null | awk '/^fan1:/ { printf \"🌪️ Fan: %s RPM\\n\", $2 } /^CPU:/ { printf \"🔥 CPU: %s\\n\", $2 } /^Core 0:/ { printf \"1️⃣ Core 0: %s\\n\", $3 } /^Core 1:/ { printf \"2️⃣ Core 1: %s\\n\", $3 }'); notify-send '🌡️ Sensors' \"$INFO\"");
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
        spawn_async("setsid -f ka-pop memory >/dev/null 2>&1 || setsid -f dwm-dropdown memory >/dev/null 2>&1");
    } else if (button == 2) {
        spawn_async("setsid -f st -e btop >/dev/null 2>&1");
    }

    snprintf(output, max_len, "󰘚");
}

// -----------------------------------------------------------------------------
// 3. BATTERY BLOCK
// -----------------------------------------------------------------------------
static void native_battery(char *output, size_t max_len, uint8_t button) {
    if (button == 1) {
        spawn_async("setsid -f ka-pop battery >/dev/null 2>&1 || setsid -f dwm-dropdown battery >/dev/null 2>&1");
    } else if (button == 4) {
        spawn_async("brightnessctl -q set +1% >/dev/null 2>&1");
    } else if (button == 5) {
        spawn_async("brightnessctl -q set 1%- >/dev/null 2>&1");
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
        spawn_async("setsid -f ka-pop network >/dev/null 2>&1 || setsid -f dwm-dropdown network >/dev/null 2>&1");
    } else if (button == 3) {
        spawn_async("setsid -f st -e nmtui >/dev/null 2>&1");
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
        spawn_async("setsid -f ka-pop clock >/dev/null 2>&1 || setsid -f dwm-dropdown clock >/dev/null 2>&1");
    }

    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char buf[64];
    strftime(buf, sizeof(buf), "%a · %H:%M", tm_info);
    snprintf(output, max_len, "%s", buf);
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

    return NULL;
}
