# Live Wallpapers for macOS Meditation

A curated collection of calm, cinematic 4K MP4 wallpapers for macOS.

This project is designed for use with
[thusvill/LiveWallpaperMacOS](https://github.com/thusvill/LiveWallpaperMacOS).
It includes a reproducible downloader, scene-matched tranquil audio generator,
and source manifest for ocean, forest, night-sky, city, aurora, mountain,
underwater, fireplace, river, desert, lake, cloud, and lavender scenes.

## Quick start

```bash
git clone https://github.com/ZeroXSHDW/livewallpapers_mac_meditation.git
cd livewallpapers_mac_meditation
brew install ffmpeg
./scripts/download_wallpapers.sh
./scripts/add_tranquil_audio.sh
# or: make download && make audio
```

The videos are downloaded to:

```text
wallpapers-live/videos/
```

Open LiveWallpaperMacOS and import the MP4 files from that directory. Use
fill/crop scaling for the best fit on a widescreen Mac display.

## Included wallpapers

| File | Resolution | FPS | Source |
| --- | --- | ---: | --- |
| `01-serene-ocean-waves-4k.mp4` | 3840x2160 | 30 | [Pexels](https://www.pexels.com/video/aerial-view-of-serene-ocean-waves-in-4k-36070847/) |
| `02-forest-waterfall-4k.mp4` | 3840x2160 | 30 | [Pexels](https://www.pexels.com/video/waterfalls-in-a-forest-5257861/) |
| `03-starry-night-timelapse-4k.mp4` | 3840x2160 | 25 | [Pexels](https://www.pexels.com/video/time-lapse-of-a-starry-night-sky-13384219/) |
| `04-rainy-night-city-4k.mp4` | 3840x2160 | 24 | [Pexels](https://www.pexels.com/video/night-street-slow-motion-19924296/) |
| `05-iceland-aurora-4k.mp4` | 3840x2160 | 25 | [Pexels](https://www.pexels.com/video/breathtaking-northern-lights-over-iceland-s-winter-landscape-35092214/) |
| `06-mountains-and-clouds-4k.mp4` | 3840x2160 | 25 | [Pexels](https://www.pexels.com/video/4k-aerial-view-of-mountain-landscape-with-clouds-37404855/) |
| `07-underwater-wave-4k.mp4` | 3840x2160 | 24 | [Pexels](https://www.pexels.com/video/underwater-view-of-a-breaking-wave-4863640/) |
| `08-cozy-fireplace-4k.mp4` | 3840x2160 | 60 | [Pexels](https://www.pexels.com/video/burning-logs-in-a-fireplace-13270910/) |
| `09-mountain-river-4k.mp4` | 3840x2160 | 24 | [Pexels](https://www.pexels.com/video/a-flowing-river-in-a-mountain-landscape-13978917/) |
| `10-misty-forest-4k.mp4` | 3840x2160 | 60 | [Pexels](https://www.pexels.com/video/misty-forest-with-tall-trees-in-foggy-atmosphere-32675101/) |
| `11-desert-dunes-4k.mp4` | 3840x2160 | 25 | [Pexels](https://www.pexels.com/video/aerial-view-of-the-desert-19376557/) |
| `12-golden-hour-lake-4k.mp4` | 3840x2160 | 24 | [Pexels](https://www.pexels.com/video/beautiful-scenery-of-a-calm-lake-during-golden-hour-5378535/) |
| `13-sunset-clouds-4k.mp4` | 3840x2160 | 25 | [Pexels](https://www.pexels.com/video/a-colorful-sunset-sky-above-the-clouds-12935195/) |
| `14-lavender-fields-4k.mp4` | 3840x2160 | 24 | [Pexels](https://www.pexels.com/video/drone-footage-of-a-lavender-field-in-bloom-13968685/) |

The complete machine-readable list is in
[`wallpapers.tsv`](wallpapers.tsv).

Validate the manifest offline (columns, unique names, https URLs):

```bash
make validate
# optional network HEAD checks (not used in CI; protected Pexels pages warn):
make validate-check
# patch hygiene only (whitespace and unresolved conflict markers):
make patch-hygiene
# full offline repository gate (validation, shellcheck, regression contracts):
make quality
```

`make quality` starts with `make patch-hygiene`, which runs `git diff --check`
before the remaining checks. The offline gate does not download media or require FFmpeg. It rejects unsafe
filenames, credential-bearing, non-HTTPS, or non-Pexels URLs, duplicate
entries, malformed rows, and unknown audio profiles before either media script
performs file I/O.

## Tranquil audio

The audio generator creates subtle stereo ambience matched to each scene:
ocean surf, flowing water, rain, wind, underwater hush, or a soft celestial
drone. Natural source audio is retained for the fireplace and mountain river.

```bash
brew install ffmpeg
./scripts/add_tranquil_audio.sh
```

FFmpeg copies the original video stream without re-encoding it, so the native
picture quality is preserved. Use `--force` to replace an existing generated
track. The `preserve` profile requires an existing audio stream and fails
closed if the source file does not contain one; it never invents replacement
audio for a source that is supposed to be retained.

## Downloader options

Download missing files:

```bash
./scripts/download_wallpapers.sh
```

Replace and redownload every file:

```bash
./scripts/download_wallpapers.sh --force
```

Download to a different directory:

```bash
./scripts/download_wallpapers.sh --output /path/to/videos
```

Downloads are written to a temporary file and atomically renamed only after a
non-empty HTTPS response completes. Manifest URLs and final redirects are
restricted to the expected Pexels hosts, retries have bounded connection and
total durations, and interrupted partial files are removed automatically.

## Why the MP4 files are not committed

The videos are free to use under the
[Pexels license](https://www.pexels.com/license/), but Pexels does not allow
its unmodified photos or videos to be redistributed on another stock or
wallpaper platform. For that reason, this repository stores the source links
and downloader rather than publicly mirroring the MP4 binaries.

Each user downloads the original files directly from Pexels for use with the
wallpaper app.

## Credits

The footage remains the property of its respective creators:

- Jesus Alfonso
- Engin Akyurt
- Video Fullness
- Nathan Murphy
- Ken Cheung
- Dancing Sky
- Daniel Torobekov
- Volodymyr Kostiev
- Serg Alesenko
- PUWOOK Kwak
- Volkan Yilmaz
- Danilo Riba
- DUG DIH

Attribution is not required by Pexels, but these creators made the collection
possible.

## Project license

The scripts and project documentation are released under the
[MIT License](LICENSE). The downloaded videos are not covered by the MIT
License; they remain subject to the Pexels license and their creators' rights.

## Contributing

Keep attribution, licensing boundaries, and downloader safety intact. Run the documented validation commands and see [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

Report vulnerabilities privately using [SECURITY.md](SECURITY.md). Never commit private downloads, credentials, or local media paths.

## Purpose

This repository packages a safe, inspectable macOS wallpaper and meditation
media workflow. It does not redistribute the downloaded media itself.

## Features

- Validated wallpaper catalog and attribution records.
- Shell-based downloader and local media organization guidance.

## Architecture

Metadata and scripts remain in Git; downloaded media stays local and outside
the repository. CI validates catalog structure and shell safety without
fetching or storing the media collection.

## Prerequisites

Use macOS with Bash 3.2-compatible tooling. Review the downloader options,
network permissions, storage requirements, and Pexels terms before use.
