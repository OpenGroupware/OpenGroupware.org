# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = EvoConnect
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

EvoConnect_PRINCIPAL_CLASS = EvoConnectProduct

EvoConnect_OBJC_FILES = \
	EvoConnectProduct.m	\
	SxOptionsForm.m		\
	\
	SxEvoAptQueryInfo.m		\
	SxAppointmentFolder+Evo.m	\
	\
	SxEvoContactQueryInfo.m		\
	SxEvoContactRenderer.m		\
	SxEvoFullContactParser.m	\
	SxEvoEnterpriseRenderer.m	\
	SxEvoFullEnterpriseParser.m	\
	SxEvoGroupRenderer.m		\
	SxEvoPersonRenderer.m		\
	SxEvoFullPersonParser.m		\
	\
	SxAddressFolder+Evo.m		\

EvoConnect_RESOURCE_FILES += \
	Version			\
	product.plist		\

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
