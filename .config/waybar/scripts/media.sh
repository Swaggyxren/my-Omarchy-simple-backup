#!/usr/bin/env bash
# Theme-blended media info for Waybar
# - Prefixes a play/pause icon (no CSS pseudo-elements needed)
# - Marquee scroll implemented here (no GTK animations)
# - Uses only neutral/themed colors (no per-app overrides)

set -euo pipefail

cache="/tmp/waybar_media_cache"  # stores last full text + offset for marquee
width=30                         # visible width for scrolling window
sep=" • "                        # separator used when looping text

# pick first available player
player=$(playerctl -l 2>/dev/null | head -n1 || true)
if [ -z "${player:-}" ]; then
  echo '{"text": "", "class": "none"}'
  exit 0
fi

status=$(playerctl --player="$player" status 2>/dev/null || echo "")
artist=$(playerctl --player="$player" metadata artist 2>/dev/null || echo "")
title=$(playerctl --player="$player" metadata title 2>/dev/null || echo "")

# build base title
if [ -n "$artist" ] && [ -n "$title" ]; then
  base="$artist — $title"
elif [ -n "$title" ]; then
  base="$title"
else
  base="$status"
fi

# icon from state (use Nerd Font glyphs)
if [ "$status" = "Playing" ]; then
  icon=""  # pause
  state="playing"
elif [ "$status" = "Paused" ]; then
  icon=""  # play
  state="paused"
else
  icon=""  # default to play
  state="stopped"
fi

# marquee: show a sliding window if text is long
full="$base"
display="$base"
offset=0

# read previous cache (format: first line = last text, second line = last offset int)
if [ -f "$cache" ]; then
  last_text=$(sed -n '1p' "$cache" 2>/dev/null || echo "")
  last_off=$(sed -n '2p' "$cache" 2>/dev/null || echo "0")
else
  last_text=""
  last_off="0"
fi

# advance offset only if text hasn't changed and is long
if [ ${#full} -gt $width ]; then
  if [ "$full" = "$last_text" ]; then
    offset=$(( ( ${last_off:-0} + 1 ) ))
  else
    offset=0
  fi

  # create a doubled string with a separator so it wraps nicely
  loop="$full$sep$full$sep"
  # keep offset in bounds
  loop_len=${#loop}
  if [ $offset -ge $loop_len ]; then
    offset=$(( offset % loop_len ))
  fi
  display="${loop:$offset:$width}"
else
  display="$full"
  offset=0
fi

# write cache
{
  printf '%s\n' "$full"
  printf '%s\n' "$offset"
} > "$cache"

# JSON-escape
escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

text_out="$(escape "$icon $display")"

printf '{"text":"%s","alt":"%s","class":"media %s%s"}\n' \
  "$text_out" "$(escape "$status")" "$state" ""
