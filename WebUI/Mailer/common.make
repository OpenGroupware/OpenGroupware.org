# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. -I../..			\
	-I../../../Logic/LSFoundation	\


ADDITIONAL_LIB_DIRS     += 					\
	-L../../OGoFoundation/$(GNUSTEP_OBJ_DIR)		\
	-L../../../Logic/LSFoundation/$(GNUSTEP_OBJ_DIR)	\

BUNDLE_LIBS += \
        -lOGoFoundation -lOGoDocuments \
        -lLSFoundation -lLSSearch \
	-lGDLAccess	\
        -lNGObjWeb      \
        -lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl \
        -lXmlRpc

ADDITIONAL_BUNDLE_LIBS += $(BUNDLE_LIBS)

ADDITIONAL_CPPFLAGS += -Wall

ifeq ($(FOUNDATION_LIB),nx)
ADDITIONAL_LDFLAGS += -framework Foundation
endif
