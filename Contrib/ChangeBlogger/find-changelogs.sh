#!/bin/bash

cd /path/to/checked/out/svn/repos
CLS=`find . -type f -name ChangeLog | cut -c 3-`
cat << EOF
    # the changelogs
    # Note: each entry consists of a dictionary with the following keys:
    # 'repos' -> the SVN repository
    # 'viewcvs' -> viewcvs selector key
    # 'project' -> a realname describing the project
    # 'path' -> the path as seen relative to 'basedir'
    # 'log' -> same as path but including changelog itself
    "logs" :
        [
EOF
for i in $CLS
do
    clpath=$i
	repos=${i%%/*}
	path=${clpath%%/ChangeLog}
	x=${path##*/}
	project=${x%%/*}
    if [ "$repos" = "OpenGroupware.org" ]; then
		viewcvs_repos="OGo"
	else
		viewcvs_repos="$repos"
	fi
	viewcvs="trunk/${clpath#*/}?root=$viewcvs_repos"
	cat << EOF
            { 'repos'   : '$repos',
              'viewcvs' : '$viewcvs',
              'project' : '$project',
              'path'    : '$path',
              'log'     : '$clpath',
            },
EOF
done
cat << EOF
        ],
}
EOF
