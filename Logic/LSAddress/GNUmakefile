# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make
include ./Version

COMMAND_BUNDLE = LSAddress
LIBRARY_NAME   = libLSAddress

libLSAddress_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libLSAddress_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libLSAddress_OBJC_FILES = \
	LSNewCompanyCommand.m              	\
	LSSetCompanyCommand.m              	\
	LSDeleteCompanyCommand.m           	\
	LSGetMemberForCompanyCommand.m     	\
	LSGetCompanyForMemberCommand.m     	\
	LSProjectsToCompanyAssignmentCommand.m	\
	LSGetCompanyCommand.m			\
	LSNewTelephoneCommand.m			\
	LSGetVCardForGlobalIDsCommand.m	 	\

LSAddress_OBJC_FILES = \
	LSGetStaffForGlobalIDsCommand.m		\
	LSUserDefaults.m			\
	_NSUserDefaults.m			\
	LSCheckLoginCommand.m              	\
	LSSetCategoriesCommand.m            	\
	LSSetResourcesCommand.m             	\
	LSRegisterUserDefaultsCommand.m		\
	LSWriteUserDefaultsCommand.m		\
	LSUserDefaultsFunctions.m		\
	LSGetUserDefaultsCommand.m		\
	LSChangeLoginStatusCommand.m		\
	LSFetchExtendedAttributesCommand.m	\
	LSSetAddressCommand.m			\
	LSAddressFetchAttributesCommand.m	\
	LSAddressConverterCommand.m		\
	LSBuildConverterDataCommand.m		\
	LSGroupToMemberAssignmentCommand.m 	\
	LSMemberToGroupAssignmentCommand.m 	\
	LSQueryCompanyValues.m              	\

LSAddress_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include ../commandbundle.make
-include GNUmakefile.postamble
-include fhs.make
