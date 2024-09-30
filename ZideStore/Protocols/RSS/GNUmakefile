# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

OGO_LIBDIR=${GNUSTEP_LIBRARY}
OGO_ZIDESTORE=${OGO_LIBDIR}/ZideStore-${MAJOR_VERSION}.${MINOR_VERSION}

BUNDLE_NAME        = RSS
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(OGO_ZIDESTORE)

RSS_PRINCIPAL_CLASS = RSSProduct

RSS_OBJC_FILES = \
	RSSProduct.m		\
	SxRSSRenderer.m		\
	SxRSSTaskRenderer.m	\
	SxTaskFolder+RSS.m	\
	SxFolder+RSS2.m \
	SxFolderRSS.m		\
	NSObject+SoRSSObject.m

RSS_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
