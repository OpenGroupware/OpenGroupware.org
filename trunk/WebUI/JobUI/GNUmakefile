# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME        = JobUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.0a/WebUI/

JobUI_PRINCIPAL_CLASS = JobUIModule

JobUI_OBJC_FILES = \
	JobUIModule.m	 		\
	LSWJobViewer.m	 		\
	LSWJobs.m	 		\
	LSWJobEditor.m	 		\
	LSWJobAction.m	 		\
	LSWJobImport.m	 		\
	LSWJobMailPage.m 		\
	LSWJobPreferences.m 		\
	SkyJobList.m        		\
	SkyAssignProjectToJobEditor.m	\
	SkyJobAttributesEditor.m	\
	OGoJobStatus.m			\
	NSArray+JobIntNums.m		\

JobUI_COMPONENTS = \
	LSWJobViewer.wo			\
	LSWJobs.wo			\
	LSWJobEditor.wo			\
	LSWJobAction.wo			\
	LSWJobImport.wo			\
	LSWJobHtmlMailPage.wo		\
	LSWJobTextMailPage.wo		\
	LSWJobPreferences.wo    	\
	SkyJobList.wo           	\
	SkyAssignProjectToJobEditor.wo	\
	SkyJobAttributesEditor.wo	\

JobUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
