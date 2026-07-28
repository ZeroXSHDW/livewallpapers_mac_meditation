.PHONY: download audio all help

help:
	@echo "Targets:"
	@echo "  make download  - download wallpapers from wallpapers.tsv"
	@echo "  make audio     - add tranquil ambient audio to videos"
	@echo "  make all       - download then audio"

download:
	./scripts/download_wallpapers.sh

audio:
	./scripts/add_tranquil_audio.sh

all: download audio
