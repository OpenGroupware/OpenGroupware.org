# ZideStore makefile

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = ZideStore13

ZideStore13_OBJC_FILES += \
	ZideStore.m		\
	SxAuthenticator.m	\

ZideStore13_HEADER_FILES += \
	SxAuthenticator.h	\

ZideStore13_RESOURCE_FILES += \
	Version				\
	product.plist			\
	\
	../Maps/E2KAttrMap.plist	\
	../Maps/DAVPropSets.plist	\
	../Maps/MAPIPropMap.plist	\
	../Maps/MAPIPropIDMap.plist	\
	../Maps/AptBackendSets.plist	\
	../Maps/PersonalFolderInfo.plist

ZideStore13_WEBSERVER_RESOURCE_FILES += \
	../PrefsUI/English.lproj/*.gif 	\
	../PrefsUI/English.lproj/*.jpg 	\
	../PrefsUI/English.lproj/*.ico	\
	../PrefsUI/English.lproj/*.css	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
