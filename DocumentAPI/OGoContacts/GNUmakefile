# $Id$

include ../common.make
include ./Version

LIBRARY_NAME       = libOGoContacts
BUNDLE_NAME        = OGoContacts
BUNDLE_EXTENSION   = .ds

libOGoContacts_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

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

OGoContacts_PRINCIPAL_CLASS = SkyContactsBundleManager

OGoContacts_OBJC_FILES = 	\
	SkyContactsBundleManager.m \
	SkyContactsAccessHandler.m \

OGoContacts_RESOURCE_FILES += Defaults.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-OGoContacts-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  $(LN_S) -f ../bundle-info.plist .)
