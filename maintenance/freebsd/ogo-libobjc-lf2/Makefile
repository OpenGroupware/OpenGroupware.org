# New ports collection makefile for:	ogo-libobjc-lf2
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	libobjc_lf2
PORTVERSION=	2.95.3
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/thirdparty/ogo-libobjc-lf2/
PKGNAMEPREFIX=	ogo-
DISTNAME=	libobjc-lf2-trunk-r124-200508291710

MAINTAINER=	frank@opengroupware.org
COMMENT=	Library needed to run Objective-C applications which use libFoundation

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make

DIST_SUBDIR=	ogo-suite

SHLIB_VERSION=	${PORTVERSION}
PLIST_SUB=	SHLIB_VERSION=${SHLIB_VERSION}
WRKSRC=		${WRKDIR}/libobjc-lf2
USE_GMAKE=	yes
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
PREFIX=	${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=	messages=yes
.endif

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.mk>
