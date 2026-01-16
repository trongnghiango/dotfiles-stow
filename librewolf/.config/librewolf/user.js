// ===== HD4000 SAFE PROFILE =====

// WebRender
user_pref("gfx.webrender.enabled", true);
user_pref("gfx.webrender.all", false);

// VAAPI (safe mode)
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.enabled", true);

// Disable codecs HD4000 can't handle well
user_pref("media.av1.enabled", false);
user_pref("media.vp9.enabled", false);
user_pref("media.webm.enabled", false);
user_pref("media.mediasource.webm.enabled", false);

// Stability
user_pref("media.rdd-process.enabled", false);
user_pref("layers.acceleration.force-enabled", false);

// Network sanity
user_pref("network.http.http3.enable", false);
user_pref("network.prefetch-next", false);
