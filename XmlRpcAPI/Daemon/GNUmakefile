# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = ogo-xmlrpcd-51

ogo-xmlrpcd-51_OBJC_FILES = \
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

ogo-xmlrpcd-51_SUBPROJECTS = \
	Actions.subproj		\
	XmlRpcCoding.subproj	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
-include fhs.make
