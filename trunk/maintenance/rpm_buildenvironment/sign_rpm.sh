#!/bin/sh
# frank@opengroupware.org
# signs RPMS unattended...

MYHOME=${HOME}
TOSIGN=$1
EXPECT="/usr/bin/expect"

if [ ! -e "${MYHOME}/sign_rpm_passphrase.secret" ]; then
  echo -e "No secret found..."
  echo -e "cannot proceed!"
  exit 0
fi

if [ ! "${TOSIGN}" -o ! -e "${TOSIGN}" ]; then
  echo -e "no rpm given... or nonexistent"
  echo -e "Usage: $0 <PATH_TO_RPM>"
  exit 0
fi

#contains the passphrase (chmod'ed 400!)
source ${MYHOME}/sign_rpm_passphrase.secret

${EXPECT} -c "spawn rpm --addsign ${TOSIGN}; \
              expect \"Enter pass phrase:\"; \
              send -- \"${PASSPHRASE}\\r\"; \
              expect eof" >/dev/null

