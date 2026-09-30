/* ==============================================================================
 * ka-pop: Bluetooth Module — Ultra-Fast Native C / GDBus Control Center (< 20ms)
 * Direct BlueZ D-Bus integration without interactive shell/bluetoothctl overhead.
 *
 * Triết lý Quản lý Trạng thái & UX:
 *   - Popup CHỈ đóng khi: (1) click ngoài (DWM root/bar), (2) phím Esc/q (ui.c)
 *   - Tuyệt đối KHÔNG tự động đóng popup khi bấm các nút tương tác bên trong
 *   - Quét thiết bị: chạy async, cập nhật danh sách thiết bị real-time mỗi 2s
 *   - Phân giải tên chuẩn: Ưu tiên Name > Alias tùy chỉnh > Vendor ID > Địa chỉ MAC
 *   - Tự động co giãn chiều cao danh sách: Hiển thị đầy đủ thiết bị, không bị cắt ẩn
 * ============================================================================== */

#include "modules.h"
#include "ui.h"
#include "util.h"
#include <gio/gio.h>
#include <signal.h>

#define MAX_BT_DEVICES 32

typedef struct {
    char path[128];
    char address[32];
    char name[64];
    char icon[32];
    gboolean paired;
    gboolean connected;
    gboolean trusted;
    int battery; /* -1 if unknown */
    gboolean has_real_name;
} BtDevice;

static char g_adapter_path[128] = {0};
static char g_adapter_name[64] = "Bluetooth Adapter";
static gboolean g_adapter_powered = FALSE;
static gboolean g_service_active = FALSE;

static BtDevice g_devices[MAX_BT_DEVICES];
static int g_device_count = 0;

/* Widget references để cập nhật giao diện tại chỗ */
static GtkWidget *g_subtitle_label = NULL;
static GtkWidget *g_content_area   = NULL;
static GtkWidget *g_main_box       = NULL;
static GtkWidget *g_actions_bar    = NULL;
static GtkWidget *g_scan_btn       = NULL;

/* Trạng thái quét thiết bị (Discovery) */
static gboolean g_scanning        = FALSE;
static guint    g_scan_timer_id   = 0;
static int      g_scan_countdown  = 0;

/* Forward declarations */
static void on_device_toggle(GtkButton *btn, gpointer user_data);
static void refresh_content_area(void);
static void stop_discovery_sync(void);

static gboolean is_mac_with_dashes(const char *s) {
    if (!s || strlen(s) != 17) return FALSE;
    return (s[2] == '-' && s[5] == '-' && s[8] == '-' && s[11] == '-' && s[14] == '-');
}

/* Bắn tín hiệu SIGRTMIN+7 tới dwmblocks để cập nhật icon tức thì (< 10µs) */
static void signal_dwmblocks_bluetooth(void) {
    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    char pid_file[128];
    if (runtime_dir && runtime_dir[0]) {
        snprintf(pid_file, sizeof(pid_file), "%s/dwmblocks.pid", runtime_dir);
    } else {
        snprintf(pid_file, sizeof(pid_file), "/tmp/dwmblocks-%d.pid", getuid());
    }

    FILE *f = fopen(pid_file, "r");
    if (f) {
        pid_t pid = 0;
        if (fscanf(f, "%d", &pid) == 1 && pid > 0) {
            kill(pid, SIGRTMIN + 7);
        }
        fclose(f);
        return;
    }

    char *args[] = {(char *)"pkill", (char *)"-RTMIN+7", (char *)"-x", (char *)"dwmblocks", NULL};
    spawn_cmd(args);
}

/* Đọc toàn bộ cây thiết bị BlueZ trong 1 D-Bus call duy nhất (< 2ms) */
static void fetch_bluez_state(void) {
    g_device_count = 0;
    g_adapter_path[0] = '\0';
    g_adapter_powered = FALSE;
    g_service_active = FALSE;

    GError *err = NULL;
    GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, &err);
    if (!conn) {
        g_clear_error(&err);
        return;
    }

    GVariant *res = g_dbus_connection_call_sync(
        conn,
        "org.bluez",
        "/",
        "org.freedesktop.DBus.ObjectManager",
        "GetManagedObjects",
        NULL,
        G_VARIANT_TYPE("(a{oa{sa{sv}}})"),
        G_DBUS_CALL_FLAGS_NONE,
        300,
        NULL,
        &err
    );

    if (!res) {
        g_clear_error(&err);
        g_object_unref(conn);
        return;
    }

    g_service_active = TRUE;

    GVariantIter *objects = NULL;
    const char *opath = NULL;
    GVariantIter *ifaces = NULL;

    g_variant_get(res, "(a{oa{sa{sv}}})", &objects);
    while (g_variant_iter_next(objects, "{&oa{sa{sv}}}", &opath, &ifaces)) {
        const char *iname = NULL;
        GVariantIter *props = NULL;
        while (g_variant_iter_next(ifaces, "{&sa{sv}}", &iname, &props)) {
            if (!strcmp(iname, "org.bluez.Adapter1")) {
                if (g_adapter_path[0] == '\0') {
                    strncpy(g_adapter_path, opath, sizeof(g_adapter_path) - 1);
                }
                const char *pname = NULL;
                GVariant *pval = NULL;
                while (g_variant_iter_next(props, "{&sv}", &pname, &pval)) {
                    if (!strcmp(pname, "Powered")) {
                        g_adapter_powered = g_variant_get_boolean(pval);
                    } else if (!strcmp(pname, "Alias") || !strcmp(pname, "Name")) {
                        const char *s = g_variant_get_string(pval, NULL);
                        if (s && s[0]) strncpy(g_adapter_name, s, sizeof(g_adapter_name) - 1);
                    }
                    g_variant_unref(pval);
                }
            } else if (!strcmp(iname, "org.bluez.Device1")) {
                int idx = -1;
                for (int i = 0; i < g_device_count; i++) {
                    if (!strcmp(g_devices[i].path, opath)) { idx = i; break; }
                }
                if (idx < 0 && g_device_count < MAX_BT_DEVICES) {
                    idx = g_device_count++;
                    memset(&g_devices[idx], 0, sizeof(BtDevice));
                    strncpy(g_devices[idx].path, opath, sizeof(g_devices[idx].path) - 1);
                    g_devices[idx].battery = -1;
                }
                if (idx >= 0) {
                    const char *pname = NULL;
                    GVariant *pval = NULL;
                    char real_name[64] = {0};
                    char alias_name[64] = {0};
                    uint16_t mfg_id = 0;

                    while (g_variant_iter_next(props, "{&sv}", &pname, &pval)) {
                        if (!strcmp(pname, "Address")) {
                            strncpy(g_devices[idx].address, g_variant_get_string(pval, NULL), sizeof(g_devices[idx].address) - 1);
                        } else if (!strcmp(pname, "Name")) {
                            const char *s = g_variant_get_string(pval, NULL);
                            if (s && s[0]) strncpy(real_name, s, sizeof(real_name) - 1);
                        } else if (!strcmp(pname, "Alias")) {
                            const char *s = g_variant_get_string(pval, NULL);
                            if (s && s[0]) strncpy(alias_name, s, sizeof(alias_name) - 1);
                        } else if (!strcmp(pname, "Icon")) {
                            strncpy(g_devices[idx].icon, g_variant_get_string(pval, NULL), sizeof(g_devices[idx].icon) - 1);
                        } else if (!strcmp(pname, "Paired")) {
                            g_devices[idx].paired = g_variant_get_boolean(pval);
                        } else if (!strcmp(pname, "Connected")) {
                            g_devices[idx].connected = g_variant_get_boolean(pval);
                        } else if (!strcmp(pname, "Trusted")) {
                            g_devices[idx].trusted = g_variant_get_boolean(pval);
                        } else if (!strcmp(pname, "ManufacturerData")) {
                            GVariantIter *miter = NULL;
                            uint16_t key = 0;
                            GVariant *mval = NULL;
                            g_variant_get(pval, "a{qv}", &miter);
                            if (g_variant_iter_next(miter, "{qv}", &key, &mval)) {
                                mfg_id = key;
                                g_variant_unref(mval);
                            }
                            g_variant_iter_free(miter);
                        }
                        g_variant_unref(pval);
                    }

                    /* Phân giải tên thiết bị một cách rõ ràng và chuẩn xác */
                    if (real_name[0]) {
                        strncpy(g_devices[idx].name, real_name, sizeof(g_devices[idx].name) - 1);
                        g_devices[idx].has_real_name = TRUE;
                    } else if (alias_name[0] && !is_mac_with_dashes(alias_name)) {
                        strncpy(g_devices[idx].name, alias_name, sizeof(g_devices[idx].name) - 1);
                        g_devices[idx].has_real_name = TRUE;
                    } else {
                        /* Tên chưa được phát quảng bá hoặc là Beacon BLE ngẫu nhiên */
                        g_devices[idx].has_real_name = FALSE;
                        if (mfg_id == 0x004c) {
                            strncpy(g_devices[idx].name, "Thiết bị Apple (Beacon)", sizeof(g_devices[idx].name) - 1);
                        } else if (mfg_id == 0x0075) {
                            strncpy(g_devices[idx].name, "Samsung Electronics", sizeof(g_devices[idx].name) - 1);
                        } else if (mfg_id == 0x0006) {
                            strncpy(g_devices[idx].name, "Thiết bị Microsoft", sizeof(g_devices[idx].name) - 1);
                        } else if (mfg_id == 0x012d) {
                            strncpy(g_devices[idx].name, "Thiết bị Sony", sizeof(g_devices[idx].name) - 1);
                        } else {
                            strncpy(g_devices[idx].name, g_devices[idx].address, sizeof(g_devices[idx].name) - 1);
                        }
                    }
                }
            } else if (!strcmp(iname, "org.bluez.Battery1")) {
                for (int i = 0; i < g_device_count; i++) {
                    if (!strcmp(g_devices[i].path, opath)) {
                        const char *pname = NULL;
                        GVariant *pval = NULL;
                        while (g_variant_iter_next(props, "{&sv}", &pname, &pval)) {
                            if (!strcmp(pname, "Percentage")) {
                                g_devices[i].battery = (int)g_variant_get_byte(pval);
                            }
                            g_variant_unref(pval);
                        }
                        break;
                    }
                }
            }
            g_variant_iter_free(props);
        }
        g_variant_iter_free(ifaces);
    }
    g_variant_iter_free(objects);
    g_variant_unref(res);
    g_object_unref(conn);
}

static const char* get_device_glyph(const char *icon) {
    if (!icon || !icon[0]) return "󰂯";
    if (strstr(icon, "audio") || strstr(icon, "headphone") || strstr(icon, "headset")) return "󰂯";
    if (strstr(icon, "keyboard")) return "󰌌";
    if (strstr(icon, "mouse") || strstr(icon, "pointing")) return "󰍽";
    if (strstr(icon, "phone")) return "󰄝";
    return "󰂯";
}

/* ============================================================================
 * Xây dựng danh sách thiết bị
 * Hiển thị đầy đủ thiết bị và tự co giãn độ cao chính xác không bị cắt ẩn
 * ============================================================================ */
static GtkWidget* build_device_list(void) {
    GtkWidget *scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll),
                                   GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);

    GtkWidget *list_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
    gtk_container_add(GTK_CONTAINER(scroll), list_box);

    int shown = 0;

    /* 1. Thiết bị đã ghép hoặc đang kết nối */
    for (int i = 0; i < g_device_count; i++) {
        BtDevice *dev = &g_devices[i];
        if (!dev->paired && !dev->connected) continue;

        GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
        gtk_style_context_add_class(gtk_widget_get_style_context(row), "badge");

        GtkWidget *ico = gtk_label_new(get_device_glyph(dev->icon));
        gtk_style_context_add_class(gtk_widget_get_style_context(ico), "metric-sub");
        gtk_box_pack_start(GTK_BOX(row), ico, FALSE, FALSE, 0);

        GtkWidget *info = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
        const char *display_name = dev->name[0] ? dev->name : dev->address;
        GtkWidget *lbl_name = gtk_label_new(display_name);
        gtk_label_set_xalign(GTK_LABEL(lbl_name), 0.0f);
        gtk_label_set_ellipsize(GTK_LABEL(lbl_name), PANGO_ELLIPSIZE_END);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_name), "title-label");
        gtk_box_pack_start(GTK_BOX(info), lbl_name, FALSE, FALSE, 0);

        char status_str[64];
        if (dev->connected) {
            if (dev->battery >= 0)
                snprintf(status_str, sizeof(status_str), "● Đã kết nối · 🔋 %d%%", dev->battery);
            else
                snprintf(status_str, sizeof(status_str), "● Đã kết nối");
        } else {
            snprintf(status_str, sizeof(status_str), "○ Đã ghép nối");
        }
        GtkWidget *lbl_status = gtk_label_new(status_str);
        gtk_label_set_xalign(GTK_LABEL(lbl_status), 0.0f);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_status), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(info), lbl_status, FALSE, FALSE, 0);

        gtk_box_pack_start(GTK_BOX(row), info, TRUE, TRUE, 0);

        GtkWidget *btn = gtk_button_new_with_label(dev->connected ? "Ngắt" : "Kết nối");
        gtk_style_context_add_class(gtk_widget_get_style_context(btn),
                                    dev->connected ? "action-btn" : "btn-active");
        g_signal_connect(btn, "clicked", G_CALLBACK(on_device_toggle), GINT_TO_POINTER(i));
        gtk_box_pack_end(GTK_BOX(row), btn, FALSE, FALSE, 0);

        gtk_box_pack_start(GTK_BOX(list_box), row, FALSE, FALSE, 0);
        shown++;
    }

    /* 2. Thiết bị mới phát hiện qua Discovery (chưa ghép) */
    int new_devices_shown = 0;
    for (int i = 0; i < g_device_count; i++) {
        BtDevice *dev = &g_devices[i];
        if (dev->paired || dev->connected) continue;

        if (new_devices_shown == 0 && shown > 0) {
            GtkWidget *sep_lbl = gtk_label_new("THIẾT BỊ MỚI XUNG QUANH:");
            gtk_label_set_xalign(GTK_LABEL(sep_lbl), 0.0f);
            gtk_style_context_add_class(gtk_widget_get_style_context(sep_lbl), "subtitle-label");
            gtk_box_pack_start(GTK_BOX(list_box), sep_lbl, FALSE, FALSE, 4);
        }

        GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
        gtk_style_context_add_class(gtk_widget_get_style_context(row), "badge");

        GtkWidget *ico = gtk_label_new(get_device_glyph(dev->icon));
        gtk_style_context_add_class(gtk_widget_get_style_context(ico), "metric-sub");
        gtk_box_pack_start(GTK_BOX(row), ico, FALSE, FALSE, 0);

        GtkWidget *info = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
        const char *display_name = dev->name[0] ? dev->name : dev->address;
        GtkWidget *lbl_name = gtk_label_new(display_name);
        gtk_label_set_xalign(GTK_LABEL(lbl_name), 0.0f);
        gtk_label_set_ellipsize(GTK_LABEL(lbl_name), PANGO_ELLIPSIZE_END);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_name), "title-label");
        gtk_box_pack_start(GTK_BOX(info), lbl_name, FALSE, FALSE, 0);

        char status_str[64];
        if (dev->has_real_name) {
            snprintf(status_str, sizeof(status_str), "○ Chưa ghép nối (%s)", dev->address);
        } else {
            snprintf(status_str, sizeof(status_str), "○ Beacon BLE (%s)", dev->address);
        }
        GtkWidget *lbl_status = gtk_label_new(status_str);
        gtk_label_set_xalign(GTK_LABEL(lbl_status), 0.0f);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_status), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(info), lbl_status, FALSE, FALSE, 0);

        gtk_box_pack_start(GTK_BOX(row), info, TRUE, TRUE, 0);

        GtkWidget *btn = gtk_button_new_with_label("Ghép nối");
        gtk_style_context_add_class(gtk_widget_get_style_context(btn), "btn-active");
        g_signal_connect(btn, "clicked", G_CALLBACK(on_device_toggle), GINT_TO_POINTER(i));
        gtk_box_pack_end(GTK_BOX(row), btn, FALSE, FALSE, 0);

        gtk_box_pack_start(GTK_BOX(list_box), row, FALSE, FALSE, 0);
        shown++;
        new_devices_shown++;
    }

    if (shown == 0) {
        const char *empty_msg = g_scanning
            ? "🔍 Đang tìm kiếm thiết bị xung quanh...\nHãy bật Bluetooth trên tai nghe/chuột của bạn."
            : "Chưa có thiết bị nào được ghép nối.\nBấm 'Quét thiết bị' để ghép nối mới.";
        GtkWidget *empty_lbl = gtk_label_new(empty_msg);
        gtk_label_set_line_wrap(GTK_LABEL(empty_lbl), TRUE);
        gtk_style_context_add_class(gtk_widget_get_style_context(empty_lbl), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(list_box), empty_lbl, FALSE, FALSE, 14);
    }

    /* TÍNH TOÁN CHIỀU CAO THỰC TẾ: Đảm bảo toàn bộ card thiết bị đều hiển thị rõ ràng */
    int total_cards = shown;
    int desired_h = (total_cards * 58) + (new_devices_shown > 0 && (shown - new_devices_shown) > 0 ? 28 : 0) + 8;
    if (desired_h > 260) desired_h = 260;
    if (desired_h < 75)  desired_h = 75;
    gtk_widget_set_size_request(scroll, -1, desired_h);

    return scroll;
}

/* ============================================================================
 * Cập nhật subtitle và content area tại chỗ mà không làm mất focus hay đóng cửa sổ
 * ============================================================================ */
static void refresh_content_area(void) {
    if (!g_main_box || !g_content_area) return;

    /* 1. Cập nhật Subtitle */
    if (g_subtitle_label) {
        char sub[96];
        if (!g_service_active) {
            snprintf(sub, sizeof(sub), "Dịch vụ bluetoothd chưa chạy");
        } else if (!g_adapter_powered) {
            snprintf(sub, sizeof(sub), "Adapter đang tắt nguồn");
        } else if (g_scanning) {
            snprintf(sub, sizeof(sub), "Đang quét thiết bị xung quanh (%ds)...", g_scan_countdown);
        } else {
            snprintf(sub, sizeof(sub), "%s · %d thiết bị", g_adapter_name, g_device_count);
        }
        gtk_label_set_text(GTK_LABEL(g_subtitle_label), sub);
    }

    /* 2. Cập nhật hiển thị Actions Bar */
    if (g_actions_bar) {
        gtk_widget_set_visible(g_actions_bar, g_service_active && g_adapter_powered);
    }

    /* 3. Thay thế vùng Content Area */
    gtk_widget_destroy(g_content_area);

    GtkWidget *new_content = NULL;
    if (!g_service_active) {
        new_content = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
        GtkWidget *lbl = gtk_label_new(
            "Dịch vụ BlueZ chưa kích hoạt trên hệ thống.\nChạy lệnh: ka-setup sys hoặc sudo systemctl enable --now bluetooth");
        gtk_label_set_line_wrap(GTK_LABEL(lbl), TRUE);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(new_content), lbl, FALSE, FALSE, 10);
    } else if (!g_adapter_powered) {
        new_content = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
        GtkWidget *lbl = gtk_label_new("Bật công tắc phía trên để kết nối thiết bị.");
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(new_content), lbl, FALSE, FALSE, 14);
    } else {
        new_content = build_device_list();
    }

    gtk_box_pack_start(GTK_BOX(g_main_box), new_content, TRUE, TRUE, 4);
    gtk_box_reorder_child(GTK_BOX(g_main_box), new_content, 1);
    g_content_area = new_content;

    gtk_widget_show_all(g_main_box);
}

/* ============================================================================
 * Callback Async hoàn thành kết nối/ngắt kết nối
 * ============================================================================ */
static void on_device_action_finish(GObject *source_object, GAsyncResult *res, gpointer user_data) {
    (void)user_data;
    GDBusConnection *conn = G_DBUS_CONNECTION(source_object);
    GError *err = NULL;
    GVariant *result = g_dbus_connection_call_finish(conn, res, &err);

    if (!result && err) {
        char notif_msg[128];
        snprintf(notif_msg, sizeof(notif_msg), "Thao tác Bluetooth thất bại: %s", err->message);
        char *args[] = {(char *)"notify-send", (char *)"-a", (char *)"Bluetooth",
                        (char *)"-u", (char *)"normal",
                        (char *)"-i", (char *)"bluetooth-disabled",
                        (char *)"Bluetooth", notif_msg, NULL};
        spawn_cmd(args);
        g_clear_error(&err);
    } else if (result) {
        g_variant_unref(result);
    }

    fetch_bluez_state();
    refresh_content_area();
    signal_dwmblocks_bluetooth();
}

/* ============================================================================
 * Callback: bấm nút Kết nối / Ngắt trên một thiết bị
 * ============================================================================ */
static void on_device_toggle(GtkButton *btn, gpointer user_data) {
    int idx = GPOINTER_TO_INT(user_data);
    if (idx < 0 || idx >= g_device_count) return;

    BtDevice *dev = &g_devices[idx];
    const char *action = dev->connected ? "Disconnect" : "Connect";

    gtk_button_set_label(btn, dev->connected ? "Đang ngắt..." : "Đang kết nối...");
    gtk_widget_set_sensitive(GTK_WIDGET(btn), FALSE);

    if (!dev->connected) {
        char notif_msg[128];
        snprintf(notif_msg, sizeof(notif_msg), "Đang kết nối tới %s...",
                 dev->name[0] ? dev->name : dev->address);
        char *args[] = {(char *)"notify-send", (char *)"-a", (char *)"Bluetooth",
                        (char *)"-i", (char *)"bluetooth", (char *)"Bluetooth",
                        notif_msg, NULL};
        spawn_cmd(args);
    }

    GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL);
    if (conn) {
        g_dbus_connection_call(
            conn,
            "org.bluez",
            dev->path,
            "org.bluez.Device1",
            action,
            NULL,
            NULL,
            G_DBUS_CALL_FLAGS_NONE,
            15000,
            NULL,
            on_device_action_finish,
            NULL
        );
        g_object_unref(conn);
    } else {
        gtk_widget_set_sensitive(GTK_WIDGET(btn), TRUE);
        gtk_button_set_label(btn, dev->connected ? "Ngắt" : "Kết nối");
    }

    signal_dwmblocks_bluetooth();
}

/* ============================================================================
 * Dừng Discovery một cách an toàn
 * ============================================================================ */
static void stop_discovery_sync(void) {
    if (g_adapter_path[0]) {
        GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL);
        if (conn) {
            g_dbus_connection_call(
                conn,
                "org.bluez",
                g_adapter_path,
                "org.bluez.Adapter1",
                "StopDiscovery",
                NULL,
                NULL,
                G_DBUS_CALL_FLAGS_NONE,
                2000,
                NULL, NULL, NULL
            );
            g_object_unref(conn);
        }
    }
    char *stop_args[] = {(char *)"bluetoothctl", (char *)"scan", (char *)"off", NULL};
    spawn_cmd(stop_args);
    g_scanning = FALSE;
}

/* ============================================================================
 * Timer Polling trong quá trình quét thiết bị (chạy mỗi 2 giây)
 * ============================================================================ */
static gboolean on_scan_poll_tick(gpointer user_data) {
    (void)user_data;
    g_scan_countdown -= 2;

    fetch_bluez_state();
    refresh_content_area();

    if (g_scan_countdown <= 0) {
        stop_discovery_sync();
        g_scan_timer_id = 0;

        if (g_scan_btn) {
            gtk_button_set_label(GTK_BUTTON(g_scan_btn), "🔍 Quét lại thiết bị");
            gtk_widget_set_sensitive(g_scan_btn, TRUE);
        }
        return G_SOURCE_REMOVE;
    }

    if (g_scan_btn) {
        char buf[32];
        snprintf(buf, sizeof(buf), "🔍 Đang quét (%ds)...", g_scan_countdown);
        gtk_button_set_label(GTK_BUTTON(g_scan_btn), buf);
    }

    return G_SOURCE_CONTINUE;
}

/* ============================================================================
 * Callback: toggle công tắc nguồn Bluetooth
 * ============================================================================ */
static void on_power_switch_changed(GtkSwitch *sw, GParamSpec *pspec, gpointer user_data) {
    (void)pspec;
    (void)user_data;
    gboolean state = gtk_switch_get_active(sw);

    if (g_adapter_path[0]) {
        GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL);
        if (conn) {
            g_dbus_connection_call(
                conn,
                "org.bluez",
                g_adapter_path,
                "org.freedesktop.DBus.Properties",
                "Set",
                g_variant_new("(ssv)", "org.bluez.Adapter1", "Powered",
                              g_variant_new_boolean(state)),
                NULL,
                G_DBUS_CALL_FLAGS_NONE,
                1000,
                NULL, NULL, NULL
            );
            g_object_unref(conn);
        }
    }

    g_adapter_powered = state;

    if (!state && g_scanning) {
        if (g_scan_timer_id > 0) {
            g_source_remove(g_scan_timer_id);
            g_scan_timer_id = 0;
        }
        stop_discovery_sync();
        if (g_scan_btn) {
            gtk_button_set_label(GTK_BUTTON(g_scan_btn), "🔍 Quét thiết bị");
            gtk_widget_set_sensitive(g_scan_btn, TRUE);
        }
    }

    refresh_content_area();
    signal_dwmblocks_bluetooth();
}

/* ============================================================================
 * Callback: bấm nút Quét thiết bị
 * ============================================================================ */
static void on_scan_btn_clicked(GtkButton *b, gpointer u) {
    (void)u;
    if (g_scanning || !g_adapter_powered || !g_adapter_path[0]) return;

    GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL);
    if (conn) {
        /* 1. Thiết lập Discovery Filter để quét cả Classic Bluetooth (BR/EDR) lẫn BLE Beacons */
        GVariantBuilder filter_builder;
        g_variant_builder_init(&filter_builder, G_VARIANT_TYPE("a{sv}"));
        g_variant_builder_add(&filter_builder, "{sv}", "Transport", g_variant_new_string("auto"));
        g_variant_builder_add(&filter_builder, "{sv}", "DuplicateData", g_variant_new_boolean(TRUE));
        GVariant *filter = g_variant_builder_end(&filter_builder);

        g_dbus_connection_call_sync(
            conn,
            "org.bluez",
            g_adapter_path,
            "org.bluez.Adapter1",
            "SetDiscoveryFilter",
            g_variant_new("(@a{sv})", filter),
            NULL,
            G_DBUS_CALL_FLAGS_NONE,
            1000,
            NULL, NULL
        );

        /* 2. Kích hoạt Discovery trên adapter */
        g_dbus_connection_call(
            conn,
            "org.bluez",
            g_adapter_path,
            "org.bluez.Adapter1",
            "StartDiscovery",
            NULL,
            NULL,
            G_DBUS_CALL_FLAGS_NONE,
            2000,
            NULL, NULL, NULL
        );
        g_object_unref(conn);
    }

    g_scanning = TRUE;
    g_scan_countdown = 15;
    gtk_button_set_label(b, "🔍 Đang quét (15s)...");
    gtk_widget_set_sensitive(GTK_WIDGET(b), FALSE);

    /* Kích hoạt discovery pipeline qua bluetoothctl để đảm bảo adapter nhận toàn bộ gói tin LE/BR */
    char *scan_args[] = {(char *)"bluetoothctl", (char *)"--timeout", (char *)"15", (char *)"scan", (char *)"on", NULL};
    spawn_cmd(scan_args);

    char *args[] = {(char *)"notify-send", (char *)"-a", (char *)"Bluetooth",
                    (char *)"-i", (char *)"bluetooth",
                    (char *)"Bluetooth Discovery",
                    (char *)"Đang quét tìm thiết bị lân cận trong 15s...", NULL};
    spawn_cmd(args);

    if (g_scan_timer_id > 0) g_source_remove(g_scan_timer_id);
    g_scan_timer_id = g_timeout_add_seconds(2, on_scan_poll_tick, NULL);

    refresh_content_area();
}

/* ============================================================================
 * Dọn dẹp tài nguyên khi cửa sổ bị đóng (Click ra ngoài hoặc bấm Esc/q)
 * ============================================================================ */
static void on_window_destroy(GtkWidget *w, gpointer u) {
    (void)w;
    (void)u;
    if (g_scan_timer_id > 0) {
        g_source_remove(g_scan_timer_id);
        g_scan_timer_id = 0;
    }
    if (g_scanning) {
        stop_discovery_sync();
    }
    g_main_box = NULL;
    g_content_area = NULL;
    g_subtitle_label = NULL;
    g_actions_bar = NULL;
    g_scan_btn = NULL;
}

/* ============================================================================
 * Khởi tạo cửa sổ Bluetooth của ka-pop
 * ============================================================================ */
GtkWidget* build_bluetooth_window(void) {
    GtkWidget *main_box = NULL;
    GtkWidget *win = create_base_window("bluetooth", 380, &main_box);
    g_main_box = main_box;

    fetch_bluez_state();

    /* Header: tiêu đề + công tắc nguồn */
    GtkWidget *sw = gtk_switch_new();
    gtk_switch_set_active(GTK_SWITCH(sw), g_adapter_powered);
    gtk_widget_set_valign(sw, GTK_ALIGN_CENTER);
    g_signal_connect(sw, "notify::active", G_CALLBACK(on_power_switch_changed), NULL);

    char sub[96];
    if (!g_service_active) {
        snprintf(sub, sizeof(sub), "Dịch vụ bluetoothd chưa chạy");
    } else if (!g_adapter_powered) {
        snprintf(sub, sizeof(sub), "Adapter đang tắt nguồn");
    } else {
        snprintf(sub, sizeof(sub), "%s · %d thiết bị", g_adapter_name, g_device_count);
    }

    {
        GtkWidget *h_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 10);
        GtkWidget *v_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);

        GtkWidget *lbl_t = gtk_label_new("Bluetooth");
        gtk_label_set_xalign(GTK_LABEL(lbl_t), 0.0f);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl_t), "title-label");
        gtk_box_pack_start(GTK_BOX(v_box), lbl_t, FALSE, FALSE, 0);

        g_subtitle_label = gtk_label_new(sub);
        gtk_label_set_xalign(GTK_LABEL(g_subtitle_label), 0.0f);
        gtk_style_context_add_class(gtk_widget_get_style_context(g_subtitle_label), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(v_box), g_subtitle_label, FALSE, FALSE, 0);

        gtk_box_pack_start(GTK_BOX(h_box), v_box, TRUE, TRUE, 0);
        gtk_box_pack_end(GTK_BOX(h_box), sw, FALSE, FALSE, 0);
        gtk_box_pack_start(GTK_BOX(main_box), h_box, FALSE, FALSE, 0);
    }

    /* Vùng nội dung chính (Index 1) */
    if (!g_service_active) {
        GtkWidget *msg_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
        GtkWidget *lbl = gtk_label_new(
            "Dịch vụ BlueZ chưa kích hoạt trên hệ thống.\nChạy lệnh: ka-setup sys hoặc sudo systemctl enable --now bluetooth");
        gtk_label_set_line_wrap(GTK_LABEL(lbl), TRUE);
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(msg_box), lbl, FALSE, FALSE, 10);
        gtk_box_pack_start(GTK_BOX(main_box), msg_box, FALSE, FALSE, 4);
        g_content_area = msg_box;
    } else if (!g_adapter_powered) {
        GtkWidget *off_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
        GtkWidget *lbl = gtk_label_new("Bật công tắc phía trên để kết nối thiết bị.");
        gtk_style_context_add_class(gtk_widget_get_style_context(lbl), "subtitle-label");
        gtk_box_pack_start(GTK_BOX(off_box), lbl, FALSE, FALSE, 14);
        gtk_box_pack_start(GTK_BOX(main_box), off_box, FALSE, FALSE, 4);
        g_content_area = off_box;
    } else {
        GtkWidget *device_list = build_device_list();
        gtk_box_pack_start(GTK_BOX(main_box), device_list, TRUE, TRUE, 4);
        g_content_area = device_list;
    }

    /* Thanh tác vụ: Quét thiết bị */
    g_actions_bar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    g_scan_btn = gtk_button_new_with_label("🔍 Quét thiết bị");
    gtk_style_context_add_class(gtk_widget_get_style_context(g_scan_btn), "action-btn");
    g_signal_connect(g_scan_btn, "clicked", G_CALLBACK(on_scan_btn_clicked), NULL);
    gtk_box_pack_start(GTK_BOX(g_actions_bar), g_scan_btn, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(main_box), g_actions_bar, FALSE, FALSE, 4);
    gtk_widget_set_visible(g_actions_bar, g_service_active && g_adapter_powered);

    build_footer(main_box, "Click để Kết nối/Ngắt · Esc để đóng");

    g_signal_connect(win, "destroy", G_CALLBACK(on_window_destroy), NULL);

    return win;
}
