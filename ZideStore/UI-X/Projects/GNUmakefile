# GNUstep makefile

include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = ProjectsUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

ProjectsUI_PRINCIPAL_CLASS = ProjectsUIProduct

ProjectsUI_OBJC_FILES = \
	ProjectsUIProduct.m	\
	OGoProjectView.m	\
	\
	OGoProjectsOverview.m	\
	OGoProjectOverview.m	\
	OGoDocFolderView.m	\
	OGoDocumentView.m	\

ProjectsUI_RESOURCE_FILES += \
	Version			\
	product.plist		\
	\
	blog.css		\
	OGoProjectsOverview.wox	\
	OGoProjectOverview.wox	\
	OGoDocFolderView.wox	\
	OGoDocumentView.wox	\

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
