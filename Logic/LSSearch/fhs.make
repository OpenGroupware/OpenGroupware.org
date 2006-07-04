# postprocessing

# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)
FHS_CMD_DIR=$(FHS_LIB_DIR)opengroupware.org-1.1/commands/

NONFHS_LIBDIR="$(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)/"
NONFHS_LIBNAME="$(LIBRARY_NAME)$(LIBRARY_NAME_SUFFIX)$(SHARED_LIBEXT)"
NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"


fhs-header-dirs ::
	$(MKDIRS) $(FHS_INCLUDE_DIR)$(libLSSearch_HEADER_FILES_INSTALL_DIR)

fhs-command-dirs ::
	$(MKDIRS) $(FHS_CMD_DIR)


move-headers-to-fhs :: fhs-header-dirs
	@echo "moving headers to $(FHS_INCLUDE_DIR) .."
	mv $(GNUSTEP_HEADERS)$(libLSSearch_HEADER_FILES_INSTALL_DIR)/*.h \
	  $(FHS_INCLUDE_DIR)$(libLSSearch_HEADER_FILES_INSTALL_DIR)/

move-libs-to-fhs :: 
	@echo "moving libs to $(FHS_LIB_DIR) .."
	mv $(NONFHS_LIBDIR)/$(NONFHS_LIBNAME)* $(FHS_LIB_DIR)/

move-bundles-to-fhs :: fhs-command-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_CMD_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_CMD_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \
	done

move-to-fhs :: move-libs-to-fhs move-bundles-to-fhs

after-install :: move-to-fhs

endif
