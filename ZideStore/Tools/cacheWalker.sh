#!/bin/bash

# $Id: cacheWalker.sh,v 1.1 2003/07/21 15:33:24 helge Exp $

# cacheWalker.sh - removes outdated cache entries from the ZideStore cache

CACHEDIR="/var/cache/zidestore/"

if test "x$USER" = "xskyrix41"; then
  . ~skyrix41/SKYRiX.sh
fi

CD=`Defaults read ZideStore SxCachePath 2>/dev/null`
if test "x$CD" != "x"; then
  if test -d $CD; then
    CACHEDIR=$CD
  else
    echo "Invalid cache dir specified in Default, using '$CACHEDIR'"
  fi
fi

DELETED=0

checkFilesInSubdir () {
  SUBDIR=$1
  CURPREFIX=""
  PREVFILE=""

  FILES=`ls -1 $SUBDIR`
  for FILE in $FILES; do
    if ! test -d $FILE; then
      PREFIX=`expr substr $FILE 1 4`
      if test "x$CURPREFIX" = "x"; then
        CURPREFIX=$PREFIX
      else
        if test "x$CURPREFIX" = "x$PREFIX"; then
          DELFILE="$SUBDIR/$PREVFILE"
          echo "Deleting $DELFILE cause $FILE is newer."
          if test -w $DELFILE; then          
            rm -f $DELFILE
            DELETED=`expr $DELETED + 1`
          else
            echo "Can't delete '$DELFILE', invalid permissions!"
          fi
        else
          CURPREFIX=$PREFIX
        fi
      fi
      PREVFILE=$FILE
    fi
  done
}

echo ">> Starting cache walk...."

SUBDIRS=`find $CACHEDIR -type d`

for SUBDIR in $SUBDIRS; do
  if test "x$SUBDIR" != "x$CACHEDIR"; then
    checkFilesInSubdir $SUBDIR
  fi
done
echo ">> Finished, deleted $DELETED files"