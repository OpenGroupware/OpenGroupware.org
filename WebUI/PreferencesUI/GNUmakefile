# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

MODULE_NAME = LSWPreferences

WOBUNDLE_NAME = PreferencesUI

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
	\
	SimpleTextSepFormatter.m	\
	ArrayFormatter.m		\
	BoolFormatter.m			\

PreferencesUI_RESOURCE_FILES += Defaults.plist Version

-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
