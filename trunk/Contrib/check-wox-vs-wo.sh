#!/bin/sh

# iterates over all .wox files below the working directory and check whether
# an .html is available as well

for WOXFILE in `find . -name "*.wox"`; do
  WOBASENAME="`echo $WOXFILE | sed s/\.wox$//g`"
  
  if test -d $WOBASENAME.wo; then
    echo "found .wo wrapper for the same component: $WOBASENAME.wo"
  elif test -f $WOBASENAME.html; then
    echo "found .html file for the same component: $WOBASENAME.html"
  elif test -f $WOBASENAME.wod; then
    echo "found .wod file for the same component: $WOBASENAME.wod"
  else
    continue
  fi

  echo "  validate .wox: $WOXFILE ..."
  xmllint --noout $WOXFILE
done
