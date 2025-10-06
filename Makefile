# Root Makefile - delegates to CAPI and OCM subdirectories

.PHONY: help capi ocm capi-% ocm-%

# Default target
help:
	@echo "Available commands:"
	@echo ""
	@echo "CAPI (Cluster API) commands:"
	@echo "  make capi                 - Show CAPI help"
	@echo "  make capi-<target>        - Run CAPI target (e.g., make capi-setup-capi)"
	@echo ""
	@echo "OCM (Open Cluster Management) commands:"
	@echo "  make ocm                  - Show OCM help"
	@echo "  make ocm-<target>         - Run OCM target (e.g., make ocm-create-hub)"
	@echo ""
	@echo "Examples:"
	@echo "  make capi-setup-capi      - Setup Cluster API"
	@echo "  make ocm-create-hub       - Create OCM hub cluster"
	@echo "  make ocm-join-spokes      - Join spoke clusters to hub"

# CAPI delegation
capi:
	@cd capi && $(MAKE) help

capi-%:
	@cd capi && $(MAKE) $(subst capi-,,$@)

# OCM delegation
ocm:
	@cd ocm && $(MAKE) help

ocm-%:
	@cd ocm && $(MAKE) $(subst ocm-,,$@)

# Legacy targets for backward compatibility
all: capi-all
	@echo "Running default CAPI setup..."

cleanup: capi-cleanup
	@echo "Running CAPI cleanup..."