#!/bin/sh

echo -en "WARNING: not yet configured!\n" && exit 127
DISTRI="fedora-core3"
#DISTRI="fedora-core2"
#DISTRI="redhat9"
#DISTRI="mdk-10.1"
#DISTRI="mdk-10.0"
#DISTRI="suse93"
#DISTRI="suse92"
#DISTRI="suse91"
#DISTRI="suse82"
#DISTRI="sles9"
#DISTRI="slss8"
#DISTRI="rhel3"
#DISTRI="rhel4"
#DISTRI="redhat9"
#DISTRI="conectiva10"

SPECS="ogo-gnustep_make
libobjc-lf2
libfoundation
sope
opengroupware
mod_ngobjweb_fedora
ogo-environment
epoz"

WWWUSER="www"
WWWHOST="download.opengroupware.org"

OPTS="-v yes -u yes -d yes"
#OPTS="-v yes -u no -d no -f yes -b no"
#OPTS="-v yes -u no -d no"

for PACKAGE in ${SPECS}; do
  echo -en "Building for ${PACKAGE}\n"
  /home/build/purveyor_of_rpms.pl -p ${PACKAGE} ${OPTS}
done

rm -fr /home/build/rpm/tmp/*
rm -fr /home/build/rpm/BUILD/*

`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/do_LATESTVERSION.pl /var/virtual_hosts/download/packages/${DISTRI}/trunk/ >/dev/null 2>&1"`;
`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/packages/${DISTRI}/trunk/ >/dev/null 2>&1"`;
`ssh ${WWWUSER}\@${WWWHOST} "/home/www/scripts/trunk_apt4rpm_build.pl -d ${DISTRI} >/dev/null 2>&1"`;

if [ "x${DISTRI}" = "xfedora-core2" ]; then
  echo -en "we're on ${DISTRI} - creating yum repo for ${DISTRI}...\n"
  sh ${HOME}/prepare_yum_fcore2.sh
fi

if [ "x${DISTRI}" = "xfedora-core3" ]; then
  echo -en "we're on ${DISTRI} - creating yum repo for ${DISTRI}...\n"
  sh ${HOME}/prepare_yum_fcore3.sh
fi

