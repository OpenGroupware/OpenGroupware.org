# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSDocuments

LSDocuments_OBJC_FILES = \
	LSCheckGetPermissionDocumentCommand.m		\
	LSCheckGetPermissionDocumentEditingCommand.m	\
	LSCheckGetPermissionDocumentVersionCommand.m	\
	LSCheckoutDocumentCommand.m			\
	LSCheckoutDocumentVersionCommand.m		\
	LSDeleteDocumentCommand.m			\
	LSDeleteDocumentVersionCommand.m		\
	LSExtendedSearchDocumentCommand.m		\
	LSFetchIndexDocumentCommand.m			\
	LSFetchRootDocumentCommand.m			\
	LSFilterAndSortDocCommand.m			\
	LSFilterAndSortFolderCommand.m			\
	LSGetAttachmentNameCommand.m			\
	LSGetDocumentCommand.m				\
	LSGetDocumentEditingCommand.m			\
	LSGetDocumentEditingForGlobalIDs.m		\
	LSGetDocumentForGlobalIDs.m			\
	LSGetDocumentVersionCommand.m			\
	LSMoveDocumentCommand.m				\
	LSNewDocumentCommand.m				\
	LSRejectDocumentCommand.m			\
	LSReleaseDocumentCommand.m			\
	LSSetDocumentCommand.m				\
	LSSetFolderCommand.m				\
	LSSetObjectLinkCommand.m			\

LSDocuments_RESOURCE_FILES += Defaults.plist Version

include ../commandbundle.make
