.PHONY: download audio all help validate validate-check test quality

help:
	@echo "Targets:"
	@echo "  make validate       - offline wallpapers.tsv checks (columns, unique names, https)"
	@echo "  make validate-check - validate plus optional HTTP HEAD (needs network)"
	@echo "  make test           - offline manifest safety regression contracts"
	@echo "  make quality        - validate, test, ShellCheck, and diff checks"
	@echo "  make download       - download wallpapers from wallpapers.tsv"
	@echo "  make audio          - add tranquil ambient audio to videos"
	@echo "  make all            - download then audio"

validate:
	./scripts/validate_manifest.sh

validate-check:
	./scripts/validate_manifest.sh --check

test:
	bash tests/test_scripts.sh

quality: validate test
	shellcheck scripts/*.sh tests/*.sh
	git diff --check

download: validate
	./scripts/download_wallpapers.sh

audio:
	./scripts/add_tranquil_audio.sh

all: download audio
