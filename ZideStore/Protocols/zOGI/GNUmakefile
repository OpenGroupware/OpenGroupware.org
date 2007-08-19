# GNUstep makefile

-include ../../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = zOGI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_INSTALLATION_DIR)/Library/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

zOGI_PRINCIPAL_CLASS = zOGIProduct

zOGI_OBJC_FILES = \
        NSString+SearchingAdditions.m \
	zOGIProduct.m \
	NSObject+zOGI.m	\
	zOGIAction.m \
        zOGIAction+Account.m \
        zOGIAction+Appointment.m \
        zOGIAction+AppointmentConflicts.m \
        zOGIAction+Assignment.m \
        zOGIAction+Company.m \
        zOGIAction+Contact.m \
        zOGIAction+Document.m \
        zOGIAction+Enterprise.m \
        zOGIAction+Object.m \
        zOGIAction+Project.m \
        zOGIAction+Resource.m \
        zOGIAction+Task.m \
        zOGIAction+Team.m \
        zOGIAction+Note.m \
        zOGIAction+Property.m \
        zOGIRPCAction.m 

zOGI_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist		\

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
