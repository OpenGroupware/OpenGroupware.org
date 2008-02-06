# GNUstep makefile

include ../common.make

BUNDLE_NAME  = Contacts
LIBRARY_NAME = libZSContacts

Contacts_PRINCIPAL_CLASS = ContactsProduct
Contacts_OBJC_FILES      = Product.m

libZSContacts_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSContacts_INSTALL_DIR=$(OGO_SYSLIBDIR)
libZSContacts_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSContacts_OBJC_FILES = \
	SxAddress.m		\
	SxAddressFolder.m	\
	SxVCardContactRenderer.m\
	\
	SxEnterpriseFolder.m	\
	SxEnterprise.m		\
	SxVCardEnterpriseRenderer.m \
	\
	SxGroupsFolder.m	\
	SxGroup.m		\
	\
	SxPersonFolder.m	\
	SxGroupFolder.m		\
	SxPerson.m		\
	\
	SxVCardPersonRenderer.m	\
	\
	ZSPersonListEntryRenderer.m	\
	SxAddressFolder+ZL.m		\

Contacts_RESOURCE_FILES += 	\
	bundle-info.plist	\
	Version			\
	product.plist

BUNDLE_INSTALL_DIR = $(ZIDESTORE_WEBUIDIR)

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
