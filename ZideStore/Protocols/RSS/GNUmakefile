# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = RSS
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore-1.3

RSS_PRINCIPAL_CLASS = RSSProduct

RSS_OBJC_FILES = \
	RSSProduct.m		\
	SxRSSRenderer.m		\
	SxRSSTaskRenderer.m	\
	SxTaskFolder+RSS.m	\

RSS_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
