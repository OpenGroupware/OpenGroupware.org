# Instruct cron to call skyaptnotify in regular intervals. Skyaptnotify sends
# out appointment notifications for OpenGroupware.org via mail.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

*/5 * * * * ogo [ -x /usr/lib/opengroupware.org/System/Tools/skyaptnotify ] && . /usr/lib/opengroupware.org/System/Makefiles/GNUstep.sh && /usr/lib/opengroupware.org/System/Tools/skyaptnotify >> /var/log/opengroupware.org-skyaptnotify.log 2>&1
