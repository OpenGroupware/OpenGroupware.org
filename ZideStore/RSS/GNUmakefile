# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = RSS
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore12

RSS_PRINCIPAL_CLASS = RSSProduct

RSS_OBJC_FILES = \
	RSSProduct.m		\
	SxRSSRenderer.m		\
	SxRSSTaskRenderer.m	\
	SxTaskFolder+RSS.m	\

RSS_BUNDLE_LIBS += -lNGObjWeb

RSS_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

ADDITIONAL_INCLUDE_DIRS += \
	-I. -I../Products/Tasks -I..

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
