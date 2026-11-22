# HƯỚNG DẪN CÀI ĐẶT DOCKER CHO DEBIAN PRODUCTION: TRIẾT LÝ ỔN ĐỊNH TUYỆT ĐỐI

> **Mục tiêu:** Thiết lập Docker Engine trên máy chủ **Debian Linux (Debian 12 Bookworm / Debian 13 Trixie)** đạt tiêu chuẩn **Enterprise Production**: Không tự ý nhảy phiên bản, không tràn ổ cứng do log, không rớt container khi restart daemon, và tối ưu hóa hiệu năng mạng mức kernel.

---

## PHẦN 1: BỐN TRỤ CỘT CỦA KIẾN TRÚC ỔN ĐỊNH

| Trụ cột | Cơ chế kỹ thuật | Nguy cơ nếu bỏ qua |
| :--- | :--- | :--- |
| **1. Ghim & Khóa gói (Pinning & Holding)** | `apt-cache madison` + `apt-mark hold` | Lệnh `apt-get upgrade` định kỳ tự ý kéo bản Docker mới nhất gây xung đột với container/ứng dụng đang chạy. |
| **2. Giới hạn dung lượng Log (Log Rotation)** | `"log-driver": "json-file"` với `max-size: 10m`, `max-file: 3` | Container chạy web/DB ghi hàng chục GB log, làm đầy 100% dung lượng đĩa gây sập hệ điều hành và hỏng dữ liệu. |
| **3. Duy trì Container khi bảo trì (Live Restore)** | `"live-restore": true` trong `daemon.json` | Mọi container bị dừng tức thì mỗi khi Docker Daemon reload, restart hoặc nâng cấp gói. |
| **4. Tối ưu định tuyến mạng (Zero Userland Proxy)** | `"userland-proxy": false` | Hàng loạt tiến trình `docker-proxy` Go userspace sinh ra ngốn RAM và tăng độ trễ mạng so với iptables/nftables trực tiếp. |

---

## PHẦN 2: QUY TRÌNH CÀI ĐẶT TỪNG BƯỚC (KÈM GIẢI THÍCH)

### Bước 1: Dọn dẹp môi trường (Clean Slate)
Gỡ sạch mọi gói Docker cũ hoặc các biến thể phân phối không đồng nhất:

```bash
sudo apt-get remove -y \
    docker.io \
    docker-doc \
    docker-compose \
    podman-docker \
    containerd \
    runc 2>/dev/null || true

sudo apt-get autoremove -y
```

*   **Tại sao làm vậy?** Kho APT mặc định của Debian cung cấp gói `docker.io` do cộng đồng Debian đóng gói. Gói này xung đột trực tiếp với `docker-ce` chính chủ của Docker Inc. Dọn sạch giúp loại bỏ triệt để xung đột dependency và file cấu hình rác.

---

### Bước 2: Cài đặt GPG Key và Repository Docker CE cho Debian
Cài đặt công cụ bảo mật và thiết lập nguồn gói chính thức từ Docker Inc dành riêng cho hệ sinh thái Debian:

```bash
# 1. Cài đặt các công cụ giao tiếp HTTPS và xử lý GPG
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 2. Tạo thư mục lưu trữ GPG Key chuẩn bảo mật Debian
sudo install -m 0755 -d /etc/apt/keyrings

# 3. Tải và giải mã GPG Key chính thức của Docker cho Debian
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 4. Thêm Repository chính thức của Debian vào sources.list.d (tự động nhận diện bookworm / trixie)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Cập nhật lại chỉ mục gói
sudo apt-get update -y
```

*   **Tại sao dùng repo chính chủ thay vì `docker.io` của Debian?**
    *   *Bảo mật chuỗi cung ứng:* Kèm GPG Key xác thực toàn vẹn.
    *   *Lịch sử phiên bản đầy đủ:* Repo Debian chỉ lưu phiên bản tại thời điểm phát hành distro, trong khi repo Docker lưu trữ toàn bộ lịch sử các bản vá ổn định (point releases), cho phép chọn chính xác bản đã test.

---

### Bước 3: Tra cứu & Ghim phiên bản (Version Pinning)
Không bao giờ cài đặt phiên bản "Latest" trên môi trường Production:

```bash
# 1. Liệt kê các phiên bản có sẵn trong kho
apt-cache madison docker-ce | head -n 10
```

*Output mẫu trên Debian 12 (bookworm):*
```text
 docker-ce | 5:27.3.1-1~debian.12~bookworm | https://download.docker.com/linux/debian bookworm/stable amd64 Packages
 docker-ce | 5:26.1.4-1~debian.12~bookworm | https://download.docker.com/linux/debian bookworm/stable amd64 Packages
 docker-ce | 5:24.0.9-1~debian.12~bookworm | https://download.docker.com/linux/debian bookworm/stable amd64 Packages
```

```bash
# 2. Chọn phiên bản mong muốn và cài đặt kèm chuỗi phiên bản chính xác
DOCKER_VER="5:27.3.1-1~debian.12~bookworm"

sudo apt-get install -y --no-install-recommends \
    docker-ce="$DOCKER_VER" \
    docker-ce-cli="$DOCKER_VER" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

*   **Tại sao phải chỉ định `=<version>`?**
    *   Tránh hiện tượng mỗi lần dựng server mới lại ra một phiên bản Docker khác nhau. Bạn bắt buộc phải cài đúng phiên bản đã vượt qua bài kiểm thử (Staging/QA).

---

### Bước 4: Khóa phiên bản (Package Holding)
Đặt chốt chặn không cho hệ thống tự nâng cấp Docker Engine:

```bash
sudo apt-mark hold \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

*   **Kiểm tra lại trạng thái khóa:**
```bash
apt-mark showhold
```

*   **Tại sao bắt buộc?**
    *   Khi bạn hoặc đồng nghiệp chạy lệnh `sudo apt-get upgrade`, APT sẽ bỏ qua các gói này. Docker Engine sẽ đứng yên cho đến khi bạn chủ động mở khóa có kế hoạch.

---

### Bước 5: Cấu hình Daemon Production Chống Sập & Tối Ưu Mạng
Thiết lập file cấu hình trung tâm `/etc/docker/daemon.json`:

```bash
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF
```

*   **Giải thích chi tiết 4 tham số vàng:**
    1.  **`log-opts`**: Khống chế mỗi container tối đa 3 file x 10MB = 30MB log. Tránh hoàn toàn lỗi Disk Full.
    2.  **`live-restore: true`**: Cho phép container duy trì trạng thái hoạt động ngay cả khi daemon Docker bị restart, crash hoặc reload cấu hình.
    3.  **`userland-proxy: false`**: Vô hiệu hóa tiến trình trung gian `docker-proxy` viết bằng Go. Toàn bộ lưu lượng mạng được chuyển thẳng cho Netfilter/iptables trong kernel xử lý, giảm độ trễ (latency) 15-25% và tiết kiệm RAM.
    4.  **`no-new-privileges: true`**: Tăng cường bảo mật, cấm các tiến trình con bên trong container tự leo thang đặc quyền qua `setuid`/`setgid`.

Áp dụng cấu hình và kích hoạt dịch vụ:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now docker
sudo systemctl restart docker
```

---

### Bước 6: Phân quyền Người dùng (Non-root Management)
Tránh việc lạm dụng quyền `sudo` khi thao tác với container:

```bash
# 1. Đảm bảo nhóm docker tồn tại
sudo groupadd -f docker

# 2. Thêm user hiện tại vào nhóm docker
sudo usermod -aG docker "$USER"
```

> [!WARNING]
> **Tuyệt đối không dùng lệnh `newgrp docker` trong automation script!**  
> Lệnh `newgrp` mở ra một subshell tương tác mới và sẽ chặn đứng luồng thực thi của các script tự động hóa. Hãy đăng xuất SSH và đăng nhập lại, hoặc kiểm tra ngay trong phiên hiện tại bằng lệnh:  
> `sg docker -c "docker info"`

---

## PHẦN 3: GIẢI THÍCH CHUYÊN SÂU: TẠI SAO DÙNG `apt-get` MÀ KHÔNG DÙNG `apt`?

Trong tài liệu kỹ thuật chuẩn mực, **`apt-get` là tiêu chuẩn bắt buộc cho Production và Automation**:

1.  **Tính ổn định của định dạng đầu ra (Output Stability):**
    *   `apt` được thiết kế cho con người ngồi gõ: có thanh tiến trình động, màu sắc, và định dạng output thay đổi theo từng bản cập nhật distro.
    *   `apt-get` được thiết kế cho máy móc và script: định dạng log đơn giản, cố định, không thay đổi cấu trúc qua nhiều thập kỷ, đảm bảo script không bao giờ bị lỗi regex/parsing sau 5-10 năm.
2.  **Hành vi trong môi trường Non-Interactive:**
    *   Khi chạy qua SSH, CI/CD runner hoặc Docker build, `apt` có thể bị nghẽn (hang) do cố gắng hiển thị progress bar mà không có pseudo-TTY.
    *   `apt-get` chạy ngầm mượt mà 100%.
3.  **Tương thích ngược tuyệt đối (Backward Compatibility):**
    *   `apt-get` có mặt trên mọi hệ điều hành họ Debian/Ubuntu từ thời kỳ đầu. Dùng `apt-get` là dùng ngôn ngữ chuẩn mực chung cho toàn bộ hệ sinh thái.

---

## PHẦN 4: KIỂM TRA NGHIỆM THU HỆ THỐNG (HEALTH CHECK)

Chạy các lệnh kiểm tra sau để xác nhận cài đặt chuẩn mực:

```bash
# 1. Kiểm tra phiên bản Engine & CLI
docker version --format 'Client: {{.Client.Version}} | Server: {{.Server.Version}}'

# 2. Xác nhận tính năng Live-Restore đã kích hoạt thành công
docker info 2>/dev/null | grep -i "Live Restore Enabled"
# Kết quả mong đợi: Live Restore Enabled: true

# 3. Chạy thử container kiểm tra quyền không cần sudo
docker run --rm hello-world

# 4. Xác nhận Compose V2 Plugin hoạt động
docker compose version
```

---

## PHẦN 5: QUY TRÌNH NÂNG CẤP CÓ KIỂM SOÁT (CONTROLLED UPGRADE SOP)

Khi xuất hiện lỗ hổng bảo mật nghiêm trọng (CVE) và bạn chủ động muốn nâng cấp phiên bản Docker:

```bash
# 1. Cập nhật chỉ mục gói mới nhất
sudo apt-get update -y

# 2. Xem danh sách các phiên bản mới có sẵn
apt-cache madison docker-ce | head -n 5

# 3. Mở khóa toàn bộ hệ sinh thái Docker
sudo apt-mark unhold \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 4. Cài đặt CHÍNH XÁC phiên bản mới đã kiểm thử
NEW_VER="5:27.3.1-1~debian.12~bookworm"

sudo apt-get install -y --no-install-recommends \
    docker-ce="$NEW_VER" \
    docker-ce-cli="$NEW_VER" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 5. KHÓA LẠI NGAY LẬP TỨC
sudo apt-mark hold \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 6. Xác nhận phiên bản mới đã nạp
docker info | grep "Server Version"
```

---

## PHẦN 6: SCRIPT CÀI ĐẶT TỰ ĐỘNG HOÀN TOÀN (ALL-IN-ONE AUTOMATED SCRIPT)

Bạn có thể lưu đoạn mã sau thành `install_docker_debian.sh` để triển khai tự động trong 1 lệnh:

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Cài Đặt Docker CE Production cho Debian (Debian 12 Bookworm / 13 Trixie)
# Chuẩn mực: Version Pinning + Holding + Live Restore + Log Rotation
# ==============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Vui lòng thực thi script với quyền root hoặc sudo." >&2
  exit 1
fi

echo ">>> [1/6] Dọn dẹp các gói Docker cũ không đồng nhất..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done
apt-get autoremove -y

echo ">>> [2/6] Cài đặt công cụ nền tảng & cấu hình Docker GPG Key..."
apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

DEBIAN_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  ${DEBIAN_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

echo ">>> [3/6] Tự động tra cứu và cài đặt phiên bản ổn định mới nhất..."
TARGET_VER="$(apt-cache madison docker-ce | awk '{print $3}' | head -n 1)"
echo "Phiên bản được ghim: $TARGET_VER"

apt-get install -y --no-install-recommends \
    docker-ce="$TARGET_VER" \
    docker-ce-cli="$TARGET_VER" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo ">>> [4/6] Khóa phiên bản (Package Holding)..."
apt-mark hold \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo ">>> [5/6] Triển khai daemon.json chuẩn Enterprise Production..."
mkdir -p /etc/docker
cat <<-'EOF' > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

systemctl daemon-reload
systemctl enable --now docker
systemctl restart docker

echo ">>> [6/6] Phân quyền Non-root cho user quản trị..."
REAL_USER="${SUDO_USER:-$USER}"
if [ "$REAL_USER" != "root" ]; then
  groupadd -f docker
  usermod -aG docker "$REAL_USER"
  echo "Đã thêm user '$REAL_USER' vào nhóm docker."
fi

echo "================================================================"
echo "✔ CÀI ĐẶT DOCKER PRODUCTION TRÊN DEBIAN HOÀN TẤT THÀNH CÔNG!"
echo "  Phiên bản Engine : $(docker --version)"
echo "  Live Restore     : Bật (Active)"
echo "  Log Rotation     : Tối đa 30MB/container"
echo "  Tài khoản        : $REAL_USER"
echo "  LƯU Ý            : Hãy đăng xuất SSH và đăng nhập lại để nạp quyền."
echo "================================================================"
```
