#!/bin/sh

WWWUSER="www"
WWWHOST="download.opengroupware.org"
MYHOME=${HOME}
TOBUILD="libobjc-lf2
  libfoundation
  libical-sope
  sope
  opengroupware.org"

OPTS="-v yes -d yes -u yes"

for PKG in ${TOBUILD}; do
  echo -en "Building: ${PKG}\n"
  ${MYHOME}/purveyor_of_debs.pl -p ${PKG} ${OPTS}
done

`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/trunk_debian_apt.sh sarge >/dev/null 2>&1"`;
