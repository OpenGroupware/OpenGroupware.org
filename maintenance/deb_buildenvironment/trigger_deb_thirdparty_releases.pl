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
my $tprel;
my $buildtarget;
my $hpath = "$ENV{HOME}/";
my @tp_packages = qw( sope-epoz libobjc-lf2 libfoundation libical-sope );
my @skip_list = qw( libical-sope1-r30.tar.gz
  libFoundation-1.0.59-r29.tar.gz
  libFoundation-1.0.64-r61.tar.gz
  libFoundation-1.0.65-r63.tar.gz
  gnustep-objc-lf2.95.3-r85.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @tp_releases;

@tp_releases = `wget --proxy=off -q -O - http://$dl_host/sources/releases/MD5_INDEX`;
open(KNOWN_TP_RELEASES, ">> $hpath/ThirdParty.known.rel");
foreach $tprel (@tp_releases) {
  chomp $tprel;
  $tprel =~ s/^.*\s+//g;
  next unless($tprel =~ m/epoz|gnustep-objc|libFoundation|libical-sope/i);
  my @already_known_tp_rel = `cat $hpath/ThirdParty.known.rel`;
  next if (grep /$tprel/, @skip_list);
  $buildtarget = $tprel;
  $buildtarget =~ s/-r\d+.*$//g;
  unless(grep /\b$tprel\b/, @already_known_tp_rel) {
    my $package_to_build; # <-p> switch for 'purveyor_of_debs.pl'
    my $cleanup;
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/sources/releases/$tprel\n";
    system("wget --proxy=off -q -O $ENV{HOME}/sources/$tprel http://$dl_host/sources/releases/$tprel");
    ###
    $package_to_build = "sope-epoz" if ($tprel =~ m/epoz/i);
    $cleanup = "sope-epoz" if ($tprel =~ m/epoz/i);
    ###
    $package_to_build = "libobjc-lf2" if ($tprel =~ m/gnustep-objc/i);
    $cleanup = "libobjc-lf2" if ($tprel =~ m/gnustep-objc/i);
    ###
    $package_to_build = "libfoundation" if ($tprel =~ m/libfoundation/i);
    $cleanup = "libfoundation" if ($tprel =~ m/libfoundation/i);
    ###
    $package_to_build = "libical-sope" if ($tprel =~ m/libical-sope/i);
    $cleanup = "libical-sope" if ($tprel =~ m/libical-sope/i);
    ###
    print "cleaning up/purging $cleanup prior actual build...\n";
    system("sudo dpkg --purge --force-all `dpkg -l | awk '{print \$2}' | grep -iE '(^$cleanup)'`");
    print "ThirdParty_REL: building debs for ThirdParty $tprel\n";
    print "calling `purveyor_of_debs.pl -p $package_to_build $build_opts -c $tprel\n";
    system("$ENV{HOME}/purveyor_of_debs.pl -p $package_to_build $build_opts -c $tprel");
    print KNOWN_TP_RELEASES "$tprel\n";
    print "recreating apt-repository for: $host_i_runon - ThirdParty\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    print SSH "/home/www/scripts/release_debian_apt.sh $host_i_runon ThirdParty\n";
    close(SSH);
  }
}
close(KNOWN_TP_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo dpkg --purge --force-all `dpkg -l | awk '{print \$2}' | grep -iE '(^sope-epoz|^libobjc-lf2|^libfoundation)'`");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_debs.pl -p libobjc-lf2 -v yes -u no -d yes -f yes -b no");
  system("$ENV{HOME}/purveyor_of_debs.pl -p libfoundation -v yes -u no -d yes -f yes -b no");
} else {
  print "Seems as if there's nothing to do.\n";
  print "ThirdParty.known.rel told me, that we've alread build every single release\n";
  print "If you think that I'm wrong - you can either delete ThirdParty.known.rel completely\n";
  print "or only parts of it and I'll happily rebuild each release I don't know.\n";
}
