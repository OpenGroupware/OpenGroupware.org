# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = JobUI

JobUI_PRINCIPAL_CLASS = JobUIModule

JobUI_OBJC_FILES = \
	JobUIModule.m	 		\
	LSWJobViewer.m	 		\
	LSWJobs.m	 		\
	LSWJobEditor.m	 		\
	LSWJobAction.m	 		\
	LSWJobMailPage.m 		\
	LSWJobPreferences.m 		\
	SkyJobList.m        		\
	SkyAssignProjectToJobEditor.m	\
	SkyJobAttributesEditor.m	\
	OGoJobStatus.m			\
	NSArray+JobIntNums.m		\

JobUI_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
