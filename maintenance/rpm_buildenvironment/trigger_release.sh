#!/bin/sh

#DISTRI="fedora-core3"
DISTRI="fedora-core2"
#DISTRI="rhel3"
#DISTRI="redhat-9"
#DISTRI="mdk-10.1"
#DISTRI="mdk-10.0"
#DISTRI="suse92"
#DISTRI="suse91"
#DISTRI="suse82"
#DISTRI="sles9"
#DISTRI="slss8"

OPTS="-v yes -u no -t release -d no -f yes"

#TODO replace the following lines with some logic to automagically
#build for a newer release (same way as I do for svn packaging)
OGO="opengroupware.org-1.0alpha8-shapeshifter-r233.tar.gz"
SOPE="sope-4.3.9-shapeshifter-r301.tar.gz"


#cleanup previous -trunk- buildenvironment
/home/build/cleanup_all.sh 2>&1 >/dev/null

#debug=no packages ...
/home/build/purveyor_of_rpms.pl -p ogo-gnustep_make -c gnustep-make-1.10.0.tar.gz ${OPTS}
/home/build/purveyor_of_rpms.pl -p libobjc-lf2 -c libobjc-lf2-trunk-latest.tar.gz ${OPTS}
/home/build/purveyor_of_rpms.pl -p libfoundation -c libfoundation-trunk-latest.tar.gz ${OPTS}
/home/build/purveyor_of_rpms.pl -p libical-sope-devel -c libical-sope-trunk-latest.tar.gz ${OPTS}

#RELEASE...
/home/build/purveyor_of_rpms.pl -p sope -c ${SOPE} ${OPTS}
/home/build/purveyor_of_rpms.pl -p opengroupware -c ${OGO} ${OPTS}

/home/build/purveyor_of_rpms.pl -p mod_ngobjweb_fedora -c sope-mod_ngobjweb-trunk-latest.tar.gz ${OPTS}
/home/build/purveyor_of_rpms.pl -p epoz -c sope-epoz-trunk-latest.tar.gz ${OPTS}

/home/build/purveyor_of_rpms.pl -p ogo-environment ${OPTS}

rm -fr /home/build/rpm/tmp/*
rm -fr /home/build/rpm/BUILD/*
