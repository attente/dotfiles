#!/bin/sh

percent_from_decimal() {
  raw=${1:-0}

  case "$raw" in
    *.*)
      whole=${raw%%.*}
      frac=${raw#*.}
      frac=${frac}00
      tens=${frac%"${frac#?}"}
      rest=${frac#?}
      ones=${rest%"${rest#?}"}
      printf '%s' "$((whole * 100 + tens * 10 + ones))"
      ;;
    *)
      printf '%s' "$((raw * 100))"
      ;;
  esac
}

state_for() {
  line=$(wpctl get-volume "$1" 2>/dev/null || printf 'Volume: 0')
  raw=${line#Volume: }
  raw=${raw%% *}

  muted=false
  case "$line" in
    *"[MUTED]"*) muted=true ;;
  esac

  printf '%s:%s' "$muted" "$(percent_from_decimal "$raw")"
}

volume() {
  SINK_STATE=$(state_for @DEFAULT_AUDIO_SINK@)
  SOURCE_STATE=$(state_for @DEFAULT_AUDIO_SOURCE@)

  SINK_MUTED=${SINK_STATE%%:*}
  SINK_VOLUME=${SINK_STATE#*:}
  SOURCE_MUTED=${SOURCE_STATE%%:*}
  SOURCE_VOLUME=${SOURCE_STATE#*:}

  printf '{"sink":{"muted":%s,"volume":%s},"source":{"muted":%s,"volume":%s}}\n' \
    "$SINK_MUTED" "$SINK_VOLUME" "$SOURCE_MUTED" "$SOURCE_VOLUME"
}

VOLUME=$(volume)
printf '%s\n' "$VOLUME"

pw-mon -N -p |
  awk '
    /Audio\/(Sink|Source)|default\.audio\.(sink|source)|channelVolumes|mute/ {
      interesting = 1
    }

    /^$/ {
      if (interesting) {
        print "refresh"
        fflush()
      }
      interesting = 0
    }
  ' |
  while read -r _; do
    NEW_VOLUME=$(volume)
    if [ "$NEW_VOLUME" != "$VOLUME" ]; then
      VOLUME=$NEW_VOLUME
      printf '%s\n' "$VOLUME"
    fi
  done
