#!/usr/bin/env bash
# ~/.config/waybar/scripts/media.sh
# Outputs JSON for Waybar. Provides a character-scrolling marquee when title is long.
# Configurable knobs below.

MAX_CHARS=38        # max visible characters before scrolling
STEP_SECONDS=1      # how often to advance by one character (seconds) — use same as Waybar interval for best sync
PADDING="   "       # gap inserted between end and beginning when scrolling
ELLIPSIS="…"        # show if you prefer an ellipsis when truncated static
PLAY_ICON="⏵"
PAUSE_ICON="⏸"
STOP_ICON="■"

# get primary player (first line)
player=$(playerctl -l 2>/dev/null | head -n1 || true)
status=$(playerctl -p "$player" status 2>/dev/null || echo "")
artist=$(playerctl -p "$player" metadata artist 2>/dev/null || true)
title=$(playerctl -p "$player" metadata title 2>/dev/null || true)
album=$(playerctl -p "$player" metadata album 2>/dev/null || true)

# build display text
if [[ -n "$artist" && -n "$title" ]]; then
  base_text="$artist - $title"
elif [[ -n "$title" ]]; then
  base_text="$title"
else
  base_text=""
fi

# set class for styling (optional)
cls="media"
if [[ "$player" == *spotify* ]]; then cls="spotify"; fi
if [[ "$player" == *vlc* ]]; then cls="vlc"; fi

# set icon
icon="$PLAY_ICON"
if [[ "$status" == "Paused" ]]; then icon="$PAUSE_ICON"; fi
if [[ "$status" == "Stopped" || -z "$player" ]]; then icon="$STOP_ICON"; fi

# if no player or no text, print nothing (or a small icon)
if [[ -z "$player" || -z "$base_text" ]]; then
  # If you prefer to hide when no player: echo '{"text": ""}' and exit 0
  echo "{\"text\":\"\",\"class\":\"$cls\",\"tooltip\":\"No player\"}"
  exit 0
fi

# prepare scrolling text by adding padding so it loops nicely
scroll_source="${base_text}${PADDING}"

# get scrolling state index based on epoch so it persists across restarts
# compute total length we can scroll through
len=${#scroll_source}
if (( len <= MAX_CHARS )); then
  # fits — no scrolling; show icon + text maybe trimmed safely
  display="$icon $scroll_source"
else
  # step based on epoch seconds divided by STEP_SECONDS
  epoch=$(date +%s)
  step=$(( epoch / STEP_SECONDS ))
  # position cycles through [0 .. len-1]
  pos=$(( step % len ))
  # build substring of length MAX_CHARS from pos (wrap-around)
  # create doubled buffer to easily take substring across boundary
  buf="${scroll_source}${scroll_source}"
  # take substring
  display_text="${buf:pos:MAX_CHARS}"
  # if we sliced whitespace at edges, trim ends
  # prefix icon
  display="$icon $display_text"
fi

# escape JSON-safe (escape backslash and double quote)
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;s/\n/\\n/;ta'; }

json_text=$(esc "$display")
tooltip_text=$(esc "${artist:+$artist - }${title:+$title}${album:+ — $album}")

# print JSON (Waybar expects valid JSON when return-type=json)
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$json_text" "$cls" "$tooltip_text"
