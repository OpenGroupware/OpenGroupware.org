# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = ZideStore

ZideStore_OBJC_FILES += \
	ZideStore.m		\
	SxAuthenticator.m	\

ZideStore_HEADER_FILES += \
	SxAuthenticator.h	\

ZideStore_RESOURCE_FILES += \
	Version				\
	product.plist			\
	\
	Maps/E2KAttrMap.plist		\
	Maps/DAVPropSets.plist		\
	Maps/MAPIPropMap.plist		\
	Maps/MAPIPropIDMap.plist	\
	\
	Maps/AptBackendSets.plist	\
	\
	Maps/PersonalFolderInfo.plist	\

ZideStore_WEBSERVER_RESOURCE_FILES += \
	PrefsUI/English.lproj/*.gif 	\
	PrefsUI/English.lproj/*.jpg 	\
	PrefsUI/English.lproj/*.ico	\
	PrefsUI/English.lproj/*.css	\

# aggregate

SUBPROJECTS = \
	Backend		\
	Frontend	\
	Products	\
	\
	PrefsUI		\

# some products do not yet compile with Cocoa Foundation
ifneq ($(FOUNDATION_LIB),apple)

SUBPROJECTS += \
	EvoConnect	\
	WCAP		\
	RSS		\

endif

# make

-include ZLConnect.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
