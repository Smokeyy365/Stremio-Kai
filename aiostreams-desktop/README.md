# Stremio Kai scripts for AIOStreams Desktop

Puts Stremio Kai's mpv scripts and player tuning into the
[AIOStreams Desktop](https://github.com/Viren070/AIOStreams/tree/main/packages/desktop) app.

## Install

1. Download this repository (Code → Download ZIP) and extract it.
2. Close AIOStreams Desktop.
3. In this `aiostreams-desktop` folder, run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

   If Stremio Kai is installed, add `-KaiDir C:\path\to\Stremio-Kai` to copy its full shader set
   and fonts as well. Without it, only the Anime4K shaders are downloaded.
4. Start AIOStreams Desktop and play something.

The files go to `%APPDATA%\AIOStreams Desktop\mpv`, the only folder the app reads mpv config from.
`%LOCALAPPDATA%\aiostreams-desktop` is the app's install folder and is replaced on every update.
For a portable copy, pass `-MpvDir <copy>\data\mpv`. Your old `mpv.conf` and `input.conf` are kept
as `*.pre-kai`.

## What is ported

| Kai part | Under AIOStreams Desktop |
| --- | --- |
| `mpv.conf` (scaling, deband, dither, cache, anime/cinema profiles) | Works. The `log-file` line is dropped |
| `input.conf` (Anime4K F1–F4, F8 colour profiles, backtick for audio presets, etc.) | Works for keys the page doesn't use itself. F11 stays the app's fullscreen. `q quit` is dropped because it would close the player |
| `profile-manager.lua` (anime/cinema profiles, HDR, Anime4K, colour and audio presets) | Works, set through `script-opts\kai_bridge.conf` |
| `notify_skip` (skip intro/outro, Tab) | Works from chapters and silence detection. IntroDB lookups are off: they need Kai's bundled Python |
| `smart-track-selector` | Works from `script-opts\smart_track_selector.conf`. Track choices you make in the app's own menu still win |
| SVP (`svp_*.vpy`, `reactive_vf_bypass`, `svp_cleanup`) | Copied but off by default: it needs SVP 4 and VapourSynth installed |
| `thumbfast.lua` | Not ported. The app draws its own seek bar, which never asks thumbfast for thumbnails |
| `webmods/` (hero banner, metadata panel, settings pages, themes) | Not ported. They patch Stremio's web UI, and the app gives no way to load scripts into its page |

`kai-bridge.lua` takes the place of Kai's `mpv-bridge.js`, which fed these scripts settings from
the Settings page. It sends the same messages from `kai_bridge.conf` and works out movie or episode
from the file name.
Anime is detected by release group in the file name only. Kai's metadata database lookup lives in
its web mods. Set `force_anime=yes` while watching anime if a release isn't recognised.
