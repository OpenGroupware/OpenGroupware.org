# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = OGo
BUNDLE_EXTENSION   = .model
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/

#ADDITIONAL_CPPFLAGS += -DUSE_EO_RECORDS=1

OGo_PRINCIPAL_CLASS = OGoModel

OGo_OBJC_FILES = \
	OGoModel.m	\
	LSEOObject.m	\
	LSDatabaseObject.m

OGo_SUBPROJECTS = Classes

MODELS = \
	OpenGroupware.org_FrontBase2.eomodel	\
	OpenGroupware.org_PostgreSQL.eomodel

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
