#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

use strict;
#die "WARNING: not yet configured!\n";
my $host_i_runon = "sarge";
#my $host_i_runon = "fedora-core3";
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
$ENV{'COLUMNS'} = "150";
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

@sope_releases = `wget -q -O - http://$dl_host/sources/releases/MD5_INDEX`;
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
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/sources/releases/$srel\n";
    system("wget -q -O $ENV{HOME}/sources/$srel http://$dl_host/sources/releases/$srel");
    print "cleaning up prior actual build...\n";
    system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
    print "SOPE_REL: building debs for SOPE $srel\n";
    print "calling `purveyor_of_debs.pl -p sope $build_opts -c $srel\n";
    system("$ENV{HOME}/purveyor_of_debs.pl -p sope $build_opts -c $srel");
    print KNOWN_SOPE_RELEASES "$srel\n";
    print "recreating apt-repository for: $host_i_runon - $buildtarget\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    print SSH "/home/www/scripts/release_debian_apt.sh $host_i_runon $buildtarget\n";
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
  system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -u no -d no -f yes -b no");
}
