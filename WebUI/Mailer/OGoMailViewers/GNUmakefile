# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

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
	SkyMailIcon.m				\
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

OGoMailViewers_LOCALIZED_RESOURCE_FILES = OGoMailViewers.ccfg

OGoMailViewers_RESOURCE_FILES += \
	Defaults.plist	\
	Version		\

OGoMailViewers_DERIVED_RESOURCES += \
	German.lproj/OGoMailViewers.ccfg

German.lproj/OGoMailViewers.ccfg : English.lproj/OGoMailViewers.ccfg
	echo "// generated from $(<), do not modify !" >$@
	cat $< >>$@

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
