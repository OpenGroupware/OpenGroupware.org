# $Id$

include ../common.make

LIBRARY_NAME = libICal2
TOOL_NAME    = skyaptd ical
BUNDLE_NAME  = SkyApt

# libICal2
libICal2_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libICal2_OBJC_FILES = \
	ICalParser.m		\
	ICalVFreeBusy+Parser.m	\
	ICalVCalendar+Parser.m	\
	ICalVEvent+Parser.m	\
	ICalXRoot+Parser.m	\
	\
	ICalComponent.m		\
	ICalProperty.m		\
	NSString+ICal.m		\
	NSCalendarDate+ICal.m	\
	\
	ICalVCalendar.m		\
	ICalVEvent.m		\
	ICalVFreeBusy.m		\
	ICalFreeBusy.m		\
	ICalXRoot.m		\

#endof libICal2

SkyApt_PRINCIPAL_CLASS = SkyAptAction

SkyApt_RESOURCE_FILES += \
	Version			\
	INTERFACE.xml		\
	SkyAptActionMap.plist	\

SkyApt_OBJC_FILES = \
	SkyAptAction.m				\
	SkyAptAction+LastError.m		\
	SkyAptAction+SetValuesMethods.m		\
	SkyAptAction+InputParsing.m		\
	SkyAptAction+PrivateMethods.m		\
	SkyAptAction+AppointmentBindings.m	\
	SkyAptAction+Logging.m			\
	SkyAptAction+Conflicts.m		\
	SkyAptAction+ICal.m			\
	SkyAppointmentResourceCache.m		\

skyaptd_OBJC_FILES = \
	skyaptd.m			\
	DirectIcalAction.m		\
	SkyAptApplication.m		\
	IcalResponse.m			\
	IcalEvents.m			\
	IcalPublish.m			\
	IcaliCalPublish.m		\

ical_OBJC_FILES = ical.m

-include GNUmakefile.preamble
include ../xmlrpcd.make
include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
