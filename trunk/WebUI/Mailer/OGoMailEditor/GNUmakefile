# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoMailEditor

OGoMailEditor_PRINCIPAL_CLASS = OGoMailEditorModule

OGoMailEditor_OBJC_FILES = \
        OGoMailEditorModule.m		\
	\
	NSString+MailEditor.m		\
	NGMimeType+Mailer.m		\
	\
        LSWImapMailEditor.m		\
	LSWImapMailEditor+Activation.m	\
	\
	OGoMailAddressSearch.m		\
	OGoComplexMailAddressSearch.m	\
	OGoSimpleMailAddressSearch.m	\
	OGoMailAddressRecordResult.m	\
	OGoMailAddressRecord.m		\

OGoMailEditor_COMPONENTS = \
        LSWImapMailEditor.wo		\

OGoMailEditor_LANGUAGES = English German

OGoMailEditor_RESOURCE_FILES += Defaults.plist Version

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
