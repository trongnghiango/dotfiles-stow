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
#define BLOCKS(X)                     \
    X("", "ka-forecast", 1800, 14)    \
    X("", "ka-memory",   10,   10)    \
    X("", "ka-cpu",      2,    15)    \
    X("", "ka-nettraf",  2,    18)    \
    X("", "ka-battery",  60,   30)    \
    X("", "ka-volume",   60,    11)    \
    X("", "ka-internet", 10,   4)     \
    X("", "ka-clock",    60,   1)

#endif  // CONFIG_H
