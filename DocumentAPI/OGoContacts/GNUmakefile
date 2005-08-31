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
	SkyPersonDataSource.h				\
	SkyAddressConverterDataSource.h 		\
	SkyPersonAddressConverterDataSource.h		\
	SkyPersonDocument.h				\
	SkyAddressDocument.h				\
	SkyEnterpriseDataSource.h			\
	SkyEnterpriseAddressConverterDataSource.h 	\
	SkyCompanyDocument.h				\
	SkyEnterpriseDocument.h				\
	SkyCompanyDataSource.h				\
	SkyPersonProjectDataSource.h			\
	SkyEnterpriseProjectDataSource.h		\
	SkyPersonEnterpriseDataSource.h			\
	SkyEnterprisePersonDataSource.h			\
	SkyContactAddressDataSource.h			\
	SkyCompanyProjectDataSource.h			\

libOGoContacts_OBJC_FILES = \
	SkyPersonDataSource.m				\
	SkyAddressConverterDataSource.m 		\
	SkyPersonAddressConverterDataSource.m		\
	SkyCompanyDocument.m				\
	SkyPersonDocument.m 				\
	SkyAddressDocument.m				\
	SkyPersonDocument+JS.m 				\
	SkyAddressDocument+JS.m				\
	SkyCompanyDocument+JS.m				\
	SkyEnterpriseDataSource.m			\
	SkyEnterpriseAddressConverterDataSource.m	\
	SkyEnterpriseDocument.m				\
	SkyCompanyDataSource.m				\
	SkyCompanyCompanyDataSource.m			\
	SkyCompanyProjectDataSource.m			\
	SkyPersonProjectDataSource.m			\
	SkyEnterpriseProjectDataSource.m		\
	SkyPersonEnterpriseDataSource.m			\
	SkyEnterprisePersonDataSource.m			\
	SkyEnterpriseDocument+JS.m			\
	SkyPersonDocument+JobDS.m			\
	SkyContactAddressDataSource.m			\
	SkyEnterpriseAllProjectsDataSource.m		\

libOGoContacts_HEADER_FILES_DIR         = .
libOGoContacts_HEADER_FILES_INSTALL_DIR = /OGoContacts
FHS_HEADER_DIRS = OGoContacts

OGoContacts_PRINCIPAL_CLASS = SkyContactsBundleManager

OGoContacts_OBJC_FILES = 	\
	SkyContactsBundleManager.m \
	SkyContactsAccessHandler.m \

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
