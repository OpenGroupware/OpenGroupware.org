# GNUstep Makefiles

-include ../../config.make
include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libZSBackend

libZSBackend_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)
libZSBackend_VERSION=$(MAJOR_VERSION).$(MINOR_VERSION).$(SUBMINOR_VERSION)

libZSBackend_HEADER_FILES_DIR         = .
libZSBackend_HEADER_FILES_INSTALL_DIR = /ZSBackend
FHS_HEADER_DIRS = ZSBackend

libZSBackend_HEADER_FILES = \
	NSObject+DBColumns.h		\
	NSString+DBName.h		\
	NSString+rtf.h			\
	SxAptManager.h			\
	SxBackendManager.h		\
	SxBackendMaster.h		\
	SxContactManager.h		\
	SxFreeBusyManager.h		\
	SxSQLQuery.h			\
	SxSQLQueryResultEnumerator.h	\
	SxTaskManager.h			\
	SxUpdateContact.h		\
	SxUpdateEnterprise.h		\
	SxUpdatePerson.h		\
	NGResourceLocator+ZSB.h		\

libZSBackend_OBJC_FILES = \
	SxBackendMaster.m		\
	SxBackendManager.m		\
	SxTaskManager.m			\
	\
	NSString+rtf.m			\
	NSString+DBName.m		\
	SxSQLQuery.m			\
	SxSQLQueryResultEnumerator.m 	\
	\
	SxFreeBusyManager.m		\
	\
	NSObject+DBColumns.m		\
	NGResourceLocator+ZSB.m		\

libZSBackend_OBJC_FILES += \
	SxAptManager.m		\
	SxAptSetHandler.m	\
	SxAptSetIdentifier.m	\
	SxAptManager+iCal.m	\
	\
	SxAppointmentRenderer.m	\

libZSBackend_OBJC_FILES += \
	SxContactManager.m			\
	SxContactManager+evo.m			\
	SxContactSQLQuery.m			\
	SxEvoContactSQLQuery.m			\
	SxZLContactSQLQuery.m			\
	SxListContactSQLQuery.m			\
	SxContactEmailSQLQuery.m		\
	\
	SxFetchContact.m			\
	SxFetchEnterprise.m			\
	SxFetchPerson.m				\
	SxFetchGroup.m				\
	\
	SxUpdateContact.m			\
	SxUpdateEnterprise.m			\
	SxUpdatePerson.m			\
	\
	SxContactSetIdentifier.m		\
	\
	NSMutableDictionary+SetSafeObject.m	\

libZSBackend_RESOURCES += \
	AptBackendSets.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../fhslib.make
