# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = LDAPAccounts

LDAPAccounts_PRINCIPAL_CLASS = LDAPAccountsModule

LDAPAccounts_OBJC_FILES = \
	LDAPAccountsModule.m		\
	WelcomeNewLDAPAccount.m		\
	SkyGenericLDAPViewer.m		\
	NGLdapConnection+DNSearch.m	\

# resources

LDAPAccounts_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
