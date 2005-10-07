#!/bin/sh
# dpkg-scanpackages binary-i386 /dev/null dists/sarge/trunk/  > binary-i386/Packages

FLAVOUR="$1"
RELEASE="$2"
STAGE="$3"

if [ "x${FLAVOUR}" = "x" ]; then
  echo -en "No flavour given...\n"
  echo -en "choose either 'sid' or 'sarge'\n"
  exit 1
fi

if [ "x${STAGE}" = "x" ]; then
  echo -en "Please select whether you intend to use me for 'stable' or 'unstable'\n"
  exit 1
fi

if [ ! -e "${HOME}/sign_rpm_passphrase.secret" ]; then
  echo -e "No secret found..."
  echo -e "cannot proceed!"
  exit 0
fi

if [ "x${RELEASE}" = "x" ]; then
  echo -en "No releaes given...\n"
  echo -en "This must be the basename of the directory in:\n"
  #echo -en "/var/virtual_hosts/download/nightly/packages/debian/dists/${FLAVOUR}/releases/binary-i386/\n"
  echo -en "/var/virtual_hosts/download/releases/unstable/*/${FLAVOUR}/binary-i386/\n"
  echo -en "and thus it can be one out of:\n"
  POSSIBILITIES="`find /var/virtual_hosts/download/releases/unstable/* -type d -maxdepth 0 \! -iname 'apt4rpm' -exec basename {} \;`"
  echo -en "${POSSIBILITIES}\n"
  exit 1
fi

if [ ! -d "/var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}" ]; then
  echo -en "directory doesn't even exist... I quit.\n"
  exit 1
fi

#exit 0

source ${HOME}/sign_rpm_passphrase.secret
rm -f /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/Packages*
rm -f /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/Release*

echo "Archive: download.opengroupware.org
Version: 1.0+opengroupware.org
Component: ${FLAVOUR}/releases/${RELEASE}
Origin: OpenGroupware.org
Label: OpenGroupware.org Debian packages
Architecture: i386" >/var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/Release

/usr/bin/apt-ftparchive release \
  /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386 \
  >> /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/Release

/usr/bin/expect -c \
  "spawn /usr/bin/gpg --sign -ba /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/Release; \
   expect \"Enter pass phrase:\"; \
   send -- \"${PASSPHRASE}\\r\"; \
   expect eof" >/dev/null

cd /var/virtual_hosts/download/releases/unstable/
dpkg-scanpackages ${RELEASE}/${FLAVOUR}/binary-i386 /dev/null > ${RELEASE}/${FLAVOUR}/binary-i386/Packages
cd /var/virtual_hosts/download/releases/unstable/${RELEASE}/${FLAVOUR}/binary-i386/
gzip -c Packages > Packages.gz
