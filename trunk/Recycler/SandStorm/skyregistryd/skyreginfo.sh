#!/bin/sh

if test "x${GNUSTEP_USER_ROOT}" = "x"; then
  echo "source GNUstep.sh before running $0 !"
  exit 1
fi

REGDIR="/LOCAL/home/$USER/dev/Skyrix-dev-42/Daemons/skyregistryd/obj/skyregistryd"
ERRDIR="${GNUSTEP_USER_ROOT}/registry.stderr"
OUTDIR="${GNUSTEP_USER_ROOT}/registry.stdout"

REGPID=`ps waux|grep "^$USER .* .*/skyregistryd$"|sed "s/$USER *//"|sed "s/ .*$//"`
REGPORT=`Defaults read skyregistryd WOPort`

MASTERREG=`Defaults read skyregistryd SxMasterRegistryURL 2>/dev/null`
REGURL=`Defaults read NSGlobalDomain SxComponentRegistryURL 2>/dev/null`

if test "x$REGPID" = "x"; then
  if test "x$REGPORT" = "x"; then
    echo "you need to set WOPort for skyregistryd !!!"
    exit 0
  fi
  
  if test -x $REGDIR; then
    echo "registry is down."
    exit 0
  else
    "Did not find skyregistryd at: $REGDIR"
    exit 0
  fi
else
  echo "registry for user $USER running on pid $REGPID .."
fi

echo "  master:   ${MASTERREG}"
echo "  port:     ${REGPORT}    (should match the port below !!!)"
echo "  registry: ${REGURL}"
