# $Id$

OGoROOT=..

include $(GNUSTEP_MAKEFILES)/common.make
include ../Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

ADDITIONAL_INCLUDE_DIRS += \
	-I.. 			\
	-I../../Logic		\
	-I../../DocumentAPI

ADDITIONAL_LIB_DIRS += \
	-L../OGoFoundation/$(GNUSTEP_OBJ_DIR)			\
	-L../../DocumentAPI/OGoDocuments/$(GNUSTEP_OBJ_DIR)	\
	-L../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L/usr/local/lib -L/usr/lib

ADDITIONAL_BUNDLE_LIBS += \
	-lOGoFoundation -lOGoDocuments	\
	-lLSFoundation		\
	-lGDLAccess		\
	-lNGObjWeb		\
	-lNGLdap -lNGMime	\
	-lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_CPPFLAGS += -Wall -pipe -Wno-protocol
