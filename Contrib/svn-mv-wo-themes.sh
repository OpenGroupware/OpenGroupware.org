#!/bin/sh

# work in progress

for COMP in `find . -type d -name "*.wo"`; do
  echo "check $COMP ..."
  LPROJS="`ls -d $COMP/*.lproj 2>/dev/null`"
  for LPROJPATH in $LPROJS; do
    LPROJ=`basename $LPROJPATH`
    LANG=`echo $LPROJ | sed s/.lproj// | sed s#_#/#`
    LANGNAME="`dirname $LANG`"
    THEME="`basename $LANG`"
    echo "  check language $LANGNAME theme $THEME ..."
  done
done
