# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include $(GNUSTEP_MAKEFILES)/common.make
include ./Version

LIBRARY_NAME = libZideStoreBackend

libZideStoreBackend_SOVERSION=$(MAJOR_VERSION).$(MINOR_VERSION)

libZideStoreBackend_HEADER_FILES_DIR         = .
libZideStoreBackend_HEADER_FILES_INSTALL_DIR = /ZideStore12/Backend

libZideStoreBackend_HEADER_FILES = \
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
	SxUpdatePerson.h

libZideStoreBackend_OBJC_FILES = \
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
	NSObject+DBColumns.m

libZideStoreBackend_SUBPROJECTS = Contacts Appointments

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
