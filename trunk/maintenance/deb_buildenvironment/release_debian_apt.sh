#!/bin/sh
# dpkg-scanpackages binary-i386 /dev/null dists/sarge/trunk/  > binary-i386/Packages

FLAVOUR="$1"
RELEASE="$2"

if [ "x${FLAVOUR}" = "x" ]; then
  echo -en "No flavour given...\n"
  echo -en "choose either 'sid' or 'sarge'\n"
  exit 1
fi

if [ "x${RELEASE}" = "x" ]; then
  echo -en "No releaes given...\n"
  echo -en "This must be the basename of the directory in:\n"
  echo -en "/var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/releases/binary-i386/\n"
  echo -en "and thus it can be one out of:\n"
  POSSIBILITIES="`find /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/releases/* -type d \! -iname 'binary-*' -exec basename {} \;`"
  echo -en "${POSSIBILITIES}\n"
  exit 1
fi

#rm -fr ${HOME}/tmp/*
#mkdir -p ${HOME}/tmp/
#mv /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk/binary-i386/*-latest* ${HOME}/tmp/
cd /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/releases/${RELEASE}
dpkg-scanpackages binary-i386 /dev/null dists/${FLAVOUR}/releases/${RELEASE}/ > binary-i386/Packages
cd /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/releases/${RELEASE}/binary-i386/
gzip -c Packages > Packages.gz
#mv ${HOME}/tmp/* /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk/binary-i386/
