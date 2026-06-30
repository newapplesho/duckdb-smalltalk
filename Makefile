# Common Pharo project tasks (macOS / Linux — Windows users: see README.md).
# Reusable in other Pharo projects: adjust TEST_PATTERN (and PHARO_DIR if needed).

PHARO_DIR    = pharo-local
PHARO        = ./pharo --headless Pharo.image
TEST_PATTERN = DuckDB.*

.PHONY: help load test ui

help:   ## Show available targets
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-6s %s\n", $$1, $$2}'

load:   ## Load (or reload) the project into the Pharo image
	cd $(PHARO_DIR) && $(PHARO) eval --save "$$(cat ../scripts/load-project.st)"

test:   ## Run all tests headless with JUnit XML output
	cd $(PHARO_DIR) && $(PHARO) test --junit-xml-output '$(TEST_PATTERN)'

ui:     ## Open the Pharo GUI
	cd $(PHARO_DIR) && ./pharo-ui Pharo.image
