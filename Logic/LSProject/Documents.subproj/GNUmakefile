# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Documents

Documents_OBJC_FILES = \
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

ADDITIONAL_INCLUDE_DIRS += 	\
	-I. -I.. -I../.. 	\
	-I../../LSSearch/	\
	-I../../LSFoundation	\

include $(GNUSTEP_MAKEFILES)/subproject.make
