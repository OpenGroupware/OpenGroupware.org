# GNUstep makefile

include ../common.make

BUNDLE_NAME = Mailer

Mailer_PRINCIPAL_CLASS = SOGoMailerProduct

Mailer_OBJC_FILES += \
	Product.m			\
	\
	SOGoMailManager.m		\
	SOGoMailConnectionEntry.m	\
	\
	SOGoMailBaseObject.m		\
	SOGoMailAccounts.m		\
	SOGoMailAccount.m		\
	SOGoMailFolder.m		\
	SOGoMailObject.m		\
	\
	SOGoMailBodyPart.m		\
	SOGoImageMailBodyPart.m		\
	SOGoMessageMailBodyPart.m	\
	\
	SOGoDraftsFolder.m		\
	SOGoDraftObject.m		\

Mailer_RESOURCE_FILES += \
	Version		\
	product.plist	\

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
