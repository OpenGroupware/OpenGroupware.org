# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = adminxmlrpcd

adminxmlrpcd_OBJC_FILES = \
	xmlrpcd.m			\
	Application.m			\
	XmlRpcApplication.m		\
	Session.m			\
	\
	EOControl+XmlRpcDirectAction.m	\
	NSObject+EKVC.m			\

adminxmlrpcd_SUBPROJECTS = \
	Actions.subproj		\
	XmlRpcCoding.subproj	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
