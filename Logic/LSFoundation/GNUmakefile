# GNUstep makefile

include ../../config.make
include ../common.make
include ./Version

LIBRARY_NAME = libLSFoundation

libLSFoundation_PCH_FILE = common.h
libLSFoundation_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libLSFoundation_INSTALL_DIR=$(OGO_SYSLIBDIR)
libLSFoundation_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)
libLSFoundation_DLL_DEF = libLSFoundation.def

libLSFoundation_HEADER_FILES = \
	LSArrayFilterCommand.h		\
	LSBaseCommand.h			\
	LSCommand.h			\
	LSCommandContext.h		\
	LSCommandFactory.h		\
	LSCommandKeys.h			\
	LSDBArrayFilterCommand.h	\
	LSDBFetchRelationCommand.h	\
	LSDBObjectBaseCommand.h		\
	LSDBObjectCommandException.h	\
	LSDBObjectDeleteCommand.h	\
	LSDBObjectGetCommand.h		\
	LSDBObjectNewCommand.h		\
	LSDBObjectNewKeyCommand.h	\
	LSDBObjectSetCommand.h		\
	LSDBObjectTransactionCommand.h	\
        LSGetAsRSSFeedCommand.h		\
	LSDBTransaction.h		\
	LSFoundation.h			\
	LSMail.h			\
	LSModuleManager.h		\
	LSSort.h			\
	LSSortCommand.h			\
	LSTypeManager.h			\
	EODatabaseChannel+LSAdditions.h	\
	LSGetObjectForGlobalIDs.h	\
	SkyObjectPropertyManager.h	\
	\
	LSBundleCmdFactory.h		\
	OGoContextManager.h		\
	OGoContextSession.h		\
	NSObject+Commands.h		\
	SkyAttributeDataSource.h	\
	SkyAccessManager.h		\
	OGoAccessManager.h		\
	OGoAccessHandler.h		\
	SkyAccessHandler.h		\
	OGoObjectLink.h			\
	OGoObjectLinkManager.h		\
	NGBundleManager+OGo.h		\
	\
	EOSQLQualifier+LS.h		\

libLSFoundation_OBJC_FILES = \
	LSArrayFilterCommand.m			\
	LSBaseCommand.m				\
	LSCommandContext.m			\
	LSCommandContext+Login.m		\
	LSCommandContext+Init.m			\
	LSDBArrayFilterCommand.m		\
	LSDBFetchRelationCommand.m		\
	LSDBObjectBaseCommand.m			\
	LSDBObjectCommandException.m		\
	LSDBObjectDeleteCommand.m		\
	LSDBObjectGetCommand.m			\
	LSDBObjectNewCommand.m			\
	LSDBObjectNewKeyCommand.m		\
	LSDBObjectSetCommand.m			\
	LSDBObjectTransactionCommand.m		\
	LSGetAsRSSFeedCommand.m			\
	LSDBTransaction.m			\
	LSMail.m				\
	LSModuleManager.m			\
	LSSort.m				\
	LSSortCommand.m				\
	LSTypeManager.m				\
	EODatabaseChannel+LSAdditions.m		\
	LSGetObjectForGlobalIDs.m		\
	SkyObjectPropertyManager.m		\
	SkyObjectPropertyManagerHandler.m	\
	SkyObjectPropertyManager+Internals.m	\
	LSBundleCmdFactory.m			\
	OGoContextManager.m			\
	OGoContextManager+LDAP.m		\
	OGoContextManager+FailedLogin.m		\
	OGoContextSession.m			\
	NSObject+Commands.m			\
	SkyAttributeDataSource.m		\
	SkyAttributeDataSource+Internals.m	\
	OGoAccessManager.m			\
	OGoAccessHandler.m			\
	SkyPropertyValues.m			\
	OGoObjectLink.m				\
	OGoObjectLinkManager.m			\
	NGBundleManager+OGo.m			\
	\
	EOSQLQualifier+LS.m			\

libLSFoundation_INCLUDE_DIRS             = -ILSFoundation
libLSFoundation_HEADER_FILES_DIR         = .
libLSFoundation_HEADER_FILES_INSTALL_DIR = /LSFoundation

TOOL_NAME = load-LSModel

load-LSModel_OBJC_FILES = load-LSModel.m

load-LSModel_INSTALL_DIR = $(OGO_TOOLS)

# set compile flags and go

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
