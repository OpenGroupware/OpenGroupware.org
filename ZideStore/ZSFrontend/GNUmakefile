# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libZideStoreFrontend

libZideStoreFrontend_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libZideStoreFrontend_HEADER_FILES_DIR         = .
libZideStoreFrontend_HEADER_FILES_INSTALL_DIR = /ZideStore12/Frontend

libZideStoreFrontend_HEADER_FILES = \
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

libZideStoreFrontend_OBJC_FILES = \
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

libZideStoreFrontend_SUBPROJECTS = Mails

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
