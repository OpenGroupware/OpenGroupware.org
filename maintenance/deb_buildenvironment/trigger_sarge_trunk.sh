#!/bin/sh

DISTRI="sarge"
WWWUSER="www"
WWWHOST="download.opengroupware.org"
MYHOME=${HOME}
TOBUILD="libobjc-lf2
  libfoundation
  sope
  opengroupware.org
  sope-epoz"

OPTS="-v yes -d yes -u yes"
#OPTS="-v yes -d yes -u no"
#OPTS="-v yes -d yes -u no -f yes"

for PKG in ${TOBUILD}; do
  echo -en "Building: ${PKG}\n"
  ${MYHOME}/purveyor_of_debs.pl -p ${PKG} ${OPTS}
done

`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/do_LATESTVERSION.pl /var/virtual_hosts/download/packages/debian/dists/${DISTRI}/trunk/binary-i386/ >/dev/null 2>&1"`;
`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/packages/debian/dists/${DISTRI}/trunk/binary-i386/ >/dev/null 2>&1"`;
`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/trunk_debian_apt.sh ${DISTRI} >/dev/null 2>&1"`;

