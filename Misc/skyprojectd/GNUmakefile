# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

WOAPP_NAME = skyprojectd

# Resources

skyprojectd_RESOURCE_FILES += Defaults.plist

# Sources

skyprojectd_OBJC_FILES = \
	skyprojectd.m			\
	SkyProjectRequestHandler.m	\
	SkyProjectDirectAction.m	\
	SkyProject_PROPFIND.m		\
	SkyProject_PROPPATCH.m		\
	SkyProject_GET.m		\
	SkyProject_HEAD.m		\
	SkyProject_PUT.m		\
	SkyProject_LOCK.m		\
	Session.m			\
	NGFileManager+DAV.m		\
	WORequest+WebDAV.m		\
	main.m				\
	WOAdaptor+DelegateMethods.m	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/woapp.make
-include GNUmakefile.postamble
