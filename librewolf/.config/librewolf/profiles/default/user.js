// ===== X230 HD4000 OPTIMIZED (FINAL SAFE) =====

/*** GPU & RENDER ***/
// Để mặc định để tránh crash. Không ép force-enabled.
user_pref("gfx.webrender.all", false);
user_pref("layers.acceleration.force-enabled", false);

/*** VIDEO DECODING (H.264 VA-API) ***/
user_pref("media.hardware-video-decoding.enabled", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
// HD4000 hỗ trợ H.264 rất tốt qua VA-API.

/*** CODEC BLOCKING (QUAN TRỌNG) ***/
// Chặn tuyệt đối codec nặng để ép Youtube về H.264
user_pref("media.av1.enabled", false);
user_pref("media.vp9.enabled", false);
user_pref("media.mediasource.vp9.enabled", false);
user_pref("media.webm.enabled", false);
user_pref("media.mediasource.webm.enabled", false);

/*** STABILITY FIX ***/
// Tắt RDD process để tránh crash driver cũ khi decode video
user_pref("media.rdd-process.enabled", false);

/*** MEMORY (16GB RAM) ***/
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 1048576); // 1GB Cache
user_pref("browser.sessionhistory.max_total_viewers", 6);

/*** NETWORK ***/
user_pref("network.http.http3.enable", false); // Tắt QUIC
user_pref("general.smoothScroll", true);
