# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_NAME        = CfgAdminUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

CfgAdminUI_PRINCIPAL_CLASS = OGoCfgAdminUIModule

CfgAdminUI_OBJC_FILES += \
	OGoCfgAdminUI.m			\
	OGoCfgAdminPage.m		\
	WOApplication+CfgDB.m		\
	OGoConfigFileEditorPage.m	\
	\
	OGoAccountsVirtualEditor.m	\
	OGoTeamsVirtualEditor.m		\
	OGoCyrusConfigEditor.m		\
	OGoPostfixConfigEditor.m	\
	OGoQuotaTabEditor.m		\

CfgAdminUI_COMPONENTS += \
	OGoCfgAdminPage.wo		\
	OGoAccountsVirtualEditor.wo	\
	OGoTeamsVirtualEditor.wo	\
	OGoCyrusConfigEditor.wo		\
	OGoPostfixConfigEditor.wo	\
	OGoQuotaTabEditor.wo		\

CfgAdminUI_RESOURCE_FILES += Version Defaults.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
