# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_NAME        = CyrusAdminUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

CyrusAdminUI_PRINCIPAL_CLASS = OGoCyrusAdminUIModule

CyrusAdminUI_OBJC_FILES += \
	OGoCyrusAdminUI.m		\
	OGoCyrusAdminPage.m

CyrusAdminUI_COMPONENTS += \
	OGoCyrusAdminPage.wo

CyrusAdminUI_RESOURCE_FILES += Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
