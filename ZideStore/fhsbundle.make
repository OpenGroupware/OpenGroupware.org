# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)
FHS_WEBUI_DIR=$(FHS_LIB_DIR)zidestore-$(MAJOR_VERSION).$(MINOR_VERSION)/

#NONFHS_LIBDIR="$(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)/"
#NONFHS_LIBNAME="$(LIBRARY_NAME)$(LIBRARY_NAME_SUFFIX)$(SHARED_LIBEXT)"
NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"


fhs-webui-dirs ::
	$(MKDIRS) $(FHS_WEBUI_DIR)

move-bundles-to-fhs :: fhs-webui-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_WEBUI_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_WEBUI_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  (cd $(BUNDLE_INSTALL_DIR); \
	    $(TAR) chf - --exclude=CVS --exclude=.svn --to-stdout \
            "$${i}$(BUNDLE_EXTENSION)") | \
          (cd $(FHS_WEBUI_DIR); $(TAR) xf -); \
	  rm -rf "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)";\
	done

#	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \

move-to-fhs :: move-bundles-to-fhs

after-install :: move-to-fhs

endif
