# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = SkyRegistryBrowser

SkyRegistryBrowser_OBJC_FILES = \
	Application.m		\
	Session.m		\
	Main.m			\
	Frame.m			\
	RunMethod.m		\
	ShowValue.m		\
	ShowStructValue.m	\
	ShowArrayValue.m	\
	EnterValue.m		\
	ComponentList.m		\
	ComponentElement.m	\
	RelatedMethods.m	\
	LoginPanel.m		\

SkyRegistryBrowser_RESOURCE_FILES += \
	Version			\
	Main.wox		\
	Frame.wox		\
	RunMethod.wox		\
	ShowValue.wox		\
	ShowStructValue.wox	\
	ShowArrayValue.wox	\
	EnterValue.wox		\
	RelatedMethods.wox	\
	LoginPanel.wox		\

SkyRegistryBrowser_WEBSERVER_RESOURCE_FILES = \
	WebServerResources/skyrix_logo.gif        \
	WebServerResources/treeview_space.gif        \
	WebServerResources/treeview_line.gif         \
	WebServerResources/treeview_plus.gif         \
	WebServerResources/treeview_minus.gif        \
	WebServerResources/treeview_corner_plus.gif  \
	WebServerResources/treeview_corner_minus.gif \
	WebServerResources/treeview_leaf.gif         \
	WebServerResources/treeview_leaf_corner.gif  \
	WebServerResources/treeview_junction.gif     \
	WebServerResources/treeview_corner.gif       \

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
