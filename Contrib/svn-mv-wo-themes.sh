#!/bin/sh

# work in progress

for COMP in `find . -type d -name "*.wo"`; do
  echo "check $COMP ..."
  LPROJS="`ls -d $COMP/*.lproj 2>/dev/null`"
  for LPROJ in $LPROJS; do
    echo "  check language `basename $LPROJ` ..."
  done
done
