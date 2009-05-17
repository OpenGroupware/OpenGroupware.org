# FHS support (this is a hack and is going to be done by gstep-make!)

ifneq ($(FHS_INSTALL_ROOT),)

FHS_INCLUDE_DIR=$(FHS_INSTALL_ROOT)/include/
FHS_LIB_DIR=$(CONFIGURE_FHS_INSTALL_LIBDIR)

FHS_SHARE_DIR=$(FHS_INSTALL_ROOT)/share/opengroupware.org-5.4/
FHS_COMMANDS_DIR=$(FHS_LIB_DIR)opengroupware.org-5.4/commands/

NONFHS_BINDIR="$(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)"


fhs-commands-dirs ::
	$(MKDIRS) $(FHS_COMMANDS_DIR)

move-bundles-to-fhs :: fhs-commands-dirs
	@echo "moving bundles $(BUNDLE_INSTALL_DIR) to $(FHS_COMMANDS_DIR) .."
	for i in $(BUNDLE_NAME); do \
          j="$(FHS_COMMANDS_DIR)/$${i}$(BUNDLE_EXTENSION)"; \
	  if test -d $$j; then rm -r $$j; fi; \
	  (cd $(BUNDLE_INSTALL_DIR); \
	    $(TAR) chf - --exclude=CVS --exclude=.svn --to-stdout \
            "$${i}$(BUNDLE_EXTENSION)") | \
          (cd $(FHS_COMMANDS_DIR); $(TAR) xf -); \
	  rm -rf "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)";\
	done

#	  mv "$(BUNDLE_INSTALL_DIR)/$${i}$(BUNDLE_EXTENSION)" $$j; \

move-to-fhs :: move-bundles-to-fhs

after-install :: move-to-fhs

endif
