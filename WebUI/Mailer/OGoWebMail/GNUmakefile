# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoWebMail

OGoWebMail_PRINCIPAL_CLASS = OGoWebMailModule

OGoWebMail_OBJC_FILES = \
        OGoWebMailModule.m		\
	LSWImapMailFilterManager.m	\
        LSWImapMails.m			\
        LSWImapMailFolderTree.m		\
	NGImap4+KVC.m		 	\
        LSWImapMailViewer.m		\
        LSWImapMailFolderEditor.m	\
        LSWImapMailFolderMove.m		\
        LSWImapMailMove.m		\
	LSWImapMailSearch.m		\
	LSWImapMailFilterEditor.m	\
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
	SkyImapMailRestrictions.m	\
	SkyVacationViewer.m		\
	SkyVacationEditor.m		\
	SkyImapMailPrintViewer.m	\
	SkyMailingListManager.m		\
	SkyMailingListViewer.m		\
	SkyMailingListEditor.m		\
	SkyMailingListDataSource.m	\
	SkyImapContextHandler.m		\
	SkyImapMailActions.m		\
	\
	LSWImapBuildFolderDict.m	\
	\
	OGoMailFilterManager.m		\

OGoWebMail_COMPONENTS = \
        LSWImapMails.wo			\
        LSWImapMailFolderTree.wo	\
        LSWImapMailViewer.wo		\
        LSWImapMailFolderEditor.wo	\
        LSWImapMailFolderMove.wo	\
        LSWImapMailMove.wo		\
        LSWImapMailSearch.wo		\
	LSWImapMailFilterEditor.wo	\
	LSWImapMailLogin.wo		\
	SkyImapMailFolderTree.wo        \
	LSWImapMail2Project.wo		\
	LSWMailPreferences.wo		\
	SkyImapMailList.wo              \
	SkyImapMailListPanel.wo         \
	SkyImapMailListConfigPanel.wo   \
	SkyImapMailListHeader.wo	\
	SkyImapMailListFooter.wo  	\
	SkyVacationViewer.wo		\
	SkyVacationEditor.wo		\
	SkyImapMailPrintViewer.wo	\
	SkyMailingListViewer.wo		\
	SkyMailingListEditor.wo		\

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
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
