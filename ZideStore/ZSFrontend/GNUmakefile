# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libZSFrontend

libZSFrontend_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSFrontend_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSFrontend_HEADER_FILES_DIR         = .
libZSFrontend_HEADER_FILES_INSTALL_DIR = /ZSFrontend
FHS_HEADER_DIRS = ZSFrontend

libZSFrontend_HEADER_FILES = \
	ExStoreEntryID.h	\
	NSObject+ExValues.h	\
	NSString+csv.h		\
	SxDavAction.h		\
	SxFolder.h		\
	SxImageHandler.h	\
	SxMailFolder.h		\
	SxMsgRootFolder.h	\
	SxObject.h		\
	SxPublicFolder.h	\
	SxRenderer.h		\
	SxRendererFactory.h	\
	SxSearchFolder.h	\
	SxUserFolder.h		\
	OLDavPropMapper.h	\
	SxMapEnumerator.h	\
	EOQualifier+Additions.h	\

libZSFrontend_OBJC_FILES = \
	SxFolder.m		\
	SxFolder+DAV.m		\
	SxObject.m		\
	SxDavAction.m		\
	\
	SxMailFolder.m		\
	SxUserFolder.m		\
	SxPublicFolder.m	\
	SxSearchFolder.m	\
	SxMsgRootFolder.m	\
	SxImageHandler.m	\
	\
	NSObject+ExValues.m	\
	NSString+csv.m		\
	dateTime.m		\
	ExStoreEntryID.m	\
	\
	OLDavPropMapper.m	\
	SxMapEnumerator.m	\
	EOQualifier+Additions.m	\

libZSFrontend_SUBPROJECTS = Mails

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../fhslib.make
