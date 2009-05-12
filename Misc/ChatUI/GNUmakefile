# GNUstep makefile

OGoROOT=../..

-include $(OGoROOT)/config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

WOBUNDLE_NAME        = ChatUI
WOBUNDLE_EXTENSION   = .lso
WOBUNDLE_INSTALL_DIR = \
  $(GNUSTEP_INSTALLATION_DIR)/Library/OpenGroupware.org-1.3/WebUI/

ChatUI_PRINCIPAL_CLASS = ChatUIModule

ChatUI_OBJC_FILES += \
	ChatUIModule.m		\
	OGoChatPage.m		\

ChatUI_RESOURCE_FILES += \
	Defaults.plist Version	\
	ChatUI.wox

ChatUI_LANGUAGES = English German ptBR

ChatUI_LOCALIZED_RESOURCE_FILES += \
	ChatUI.strings

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../fhsbundle.make
