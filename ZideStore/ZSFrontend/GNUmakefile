# GNUstep makefile

include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libZSFrontend

libZSFrontend_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSFrontend_INSTALL_DIR=$(OGO_SYSLIBDIR)
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
	NGResourceLocator+ZSF.h	\
	SxStoreInfoFolder.h	\

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
	NGResourceLocator+ZSF.m	\
	SxStoreInfoFolder.m	\
	\
	SxFolder+ZL.m		\

libZSFrontend_RESOURCES += \
	E2KAttrMap.plist	\
	MAPIPropIDMap.plist	\
	MAPIPropMap.plist	\
	PersonalFolderInfo.plist\
	DAVPropSets.plist	\

libZSFrontend_SUBPROJECTS = Mails

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
