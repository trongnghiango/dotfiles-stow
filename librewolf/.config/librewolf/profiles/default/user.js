/*********************************************************
 * LibreWolf – X230 HD4000 optimized V2 (SAFE VERSION)
 *********************************************************/

/*** GPU / RENDER ***/
// KHÔNG ép buộc WebRender. Để trình duyệt tự quyết định.
// user_pref("gfx.webrender.all", true); // <-- DÒNG NGUY HIỂM, ĐÃ XÓA

/*** VIDEO – HARDWARE DECODING ***/
user_pref("media.hardware-video-decoding.enabled", true); // Chỉ hỗ trợ H.264
// XÓA: user_pref("media.ffmpeg.vaapi.enabled", true); // HD4000 không dùng VA-API

// BLOCK HEAVY CODECS (Thay thế h264ify) - PHẦN NÀY RẤT TỐT
user_pref("media.av1.enabled", false);
user_pref("media.vp9.enabled", false);
user_pref("media.mediasource.vp9.enabled", false);
user_pref("media.webm.enabled", false);
user_pref("media.mediasource.webm.enabled", false);

/*** MEMORY (Tận dụng 16GB RAM) ***/
user_pref("browser.cache.disk.enable", false); // Bảo vệ SSD
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 1048576); // 1GB RAM Cache
user_pref("browser.sessionhistory.max_total_viewers", 6);
user_pref("browser.tabs.unloadOnLowMemory", true); // Tự động dọn tab khi RAM thấp

/*** PERFORMANCE & NETWORK ***/
user_pref("dom.ipc.processCount", 4); // Phù hợp với 2C/4T
user_pref("network.http.http3.enable", false); // Giảm tải CPU
user_pref("network.http.max-connections", 900);
user_pref("general.smoothScroll", true);

/*** PRIVACY & UX ***/
// KHÔNG tắt RFP toàn cục. Nếu gặp lỗi site cụ thể, hãy tắt trong biểu tượng shield.
// user_pref("privacy.resistFingerprinting", false); // <-- NÊN GIỮ MẶC ĐỊNH
// user_pref("privacy.firstparty.isolate", false); // <-- NÊN GIỮ MẶC ĐỊNH
user_pref("privacy.trackingprotection.enabled", true);
