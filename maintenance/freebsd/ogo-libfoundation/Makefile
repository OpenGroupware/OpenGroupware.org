# New ports collection makefile for:	ogo-libfoundation
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	libfoundation
PORTVERSION=	1.0.84
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/thirdparty/ogo-libfoundation/
PKGNAMEPREFIX=	ogo-
DISTNAME=	libfoundation-trunk-r137-200512061107

MAINTAINER=	frank@opengroupware.org
COMMENT=	The libFoundation required by the OGo suite

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2
# can't use LIB_DEPENDS because OGo/SOPE libraries are not in the proper
# format (bsd.port.mk uses ldconfig -r to look them up)

DIST_SUBDIR=	ogo-suite

SHLIB_MAJOR=	1
SHLIB_MINOR=	0
SHLIB_SUBMINOR=	84
SHLIB_VERSION=	${SHLIB_MAJOR}.${SHLIB_MINOR}.${SHLIB_SUBMINOR}
PLIST_SUB=	SHLIB_MAJOR=${SHLIB_MAJOR} \
		SHLIB_MINOR=${SHLIB_MINOR} \
		SHLIB_VERSION=${SHLIB_VERSION}

WRKSRC=		${WRKDIR}/libfoundation
HAS_CONFIGURE=	yes
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
USE_GMAKE=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=     messages=yes
.endif

do-configure:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ./configure)

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.mk>
