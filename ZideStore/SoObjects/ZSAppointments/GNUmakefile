# GNUstep makefile

include ../common.make

BUNDLE_NAME  = Appointments
LIBRARY_NAME = libZSAppointments

Appointments_PRINCIPAL_CLASS = AppointmentsProduct
Appointments_OBJC_FILES      = Product.m

libZSAppointments_INTERFACE_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSAppointments_INSTALL_DIR=$(OGO_SYSLIBDIR)
libZSAppointments_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSAppointments_OBJC_FILES = \
	SxAppointment.m			\
	SxAppointment+Participants.m	\
	SxAppointmentFolder.m		\
	SxAppointmentMessageParser.m	\
	SxFreeBusy.m			\
	SxICalendar.m			\
	\
	SxDavAptAction.m		    \
	SxDavAptCreate.m		    \
	SxDavAptChange.m		    \
	SxDavCalendarQuery.m		\
  SxDavCalendarMultiget.m

Appointments_RESOURCE_FILES += \
	bundle-info.plist	\
	Version			\
	product.plist

BUNDLE_INSTALL_DIR=$(ZIDESTORE_WEBUIDIR)

-include GNUmakefile.preamble
ifneq ($(FHS_INSTALL_ROOT),)
GNUSTEP_HEADERS=$(DESTDIR)$(FHS_INSTALL_ROOT)/include
endif
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
