# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = LSWProject

LSWProject_PRINCIPAL_CLASS = LSWProjectModule

LSWProject_OBJC_FILES = \
	LSWProjectModule.m		\
	DateIntervalFormatter.m		\
	LSWDocumentDownloadAction.m	\
	LSWDocumentMailPage.m		\
	LSWDocumentViewer.m		\
	LSWProjectJobList.m		\
	LSWProjectMailPage.m		\
	LSWProjectPreferences.m		\
	LSWProjectWizard.m		\
	LSWProjects.m			\
	\
	SkyProjectAssignment.m		\
	SkyProjectInlineViewer.m	\
	SkyProjectList.m		\
	SkyProjectSelection.m		\
	SkyProjectSelections.m      	\
	SkyPropertiesEditor.m		\
	SkyPropertyEditor.m		\
	LSWProjectEditor.m		\
	NSString+Perm.m			\
	NSObject+ProjectLabels.m	\

LSWProject_COMPONENTS = \
	LSWDocumentHtmlMailPage.wo	\
	LSWDocumentTextMailPage.wo	\
	LSWDocumentViewer.wo		\
	LSWProjectHtmlMailPage.wo	\
	LSWProjectJobList.wo		\
	LSWProjectPreferences.wo	\
	LSWProjectTextMailPage.wo	\
	LSWProjectWizard.wo		\
	\
	SkyProjectAssignment.wo		\
	SkyProjectInlineViewer.wo	\
	SkyProjectList.wo               \
	SkyProjectSelection.wo          \
	SkyProjectSelections.wo		\
	SkyPropertiesEditor.wo		\
	SkyPropertyEditor.wo		\
	LSWProjectEditor.wo		\

LSWProject_RESOURCE_FILES += Version

LSWProject_LANGUAGES = English German

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
