# templates

FHS_BUNDLE_TEMPLATE_DIR = $(FHS_SHARE_DIR)templates/$(WOBUNDLE_NAME)
FHS_BUNDLE_DIR = $(FHS_WEBUI_DIR)/$(WOBUNDLE_NAME)$(WOBUNDLE_EXTENSION)

fhs-templates-dirs ::
	$(MKDIRS) $(FHS_BUNDLE_TEMPLATE_DIR)

move-templates-to-fhs :: move-bundles-to-fhs fhs-templates-dirs
	@echo "copying templates to $(FHS_BUNDLE_TEMPLATE_DIR) .."
	for i in $($(WOBUNDLE_NAME)_COMPONENTS); do \
	  mv $$i/*.html $$i/*.wod $(FHS_BUNDLE_TEMPLATE_DIR)/; \
	done

after-install :: move-templates-to-fhs

