#ifndef CONFIG_H
#define CONFIG_H

// Dấu phân cách giữa các block (2 khoảng trắng như cũ)
#define DELIMITER "  "

// Độ dài tối đa của text output (50 ký tự là đủ cho weather/music)
#define MAX_BLOCK_OUTPUT_LENGTH 50

// Bật tính năng click chuột (Quan trọng để dùng $BUTTON)
#define CLICKABLE_BLOCKS 1

// Không hiện dấu phân cách ở đầu chuỗi status
#define LEADING_DELIMITER 0

// Không hiện dấu phân cách ở cuối chuỗi status
#define TRAILING_DELIMITER 0

// Định nghĩa các blocks: X(icon, cmd, interval, signal)
// Lưu ý: Interval = 0 nghĩa là chỉ update khi có signal (tương tự bản cũ)
// Số lượng block thuộc phân vùng Center (giữa)
#define CENTER_BLOCK_COUNT 2

// Định nghĩa các blocks: X(icon, cmd, interval, signal)
// Phân đoạn 1 (Center): ka-clock, ka-forecast
// Phân đoạn 2 (Right): sb-record, ka-volume, ka-battery, ka-network, ka-cpu, ka-memory, sb-notify
#define BLOCKS(X)                     \
    X("", "ka-clock",    60,   1)     \
    X("", "ka-forecast", 1800, 14)    \
    X("", "sb-record",   0,    9)     \
    X("", "ka-volume",   60,   11)    \
    X("", "ka-battery",  60,   30)    \
    X("", "ka-network",  10,   4)     \
    X("", "ka-cpu",      2,    15)    \
    X("", "ka-memory",   10,   10)    \
    X("", "sb-notify",   10,   8)

#endif  // CONFIG_H
