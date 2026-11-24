#!/data/data/com.termux/files/usr/bin/bash
# Sets up the i3 desktop on a fresh Termux install.
#
#   git clone <this repo> ~/.config/i3 && ~/.config/i3/install.sh [layout]
#
#   layout   X keyboard layout for the session (default: ch). Stored in
#            local.conf, which isn't tracked by git.
#
# Safe to run again: installed packages, the font and correct symlinks are
# left alone; files that would be replaced by a symlink are backed up first.
#
# Not done here (Android side, see README.md):
#   - install the Termux:X11 and Termux:API apps (same source as Termux)
#   - Termux:X11 settings: capture external keyboard + Meta key, scaled resolution

set -euo pipefail

LAYOUT=${1:-ch}
I3="$HOME/.config/i3"
FONT_DIR="$HOME/.local/share/fonts/NotoSansNerd"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Noto.tar.xz"
FONT_FILES=(Regular Light Medium SemiBold Bold Italic)

PACKAGES=(
  # X server, GPU (Turnip/zink for Adreno), sound, session
  termux-x11-nightly mesa-vulkan-icd-freedreno mesa-demos pulseaudio dbus
  # desktop
  i3 picom polybar rofi dunst libnotify
  # terminals, apps
  kitty xfce4-terminal fish firefox yazi htop
  # helpers used by the scripts
  xclip maim xdotool xorg-setxkbmap xorg-xsetroot xorg-xrandr jq termux-api
  # fonts / icons
  fontconfig-utils ttf-jetbrains-mono-nerd papirus-icon-theme
  # font download
  curl tar xz-utils
)

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

[[ -n ${PREFIX:-} && -d $PREFIX ]] || { warn "Run this inside Termux."; exit 1; }

# ── Repo location ─────────────────────────────────────────────────────────
# Every path in the config points at ~/.config/i3.
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
if [[ $repo != "$(cd "$I3" 2>/dev/null && pwd -P)" ]]; then
  if [[ -e $I3 || -L $I3 ]]; then
    warn "$I3 exists and isn't this repo ($repo). Move one of them and run again."
    exit 1
  fi
  say "Linking $I3 -> $repo"
  mkdir -p "$HOME/.config"
  ln -s "$repo" "$I3"
fi

# ── Packages ──────────────────────────────────────────────────────────────
apt_opts=(-y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef)
export DEBIAN_FRONTEND=noninteractive

if ! dpkg -s x11-repo >/dev/null 2>&1; then
  say "Enabling x11-repo"
  pkg update "${apt_opts[@]}"
  pkg install "${apt_opts[@]}" x11-repo
fi
say "Updating package lists"
pkg update "${apt_opts[@]}"

missing=()
for p in "${PACKAGES[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]})); then
  say "Installing: ${missing[*]}"
  pkg install "${apt_opts[@]}" "${missing[@]}"
else
  say "All packages already installed"
fi

# ── Font: NotoSans Nerd Font (not packaged in Termux) ─────────────────────
if [[ -f $FONT_DIR/NotoSansNerdFont-Regular.ttf ]]; then
  say "NotoSans Nerd Font already installed"
else
  say "Downloading NotoSans Nerd Font"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fL --progress-bar --retry 3 -o "$tmp/Noto.tar.xz" "$FONT_URL"
  mkdir -p "$FONT_DIR"
  members=()
  for w in "${FONT_FILES[@]}"; do members+=("NotoSansNerdFont-$w.ttf"); done
  tar -xJf "$tmp/Noto.tar.xz" -C "$FONT_DIR" "${members[@]}"
  rm -rf "$tmp"
  trap - EXIT
fi
say "Refreshing font cache"
fc-cache -f >/dev/null

# ── Symlinks ──────────────────────────────────────────────────────────────
# link TARGET LINK: back up whatever is in the way, then symlink.
link() {
  local target=$1 link=$2
  if [[ -L $link && $(readlink "$link") == "$target" ]]; then
    return
  fi
  if [[ -e $link || -L $link ]]; then
    local backup="$link.bak.$(date +%Y%m%d-%H%M%S)"
    warn "Backing up $link -> $backup"
    mv "$link" "$backup"
  fi
  mkdir -p "$(dirname "$link")"
  ln -s "$target" "$link"
  say "Linked $link"
}

link "$I3/kitty" "$HOME/.config/kitty"
link "$I3/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
link "$I3/xfce4-terminal/terminalrc" "$HOME/.config/xfce4/terminal/terminalrc"
link "$I3/scripts/start-desktop.sh" "$HOME/start-desktop.sh"

chmod +x "$I3"/scripts/*.sh "$I3"/polybar/*.sh "$I3/install.sh"

# ── Device-specific config ────────────────────────────────────────────────
say "Keyboard layout: $LAYOUT (in $I3/local.conf)"
cat >"$I3/local.conf" <<EOF
# Written by install.sh, not tracked in git. Device-specific i3 settings.
exec --no-startup-id setxkbmap $LAYOUT
EOF

# ── Checks ────────────────────────────────────────────────────────────────
i3 -C -c "$I3/config" >/dev/null || { warn "i3 config check failed"; exit 1; }

gpu=$(getprop ro.hardware.vulkan 2>/dev/null || true)
if [[ $gpu == adreno* ]]; then
  say "GPU: Adreno, start-desktop.sh will use Turnip + zink"
else
  warn "GPU: '${gpu:-unknown}', not Adreno: apps will render in software (llvmpipe)"
fi

termux-battery-status >/dev/null 2>&1 &
bat_pid=$!
sleep 5
if kill -0 "$bat_pid" 2>/dev/null; then
  kill "$bat_pid" 2>/dev/null
  warn "termux-battery-status hangs: install the Termux:API app for the battery module"
fi

cat <<EOF

Done. Start the desktop with:  ~/start-desktop.sh
Stop it with Super+Shift+E.

On the Android side (once):
  - Termux:X11 and Termux:API apps, from the same source as Termux
  - Termux:X11 settings: capture external keyboard + Meta key,
    resolution mode "scaled" or custom (e.g. 1920x1200)
EOF
