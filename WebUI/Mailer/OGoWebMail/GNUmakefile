# GNUstep makefile

include ../common.make
include ../../Version
include ./Version

WOBUNDLE_NAME = OGoWebMail
LIBRARY_NAME  = libOGoWebMail

libOGoWebMail_HEADER_FILES_DIR         = .
libOGoWebMail_HEADER_FILES_INSTALL_DIR = /OGoWebMail

libOGoWebMail_HEADER_FILES += \
	LSWImapBuildFolderDict.h	\
	SkyImapContextHandler.h		\
	SkyImapMailRestrictions.h	\

libOGoWebMail_OBJC_FILES += \
	LSWImapBuildFolderDict.m	\
	SkyImapContextHandler.m		\
	SkyImapMailRestrictions.m	\

OGoWebMail_PRINCIPAL_CLASS = OGoWebMailModule

OGoWebMail_OBJC_FILES = \
        OGoWebMailModule.m		\
        LSWImapMails.m			\
        LSWImapMailFolderTree.m		\
	NGImap4+KVC.m		 	\
        LSWImapMailViewer.m		\
        LSWImapMailFolderEditor.m	\
        LSWImapMailFolderMove.m		\
        LSWImapMailMove.m		\
	LSWImapMailSearch.m		\
	LSWImapMailLogin.m		\
	SkyImapMailFolderTree.m     	\
	LSWImapMail2Project.m		\
	LSWMailPreferences.m		\
	SkyImapMailDataSource.m     	\
	SkyImapMailList.m           	\
	SkyImapMailListState.m          \
	SkyImapMailListConfigPanel.m    \
	SkyImapMailListPanel.m          \
	SkyImapMailListHeader.m		\
	SkyImapMailListFooter.m   	\
	LSWImapMailDeletePage.m		\
	\
	SkyImapMailPrintViewer.m	\
	SkyImapMailActions.m		\

OGoWebMail_COMPONENTS = \
        LSWImapMails.wo			\
        LSWImapMailFolderTree.wo	\
        LSWImapMailViewer.wo		\
        LSWImapMailFolderEditor.wo	\
        LSWImapMailFolderMove.wo	\
        LSWImapMailMove.wo		\
        LSWImapMailSearch.wo		\
	LSWImapMailLogin.wo		\
	SkyImapMailFolderTree.wo        \
	LSWImapMail2Project.wo		\
	LSWMailPreferences.wo		\
	SkyImapMailList.wo              \
	SkyImapMailListPanel.wo         \
	SkyImapMailListConfigPanel.wo   \
	SkyImapMailListHeader.wo	\
	SkyImapMailListFooter.wo  	\
	SkyImapMailPrintViewer.wo	\

OGoWebMail_LANGUAGES = English German

OGoWebMail_LOCALIZED_RESOURCE_FILES = OGoWebMail.ccfg

OGoWebMail_RESOURCE_FILES += Defaults.plist Version

OGoWebMail_DERIVED_RESOURCES = 		\
	German.lproj/OGoWebMail.ccfg  	\

German.lproj/OGoWebMail.ccfg : English.lproj/OGoWebMail.ccfg
	echo "// generated from $(<), do not modify !" >$@
	cat $< >>$@

include GNUmakefile.components

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
