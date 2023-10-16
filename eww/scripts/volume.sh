#!/bin/sh

volume() {
  SINK_MUTED=$(pactl get-sink-mute @DEFAULT_SINK@)
  if [ "$SINK_MUTED" = 'Mute: yes' ]; then
    SINK_MUTED=true
  else
    SINK_MUTED=false
  fi

  SOURCE_MUTED=$(pactl get-source-mute @DEFAULT_SOURCE@)
  if [ "$SOURCE_MUTED" = 'Mute: yes' ]; then
    SOURCE_MUTED=true
  else
    SOURCE_MUTED=false
  fi

  SINK_VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | rg --color never '^Volume:' | awk '{print $5}' | awk -F % '{print $1}')

  SOURCE_VOLUME=$(pactl get-source-volume @DEFAULT_SOURCE@ | rg --color never '^Volume:' | awk '{print $5}' | awk -F % '{print $1}')

  echo "{\"sink\":{\"muted\":$SINK_MUTED,\"volume\":$SINK_VOLUME},\"source\":{\"muted\":$SOURCE_MUTED,\"volume\":$SOURCE_VOLUME}}"
}

VOLUME=$(volume)
echo "$VOLUME"

pactl subscribe | rg --line-buffered --color never "^Event 'change' on (sink|source) #" | while read -r; do
  NEW_VOLUME=$(volume)
  if [ "$NEW_VOLUME" != "$VOLUME" ]; then
    VOLUME=$NEW_VOLUME
    echo "$VOLUME"
  fi
done
