# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = Appointments

Appointments_PRINCIPAL_CLASS = AppointmentsProduct

Appointments_OBJC_FILES = \
	Product.m			\
	\
	SxAppointment.m			\
	SxAppointment+Participants.m	\
	SxAppointmentFolder.m		\
	SxAppointmentMessageParser.m	\
	SxFreeBusy.m			\
	SxICalendar.m			\
	\
	SxDavAptAction.m		\
	SxDavAptCreate.m		\
	SxDavAptChange.m		\

ifeq ($(zidelook),yes)

Appointments_OBJC_FILES += \
	SxZLAptRenderer.m		\
	SxZLFullAptRenderer.m

endif

Appointments_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
