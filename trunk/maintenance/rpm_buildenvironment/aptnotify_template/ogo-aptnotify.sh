#!/bin/sh
#
# runs - summoned by cron.d - periodically ogo-aptnotify.sh
#
USE_SKYAPTNOTIFY="YES"
OGO_USER="ogo"

[ -f /etc/sysconfig/OGO_SYSCONF ] && . /etc/sysconfig/OGO_SYSCONF

if [ "x${USE_SKYAPTNOTIFY}" = "xYES" ]; then
  su - ${OGO_USER} -c "OGO_PREFIX/bin/skyaptnotify >/dev/null"
fi
