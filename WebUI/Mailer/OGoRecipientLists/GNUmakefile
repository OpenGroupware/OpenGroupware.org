# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = OGoRecipientLists

OGoRecipientLists_PRINCIPAL_CLASS = OGoRecipientListsModule

OGoRecipientLists_OBJC_FILES = \
        OGoRecipientListsModule.m	\
	SkyMailingListManager.m		\
	SkyMailingListViewer.m		\
	SkyMailingListEditor.m		\
	SkyMailingListDataSource.m	\

OGoRecipientLists_COMPONENTS = \
	SkyMailingListViewer.wo		\
	SkyMailingListEditor.wo		\

OGoRecipientLists_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
