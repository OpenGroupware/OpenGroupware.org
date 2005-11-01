# New ports collection makefile for:	opengroupware-devel
# Date created:  09 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$

PORTNAME=	opengroupware
PORTVERSION=	1.1
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/opengroupware/
DISTNAME=	opengroupware.org-trunk-r1266-200509071106

MAINTAINER=	frank@opengroupware.org
COMMENT=	OpenGroupware suite

BUILD_DEPENDS=	${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.csh:${PORTSDIR}/devel/ogo-gnustep-make \
		${LOCALBASE}/lib/libobjc_d.so.lf2.95.3:${PORTSDIR}/devel/ogo-libobjc-lf2 \
		${LOCALBASE}/lib/libFoundation_d.so.1.0:${PORTSDIR}/devel/ogo-libfoundation \
		pkg-config:${PORTSDIR}/devel/pkgconfig
LIB_DEPENDS=	pisock.8:${PORTSDIR}/palm/pilot-link

UNIQUENAME=	${PORTNAME}-devel
DIST_SUBDIR=	ogo-suite

OPTIONS=	SOPE_45_DEVEL	"link with sope-4.5" on \
		SOPE_44		"link with sope-4.4" off

.include <bsd.port.pre.mk>

WRKSRC=		${WRKDIR}/opengroupware.org
INSTALLS_SHLIB=	yes
NO_FILTER_SHLIBS=	yes
USE_OPENLDAP=	yes
USE_RC_SUBR=	yes
USE_PGSQL=	yes
DEFAULT_PGSQL_VER=	80
USE_GMAKE=	yes
USE_ICONV=	yes
PREFIX=		${LOCALBASE}
MAKEFILE=	GNUmakefile
MAKE_ARGS=	debug=yes \
		GNUSTEP_INSTALLATION_DIR=${PREFIX} \
		FHS_INSTALL_ROOT=${PREFIX}
.if ${OSVERSION} >= 600000
EXTRACT_DEPENDS+=	${LOCALBASE}/bin/gtar:${PORTSDIR}/archivers/gtar
TAR=	gtar
MAKE_ARGS+=	TAR=${TAR}
.endif

.if defined(WITH_SOPE_44) || !defined(WITHOUT_SOPE_44)
BUILD_DEPENDS+=	${LOCALBASE}/sbin/sope-4.4:${PORTSDIR}/devel/sope44
.endif
.if defined(WITH_SOPE_45_DEVEL) || !defined(WITHOUT_SOPE_45_DEVEL)
BUILD_DEPENDS+=	${LOCALBASE}/sbin/sope-4.5:${PORTSDIR}/devel/sope45-devel
.endif

pre-everything::
.if defined(WITH_SOPE_44) && defined(WITH_SOPE_45_DEVEL)
	@${ECHO_MSG} "WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!   WARNING!!!"
	@${ECHO_MSG} "You must either choose sope-4.4 or sope-4.5, not both!"
	@${ECHO_MSG} "Please run 'make config' again..."
	@${ECHO_MSG} "  ... or 'make rmconfig' prior your next 'make' attempt"
	@exit 1
.endif

do-build:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS})

do-install:
	(cd ${WRKSRC}; . ${LOCALBASE}/OGo-GNUstep/Makefiles/GNUstep.sh; ${GMAKE} ${MAKE_ARGS} install)

.include <bsd.port.post.mk>
