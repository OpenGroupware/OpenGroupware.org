# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = LDAPAccounts

LDAPAccounts_PRINCIPAL_CLASS = LDAPAccountsModule

LDAPAccounts_OBJC_FILES = \
	LDAPAccountsModule.m		\
	WelcomeNewLDAPAccount.m		\
	SkyGenericLDAPViewer.m		\
	NGLdapConnection+DNSearch.m	\

LDAPAccounts_COMPONENTS = \
	WelcomeNewLDAPAccount.wo	\
	SkyGenericLDAPViewer.wo		\

# resources

LDAPAccounts_RESOURCE_FILES += Defaults.plist Version
LDAPAccounts_LANGUAGES = English German

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
