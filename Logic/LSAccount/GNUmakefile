# GNUstep makefile

-include ../../config.make
include ../common.make

COMMAND_BUNDLE = LSAccount

LSAccount_PCH_FILE = common.h
LSAccount_OBJC_FILES = \
	LSNewAccountCommand.m              	\
	LSSetAccountCommand.m              	\
	LSGetAccountByLoginCommand.m       	\
	LSGetTeamForAccountCommand.m       	\
	LSLoginAccountCommand.m			\
	LSGetAccountCommand.m              	\
	LSExtendedSearchAccountCommand.m	\
	LSDeleteAccountCommand.m		\
	LSGetAccountsForGlobalIDsCommand.m	\
	LSAccountToPersonCommand.m		\
	LSChangePasswordCommand.m		\

LSAccount_RESOURCE_FILES += Defaults.plist Version

LSAccount_INCLUDE_DIRS = -IHeaders -I../LSAddress/Headers

LSAccount_BUNDLE_LIBS += -lLSSearch -lLSAddress -lNGLdap

LSAccount_LIB_DIRS    += -L../LSSearch/$(GNUSTEP_OBJ_DIR) -L../LSAddress/$(GNUSTEP_OBJ_DIR)

include ../commandbundle.make
