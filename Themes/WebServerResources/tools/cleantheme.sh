#!/bin/sh

#
# This script looks for images which are the same in different localisations
# of a theme.
#

LOCAL=$1
BASE=$2

echo "compare local '$LOCAL' with base theme '$BASE'"

for ICON in $LOCAL/*.gif; do
  ICONNAME=`basename $ICON`
  BASEICON="$BASE/$ICONNAME"

  if test -f $BASEICON; then
    diff $ICON $BASEICON >/dev/null 2>&1

    if test $? -eq 0; then
      echo "same: $ICONNAME"
    elif test $? -eq 1; then
      echo "diff: $ICONNAME"
    else
      echo "FAIL: $ICON"
    fi
  else
    echo "only in local theme: $ICONNAME"
  fi
done
