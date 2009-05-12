# postprocessing

# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(FHS_INSTALL_ROOT)/lib/
FHS_BIN_DIR=$(FHS_INSTALL_ROOT)/bin/
FHS_DS_DIR=$(FHS_LIB_DIR)opengroupware.org-1.3/datasources/

NONFHS_LIBDIR="$(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)/"
NONFHS_LIBNAME="$(LIBRARY_NAME)$(LIBRARY_NAME_SUFFIX)$(SHARED_LIBEXT)"
NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"

# headers

ifneq ($(FHS_HEADER_DIRS),)

move-headers-to-fhs ::
	@echo "moving headers to $(FHS_INCLUDE_DIR) .."
	for i in "$(FHS_HEADER_DIRS)"; do \
	  $(MKDIRS) $(FHS_INCLUDE_DIR)/$$i;	\
          mv $(GNUSTEP_HEADERS)/$$i/*.h $(FHS_INCLUDE_DIR)/$$i/; \
	done

else

move-headers-to-fhs :: 

endif

move-libs-to-fhs :: 
	@echo "moving libs to $(FHS_LIB_DIR) .."
	mv $(NONFHS_LIBDIR)/$(NONFHS_LIBNAME)* $(FHS_LIB_DIR)/

# tools

ifneq ($(TOOL_NAME),)

fhs-bin-dirs ::
	$(MKDIRS) $(FHS_BIN_DIR)

move-tools-to-fhs :: fhs-bin-dirs
	@echo "moving tools from $(NONFHS_BINDIR) to $(FHS_BIN_DIR) .."
	for i in $(TOOL_NAME); do \
	  mv "$(NONFHS_BINDIR)/$${i}" $(FHS_BIN_DIR); \
	done

else

move-tools-to-fhs ::

endif

# bundles

ifneq ($(BUNDLE_NAME),)

fhs-datasources-dirs ::
	$(MKDIRS) $(FHS_DS_DIR)

move-datasources-to-fhs :: fhs-datasources-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_DS_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_DS_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \
	done

else

move-datasources-to-fhs ::

endif

# master

move-to-fhs :: move-headers-to-fhs move-libs-to-fhs move-tools-to-fhs \
		move-datasources-to-fhs

after-install :: move-to-fhs

endif
