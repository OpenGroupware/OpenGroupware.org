# $Id$

include ../common.make

BUNDLE_NAME = SkyMaster
TOOL_NAME = skymasterd

# XML Schema

XMLSCHEMA = skymasterd-config.xsd

GENFILES = 			\
	SkyMasterConfig.m 	\
	TaskTemplate.m 		\
	DefaultEntry.m		\
	AutostartConfig.m	\
	AutostartInstance.m	\

$(GENFILES) : $(XMLSCHEMA)
	@(createSchemaClasses skymasterd-config.xsd)

# Sources

SkyMaster_RESOURCE_FILES += \
	Version			\
	INTERFACE.xml		\
	skymasterd-config.xsd	\
	SkyMasterActionMap.plist

skymasterd_OBJC_FILES = skymasterd.m

SkyMaster_OBJC_FILES =			\
	SkyMasterApplication.m		\
	SkyMasterAction.m		\
					\
	SkyMasterConfig.m		\
	TaskTemplate.m			\
	DefaultEntry.m			\
	AutostartConfig.m		\
	AutostartInstance.m		\
					\
	TaskTemplate+Logic.m		\
	AutostartInstance+Logic.m	\
					\
	MasterTask.m			\
	DaemonTask.m			\
	ApacheTask.m			\
	RegistryTask.m			\

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
