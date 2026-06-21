SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

.DEFAULT_GOAL := help

ARGS ?= --format json --output ./reminders.json

.PHONY: export setup help

export: ## Build, sign, and export reminders
	swift build -c release && \
	codesign --sign - --entitlements entitlements.plist .build/release/ExportReminders && \
	.build/release/ExportReminders $(ARGS)

setup: ## Check and install development tools (Homebrew, SwiftFormat, Periphery)
	@echo "=== Checking development tools ==="
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Homebrew not found. Install Homebrew? (y/N)"; \
		read -r ans; \
		if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
			echo "Installing Homebrew..."; \
			/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		else \
			echo "Skipping Homebrew installation."; \
		fi; \
	else \
		echo "✓ Homebrew is installed."; \
	fi
	@if ! command -v swiftformat >/dev/null 2>&1; then \
		echo "SwiftFormat not found. Install via Homebrew? (y/N)"; \
		read -r ans; \
		if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
			echo "Installing SwiftFormat..."; \
			brew install swiftformat; \
		else \
			echo "Skipping SwiftFormat installation."; \
		fi; \
	else \
		echo "✓ SwiftFormat is installed."; \
	fi
	@if ! command -v periphery >/dev/null 2>&1; then \
		echo "Periphery not found. Install via Homebrew? (y/N)"; \
		read -r ans; \
		if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
			echo "Installing Periphery..."; \
			brew install periphery; \
		else \
			echo "Skipping Periphery installation."; \
		fi; \
	else \
		echo "✓ Periphery is installed."; \
	fi
	@echo ""
	@echo "=== All tools are installed. ==="

help: ## Show this help
	@echo "Available targets:"
	@echo "  make export       Build, sign, and export reminders to JSON"
	@echo "                   ARGS=\"...\"  Custom CLI arguments"
	@echo "  make setup        Check and install development tools"
	@echo "  make help         Show this help"
