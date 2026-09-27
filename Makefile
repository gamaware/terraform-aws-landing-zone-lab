# One entry point for local runs and CI. `make verify` is offline: no AWS
# credentials, no AWS API calls. Provider and tflint plugin downloads happen
# on first run.

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

ROOTS    := bootstrap $(sort $(patsubst %/versions.tf,%,$(wildcard environments/*/*/*/versions.tf)))
MODULES  := $(sort $(patsubst %/versions.tf,%,$(wildcard modules/*/versions.tf)))
EXAMPLES := $(sort $(patsubst %/versions.tf,%,$(wildcard modules/*/examples/*/versions.tf)))
TFLINT_CONFIG := $(CURDIR)/.tflint.hcl
CHECKOV_VERSION := 3.3.19

.PHONY: help verify fmt init validate lint test policy-test structure-test checkov example-ids test-live clean

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

verify: fmt validate lint test policy-test structure-test checkov example-ids ## Run every offline check
	@echo "verify: all checks passed"

fmt: ## Check Terraform formatting
	terraform fmt -check -recursive -diff

init: ## Initialize every root, module and example without a backend
	@for dir in $(ROOTS) $(MODULES) $(EXAMPLES) tests/live; do \
	  terraform -chdir="$$dir" init -backend=false -input=false -no-color >/dev/null || { echo "init failed: $$dir"; exit 1; }; \
	done

validate: init ## Validate every root and example
	@for dir in $(ROOTS) $(EXAMPLES) tests/live; do \
	  out=$$(terraform -chdir="$$dir" validate -no-color 2>&1) || { echo "$$out"; exit 1; }; \
	  printf '%-55s %s\n' "$$dir" "$$(echo "$$out" | head -1)"; \
	done

lint: ## Run tflint on every root, module and example
	tflint --init --config="$(TFLINT_CONFIG)" >/dev/null
	@for dir in $(ROOTS) $(MODULES) $(EXAMPLES) tests/live; do \
	  tflint --chdir="$$dir" --config="$(TFLINT_CONFIG)" || { echo "tflint failed: $$dir"; exit 1; }; \
	done
	@echo "tflint: clean"

test: ## Run terraform test (mocked provider) in every module
	@for dir in $(MODULES); do \
	  terraform -chdir="$$dir" init -backend=false -input=false -no-color >/dev/null || { echo "init failed: $$dir"; exit 1; }; \
	  out=$$(terraform -chdir="$$dir" test -no-color 2>&1) || { echo "$$out"; exit 1; }; \
	  printf '%-32s %s\n' "$$dir" "$$(echo "$$out" | tail -1)"; \
	done

policy-test: ## Validate SCP JSON and assert which requests each SCP denies
	python3 -m unittest discover -s tests/policies -v

structure-test: ## Assert each root's backend key matches its path and is unique
	python3 -m unittest discover -s tests/structure -v

checkov: ## Scan all Terraform with Checkov
	uvx checkov==$(CHECKOV_VERSION) --config-file .checkov.yaml

example-ids: ## Fail on any 12-digit ID that is not an AWS documentation example
	scripts/check-example-ids.sh

test-live: ## Deploy non-org resources to the sandbox account, assert, destroy (needs CONFIRM_LIVE=yes)
	scripts/test-live.sh

clean: ## Remove local Terraform working directories
	find . -type d -name .terraform -prune -exec rm -rf {} +
