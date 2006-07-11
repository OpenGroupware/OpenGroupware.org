# New ports collection makefile for:	ogo-gnustep-make
# Date created:  07 Sep 2005
# Whom:          Frank Reppin <frank@opengroupware.org>
#
# $FreeBSD$
#

PORTNAME=	gnustep_make
PORTVERSION=	1.10.0
PORTREVISION=	1
CATEGORIES=	devel
MASTER_SITES=	http://download.opengroupware.org/nightly/packages/freebsd/thirdparty/ogo-gnustep-make/ \
		http://ftp.easynet.nl/mirror/GNUstep/pub/gnustep/core/ \
		http://archive.progeny.com/gnustep/core/ \
		http://ftp.gnustep.org/pub/gnustep/core/
PKGNAMEPREFIX=	ogo-
DISTNAME=	gnustep-make-${PORTVERSION}

MAINTAINER=	frank@opengroupware.org
COMMENT=	GNUstep make environment used by OpenGroupware.org

DIST_SUBDIR=	ogo-suite

USE_GMAKE=	yes
MAKEFILE=	GNUmakefile
PREFIX=		${LOCALBASE}/OGo-GNUstep
HAS_CONFIGURE=	yes
STRIP=
CONFIGURE_ENV=	CPPFLAGS="-Wno-import" \
		CFLAGS="-O0"
CONFIGURE_ARGS=	--prefix=${PREFIX} \
		--with-library-combo=gnu-fd-nil \
		--with-network-root=${PREFIX} \
		--with-local-root=${PREFIX} \
		--without-system-root

.if defined(SHOW_MESSAGES)
MAKE_ARGS+=	messages=yes
.endif

.include <bsd.port.mk>
