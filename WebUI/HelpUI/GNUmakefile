# $Id$

include ../common.make

WOBUNDLE_NAME        = HelpUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

HelpUI_PRINCIPAL_CLASS = LSWJobModule

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
	Defaults.plist Version	\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
