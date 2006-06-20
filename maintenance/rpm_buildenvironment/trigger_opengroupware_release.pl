#!/usr/bin/perl -w
# frank reppin <frank@opengroupware.org> 2004
# 
# Here we trigger OGo release builds...
#
# Each OGo release is built against a specific
# SOPE release/version.
# I've commited comments/hints into some prior
# opengroupware.spec release files (alpha8 and alpha9)
# in order to know which SOPE release/version must be
# present prior the OGo release build:
# <opengroupware.spec_snippet>
#   #UseSOPE:      sope-4.4beta.1-voyager
# </opengroupware.spec_snippet>
# 
# UseSOPE => sope-<version>-<codename>.spec
#
# Normal workflow is... the SOPE version we need was
# already built (SOPE release cron runs before OGo release cron)
# and thus the release should be already present in the download area.
#
# * compare OGo.known.rel with current MD5_INDEX to see whether we
#   have a new release or not ('not' will finish the script, as well as @skip_list)
# * download new OGo release sources
# * cleanup currently installed SOPE and OGo RPMS (rpm -e)
# * extract specfile from 'OGo release sources' into spec_tmp/ and rename it
#   (to sth like opengroupware-<release_we_build_for>.spec)
# * parse through this specfile - seeking the above mentioned #UseSOPE: line
# * download this required SOPE release (!) into install_tmp/
# * install the required SOPE release (rpm -Uvh)
# * run 'purveyor_of_rpms.pl' in order to build the OGo release we've downloaded
#   using the specfile we've moved into spec_tmp/
# * 'purveyor_of_rpms.pl' will create a new directory in the downloadarea of this buildhost
#   on the downloadhost (in $buildhost/releases/)
# * 'purveyor_of_rpms.pl' will upload the packages created by this OGo release build into
#   this directory
# * 'purveyor_of_rpms.pl' will also build 'ogo-environment', 'ogo-database-setup'
#   and the 'mod_ngobjweb' RPMS... these packages will be uploaded into the same directory
#   where we just uploaded the OGo release RPMS
# * we then rebuild the apt repo and recreate the MD5_INDEX for this new directory on the
#   downloadhost
# * ... we also drop a 'SOPE.INFO' there (it contains an info about the SOPE release we've used
#   building this OGo release)
# * the just built OGo release version gets appended to 'OGo.known.rel'
# * if we're on either fcore2 or fcore3 - we start rebuilding the yum repositories
# * we initialize our buildenvironment:
#     - removing the above mentioned SOPE release
#     - removing the just built OGo release
#     - force 'purveyor_of_rpms.pl' to build a 'opengroupware' and 'sope' trunk

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
my $orel;
my $buildtarget;
my $apttarget;
my $version_override;
my $hpath = "$ENV{HOME}/";
my @skip_list = qw( opengroupware.org-0.9pre-r4.tar.gz
opengroupware.org-1.0alpha1-shapeshifter-r34.tar.gz
opengroupware.org-1.0alpha2-shapeshifter-r49.tar.gz
opengroupware.org-1.0alpha3-shapeshifter-r59.tar.gz
opengroupware.org-1.0alpha4-shapeshifter-r84.tar.gz
opengroupware.org-1.0alpha5-shapeshifter-r86.tar.gz
opengroupware.org-1.0alpha6-shapeshifter-r89.tar.gz
opengroupware.org-1.0alpha7-shapeshifter-r158.tar.gz
opengroupware.org-1.0alpha8-shapeshifter-r452.tar.gz
opengroupware.org-1.0alpha9-ultra-r630.tar.gz
opengroupware.org-1.0alpha10-ultra-r695.tar.gz
opengroupware.org-1.0alpha11-ultra-r778.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @ogo_releases;
my @ogo_spec;
my $rc;
my $line;
my $use_sope;
my @t_sope;
my $sope_rpm;
my $sope_spec;
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

@ogo_releases = `wget -q --proxy=off -O - http://$dl_host/nightly/sources/releases/MD5_INDEX`;
open(KNOWN_OGo_RELEASES, ">> $hpath/OGo.known.rel");
foreach $orel (@ogo_releases) {
  my @sope;
  my @t_sope;
  chomp $orel;
  $orel =~ s/^.*\s+//g;
  next unless($orel =~ m/^opengroupware.org/i);
  my @already_known_ogo_rel = `cat $hpath/OGo.known.rel`;
  next if (grep /$orel/, @skip_list);
  $buildtarget = $orel;
  $buildtarget =~ s/-r\d+.*$//g;
  unless(grep /\b$orel\b/, @already_known_ogo_rel) {
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/nightly/sources/releases/$orel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$orel http://$dl_host/nightly/sources/releases/$orel");
    #since we build the OGo release using a specific SOPE release... we must
    #cleanup everything prior the actual wanted OGo *and* SOPE builds
    #I don't use apt-get here bc not every RPM based distri provides a package (apt-get).
    #we must ensure that we have a debug=no libobjc-lf2 present...
    print "ensuring that we have a debug=no libobjc-lf2 present...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
    system("sudo /sbin/ldconfig");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -d yes -u no -t release -c libobjc-lf2-trunk-latest.tar.gz -f yes -b no");
    #we must ensure that we have a debug=no libfoundation present...
    print "ensuring that we have a debug=no libfoundation present...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^libfoundation` --nodeps");
    system("sudo /sbin/ldconfig");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p libfoundation -d yes -u no -t release -c libfoundation-trunk-latest.tar.gz -f yes -b no");
    print "cleaning up previous SOPE build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
    print "cleaning up previous OGo build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^ogo-|grep -vi gnustep` --nodeps");
    system("sudo /sbin/ldconfig");
    print "extracting specfile from $orel into $ENV{HOME}/spec_tmp/\n";
    system("mkdir $ENV{HOME}/spec_tmp/") unless (-e "$ENV{HOME}/spec_tmp/");
    system("mkdir $ENV{HOME}/install_tmp/") unless (-e "$ENV{HOME}/install_tmp/");
    #extract the specfile coming with the release tarball into a temporary location and keep it there
    #in order to build using exactly this specfile...
    system("tar xfzO $ENV{HOME}/rpm/SOURCES/$orel opengroupware.org/maintenance/opengroupware.spec >$ENV{HOME}/spec_tmp/$buildtarget.spec");
    system("tar xfzO $ENV{HOME}/rpm/SOURCES/$orel opengroupware.org/maintenance/ogofull-singlerpm.spec >$ENV{HOME}/spec_tmp/$buildtarget-singlerpm.spec");
    open(SOPEHINTS, "$ENV{HOME}/spec_tmp/$buildtarget.spec");
    @ogo_spec = <SOPEHINTS>;
    close(SOPEHINTS);
    foreach $line(@ogo_spec) {
      chomp $line;
      $use_sope = $line if ($line =~ s/^#UseSOPE:\s+//g);
    }
    #we should've already build this SOPE release at least once in an earlier run
    print "preparing SOPE... $use_sope\n";
    if($use_sope ne "trunk") {
      @t_sope = `wget -q --proxy=off -O - http://$dl_host/nightly/packages/$host_i_runon/releases/$use_sope/MD5_INDEX` or die "I DIE: couldn't fetch MD5_INDEX (http://$dl_host/nightly/packages/$host_i_runon/releases/$use_sope/MD5_INDEX)\n";
    } elsif($use_sope eq "trunk") {
      @t_sope = `wget -q --proxy=off -O - http://$dl_host/nightly/packages/$host_i_runon/trunk/LATESTVERSION` or die "I DIE: couldn't fetch LATESTVERSION (http://$dl_host/nightly/packages/$host_i_runon/trunk/LATESTVERSION)\n";
    }
    warn "WARNING: the following 'foreach' loops through each and every package found...\n";
    #rather rare case... it produces too much noise on stdout if there are re-rebuild versions of the same release (with different SVN revisions ofcourse)
    foreach $line (@t_sope) {
      chomp $line;
      next unless($line =~ m/sope.*\.rpm$/i);
      $line =~ s/^.*\s+//g;
      $sope_rpm = $line;
      print "downloading: $sope_rpm into install_tmp/";
      $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$sope_rpm http://$dl_host/nightly/packages/$host_i_runon/releases/$use_sope/$sope_rpm") if($use_sope ne "trunk");
      $rc = system("wget -q --proxy=off -O $ENV{HOME}/install_tmp/$sope_rpm http://$dl_host/nightly/packages/$host_i_runon/trunk/$sope_rpm") if($use_sope eq "trunk");
      print " ...success!\n" if($rc == 0);
      print "\nFATAL: system call (wget) returned $rc whilst downloading $sope_rpm into install_tmp/\n" and exit 1 unless($rc == 0);
      push(@sope, $sope_rpm);
    }
    my $rpm_count = @sope;
    print "must install $rpm_count RPMS ($use_sope) from install_tmp/ ... this may take some seconds\n";
    foreach $line(@sope) {
      $rc = system("sudo rpm -U --nodeps --force --noscripts $ENV{HOME}/install_tmp/$line");
      print "$line ($rc)...ok, done!\n" if($rc == 0);
      print "\nFATAL: system call (rpm) returned $rc whilst installing required RPMS from install_tmp/\n" and exit 1 unless($rc == 0);
    }
    system("sudo /sbin/ldconfig");
    print "OGo_REL: building RPMS for OGo $orel using $use_sope\n";
    print "calling `purveyor_of_rpms.pl -p opengroupware $build_opts -c $orel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p opengroupware $build_opts -c $orel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    print KNOWN_OGo_RELEASES "$orel\n";
    print "recreating apt-repository for: $host_i_runon >>> $buildtarget\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    #these differ...
    $apttarget = $buildtarget;
    $version_override = $buildtarget;
    $apttarget =~ s/^opengroupware\.org/opengroupware/g;
    $version_override =~ s/opengroupware\.org-(.*)-(.*)//g;
    $version_override = $1;
    system("$ENV{HOME}/purveyor_of_rpms.pl -p ogo-environment $build_opts -r $apttarget -o $version_override");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p ogo-database-setup $build_opts -r $apttarget -o $version_override");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p $mod_ngobjweb_to_use.spec $build_opts -c rpm/SOURCES/sope-mod_ngobjweb-trunk-latest.tar.gz -r $apttarget");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p ogo-gnustep_make $build_opts -c rpm/SOURCES/gnustep-make-1.10.0.tar.gz -r $apttarget");
    system("$ENV{HOME}/purveyor_of_rpms.pl -p ogofull $build_opts -c $orel -r $apttarget -s $ENV{HOME}/spec_tmp/$buildtarget-singlerpm.spec");
    print "thus calling: /home/www/scripts/release_in_nightly_apt4rpm_build.pl -d $host_i_runon -n $apttarget\n";
    print SSH "/home/www/scripts/release_in_nightly_apt4rpm_build.pl -d $host_i_runon -n $apttarget\n";
    print SSH "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/nightly/packages/$host_i_runon/releases/$apttarget/\n";
    print SSH "echo \"This OGo release was built using $use_sope\" >/var/virtual_hosts/download/nightly/packages/$host_i_runon/releases/$apttarget/SOPE.INFO\n";
    close(SSH);
  }
}
close(KNOWN_OGo_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  if($host_i_runon eq "fedora-core2") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore2.sh");
  }
  if($host_i_runon eq "fedora-core3") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore3.sh");
  }
  if($host_i_runon eq "fedora-core4") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore4.sh");
  }
  if($host_i_runon eq "fedora-core5") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_fcore5.sh");
  }
  if($host_i_runon eq "centos43") {
    print "building yum-repo for $host_i_runon\n";
    system("sh $ENV{HOME}/prepare_yum_centos43.sh");
  }
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^libfoundation` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^ogo-|grep -vi gnustep` --nodeps"); 
  system("sudo /sbin/ldconfig");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current trunk of everything built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -v yes -u no -d yes -f yes -b no -n yes");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libfoundation -v yes -u no -d yes -f yes -b no -n yes");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -u no -d yes -f yes -b no -n yes");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p opengroupware -v yes -u no -d yes -f yes -b no -n yes");
  system("sudo /sbin/ldconfig");
}
