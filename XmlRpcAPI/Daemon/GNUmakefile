# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = xmlrpcd

xmlrpcd_OBJC_FILES = \
	xmlrpcd.m			\
	Application.m			\
	XmlRpcApplication.m		\
	Session.m			\
	\
	NGFileManagerZipTool.m		\
	NGFileManagerZipTool+Project.m	\
	NGUnixTool.m			\
	\
	EOControl+XmlRpcDirectAction.m	\
	NSObject+EKVC.m			\

xmlrpcd_SUBPROJECTS = \
	Actions.subproj		\
	XmlRpcCoding.subproj	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
