# GNUstep Makefiles

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
	SxRecordCacheManager.h		\
	SxSQLQuery.h			\
	SxSQLQueryResultEnumerator.h	\
	SxSetCacheManager.h		\
	SxTaskManager.h			\
	SxUpdateContact.h		\
	SxUpdateEnterprise.h		\
	SxUpdatePerson.h		\
	NGResourceLocator+ZSB.h		\

libZSBackend_OBJC_FILES = \
	SxBackendMaster.m		\
	SxBackendManager.m		\
	SxSetCacheManager.m		\
	SxRecordCacheManager.m		\
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

libZSBackend_SUBPROJECTS = Contacts Appointments

libZSBackend_RESOURCES += \
	Appointments/AptBackendSets.plist

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
-include ../fhslib.make
