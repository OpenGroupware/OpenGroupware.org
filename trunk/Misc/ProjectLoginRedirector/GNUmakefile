# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = PLRApp

PLRApp_OBJC_FILES = \
	PLRApp.m		\
	DirectAction.m		\
	\
	PLRConnectionSet.m	\
	NSArray+ColGroups.m	\
	WOResponse+ExtractSID.m	\
	EllipsisFormatter.m	\
	\
	Frame.m			\
	Main.m			\
	WelcomePage.m		\
	InstanceView.m		\
	ProjectCard.m		\

PLRApp_RESOURCE_FILES = \
	Frame.wox		\
	Main.wox		\
	WelcomePage.wox		\
	InstanceView.wox	\
	ProjectCard.wox		\

PLRApp_WEBSERVER_RESOURCE_FILES = \
	WebServerResources/favicon.ico		\
	WebServerResources/site.css		\
	WebServerResources/OGoLogo.gif		\
	WebServerResources/corner_left.gif	\
	WebServerResources/corner_right.gif	\
	WebServerResources/tab_.gif		\
	WebServerResources/tab_left.gif		\
	WebServerResources/tab_selected.gif	\

PLRApp_SUBPROJECTS += OGoClient

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
