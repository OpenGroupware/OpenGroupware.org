# $Id$

include ../common.make
include ./Version

LIBRARY_NAME       = libOGoProject
BUNDLE_NAME        = OGoProject
BUNDLE_EXTENSION   = .ds

libOGoProject_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoProject_HEADER_FILES = \
	SkyProject.h				\
	SkyProjectDataSource.h			\
	SkyProjectHistoryDocument.h		\
	SkyProjectTeamDataSource.h		\
	NSString+XMLNamespaces.h		\
	NGFileManagerCopyTool.h			\
	NGFileManagerProcessingTool.h		\
	OGoFileManagerFactory.h			\
	SkyContentHandler.h			\

libOGoProject_OBJC_FILES = \
	NGFileManagerCopyTool.m			\
	NGFileManagerProcessingTool.m		\
	NSString+XMLNamespaces.m		\
	OGoFileManagerFactory.m			\
	SkyContentHandler.m			\
	SkyProject+JS.m				\
	SkyProject+JobDS.m			\
	SkyProject.m				\
	SkyProjectDataSource.m			\
	SkyProjectDocumentGlobalIDResolver.m	\
	SkyProjectHistoryDocument.m		\
	SkyProjectTeamDataSource.m		\
	SkyProjectURLHandle.m			\

libOGoProject_HEADER_FILES_DIR         = .
libOGoProject_HEADER_FILES_INSTALL_DIR = /OGoProject

# datasource/accesshandler bundle

OGoProject_PRINCIPAL_CLASS = SkyProjectBundleManager

OGoProject_OBJC_FILES += \
	SkyProjectBundleManager.m	\
	SkyProjectAccessHandler.m	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-OGoProject-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION); \
	$(LN_S) -f ../bundle-info.plist .; cd ..)
