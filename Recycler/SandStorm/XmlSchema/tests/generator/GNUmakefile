# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = testClassGenerator

person_XMLSCHEMA = person.xsd

config_XMLSCHEMA = config.xsd

Person.h Person.m Address.h Address.m : $(person_XMLSCHEMA)
	@(createSchemaClasses $(person_XMLSCHEMA))

SkyTaskTemplate.h SkyTaskTemplate.m : $(config_XMLSCHEMA)
	@(createSchemaClasses $(config_XMLSCHEMA) Sky)

testClassGenerator.m : Person.h Address.h SkyTaskTemplate.h

testClassGenerator_OBJC_FILES = \
	testClassGenerator.m	\
	Person.m		\
	Address.m		\
	Person+Logic.m		\
	Address+Logic.m		\
	\
	SkyTaskTemplate.m	\
	SkyMasterConfig.m	\
	SkyDefaultEntry.m	\

ADDITIONAL_TOOL_LIBS += -lXmlSchema -lEOControl

include $(GNUSTEP_MAKEFILES)/tool.make

remove-schema-classes:
	@(rm 			\
	Person.h 		\
	Person.m 		\
	Address.h 		\
	Address.m		\
	SkyTaskTemplate.h	\
	SkyTaskTemplate.m	\
	SkyDefaultEntry.h	\
	SkyDefaultEntry.m	\
	SkyMasterConfig.h	\
	SkyMasterConfig.m)
