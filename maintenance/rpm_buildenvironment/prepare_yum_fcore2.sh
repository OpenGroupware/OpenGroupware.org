#!/bin/sh

MYHOME="${HOME}"
YUMTEMP="yum-tmp"
YUMREPO="/var/virtual_hosts/download/packages/fedora-core2/"

rm -fr ${YUMTEMP}
mkdir ${YUMTEMP}

ssh www@download.opengroupware.org "rm -fr ${YUMREPO}/trunk/headers/"
ssh www@download.opengroupware.org "rm -fr ${YUMREPO}/releases/headers/"

echo -en "rsyncing from download.opengroupware.org...\n"
rsync -a rsync://download.opengroupware.org/yummer ${YUMTEMP}
rm -fr ${YUMTEMP}/trunk/headers
rm -fr ${YUMTEMP}/releases/headers
echo -en "creating headers for trunk\n"
/usr/bin/yum-arch ${YUMTEMP}/trunk 2>&1 >/dev/null
echo -en "creating headers for release\n"
/usr/bin/yum-arch ${YUMTEMP}/releases 2>&1 >/dev/null

cd ${MYHOME}/${YUMTEMP}
tar cf - trunk/headers --numeric-owner | ssh www@download.opengroupware.org tar xf - -C ${YUMREPO}
cd ${MYHOME}/${YUMTEMP}
tar cf - releases/headers --numeric-owner | ssh www@download.opengroupware.org tar xf - -C ${YUMREPO}

