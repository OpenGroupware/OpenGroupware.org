# GNUstep makefile

OGoROOT   =../../..
WebUIROOT =../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

# hh: 2024-09-04
OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_WEBUIS=${OGO_LIBDIR}/WebUI-${MAJOR_VERSION}.${MINOR_VERSION}
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_INSTALL_DIR = $(OGO_WEBUIS)
WOBUNDLE_EXTENSION   = .lso

ADDITIONAL_INCLUDE_DIRS += \
	-I.. -I../..		\
	-I../../../Logic/	\
	-I../../../DocumentAPI/

ADDITIONAL_LIB_DIRS     += \
	-L../../OGoFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L../../../DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR)	\
	-L../../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)	\
	-L../../../Logic/LSSearch/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation -lOGoDocuments \
	-lGDLAccess		\
	-lNGObjWeb		\
	-lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
