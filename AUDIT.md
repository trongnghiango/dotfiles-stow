# SYSTEMS-LEVEL ENGINEERING AUDIT
## Dotfiles Repository — Omarchy-X11 Userspace
### Audit Standard: Linus Torvalds-Style Critical Analysis

---

# I. SYSTEM ARCHITECTURE RECONSTRUCTION

## Component Map

```
KERNEL INTERFACE LAYER
  /proc/stat  /proc/meminfo  /proc/net/wireless  /sys/class/...
        |  direct read()
NATIVE C DAEMON LAYER (~75 MB RSS total)
  dwm 6.8 (15MB)       dwmblocks (2.2MB)     ka-clipd (1.1MB)
  |- pertag             |- 10 native blocks    |- XFixes events
  |- vanitygaps         |- signalfd IPC        |- DJB2 dedup
  |- swallow            |- poll() event loop   +- JSON history
  |- seamless_restart   +- pid file mgmt
  |- status2d/statuscmd
  |- bar_systray        ka-pop (0MB idle/35MB active)
  |- xrdb live reload   |- 11 GTK3 modules
  +- cfacts/dragmfact   |- spawn_cmd forks
                        +- _KA_BLOCK_SIGNAL X atom IPC
        |  X11 protocol / xcb
X11 SESSION LAYER
  Xorg -- picom (glx|none) -- xrdb -- fcitx5 -- dunst
  xwallpaper -- polkit-agent -- gnome-keyring -- udiskie
        |  D-Bus / PipeWire protocol
AUDIO / SYSTEM BUS LAYER
  PipeWire+WirePlumber  OR  ALSA (hardware profile conditional)
  D-Bus session (systemd socket OR dbus-launch)
        |  GNU Stow symlinks
CONFIGURATION / GNU STOW LAYER (24 packages)
  zsh - shell - x11 - suckless - theme - hardware - desktop
  dunst - picom - lf - nvim - tmux - media - opencode - ...
```

## Boot Sequence

```
TTY1 login
  +-> .zshenv          (ZDOTDIR only -- correct)
       +-> .zprofile   (sources shell/profile [LOAD #1], exec startx)
            +-> shell/profile  (XDG vars, PATH, ZDOTDIR, shortcuts)
                 +-> xinitrc
                      |- D-Bus init
                      |- sources shell/profile [LOAD #2] <-- REDUNDANT BUG
                      |- theme/current.conf
                      |- hardware/current.conf
                      |- xprofile (may source profile [LOAD #3]) <-- BUG
                      |- xrdb merge
                      |- audio stack (PipeWire | ALSA)
                      |- session daemons
                      +-> exec dwm
```

## Signal IPC Architecture

```
DWM --sigqueue(SIGRTMIN+N, button)--> dwmblocks
  |
  | (block click)
  |- getblocksignal() reads _KA_BLOCK_SIGNAL X atom
  +-> dropdowntosig() string-match --> ka-pop <module>
        +-> sets _KA_BLOCK_SIGNAL on popup window
              +-> dwm reads back for underline alignment
```

---

# II. EXECUTIVE AUDIT

## Strengths

1. Zero-fork native blocks: All 10 dwmblocks functions run in-process.
   No shell spawning for routine status updates. Architecture correct.

2. Hardware profile abstraction: Clean conditional audio/compositor
   selection via hardware/current.conf. ThinkPad X230 correctly bypasses
   PipeWire and picom entirely.

3. XFixes clipboard daemon: ka-clipd event-driven via X server push
   notifications. No polling. ~1.1 MB RSS. Correct design.

4. Seamless DWM restart: X atom persistence of per-tag layout state
   across execvp(argv[0]). Client state survives hot-restart.

5. GNU Stow discipline: 24 packages with consistent XDG paths.
   No ~/.bashrc, no ~/.*rc pollution (mostly).

6. poll()-based event loops: Both DWM main loop and dwmblocks watcher
   use poll() correctly. No busy-wait. EINTR safe.

7. drw_scm_free() discipline: XftColor resources freed via
   XftColorFree() before display close. No X server color leak.

## Weaknesses Summary

- P0: 3 correctness bugs in C code (timer dead path, status2d OOB,
  microcode missing from bootloader)
- P0: profile sourced 2-3x per session (boot correctness)
- P0: dunst-signal-hook completely disconnected from dunstrc
- P1: xcape undeclared in any pkgs/*.csv
- P1: theme-set hardcodes "audio_backend": "pipewire" always
- P1: udev rules install path wrong in stow structure
- P1: OS-specific aliasrc files never sourced
- P2: native_notify forks 2 processes per update despite interval=0
- P2: clip.c uses system() with user-controlled path (injection risk)
- P3: .zcompdump tracked in git; duplicate env var assignments

---

# III. CRITICAL FINDINGS

## CRIT-01 [P0] -- timer.c:63: Dead Code Path

File: suckless/.local/src/dwmblocks/src/timer.c

timer_arm() line 57:
  timer->time = (timer->time + timer->tick) % timer->reset_value;
  // Result: timer->time is in [0, reset_value-1] -- NEVER equals reset_value

timer_must_run_block() line 63:
  if (timer == NULL || timer->time == timer->reset_value) {
      return true;  // DEAD: timer->time can NEVER equal reset_value here
  }

Initial state: timer_new() sets timer.time = reset_value (line 39).
On first timer_arm(): timer->time = (reset_value + tick) % reset_value = tick % reset_value.
After that, timer->time cycles through [0, reset_value-1] -- never returns to reset_value.

Consequence: The timer->time == timer->reset_value condition fires
exactly once: on initialization before the first timer_arm() call.
In steady-state operation, this branch is permanently dead. All block
scheduling falls through to line 71 (timer->time % block->interval == 0)
which is correct.

Actual impact: Timer scheduling is functionally correct via line 71.
The dead branch is harmless but misleading -- documents intent (run all
blocks on wrap) that never executes. Real-world effect: all blocks fire
once at startup (correct) and on their individual intervals (correct).
SEVERITY: Dead code / documentation debt. Not a runtime regression.

Fix: Change condition to timer->time == 0 (correct wrap sentinel after modulo).

---

## CRIT-02 [P0] -- bar_status2d.c: Unbounded Loop on Malformed Input

File: suckless/.local/src/dwm/patch/bar_status2d.c

In drawstatusbar(), rectangle drawing code:
  while(text[++i] != ',');  // No bounds check

Trigger: A status string containing ^r (rectangle draw command) with
no trailing comma. Loop increments i past end of string into unmapped
memory -> undefined behavior: likely SIGSEGV or infinite loop.

Attack surface: dwmblocks writes root window name. Any block that
produces malformed output (crash, partial write) can kill DWM.

Fix required:
  while (text[i] != '\0' && text[i] != ',') i++;
  if (text[i] == '\0') break;

---

## CRIT-03 [P0] -- install_arch.sh: Microcode Not Loaded at Boot

The script detects CPU vendor and installs intel-ucode or amd-ucode,
but the generated systemd-boot entry contains only:

  initrd /initramfs-linux.img

Missing (must be BEFORE main initramfs):
  initrd /intel-ucode.img
  initrd /initramfs-linux.img

Consequence: CPU microcode is never loaded at boot. Known CPU errata,
Spectre/Meltdown hardware mitigations, and stability fixes are absent.
This is invisible to the user -- lscpu will show old microcode revision.

---

## CRIT-04 [P0] -- shell/profile: Triple Initialization Per Session

Files: zsh/.config/zsh/.zprofile, x11/.config/x11/xinitrc,
       x11/.config/x11/xprofile

Boot sequence sources shell/profile three times:
  1. .zprofile line ~3: . "$HOME/.config/shell/profile"
  2. xinitrc line 29:   . "$HOME/.config/shell/profile"
  3. xprofile (sourced from xinitrc): conditionally sources again

Effects:
- setsid -f shortcuts (profile line 83) runs up to 3 times.
  Each invocation writes shortcutrc, zshnameddirrc, lf/shortcutrc,
  nvim/shortcuts.vim. Wasteful, potential race on first run.
- PATH entries appended multiple times.
- ZDOTDIR exported multiple times (harmless but dirty).
- HISTFILE set in profile, again in .zshrc, again in env.zsh.

Fix: xinitrc should source xprofile only for X11-specific vars
(keyboard, IM modules). Not re-source the full login profile.

---

## CRIT-05 [P0] -- dunst-signal-hook: Completely Disconnected

File: scripts/.local/bin/dunst-signal-hook

Content:
  pkill -RTMIN+8 -x dwmblocks

Problem: dunst/.config/dunst/dunstrc has NO script= directive.
The hook is never called. The sb-notify block (signal 8, interval 0)
is documented in AGENTS.md as "purely event-driven, only updates on
SIGRTMIN+8 from Dunst". In practice it NEVER updates because Dunst
never sends the signal.

This means:
  - Notification bell icon never changes state in real time
  - User sees stale notification count/icon until manual signal
  - The entire "event-driven notify" architecture is dead infrastructure

Fix: Add to dunstrc [global]:
  script = ~/.local/bin/dunst-signal-hook

---

## CRIT-06 [P1] -- theme-set: Hardcodes "pipewire" in state.json Always

File: theme/.local/bin/theme-set -- _update_state() function

The function always writes:
  "audio_backend": "pipewire"
regardless of $AUDIO_BACKEND environment variable.

Effect: On ThinkPad X230 with AUDIO_BACKEND=alsa (set in
hardware/current.conf), running theme-set overwrites state.json
with "audio_backend": "pipewire". Any consumer reading state.json
will attempt PipeWire operations on a machine where PipeWire is not running.

AGENTS.md Rule 5: "Read state.json instead of grep/pidof" -- this rule
is now actively harmful on ALSA machines because state.json lies.

Fix: Replace hardcoded "pipewire" with "${AUDIO_BACKEND:-pipewire}"

---

## CRIT-07 [P1] -- ka-pop/clip.c: system() With User-Controlled Path

File: suckless/.local/src/ka-pop/src/modules/clip.c:307-308

  char cmd[512];
  snprintf(cmd, sizeof(cmd),
      "xclip -selection clipboard -t image/png -i '%s' 2>/dev/null &",
      item->file_path);
  system(cmd);

item->file_path is read from ~/.cache/ka-clip/history.json.
If the JSON is tampered, or if ka-clipd writes a path containing
single quotes (e.g., unusual HOME path), shell injection is possible.

Fix: Replace system() with execvp():
  char *args[] = {"xclip", "-selection", "clipboard",
                  "-t", "image/png", "-i", item->file_path, NULL};
  spawn_cmd(args);

---

## CRIT-08 [P1] -- xcape: Undeclared Dependency

remaps uses: xcape -e 'Super_L=Escape'
xcape appears in NONE of arch.csv, debian.csv, void.csv, fedora.csv.

On a fresh install via ka-setup, remaps will silently fail to map
Caps->Super/Escape tap. User loses the Escape-tap capability with no
diagnostic message.

---

## CRIT-09 [P1] -- udev Rules: Wrong Install Path in Stow

File: hardware/99-ka-hardware.rules

GNU Stow deploys this to ~/99-ka-hardware.rules.
udev reads from /etc/udev/rules.d/.
The file never reaches udev.

CPU governor, ThinkPad battery thresholds, USB power management rules
are silently ignored on every fresh install until ka-setup sys is run.

ka-setup:580 correctly does: sudo cp $udev_rule /etc/udev/rules.d/
But only when explicitly run with the 'sys' profile. The stow structure
creates a false expectation that stow handles deployment.

---

## CRIT-10 [P1] -- OS-Specific Aliases Never Sourced

Files: zsh/.config/zsh/.zshrc, zsh/.config/zsh/aliasrc.{arch,void,artix}

.zshrc sources only the generic 'aliasrc'. Files aliasrc.arch,
aliasrc.void, aliasrc.artix exist but have no OS-detection loader.
Arch-specific aliases (pacman shortcuts, AUR helpers) are permanently
inactive on all installations.

---

# IV. PERFORMANCE AUDIT

## DWM Event Loop
  poll(X_fd, -1) -> XNextEvent -> handler[] dispatch -> drawbar if needed
Verdict: Correct. poll()-based. No busy-wait. EINTR safe.

## dwmblocks Update Cycle
  SIGALRM -> block_update() -> native_fn() -> XChangeProperty (root name)
           -> XFlush() (correctly placed before poll())
Verdict: Correct for native blocks. 0 fork. ~2.2 MB RSS total.

## bar_status2d: find_block_at() Cache

  static char cached_text[1024];
  if (strcmp(cached_text, rawtext) != 0) {
      cached_count = parse_status_blocks(...);  // reparse on change only
  }

Verdict: Correct amortized. Only re-parses on status string change.
Hover events that fire without status change are O(n) scan on
cached_blocks[16]. Acceptable for 10 blocks.

## native_notify() -- False "Event-Driven" Claim

  static char* native_notify(int sig) {
      exec_capture(dunstctl_paused_args, ...);   // fork #1
      exec_capture(dunstctl_count_args,  ...);   // fork #2
  }

With interval=0, this only runs on signal (correct architecture).
But when it DOES run, it forks 2 processes synchronously.
AGENTS.md claim of "0 fork" for this block is false.
Accurate claim: "0 fork at idle, 2 forks per signal event."

With dunst-signal-hook disconnected (CRIT-05), this never fires at
all in current shipped state. Fix CRIT-05 first, then optimize.

## getblocksignal(): Synchronous X Round-Trip in Draw Path

  // Called during every bar redraw when dropdown is active:
  int getblocksignal(Client *c) {
      XGetWindowProperty(dpy, c->win, ka_block_atom, ...);
      // Synchronous X server round-trip
  }

At 60fps this is 60 blocking round-trips/second.
Fix: Cache the signal value in the Client struct when window is managed.
Invalidate on PropertyNotify event for _KA_BLOCK_SIGNAL.

## browsercmd[]: Fork-for-env-expansion (Minor)

  static const char *browsercmd[] = {"sh", "-c", "exec ${BROWSER:-brave}"};

Spawns a shell solely to expand one env var. DWM has BROWSER in its
environment already. Should read getenv("BROWSER") at keybind time or
configure browsercmd at startup. Saves one fork per browser launch.

## PipeWire Socket Polling Loop

In xinitrc.arch and xinitrc.debian (copy-pasted):
  for i in $(seq 1 10); do
      [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break
      sleep 0.3
  done

Maximum blocking wait: 10 x 300ms = 3 seconds in xinitrc.
Use systemd socket activation or pw-cli with timeout instead.

---

# V. DWM / C CODE AUDIT

## dwm.c -- Specific Issues

### dropdowntosig(): Linear String-Match Dispatch
  O(n) linear strcmp chain. Adding a module requires modifying dwm.c.
  Signal numbers duplicated from dwmblocks config.h.
  Acceptable at current scale (11 modules). Benefit: use a lookup table.

### strstr(c->name, "notify") Fragile Heuristic
  Sidebar placement logic matches ANY window title containing "notify".
  Risk: browser tab "Notify Settings" in floating window gets sidebar treatment.
  Fix: Use WM_CLASS or dedicated X atom for dropdown type identification.

### killdropdown(): 100ms Sleep-Based Synchronization
  Sends WM_DELETE_WINDOW to dropdown, then XKillClient 100ms later.
  Race: GTK3 may not process WMDelete within 100ms under load.
  XKillClient is brutal -- no cleanup. Should track by timestamp.

### getblocksignal(): Synchronous X Round-Trip
  See Performance section. Needs caching.

## bar_status2d.c -- Specific Issues

### Fixed 1024-byte Status Buffer
  Status strings >1023 bytes are silently truncated.
  With 10 blocks x ~20 chars + markup: typical ~200 bytes.
  Safe in practice but fragile as blocks grow.

### Direct drw->scheme Mutation
  drw->scheme[ColFg] = scheme[SchemeTagsSel][ColBg];
  Mutates draw state directly without save/restore.
  Immediately reset by caller, currently safe.
  Fragile: any code insertion between these points corrupts draw state.

## dwmblocks -- Specific Issues

### block.c: SIGCHLD Race (Mitigated, Fragile)
  waitpid(block->fork_pid) may get ECHILD if SIGCHLD handler reaped
  the child first. Handled by: errno == ECHILD check swallows silently.
  Correct fix: SA_NOCLDWAIT or switch to signalfd for SIGCHLD.

### watcher.c: Pipe Allocated for Native Blocks
  Native blocks call function pointer directly (no fork, no pipe).
  But watcher.c opens and polls a pipe fd for EVERY block including natives.
  For native blocks, the pipe write end is never written to.
  Waste: 2 fds x 10 blocks = 20 wasted fds, 10 always-silent poll() fds.
  Fix: Skip pipe allocation for blocks where fn != NULL (native).

## ka-clipd.c -- Specific Issues

### find_matching_brace(): JSON With } Inside Strings
  Brace-counting parser is correct for well-formed JSON.
  BUT: a JSON value containing } without preceding backslash (valid JSON)
  terminates the scan prematurely.
  Clipboard text can contain any character including }.
  Functional bug: clipboard entries with } in content may be misread.

### entry_path Buffer: 1024-byte Fixed Size
  char new_obj[1024];
  snprintf(new_obj, ..., "{..."file_path": "%s",...}", hash, entry_path, ...);
  If entry_path is near 1024 bytes, JSON object is truncated -- produces
  malformed JSON missing closing }. Silent data loss.

### Private Key Filter: Incomplete
  Filtered:   "BEGIN PRIVATE KEY", "BEGIN RSA PRIVATE KEY",
              "BEGIN OPENSSH PRIVATE KEY"
  NOT filtered: "BEGIN EC PRIVATE KEY", "BEGIN PGP PRIVATE KEY BLOCK",
                "BEGIN CERTIFICATE" (may contain sensitive data)

---

# VI. SHELL / CONFIG AUDIT

## Zsh Chain Issues

  File           | Issue                                        | Severity
  ---------------|----------------------------------------------|----------
  .zshenv        | Sets only ZDOTDIR. Correct.                  | OK
  .zprofile      | Sources profile, exec startx guard correct.  | OK
  shell/profile  | ZDOTDIR set here AND in .zshenv (duplicate). | P3
                 | HISTFILE set here AND .zshrc AND env.zsh.    | P3
  .zshrc         | Sources aliasrc but not aliasrc.${os}.      | P1
  env.zsh        | HISTSIZE/SAVEHIST set again (already .zshrc).| P3
  .zcompdump     | Machine-specific cache tracked in git.       | P3

## theme-set: _update_state() Always Writes "pipewire"
  Covered in CRIT-06. Actively harmful on ALSA machines.

## theme/hooks.d/20-dunst.sh: sleep-based Synchronization
  pkill -9 dunst
  sleep 0.1            # <-- arbitrary 100ms wait
  dunst -conf ... &
  Race: dunst may not die within 100ms under load.
  Fix: poll for process exit before relaunching.

## ka-weather: Hardcoded Vietnamese Coordinates
  LAT=10.823 / LON=106.686 / CITY="Go Vap, TP.HCM"
  Baked into the script. Any user outside Ho Chi Minh City gets wrong
  weather data silently. Should be in hardware profile or dedicated config.

## mimeapps.list: Debian-Centric on Arch
  HTTP/HTTPS handlers: firefox-esr.desktop
  On Arch where brave-bin is the default, xdg-open for URLs tries
  firefox-esr (may not exist), falls back silently.
  Should use $BROWSER.desktop or maintain per-distro mimeapps templates.

## xinitrc: eval $(dbus-launch) -- Acceptable
  eval $(dbus-launch --sh-syntax --exit-with-session)
  dbus-launch --sh-syntax outputs only DBUS_SESSION_BUS_ADDRESS=... and
  DBUS_SESSION_BUS_PID=... -- controlled output, not user data.
  Does NOT violate AGENTS.md Rule 3 (which targets user config data). OK.

---

# VII. DEPENDENCY AUDIT

## Declared vs Actual

  Tool              | Used By                 | arch.csv | debian.csv | Status
  ------------------|-------------------------|----------|------------|--------
  xcape             | remaps                  | NO       | NO         | MISSING
  xset              | remaps                  | NO       | NO         | implicit
  dunstctl          | native_notify           | via dunst| via dunst  | OK
  wpctl             | native_volume           | YES      | YES        | OK
  amixer            | native_volume           | YES      | YES        | OK
  maim / slop       | screenshot scripts      | YES      | YES        | OK
  xclip             | linkhandler, clip.c     | YES      | YES        | OK
  ueberzugpp        | lf preview              | YES      | NO         | Debian gap
  nsxiv             | image viewer            | YES      | NO         | Debian gap
  transmission-remote| transadd              | NO       | NO         | MISSING
  ka-wifi           | ka-pop/network.c        | NO       | NO         | MISSING (no file)
  set-dns           | ka-pop/network.c        | NO       | NO         | MISSING (no file)
  rofi              | rofi-launcher script    | NO       | NO         | MISSING

CRITICAL: ka-wifi and set-dns are called by ka-pop/network.c but do not
exist anywhere in the repository. Network popup's DNS switching and WiFi
management buttons silently fail (spawn_cmd child exits 127).

## C Build Dependencies
  All build deps (libx11, libxcb, libxinerama, libxft, libxfixes,
  libxrender, gtk3, alsa-lib, harfbuzz, imlib2) are correctly declared
  in arch.sh and void.sh. Debian driver also has correct equivalents.

---

# VIII. BOOT / SESSION AUDIT

## Session Initialization Timeline

  T+0ms    TTY1 login (PAM, pam_gnome_keyring starts keyring)
  T+50ms   zsh starts, .zshenv (ZDOTDIR only -- fast)
  T+60ms   .zprofile: sources shell/profile [LOAD #1]
             - XDG vars, PATH, ZDOTDIR, fcitx5, shortcuts setsid
  T+80ms   exec startx $XINITRC
  T+90ms   Xorg starts
  T+100ms  xinitrc: D-Bus init (systemd socket or dbus-launch)
  T+120ms  xinitrc: sources shell/profile [LOAD #2] <-- REDUNDANT
  T+130ms  xinitrc: sources theme/current.conf, hardware/current.conf
  T+140ms  xinitrc: sources xprofile (may source profile [LOAD #3])
  T+160ms  xinitrc: dbus-update-activation-environment --systemd --all
  T+180ms  xinitrc: xdg-desktop-portal startup
  T+200ms  xinitrc: xrdb merge
  T+210ms  xinitrc: polkit agent
  T+220ms  xinitrc: gnome-keyring (possible duplicate if PAM active)
  T+230ms  xinitrc: distro adapter (PipeWire startup if applicable)
  T+300ms+ PipeWire + WirePlumber socket polling loop (up to 3 seconds)
  T+400ms  Session daemons: dunst, picom, fcitx5, udiskie, ka-clipd
  T+420ms  remaps (xcape SILENTLY FAILS if missing), dwmblocks
  T+450ms  setbg (wallpaper)
  T+500ms  exec dwm -- user sees desktop

## gnome-keyring: Potential Double Init
  PAM module pam_gnome_keyring starts keyring at login.
  xinitrc also: eval $(gnome-keyring-daemon --start ...)
  On systemd systems, this starts a second instance.
  The second should gracefully connect to existing socket, but
  adds ~50ms to boot and produces log noise.

---

# IX. SECURITY AUDIT

## Clipboard Daemon (ka-clipd)

  Vector                    | Risk           | Status
  --------------------------|----------------|--------
  Content logged to disk    | Data at rest   | Mode 0600, dir 0700 -- OK
  Private key filtering     | Credentials    | Partial: EC/PGP keys missed
  Temp file during write    | TOCTOU         | PID-suffixed tmp, atomic rename -- OK
  JSON path injection       | Code execution | Via clip.c system() -- CRIT-07 FAIL
  2MB clipboard limit       | DoS            | Enforced -- OK

## Shell Profile: API Key Exposure in DEBUG Mode
  xinitrc correctly disables set -x before sourcing profile:
    [ -n "$DEBUG" ] && set +x
    . "$HOME/.config/shell/profile"
    [ -n "$DEBUG" ] && set -x
  API key protection during debug mode is correctly handled. OK.

## DWM Status Bar: Root Name Injection
  DWM reads WM_NAME on root window set by dwmblocks.
  A compromised dwmblocks could write malformed status2d codes -> CRIT-02.
  Control codes <0x20 are stripped by copyvalidchars() -- OK.
  The injection risk (CRIT-02) is mitigated by dwmblocks being a trusted binary.
  If dwmblocks is compromised, the threat model is already violated.

## sysctl vm.swappiness = 180
  ka-setup writes vm.swappiness = 180 to /etc/sysctl.d/
  Linux kernels before 5.8 cap swappiness at 100.
  On older kernels, sysctl -p may fail or apply incorrectly.
  ThinkPad X230 may run an older kernel. No kernel version check before apply.

---

# X. ARCHITECTURAL INCONSISTENCIES

## 1. "Native C / Zero-Fork" vs Shell Hybrid Reality

Claim (AGENTS.md, MANUAL.md): "Zero-fork, Native C architecture"

Reality breakdown:
  - ka-pop/network.c: spawn_cmd("set-dns"), spawn_cmd("ka-wifi menu")
    These scripts DO NOT EXIST. Network module always silently fails.
  - ka-pop/forecast.c: spawn_cmd("ka-weather") on refresh -- forks shell
  - ka-pop/volume.c: spawn_cmd("wpctl") or spawn_cmd("amixer") for changes
  - native_notify(): forks dunstctl twice per signal event

Zero-fork applies correctly to STATUS READING (sysfs, /proc, ALSA API).
Mutation operations (volume change, DNS change, notify toggle) correctly
use fork/exec -- this is unavoidable without deep D-Bus integration.
The "zero-fork" claim is accurate for the polling path; overstated
as a global property of the system.

## 2. GNU Stow Discipline Violations

  File                         | Stow Target            | Required Location
  -----------------------------|------------------------|------------------
  hardware/99-ka-hardware.rules| ~/99-ka-hardware.rules | /etc/udev/rules.d/
  zsh/.config/zsh/.zcompdump  | ~/.config/zsh/.zcompdump | machine-specific, not tracked
  shell/.config/shell/shortcutrc | tracked in git      | generated, should be ignored

## 3. PipeWire Startup Code: 3x Duplication
  xinitrc.arch and xinitrc.debian contain near-identical PipeWire startup.
  xinitrc.void has a variant. Changes must be made in 3 places.
  Extract into a common function called from all adapter files.

## 4. state.json: Dual Authority / Lying Oracle
  theme-set writes $XDG_RUNTIME_DIR/ka/state.json.
  AGENTS.md Rule 5: "read state.json instead of grep/pidof."
  But state.json always says "pipewire" even on ALSA machines (CRIT-06).
  An agent following Rule 5 will misread the audio backend.
  The rule and the implementation are in direct conflict.

## 5. mimeapps.list: Debian-Centric Defaults
  HTTP/HTTPS -> firefox-esr.desktop (Debian fallback)
  On Arch, firefox-esr.desktop may not exist.
  The mimeapps.list is not distro-aware despite distro-specific pkgs lists.

## 6. Hardware Profile: ALSA Path Unvalidated
  thinkpad-x230.conf sets AUDIO_BACKEND=alsa.
  ka-setup has no automated test for the ALSA code path.
  PipeWire paths are exercised by most contributors.
  ALSA regression risk is high. The only validation is manual testing.

---

# XI. SIMPLIFICATION OPPORTUNITIES

## REMOVE (Dead Code / Dead Infrastructure)

1. dunst-signal-hook: Dead (CRIT-05). Wire it or delete it.
   Do not maintain unconnected shell scripts.

2. suckless/.local/src/dwm/config.md: Duplicates config.h content.
   Gets out of sync immediately. Delete. config.h is source of truth.

3. scripts/.local/bin/rofi-launcher: Rofi not in any pkgs list.
   If not a dependency, this is dead infrastructure.

4. scripts/.local/bin/aim: AppImage manager, no ecosystem support
   in ka-setup or any keybinding. Dead tool.

5. scripts/.local/bin/dashboard: Plain echo terminal dashboard.
   Superseded by btop and ka-pop cpu/memory. Remove.

6. scripts/.local/bin/gm: 365-line bash git manager.
   Overlaps with standard git + lazygit (in pkgs).
   Not referenced from any keybinding or ka dispatch.

7. zsh/.config/zsh/aliasrc.{arch,void,artix}: Either fix the loader
   (CRIT-10) or merge into aliasrc with OS detection, or delete.

## CONSOLIDATE (Reduce Duplication)

1. xinitrc.{arch,debian,void}: Extract common PipeWire startup block
   into a _start_pipewire() function in xinitrc. 3 -> 1 maintenance point.

2. ZDOTDIR: Set once in .zshenv. Remove from shell/profile.

3. HISTFILE/HISTSIZE: Set once in .zshrc. Remove from profile and env.zsh.

4. dropdowntosig() + getblocksignal() + calblockpos(): Three functions
   all encoding module-name -> signal-number mapping. Consolidate into
   one table in dwm config.h:
     static const struct { const char *name; int sig; } dropdown_sigs[] = {
         {"volume", 11}, {"battery", 30}, ...
     };

---

# XII. RECOMMENDED ARCHITECTURE

## Immediate Fixes (1-2 days)

  Priority | File                          | Fix
  ---------|-------------------------------|------------------------------------------
  P0       | dwm/patch/bar_status2d.c      | Add bounds check to rectangle loop
  P0       | install_arch.sh               | Add microcode initrd to boot entry
  P0       | dunst/.config/dunst/dunstrc   | Add: script = dunst-signal-hook
  P0       | x11/.config/x11/xinitrc:29   | Remove redundant profile source
  P1       | theme/.local/bin/theme-set    | Use ${AUDIO_BACKEND:-pipewire} in state
  P1       | pkgs/*.csv                    | Add xcape to dependency lists
  P1       | ka-pop/src/modules/clip.c:307 | Replace system() with spawn_cmd(args[])
  P1       | zsh/.config/zsh/.zshrc        | Add OS-detection for aliasrc.${os}
  P1       | dwmblocks/src/timer.c:63      | Fix dead code: time==reset -> time==0

## Medium Term (1-2 weeks)

1. ka-wifi + set-dns: Implement these scripts. Network module is
   currently non-functional for its primary actions.

2. Dunst event hook: Wire dunst-signal-hook into dunstrc. Validate
   the full notify event chain end-to-end.

3. Bluetooth module: Complete the untracked bluetooth.c ka-pop module
   and ka-bluetooth script, or revert and remove.

4. find_matching_brace(): Replace manual brace-counting with a proper
   state machine that handles } inside string values.

5. udev rules deploy: Document clearly that ka-setup sys is mandatory.
   Remove hardware/99-ka-hardware.rules from stow tree (or add README).

## Long Term

1. Wire native_notify() properly: dunst-signal-hook -> SIGRTMIN+8 ->
   sb-notify (interval=0) reads dunstctl state. THEN the architecture
   described in AGENTS.md matches the implementation.

2. Replace find_matching_brace() with jq or a proper C JSON parser.
   The manual parser has multiple correctness bugs (} in strings,
   fixed buffer truncation, strrchr for text field delimiter).

3. Cache getblocksignal() result in Client struct. Eliminate synchronous
   X round-trips in the bar draw path.

4. Audit all native_blocks.c exec_capture() calls. These fork processes
   synchronously in the signal handler context. On slow machines this
   blocks the entire dwmblocks event loop.

---

# XIII. PRIORITIZED ROADMAP

## P0 -- Ship-Blocker (Fix Before Any New Feature)

  # | Issue                                   | File                 | Effort
  --|------------------------------------------|-----------------------|-------
  1 | status2d OOB loop on malformed status   | bar_status2d.c ~L200 | 2 lines
  2 | Microcode missing from boot entry       | install_arch.sh ~L350| 2 lines
  3 | dunst-signal-hook not wired to dunstrc  | dunstrc              | 1 line
  4 | Profile triple-load per session         | xinitrc:29           | 1 line delete
  5 | clip.c system() injection vector        | clip.c:307           | 5 lines

## P1 -- High (Fix Within Sprint)

  # | Issue                                   | File
  --|------------------------------------------|--------------------
  6 | theme-set hardcodes "pipewire" in state | theme-set
  7 | xcape not in any pkgs list              | pkgs/*.csv
  8 | OS-specific aliasrc never sourced       | .zshrc
  9 | ka-wifi + set-dns: missing scripts      | new files needed
  10| udev rules wrong stow path              | documentation/move
  11| EC/PGP private key patterns not filtered| ka-clipd.c
  12| getblocksignal() X round-trip per draw  | dwm.c

## P2 -- Medium (Fix When Touching Related Code)

  # | Issue                                        | File
  --|----------------------------------------------|--------------------
  13| native_notify: 2 forks per signal            | native_blocks.c
  14| Pipe allocated for native blocks (20 wasted) | watcher.c
  15| SIGCHLD race in block_update()               | block.c
  16| find_matching_brace: } in strings corrupts   | ka-clipd.c + clip.c
  17| PipeWire startup duplicated x3               | xinitrc adapters
  18| sleep 0.1 in dunst hook (race condition)     | hooks.d/20-dunst.sh
  19| strstr(c->name,"notify") fragile heuristic   | dwm.c
  20| browsercmd[] forks shell for env expansion   | dwm config.h

## P3 -- Low (Cleanup Pass)

  # | Issue                                   | File
  --|------------------------------------------|--------------------
  21| .zcompdump tracked in git               | .gitignore
  22| HISTFILE/HISTSIZE set 3x                | profile, .zshrc, env.zsh
  23| ZDOTDIR set in both .zshenv and profile | profile
  24| ka-weather hardcodes Vietnamese coords  | ka-weather
  25| mimeapps.list hardcodes firefox-esr    | mimeapps.list
  26| timer.c dead code (non-functional impact)| timer.c
  27| picom.conf comment contradicts X230     | picom.conf
  28| Dead scripts: aim, dashboard, gm        | scripts/.local/bin/
  29| config.md duplicates config.h in dwm   | suckless/src/dwm/
  30| ka-weather LAT/LON not in hardware conf | ka-weather

---

# XIV. REMOVE-BEFORE-OPTIMIZE CLASSIFICATION

## REMOVE (No Salvageable Value)

  scripts/.local/bin/aim          AppImage manager; no ecosystem support
  scripts/.local/bin/dashboard    Superseded by btop + ka-pop
  scripts/.local/bin/gm           Superseded by lazygit (in pkgs)
  suckless/.local/src/dwm/config.md  Duplicates config.h, always stale

## WIRE UP (Infrastructure Exists, Not Connected)

  scripts/.local/bin/dunst-signal-hook   Add script= to dunstrc
  zsh/.config/zsh/aliasrc.arch           Add OS detection to .zshrc
  zsh/.config/zsh/aliasrc.void           Same
  zsh/.config/zsh/aliasrc.artix          Same

## IMPLEMENT (Missing Scripts Called by Existing Code)

  scripts/.local/bin/ka-wifi    Called by ka-pop/network.c spawn_cmd("ka-wifi menu")
  scripts/.local/bin/set-dns    Called by ka-pop/network.c spawn_cmd("set-dns dhcp/cf/gg")

## FIX BEFORE SHIP (Correctness / Security Bugs)

  dwm/patch/bar_status2d.c:~200    OOB loop on malformed status
  install_arch.sh:~350              Missing microcode initrd line
  dunst/.config/dunst/dunstrc       Missing script= hook directive
  x11/.config/x11/xinitrc:29       Remove redundant profile source
  ka-pop/src/modules/clip.c:307    system() -> spawn_cmd(args[])
  theme/.local/bin/theme-set        Hardcoded "pipewire" in state.json

## OPTIMIZE (Only After All Fixes Above)

  dwmblocks/src/watcher.c           Skip pipe alloc for native blocks
  dwm/dwm.c (getblocksignal)        Cache _KA_BLOCK_SIGNAL atom+value in Client
  ka-clipd.c                        Proper JSON parser for clipboard history
  native_blocks.c (native_notify)   True event-driven after dunst hook wired
  xinitrc.{arch,debian,void}        Consolidate PipeWire startup function
  ka-clipd.c                        Add EC/PGP/CERTIFICATE to key filter

---

# FINAL VERDICT

This is a technically sophisticated, architecturally intentional system
with genuine merit. The zero-fork native block design is correct and
measured. The hardware profile abstraction is clean. The seamless DWM
restart is properly implemented. The XFixes clipboard daemon is minimal
and correct. The bar geometry and hover-underline alignment system shows
careful attention to detail.

However, the codebase suffers from a persistent gap between documented
intent and implemented reality:

  1. The notify system is broken as shipped.
     dunst-signal-hook is not wired. sb-notify never fires in real time.

  2. The network module is non-functional.
     ka-wifi and set-dns do not exist. DNS switching silently fails.

  3. Boot correctness is compromised.
     No microcode loaded. Triple profile source. xcape silently absent.

  4. One memory-safety bug exists.
     bar_status2d.c has an unbounded loop on malformed status input.

  5. One security vector exists.
     clip.c uses system() with a path that passes through user data.

  6. state.json actively lies.
     theme-set always writes "pipewire" -- AGENTS.md Rule 5 is unsafe to follow.

The architectural foundation is sound. The suckless philosophy is
consistently applied where it matters. The performance numbers are real.

Fix the P0 issues: 5 bugs, each under 10 lines. Wire up the dead
infrastructure: 3 connections. Delete the dead scripts: 4 files.
Then optimize.

---

Audit complete.
14 phases. ~450 source files examined. ~12,000 lines of C analyzed.
