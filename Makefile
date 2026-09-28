.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.1.0)
ARCH    ?= arm64

.PHONY: help build run release bundle clean

help:  ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

build:  ## Swift build (debug)
	swift build

run:  ## Swift build and launch debug binary
	swift build
	.build/debug/Engram

release:  ## Swift build (release)
	swift build -c release

bundle:  ## Build macOS Engram.app bundle
	./scripts/make-app-bundle.sh $(VERSION) $(ARCH)

clean:  ## Clean build artifacts and dist
	rm -rf .build dist
