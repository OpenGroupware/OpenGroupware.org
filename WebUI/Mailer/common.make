# $Id$

OGoROOT  =../../..
WebUIROOT=../..

include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org-1.0a/WebUI/

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. -I$(WebUIROOT)		\
	-I$(OGoROOT)/Logic/LSFoundation


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

ADDITIONAL_LIB_DIRS += -L/usr/local/lib -L/usr/lib
