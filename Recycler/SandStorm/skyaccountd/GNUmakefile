# $Id$

include ../common.make

BUNDLE_NAME = SkyAccount
TOOL_NAME   = skyaccountd

SkyAccount_PRINCIPAL_CLASS = SkyAccountAction

skyaccountd_OBJC_FILES = skyaccountd.m

SkyAccount_OBJC_FILES = \
	SkyAccountAction.m	\
	DirectAction+Group.m	\
	DirectAction+Account.m	\
	SkyAccountApplication.m	\
	OGoContextManager+SkyAccountd.m	\

SkyAccount_RESOURCE_FILES += \
	Version				\
	INTERFACE.xml			\
	SkyAccountActionMap.plist	\

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
