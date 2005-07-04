#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

use strict;
my $host_i_runon;
my $mod_ngobjweb_to_use;
my $svn_host = 'svn.opengroupware.org';
my $svn = '/usr/bin/svn';
my $dl_host = "download.opengroupware.org";
my $www_user = "www";
my $www_host = "download.opengroupware.org";
my $i_really_had_sth_todo = "no";
my @latest;
my $tarball_name;
my $srel;
my $buildtarget;
my $hpath = "$ENV{HOME}/";
my @skip_list = qw( sope-4.2pre-r3.tar.gz
  sope-4.3.1-shapeshifter-r96.tar.gz
  sope-4.3.2-shapeshifter-r53.tar.gz
  sope-4.3.3-shapeshifter-r69.tar.gz
  sope-4.3.4-shapeshifter-r97.tar.gz
  sope-4.3.5-shapeshifter-r110.tar.gz
  sope-4.3.6-shapeshifter-r114.tar.gz
  sope-4.3.7-shapeshifter-r142.tar.gz
  sope-4.3.8-shapeshifter-r210.tar.gz
  sope-4.3.9-shapeshifter-r519.tar.gz
  sope-4.3.10-ultra-r520.tar.gz
  sope-4.4beta.0-voyager-r512.tar.gz
  sope-4.4beta.1-voyager-r513.tar.gz
  sope-4.4beta.2-voyager-r527.tar.gz
  sope-4.4beta.3-voyager-r602.tar.gz
  sope-4.5alpha.0-nevermind-r514.tar.gz
  sope-4.5alpha.1-nevermind-r515.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @sope_releases;
eval getconf("$ENV{'HOME'}/purveyor_of_rpms.conf") or die "FATAL: $@\n";

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

@sope_releases = `wget -q --proxy=off -O - http://$dl_host/nightly/sources/releases/MD5_INDEX`;
open(KNOWN_SOPE_RELEASES, ">> $hpath/SOPE.known.rel");
foreach $srel (@sope_releases) {
  chomp $srel;
  $srel =~ s/^.*\s+//g;
  next unless($srel =~ m/^sope/i);
  my @already_known_sope_rel = `cat $hpath/SOPE.known.rel`;
  next if (grep /$srel/, @skip_list);
  $buildtarget = $srel;
  $buildtarget =~ s/-r\d+.*$//g;
  unless(grep /\b$srel\b/, @already_known_sope_rel) {
    my $buildtargetspecfilesize;
    my @sope_spec;
    my @tp_requirements;
    my $has_certain_tp_requirements = "no";
    my $line;
    my $uselibobjc_lf2;
    my $uselibfoundation;
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/nightly/sources/releases/$srel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$srel http://$dl_host/nightly/sources/releases/$srel");
    print "cleaning up prior actual build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
    system("sudo /sbin/ldconfig");
    print "extracting specfile from $srel\n";
    system("mkdir $ENV{HOME}/spec_tmp/") unless (-e "$ENV{HOME}/spec_tmp/");
    system("tar xfzO $ENV{HOME}/rpm/SOURCES/$srel sope/maintenance/sope.spec >$ENV{HOME}/spec_tmp/$buildtarget.spec");
    $buildtargetspecfilesize = -s "$ENV{HOME}/spec_tmp/$buildtarget.spec";
    #extracted spec should have a reasonable size
    if( $buildtargetspecfilesize <= 1 ) {
      print "extracted specfile has a size of: $buildtargetspecfilesize\n";
      print "this is most likely an error and thus I'll quit here building $buildtarget.spec\n";
      #give hint about the most likely reason for this failure;
      print "HINT: make sure that sope.spec is present in $srel\n";
      exit 1;
    }
    open(BUILDHINTS, "$ENV{HOME}/spec_tmp/$buildtarget.spec");
    @sope_spec = <BUILDHINTS>;
    close(BUILDHINTS);
    foreach $line(@sope_spec) {
      chomp $line;
      $uselibobjc_lf2 = $line if ($line =~ s/^#UseLibObjc:\s+//g);
      $uselibfoundation = $line if ($line =~ s/^#UseLibFoundation:\s+//g);
      $has_certain_tp_requirements = "yes" if($uselibobjc_lf2);
      $has_certain_tp_requirements = "yes" if($uselibfoundation);
    }
    if($has_certain_tp_requirements eq "yes") {
      my $rc;
      my $single_req_package;
      my $libobjc_install_candidate;
      my $libobjc_install_candidate_devel;
      my $libobjc_install_candidate_name;
      my $libobjc_install_candidate_version;
      my $libobjc_install_candidate_release;
      my $libobjc_install_candidate_arch;
      my $libfoundation_install_candidate;
      my $libfoundation_install_candidate_devel;
      my $libfoundation_install_candidate_name;
      my $libfoundation_install_candidate_version;
      my $libfoundation_install_candidate_release;
      my $libfoundation_install_candidate_arch;
      system("mkdir $ENV{HOME}/install_tmp/") unless (-e "$ENV{HOME}/install_tmp/");
      print "building $buildtarget.spec requires me to install:\n";
      print "libobjc-lf2   -> $uselibobjc_lf2\n" if($uselibobjc_lf2);
      print "libFoundation -> $uselibfoundation\n" if($uselibfoundation);
      print "going to check availability of those ThirdParty requirements for $host_i_runon\n" if($has_certain_tp_requirements eq "yes");
      @tp_requirements = `wget -q --proxy=off -O - http://$dl_host/nightly/packages/$host_i_runon/releases/ThirdParty/MD5_INDEX`;
      foreach $single_req_package(@tp_requirements) {
        chomp $single_req_package;
        next unless($single_req_package =~ m/\.rpm$/i);
        $single_req_package =~ s/^.*\s+//g;
        if($uselibobjc_lf2) {
          $libobjc_install_candidate = $single_req_package if ($single_req_package =~ m/^$uselibobjc_lf2/i);
        } 
        if ($uselibfoundation) {
          $libfoundation_install_candidate = $single_req_package if ($single_req_package =~ m/^$uselibfoundation/i);
        }
      }
      if($libobjc_install_candidate) {
        print "downloading $libobjc_install_candidate to install_tmp/\n";
        $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$libobjc_install_candidate http://$dl_host/nightly/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate");
        print "FATAL: system call (wget) returned $rc whilst downloading $libobjc_install_candidate into install_tmp/\n" and exit 1 unless($rc == 0);
        #dissecting $libobjc_install_candidate in order to get the proper name for the corresponding -devel RPM
        $libobjc_install_candidate_arch = `/bin/rpm --qf '%{arch}' -qp $ENV{HOME}/install_tmp/$libobjc_install_candidate`;
        $libobjc_install_candidate_release = `/bin/rpm --qf '%{release}' -qp $ENV{HOME}/install_tmp/$libobjc_install_candidate`;
        $libobjc_install_candidate_version = `/bin/rpm --qf '%{version}' -qp $ENV{HOME}/install_tmp/$libobjc_install_candidate`;
        $libobjc_install_candidate_name = `/bin/rpm --qf '%{name}' -qp $ENV{HOME}/install_tmp/$libobjc_install_candidate`;
        $libobjc_install_candidate_devel = "$libobjc_install_candidate_name" . "-devel-" . "$libobjc_install_candidate_version" . "-" . "$libobjc_install_candidate_release" . "\." . "$libobjc_install_candidate_arch" . "\.rpm";
        print "downloading $libobjc_install_candidate_devel to install_tmp/\n";
        $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$libobjc_install_candidate_devel http://$dl_host/nightly/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate_devel");
        print "FATAL: system call (wget) returned $rc whilst downloading $libobjc_install_candidate_devel into install_tmp/\n" and exit 1 unless($rc == 0);
        #wipe out old and install the chosen one.
        system("sudo rpm -e `rpm -qa|grep -i '^libobjc-lf2'` --nodeps");
        system("/usr/bin/sudo /bin/rpm -Uvh --force $ENV{HOME}/install_tmp/$libobjc_install_candidate");
        system("/usr/bin/sudo /bin/rpm -Uvh --force $ENV{HOME}/install_tmp/$libobjc_install_candidate_devel");
        system("sudo /sbin/ldconfig");
      }
      if($libfoundation_install_candidate) {
        print "downloading $libfoundation_install_candidate to install_tmp/\n";
        $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$libfoundation_install_candidate http://$dl_host/nightly/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate");
        print "FATAL: system call (wget) returned $rc whilst downloading $libfoundation_install_candidate into install_tmp/\n" and exit 1 unless($rc == 0);
        #dissecting $libfoundation_install_candidate in order to get the proper name for the corresponding -devel RPM
        $libfoundation_install_candidate_arch = `/bin/rpm --qf '%{arch}' -qp $ENV{HOME}/install_tmp/$libfoundation_install_candidate`;
        $libfoundation_install_candidate_release = `/bin/rpm --qf '%{release}' -qp $ENV{HOME}/install_tmp/$libfoundation_install_candidate`;
        $libfoundation_install_candidate_version = `/bin/rpm --qf '%{version}' -qp $ENV{HOME}/install_tmp/$libfoundation_install_candidate`;
        $libfoundation_install_candidate_name = `/bin/rpm --qf '%{name}' -qp $ENV{HOME}/install_tmp/$libfoundation_install_candidate`;
        $libfoundation_install_candidate_devel = "$libfoundation_install_candidate_name" . "-devel-" . "$libfoundation_install_candidate_version" . "-" . "$libfoundation_install_candidate_release" . "\." . "$libfoundation_install_candidate_arch" . "\.rpm";
        print "downloading $libfoundation_install_candidate_devel to install_tmp/\n";
        $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$libfoundation_install_candidate_devel http://$dl_host/nightly//packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate_devel");
        print "FATAL: system call (wget) returned $rc whilst downloading $libfoundation_install_candidate into install_tmp/\n" and exit 1 unless($rc == 0);
        system("sudo rpm -e `rpm -qa|grep -i '^libfoundation'` --nodeps");
        system("/usr/bin/sudo /bin/rpm -Uvh --force $ENV{HOME}/install_tmp/$libfoundation_install_candidate");
        system("/usr/bin/sudo /bin/rpm -Uvh --force $ENV{HOME}/install_tmp/$libfoundation_install_candidate_devel");
        system("sudo /sbin/ldconfig");
      }
    } else {
      print "building $buildtarget.spec comes with no certain requirements (regarding TP packages).\n";
      print "thus I'll continue building $buildtarget.spec using the currently installed libobjc-lf2/libFoundation...\n";
      warn "WARNING: should I force reinstallation of libobjc-lf2-trunk-latest/libfoundation-trunk-latest???\n";
    }
    print "SOPE_REL: building RPMS for SOPE $srel\n";
    print "calling `purveyor_of_rpms.pl -p sope $build_opts -c $srel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p sope $build_opts -c $srel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    print KNOWN_SOPE_RELEASES "$srel\n";
    print "recreating apt-repository for: $host_i_runon\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    print SSH "/home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n $buildtarget\n";
    print SSH "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/releases/unstable/$buildtarget/$host_i_runon/\n";
    close(SSH);
  }
}
close(KNOWN_SOPE_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  if($host_i_runon eq "fedora-core2") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore2.sh");
  }
  if($host_i_runon eq "fedora-core3") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore3.sh");
  }
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^libfoundation` --nodeps");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -v yes -u no -d yes -f yes -b no -n yes");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libfoundation -v yes -u no -d yes -f yes -b no -n yes");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -u no -d yes -f yes -b no -n yes");
}
