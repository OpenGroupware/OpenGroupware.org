# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOBUNDLE_NAME        = Publisher
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org/

TOOL_NAME = skypubd

# common stuff

COMMON_OBJC_FILES = \
	PubKeyValueCoding.m		\
	PubNodeRenderer.m		\
	SkyDocument+Pub2.m		\
	SkyDocument+Pub.m		\
	SkyDocument+PubJS.m		\
	SkyDocument+PubResponse.m	\
	SkyPubComponent+JS.m		\
	SkyPubComponent.m		\
	SkyPubComponentDefinition.m	\
	SkyPubDataSource.m		\
	SkyPubFileManager.m		\
	SkyPubLink.m			\
	SkyPubLinkManager.m		\
	SkyPubRequestHandler.m		\
	SkyPubResourceManager.m		\
	DOMNode+Pub.m			\

Publisher_PRINCIPAL_CLASS = SkyPublisherModule

Publisher_OBJC_FILES = \
	SkyPubInlineViewer.m		\
	SkyPubLinks.m			\
	SkyPubPartPreview.m		\
	SkyPubPartSourceViewer.m	\
	SkyPublisherModule.m		\
	SkyPubSourceRendering.m		\
	SkyPubPreviewRendering.m	\
	SkyPubLink+Activation.m		\
	SkyPubDirectAction.m		\
	SkyPubRendering.m		\
	$(COMMON_OBJC_FILES)		\

Publisher_COMPONENTS = \
	SkyPubLinks.wo			\
	SkyPubPartPreview.wo		\
	SkyPubPartSourceViewer.wo	\

Publisher_SUBPROJECTS += SKYOBJ_preview.subproj SKYOBJ.subproj

# resources

Publisher_RESOURCE_FILES += Defaults.plist Version
Publisher_LANGUAGES      =  English German

# skypubd

skypubd_OBJC_FILES = \
	skypubd.m			\
	SkyPubRendering.m		\
	$(COMMON_OBJC_FILES)		\

skypubd_SUBPROJECTS += SKYOBJ.subproj

# exporter

TOOL_NAME += skypubexport

skypubexport_OBJC_FILES = \
	skypubexport.m 			\
	SkyPubRendering.m		\
	$(COMMON_OBJC_FILES)		\

skypubexport_SUBPROJECTS += SKYOBJ.subproj

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
