# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = Appointments

Appointments_OBJC_FILES = \
	SxEvoAptQueryInfo.m		\
	SxAppointmentFolder+Evo.m	\

ADDITIONAL_INCLUDE_DIRS += \
	-I. -I.. -I../..		\
	-I../../Products/Appointments	\
	-I../../Frontend		\
	-I../../Backend			\

include $(GNUSTEP_MAKEFILES)/subproject.make
