# $Id$

OGoROOT  =../../..
WebUIROOT=../..

include $(GNUSTEP_MAKEFILES)/common.make
include $(WebUIROOT)/Version

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org
WOBUNDLE_EXTENSION   = .lso

SCHEDULER_LIBS += \
	-lOGoScheduler -lOGoSchedulerTools \
	-lOGoFoundation	-lOGoDocuments \
	-lLSFoundation	\
	-lGDLAccess	\
	-lNGObjWeb	\
	-lNGLdap -lNGMime -lNGStreams -lNGExtensions -lEOControl \
	-lXmlRpc

ADDITIONAL_INCLUDE_DIRS += 		\
	-I.. -I../..			\
	-I../../../Logic/LSFoundation	\
	-I../../../DocumentAPI		\

ADDITIONAL_LIB_DIRS     += -L../../OGoFoundation/$(GNUSTEP_OBJ_DIR)

#ADDITIONAL_WOBUNDLE_LIBS += $(SCHEDULER_LIBS)
ADDITIONAL_BUNDLE_LIBS += $(SCHEDULER_LIBS)

ADDITIONAL_CPPFLAGS += -Wall

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
