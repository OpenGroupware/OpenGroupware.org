# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = EvoConnect
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore12

EvoConnect_PRINCIPAL_CLASS = EvoConnectProduct

EvoConnect_OBJC_FILES = \
	EvoConnectProduct.m	\
	SxOptionsForm.m		\

EvoConnect_RESOURCE_FILES += \
	Version			\
	product.plist		\

EvoConnect_SUBPROJECTS += Contacts Appointments

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
