#!/usr/bin/perl -w
# by <frank@opengroupware.org> 2004

use strict;
use Getopt::Std;
use File::Basename;

# must be the same as the dest dir on the \$remote_host
# I'll also create a directory like \$ENV{'HOME'}/macros/\$host_i_runon
# where I *expect* the rpmmacros to be present!
# The purveyor will fail royally if it's not there.
# NEW >  moved this variable into an external configfile called
#        $ENV{'HOME'}/purveyor_of_rpms.conf
my $host_i_runon;
my $mod_ngobjweb_to_use;
my $time_we_started = `date +"%Y%m%d-%H%M%S"`;
chomp $time_we_started;
our ($opt_p,$opt_f,$opt_t,$opt_b,$opt_d,$opt_c,$opt_v,$opt_u,$opt_s,$opt_r);
my ($package,$force_rebuild,$build_type,$bump_buildcount,$do_download,$release_tarballname,$verbose,$do_upload,$use_specfile,$rdirbase);
my $hpath = "$ENV{'HOME'}";
my $logs_dir = "$ENV{'HOME'}/logs";
my $sources_dir = "$ENV{'HOME'}/rpm/SOURCES";
my $specs_dir = "$ENV{'HOME'}/rpm/SPECS";
my $use_specdir_specfile = "yes";
my $dl_host = "download.opengroupware.org";
# this are the packages I can deal with
# every package given here should have its own specfile...
# adding new packages is more or less a copy'n'paste job of code snippets below
my @poss_packages = qw( ogo-gnustep_make libobjc-lf2 libfoundation libical-sope-devel opengroupware-pilot-link opengroupware-nhsc sope opengroupware mod_ngobjweb_slss8 mod_ngobjweb_fedora mod_ngobjweb_suse82 mod_ngobjweb_suse91 mod_ngobjweb_suse92 mod_ngobjweb_mdk100 mod_ngobjweb_mdk101 mod_ngobjweb_sles9 mod_ngobjweb_rhel3 mod_ngobjweb_redhat9 mod_ngobjweb_conectiva10 ogo-environment epoz ogo-database-setup );
my $flavour_we_build_upon;
my $distrib_define;
my $memyself = basename($0);
my $version_bumped = "no";
my $do_build = "no";
my ($cur_version,$cur_svnrev,$cur_buildcount);
my ($new_version,$new_major,$new_minor,$new_sminor,$new_svnrev,$new_buildcount);
my $rpm;
my @rpms_build;
#package_wo_source contains packages wo source at all or where i refuse to download
#the source (source should be already in \$sources_dir)
my @package_wo_source = qw( ogo-gnustep_make ogo-environment ogo-database-setup );
my @dont_install = qw( mod_ngobjweb_fedora mod_ngobjweb_suse82 mod_ngobjweb_suse91 mod_ngobjweb_suse92 mod_ngobjweb_slss8 mod_ngobjweb_mdk100 mod_ngobjweb_mdk101 mod_ngobjweb_sles9 mod_ngobjweb_rhel3 mod_ngobjweb_redhat9 mod_ngobjweb_conectiva10 ogo-environment opengroupware-pilot-link opengroupware-nhsc ogo-database-setup ogo-meta );
my $release_codename;
my $remote_release_dirname;
my $libversion;
eval getconf("$ENV{'HOME'}/purveyor_of_rpms.conf") or die "FATAL: $@\n";

prepare_build_env();
get_commandline_options();
my $logerr = "$logs_dir/$package-$time_we_started.err";
my $logout = "$logs_dir/$package-$time_we_started.out";
get_latest_sources();
link_rpmmacros();
collect_patchinfo();
get_current_from_rpmmacro();
pre_patch_rpmmacros();
build_rpm();
move_to_dest();


sub move_to_dest {
  my ($rpm_basename,$ln_name,$prep_ln_name,$forarch);
  my $remote_user = "www";
  my $remote_host = "download.opengroupware.org";
  my $remote_dir;
  my $remote_trunk_dir = "/var/virtual_hosts/download/packages/$host_i_runon/trunk";
  my $remote_rel_dir = "/var/virtual_hosts/download/packages/$host_i_runon/releases";
  my $do_link = "yes";
  if (($do_upload eq "yes") and ($build_type eq "release")) {
    $remote_dir = $remote_rel_dir;
    print "[MOVETODEST]        - going to create directory for release on remote side.\n";
    print "[MOVETODEST]        - name -> $remote_dir/$remote_release_dirname.\n" if ($remote_release_dirname);
    print "[MOVETODEST]        - name -> $remote_dir/$rdirbase.\n" if ($rdirbase);
    open(SSH, "|/usr/bin/ssh $remote_user\@$remote_host");
    print SSH "cd $remote_dir\n";
    print SSH "mkdir -p $remote_release_dirname\n" if ($remote_release_dirname);
    print SSH "mkdir -p $rdirbase\n" if ($rdirbase); #didn't I mention that it's already there :)
    close(SSH);
  }
  foreach $rpm (@rpms_build) {
    $rpm_basename = basename($rpm);
    $prep_ln_name = `/bin/rpm --qf '%{name}' -qp $rpm`;
    $forarch = `/bin/rpm --qf '%{arch}' -qp $rpm`;
    chomp $prep_ln_name;
    chomp $forarch;
    $ln_name = "$prep_ln_name-latest.$forarch.rpm";
    print "[MOVETODEST]        - $package will be put into $rdirbase as requested via commandline\n" if (($verbose eq "yes") and ($do_upload eq "yes") and ($rdirbase));
    print "[MOVETODEST]        - $package rolling out '$rpm_basename' to $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "yes"));
    print "[MOVETODEST]        - $package won't copy '$rpm_basename' to $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "no"));
    system("/usr/bin/scp $rpm $remote_user\@$remote_host:$remote_trunk_dir/ 1>>$logout 2>>$logerr") if (($build_type eq "trunk") and ($do_upload eq "yes"));
    system("/usr/bin/scp $rpm $remote_user\@$remote_host:$remote_rel_dir/$rdirbase/ 1>>$logout 2>>$logerr") if (($rdirbase) and ($build_type eq "release") and ($do_upload eq "yes"));
    system("/usr/bin/scp $rpm $remote_user\@$remote_host:$remote_rel_dir/$remote_release_dirname/ 1>>$logout 2>>$logerr") if (($build_type eq "release") and ($do_upload eq "yes") and (!$rdirbase));
    $remote_dir = $remote_trunk_dir if ($build_type eq "trunk");
    $remote_dir = $remote_rel_dir if ($build_type eq "release");
    print "[LINKATDEST]        - will not really link $ln_name <- $rpm_basename at $remote_host\n" if (($verbose eq "yes") and ($do_upload eq "no") and ($build_type eq "trunk"));
    print "[LINKATDEST]        - skip linking with latest bc we build a release\n" if (($verbose eq "yes") and ($build_type eq "release"));
    if (($do_upload eq "yes") and ($do_link eq "yes") and ($build_type eq "trunk")) {
      print "[LINKATDEST]        - \$remote_dir set to: $remote_dir\n" if ($verbose eq "yes");
      print "[LINKATDEST]        - will link $ln_name <- $rpm_basename at $remote_host\n" if ($verbose eq "yes");
      open(SSH, "|/usr/bin/ssh $remote_user\@$remote_host");
      print SSH "cd $remote_dir\n";
      print SSH "/bin/ln -sf $rpm_basename $ln_name\n";
      close(SSH);
    }
  }
}

sub build_rpm {
  my $rc;
  my $specfile = "$package.spec";
  my @tmp_spec;
  my $tmp_spec_line;
  my $use_sope;
  my @outlog;
  my $logline;
  if(($package eq "opengroupware") and ($build_type eq "trunk")) {
    my @t_sope;
    my @sope;
    my $sope_rpm;
    my $line;
    print "[RPMBUILD]          - checking which SOPE version we want for this OGo trunk\n" if ($verbose eq "yes");
    open(SOPEHINTS, "$specs_dir/$specfile") if($use_specdir_specfile eq "yes");
    open(SOPEHINTS, "$use_specfile") if($use_specdir_specfile eq "no");
    @tmp_spec = <SOPEHINTS>;
    close(SOPEHINTS);
    foreach $tmp_spec_line(@tmp_spec) {
      chomp $tmp_spec_line;
      $use_sope = $tmp_spec_line if ($tmp_spec_line =~ s/^#UseSOPE:\s+//g);
    }
    print "[RPMBUILD]          - didn't found UseSOPE hint in specfile.\n" and exit 1 if (($verbose eq "yes") and (!$use_sope));
    print "[RPMBUILD]          - building $package using: SOPE release  $use_sope\n" if ($verbose eq "yes");
    print "[RPMBUILD]          - getting MD5_INDEX for $use_sope prior installation...\n" if ($verbose eq "yes");
    @t_sope = `wget -q --proxy=off -O - http://$dl_host/packages/$host_i_runon/releases/$use_sope/MD5_INDEX` or die "I DIE: couldn't fetch MD5_INDEX (http://$dl_host/packages/$host_i_runon/releases/$use_sope/MD5_INDEX)\n";
    #parse through MD5_INDEX and generate a list of all sope RPMS... additionally download 'em into install_tmp/
    foreach $line (@t_sope) {
      chomp $line;
      next unless($line =~ m/\.rpm$/i);
      $line =~ s/^.*\s+//g;
      $sope_rpm = $line;
      print "[RPMBUILD]          - loading $sope_rpm into install_tmp/" if ($verbose eq "yes");
      $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$sope_rpm http://$dl_host/packages/$host_i_runon/releases/$use_sope/$sope_rpm");
      print " ...success!\n" if($rc == 0);
      print "\nFATAL: system call (wget) returned $rc whilst downloading $sope_rpm into install_tmp/\n" and exit 1 unless($rc == 0);
      push(@sope, $sope_rpm);
    }
    print "[RPMBUILD]          - removing the currently installed SOPE\n" if ($verbose eq "yes");
    system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps --noscripts");
    system("sudo /sbin/ldconfig");
    my $sope_rpm_count = @sope;
    print "[RPMBUILD]          - must install $sope_rpm_count RPMS ($use_sope) from install_tmp/ ... this may take some seconds\n";
    foreach $line(@sope) {
      $rc = system("sudo rpm -U --force --noscripts $ENV{HOME}/install_tmp/$line");
      print "[RPMBUILD]          - $line ($rc)...ok, done!\n" if($rc == 0);
      print "\n[RPMBUILD]          - FATAL: system call (rpm) returned $rc whilst installing required RPMS from install_tmp/\n" and exit 1 unless($rc == 0);
    }
    system("sudo /sbin/ldconfig");
    print "[RPMBUILD]          - finished to prepare SOPE $use_sope... continue to build $package $build_type...\n" if ($verbose eq "yes");

  }
  system("/usr/bin/rpmbuild -bb $specs_dir/$specfile 1>>$logout 2>>$logerr") if ($build_type eq "trunk");
  system("/usr/bin/rpmbuild -bb $use_specfile 1>>$logout 2>>$logerr") if (($build_type eq "release") and ($use_specdir_specfile eq "no"));
  system("/usr/bin/rpmbuild -bb $specs_dir/$specfile 1>>$logout 2>>$logerr") if (($build_type eq "release") and ($use_specdir_specfile eq "yes"));
  open(OUTLOG, "$logout");
  @outlog = <OUTLOG>;
  close(OUTLOG);
  foreach $logline (@outlog) {
    next unless ($logline =~ m/^Wrote: /);
    $logline =~ s/^Wrote: //g;
    push @rpms_build, $logline;
  }
  if (@rpms_build) {
    foreach $rpm (@rpms_build) {
      my $current_rpm_name;
      $current_rpm_name = `/bin/rpm --qf '%{name}' -qp $rpm`;
      chomp $rpm;
      print "[RPMBUILD]          - $package summoned $rpm ($current_rpm_name)\n" if ($verbose eq "yes");
      system("/usr/bin/sudo rpm -Uvh --force --nodeps $rpm 1>>$logout 2>>$logerr") unless ((grep /^$package$/, @dont_install) or (grep /^$current_rpm_name$/, @dont_install));
      print "[RPMBUILD]          - $package didn't install $current_rpm_name locally bc it's not needed in further buildprocess\n" if (($verbose eq "yes") and (grep /^$package$/, @dont_install) or (grep /^$current_rpm_name$/, @dont_install));
      system("/usr/bin/sudo /sbin/ldconfig 1>>$logout 2>>$logerr");
    }
  } else {
    print "[RPMBUILD]          - $package whoups - build produced nothing!\n" if ($verbose eq "yes");
    print "[RPMBUILD]          - $package examine \$logerr: $logerr\n" if ($verbose eq "yes");
    print "[RPMBUILD]          - $package examine \$logout: $logout\n" if ($verbose eq "yes");
    print "[RPMBUILD]          - $memyself will quit its work for $package here.\n" if ($verbose eq "yes");
    #TODO -> parse err/out log and mail some results to the maintainers.
    exit 1;
  }
}

sub pre_patch_rpmmacros {
  my $line;
  my @tmp_rpmmacros;
  open(RPMMACROS_IN, "$hpath/macros/$host_i_runon/rpmmacros_trunk") if ($build_type eq "trunk");
  open(RPMMACROS_IN, "$hpath/macros/$host_i_runon/rpmmacros_release") if ($build_type eq "release");
  @tmp_rpmmacros = <RPMMACROS_IN>;
  close(RPMMACROS_IN);
  open(RPMMACROS_OUT, ">$hpath/macros/$host_i_runon/rpmmacros_trunk") if ($build_type eq "trunk");
  open(RPMMACROS_OUT, ">$hpath/macros/$host_i_runon/rpmmacros_release") if ($build_type eq "release");
  foreach $line (@tmp_rpmmacros) {
    chomp $line;
    #ogo-gnustep_make...
    if ($package eq "ogo-gnustep_make") {
      $line = "\%ogo_gnustep_make_version $new_version" if ($line =~ m/^\%ogo_gnustep_make_version/);
      $line = "\%ogo_gnustep_make_release $new_svnrev" if ($line =~ m/^\%ogo_gnustep_make_release/);
      $line = "\%ogo_gnustep_make_buildcount $new_buildcount" if ($line =~ m/^\%ogo_gnustep_make_buildcount/);
      $line = "\%ogo_gnustep_make_source $release_tarballname" if (($line =~ m/^\%ogo_gnustep_make_source/) and ($build_type eq "release"));
    }
    #libobjc-lf2...
    if ($package eq "libobjc-lf2") {
      $line = "\%libf_objc_version $new_version" if ($line =~ m/^\%libf_objc_version/);
      $line = "\%libf_objc_release trunk_r$new_svnrev" if (($line =~ m/^\%libf_objc_release/) and ($build_type eq "trunk"));
      $line = "\%libf_objc_release r$new_svnrev" if (($line =~ m/^\%libf_objc_release/) and ($build_type eq "release"));
      $line = "\%libf_objc_buildcount $new_buildcount" if ($line =~ m/^\%libf_objc_buildcount/);
      $line = "\%libf_objc_source $release_tarballname" if (($line =~ m/^\%libf_objc_source/) and ($build_type eq "release"));
    }
    #libfoundation...
    if ($package eq "libfoundation") {
      $line = "\%libf_version $new_version" if ($line =~ m/^\%libf_version/);
      $line = "\%libf_major_version $new_major" if ($line =~ m/^\%libf_major_version/);
      $line = "\%libf_minor_version $new_minor" if ($line =~ m/^\%libf_minor_version/);
      $line = "\%libf_release trunk_r$new_svnrev" if (($line =~ m/^\%libf_release/) and ($build_type eq "trunk"));
      $line = "\%libf_release r$new_svnrev" if (($line =~ m/^\%libf_release/) and ($build_type eq "release"));
      $line = "\%libf_buildcount $new_buildcount" if ($line =~ m/^\%libf_buildcount/);
      $line = "\%libf_source $release_tarballname" if (($line =~ m/^\%libf_source/) and ($build_type eq "release"));
      $line = "\%libf_libversion $libversion" if ($line =~ m/^\%libf_libversion/);
    }
    #libical-sope-devel...
    if ($package eq "libical-sope-devel") {
      $line = "\%libical_version $new_version" if ($line =~ m/^\%libical_version/);
      $line = "\%libical_release trunk_r$new_svnrev" if (($line =~ m/^\%libical_release/) and ($build_type eq "trunk"));
      $line = "\%libical_release r$new_svnrev" if (($line =~ m/^\%libical_release/) and ($build_type eq "release"));
      $line = "\%libical_buildcount $new_buildcount" if ($line =~ m/^\%libical_buildcount/);
      $line = "\%libical_source $release_tarballname" if (($line =~ m/^\%libical_source/) and ($build_type eq "release"));
    }
    #sope..
    if ($package eq "sope") {
      $line = "\%sope_version $new_version" if ($line =~ m/^\%sope_version/);
      $line = "\%sope_major_version $new_major" if ($line =~ m/^\%sope_major_version/);
      $line = "\%sope_minor_version $new_minor" if ($line =~ m/^\%sope_minor_version/);
      $line = "\%sope_release trunk_r$new_svnrev" if (($line =~ m/^\%sope_release/) and ($build_type eq "trunk"));
      $line = "\%sope_release r$new_svnrev" if (($line =~ m/^\%sope_release/) and ($build_type eq "release"));
      $line = "\%sope_buildcount $new_buildcount" if ($line =~ m/^\%sope_buildcount/);
      $line = "\%sope_source $release_tarballname" if (($line =~ m/^\%sope_source/) and ($build_type eq "release"));
      $line = "\%sope_libversion $libversion" if ($line =~ m/^\%sope_libversion/);
    }
    #opengroupware...
    if ($package eq "opengroupware") {
      $line = "\%ogo_version $new_version" if ($line =~ m/^\%ogo_version/);
      $line = "\%ogo_release trunk_r$new_svnrev" if (($line =~ m/^\%ogo_release/) and ($build_type eq "trunk"));
      $line = "\%ogo_release r$new_svnrev" if (($line =~ m/^\%ogo_release/) and ($build_type eq "release"));
      $line = "\%ogo_buildcount $new_buildcount" if ($line =~ m/^\%ogo_buildcount/);
      $line = "\%ogo_source $release_tarballname" if (($line =~ m/^\%ogo_source/) and ($build_type eq "release"));
    }
    #mod_ngobjweb...
    if ($package =~ m/^mod_ngobjweb_/) {
      $line = "\%mod_ngobjweb_version $new_version" if ($line =~ m/^\%mod_ngobjweb_version/);
      $line = "\%mod_ngobjweb_release trunk_r$new_svnrev" if (($line =~ m/^\%mod_ngobjweb_release/) and ($build_type eq "trunk"));
      $line = "\%mod_ngobjweb_release r$new_svnrev" if (($line =~ m/^\%mod_ngobjweb_release/) and ($build_type eq "release"));
      $line = "\%mod_ngobjweb_buildcount $new_buildcount" if ($line =~ m/^\%mod_ngobjweb_buildcount/);
      $line = "\%mod_ngobjweb_source $release_tarballname" if (($line =~ m/^\%mod_ngobjweb_source/) and ($build_type eq "release"));
    }
    #ogo-environment...
    if ($package eq "ogo-environment") {
      $line = "\%ogo_env_version $new_version" if ($line =~ m/^\%ogo_env_version/);
      $line = "\%ogo_env_release trunk_r$new_svnrev" if (($line =~ m/^\%ogo_env_release/) and ($build_type eq "trunk"));
      $line = "\%ogo_env_release r$new_svnrev" if (($line =~ m/^\%ogo_env_release/) and ($build_type eq "release"));
      $line = "\%ogo_env_buildcount $new_buildcount" if ($line =~ m/^\%ogo_env_buildcount/);
    }
    #opengroupware-pilot-link...
    if ($package eq "opengroupware-pilot-link") {
      $line = "\%ogo_pilotlink_version $new_version" if ($line =~ m/^\%ogo_pilotlink_version/);
      $line = "\%ogo_pilotlink_release trunk_r$new_svnrev" if (($line =~ m/^\%ogo_pilotlink_release/) and ($build_type eq "trunk"));
      $line = "\%ogo_pilotlink_release r$new_svnrev" if (($line =~ m/^\%ogo_pilotlink_release/) and ($build_type eq "release"));
      $line = "\%ogo_pilotlink_buildcount $new_buildcount" if ($line =~ m/^\%ogo_pilotlink_buildcount/);
      $line = "\%ogo_pilotlink_source $release_tarballname" if (($line =~ m/^\%ogo_pilotlink_source/) and ($build_type eq "release"));
    }
    #opengroupware-nhsc...
    if ($package eq "opengroupware-nhsc") {
      $line = "\%ogo_nhsc_version $new_version" if ($line =~ m/^\%ogo_nhsc_version/);
      $line = "\%ogo_nhsc_release trunk_r$new_svnrev" if (($line =~ m/^\%ogo_nhsc_release/) and ($build_type eq "trunk"));
      $line = "\%ogo_nhsc_release r$new_svnrev" if (($line =~ m/^\%ogo_nhsc_release/) and ($build_type eq "release"));
      $line = "\%ogo_nhsc_buildcount $new_buildcount" if ($line =~ m/^\%ogo_nhsc_buildcount/);
      $line = "\%ogo_nhsc_source $release_tarballname" if (($line =~ m/^\%ogo_nhsc_source/) and ($build_type eq "release"));
    }
    #epoz
    if ($package eq "epoz") {
      $line = "\%epoz_version $new_version" if ($line =~ m/^\%epoz_version/);
      $line = "\%epoz_release trunk_r$new_svnrev" if (($line =~ m/^\%epoz_release/) and ($build_type eq "trunk"));
      $line = "\%epoz_release r$new_svnrev" if (($line =~ m/^\%epoz_release/) and ($build_type eq "release"));
      $line = "\%epoz_buildcount $new_buildcount" if ($line =~ m/^\%epoz_buildcount/);
      $line = "\%epoz_source $release_tarballname" if (($line =~ m/^\%epoz_source/) and ($build_type eq "release"));
    }
    #ogo-database-setup...
    if ($package eq "ogo-database-setup") {
      $line = "\%ogo_dbsetup_version $new_version" if ($line =~ m/^\%ogo_dbsetup_version/);
      $line = "\%ogo_dbsetup_release trunk_r$new_svnrev" if (($line =~ m/^\%ogo_dbsetup_release/) and ($build_type eq "trunk"));
      $line = "\%ogo_dbsetup_release r$new_svnrev" if (($line =~ m/^\%ogo_dbsetup_release/) and ($build_type eq "release"));
      $line = "\%ogo_dbsetup_buildcount $new_buildcount" if ($line =~ m/^\%ogo_dbsetup_buildcount/);
    }
    #see flavour detector...
    $line = "\%distribution $distrib_define" if ($line =~ m/^\%distribution/);
    print RPMMACROS_OUT "$line\n";
  }
}

sub get_current_from_rpmmacro {
  my @current_versions;
  my $cline;
  open(CURRENT, "$hpath/macros/$host_i_runon/rpmmacros_trunk") if ($build_type eq "trunk");
  open(CURRENT, "$hpath/macros/$host_i_runon/rpmmacros_release") if ($build_type eq "release");
  @current_versions = <CURRENT>;
  close(CURRENT);
  foreach $cline (@current_versions) {
    chomp $cline;
    #ogo-gnustep_make...
    if ($package eq "ogo-gnustep_make") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_gnustep_make_version\s+//);
      $cur_svnrev = "0";
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_gnustep_make_buildcount\s+//);
    }
    #libobjc-lf2...
    if ($package eq "libobjc-lf2") {
      $cur_version = $cline if ($cline =~ s/^\%libf_objc_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%libf_objc_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%libf_objc_buildcount\s+//);
    }
    #libfoundation...
    if ($package eq "libfoundation") {
      $cur_version = $cline if ($cline =~ s/^\%libf_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%libf_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%libf_buildcount\s+//);
    }
    #libical-sope-devel...
    if ($package eq "libical-sope-devel") {
      $cur_version = $cline if ($cline =~ s/^\%libical_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%libical_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%libical_buildcount\s+//);
    }
    #sope...
    if ($package eq "sope") {
      $cur_version = $cline if ($cline =~ s/^\%sope_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%sope_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%sope_buildcount\s+//);
    }
    #opengroupware...
    if ($package eq "opengroupware") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%ogo_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_buildcount\s+//);
    }
    #mod_ngobjweb...
    if ($package =~ m/^mod_ngobjweb_/) {
      $cur_version = $cline if ($cline =~ s/^\%mod_ngobjweb_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%mod_ngobjweb_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%mod_ngobjweb_buildcount\s+//);
    }
    #ogo-environment
    if ($package eq "ogo-environment") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_env_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%ogo_env_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_env_buildcount\s+//);
    }
    #opengroupware-pilot-link
    if ($package eq "opengroupware-pilot-link") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_pilotlink_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%ogo_pilotlink_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_pilotlink_buildcount\s+//);
    }
    #opengroupware-nhsc
    if ($package eq "opengroupware-nhsc") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_nhsc_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%ogo_nhsc_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_nhsc_buildcount\s+//);
    }
    #epoz
    if ($package eq "epoz") {
      $cur_version = $cline if ($cline =~ s/^\%epoz_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%epoz_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%epoz_buildcount\s+//);
    }
    #ogo-database-setup
    if ($package eq "ogo-database-setup") {
      $cur_version = $cline if ($cline =~ s/^\%ogo_dbsetup_version\s+//);
      $cur_svnrev = $cline if ($cline =~ s/^\%ogo_dbsetup_release\s+//);
      $cur_buildcount = $cline if ($cline =~ s/^\%ogo_dbsetup_buildcount\s+//);
    }
  }
  #wipe out prefix to svn revision used in rpmmacros_trunk/rpmmacros_release before comparision...
  $cur_svnrev =~ s/\D+//g;
  print "[CURRENT RPMMACROS] - $package VERSION:$cur_version SVNREV:$cur_svnrev BUILDCOUNT:$cur_buildcount\n" if ($verbose eq "yes");
  # * evertime the svn revision changes ... we should build a new rpm
  # * and bump the buildcount - or not? why bumping the buildcount when svn revision
  #   bumped too? Seems silly... should only apply when we force a rebuild.
  unless("$cur_svnrev" eq "$new_svnrev") {
    $do_build = "yes";
    print "[DOBUILD LOGIC]     - $package SVNREV NEW: $new_svnrev SVNREV OLD: $cur_svnrev -> setting \$do_build = \"$do_build\"\n" if ($verbose eq "yes");
  }
  unless("$cur_version" eq "$new_version") {
    $do_build = "yes";
    $version_bumped = "yes";
    print "[DOBUILD LOGIC]     - $package VERSION NEW: $new_version VERSION OLD: $cur_version -> setting \$do_build = \"$do_build\"\n" if ($verbose eq "yes");
  }
  #next case matches whenever we see a SVNREV change without a bumped version.
  if (("$do_build" eq "yes") and ("$version_bumped" eq "no")) {
    $new_buildcount = $cur_buildcount;
    $new_buildcount++ unless ($bump_buildcount eq "no");
    print "[DOBUILD LOGIC]     - $package raising buildcount from: $cur_buildcount to: $new_buildcount\n" if (($verbose eq "yes") and ($bump_buildcount eq "yes"));
    print "[DOBUILD LOGIC]     - $package not raising buildcount from - current buildcount is $new_buildcount\n" if (($verbose eq "yes") and ($bump_buildcount eq "no"));
  }
  # next case deals with major/minor version bumps... we're resetting the buildcount
  # to '0' again (unless... see code.)
  if (("$do_build" eq "yes") and ("$version_bumped" eq "yes")) {
    $new_buildcount = $cur_buildcount;
    $new_buildcount = "0" unless ($bump_buildcount eq "no");
    print "[DOBUILD LOGIC]     - $package resetting buildcount to: $new_buildcount because version changed from: $cur_version to: $new_version\n" if ($verbose eq "yes");
  }
  if (("$do_build" eq "no") and ("$force_rebuild" eq "yes")) {
    $new_buildcount = $cur_buildcount;
    $new_buildcount++ unless ($bump_buildcount eq "no");
    print "[DOBUILD LOGIC]     - $package rebuild not necessary but I was called with force rebuild bumping from: $cur_buildcount to: $new_buildcount\n" if ($verbose eq "yes");
    $do_build = "yes";
  }
  #don't waste time rebuilding mod_ngobjweb, epoz, libfoundation with every svn revision change...
  #we only want to rebuild this package if we see the version has changed.
  if (($package =~ m/^(mod_ngobjweb_|^epoz|^libfoundation)/) and ($force_rebuild eq "no") and ("$cur_version" eq "$new_version")) {
    $do_build = "no";
    print "[DOBUILD LOGIC]     - $package prevented rebuild of $package because old: $cur_version new: $new_version are the same.\n" if ($verbose eq "yes");
  }
  if ("$do_build" eq "no") {
    print "[DOBUILD LOGIC]     - $package rebuild not necessary because \$do_build = $do_build:\n" if ($verbose eq "yes");
    print "[DOBUILD LOGIC]     - $package same versions -> old: $cur_version new: $new_version\n" if ($verbose eq "yes");
    print "[DOBUILD LOGIC]     - $package same svnrev's -> old: $cur_svnrev  new: $new_svnrev\n" if ($verbose eq "yes");
    print "[DOBUILD LOGIC]     - $package '$memyself' will quit its work here. Goodbye! :p\n" if ($verbose eq "yes");
    exit 0;
  }
  print "[DOBUILD LOGIC]     - $package final result for \$do_build is $do_build\n" if ($verbose eq "yes");
  print "[DOBUILD LOGIC]     - $package final result for \$new_buildcount is $new_buildcount\n" if ($verbose eq "yes");


}

sub collect_patchinfo {
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
    open(LIBOBJCLF2, "tar xfzO $sources_dir/libobjc-lf2-trunk-latest.tar.gz libobjc-lf2/REVISION.svn|") if ($build_type eq "trunk");
    open(LIBOBJCLF2, "tar xfzO $sources_dir/$release_tarballname libobjc-lf2/REVISION.svn|") if ($build_type eq "release");
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
    open(LIBF, "tar xfzO $sources_dir/libfoundation-trunk-latest.tar.gz libfoundation/Version libfoundation/REVISION.svn|") if ($build_type eq "trunk");
    open(LIBF, "tar xfzO $sources_dir/$release_tarballname libfoundation/Version libfoundation/REVISION.svn|") if ($build_type eq "release");
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
    $libversion = "$new_major.$new_minor";
    $remote_release_dirname = "ThirdParty" if($build_type eq "release");
  }
  ###########################################################################
  if ($package eq "libical-sope-devel") {
    open(LIBICAL, "tar xfzO $sources_dir/libical-sope-trunk-latest.tar.gz libical-sope/REVISION.svn|") if ($build_type eq "trunk");
    open(LIBICAL, "tar xfzO $sources_dir/$release_tarballname libical-sope/REVISION.svn|") if ($build_type eq "release");
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
    open(SOPE, "tar xfzO $sources_dir/sope-trunk-latest.tar.gz sope/Version sope/REVISION.svn|") if ($build_type eq "trunk");
    open(SOPE, "tar xfzO $sources_dir/$release_tarballname sope/Version sope/REVISION.svn|") if ($build_type eq "release");
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
    $libversion = "$new_major.$new_minor";
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
      # %version cannot contain dashes... rpm will complain if it does
      $remote_release_dirname = "sope-$new_version-$release_codename";
    }
  }
  ###########################################################################
  if ($package eq "opengroupware") {
    open(OGO, "tar xfzO $sources_dir/opengroupware.org-trunk-latest.tar.gz opengroupware.org/REVISION.svn|") if ($build_type eq "trunk");
    open(OGO, "tar xfzO $sources_dir/$release_tarballname opengroupware.org/REVISION.svn|") if ($build_type eq "release");
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
      # %version cannot contain dashes... rpm will complain if it does
      $remote_release_dirname = "opengroupware-$new_version-$release_codename";
    }
  }
  ###########################################################################
  if ($package =~ m/^mod_ngobjweb_/) {
    open(NGO, "tar xfzO $sources_dir/sope-mod_ngobjweb-trunk-latest.tar.gz sope-mod_ngobjweb/REVISION.svn|") if ($build_type eq "trunk");
    open(NGO, "tar xfzO $sources_dir/$release_tarballname sope-mod_ngobjweb/REVISION.svn|") if ($build_type eq "release");
    while(<NGO>) {
      chomp;
      $new_svnrev = $_ if ($_ =~ s/^SVN_REVISION:=//g);
    }
    close(NGO);
    chomp $new_svnrev if (defined $new_svnrev);
    if ($flavour_we_build_upon eq "fedora") {
      $new_version = `/bin/rpm --qf '%{version}' -q httpd-devel`;
      print "Senseless to continue... got no version for mod_ngobjweb whilst '/bin/rpm --qf '%{version}' -q httpd-devel'\n" and exit 1 if ($?);
    } elsif ((($flavour_we_build_upon eq "suse") or ($flavour_we_build_upon eq "mandrake")) and ($distrib_define !~ m/^suse sles-8/i) or ($distrib_define !~ m/^conectiva linux 10/i)) {
      $new_version = `/bin/rpm --qf '%{version}' -q apache2-devel`;
      print "Sensesless to continue... got no version for mod_ngobjweb whilst '/bin/rpm --qf '%{version}' -q apache2-devel'\n" and exit 1 if ($?);
    } elsif ($distrib_define =~ m/^suse sles-8/i) {
      $new_version = `/bin/rpm --qf '%{version}' -q apache-devel`;
      print "Senseless to continue... got no version for mod_ngobjweb whilst '/bin/rpm --qf '%{version}' -q apache-devel'\n" and exit 1 if ($?);
    } elsif ($distrib_define =~ m/^conectiva linux 10/i) {
      $new_version = `/bin/rpm --qf '%{version}' -q apache-devel`;
      print "Senseless to continue... got no version for mod_ngobjweb whilst '/bin/rpm --qf '%{version}' -q apache-devel'\n" and exit 1 if ($?);
    }
  }
  ###########################################################################
  if ($package eq "ogo-environment") {
    $new_major = "1.0a";
    $new_minor = "0";
    $new_svnrev = "0";
    $new_version = "$new_major";
  }
  ###########################################################################
  if ($package eq "opengroupware-pilot-link") {
    #hardcoded for now... shouldn't change often
    $new_major = "0";
    $new_minor = "11";
    $new_sminor = "8";
    $new_svnrev = "0";
    $new_version = "$new_major.$new_minor.$new_sminor";
  }
  ###########################################################################
  if ($package eq "opengroupware-nhsc") {
    #hardcoded for now... shouldn't change often
    $new_major = "1";
    $new_minor = "0";
    $new_sminor = "0";
    $new_svnrev = "0";
    $new_version = "$new_major.$new_minor";
  }
  ###########################################################################
  if ($package eq "epoz") {
    open(EPOZ, "tar xfzO $sources_dir/sope-epoz-trunk-latest.tar.gz sope-epoz/Version sope-epoz/REVISION.svn|") if ($build_type eq "trunk");
    open(EPOZ, "tar xfzO $sources_dir/$release_tarballname sope-epoz/Version sope-epoz/REVISION.svn|") if ($build_type eq "release");
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
  if ($package eq "ogo-database-setup") {
    $new_major = "1.0a";
    $new_minor = "0";
    $new_svnrev = "0";
    $new_version = "$new_major";
  }
  ####
  print "[CURRENT SOURCE]    - $package VERSION:$new_version SVNREV:$new_svnrev\n" if ($verbose eq "yes");
}

sub link_rpmmacros {
  if (( -e "$hpath/.rpmmacros") and (! -l "$hpath/.rpmmacros")) {
    #useful if one uses $0 on another host where other rpmmacros
    #are already stored in .rpmmacros as a file by itself...
    print "$hpath/.rpmmacros is not a symlink as expected...\n";
    print "you prolly might want to check this first\n";
    exit 1;
  }
  if ((! -e "$hpath/macros/$host_i_runon/rpmmacros_trunk") and (! -e "$hpath/macros/$host_i_runon/rpmmacros_release")) {
    print "Neither rpmmacros_trunk nor rpmmacros_release exist...\n";
    print "How the heck should I build $package if I have no clues?!\n";
    exit 1;
  }
  if (($build_type eq "trunk") and (! -e "$hpath/macros/$host_i_runon/rpmmacros_trunk")) {
    print "Attempt to build $package $build_type without existing rpmmacros_trunk\n";
    print "will fail royally!\n";
    exit 1;
  }
  if (($build_type eq "release") and (! -e "$hpath/macros/$host_i_runon/rpmmacros_release")) {
    print "Attempt to build $package $build_type without existing rpmmacros_release\n";
    print "will fail royally!\n";
    exit 1;
  }
  unlink "$hpath/.rpmmacros" if ( -l "$hpath/.rpmmacros");
  if ($build_type eq "trunk") {
    print "[RELINK_RPMMACROS]  - Linking for $build_type build.\n" if ($verbose eq "yes");
    symlink "$hpath/macros/$host_i_runon/rpmmacros_trunk", "$hpath/.rpmmacros" || die "Arrr!: $!";
  }
  if ($build_type eq "release") {
    print "[RELINK_RPMMACROS]  - Linking for $build_type build.\n" if ($verbose eq "yes");
    symlink "$hpath/macros/$host_i_runon/rpmmacros_release", "$hpath/.rpmmacros" || die "Arrr!: $!";
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
  #present in rpm/SOURCES - just a hint :p - but you'll notice
  #when the script dies.
  #Defaults - if no other options are given - to:
  #download=yes for a build_type=trunk
  return if (grep /^$package$/, @package_wo_source) and print "[DOWNLOAD_SRC]      - Will not download src for $package bc it should be already in $sources_dir!\n";
  my @latest;
  my $sourcefile;
  my $dl_candidate;
  my $destfilename;
  my $package_mapped_tosrc = $package;
  #<trunk>
  if(("$do_download" eq "yes") and ("$build_type" eq "trunk")) {
    print "[DOWNLOAD_SRC]      - Download sources for a trunk build!\n" if ($verbose eq "yes");
    @latest = `wget -q --proxy=off -O - http://$dl_host/sources/trunk/LATESTVERSION`;
    #remap package name to its corresponding source tarball prefix
    #bc specfile names are not always the same as the source tarball name
    $package_mapped_tosrc = "libobjc-lf2" if ("$package" eq "libobjc-lf2");
    $package_mapped_tosrc = "libfoundation" if ("$package" eq "libfoundation");
    $package_mapped_tosrc = "libical-sope" if ("$package" eq "libical-sope-devel");
    $package_mapped_tosrc = "opengroupware.org" if ("$package" eq "opengroupware");
    $package_mapped_tosrc = "opengroupware.org-pilot-link" if ("$package" eq "opengroupware-pilot-link");
    $package_mapped_tosrc = "opengroupware.org-nhsc" if ("$package" eq "opengroupware-nhsc");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_fedora");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_mdk101");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_mdk100");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_suse82");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_suse91");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_suse92");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_slss8");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_sles9");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_rhel3");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_redhat9");
    $package_mapped_tosrc = "sope-mod_ngobjweb" if ("$package" eq "mod_ngobjweb_conectiva10");
    $package_mapped_tosrc = "sope-epoz" if ("$package" eq "epoz");
    foreach $sourcefile (@latest) {
      $destfilename = shift;
      chomp $sourcefile;
      $dl_candidate = $sourcefile if ($sourcefile =~ m/^$package_mapped_tosrc-trunk/i);
    }
    $destfilename = $dl_candidate;
    $destfilename =~ s/-r\d+-\d+/-latest/g;
    print "[DOWNLOAD_SRC]      - Will download $dl_candidate and save the file as $destfilename\n" if ($verbose eq "yes");
    `wget -q --proxy=off -O "$sources_dir/$destfilename" http://$dl_host/sources/trunk/$dl_candidate`;
  }
  #</trunk>
  #<release>
  if(("$do_download" eq "yes") and ("$build_type" eq "release") and ($package !~ m/^mod_ngobjweb_/)) {
    #MD5_INDEX comes in handy here, bc this file keeps track of all uploaded releases
    @latest = `wget -q --proxy=off -O - http://$dl_host/sources/releases/MD5_INDEX`;
    chomp $release_tarballname;
    if (grep /$release_tarballname$/, @latest) {
      print "[DOWNLOAD_SRC]      - $release_tarballname should be present for download.\n" if ($verbose eq "yes");
      print "[DOWNLOAD_SRC]      - going to retrieve into -> $sources_dir/$release_tarballname\n" if ($verbose eq "yes");
      `wget -q --proxy=off -O "$sources_dir/$release_tarballname" http://$dl_host/sources/releases/$release_tarballname`;
    } elsif ( -f "$sources_dir/$release_tarballname" ) {
      print "[DOWNLOAD_SRC]      - using $sources_dir/$release_tarballname\n" if ($verbose eq "yes");
      print "[DOWNLOAD_SRC]      - bc I had no luck downloading the sources from $dl_host\n" if ($verbose eq "yes");
    } else {
      print "[DOWNLOAD_SRC]      - Looks like $release_tarballname isn't even present at neither $dl_host nor $sources_dir/.\n" if ($verbose eq "yes");
      print "[DOWNLOAD_SRC]      - Senseless to continue - goodbye!\n" if ($verbose eq "yes");
      exit 1;
    }
  #</release>
  }
}

sub get_commandline_options {
  getopt('pftbdcvusr');
  #self explaining...
  if (!$opt_p) {
    print "No package given!\n";
    print "Package can be one out of:\n@poss_packages\n";
    print "Usage: $0 -p <package>\n";
    exit 127;
  } else {
    $package = $opt_p;
    chomp $package;
    $package = basename($package);
    $package =~ s/.spec$//g;
    print "No valid package given!\nPackage can be one out of:\n@poss_packages\nUsage: $0 -p <package>\n" and exit 127 unless (grep /^$package$/, @poss_packages);
  }
  #here we trigger if we force a rebuild
  #that is - ie - we rebuild a rpm although
  #the SVN revision didn't changed
  #might be handy for specfile changes
  #default >> no - don't force a rebuild if not necessary
  if (!$opt_f or ($opt_f !~ m/^yes$/i)) {
    $force_rebuild = "no";
  } else {
    $force_rebuild = "yes";
  }
  #distinguish between different build type
  #(either trunk or release)
  #default >> trunk - build a 'trunk' rpm
  if (!$opt_t or ($opt_t !~ m/^release$/i)) {
    $build_type = "trunk";
  } else {
    $build_type = "release";
  }
  #the following might be handy to debug build issues
  #without raising the buildcount on subsequent build attempts
  #thus - we safe our .rpmmacros buildcount settings
  #default >> no - don't bump buildcount
  if (!$opt_b or ($opt_b !~ m/^yes$/i)) {
    $bump_buildcount = "no";
  } else {
    $bump_buildcount = "yes";
  }
  #do_download decides whether we should attempt to download
  #current sources from MASTER_SITE_OPENGROUPWARE or if we
  #are happy with the sources in rpm/SOURCES
  #this requires `wget`
  #default >> yes - always attempt to download the sources from \$dl_host
  if (!$opt_d or ($opt_d !~ m/^no$/i)) {
    $do_download = "yes";
  } else {
    $do_download = "no";
  }
  #release tarballname specifies for which release we actually
  #build this package... this setting is required, if we
  #build a release package.
  #I need a real name here ala:
  # opengroupware.org-1.0alpha8-shapeshifter-r233.tar.gz or
  # sope-4.3.8-shapeshifter-r210.tar.gz
  # (not required for 'ogo-environment.spec') bc there
  # we don't have a sourcefile
  # 
  # The release trigger scripts determine the `real` name
  # and it gets then feeded into the 'purveyor_of_rpms.pl'
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
    #obviously - the package will be present in rpm/RPMS/${arch}
    $do_upload = "no";
  } else {
    $do_upload = "yes"
  }
  #explicitly use the named specfile instead of the one
  #we keep in rpm/SPECS/
  #this is required to build releases
  #trigger_sope_releases.pl/trigger_opengroupware_releases.pl use this.
  if (!$opt_s) {
    #this is the default location...
    #(I really should copy the specfile from the sourcetarball into $specs_dir
    # prior the trunk builds - TODO)
    $use_specfile = "$specs_dir/$package.spec";
    $use_specdir_specfile = "yes";
  } else {
    chomp $opt_s;
    #should be a relative path to the specfile
    $use_specfile = $opt_s;
    $use_specdir_specfile = "no";
  }
  #upload the package into \$rdirbase instead of the
  #automagically determined location on the \$dl_host
  #using this option ensures that certain packages end up
  #in the correct place (required to put ie ogo-environment,
  #mod_ngobjweb etc in the codenamed dirs.
  if (!$opt_r) {
    #defaults to nothing useful at all
  } else {
    chomp $opt_r;
    #Don't use a full pathname here (I don't basename($_) this var)!
    #The given directory already exists (I repeat... *already exists*)...
    #...because it was already created during another another run (either trigger_sope or trigger_opengroupware
    #release build)... there won't be a `normal` case where the script will die whilst trying to upload
    #a package into a non-existant directory.
    #Examples for a common option given to <-r> are available at:
    #  http://download.opengroupware.org/packages/fedora-core3/releases/
    #  
    $rdirbase = $opt_r;
  }
  #sanitize... weird option combinations
  if (($build_type eq "release") and ($release_tarballname eq "none") and (! grep /^$package$/, @package_wo_source)) {
    print "Check your commandline - no '-c <tarballname>' given for release build!\n";
    print "I cannot build a release without knowing the release_tarballname\n";
    exit 127;
  }
  if ($verbose eq "yes") {
    print "########################################\n"; 
    print "[COMMANDLINE]       - host I run on             $host_i_runon\n";
    print "[COMMANDLINE]       - package to build          <-p $package>\n";
    print "[COMMANDLINE]       - force_rebuild             <-f $force_rebuild>\n";
    print "[COMMANDLINE]       - type of build             <-t $build_type>\n";
    print "[COMMANDLINE]       - bump buildcount           <-b $bump_buildcount>\n";
    print "[COMMANDLINE]       - do download               <-d $do_download>\n";
    print "[COMMANDLINE]       - do upload                 <-u $do_upload>\n";
    print "[COMMANDLINE]       - release tarballname       <-c $release_tarballname>\n";
    print "[COMMANDLINE]       - verbose                   <-v $verbose>\n";
    print "[COMMANDLINE]       - using specfile            <-s $use_specfile>\n";
    print "[COMMANDLINE]       - uploading into directory  <-r $rdirbase>\n" if($opt_r);
    print "[COMMANDLINE]       - uploading into directory  using default location determined by $memyself\n" if(!$opt_r);
    print "[COMMANDLINE]       - detected distribution     $distrib_define\n";
    print "[COMMANDLINE]       - flavour we build upon     $flavour_we_build_upon\n";
  }
}

sub prepare_build_env {
  #we use rpm instead of the traditional redhat directory style
  #logs will eat the buildlogs
  my $dir;
  my @dirs = qw( logs macros rpm rpm/BUILD rpm/RPMS rpm/RPMS/athlon rpm/RPMS/i386 rpm/RPMS/i486 rpm/RPMS/i586 rpm/RPMS/i686 rpm/RPMS/noarch rpm/SOURCES rpm/SPECS rpm/SPECS/initscript_templates rpm/SRPMS rpm/tmp spec_tmp install_tmp );
  if (!$ENV{'HOME'}) {
    print "[FATAL]     Oups! It seems as if there's no valid \$HOME defined.\n";
    exit 127;
  }
  push @dirs, "macros/$host_i_runon";
  for $dir (@dirs) {
    print "[PREPARE_ENV]       - Create missing directory: $ENV{'HOME'}/$dir\n" and mkdir("$ENV{'HOME'}/$dir", 0755) if (! -d "$ENV{'HOME'}/$dir");
  }
  #generic flavour detector - guaranted to fail somewhere or on on older releases... :>
  #this flavour detect is currently in use to get the apache version for mod_ngobjweb
  #it's here bc apache2/httpd/httpd2 has got different names amongst the packagers
  #I'll prolly do a better flavour detector if I need a better one - for now, this is sufficient
  #for this purpose :p
  #what we get here is also used as %distribution in your .rpmmacros
  if ( -f "/etc/fedora-release" ) {
    $flavour_we_build_upon = "fedora";
    $distrib_define = `head -n1 /etc/fedora-release`;
    chomp $distrib_define;
  } elsif ( -f "/etc/SuSE-release") {
    $flavour_we_build_upon = "suse";
    $distrib_define = `head -n1 /etc/SuSE-release`;
    chomp $distrib_define;
  } elsif ( -f "/etc/mandrake-release" ) {
    $flavour_we_build_upon = "mandrake";
    $distrib_define = `head -n1 /etc/mandrake-release`;
    chomp $distrib_define;
  } elsif ( -f "/etc/redhat-release") {
    $flavour_we_build_upon = "fedora";
    $distrib_define = `head -n1 /etc/redhat-release`;
    chomp $distrib_define;
  } elsif ( -f "/etc/conectiva-release") {
    $flavour_we_build_upon = "conectiva";
    $distrib_define = `head -n1 /etc/conectiva-release`;
    chomp $distrib_define;
  }
}

#eval getconf("$ENV{'HOME'}/purveyor_of_rpms.conf") or die "FATAL: $@\n";
sub getconf {
  my $conffile = shift;
  local *F;
  open F, "< $conffile" or die "Error opening '$conffile' for read: $!";
  if(not wantarray){
    local $/ = undef;
    my $string = <F>;
    close F;
    return $string;
  }
  local $/ = "";
  my @a = <F>;
  close F;
  return @a;
}
