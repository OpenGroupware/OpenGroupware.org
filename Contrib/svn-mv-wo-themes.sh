#!/bin/sh

# work in progress

for COMP in `find . -type d -name "*.wo" | grep -v Templates`; do
  BUNDLE="`dirname $COMP`"
  BUNDLE="`basename $BUNDLE`"
  COMPNAME="`basename $COMP`"
  COMPNAME="`echo $COMPNAME | sed s#.wo##`"
  
  echo "check $COMPNAME in bundle $BUNDLE ..."

  LPROJS="`ls -d $COMP/*.lproj 2>/dev/null`"

  for LPROJPATH in $LPROJS; do
    LPROJ=`basename $LPROJPATH`

    LANG=`echo $LPROJ | sed s/.lproj// | sed s#_#/#`
    LANGNAME="`dirname $LANG`"
    THEME="`basename $LANG`"

    HTMLPATH="$LPROJPATH/$COMPNAME.html"
    WODPATH="$LPROJPATH/$COMPNAME.wod"

    if test "x$LANGNAME" = "x."; then
      if test "x$THEME" = "xEnglish"; then
        echo "  check core language $THEME ..."
        if test -f $HTMLPATH; then
          svn mv $HTMLPATH Templates/$BUNDLE/$COMPNAME.html
          svn mv $WODPATH  Templates/$BUNDLE/$COMPNAME.wod
        else
          echo "DID NOT FIND HTML: $HTMLPATH"
        fi
      else
        echo "  different core language $THEME ..."
      fi
    else
      if test "x$LANGNAME" = "xEnglish"; then
        echo "  check language $LANGNAME theme $THEME ..."
        THEMEDIR="Templates/Themes/$THEME/$BUNDLE"
        if test -f $HTMLPATH; then
          if ! test -d $THEMEDIR; then
            mkdir $THEMEDIR
            svn add $THEMEDIR
          fi
          svn mv $HTMLPATH $THEMEDIR/$COMPNAME.html
          svn mv $WODPATH  $THEMEDIR/$COMPNAME.wod
        else
          echo "DID NOT FIND HTML: $HTMLPATH"
        fi
      else
        echo "  different language $LANGNAME theme $THEME ..."
      fi
    fi
  done
done
