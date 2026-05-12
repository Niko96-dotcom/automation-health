SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help build test ci run verify debug logs clean dmg release

help:
	@printf "Automation Health developer targets\n"
	@printf "\n"
	@printf "  make build   Compile all SwiftPM products\n"
	@printf "  make test    Run the scanner self-test\n"
	@printf "  make ci      Run the full local CI gate\n"
	@printf "  make run     Build an app bundle and open it\n"
	@printf "  make verify  Build, open, and verify the app process starts\n"
	@printf "  make debug   Build an app bundle and launch lldb\n"
	@printf "  make logs    Open the app and stream process logs\n"
	@printf "  make clean   Remove local build artifacts\n"
	@printf "  make dmg     Build a signed and notarized DMG (requires Apple Developer credentials)\n"
	@printf "  make release Same as make dmg — build a signed and notarized DMG\n"

build:
	swift build

test:
	./script/test.sh

ci:
	./script/ci.sh

run:
	./script/build_and_run.sh

verify:
	./script/build_and_run.sh --verify

debug:
	./script/build_and_run.sh --debug

logs:
	./script/build_and_run.sh --logs

clean:
	rm -rf .build dist

dmg:
	./script/release.sh

release:
	./script/release.sh
