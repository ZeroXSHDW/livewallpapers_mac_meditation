#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
validator="$script_dir/validate_manifest.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/livewallpapers-tests.XXXXXX")"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

header=$'filename\tpage_url\tasset_url\taudio_profile'

expect_valid() {
  local name="$1"
  local row="$2"
  local manifest="$test_root/$name.tsv"

  printf '%s\n%s\n' "$header" "$row" > "$manifest"
  if ! "$validator" --manifest "$manifest" >/dev/null; then
    echo "FAIL: expected valid manifest: $name" >&2
    exit 1
  fi
}

expect_invalid() {
  local name="$1"
  local row="$2"
  local manifest="$test_root/$name.tsv"

  printf '%s\n%s\n' "$header" "$row" > "$manifest"
  if "$validator" --manifest "$manifest" >/dev/null 2>&1; then
    echo "FAIL: expected invalid manifest: $name" >&2
    exit 1
  fi
}

valid_row=$'scene-01.mp4\thttps://www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_valid valid "$valid_row"

expect_invalid traversal $'../escape.mp4\thttps://www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_invalid http_page $'scene-01.mp4\thttp://www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_invalid empty_host $'scene-01.mp4\thttps:///video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_invalid credentials $'scene-01.mp4\thttps://user:pass@www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_invalid untrusted_host $'scene-01.mp4\thttps://evil.example/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean'
expect_invalid audio_profile $'scene-01.mp4\thttps://www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tunknown'
expect_invalid duplicate $'scene-01.mp4\thttps://www.pexels.com/video/scene/\thttps://videos.pexels.com/video-files/scene.mp4\tocean\nscene-01.mp4\thttps://www.pexels.com/video/scene-2/\thttps://videos.pexels.com/video-files/scene-2.mp4\train'

if ! grep -Fq -- "https://videos.pexels.com/*" "$script_dir/download_wallpapers.sh"; then
  echo "FAIL: downloader must enforce the final Pexels CDN host" >&2
  exit 1
fi
if ! grep -Fq -- "--proto-redir '=https'" "$script_dir/download_wallpapers.sh"; then
  echo "FAIL: downloader must keep redirects on HTTPS" >&2
  exit 1
fi

workflow="$repo_root/.github/workflows/ci.yml"
if grep -Fq -- 'runs-on: ubuntu-latest' "$workflow" ||
   ! grep -Fq -- 'runs-on: ubuntu-24.04' "$workflow"; then
  echo "FAIL: CI must use the fixed Ubuntu 24.04 runner" >&2
  exit 1
fi
if ! awk '/persist-credentials: false/ { checkout = NR } /run: git diff --check/ { patch = NR } END { exit !(checkout > 0 && patch > checkout) }' "$workflow"; then
  echo "FAIL: CI must run patch hygiene immediately after checkout" >&2
  exit 1
fi

echo "ok: manifest safety and profile contracts passed"
