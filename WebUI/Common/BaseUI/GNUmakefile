# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = BaseUI

BaseUI_PRINCIPAL_CLASS = LSWBaseModule

BaseUI_OBJC_FILES = 			\
        LSWBaseModule.m                 \
	OGoElemBuilder.m		\
        LSWViewAction.m                 \
        LSWObjectEditor.m               \
        LSWObjectViewer.m               \
        LSWSkyrixFrame.m                \
        LSWTableView.m                  \
        LSWWarningPanel.m               \
        LSSort+TableView.m              \
        \
        OGoWindowFrame.m                \
        LSWTableViewHeader.m            \
        LSWTableViewFooter.m            \
        LSWTableViewAttributeRow.m      \
        LSWTableViewCell.m              \
        LSWViewerTitle.m                \
        SkyFavorites.m                  \
        SkyNavigation.m                 \
        SkyRequestViewer.m              \
        SkyButton.m                     \
        SkyButtonRow.m                  \
        SkyDock.m                       \
        SkyWizardChoicePage.m           \
        SkyWizardResultList.m           \
        SkyAttributeCell.m              \
	SkyAttribute.m			\
        SkyValueCell.m                  \
        SkyListView.m                   \
        SkyConfigFont.m                 \
        SkyObjectValue.m                \
        SkyConfigEditFont.m             \
	SkyTimeZonePopUp.m              \
	SkyWeekOfYearPopUp.m            \
	SkyObjectLogList.m              \
	SkyPanel.m                      \
	SkyWarningPanel.m               \
	SkySearchPanel.m                \
	SkyListSorter.m                 \
	SkyObjectField.m                \
	SkyEditorButtons.m		\
	SkyWarningMode.m		\
	\
	OGoMenuBox.m			\
	WODirectAction+Mails.m		\
	WODirectAction+SkyDock.m	\
	WODirectAction+Misc.m		\
	WODirectAction+activate.m	\
	\
	OGoLogoutPage.m			\
	Main.m				\

BaseUI_RESOURCE_FILES += Defaults.plist Version

-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
