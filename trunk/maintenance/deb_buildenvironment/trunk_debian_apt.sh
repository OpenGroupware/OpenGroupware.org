#!/bin/sh
# dpkg-scanpackages binary-i386 /dev/null dists/sarge/trunk/  > binary-i386/Packages

FLAVOUR="$1"

if [ "x${FLAVOUR}" = "x" ]; then
  echo -en "No flavour given...\n"
  echo -en "choose either 'sid' or 'sarge'\n"
  exit 1
fi

rm -fr ${HOME}/tmp/*
mkdir -p ${HOME}/tmp/
mv /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk/binary-i386/*-latest* ${HOME}/tmp/
cd /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk
dpkg-scanpackages binary-i386 /dev/null dists/${FLAVOUR}/trunk/ > binary-i386/Packages
cd /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk/binary-i386/
gzip -c Packages > Packages.gz
mv ${HOME}/tmp/* /var/virtual_hosts/download/packages/debian/dists/${FLAVOUR}/trunk/binary-i386/
