#!/bin/sh

MYHOME="${HOME}"
YUMTEMP="yum-tmp"
YUMREPO="/var/virtual_hosts/download/nightly/packages/fedora-core3/"

rm -fr ${YUMTEMP}
mkdir ${YUMTEMP}

ssh www@download.opengroupware.org "rm -fr ${YUMREPO}/trunk/repodata/"
ssh www@download.opengroupware.org "rm -fr ${YUMREPO}/releases/*/repodata/"

echo -en "rsyncing from download.opengroupware.org...\n"
rsync -a rsync://download.opengroupware.org/fcore3 ${YUMTEMP}
rm -fr ${YUMTEMP}/trunk/repodata
rm -fr ${YUMTEMP}/releases/repodata
echo -en "creating repodata/ for trunk\n"
/usr/bin/createrepo ${YUMTEMP}/trunk 2>&1 >/dev/null
for RELEASE in `ls -1 ${YUMTEMP}/releases`; do
  echo -en "creating repodata/ for release/${RELEASE}\n"
  /usr/bin/createrepo ${YUMTEMP}/releases/${RELEASE} 2>&1 >/dev/null
done

cd ${MYHOME}/${YUMTEMP}
tar cf - trunk/repodata | ssh www@download.opengroupware.org tar xf - -C ${YUMREPO}
cd ${MYHOME}/${YUMTEMP}
tar cf - releases/*/repodata | ssh www@download.opengroupware.org tar xf - -C ${YUMREPO}

