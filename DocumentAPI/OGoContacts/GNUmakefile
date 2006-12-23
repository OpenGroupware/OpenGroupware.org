# GNUstep makefile

-include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME       = libOGoContacts
BUNDLE_NAME        = OGoContacts
BUNDLE_EXTENSION   = .ds

libOGoContacts_PCH_FILE = common.h
OGoContacts_PCH_FILE = common.h

libOGoContacts_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoContacts_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoContacts_HEADER_FILES = \
	SkyAddressConverterDataSource.h 		\
	SkyAddressDocument.h				\
	SkyCompanyDataSource.h				\
	SkyCompanyDocument.h				\
	SkyCompanyProjectDataSource.h			\
	SkyContactAddressDataSource.h			\
	SkyEnterpriseDataSource.h			\
	SkyEnterpriseDocument.h				\
	SkyEnterprisePersonDataSource.h			\
	SkyEnterpriseProjectDataSource.h		\
	SkyPersonDataSource.h				\
	SkyPersonDocument.h				\
	SkyPersonEnterpriseDataSource.h			\
	SkyPersonProjectDataSource.h			\

libOGoContacts_OBJC_FILES = \
	SkyAddressConverterDataSource.m 		\
	SkyAddressDocument.m				\
	SkyCompanyCompanyDataSource.m			\
	SkyCompanyDataSource.m				\
	SkyCompanyDocument.m				\
	SkyCompanyProjectDataSource.m			\
	SkyContactAddressDataSource.m			\
	SkyEnterpriseAllProjectsDataSource.m		\
	SkyEnterpriseDataSource.m			\
	SkyEnterpriseDocument.m				\
	SkyEnterprisePersonDataSource.m			\
	SkyEnterpriseProjectDataSource.m		\
	SkyPersonDataSource.m				\
	SkyPersonDocument+JobDS.m			\
	SkyPersonDocument.m 				\
	SkyPersonEnterpriseDataSource.m			\
	SkyPersonProjectDataSource.m			\

libOGoContacts_HEADER_FILES_DIR         = .
libOGoContacts_HEADER_FILES_INSTALL_DIR = /OGoContacts
FHS_HEADER_DIRS = OGoContacts

OGoContacts_PRINCIPAL_CLASS = SkyContactsBundleManager

OGoContacts_OBJC_FILES += SkyContactsBundleManager.m

OGoContacts_RESOURCE_FILES += Defaults.plist

# test tools

ifeq ($(tests),yes)
TOOL_NAME = test_ogocds test_ogocds_addrfetch
endif

test_ogocds_OBJC_FILES           += test_ogocds.m
test_ogocds_addrfetch_OBJC_FILES += test_ogocds_addrfetch.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include ../fhslib.make
