# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

BUNDLE_NAME = Contacts

Contacts_PRINCIPAL_CLASS = ContactsProduct

Contacts_OBJC_FILES = \
	Product.m		\
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

Contacts_RESOURCE_FILES += 	\
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
