# GNUstep makefile

include ../common.make

BUNDLE_NAME = MailerUI

MailerUI_PRINCIPAL_CLASS = MailerUIProduct

MailerUI_LANGUAGES = English French

MailerUI_OBJC_FILES += \
	MailerUIProduct.m	\
	\
	UIxMailFormatter.m		\
	UIxSubjectFormatter.m		\
	UIxEnvelopeAddressFormatter.m	\
	WOContext+UIxMailer.m		\
	UIxMailRenderingContext.m	\
	\
	UIxMailMainFrame.m		\
	UIxMailTree.m			\
	UIxMailTreeBlock.m		\
	UIxMailToolbar.m		\
	\
	UIxMailAccountsView.m		\
	UIxMailAccountView.m		\
	UIxMailListView.m		\
	UIxMailView.m			\
	UIxMailSortableTableHeader.m	\
	UIxMailMoveToPopUp.m		\
	\
	UIxMailEditor.m			\
	UIxMailEditorAttach.m		\
	UIxMailEditorAction.m		\
	UIxMailReplyAction.m		\
	UIxMailForwardAction.m		\
	UIxMailToSelection.m		\
	UIxMailAddressbook.m		\
	UIxMailWindowCloser.m		\
	\
	UIxMailPartViewer.m		\
	UIxMailPartTextViewer.m		\
	UIxMailPartImageViewer.m	\
	UIxMailPartLinkViewer.m		\
	UIxMailPartMixedViewer.m	\
	UIxMailPartAlternativeViewer.m	\
	UIxMailPartMessageViewer.m	\
	\
	UIxFilterList.m			\
	UIxSieveEditor.m		\
	\
	UIxMailSizeFormatter.m		\

MailerUI_RESOURCE_FILES += \
	Version			\
	product.plist		\

MailerUI_RESOURCE_FILES += \
	UIxMailMainFrame.wox		\
	UIxMailTree.wox			\
	UIxMailToolbar.wox		\
	\
	UIxMailAccountsView.wox		\
	UIxMailAccountView.wox		\
	UIxMailListView.wox		\
	UIxMailView.wox			\
	UIxMailSortableTableHeader.wox	\
	UIxMailMoveToPopUp.wox		\
	\
	UIxMailEditor.wox		\
	UIxMailEditorAttach.wox		\
	UIxMailToSelection.wox		\
	UIxMailAddressbook.wox		\
	UIxMailWindowCloser.wox		\
	\
	UIxMailPartTextViewer.wox	\
	UIxMailPartMixedViewer.wox	\
	UIxMailPartImageViewer.wox	\
	UIxMailPartLinkViewer.wox	\
	UIxMailPartAlternativeViewer.wox\
	UIxMailPartMessageViewer.wox	\
	\
	UIxFilterList.wox		\
	UIxSieveEditor.wox		\

MailerUI_RESOURCE_FILES += \
	uix.css			\
	mailer.css		\
	mailer.js		\

MailerUI_RESOURCE_FILES += \
	Images/tbtv_*.gif	\
	Images/icon_*.gif	\
	Images/tbtb_*.png	\
	Images/message-mail*.png\
	Images/lori_32x32.png	\
	Images/title_*.png	\

MailerUI_LOCALIZED_RESOURCE_FILES += \
	Localizable.strings

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
