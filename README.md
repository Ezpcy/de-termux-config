# i3 on Termux:X11

The Hyprland setup from `~/.config/hypr`, ported to i3 for Termux:X11 on the S25+.
It keeps the same look (black, 1px teal border, no gaps, no animations, blur only behind the launcher, NotoSans Nerd Font) and the same keybinds, as far as X11 and Android allow.

```
~/start-desktop.sh            start (symlink to scripts/start-desktop.sh)
Super+Shift+E                 stop  (scripts/stop-desktop.sh)
```

## Setup on a new device

```bash
pkg install git
git clone <this repo> ~/.config/i3
~/.config/i3/install.sh ch        # argument = keyboard layout, default ch
~/start-desktop.sh
```

`install.sh` enables x11-repo and installs every package. It also downloads NotoSans Nerd Font (not packaged in Termux) into `~/.local/share/fonts`, creates the symlinks (backing up anything already in the way), and writes `local.conf` with the keyboard layout (not tracked in git). It finishes with checks for the i3 config, the GPU and Termux:API. You can run it again at any time: whatever is already in place is skipped.

The script can't do the Android side; do these once by hand:
- Install the **Termux:X11** and **Termux:API** apps from the same source as Termux.
- Termux:X11 settings: see the section at the end.

GPU acceleration (Turnip + zink) only works on Qualcomm Adreno. `start-desktop.sh` checks `getprop ro.hardware.vulkan` and on other GPUs leaves Mesa on llvmpipe (software rendering).

## Layout

| path | what | Hyprland counterpart |
|---|---|---|
| `install.sh` | setup on a new device | – |
| `config` | i3 config | `hyprland.lua`, `custom/keybinds.lua` |
| `picom.conf`, `scripts/picom.sh` | compositor: corners, shadow, launcher blur | `decoration {}` |
| `polybar/` | bar: workspaces, clock, volume, memory, battery | waybar |
| `rofi/` | launcher | vicinae |
| `dunst/dunstrc` | notifications | mako |
| `kitty/kitty.conf` | terminal theme | kitty |
| `xfce4-terminal/terminalrc` | fallback terminal theme | – |
| `scripts/` | start/stop, volume, layout cycle, screenshots, terminal wrapper | `scripts/` |

Symlinks into this repo (created by `install.sh`): `~/.config/kitty`,
`~/.config/dunst/dunstrc`, `~/.config/xfce4/terminal/terminalrc`, `~/start-desktop.sh`.
`local.conf` holds the device-specific settings and isn't tracked in git.

## Palette

| token | value | token | value |
|---|---|---|---|
| bg | `#000000` | accent | `#29a99e` |
| bg_weak | `#0f0f0f` | border | `#238f86` |
| card | `#202124` | text | `#ebedf0` |
| primary_hi | `#155852` | muted | `#8b8e94` |
| danger | `#f7768e` | warn | `#e0af68` |

## Keybinds

| keys | action |
|---|---|
| Super (tap) / Super+R | launcher (rofi) |
| Super+Shift+T / Super+Return | terminal (kitty) |
| Super+B / Super+Shift+B | Firefox / blank window |
| Super+E | yazi |
| Super+Ctrl+Esc | htop |
| Super+Q | close window |
| Super+D | click a window to kill it |
| Super+F | toggle floating |
| Super+M | fullscreen |
| Super+S | toggle split direction |
| Super+A | cycle layout: split → tabbed → stacking |
| Super+T | toggle tabbed (Hypr groups) |
| Super+Ctrl+←/→ | previous/next window in a tab group |
| Super+H/J/K/L (or arrows) | focus |
| Super+Shift+H/J/K/L | move window |
| Super+Ctrl+H/J/K/L | resize by 40px |
| Super+1…0 | workspace |
| Super+Shift+1…0 | move window to workspace, stay here |
| Super+Ctrl+Shift+1…0 | move window to workspace and follow it |
| Super+X / Super+Shift+X | show scratchpad / move window to it |
| Super+Tab / Super+Shift+Tab | next / previous window |
| Super+scroll | next / previous workspace |
| Super+Space | toggle the bar |
| Super+Shift+S | screenshot of a region → clipboard + `~/Pictures/Screenshots` |
| Super+Print / Super+Shift+Print | screenshot of the window / whole screen |
| volume keys | volume with a progress toast |
| Super+Shift+R / Super+Shift+C | restart / reload i3 |
| Super+Drag LMB / RMB | move / resize a floating window |

Left out because X11/Termux has nothing equivalent: hyprlock/hypridle, brightness keys, zoom, OCR, screen recording, hyprpicker, clipse, emoji picker, gestures, plugins, monitor rules.

## Termux / Android quirks (found while testing)

- **GPU:** Turnip runs the Adreno 830 through zink (OpenGL 4.6). The X server has no swapchain zink can use, so without `MESA_VK_WSI_DEBUG=sw` GL windows like kitty stay black. `start-desktop.sh` sets it. Check with `glxinfo -B | grep renderer`.
- **picom** uses the **xrender** backend. The GL backend aborts on an assertion after the same swapchain error, and with `MESA_VK_WSI_DEBUG=sw` it draws a black screen. Since `dual_kawase` needs GL, the launcher blur uses `gaussian`. To try GL anyway: `PICOM_BACKEND=glx scripts/picom.sh`.
- `start-desktop.sh` always clears out the previous session first, including one that died without being stopped (app closed, X server killed by Android). Leftover processes hang on the dead X connection and ignore SIGTERM, so they get SIGKILL. PulseAudio is started without `DISPLAY`, because its D-Bus autolaunch against a dead `:0` hung forever and blocked every start after the first. If the X server doesn't come up, the script prints the tail of `$TMPDIR/termux-x11.log`.
- Android blocks `/proc/stat` for apps, so the bar has no CPU module and btop won't run (it needs root). htop works.
- The battery reading comes from `termux-battery-status`, which needs the Termux:API app; `/sys/class/power_supply` isn't readable.
- Termux:X11 only shares text with the Android clipboard, so screenshots are also saved to `~/Pictures/Screenshots`.
- i3 doesn't expand a `$var` inside another `set` value, so paths in `config` are written out in full.

## Termux:X11 app settings

- Keyboard: enable capturing the external keyboard and the Meta/Super key, or Android grabs Super.
- Output: use a scaled or custom resolution (e.g. 1920×1200) rather than native.
