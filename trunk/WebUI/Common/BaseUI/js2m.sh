#!/bin/sh

jsfile=$1
mfile=$2

if [ "x${jsfile}" = "x" ]; then
  echo "usage: $0 <jsfile> <mfile>"
  exit 1;
fi
if [ "x${mfile}" = "x" ]; then
  echo "usage: $0 <jsfile> <mfile>"
  exit 1;
fi

if [ ! -f $jsfile ]; then
  echo "$0: file '${jsfile}' can't be found !"
  exit 2;
fi

echo "transforming ${jsfile} to ${mfile} .."

IFS="
"
replaceto='\\"'

SEDCMD='sed'
#SEDCMD='cat'

echo >$mfile "/* automatically generated from ${jsfile}, do not edit ! */"
for i in `${SEDCMD} "s|\\"|$replaceto|g" <${jsfile}`; do
  echo -n >>$mfile "@\""
  echo -n >>$mfile "${i}"
  echo >>$mfile "\\n\""
done
