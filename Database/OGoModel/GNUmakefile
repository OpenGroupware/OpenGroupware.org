# GNUstep makefile

OGoROOT=../..

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include $(OGoROOT)/Version
include ./Version

# hh: 2024-09-04
OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_MODELS=${OGO_LIBDIR}/Models-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_NAME        = OGo
BUNDLE_EXTENSION   = .model
BUNDLE_INSTALL_DIR = $(OGO_MODELS)

#ADDITIONAL_CPPFLAGS += -DUSE_EO_RECORDS=1

OGo_PRINCIPAL_CLASS = OGoModel

OGo_OBJC_FILES = \
	OGoModel.m	\
	LSEOObject.m	\
	LSDatabaseObject.m

OGo_SUBPROJECTS = Classes

MODELS = \
	OpenGroupware.org_FrontBase2.eomodel	\
	OpenGroupware.org_PostgreSQL.eomodel	\
	OpenGroupware.org_MySQL5.eomodel

CREATE_SCRIPTS = \
	../PostgreSQL/pg-build-schema.psql		\
	../PostgreSQL/pg-build-schema.psql.constraints	\
	../PostgreSQL/pg-update-schema.psql

OGo_RESOURCE_FILES += Version $(MODELS) $(CREATE_SCRIPTS)

-include GNUmakefile.preamble

OGo_INCLUDE_DIRS = -IHeaders

include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include fhs.make
