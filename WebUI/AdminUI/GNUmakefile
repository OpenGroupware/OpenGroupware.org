# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME        = AdminUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org-1.0a/WebUI

AdminUI_PRINCIPAL_CLASS = LSWUserManagerModule

AdminUI_OBJC_FILES = 			\
	LSWUserManagerModule.m		\
	LSWStaff.m          		\
	LSWAccountViewer.m  		\
	LSWTeamViewer.m     		\
	LSWTeamEditor.m     		\
	LSWPasswordEditor.m 		\
	\
	SkyDefaultsViewer.m		\
	SkyDefaultsEditor.m		\
	SkyDefaultsDomain.m		\
	SkyDefaultsElement.m		\
	SkyDefaultsElementViewer.m	\

AdminUI_COMPONENTS = 			\
	LSWStaff.wo          		\
	LSWAccountViewer.wo  		\
	LSWTeamViewer.wo     		\
	LSWTeamEditor.wo     		\
	LSWPasswordEditor.wo 		\
	\
	SkyDefaultsViewer.wo		\
	SkyDefaultsEditor.wo		\
	SkyDefaultsElementViewer.wo	\

AdminUI_RESOURCE_FILES += 		\
	Version				\
	Resources/MTA.plist		\
	Resources/Skyrix.plist		\
	Resources/NSGlobalDomain.plist	\
	Resources/skyxmlrpcd.plist	\
	Resources/snsd.plist		\
	Resources/skyaptnotify.plist	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
