# $Id$

include ../common.make

MODULE_NAME = LSWPreferences

WOBUNDLE_NAME        = PreferencesUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

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

PreferencesUI_COMPONENTS = 		\
	LSWPreferencesViewer.wo 	\
	LSWPreferencesEditor.wo 	\
	SkyDefaultEditField.wo		\
	SkyDisplayPreferences.wo	\
	OGoDefaultEditField.wo		\
	OGoDefaultEditFrame.wo		\
	OGoDefaultViewField.wo		\

-include OGo.make
-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
