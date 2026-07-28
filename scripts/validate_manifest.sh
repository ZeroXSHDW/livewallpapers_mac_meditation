#!/usr/bin/env bash
# Validate wallpapers.tsv without requiring network access by default.
# Optional: --check performs HTTP HEAD on asset_url / page_url (not for CI).

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
manifest="$project_dir/wallpapers.tsv"
do_check=0
timeout_secs=10

usage() {
  cat <<'EOF'
Usage: ./scripts/validate_manifest.sh [--check] [--manifest PATH]

Validates wallpapers.tsv structure offline:
  - header columns
  - exactly 4 tab-separated fields per row
  - unique filenames
  - https:// URLs for page_url and asset_url
  - non-empty audio_profile
  - .mp4 filename suffix

Options:
  --check            Also HTTP HEAD each URL (optional; needs network; not for CI)
  --manifest PATH    Manifest file (default: wallpapers.tsv at repo root)
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      do_check=1
      shift
      ;;
    --manifest)
      if [[ $# -lt 2 ]]; then
        echo "error: --manifest requires a path" >&2
        exit 2
      fi
      manifest="$2"
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

if [[ ! -f "$manifest" ]]; then
  echo "error: manifest not found: $manifest" >&2
  exit 1
fi

expected_header=$'filename\tpage_url\tasset_url\taudio_profile'
header="$(head -n1 "$manifest")"
if [[ "$header" != "$expected_header" ]]; then
  echo "error: unexpected header (want: filename, page_url, asset_url, audio_profile)" >&2
  echo "  got: $header" >&2
  exit 1
fi

errors=0
row_count=0
seen_names=""

while IFS=$'\t' read -r filename page_url asset_url audio_profile || [[ -n "${filename:-}" ]]; do
  [[ -n "${filename:-}" ]] || continue
  [[ "$filename" == "filename" ]] && continue

  row_count=$((row_count + 1))
  line_no=$((row_count + 1))

  # Count tab-separated fields on the reconstructed row
  field_count=$(printf '%s\t%s\t%s\t%s\n' "$filename" "$page_url" "$asset_url" "$audio_profile" | awk -F'\t' '{print NF}')
  if [[ "$field_count" -ne 4 ]]; then
    echo "error: line $line_no has $field_count columns (expected 4)" >&2
    errors=$((errors + 1))
    continue
  fi

  if [[ -z "$filename" || -z "$page_url" || -z "$asset_url" || -z "$audio_profile" ]]; then
    echo "error: line $line_no has an empty required field" >&2
    errors=$((errors + 1))
  fi

  if [[ "$filename" != *.mp4 ]]; then
    echo "error: line $line_no filename must end with .mp4: $filename" >&2
    errors=$((errors + 1))
  fi

  case $'\n'"$seen_names"$'\n' in
    *$'\n'"$filename"$'\n'*)
      echo "error: duplicate filename: $filename" >&2
      errors=$((errors + 1))
      ;;
    *)
      seen_names="${seen_names}${seen_names:+$'\n'}${filename}"
      ;;
  esac

  if [[ "$page_url" != https://* ]]; then
    echo "error: line $line_no page_url must start with https://: $page_url" >&2
    errors=$((errors + 1))
  fi
  if [[ "$asset_url" != https://* ]]; then
    echo "error: line $line_no asset_url must start with https://: $asset_url" >&2
    errors=$((errors + 1))
  fi
done < "$manifest"

# Independent NF pass for malformed tab rows
awk -F'\t' '
  NR == 1 { next }
  NF != 4 {
    printf "error: awk line %d has %d columns (expected 4)\n", NR, NF > "/dev/stderr"
    bad=1
  }
  END {
    if (NR < 2) {
      print "error: wallpapers.tsv needs a header and at least one data row" > "/dev/stderr"
      exit 1
    }
    if (bad) exit 1
  }
' "$manifest"

if [[ "$row_count" -lt 1 ]]; then
  echo "error: no data rows found" >&2
  exit 1
fi

if [[ "$errors" -gt 0 ]]; then
  echo "error: manifest validation failed with $errors issue(s)" >&2
  exit 1
fi

echo "ok: $row_count wallpaper row(s); columns, unique names, and https URLs look good"

if [[ "$do_check" -eq 1 ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required for --check" >&2
    exit 1
  fi

  echo "Running optional HEAD checks (network)..."
  check_errors=0
  while IFS=$'\t' read -r filename page_url asset_url audio_profile; do
    [[ -n "${filename:-}" ]] || continue
    [[ "$filename" == "filename" ]] && continue

    for kind in page asset; do
      if [[ "$kind" == "page" ]]; then
        url="$page_url"
      else
        url="$asset_url"
      fi
      code="$(curl -sS -o /dev/null -w '%{http_code}' -I -L --max-time "$timeout_secs" "$url" || echo "000")"
      case "$code" in
        2*|3*)
          echo "ok HEAD $code $kind $filename"
          ;;
        *)
          echo "warn HEAD $code $kind $filename -> $url" >&2
          check_errors=$((check_errors + 1))
          ;;
      esac
    done
  done < "$manifest"

  if [[ "$check_errors" -gt 0 ]]; then
    echo "error: $check_errors URL(s) failed HEAD checks" >&2
    exit 1
  fi
  echo "ok: all HEAD checks passed"
fi
