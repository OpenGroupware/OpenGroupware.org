# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make
include ./Version

LIBRARY_NAME = libOGoFoundation

libOGoFoundation_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libOGoFoundation_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libOGoFoundation_HEADER_FILES_DIR         = .
libOGoFoundation_HEADER_FILES_INSTALL_DIR = /OGoFoundation

libOGoFoundation_HEADER_FILES = \
	OWPasteboard.h			\
	\
	LSStringFormatter.h		\
	NSObject+Commands.h		\
	NSObject+LSWPasteboard.h	\
	OGoComponent.h			\
	OGoContentPage.h		\
	OGoFoundation.h			\
	OGoNavigation.h			\
	OGoSession.h			\
	OGoViewerPage.h			\
	SkyEditorComponent.h		\
	SkyEditorPage.h			\
	SkyMoneyFormatter.h		\
	SkyWizard.h			\
	SkyWizardViewer.h		\
	WOComponent+Commands.h		\
	WOComponent+Navigation.h	\
	WOComponent+config.h		\
	WOSession+LSO.h			\
	\
	LSWClipboardOwner.h		\
	LSWConfigHandler.h		\
	LSWContentPage.h		\
	LSWEditorPage+Wizard.h		\
	LSWEditorPage.h			\
	LSWLabelHandler.h		\
	LSWMailEditorComponent.h	\
	LSWMimeContent.h		\
	OGoModuleManager.h		\
	LSWNotifications.h		\
	OGoObjectMailPage.h		\
	OGoResourceManager.h		\
	LSWTreeState.h			\
	LSWViewerPage.h			\
	\
	OGoHelpManager.h		\
	OGoEditorPage.h			\
	OGoConfigHandler.h		\
	OGoClipboard.h			\

libOGoFoundation_OBJC_FILES = \
	OWPasteboard.m			\
	\
	LSStringFormatter.m		\
	NSObject+Commands.m		\
	NSObject+LSWPasteboard.m	\
	OGoComponent.m			\
	OGoContentPage+OldDA.m		\
	OGoContentPage.m		\
	OGoFoundation.m 		\
	OGoModuleManager.m		\
	OGoNavigation.m			\
	OGoSession+Clipboard.m		\
	OGoSession+Commands.m		\
	OGoSession+UserManagement.m	\
	OGoSession.m			\
	OGoViewerPage.m			\
	SkyEditorComponent.m		\
	SkyEditorPage.m			\
	SkyMoneyFormatter.m		\
	SkyWizard.m			\
	SkyWizardViewer.m		\
	WOComponent+Commands.m		\
	WOComponent+Navigation.m	\
	WOComponent+config.m		\
	\
	LSWClipboardOwner.m		\
	OGoConfigHandler.m		\
	LSWEditorPage+Wizard.m		\
	LSWLabelHandler.m		\
	LSWMimeContent.m		\
	LSWNotifications.m		\
	OGoObjectMailPage.m		\
	OGoResourceManager.m		\
	LSWTreeState.m		        \
	\
	NSObject+Label.m		\
	EOGlobalID+Label.m		\
	SkyDocument+Label.m		\
	OGoSession+JS.m			\
	OGoHelpManager.m		\
	OGoEditorPage.m			\
	OGoStringTable.m		\
	OGoStringTableManager.m		\
	OGoResourceKey.m		\
	OGoClipboard.m			\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include fhs.make
