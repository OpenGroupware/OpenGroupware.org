# New ports collection makefile for:	ogo-libfoundation
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	libfoundation
PORTVERSION=	1.1.5
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/thirdparty/ogo-libfoundation/
PKGNAMEPREFIX=	ogo-
DISTNAME=	libfoundation-trunk-r162-200701261110

MAINTAINER=	frank@opengroupware.org
COMMENT=	The libFoundation required by the OGo suite

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh:${PORTSDIR}/devel/ogo-gnustep-make

DIST_SUBDIR=	ogo-suite

SHLIB_MAJOR=	1
SHLIB_MINOR=	1
SHLIB_SUBMINOR=	5
SHLIB_VERSION=	${SHLIB_MAJOR}.${SHLIB_MINOR}.${SHLIB_SUBMINOR}
PLIST_SUB=	SHLIB_MAJOR=${SHLIB_MAJOR} \
		SHLIB_MINOR=${SHLIB_MINOR} \
		SHLIB_VERSION=${SHLIB_VERSION}

WRKSRC=		${WRKDIR}/libfoundation
HAS_CONFIGURE=	yes
USE_LDCONFIG=	yes
NO_FILTER_SHLIBS=	yes
USE_GMAKE=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		strip=no \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}

STRAY_LF_FILES=	Library/Headers/libFoundation/extensions/exceptions/NSCoderExceptions.h \
		Library/Headers/libFoundation/extensions/exceptions/GeneralExceptions.h \
		Library/Headers/libFoundation/extensions/exceptions/FoundationException.h

STRAY_LF_DIRS=	Tools \
		Library/Libraries \
		Library/Headers/libFoundation/extensions/exceptions \
		Library/Headers/libFoundation/extensions \
		Library/Headers/libFoundation/amd64/freebsd/GNU \
		Library/Headers/libFoundation/amd64/freebsd \
		Library/Headers/libFoundation/amd64 \
		Library/Headers/libFoundation/Foundation/exceptions \
		Library/Headers/libFoundation/Foundation \
		Library/Headers/libFoundation \
		Library/Headers \
		Library

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=     messages=yes
.endif

do-configure:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ./configure)

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	@if [ ! -d "${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional" ]; then \
	  ${ECHO_MSG} "creating directory '${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional'"; \
	  ${MKDIR} ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/Additional; \
	fi
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/System/Library/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)
	@for STRAY_LF_FILE in ${STRAY_LF_FILES}; do \
	  if [ -f ${LOCALBASE}/$${STRAY_LF_FILE} ]; then \
  	    ${ECHO_MSG} "removing stray libfoundation file '${LOCALBASE}/$${STRAY_LF_FILE}'..."; \
	    ${RM} ${LOCALBASE}/$${STRAY_LF_FILE}; \
	  fi \
	done
	@for STRAY_LF_DIR in ${STRAY_LF_DIRS}; do \
	  if [ -d ${LOCALBASE}/$${STRAY_LF_DIR} ]; then \
  	    ${ECHO_MSG} "removing stray libfoundation directory '${LOCALBASE}/$${STRAY_LF_DIR}'..."; \
	    ${RMDIR} ${LOCALBASE}/$${STRAY_LF_DIR}; \
	  fi \
	done

.include <bsd.port.mk>
