# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

MODULE_NAME = LSWPreferences

WOBUNDLE_NAME        = PreferencesUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org-1.0a/WebUI/

PreferencesUI_PRINCIPAL_CLASS = LSWPreferencesModule

PreferencesUI_OBJC_FILES = 		\
	LSWPreferencesModule.m		\
	LSWPreferencesViewer.m		\
	LSWPreferencesEditor.m 		\
	LSWPreferencesEditor+AccountLog.m \
	SkyDefaultEditField.m		\
	SkyDisplayPreferences.m		\
	OGoDefaultEditField.m		\
	OGoDefaultEditFrame.m		\
	OGoDefaultViewField.m		\

PreferencesUI_RESOURCE_FILES += Defaults.plist Version

-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
