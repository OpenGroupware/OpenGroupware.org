#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

use strict;
#die "WARNING: not yet configured!\n";
my $host_i_runon = "sarge";
#my $host_i_runon = "sid";
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
my $perform_things_outside_buildhost = "yes";
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
    my $dep;
    my @prereq;
    $i_really_had_sth_todo = "yes";
    print "preparing...\n";
    print "cleaning up/purging libfoundation/libobjc-lf2 prior actual build...\n";
    system("sudo dpkg --purge --force-all `dpkg -l | awk '{print \$2}' | grep -iE '(libfoundation|libobjc-lf2)'`");
    open(SOPE_DEPS, "$ENV{HOME}/sarge_sope_release.hints") || die "Arrr: $!\n";
    @prereq = <SOPE_DEPS>;
    close(SOPE_DEPS);
    print "installing prequired packages to satisfy automatic dependency generator...\n";
    foreach $dep(@prereq) {
      chomp $dep;
      #keep order in file...
      system("$ENV{HOME}/purveyor_of_debs.pl -p libobjc-lf2 -t release -v yes -u no -d yes -c $dep") if($dep =~ m/gnustep-objc-lf2/i);
      system("$ENV{HOME}/purveyor_of_debs.pl -p libfoundation -t release -v yes -u no -d yes -c $dep") if($dep =~ m/libfoundation/i);
    }
    print "Retrieving: http://$dl_host/nightly/sources/releases/$srel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/sources/$srel http://$dl_host/nightly/sources/releases/$srel");
    print "cleaning up prior actual build...\n";
    system("sudo dpkg --purge --force-all `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
    print "SOPE_REL: building debs for SOPE $srel\n";
    print "calling `purveyor_of_debs.pl -p sope $build_opts -c $srel\n";
    system("$ENV{HOME}/purveyor_of_debs.pl -p sope $build_opts -c $srel");
    print KNOWN_SOPE_RELEASES "$srel\n";
    print "recreating apt-repository for: $host_i_runon - $buildtarget\n";
    if($perform_things_outside_buildhost eq "yes") {
      open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
      print SSH "/home/www/scripts/release_in_nightly_debian_apt.sh $host_i_runon $buildtarget\n";
      close(SSH);
    }
  }
}
close(KNOWN_SOPE_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo dpkg --purge --force-all `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_debs.pl -p libobjc-lf2 -v yes -u no -d yes -f yes -b no");
  system("$ENV{HOME}/purveyor_of_debs.pl -p libfoundation -v yes -u no -d yes -f yes -b no");
  system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -u no -d yes -f yes -b no");
} else {
  print "Seems as if there's nothing to do.\n";
  print "SOPE.known.rel told me, that we've alread build every single release\n";
  print "If you think that I'm wrong - you can either delete SOPE.known.rel completely\n";
  print "or only parts of it and I'll happily rebuild each release I don't know.\n";
}
