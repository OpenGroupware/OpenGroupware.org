#!/usr/bin/perl -w
# omg... porting purveyor_of_rpms.pl to deal with debs!

use strict;
use Getopt::Std;
use File::Basename;
use File::Path;

my $host_i_runon = "sarge";
#my $host_i_runon = "sid";

my $time_we_started = `date +"%Y%m%d-%H%M%S"`;
chomp $time_we_started;
our($opt_p,$opt_f,$opt_t,$opt_b,$opt_d,$opt_c,$opt_v,$opt_u,$opt_x);
my @poss_packages = qw(libobjc-lf2 libfoundation libical-sope sope opengroupware.org sope-epoz);
my ($package,$force_rebuild,$build_type,$bump_buildcount,$do_download,$release_tarballname,$verbose,$do_upload,$dl_only);
my $logs_dir = "$ENV{'HOME'}/logs";
my $build_area = "$ENV{'HOME'}/build_area";
#my $build_info = "$ENV{'HOME'}/build_info";
my $build_results = "$ENV{'HOME'}/build_results";
my $sources_dir = "$ENV{'HOME'}/sources";
my $deb;
my @debs_build;
$ENV{'DEBFULLNAME'} = "OpenGroupware.org Developers";
$ENV{'DEBEMAIL'} = "developer\@opengroupware.org";
my $dch_msg_trunk = "Automatically generated Subversion trunk package";
my $dch_msg_release = "Automatically generated Subversion release package";
my $destfilename; # aka name of the tarball we build from...
my ($new_version,$new_major,$new_minor,$new_sminor,$new_svnrev);
my $release_codename;
my $remote_release_dirname;

parse_commandline();
my $logerr = "$logs_dir/$package-$time_we_started.err";
my $logout = "$logs_dir/$package-$time_we_started.out";
get_latest_sources();
unpack_and_cleanout_sources();
get_versions_from_src();
prep_changelog();
build_package();
#parse_logs();
move_to_dest();

sub move_to_dest {
  my ($deb_basename,$ln_name,$prep_ln_name,$forarch);
  my $remote_user = "www";
  my $remote_host = "download.opengroupware.org";
  my $remote_dir;
  my $remote_trunk_dir = "/var/virtual_hosts/download/packages/debian/dists/$host_i_runon/trunk/binary-i386";
  #my $remote_rel_dir = "/var/virtual_hosts/download/packages/debian/dists/$host_i_runon/releases/binary-i386";
  my $remote_rel_dir = "/var/virtual_hosts/download/packages/debian/dists/$host_i_runon/releases/";
  my $do_link = "yes";
  if (($do_upload eq "yes") and ($build_type eq "release")) {
    $remote_dir = $remote_rel_dir;
    print "[MOVETODEST]        - going to create directory for release on remote side.\n";
    print "[MOVETODEST]        - name -> $remote_dir/$remote_release_dirname/binary-i386.\n";
    open(SSH, "|/usr/bin/ssh $remote_user\@$remote_host");
    print SSH "mkdir -p $remote_rel_dir\n";
    print SSH "cd $remote_dir\n";
    print SSH "mkdir -p $remote_release_dirname/binary-i386\n";
    close(SSH);
  }
  foreach $deb (@debs_build) {
    $deb_basename = basename($deb);
    $prep_ln_name = `echo \`dpkg -I $build_results/$deb |grep 'Package: '\` |perl -pe's/^Package: //g'`;
    $forarch = `dpkg --print-architecture`;
    chomp $prep_ln_name;
    chomp $forarch;
    $ln_name = "$prep_ln_name-latest.$forarch.deb";
    print "[MOVETODEST]        - $package rolling out '$deb_basename' to $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "yes"));
    print "[MOVETODEST]        - $package won't copy '$deb_basename' to $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "no"));
    system("/usr/bin/scp $build_results/$deb_basename $remote_user\@$remote_host:$remote_trunk_dir/ 1>>$logout 2>>$logerr") if (($build_type eq "trunk") and ($do_upload eq "yes"));
    system("/usr/bin/scp $build_results/$deb_basename $remote_user\@$remote_host:$remote_rel_dir/$remote_release_dirname/binary-i386/ 1>>$logout 2>>$logerr") if (($build_type eq "release") and ($do_upload eq "yes"));
    $remote_dir = $remote_trunk_dir if ($build_type eq "trunk");
    $remote_dir = $remote_rel_dir if ($build_type eq "release");
    print "[LINKATDEST]        - will not really link $ln_name <- $deb_basename at $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "no") and ($build_type eq "trunk"));
    print "[LINKATDEST]        - skip linking with latest bc we build a release\n" if (($verbose eq "yes") and ($build_type eq "release"));
    if (($do_upload eq "yes") and ($do_link eq "yes") and ($build_type eq "trunk")) {
      print "[LINKATDEST]        - \$remote_dir set to: $remote_dir\n" if ($verbose eq "yes");
      print "[LINKATDEST]        - will link $ln_name <- $deb_basename at $remote_host\n" if ($verbose eq "yes");
      open(SSH, "|/usr/bin/ssh $remote_user\@$remote_host");
      print SSH "cd $remote_dir\n";
      print SSH "/bin/ln -sf $deb_basename $ln_name\n";
      close(SSH);
    }
  }
}

sub parse_logs {
  my @errlog;
  my $logline;
  my @errs;
  open(ERRLOG, "$logerr");
  @errlog = <ERRLOG>;
  close(ERRLOG);
  foreach $logline (@errlog) {
    print "$.\n";
    next unless ($logline =~ m/error 1|error 2|not found/i);
    chomp $logline;
    push @errs, $logline;
    print "$. >> $logline\n";
  }
  #print "@errs\n";
}

sub build_package {
  my @errlog;
  my $logline;
  print "[BUILD_PACKAGE]     - calling 'debian/rules binary'\n" if ($verbose eq "yes");
  $ENV{'DEB_BUILD_OPTIONS'} = "nostrip" if($build_type eq "trunk");
  print "[BUILD_PACKAGE]     - using DEB_BUILD_OPTIONS=\"nostrip\"\n" if (($verbose eq "yes") and ($build_type eq "trunk"));
  system("cd $build_area/$package && sudo debian/rules binary 1>>$logout 2>>$logerr");
  open(ERRLOG, "$logout");
  @errlog = <ERRLOG>;
  close(ERRLOG);
  foreach $logline (@errlog) {
    next unless ($logline =~ m/^dpkg-deb: building package/);
    $logline =~ s/^dpkg-deb: building package//g;
    push @debs_build, $logline;
  }
  if (@debs_build) {
    foreach $deb (@debs_build) {
      chomp $deb;
      $deb =~ s/^.*`(.*)'.$//g;
      $deb = basename($1);
      print "[DPKG_BUILDPACKAGE] - summoned $deb\n" if ($verbose eq "yes");
      mkdir("$build_results", 0755),
      print "[DPKG_BUILDPACKAGE] - copy $deb into $build_results\n" if ($verbose eq "yes");
      system("sudo dpkg --force-depends -i $build_area/$deb 1>>$logout 2>>$logerr") unless ($package eq "opengroupware.org");
      system("sudo /sbin/ldconfig 1>>$logout 2>>$logerr");
      system("cp $build_area/$deb $build_results/");
    }
  } else {
    print "[DPKG_BUILDPACKAGE] - whoups - build produced nothing!\n" if ($verbose eq "yes");
    print "[DPKG_BUILDPACKAGE] - examine \$logerr: $logerr\n" if ($verbose eq "yes");
    print "[DPKG_BUILDPACKAGE] - examine \$logout: $logout\n" if ($verbose eq "yes");
    warn "should I exit here?\n";
  }
}

sub prep_changelog {
  print "[DCH]               - calling dch with:\n" if ($verbose eq "yes");
  print "[DCH]               - dch -v $new_version".".svn"."$new_svnrev-1 -D ogo-trunk $dch_msg_trunk\n" if (($verbose eq "yes") and ($build_type eq "trunk"));
  print "[DCH]               - dch -v $new_version".".svn"."$new_svnrev-1 -D ogo-release $dch_msg_release\n" if (($verbose eq "yes") and ($build_type eq "release"));
  system("cd $build_area/$package && /usr/bin/dch -v $new_version".".svn"."$new_svnrev-1 -D ogo-trunk $dch_msg_trunk 1>>$logerr 2>>$logout") if ($build_type eq "trunk");
  system("cd $build_area/$package && /usr/bin/dch -v $new_version".".svn"."$new_svnrev-1 -D ogo-release $dch_msg_release 1>>$logerr 2>>$logout") if ($build_type eq "release");
}

sub get_versions_from_src {
  print "[INFO_FROM_SRC]     - Preparing patch info for $package.\n" if ($verbose eq "yes");
  ###########################################################################
  if ($package eq "ogo-gnustep_make") {
    #hardcoded for now... shouldn't change often
    $new_major = "1";
    $new_minor = "10";
    $new_sminor = "0";
    $new_svnrev = "0";
    $new_version = "$new_major.$new_minor.$new_sminor";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "libobjc-lf2") {
    open(LIBOBJCLF2, "cat $build_area/libobjc-lf2/REVISION.svn|");
    while(<LIBOBJCLF2>) {
      chomp;
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(LIBOBJCLF2);
    chomp $new_svnrev if (defined $new_svnrev);
    #hardcoded...
    $new_major = "2";
    $new_minor = "95";
    $new_sminor = "3";
    $new_version = "$new_major.$new_minor.$new_sminor";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "libfoundation") {
    open(LIBF, "cat $build_area/libfoundation/Version $build_area/libfoundation/REVISION.svn|");
    while(<LIBF>) {
      chomp;
      $new_major = $_ if ($_ =~ s/^MAJOR_VERSION:=//);
      $new_minor = $_ if ($_ =~ s/^MINOR_VERSION:=//);
      $new_sminor = $_ if ($_ =~ s/^SUBMINOR_VERSION:=//);
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(LIBF);
    chomp $new_major if (defined $new_major);
    chomp $new_minor if (defined $new_minor);
    chomp $new_sminor if (defined $new_sminor);
    chomp $new_svnrev if (defined $new_svnrev);
    $new_version = "$new_major.$new_minor.$new_sminor";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "libical-sope") {
    open(LIBICAL, "cat $build_area/libical-sope/REVISION.svn|");
    while(<LIBICAL>) {
      chomp;
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(LIBICAL);
    chomp $new_svnrev if (defined $new_svnrev);
    $new_version = "4.3";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "sope") {
    #get info depending on build_type
    open(SOPE, "cat $build_area/sope/Version $build_area/sope/REVISION.svn|");
    while(<SOPE>) {
      chomp;
      $new_major = $_ if ($_ =~ s/^MAJOR_VERSION=//);
      $new_minor = $_ if ($_ =~ s/^MINOR_VERSION=//);
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(SOPE);
    chomp $new_major if (defined $new_major);
    chomp $new_minor if (defined $new_minor);
    chomp $new_svnrev if (defined $new_svnrev);
    $new_version = "$new_major.$new_minor";
    #release has more digits in the version than trunk...
    if ($build_type eq "release") {
      # \$release_tarballname is an argv -> <-c release_tarballname>
      # unfortunately - not really predictable... see below:
      # (I hope that we stick with the current version scheme in releases:
      #    <sope|opengroupware.org>-<version>-<codename>-<somejunk>
      # )
      $new_version = $release_tarballname;
      $new_version =~ s/sope-(.*)-(.*)-//g;
      $new_version = $1;
      $release_codename = $2;
      $remote_release_dirname = "sope-$new_version-$release_codename";
    }
  }
  ###########################################################################
  if ($package eq "opengroupware.org") {
    open(OGO, "cat $build_area/opengroupware.org/REVISION.svn|");
    while(<OGO>) {
      chomp;
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(OGO);
    chomp $new_svnrev if (defined $new_svnrev);
    #hardcoded basevalue... helge tells me :]
    $new_version = "1.0a";
    if ($build_type eq "release") {
      #check comments above (in sope)
      $new_version = $release_tarballname;
      $new_version =~ s/opengroupware.org-(.*)-(.*)-//g;
      $new_version = $1;
      $release_codename = $2;
      $remote_release_dirname = "opengroupware-$new_version-$release_codename";
    }
  }
  ###########################################################################
  if ($package eq "ogo-environment") {
    $new_major = "1.0a";
    $new_minor = "0";
    $new_svnrev = "0";
    $new_version = "$new_major";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "sope-epoz") {
    open(EPOZ, "cat $build_area/sope-epoz/Version $build_area/sope-epoz/REVISION.svn|");
    while(<EPOZ>) {
      chomp;
      $new_major = $_ if ($_ =~ s/^MAJOR_VERSION=//);
      $new_minor = $_ if ($_ =~ s/^MINOR_VERSION=//);
      $new_sminor = $_ if ($_ =~ s/^SUBMINOR_VERSION:=//);
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(EPOZ);
    chomp $new_major if (defined $new_major);
    chomp $new_minor if (defined $new_minor);
    chomp $new_sminor if (defined $new_sminor);
    chomp $new_svnrev if (defined $new_svnrev);
    $new_version = "$new_major.$new_minor.$new_sminor";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  print "[CURRENT SOURCE]    - $package VERSION:$new_version SVNREV:$new_svnrev\n" if ($verbose eq "yes");
}

sub unpack_and_cleanout_sources {
  if (-e "$sources_dir/$destfilename") {
    print "[UNPACK_CLEAN_SRC]  - going to annihilate $build_area:\n";
    #my $rmcount = rmtree("$build_area/", 0, 0);
    #print "[UNPACK_CLEAN_SRC]  - annihilated $rmcount files/dirs\n";
    system("sudo /bin/rm -fr $build_area");
    mkdir("$build_area", 0755);
    print "[UNPACK_CLEAN_SRC]  - unpacking $destfilename\n";
    system("tar xfvz $sources_dir/$destfilename -C $build_area 1>>$logout 2>>$logerr");
    my $thisdirname = $destfilename;
    $thisdirname = $1 if ($thisdirname =~ s/^(.*)-\d+//g); #deals with current naming convention in release
    $thisdirname = $1 if ($thisdirname =~ s/^(.*)-trunk.*//g); #dito for trunk
    #print "[UNPACK_CLEAN_SRC]  - implant MASTER_BUILD_INFO into $thisdirname\n";
    #my $rmcount = rmtree("$build_area/$thisdirname/debian", 0, 0);
    #print "[UNPACK_CLEAN_SRC]  - annihilated $rmcount files/dirs in $thisdirname/debian\n";
    #print "[UNPACK_CLEAN_SRC]  - cp -Rp $build_info/$thisdirname/debian $build_area/$thisdirname/\n";
    #system("cp -vRp $build_info/$thisdirname/debian $build_area/$thisdirname/ 1>>$logout 2>>$logerr");
  } else {
    print "[UNPACK_CLEAN_SRC]  - cannot unpack $destfilename\n";
    print "[UNPACK_CLEAN_SRC]  - $sources_dir/$destfilename --> $!\n";
    exit 1;
  }
}

sub get_latest_sources {
  #Self explaining... I hope - at least :>
  #We distinguish between `trunk` and `release`.
  #Atm there are specific sources for sope
  #and opengroupware.org releases only - so we use trunk sources
  #for everything else.
  #We'll build the trunk sources in a release (later in this script)
  #with 'debug = no' ... so this should -hopefully- work as expected :]
  #If we don't download <-d no> - we expect the source to be already
  #present in sources/ - just a hint :p - but you'll notice
  #when the script dies.
  #Defaults - if no other options are given - to:
  #download=yes for a build_type=trunk
  my @latest;
  my $sourcefile;
  my $dl_candidate;
  $destfilename = shift;
  my $package_mapped_tosrc = $package;
  my $dl_host = "download.opengroupware.org";
  #remap package name to its corresponding source tarball prefix
  #bc names are not always the same as the source tarball name
  $package_mapped_tosrc = "libobjc-lf2" if ("$package" eq "libobjc-lf2");
  $package_mapped_tosrc = "libfoundation" if ("$package" eq "libfoundation");
  $package_mapped_tosrc = "libical-sope" if ("$package" eq "libical-sope");
  $package_mapped_tosrc = "opengroupware.org" if ("$package" eq "opengroupware.org");
  $package_mapped_tosrc = "sope-epoz" if ("$package" eq "sope-epoz");
  # lucky case here ... useless mappings - but I keep em.
  mkdir("$sources_dir", 0755);
  if(("$do_download" eq "yes") and ("$build_type" eq "trunk")) {
    print "[DOWNLOAD_SRC]      - Download sources for a trunk build!\n" if ($verbose eq "yes");
    @latest = `wget -q -O - http://$dl_host/sources/trunk/LATESTVERSION`;
    foreach $sourcefile (@latest) {
      $destfilename = shift;
      chomp $sourcefile;
      $dl_candidate = $sourcefile if ($sourcefile =~ m/^$package_mapped_tosrc-trunk/i);
    }
    $destfilename = $dl_candidate;
    $destfilename =~ s/-r\d+-\d+/-latest/g;
    print "[DOWNLOAD_SRC]      - Will download $dl_candidate and save the file as $destfilename\n" if ($verbose eq "yes");
    `wget -q -O "$sources_dir/$destfilename" http://$dl_host/sources/trunk/$dl_candidate`;
    print "[DOWNLOAD_SRC]      - will quit now because you've asked me to dl only <-x yes>\n" and exit 0 if ($dl_only eq "yes");
  }
  if(("$do_download" eq "yes") and ("$build_type" eq "release")) {
    #MD5_INDEX comes in handy here, bc this file keeps track of all uploaded releases
    @latest = `wget -q -O - http://$dl_host/sources/releases/MD5_INDEX`;
    chomp $release_tarballname;
    if (grep /$release_tarballname$/, @latest) {
      print "[DOWNLOAD_SRC]      - $release_tarballname should be present for download.\n";
      `wget -q -O "$sources_dir/$release_tarballname" http://$dl_host/sources/releases/$release_tarballname`;
      print "[DOWNLOAD_SRC]      - will quit now because you've asked me to dl only <-x yes>\n" and exit 0 if ($dl_only eq "yes");
    } else {
      print "[DOWNLOAD_SRC]      - Looks like $release_tarballname isn't even present at $dl_host.\n";
      exit 1;
    }
  }
  if (("$do_download" eq "no") and ("$build_type" eq "trunk")) {
    $destfilename = "$package_mapped_tosrc-trunk-latest.tar.gz";
  }
  if ("$build_type" eq "release") {
    $destfilename = "$release_tarballname";
  }
}

sub parse_commandline {
  getopt('pfbtdcvux');
  if ((!$opt_p) or (! grep /^$opt_p$/, @poss_packages)) {
    print "No package given!\nChoose one out of @poss_packages!\n" and exit 1 if(!$opt_p);
    print "No valid package given!\nChoose one out of @poss_packages!\n" and exit 1 if($opt_p);
    exit 0;
  } else {
    $package = $opt_p;
    chomp $package;
  }
  #here we trigger if we force a rebuild
  #that is - ie - we build a deb although
  #the SVN revision didn't changed
  #might be handy for testing build_env changes
  #default >> no - don't force a rebuild if not necessary
  #....but we dont even utilize a buildcounter on debian...
  if (!$opt_f or ($opt_f !~ m/^yes$/i)) {
    $force_rebuild = "no";
  } else {
    $force_rebuild = "yes";
  }
  if (!$opt_t or ($opt_t !~ m/^release$/i)) {
    $build_type = "trunk";
  } else {
    $build_type = "release";
  }
  #the following might be handy to debug build issues
  #without raising the buildcount on subsequent build attempts
  #thus - we safe our current buildcount settings
  #default >> yes - always bump buildcount
  #... maybe not useful in debian too...
  if (!$opt_b or ($opt_b !~ m/^no$/i)) {
    $bump_buildcount = "yes";
  } else {
    $bump_buildcount = "no";
  }
  #do_download decides whether we should attempt to download
  #current sources from MASTER_SITE_OPENGROUPWARE or if we
  #are happy with the sources in sources/
  #this requires `wget`
  #default >> yes - always attempt to download the sources
  if (!$opt_d or ($opt_d !~ m/^no$/i)) {
    $do_download = "yes";
  } else {
    $do_download = "no";
  }
  #release tarballname specifies for which release we actually
  #build this package... this setting is required, if we
  #build one of the release packages
  #I need a real name here ala:
  # opengroupware.org-1.0alpha8-shapeshifter-r233.tar.gz or
  # sope-4.3.8-shapeshifter-r210.tar.gz
  #during runtime I'll recreate the version from this value ala:
  #opengroupware.org-(.*)-shapeshifter-r233.tar.gz etc. ...
  if (!$opt_c) {
    $release_tarballname = "none";
  } else {
    $release_tarballname = basename($opt_c);
  }
  #trigger some more verbose output in certain subs...
  if (!$opt_v or ($opt_v !~ m/^yes$/i)) {
    $verbose = "no";
  } else {
    $verbose = "yes";
  }
  #trigger if we want to upload the resulting packages
  #to a later defined remote_host
  #default >> no - don't try to upload packages
  if (!$opt_u or ($opt_u !~ m/^yes$/i)) {
    $do_upload = "no";
  } else {
    $do_upload = "yes"
  }
  # <-x yes> will only download the requested
  # source tarball and quit afterwards
  # default >> no, do more than only downloading
  if (!$opt_x or ($opt_x !~ m/^yes$/i)) {
    $dl_only = "no";
  } else {
    $dl_only = "yes";
  }
  #sanitize... weird option combinations
  if (($build_type eq "release") and ($release_tarballname eq "none")) { #and (! grep /^$package$/, @package_wo_source)) {
    print "Check your commandline, sinner... no '-c <tarballname>' given for a release build!\n";
    print "I cannot build a release without knowing the release_tarballname\n";
    exit 1;
  }
  #summarize what we've just parsed - if we're verbose
  if ($verbose eq "yes") {
    print "##########################################################################\n";
    print "[COMMANDLINE]       - package to build <-p $package>\n";
    print "[COMMANDLINE]       - force_rebuild  <-f $force_rebuild>\n";
    print "[COMMANDLINE]       - type of build <-t $build_type>\n";
    print "[COMMANDLINE]       - bump buildcount <-b $bump_buildcount>\n";
    print "[COMMANDLINE]       - do download <-d $do_download>\n";
    print "[COMMANDLINE]       - do upload <-u $do_upload>\n";
    print "[COMMANDLINE]       - release tarballname <-c $release_tarballname>\n";
    print "[COMMANDLINE]       - verbose <-v $verbose>\n";
    print "[COMMANDLINE]       - download only <-x $dl_only>\n";
  }
}
