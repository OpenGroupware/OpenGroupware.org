# ZideStore makefile

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ./Version

ZIDESTORE = ZideStore$(MAJOR_VERSION)$(MINOR_VERSION)
WOAPP_NAME = $(ZIDESTORE)

$(ZIDESTORE)_OBJC_FILES += \
	ZideStore.m		\
	SxAuthenticator.m	\

$(ZIDESTORE)_HEADER_FILES += \
	SxAuthenticator.h	\

$(ZIDESTORE)_RESOURCE_FILES += \
	Version				\
	product.plist			\
	\
	../Maps/E2KAttrMap.plist	\
	../Maps/DAVPropSets.plist	\
	../Maps/MAPIPropMap.plist	\
	../Maps/MAPIPropIDMap.plist	\
	../Maps/AptBackendSets.plist	\
	../Maps/PersonalFolderInfo.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
