# $Id$

include ../common.make

TOOL_NAME = skycontactd
BUNDLE_NAME = SkyContact

SkyContact_PRINCIPAL_CLASS = SkyContactAction

SkyContact_RESOURCE_FILES = \
	Version				\
	INTERFACE-Contacts.xml		\
	INTERFACE-Enterprises.xml	\
	SkyContactActionMap.plist	\

SkyContact_OBJC_FILES = \
	SkyContactApplication.m			\
	SkyContactAction.m			\
	SkyContactAction+Caching.m		\
	SkyContactAction+PrivateMethods.m	\
	SkyContactAction+Conversion.m		\
	SkyContactAction+QueryMethods.m		\

skycontactd_OBJC_FILES = \
	skycontactd.m				\

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
