# $Id$

include $(GNUSTEP_MAKEFILES)/common.make

MODULE_NAME = SkyInvoice

WOBUNDLE_NAME        = SkyInvoice
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = $(GNUSTEP_USER_ROOT)/Library/OpenGroupware.org

SkyInvoice_PRINCIPAL_CLASS = SkyInvoiceModule

SkyInvoice_OBJC_FILES = 		\
	SkyInvoiceModule.m		\
	SkyInvoices.m			\
	SkyInvoiceEditor.m		\
	SkyInvoiceViewer.m		\
	SkyInvoiceArticleEditor.m	\
	SkyInvoicePreferences.m	        \
	SkyInvoiceArticleViewer.m	\
	SkyArticleCategoryEditor.m	\
	SkyArticleCategoryViewer.m	\
	SkyArticleUnitEditor.m		\
	SkyArticleUnitViewer.m		\
	SkyInvoicePrintout.m		\
	SkyArticleAssignmentViewer.m	\
	SkyArticleAssignmentEditor.m	\
	SkyInvoiceList.m		\
	SkyInvoiceCopyPanel.m		\
	SkyUnsettledInvoicesViewer.m	\
	SkyUnsettledInvoicesList.m	\
	SkyInvoicePrintoutFormatter.m	\
	SkyMonitionPrintout.m		\
	SkyInvoiceAccountViewer.m	\
	SkyInvoiceAccounting.m		\
	\
	SkyInvoiceInlineSalesViewer.m	\
	SkyInlineCurrencyToggle.m	\
	SkyInvoiceArticlesList.m	\
	SkyArticlesList.m		\
	SkyMonitionDebitorsList.m	\
	\
	SkyCurrencyFormatter.m		\

SkyInvoice_COMPONENTS =      	\
	SkyInvoices.wo			\
	SkyInvoiceEditor.wo		\
	SkyInvoiceViewer.wo		\
	SkyInvoiceArticleEditor.wo	\
	SkyInvoicePreferences.wo	\
	SkyInvoiceArticleViewer.wo	\
	SkyArticleCategoryEditor.wo	\
	SkyArticleCategoryViewer.wo	\
	SkyArticleUnitEditor.wo		\
	SkyArticleUnitViewer.wo		\
	SkyInvoicePrintout.wo		\
	SkyArticleAssignmentViewer.wo	\
	SkyArticleAssignmentEditor.wo	\
	SkyInvoiceList.wo		\
	SkyInvoiceCopyPanel.wo		\
	SkyUnsettledInvoicesViewer.wo	\
	SkyUnsettledInvoicesList.wo	\
	SkyMonitionPrintout.wo		\
	SkyInvoiceAccountViewer.wo	\
	SkyInvoiceAccounting.wo		\
	\
	SkyInvoiceInlineSalesViewer.wo	\
	SkyInlineCurrencyToggle.wo	\
	SkyInvoiceArticlesList.wo	\
	SkyArticlesList.wo		\
	SkyMonitionDebitorsList.wo	\

SkyInvoice_RESOURCE_FILES += Defaults.plist

SkyInvoice_LANGUAGES = English German

SkyInvoice_DERIVED_RESOURCES = \

ADDITIONAL_WOBUNDLE_LIBS = -lSkyInvoice

before-all :: $(SkyInvoice_DERIVED_RESOURCES)

clean :: 
	rm -f $(SkyInvoice_DERIVED_RESOURCES)

SkyInvoice_INCLUDE_DIRS += -IHeaders -I../SkyInvoiceLib

ADDITIONAL_LIB_DIRS += -L/usr/local/lib

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
