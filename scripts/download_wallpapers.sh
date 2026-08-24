#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
manifest="$project_dir/wallpapers.tsv"
output_dir="$project_dir/wallpapers-live/videos"
force=0

usage() {
  cat <<'EOF'
Usage: ./scripts/download_wallpapers.sh [--force] [--output DIRECTORY]

Downloads the curated 4K MP4 wallpapers listed in wallpapers.tsv.

Options:
  --force             Replace files that already exist.
  --output DIRECTORY  Download into a custom directory.
  -h, --help          Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --output)
      if [[ $# -lt 2 ]]; then
        echo "error: --output requires a directory" >&2
        exit 2
      fi
      output_dir="$2"
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

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi

if [[ ! -f "$manifest" ]]; then
  echo "error: manifest not found: $manifest" >&2
  exit 1
fi

# Validate before creating directories or downloading anything.  This keeps
# manifest-controlled filenames from becoming traversal paths and ensures
# curl can only receive HTTPS URLs.
"$script_dir/validate_manifest.sh" --manifest "$manifest"

mkdir -p "$output_dir"

downloaded=0
skipped=0
current_partial=""

cleanup_partial() {
  if [[ -n "$current_partial" ]]; then
    rm -f "$current_partial"
  fi
}

trap cleanup_partial EXIT
trap 'exit 130' INT TERM HUP

while IFS=$'\t' read -r filename page_url asset_url _ || [[ -n "${filename:-}" ]]; do
  [[ -n "${filename:-}" ]] || continue
  [[ "$filename" == filename ]] && continue

  target="$output_dir/$filename"
  partial="$target.part"

  if [[ -f "$target" && "$force" -eq 0 ]]; then
    echo "skip: $filename"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -z "${asset_url:-}" ]]; then
    echo "error: missing asset URL for $filename" >&2
    exit 1
  fi

  echo "download: $filename"
  echo "source:   $page_url"
  current_partial="$partial"
  rm -f "$partial"
  if ! final_url="$(curl \
      --proto '=https' \
      --proto-redir '=https' \
      --location \
      --max-redirs 5 \
      --fail \
      --show-error \
      --connect-timeout 20 \
      --max-time 3600 \
      --retry 3 \
      --retry-delay 2 \
      --retry-max-time 300 \
      --remote-time \
      --output "$partial" \
      --write-out '%{url_effective}' \
      "$asset_url")"; then
    echo "error: curl failed for $filename" >&2
    exit 1
  fi
  case "$final_url" in
    https://videos.pexels.com/*)
      ;;
    *)
      echo "error: download redirected outside videos.pexels.com: $final_url" >&2
      exit 1
      ;;
  esac
  if [[ ! -s "$partial" ]]; then
    echo "error: downloaded file is empty: $filename" >&2
    exit 1
  fi
  mv -f "$partial" "$target"
  current_partial=""
  downloaded=$((downloaded + 1))
done < "$manifest"

echo "Wallpapers are ready in: $output_dir"
echo "Downloaded: $downloaded  Skipped: $skipped"
