# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = OGoMailFilter

OGoMailFilter_PRINCIPAL_CLASS = OGoMailFilterModule

OGoMailFilter_OBJC_FILES = \
        OGoMailFilterModule.m		\
	LSWImapMailFilterManager.m	\
	LSWImapMailFilterEditor.m	\
	OGoMailFilterManager.m		\
	SkyVacationViewer.m		\
	SkyVacationEditor.m		\

OGoMailFilter_COMPONENTS = \
	LSWImapMailFilterEditor.wo	\
	SkyVacationViewer.wo		\
	SkyVacationEditor.wo		\

OGoMailFilter_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
