# GNUstep makefile

include ../common.make

WOBUNDLE_NAME = OGoProject

OGoProject_PRINCIPAL_CLASS = SkyProject4Module

OGoProject_OBJC_FILES = \
	NGUnixTool.m			\
	NSString+P4.m			\
	\
	SkyP4DocJournal.m		\
	SkyP4DocumentDownloadLogList.m	\
	SkyP4DocumentIcon.m		\
	SkyP4DocumentPath.m		\
	SkyP4DocumentRequestHandler.m	\
	SkyP4DownloadLink.m		\
	SkyP4FolderView.m		\
	SkyP4ProjectTableView.m		\
	\
	OGoComponent+FileManagerError.m	\
	NSData+SkyTextEditable.m	\
	SkyCompanyAccessEditor.m	\
	SkyDocumentAttributeEditor.m	\
	SkyProject4BLOBViewer.m		\
	SkyProject4Desktop.m		\
	SkyProject4DocumentEditor.m	\
	SkyProject4DocumentRename.m	\
	SkyProject4DocumentSearch.m	\
	SkyProject4DocumentUpload.m	\
	SkyProject4DocumentVersionSave.m\
	SkyProject4DocumentViewer.m	\
	SkyProject4Module.m		\
	SkyProject4MovePanel.m		\
	SkyProject4NewLink.m		\
	SkyProject4Viewer.m		\
	SkyProject4VersionList.m	\
	SkyProject4DocumentDeletePage.m \
	OGoDocAction.m			\
	OGoProjectAction.m		\
	OGoDocumentImport.m		\
	OGoProjectQuicklist.m		\
	OGoProjectDocView.m		\

# resources

OGoProject_RESOURCE_FILES += \
	Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
