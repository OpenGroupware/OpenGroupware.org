# $Id$

include ../common.make
include ./Version

LIBRARY_NAME       = libOGoAccounts
BUNDLE_NAME        = OGoAccounts
BUNDLE_EXTENSION   = .ds

libOGoAccounts_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libOGoAccounts_HEADER_FILES = \
	SkyAccountDataSource.h				\
	SkyAccountDocument.h				\
	SkyTeamDataSource.h				\
	SkyTeamDocument.h				\
	SkyMemberDataSource.h				\
	SkyAccountTeamsDataSource.h			\

libOGoAccounts_OBJC_FILES = \
	SkyAccountDataSource.m				\
	SkyAccountDocument.m				\
	SkyTeamDataSource.m				\
	SkyTeamDocument.m				\
	SkyMemberDataSource.m				\
	SkyAccountTeamsDataSource.m			\

libOGoAccounts_HEADER_FILES_DIR         = .
libOGoAccounts_HEADER_FILES_INSTALL_DIR = /OGoAccounts

OGoAccounts_PRINCIPAL_CLASS = SkyAccountsBundleManager
OGoAccounts_OBJC_FILES = SkyAccountsBundleManager.m

OGoAccounts_LIB_DIRS       += -L./$(GNUSTEP_OBJ_DIR)
OGoAccounts_BUNDLE_LIBS    += -lOGoAccounts
OGoAccounts_RESOURCE_FILES += Defaults.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-OGoAccounts-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
