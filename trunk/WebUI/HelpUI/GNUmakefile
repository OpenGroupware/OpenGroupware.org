# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = HelpUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/WebUI/

HelpUI_PRINCIPAL_CLASS = HelpUIModule

HelpUI_OBJC_FILES = \
	HelpUIModule.m		\
	\
	OGoHelpDatabase.m	\
	OGoHelpSection.m	\
	OGoHelpPage.m		\
	\
	OGoHelpViewer.m		\
	OGoHelpAction.m		\

HelpUI_COMPONENTS = \
	OGoHelpViewer.wo

HelpUI_RESOURCE_FILES += \
	Defaults.plist	\
	Version		\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
include ../fhsbundle.make
