# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME   = skydbd
BUNDLE_NAME = SkyDB

# Sources

SkyDB_RESOURCE_FILES += \
	Version			\
	INTERFACE.xml		\
	SkyDBActionMap.plist	\

SkyDB_OBJC_FILES = \
	SkyDBAction.m			\
	EOControl+XmlRpcDirectAction.m	\

skydbd_OBJC_FILES = skydbd.m

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

after-install ::
	$(MKDIRS) $(TEMPLATE_INSTALL_DIR)/ $(INSTANCE_INSTALL_DIR)
	cp skydbd.xml $(TEMPLATE_INSTALL_DIR)/
	if ! test -f $(INSTANCE_INSTALL_DIR)/iDB.xml; then\
	  cp iDB.xml    $(INSTANCE_INSTALL_DIR)/; fi
