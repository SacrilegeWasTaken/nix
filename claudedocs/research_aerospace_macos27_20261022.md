# AeroSpace on macOS 27: research findings

Date: 2026-10-22

## Executive summary

The observed instability is most likely a combination of macOS 27 Spaces/WindowServer changes and AeroSpace's dependency on undocumented or fragile window/Spaces behavior. It is not evidence of a local AeroSpace fork: the Darwin configuration installs the official `nikitabobko/tap/aerospace` cask, currently `0.21.3-Beta`.

## Evidence

- AeroSpace's upstream release page lists `v0.21.3-Beta` as the latest release and marks it pre-release: <https://github.com/nikitabobko/AeroSpace/releases>.
- Upstream discussion #1939 reports random workspace switching, workspace state desynchronization, and windows moving across workspaces on macOS 27.0 while running AeroSpace 0.21.3-Beta: <https://github.com/nikitabobko/AeroSpace/discussions/1939>.
- Upstream discussion #2262 reports crashes when the display set changes in a clamshell setup on macOS 27.0, still on 0.21.3-Beta: <https://github.com/nikitabobko/AeroSpace/discussions/2262>.
- AeroSpace's own guide explains that it emulates workspaces by moving hidden windows off-screen because macOS provides no public API for creating, switching, or moving native Spaces. It also documents focus and performance problems when `Displays have separate Spaces` is enabled: <https://nikitabobko.github.io/AeroSpace/guide>.
- Apple documents macOS 27 Window Management compatibility changes, including changes that apply to applications linked against the macOS 27 SDK: <https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes>.

## Local configuration observations

- macOS version: 27.0.1 (build 26A434).
- AeroSpace version: 0.21.3-Beta.
- AeroSpace's own `start-at-login` is disabled; a separate launchd agent runs `/usr/bin/open -a Aerospace` at login.
- `on-focused-monitor-changed = ['move-mouse monitor-lazy-center']` is enabled. This is a legitimate documented callback, but it adds another focus/mouse side effect while diagnosing focus races.
- No workspace-change callback or AeroSpace fork is present after cleanup.

## Likely causes, ordered

1. macOS 27 regression or behavioral change in Spaces/WindowServer, especially after notifications, sleep/wake, monitor hot-plug, or clamshell transitions.
2. AeroSpace 0.21.3-Beta not fully adapted to those changes; upstream reports remain open and the latest release is still a beta.
3. Multi-monitor configuration with `Displays have separate Spaces`, if enabled in macOS. AeroSpace explicitly recommends disabling it for stability unless native fullscreen behavior across monitors is required.
4. Startup/focus race from launching AeroSpace through a separate launchd agent while its native `start-at-login` setting is disabled.

## Safe diagnostic sequence

1. Record the exact symptom and trigger: idle focus jump, monitor change, sleep/wake, clamshell, or native fullscreen.
2. Temporarily disable `on-focused-monitor-changed` and compare behavior.
3. Check whether `Displays have separate Spaces` is enabled; test with it disabled and log out/in.
4. Reproduce once with one monitor and once after sleep/wake or monitor hot-plug.
5. Collect `aerospace -v`, `aerospace list-windows --all`, and the AeroSpace launchd stdout/stderr logs.
6. Compare against a clean upstream config before changing keybindings or layout settings.

## Recommendation

Do not remove AeroSpace or rewrite the keymap yet. First isolate whether the failure is focus switching, workspace assignment, display transitions, or a crash. The highest-value configuration experiment is to disable the mouse-follow callback and use one startup mechanism. If the failure persists on a single monitor with a clean config, it should be treated as an upstream macOS 27/AeroSpace compatibility bug rather than configuration drift.

## Confirmed local symptom

On the affected machine, `aerospace list-windows --all` lists Safari and System Settings but does not list the running Kitty or Telegram windows. macOS System Events names their foreground processes `.kitty-wrapped` and `.Telegram-wrapped`. The Nix-generated app executables contain `makeCWrapper` metadata and point at `.kitty-wrapped` / `.Telegram-wrapped` launchers.

This matches AeroSpace discussion #2282: macOS 27 can report an invalid PID for applications launched through script or native wrapper executables, causing AeroSpace to omit them from `list-apps` and `list-windows --all`. The discussion's workaround is to launch the real application launcher directly, but that has trade-offs around LaunchServices and privacy attribution: <https://github.com/nikitabobko/AeroSpace/discussions/2282>.

This makes the Nix app wrappers, rather than the AeroSpace keymap, the primary suspect for Kitty and Telegram.
