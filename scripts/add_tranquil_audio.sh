#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
manifest="$project_dir/wallpapers.tsv"
video_dir="$project_dir/wallpapers-live/videos"
force=0

usage() {
  cat <<'EOF'
Usage: ./scripts/add_tranquil_audio.sh [--force] [--video-dir DIRECTORY]

Adds quiet, scene-matched ambient AAC audio to silent wallpaper videos.
The original 4K video stream is copied without re-encoding.

Options:
  --force                Replace generated audio, including existing audio.
  --video-dir DIRECTORY  Process a custom wallpaper directory.
  -h, --help             Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --video-dir)
      if [[ $# -lt 2 ]]; then
        echo "error: --video-dir requires a directory" >&2
        exit 2
      fi
      video_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for command_name in ffmpeg ffprobe; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "error: $command_name is required; install it with: brew install ffmpeg" >&2
    exit 1
  fi
done

if [[ ! -d "$video_dir" ]]; then
  echo "error: video directory not found: $video_dir" >&2
  echo "hint: run ./scripts/download_wallpapers.sh first" >&2
  exit 1
fi

"$script_dir/validate_manifest.sh" --manifest "$manifest"

temporary=""
cleanup_temporary() {
  if [[ -n "$temporary" ]]; then
    rm -f "$temporary"
  fi
}

trap cleanup_temporary EXIT
trap 'exit 130' INT TERM HUP

while IFS=$'\t' read -r filename _ _ audio_profile || [[ -n "${filename:-}" ]]; do
  [[ -n "${filename:-}" ]] || continue
  [[ "$filename" == filename ]] && continue

  video="$video_dir/$filename"

  if [[ ! -f "$video" ]]; then
    echo "missing: $filename"
    continue
  fi

  if ! existing_audio="$(
      ffprobe -v error -select_streams a -show_entries stream=codec_name \
        -of default=nw=1:nk=1 "$video"
    )"; then
    echo "error: ffprobe could not inspect $filename" >&2
    exit 1
  fi

  if [[ "$audio_profile" == "preserve" ]]; then
    if [[ -n "$existing_audio" ]]; then
      echo "preserve: $filename"
      continue
    fi
    echo "error: $filename declares preserve but has no audio stream" >&2
    exit 1
  fi

  if [[ -n "$existing_audio" && "$force" -eq 0 ]]; then
    echo "skip audio: $filename"
    continue
  fi

  if ! duration="$(
      ffprobe -v error -show_entries format=duration \
        -of default=nw=1:nk=1 "$video"
    )"; then
    echo "error: ffprobe could not read duration for $filename" >&2
    exit 1
  fi
  if [[ ! "$duration" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v duration="$duration" 'BEGIN { exit !(duration > 0) }'; then
    echo "error: invalid video duration for $filename: $duration" >&2
    exit 1
  fi
  fade_start="$(awk -v duration="$duration" \
    'BEGIN { start = duration - 0.75; if (start < 0) start = 0; printf "%.3f", start }')"

  case "$audio_profile" in
    ocean)
      source_filter="anoisesrc=color=brown:amplitude=0.22:sample_rate=48000"
      sound_filter="highpass=f=35,lowpass=f=1100,tremolo=f=0.10:d=0.25,volume=0.18"
      ;;
    water)
      source_filter="anoisesrc=color=pink:amplitude=0.16:sample_rate=48000"
      sound_filter="highpass=f=90,lowpass=f=2600,tremolo=f=0.12:d=0.15,volume=0.13"
      ;;
    rain)
      source_filter="anoisesrc=color=white:amplitude=0.10:sample_rate=48000"
      sound_filter="highpass=f=900,lowpass=f=7000,volume=0.10"
      ;;
    wind)
      source_filter="anoisesrc=color=brown:amplitude=0.14:sample_rate=48000"
      sound_filter="highpass=f=45,lowpass=f=850,tremolo=f=0.10:d=0.30,volume=0.12"
      ;;
    underwater)
      source_filter="anoisesrc=color=brown:amplitude=0.20:sample_rate=48000"
      sound_filter="highpass=f=25,lowpass=f=420,tremolo=f=0.10:d=0.20,volume=0.16"
      ;;
    celestial)
      source_filter="sine=frequency=110:sample_rate=48000"
      sound_filter="lowpass=f=500,tremolo=f=0.10:d=0.35,volume=0.035"
      ;;
    *)
      echo "error: unknown audio profile '$audio_profile' for $filename" >&2
      exit 1
      ;;
  esac

  if ! temporary="$(mktemp "$video_dir/.${filename}.audio.XXXXXX")"; then
    echo "error: could not create a temporary output for $filename" >&2
    exit 1
  fi
  echo "add $audio_profile audio: $filename"
  if ! ffmpeg \
    -hide_banner \
    -loglevel error \
    -nostdin \
    -y \
    -i "$video" \
    -f lavfi \
    -i "$source_filter" \
    -filter_complex \
      "[1:a]$sound_filter,pan=stereo|c0=c0|c1=c0,afade=t=in:st=0:d=0.75,afade=t=out:st=$fade_start:d=0.75[ambient]" \
    -map 0:v:0 \
    -map "[ambient]" \
    -c:v copy \
    -c:a aac \
    -b:a 160k \
    -t "$duration" \
    -movflags +faststart \
    "$temporary"; then
    echo "error: ffmpeg failed for $filename" >&2
    exit 1
  fi
  if [[ ! -s "$temporary" ]]; then
    echo "error: ffmpeg produced an empty file for $filename" >&2
    exit 1
  fi
  mv -f "$temporary" "$video"
  temporary=""
done < "$manifest"

echo "Tranquil audio is ready in: $video_dir"
