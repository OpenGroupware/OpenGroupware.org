#!/usr/bin/perl -w
# frank reppin <frank@opengroupware.org> 2004
# 
# Here we trigger OGo release builds....
# Each OGo release is built against a specific
# SOPE release/version... and bc of this fact
# I've commited 2 comments/hints into some prior
# opengroupware.spec release files (alpha8 and alpha9)
# in order to know which SOPE release/version must be
# present prior the OGo release build:
# <opengroupware.spec_snippet>
#   #UseSOPEsrc:   sope-4.3.9-shapeshifter-r301.tar.gz
#   #UseSOPEspec:  sope-4.3.9-shapeshifter.spec
# </opengroupware.spec_snippet>
# 
# UseSOPEsrc -> ordinary tarballname...
# UseSOPEspec -> sope-<version>-<codename>.spec
# (sope.spec from the tarball and UseSOPEspec are
# technically the same... only different names.)
#
# Normal workflow is... the SOPE version we need was
# already built (SOPE release cron runs before OGo release).
# Bc of this - \$ENV{HOME}/spec_tmp already contains the
# file we name in 'UseSOPEspec'... (it gets there by trigger_sope_release.pl)
# But since we clean up and rebuild SOPE trunk - only if trigger_sope_release.pl
# really had sth to do - we must feed 'purveyor_of_rpms.pl' with the values
# for a release build using 'UseSOPEsrc' and 'UseSOPEspec' before we actually
# go on and build OGo... building OGo itself is simply another call for 'purveyor_of_rpms.pl'.
# Said that - we call 'purveyor_of_rpms.pl' twice -:
# ./purveyor_of_rpms.pl -p sope -t release -v yes -u no -d no -f yes -b no -c <UseSOPEsrc> -c spec_tmp/<UseSOPEspec>
# ./purveyor_of_rpms.pl -p opengroupware -t release -v yes -u yes -d yes -c <see below> -c spec_tmp/<see below>

use strict;
die "WARNING: not yet configured!\n";
my $host_i_runon = "fedora-core3";
#my $host_i_runon = "fedora-core2";
#my $host_i_runon = "suse92";
#my $host_i_runon = "suse91";
#my $host_i_runon = "suse82";
#my $host_i_runon = "mdk-10.1";
#my $host_i_runon = "mdk-10.0";
#my $host_i_runon = "sles9";
#my $host_i_runon = "slss8";
#my $host_i_runon = "rhel3";
#my $host_i_runon = "redhat9";
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
my $hpath = "$ENV{HOME}/";
my @skip_list = qw( opengroupware.org-0.9pre-r4.tar.gz
opengroupware.org-1.0alpha1-shapeshifter-r34.tar.gz
opengroupware.org-1.0alpha2-shapeshifter-r49.tar.gz
opengroupware.org-1.0alpha3-shapeshifter-r59.tar.gz
opengroupware.org-1.0alpha4-shapeshifter-r84.tar.gz
opengroupware.org-1.0alpha5-shapeshifter-r86.tar.gz
opengroupware.org-1.0alpha6-shapeshifter-r89.tar.gz
opengroupware.org-1.0alpha7-shapeshifter-r158.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @ogo_releases;
my @ogo_spec;
my $line;
my $sope_spec;
my $sope_src;

@ogo_releases = `wget -q --proxy=off -O - http://$dl_host/sources/releases/MD5_INDEX`;
open(KNOWN_OGo_RELEASES, ">> $hpath/OGo.known.rel");
foreach $orel (@ogo_releases) {
  chomp $orel;
  $orel =~ s/^.*\s+//g;
  next unless($orel =~ m/^opengroupware.org/i);
  my @already_known_ogo_rel = `cat $hpath/OGo.known.rel`;
  next if (grep /$orel/, @skip_list);
  $buildtarget = $orel;
  $buildtarget =~ s/-r\d+.*$//g;
  unless(grep /\b$orel\b/, @already_known_ogo_rel) {
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/sources/releases/$orel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$orel http://$dl_host/sources/releases/$orel");
    #since we build the OGo release using a specific SOPE release... we must
    #cleanup everything prior the actual wanted OGo *and* SOPE builds
    #I don't use apt-get here bc not every RPM based distri provides a package (apt-get).
    print "cleaning up previous SOPE build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
    print "cleaning up previous OGo build...\n";
    system("sudo rpm -e `rpm -qa|grep -i ^ogo-|grep -vi gnustep` --nodeps");
    print "extracting specfile from $orel into $ENV{HOME}/spec_tmp/\n";
    system("mkdir $ENV{HOME}/spec_tmp/") unless (-e "$ENV{HOME}/spec_tmp/");
    #extract the specfile coming with the release tarball into a temporary location and keep it there
    #in order to build using exactly this specfile...
    system("tar xfzO $ENV{HOME}/rpm/SOURCES/$orel opengroupware.org/maintenance/opengroupware.spec >$ENV{HOME}/spec_tmp/$buildtarget.spec");
    open(SOPEHINTS, "$ENV{HOME}/spec_tmp/$buildtarget.spec");
    @ogo_spec = <SOPEHINTS>;
    close(SOPEHINTS);
    foreach $line(@ogo_spec) {
      chomp $line;
      $sope_src = $line if ($line =~ s/^#UseSOPEsrc:\s+//g);
      $sope_spec = $line if ($line =~ s/^#UseSOPEspec:\s+//g);
    }
    #we should've already build this SOPE release at least once in an earlier run
    print "preparing SOPE...\n";
    print "calling `purveyor_of_rpms.pl -p sope -v yes -t release -u no -d no -f yes -b no -c $sope_src -s $ENV{HOME}/spec_tmp/$sope_spec`\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -t release -u no -d no -f yes -b no -c $sope_src -s $ENV{HOME}/spec_tmp/$sope_spec");
    print "OGo_REL: building RPMS for OGo $orel using $sope_src with $sope_spec\n";
    print "calling `purveyor_of_rpms.pl -p opengroupware $build_opts -c $orel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p opengroupware $build_opts -c $orel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    print KNOWN_OGo_RELEASES "$orel\n";
    print "recreating apt-repository for: $host_i_runon >>> $buildtarget\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    #these differ...
    #TODO: we're not done yet... rpmbuild ogo-environment (and some other packages) and upload
    #      them into the same(?) directory
    #      requires new switch in purveyor_of_rpms.pl in order to upload packages into a given
    #      directory (which should be \$apttarget)
    $apttarget = $buildtarget;
    $apttarget =~ s/^opengroupware\.org/opengroupware/g;
    print "thus calling: /home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n $apttarget\n";
    print SSH "/home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n $apttarget\n";
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
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -u no -d no -f yes -b no");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p opengroupware -v yes -u no -d no -f yes -b no");
}
