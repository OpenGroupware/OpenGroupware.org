# GNUstep makefile

include ../common.make

BUNDLE_NAME = ZSCommon

ZSCommon_PRINCIPAL_CLASS = CommonProduct
ZSCommon_OBJC_FILES      = Product.m

ZSCommon_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
