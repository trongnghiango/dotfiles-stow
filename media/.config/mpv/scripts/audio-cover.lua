-- ==============================================================================
-- MPV AUDIO COVER & THUMBNAIL FALLBACK SCRIPT
-- ==============================================================================
-- Description: Automatically detects audio files without embedded cover art or
--              folder artwork, and injects a high-res aesthetic placeholder art.
-- ==============================================================================

local mp = require("mp")
local utils = require("mp.utils")

local function get_placeholder_path()
    return mp.command_native({"expand-path", "~~/assets/audio-placeholder.png"})
end

local function on_file_loaded()
    -- Check if video stream exists (either real video or embedded cover art)
    local vid = mp.get_property_native("vid")
    local video_format = mp.get_property("video-format")
    
    -- If vid is false/no/nil or no video format, this is a pure audio file with no cover art
    if not vid or vid == "no" or not video_format then
        local placeholder = get_placeholder_path()
        local file_info = utils.file_info(placeholder)
        if file_info and file_info.is_file then
            mp.msg.info("No cover art found. Displaying audio placeholder artwork: " .. placeholder)
            mp.commandv("video-add", placeholder, "select", "Cover Art", "", "yes")
        end
    end
end

mp.register_event("file-loaded", on_file_loaded)
