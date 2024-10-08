# GNUstep makefile

OGoROOT  =../../..
WebUIROOT=../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

# hh: 2024-09-04
OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_WEBUIS=${OGO_LIBDIR}/WebUI-${MAJOR_VERSION}.${MINOR_VERSION}
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(OGO_WEBUIS)
#WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-5.5/WebUI/

ADDITIONAL_INCLUDE_DIRS += \
	-I.. -I../..		\
	-I$(OGoROOT)/Logic	\
	-I$(OGoROOT)/DocumentAPI

ADDITIONAL_LIB_DIRS     += 					\
	-L$(WebUIROOT)/OGoFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L$(OGoROOT)/DocumentAPI/OGoProject/$(GNUSTEP_OBJ_DIR)   \
	-L$(OGoROOT)/DocumentAPI/OGoAccounts/$(GNUSTEP_OBJ_DIR)  \
	-L$(OGoROOT)/DocumentAPI/OGoBase/$(GNUSTEP_OBJ_DIR)	 \
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation -lOGoDocuments \
	-lLSFoundation	\
	-lGDLAccess	\
	-lNGObjWeb	\
	-lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc -lDOM -lSaxObjC

ADDITIONAL_WOBUNDLE_LIBS += $(ADDITIONAL_BUNDLE_LIBS)

ADDITIONAL_CPPFLAGS += -Wno-protocol -Wall

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
LSWAddress_BUNDLE_LIBS += \
	-lNGMime \
	-lNGStreams -lNGExtensions -lEOControl \
	-lFoundation -lobjc
endif

ifeq ($(FOUNDATION_LIB),nx)
BUNDLE_LIBS += -lFoundationExt
ADDITIONAL_LDFLAGS += -framework Foundation
endif

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
