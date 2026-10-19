--[[
  @name Kai Bridge (AIOStreams Desktop)
  @description Stands in for Stremio Kai's mpv-bridge.js, which AIOStreams Desktop cannot load.
               Sends profile-manager and notify_skip the messages they wait for, built from
               script-opts/kai_bridge.conf and the file name instead of Kai's Settings page.
--]]

local utils = require("mp.utils")

local o = {
    hdr_passthrough = false,
    target_peak = "auto",
    shader_preset = "optimized", -- optimized | fast | hq | none
    color_profile = "kai",       -- kai | vivid | original
    icc_profile = false,
    svp_enabled = false,         -- needs SVP 4 + VapourSynth installed
    svp_global = false,
    audio_preset = "off",
    osd_profile_messages = true,
    ultrawide_zoom = false,
    force_anime = false,         -- treat everything as anime (Kai detects it from its metadata DB)
}
require("mp.options").read_options(o, "kai_bridge")

-- Returns season, episode from names like "S01E05", "1x05" or "[Group] Title - 05".
local function parse_episode(name)
    local s, e = name:match("[Ss](%d+)[%s%._-]*[Ee](%d+)")
    if not s then s, e = name:match("%f[%w](%d%d?)x(%d%d%d?)%f[%W]") end
    if not s then
        e = name:match("%s%-%s(%d%d%d?%d?)[%s%.%[%(v]") or name:match("%s%-%s(%d%d%d?%d?)$")
        s = e and "1"
    end
    return tonumber(s), tonumber(e)
end

-- file-loaded comes after both scripts reset on start-file, so these are not cleared.
mp.register_event("file-loaded", function()
    local name = (mp.get_property("media-title") or "") .. " " .. (mp.get_property("filename") or "")
    local season, episode = parse_episode(name)
    local content_type = season and "series" or "movie"
    local imdb_id = (mp.get_property("path") or ""):match("tt%d+")

    mp.commandv("script-message-to", "notify_skip", "content-metadata", utils.format_json({
        content_type = content_type, imdb_id = imdb_id, season = season, episode = episode,
    }))
    mp.commandv("script-message-to", "profile_manager", "anime-metadata", utils.format_json({
        is_anime = o.force_anime,
        detection_reason = o.force_anime and "kai_bridge force_anime" or nil,
        imdb_id = imdb_id,
        content_type = content_type,
        hdr_passthrough = o.hdr_passthrough,
        shader_preset = o.shader_preset,
        svp_enabled = o.svp_enabled,
        svp_global = o.svp_global,
        color_profile = o.color_profile,
        icc_profile = o.icc_profile,
        target_peak = o.target_peak,
        osd_profile_messages = o.osd_profile_messages,
        -- gpu-api=vulkan clashes with the d3d11 context AIOStreams Desktop sets.
        vulkan_mode = false,
        ultrawide_zoom = o.ultrawide_zoom,
        audio_preset = o.audio_preset,
    }))
end)

-- Self-check: `mpv --script=kai-bridge.lua --script-opts=kai_bridge-selftest=yes --idle=once`
if mp.get_opt("kai_bridge-selftest") then
    local cases = {
        ["Show.Name.S02E07.1080p.WEB"] = { 2, 7 },
        ["Show Name 3x12 720p"] = { 3, 12 },
        ["[SubsPlease] Frieren - 05 (1080p) [ABCD].mkv"] = { 1, 5 },
        ["Movie.Name.2019.2160p.UHD"] = { nil, nil },
        ["Movie 1920x1080 x264"] = { nil, nil },
    }
    for name, want in pairs(cases) do
        local s, e = parse_episode(name)
        assert(s == want[1] and e == want[2], name .. " -> " .. tostring(s) .. "," .. tostring(e))
    end
    mp.msg.info("kai-bridge self-test passed")
end
