.PHONY: download audio all help validate validate-check

help:
	@echo "Targets:"
	@echo "  make validate       - offline wallpapers.tsv checks (columns, unique names, https)"
	@echo "  make validate-check - validate plus optional HTTP HEAD (needs network)"
	@echo "  make download       - download wallpapers from wallpapers.tsv"
	@echo "  make audio          - add tranquil ambient audio to videos"
	@echo "  make all            - download then audio"

validate:
	./scripts/validate_manifest.sh

validate-check:
	./scripts/validate_manifest.sh --check

download: validate
	./scripts/download_wallpapers.sh

audio:
	./scripts/add_tranquil_audio.sh

all: download audio
