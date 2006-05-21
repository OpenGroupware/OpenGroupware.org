# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libXmlSchema

libXmlSchema_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)
RESOURCES_DIR = $(GNUSTEP_INSTALLATION_DIR)/Libraries/Resources/XmlSchema

libXmlSchema_CPPFLAGS += -DRESOURCES_DIR="$(RESOURCES_DIR)"

libXmlSchema_HEADER_FILES_DIR         = .
libXmlSchema_HEADER_FILES_INSTALL_DIR = /XmlSchema

libXmlSchema_RESOURCES = \
	schemes/namespaces.plist		\
	schemes/XMLSchema-1999-datatypes.xsd	\
	schemes/XMLSchema-1999-instance.xsd	\
	schemes/XMLSchema-1999.xsd		\
	schemes/XMLSchema-2001-datatypes.xsd	\
	schemes/XMLSchema-2001-instance.xsd	\
	schemes/XMLSchema-2001.xsd		\

libXmlSchema_HEADER_FILES = \
	NSString+XML.h			\
	NSObject+XmlSchema.h		\
	NSObject+XmlSchemaCoding.h	\
	NSMutableString+EscStr.h	\
	\
	XmlSchemaTag.h			\
	XmlSchemaType.h			\
	XmlSchemaDerivator.h		\
	XmlSchemaContent.h		\
	\
	XmlSchema.h			\
	XmlSchemaProtocols.h		\
	XmlSchemaAnnotation.h		\
	XmlSchemaAppinfo.h		\
	XmlSchemaDocumentation.h	\
	XmlSchemaSimpleType.h		\
	XmlSchemaComplexType.h		\
	XmlSchemaAttribute.h		\
	XmlSchemaAttributeGroup.h	\
	XmlSchemaElement.h		\
	XmlSchemaGroup.h		\
	XmlSchemaRestriction.h		\
	XmlSchemaUnion.h		\
	XmlSchemaList.h			\
	XmlSchemaSequence.h		\
	XmlSchemaAll.h			\
	XmlSchemaChoice.h		\
	XmlSchemaSimpleContent.h	\
	XmlSchemaComplexContent.h	\
	XmlSchemaImport.h		\
	XmlSchemaInclude.h		\
	XmlSchemaRedefine.h		\
	\
	XmlSchemaCoder.h		\
	XmlSchemaSaxBuilder.h		\
	\
	XmlSchemaMapping.h		\
	XmlDefaultClassSchemaMapping.h	\
	XmlClassGenerator.h		\

libXmlSchema_OBJC_FILES = \
	NSString+XML.m			\
	NSMutableString+EscStr.m	\
	NSObject+XmlSchema.m		\
	NSObject+XmlSchemaCoding.m	\
	\
	XmlSchemaTag.m			\
	XmlSchemaType.m			\
	XmlSchemaDerivator.m		\
	XmlSchemaContent.m		\
	\
	XmlSchema.m			\
	XmlSchemaAnnotation.m		\
	XmlSchemaAppinfo.m		\
	XmlSchemaDocumentation.m	\
	XmlSchemaSimpleType.m		\
	XmlSchemaComplexType.m		\
	XmlSchemaAttribute.m		\
	XmlSchemaAttributeGroup.m	\
	XmlSchemaElement.m		\
	XmlSchemaGroup.m		\
	XmlSchemaRestriction.m		\
	XmlSchemaUnion.m		\
	XmlSchemaList.m			\
	XmlSchemaSequence.m		\
	XmlSchemaAll.m			\
	XmlSchemaChoice.m		\
	XmlSchemaSimpleContent.m	\
	XmlSchemaComplexContent.m	\
	XmlSchemaImport.m		\
	XmlSchemaInclude.m		\
	XmlSchemaRedefine.m		\
	\
	XmlSchemaSaxBuilder.m		\
	XmlSchemaEncoder.m		\
	\
	XmlSchemaMapping.m		\
	XmlDefaultClassSchemaMapping.m	\
	XmlSchemaDecoder.m		\
	XmlSchemaClassDescription.m	\
	XmlClassGenerator.m		\

TOOL_NAME = createSchemaClasses xschema

createSchemaClasses_OBJC_FILES = createSchemaClasses.m

xschema_OBJC_FILES = xschema.m

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
include ../fhslib.make
include ../fhstool.make
