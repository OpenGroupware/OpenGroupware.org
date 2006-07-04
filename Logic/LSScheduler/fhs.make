# postprocessing

# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)

NONFHS_LIBDIR="$(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)/"
NONFHS_LIBNAME="$(LIBRARY_NAME)$(LIBRARY_NAME_SUFFIX)$(SHARED_LIBEXT)"
NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"


fhs-header-dirs ::
	$(MKDIRS) $(FHS_INCLUDE_DIR)$(libOGoSchedulerTools_HEADER_FILES_INSTALL_DIR)

move-headers-to-fhs :: fhs-header-dirs
	@echo "moving headers to $(FHS_INCLUDE_DIR) .."
	mv $(GNUSTEP_HEADERS)$(libOGoSchedulerTools_HEADER_FILES_INSTALL_DIR)/*.h \
	  $(FHS_INCLUDE_DIR)$(libOGoSchedulerTools_HEADER_FILES_INSTALL_DIR)/

move-libs-to-fhs :: 
	@echo "moving libs to $(FHS_LIB_DIR) .."
	mv $(NONFHS_LIBDIR)/$(NONFHS_LIBNAME)* $(FHS_LIB_DIR)/

move-to-fhs :: move-headers-to-fhs move-libs-to-fhs

after-install :: move-to-fhs

endif
