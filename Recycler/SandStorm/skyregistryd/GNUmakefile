# $Id$

include ../common.make

TOOL_NAME   = skyregistryd
BUNDLE_NAME = SkyRegistry

SkyRegistry_RESOURCE_FILES += \
	Version				\
	INTERFACE.xml			\
	SkyRegistryActionMap.plist	\

SkyRegistry_OBJC_FILES = \
	RegistryEntry.m				\
	SkyRegistryAction.m			\
	SkyRegistryAction+Authorization.m	\
	SkyRegistryAction+Introspection.m	\
	SkyRegistryAction+PrivateMethods.m	\
	SkyRegistryApplication.m		\
	SkyRegistryApplication+PrivateMethods.m	\
						\
	SkyIDLTag+XmlRpcType.m			\
	NSObject+URLConversion.m		\

skyregistryd_OBJC_FILES = skyregistryd.m

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
