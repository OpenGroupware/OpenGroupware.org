# GNUstep makefile

include ../common.make

BUNDLE_NAME  = Appointments
LIBRARY_NAME = libZSAppointments

Appointments_PRINCIPAL_CLASS = AppointmentsProduct
Appointments_OBJC_FILES      = Product.m

libZSAppointments_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSAppointments_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSAppointments_OBJC_FILES = \
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
	SxDavCalendarQuery.m		\

Appointments_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
-include ../../fhslib.make
