# 🤖 KHU VƯỜN LẬP TRÌNH TÍ HON: BỘ TẬP LỆNH SÀN GẠCH (BÉ 4 - 6 TUỔI)

> **"Tách biệt hoàn toàn giữa TẬP LỆNH TRONG TAY (Code) và MÔI TRƯỜNG THỰC TẾ TRÊN SÀN (Real-world Environment)"**

---

## 1. TRIẾT LÝ THIẾT KẾ: TẠI SAO 100% LÀ THẺ HÀNH ĐỘNG?

Trong kiến trúc máy tính thực thụ:
* **Tập lệnh (Instruction Set / Code)**: Là thứ nằm trong bộ nhớ và trong tay lập trình viên (Di chuyển, Rẽ, Nhặt, Lặp lại...).
* **Môi trường & Dữ liệu (State / Memory Grid)**: Là thế giới bên ngoài mà chương trình tương tác.

Thay vì in những tấm thẻ giấy vẽ hòn đá hay vũng nước vô hồn, **chúng ta tận dụng 100% đồ vật thật trong nhà**:
* **Chướng ngại vật cứng (Hard Obstacle)**: Chiếc **gối ôm**, chiếc **ghế đẩu**, đôi **dép**, hộp carton...
* **Vũng nước / Đầm lầy (Jump Obstacle)**: Chiếc **khăn tắm màu xanh** trải trên sàn, một tờ giấy màu...
* **Kho báu / Mục tiêu (Target)**: Chú **gấu bông**, quả **chuối**, chiếc **xe ô tô đồ chơi**, hộp sữa...

Bé nhìn thấy vật thể thật 3D ngoài đời, sau đó dùng **Tập lệnh hành động trừu tượng (Thẻ bài)** để giải quyết bài toán. Đó chính là khoảnh khắc tư duy máy tính được đánh thức!

---

## 2. BẢNG TẬP LỆNH HOÀN CHỈNH (16 MẪU THẺ - 30 THẺ IN)

Toàn bộ 5 trang A4 in ra đều là **thẻ lệnh hành động** để bé cầm trên tay:

| Nhóm Lệnh | Màu Sắc | Các Thẻ Lệnh Trong Bộ | Chức Năng |
| :--- | :--- | :--- | :--- |
| **1. Di Chuyển** | **Xanh Lá** | • Bước tới 1 bước (5 thẻ)<br>• Bước tới 2 bước (2 thẻ)<br>• Bước tới 3 bước (1 thẻ)<br>• Lùi lại 1 bước (1 thẻ) | Tiến/lùi theo trục số nguyên trên ô gạch. |
| **2. Xoay Hướng** | **Xanh Dương** | • Quay sang trái 90° (3 thẻ)<br>• Quay sang phải 90° (3 thẻ)<br>• Quay đằng sau 180° (1 thẻ)<br>• Nhảy qua 1 ô (2 thẻ) | Xoay góc nhìn cục bộ (Heading). Nhảy vọt qua khăn tắm/chướng ngại vật thấp. |
| **3. Tương Tác** | **Vàng Cam** | • Cúi xuống & bắt lấy (3 thẻ)<br>• Đặt đồ xuống (1 thẻ)<br>• Bíp bíp! Chào bạn (1 thẻ)<br>• Quan sát phía trước (1 thẻ) | Gắp vật phẩm thật (gấu bông, quả bóng) và kích hoạt âm thanh robot. |
| **4. Điều Khiển** | **Tím Phép Thuật** | • Bắt đầu - Start (2 thẻ)<br>• Về đích - Finish (2 thẻ)<br>• Lặp lại 2 lần (1 thẻ)<br>• Lặp lại 3 lần (1 thẻ) | Khởi động luồng chương trình và tối ưu hóa vòng lặp (Loops). |

---

## 3. CÁCH BA MẸ THIẾT LẬP VÀ ĐỒNG HÀNH CÙNG BÉ

1. **Thiết lập sàn nhà**:
   * Chọn khoảng $4 \times 4$ hoặc $5 \times 5$ ô gạch men trống trong phòng.
   * Đặt 1 chiếc gối ôm vào 1 ô gạch (Làm bức tường chắn).
   * Trải 1 chiếc khăn tắm nhỏ màu xanh vào 1 ô gạch (Làm vũng nước cần nhảy qua).
   * Đặt 1 chú gấu bông vào ô đích (Kho báu).
2. **Bé lập trình**:
   * Bé đứng quan sát toàn bộ căn phòng (bàn cờ).
   * Bé cầm xấp thẻ bài hành động trên tay, ngồi bệt xuống sàn và bắt đầu xếp một **hàng thẻ lệnh dài**:
     `[START]` ➔ `[BƯỚC 1]` ➔ `[QUAY PHẢI]` ➔ `[NHẢY QUA 1 Ô]` ➔ `[BƯỚC 2]` ➔ `[CÚI XUỐNG BẮT LẤY]` ➔ `[FINISH]`
3. **Thực thi (Run code)**:
   * **Cách 1 (Chơi với Ba)**: Ba đóng vai Robot, bé bấm nút "START" và đọc từng thẻ để Ba đi chính xác từng ô gạch.
   * **Cách 2 (Bé tự chơi một mình)**: Bé cầm chiếc xe ô tô hoặc chú khủng long đồ chơi di chuyển lần lượt qua từng ô gạch theo đúng hàng thẻ mình vừa xếp.
4. **Săn Bọ (Debugging)**:
   * Nếu ô tô đồ chơi hoặc Ba đâm sầm vào chiếc gối ôm: Ba và bé cùng nhau tìm xem "dòng code" nào bị sai để đổi lại thẻ rẽ.
