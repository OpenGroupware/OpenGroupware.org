# GNUstep makefiles

include ../common.make

WOBUNDLE_NAME = OGoMailViewers

OGoMailViewers_PRINCIPAL_CLASS = SkyMailViewersModule

OGoMailViewers_OBJC_FILES = \
	SkyMailViewersModule.m			\
	LSWMimeBodyPartViewer.m			\
	LSWMimeMessageViewer.m			\
	LSWMimePartViewer.m			\
	LSWPartBodyViewer.m			\
	LSWMessageRfc822BodyViewer.m		\
	SkyMessageRfc822Viewer.m		\
	LSWTextPlainBodyViewer.m		\
	LSWInlineBodyViewer.m			\
	LSWMultipartAlternativeBodyViewer.m	\
	LSWImageBodyViewer.m			\
	OGoMailDownloadAction.m			\
	SkyP4MailIcon.m				\
	SkyDecodeWrapperData.m			\
	NSString+TextWrap.m			\
	NSString+LinkExtract.m			\

OGoMailViewers_COMPONENTS = \
	LSWAppOctetBodyViewer.wo		\
	LSWEnterpriseObjectBodyViewer.wo	\
	LSWImageBodyViewer.wo			\
	LSWInlineBodyViewer.wo			\
	LSWMessageRfc822BodyViewer.wo		\
	LSWMimeBodyPartViewer.wo		\
	LSWMimeMessageViewer.wo			\
	LSWMultipartAlternativeBodyViewer.wo	\
	LSWMultipartMixedBodyViewer.wo		\
	SkyMessageRfc822Viewer.wo		\
	LSWTextPlainBodyViewer.wo		\

OGoMailViewers_LANGUAGES = English German

OGoMailViewers_RESOURCE_FILES += \
	Defaults.plist	\
	Version		\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
