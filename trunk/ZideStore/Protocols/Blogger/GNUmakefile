# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = Blogger
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

Blogger_PRINCIPAL_CLASS = BloggerProduct

Blogger_OBJC_FILES = \
	BloggerProduct.m		\
	\
	NSObject+Blogger.m		\
	\
	BloggerAction.m			\
	BloggerGetUserBlogs.m		\
	BloggerGetUserInfo.m		\
	BloggerGetTemplate.m		\
	\
	MetaWeblogAction.m		\
	MetaWeblogGetRecentPosts.m	\
	MetaWeblogPost.m		\
	\
	MovableTypeAction.m		\

Blogger_RESOURCE_FILES += \
	Version			\
	product.plist		\

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
