# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = OpenGroupware

# Resources

#OpenGroupware_WEBSERVER_RESOURCE_FILES += menu.js WOStats.xsl

OpenGroupware_RESOURCE_FILES += \
	Defaults.plist	\
	calendar.js 	\
	product.plist	\
	Version

# Components

OpenGroupware_COMPONENTS += Main.wo OGoLogoutPage.wo

# Sources

OpenGroupware_OBJC_FILES = \
	OpenGroupware.m			\
	OpenGroupware+CTI.m		\
	OGoLogoutPage.m			\
	Main.m				\
	DirectAction.m			\
	WODirectAction+LoginAction.m	\
	SoOGoAuthenticator.m

-include SKYRIX.make
-include OGo.make

# Project Makefiles

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
