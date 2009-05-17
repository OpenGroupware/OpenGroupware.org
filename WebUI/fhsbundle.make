# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)

FHS_SHARE_DIR=$(FHS_INSTALL_ROOT)/share/opengroupware.org-5.5/
FHS_WEBUI_DIR=$(FHS_LIB_DIR)opengroupware.org-5.5/webui/

#NONFHS_LIBDIR="$(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)/"
#NONFHS_LIBNAME="$(LIBRARY_NAME)$(LIBRARY_NAME_SUFFIX)$(SHARED_LIBEXT)"
NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"


fhs-webui-dirs ::
	$(MKDIRS) $(FHS_WEBUI_DIR)

move-bundles-to-fhs :: fhs-webui-dirs
	@echo "moving bundles $(WOBUNDLE_INSTALL_DIR) to $(FHS_WEBUI_DIR) .."
	for i in $(WOBUNDLE_NAME); do \
          j="$(FHS_WEBUI_DIR)/$${i}$(WOBUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  (cd $(WOBUNDLE_INSTALL_DIR); \
	    $(TAR) chf - --exclude=CVS --exclude=.svn --to-stdout \
            "$${i}$(WOBUNDLE_EXTENSION)") | \
          (cd $(FHS_WEBUI_DIR); $(TAR) xf -); \
	  rm -rf "$(WOBUNDLE_INSTALL_DIR)/$${i}$(WOBUNDLE_EXTENSION)";\
	done

#	  mv "$(WOBUNDLE_INSTALL_DIR)/$${i}$(WOBUNDLE_EXTENSION)" $$j; \

move-to-fhs :: move-bundles-to-fhs

after-install :: move-to-fhs

endif
