#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

use strict;
my $host_i_runon;
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

@sope_releases = `wget -q --proxy=off -O - http://$dl_host/sources/releases/MD5_INDEX`;
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
    print "Retrieving: http://$dl_host/sources/releases/$srel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$srel http://$dl_host/sources/releases/$srel");
    print "cleaning up prior actual build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
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
      my $single_req_package;
      my $libobjc_install_candidate;
      my $libobjc_install_candidate_devel;
      my $libfoundation_install_candidate;
      my $libfoundation_install_candidate_devel;
      print "building $buildtarget.spec requires me to install:\n";
      print "libobjc-lf2   -> $uselibobjc_lf2\n" if($uselibobjc_lf2);
      print "libFoundation -> $uselibfoundation\n" if($uselibfoundation);
      print "going to check availability of those ThirdParty requirements for $host_i_runon\n" if($has_certain_tp_requirements eq "yes");
      @tp_requirements = `wget -q --proxy=off -O - http://$dl_host/packages/$host_i_runon/releases/ThirdParty/MD5_INDEX`;
      foreach $single_req_package(@tp_requirements) {
        chomp $single_req_package;
        next unless($single_req_package =~ m/\.rpm$/i);
        $single_req_package =~ s/^.*\s+//g;
        if($uselibobjc_lf2) {
          $libobjc_install_candidate = $single_req_package if ($single_req_package =~ m/^$uselibobjc_lf2/i);
          #hrm :/ ... this looks so ugly.
          $libobjc_install_candidate_devel = `/bin/rpm --qf '%{name}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate` . "-devel-" . `/bin/rpm --qf '%{version}-%{release}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate`  . "." . `/bin/rpm --qf '%{arch}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate` . "\.rpm" if($libobjc_install_candidate);
        } 
        if ($uselibfoundation) {
          $libfoundation_install_candidate = $single_req_package if ($single_req_package =~ m/^$uselibfoundation/i);
          $libfoundation_install_candidate_devel = `/bin/rpm --qf '%{name}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate` . "-devel-" . `/bin/rpm --qf '%{version}-%{release}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate`  . "." . `/bin/rpm --qf '%{arch}' -qp http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate` . "\.rpm" if($libfoundation_install_candidate);
        }
      }
      if($uselibobjc_lf2) {
        print "Installing from remote location:\n";
        system("/usr/bin/sudo /bin/rpm -Uvh --force --noscripts http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate");
        system("/usr/bin/sudo /bin/rpm -Uvh --force --noscripts http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libobjc_install_candidate_devel");
      }
      if($uselibfoundation) {
        print "Installing from remote location:\n";
        system("/usr/bin/sudo /bin/rpm -Uvh --force --noscripts http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate");
        system("/usr/bin/sudo /bin/rpm -Uvh --force --noscripts http://$dl_host/packages/$host_i_runon/releases/ThirdParty/$libfoundation_install_candidate_devel");
      }
    } else {
      print "building $buildtarget.spec comes with no certain requirements (regarding TP packages).\n";
      print "thus I'll continue building $buildtarget.spec using the currently installed libobjc-lf2/libFoundation...\n";
      warn "WARNING: should I force reinstallation of libobjc-lf2-trunk-latest/libfoundation-trunk-latest???\n";
    }
    exit 0;
    print "SOPE_REL: building RPMS for SOPE $srel\n";
    print "calling `purveyor_of_rpms.pl -p sope $build_opts -c $srel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p sope $build_opts -c $srel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    print KNOWN_SOPE_RELEASES "$srel\n";
    print "recreating apt-repository for: $host_i_runon\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    print SSH "/home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n $buildtarget\n";
    print SSH "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/packages/$host_i_runon/releases/$buildtarget/\n";
    close(SSH);
    warn "WARN: EARLY EXIT EXIT EXIT EXIT ..... EXIT!\n";
    exit 0;
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
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -u no -d no -f yes -b no");
}
