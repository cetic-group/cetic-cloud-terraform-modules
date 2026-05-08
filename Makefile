# cetic-cloud-terraform-modules — quick targets
#
# `make help` for the list.

SHELL := /bin/bash
TF ?= terraform
TFLINT ?= tflint
TERRAFORM_DOCS ?= terraform-docs

# Reusable modules + landing-zones — these must validate without external
# inputs (no `file()` calls to non-existent paths, no live API hits).
# Examples live under `examples/` and may reference local files (SSH keys etc.)
# that don't exist in CI — we don't validate them here, they're starter kits
# meant to be copied locally and adjusted.
MODULE_DIRS := $(shell find modules landing-zones -type f -name '*.tf' -exec dirname {} \; 2>/dev/null | sort -u)

.DEFAULT_GOAL := help

.PHONY: help
help:  ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: fmt
fmt:  ## terraform fmt -recursive
	$(TF) fmt -recursive

.PHONY: fmt-check
fmt-check:  ## terraform fmt -check (CI)
	$(TF) fmt -check -recursive

.PHONY: validate
validate:  ## terraform init + validate sur tous les modules
	@set -e; for d in $(MODULE_DIRS); do \
		echo "==> $$d"; \
		( cd $$d && $(TF) init -backend=false -input=false >/dev/null && $(TF) validate ) || exit 1; \
	done

.PHONY: lint
lint:  ## tflint sur tous les modules
	@set -e; for d in $(MODULE_DIRS); do \
		echo "==> tflint $$d"; \
		( cd $$d && $(TFLINT) ) || exit 1; \
	done

.PHONY: fmt-examples
fmt-examples:  ## terraform fmt -check sur les examples (pas de validate — refs locales)
	@$(TF) fmt -check -recursive examples/

.PHONY: test
test:  ## terraform test (plan-only, pas d'apply réel — provider mocké)
	@set -e; for d in modules landing-zones; do \
		find $$d -name 'tests' -type d | while read t; do \
			parent=$$(dirname $$t); \
			echo "==> terraform test $$parent"; \
			( cd $$parent && $(TF) init -backend=false -input=false >/dev/null && $(TF) test ) || exit 1; \
		done; \
	done

.PHONY: docs
docs:  ## Régénère les README.md des modules avec terraform-docs
	@set -e; for d in $(MODULE_DIRS); do \
		if [ -f $$d/README.md.tmpl ]; then \
			echo "==> terraform-docs $$d"; \
			$(TERRAFORM_DOCS) markdown table --output-file README.md --output-mode inject $$d; \
		fi; \
	done

.PHONY: clean
clean:  ## Supprime .terraform/ et fichiers d'état locaux
	find . -type d -name '.terraform' -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name '.terraform.lock.hcl' -delete
	find . -type f -name '*.tfplan' -delete

.PHONY: ci
ci: fmt-check validate lint test  ## All CI checks (fmt + validate + lint + test)
