# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = OGo
BUNDLE_EXTENSION   = .model
BUNDLE_INSTALL_DIR = $(GNUSTEP_LOCAL_ROOT)/Library/OpenGroupware.org

#ADDITIONAL_CPPFLAGS += -DUSE_EO_RECORDS=1

OGo_OBJC_FILES = \
	LSEOObject.m			\
	LSDatabaseObject.m		\

OGo_SUBPROJECTS = Classes

MODELS = \
	OpenGroupware.org_FrontBase2.eomodel	\
	OpenGroupware.org_PostgreSQL.eomodel	\

OGo_RESOURCE_FILES += Version $(MODELS)

-include GNUmakefile.preamble

OGo_INCLUDE_DIRS = -IHeaders

include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
