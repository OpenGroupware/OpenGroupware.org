# GNUstep makefile

OGoROOT=../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

ADDITIONAL_INCLUDE_DIRS += \
	-I.. 			\
	-I$(OGoROOT)/Logic		\
	-I$(OGoROOT)/DocumentAPI

ADDITIONAL_LIB_DIRS += \
	-L../OGoFoundation/$(GNUSTEP_OBJ_DIR)			\
	-L$(OGoROOT)/DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR)\
	-L$(OGoROOT)/Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)

SYSTEM_LIB_DIR += -L/usr/local/lib -L/usr/lib

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation -lOGoDocuments	\
	-lLSFoundation		\
	-lGDLAccess		\
	-lNGObjWeb		\
	-lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
