# template validation

WOX_FILES = $(shell find . -name "*.wox")

validate-wox ::
	@echo validating .wox templates ...
	for WOX_FILE in $(WOX_FILES); do \
	  echo -n "  validate: $${WOX_FILE} .."; \
	  xmllint --noout $${WOX_FILE};\
          echo ".. ok.";\
	done

all :: validate-wox

install :: all

