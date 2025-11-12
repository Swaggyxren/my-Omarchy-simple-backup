#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.config/omarchy/current/theme"
WB_CSS="$THEME_DIR/waybar.css"
OUT_IN_THEME="$THEME_DIR/fuzzel.ini"
OUT_IN_USER="$HOME/.config/fuzzel/fuzzel.ini"

FONT="CaskaydiaMono Nerd Font 9"
DEFAULT_LINES=6
INNER_PAD=0
RADIUS=10

hex() { grep -Po "@define-color\s+$1\s+\K#[0-9A-Fa-f]{6,8}" "$WB_CSS" 2>/dev/null | head -n1 || true; }

FG=$(hex foreground);  [ -z "$FG" ] && FG="#ffffff"
BG=$(hex background);  [ -z "$BG" ] && BG="#000000"
AC=$(hex accent);      [ -z "$AC" ] && AC="$FG"

to_8() { local c="${1#\#}"; if [ ${#c} -eq 6 ]; then printf "%sff" "$c"; else printf "%s" "$c"; fi; }
BGAA="$(to_8 "$BG")"
FGAA="$(to_8 "$FG")"
ACAA="$(to_8 "$AC")"

mkdir -p "$HOME/.config/fuzzel"
OUT_TMP=$(mktemp)

cat > "$OUT_TMP" <<INI
[main]
font = ${FONT}
lines = ${DEFAULT_LINES}
prompt = Windows
inner-pad = ${INNER_PAD}
width = 36
icon-theme = Papirus

[colors]
background = ${BGAA}
text = ${FGAA}
selection = ${BGAA%??}ee
selection-text = ${FGAA}
border = ${ACAA}

[border]
width = 1
radius = ${RADIUS}
INI

mv "$OUT_TMP" "$OUT_IN_THEME"
ln -sf "$OUT_IN_THEME" "$OUT_IN_USER"

echo "Updated: $OUT_IN_THEME -> $OUT_IN_USER"
