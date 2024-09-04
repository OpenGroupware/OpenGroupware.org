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
	-I.. -I$(WebUIROOT)\
	-I$(OGoROOT)/Logic


ADDITIONAL_LIB_DIRS     += 					\
	-L$(WebUIROOT)/OGoFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$/$(GNUSTEP_OBJ_DIR) \
	-L$(OGoROOT)/Logic/LSSearch/$(GNUSTEP_OBJ_DIR)		\
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

BUNDLE_LIBS += \
        -lOGoFoundation -lOGoDocuments \
        -lLSFoundation -lLSSearch \
	-lGDLAccess		\
        -lNGObjWeb      	\
        -lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
        -lXmlRpc

ADDITIONAL_BUNDLE_LIBS += $(BUNDLE_LIBS)

ADDITIONAL_CPPFLAGS += -Wall

SYSTEM_LIB_DIR += $(CONFIGURE_SYSTEM_LIB_DIR)
