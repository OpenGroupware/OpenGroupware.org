#!/bin/sh

for COMP in `find . -type d -name "*.wo"`; do
  echo -n "check $COMP .."
  CONTENTCOUNT=`ls -A $COMP | wc --lines`

  if test $CONTENTCOUNT = 1; then
    echo -n ".. single content .."
    if test -d $COMP/.svn; then
      echo ".. is .svn .."
      svn rm $COMP
      echo ".. REMOVED."
    else
      echo ".. content is not .svn."
    fi
  else
    echo ".. has content."
  fi
done
