# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_ZIDESTORE=${OGO_LIBDIR}/ZideStore-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_NAME        = EvoConnect
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(OGO_ZIDESTORE)

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
