GIN_ROOT := $(abspath $(lastword $(MAKEFILE_LIST))/..)

.DEFAULT_GOAL := help

.PHONY: all
all: help

# lists all targets in this makefile + their description comment starting by '##' next to target name
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## List this help message with makefile targets
	@echo "Makefile targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# Bumpversion 'dry' config
# if 'dry' is specified as target, any bumpversion call using 'BUMP_XARGS' will not apply changes
BUMP_XARGS ?= --verbose --allow-dirty
ifeq ($(filter dry, $(MAKECMDGOALS)), dry)
	BUMP_XARGS := $(BUMP_XARGS) --dry-run
endif
.PHONY: dry
dry: setup.cfg	## Only display results (no changes applied) when combined with 'bump'.
	@-echo > /dev/null

.PHONY: bump
bump:  ## Updates the project version using `make VERSION=<x.y.z> bump`
	@-echo "Updating package version ..."
	@[ "${VERSION}" ] || ( echo ">> 'VERSION' is not set"; exit 1 )
	@-which bump2version || pip install bump2version
	@-bash -c 'bump2version $(BUMP_XARGS) --new-version "${VERSION}" patch;'
