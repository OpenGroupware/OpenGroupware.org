#!/bin/sh

if test "x$TERM" = "x"; then
  # do not start, if it's not a tty
  exit 0
fi
if test "x$TERM" = "xdumb"; then
  # do not start, if it's not an xterm or something ...
  exit 0
fi

if test "x${GNUSTEP_USER_ROOT}" = "x"; then
  echo "source GNUstep.sh before running $0 !"
  exit 1
fi

REGD="${GNUSTEP_USER_ROOT}/Tools/${GNUSTEP_HOST_CPU}/${GNUSTEP_HOST_OS}/${LIBRARY_COMBO}/skyregistryd"
ERRDIR="${GNUSTEP_USER_ROOT}/registry.stderr"
OUTDIR="${GNUSTEP_USER_ROOT}/registry.stdout"

REGPID=`ps waux|grep "^$USER .* .*/skyregistryd$"|sed "s/$USER *//"|sed "s/ .*$//"`
REGPORT=`Defaults read skyregistryd WOPort`

MASTERREG=`Defaults read skyregistryd SxMasterRegistryURL 2>/dev/null`
REGURL=`Defaults read NSGlobalDomain SxComponentRegistryURL 2>/dev/null`

if test "x$REGPID" = "x"; then
  if test "x$REGPORT" = "x"; then
    echo "you need to set WOPort for skyregistryd !!!"
    exit 2
  fi
  
  if test -x $REGD; then
    echo -n "Starting registryd for $USER on port $REGPORT ..."
    (nohup $REGD >>$OUTDIR 2>$ERRDIR &)
    sleep 1
    REGPID=`ps waux|grep "^$USER .* .*/skyregistryd$"|sed "s/$USER *//"|sed "s/ .*$//"`
    echo "... running on pid $REGPID."
    echo "  master:   ${MASTERREG}"
    echo "  port:     ${REGPORT}    (should match the port below !!!)"
    echo "  registry: ${REGURL}"
  else
    "Did not find skyregistryd at: $REGD"
    exit 3
  fi
else
  echo "registry for user $USER running on pid $REGPID ..."
fi
