# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME        = ProjectsUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/ZideStore12

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
