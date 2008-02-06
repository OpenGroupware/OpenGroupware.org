# GNUstep makefile

include ../common.make

BUNDLE_NAME  = AptResources
LIBRARY_NAME = libZSResources

AptResources_PRINCIPAL_CLASS = ZSResourcesProduct
AptResources_OBJC_FILES      = Product.m

libZSResources_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSResources_INSTALL_DIR=$(OGO_SYSLIBDIR)
libZSResources_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSResources_OBJC_FILES += \
	SxResourceGroupsFolder.m\
	SxResourceGroupFolder.m	\
	SxResource.m		\

AptResources_RESOURCE_FILES += 	\
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
