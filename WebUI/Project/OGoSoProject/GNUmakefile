# GNUstep makefile

include ../common.make

WOBUNDLE_NAME        = OGoSoProject
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/WebUI/

OGoSoProject_PRINCIPAL_CLASS = OGoSoProjectModule

OGoSoProject_OBJC_FILES = \
	OGoSoProjectModule.m	\
	\
	OGoSoIdObject.m		\
	OGoSoProjects.m		\
	OGoSoProject.m		\
	OGoSoDocFolder.m	\

OGoSoProject_RESOURCE_FILES += \
	Defaults.plist	\
	Version		\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
include ../../fhsbundle.make
