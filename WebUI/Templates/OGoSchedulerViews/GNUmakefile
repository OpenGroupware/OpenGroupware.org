# template validation

WOX_FILES = $(shell find . -name "*.wox")

validate-wox ::
	@echo validating .wox templates ...
	for WOX_FILE in $(WOX_FILES); do \
	  echo "  validate: $${WOX_FILE} .."; \
	  xmllint --noout $${WOX_FILE};\
	done

all :: validate-wox

install :: all

