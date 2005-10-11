#!/usr/bin/perl -w
#
# Beerware license applies ...
# written by frank@opengroupware.org
# for OpenGroupware.org
#

use strict;
use Getopt::Std;
use File::Basename;
our ($opt_d,$opt_t,$opt_v,$opt_n,$opt_s);
my $item;
my $distri;
my @rel_rpms;
my $rel_name;
my $stage_for;
my $type = "releases";
my $verbose = "no";
my @distris = qw( fedora-core4
  fedora-core3
  fedora-core2
  suse82
  suse91
  suse92
  suse93
  mdk-10.1
  mdk-10.0
  slss8
  sles9
  rhel3
  rhel4
  redhat9
  conectiva10
);

getopt('dtvns');
if (!$opt_d) {
  print "No distribution specified!\n";
  print "-d <distribution>\n";
  exit 0;
} else {
  unless (grep /^$opt_d$/, @distris) {
    print "\n";
    print "I don't know if I can deal with distri: $opt_d\n";
    print "Chances are, that not everything is in place prior creating\n";
    print "the apt4rpm repository. Please check this first and add $opt_d\n";
    print "into \@distris if everything is prepared.\n";
    print "\n";
    exit 0;
  }
  $distri = $opt_d;
  chomp $distri;
  print "\n";
  print "The distri: $distri should be known to me.\n";
  print "continuing...\n";
}

if (!$opt_s) {
  print "choose either 'stable' or 'unstable'!\n";
  print "-s <stable|unstable>\n";
  exit 0;
} else {
  $stage_for = $opt_s;
  chomp $stage_for;
  if(($stage_for eq "stable") or ($stage_for eq "unstable")) {
    print "ok - $stage_for\n";
  } else {
    print "either 'stable' or 'unstable' allowed - not $stage_for...\n";
    exit 0;
  }
}

if (!$opt_v or ($opt_v !~ m/^yes$/i)) {
  $verbose = "no";
} else {
  $verbose = "yes";
}

if (!$opt_n) {
  print "\n";
  print "Nothing given to <-n>\n";
  print "<-n> eats the basename of the release/~ dir... ie:\n";
  print "/var/virtual_hosts/download/releases/$stage_for/sope-4.3.8-shapeshifter\n";
  print "would require: <-n sope-4.3.8-shapeshifter>\n";
  exit 0;
} else {
  $rel_name = $opt_n;
  chomp $rel_name;
  print "checking for existence of: /var/virtual_hosts/download/$type/$stage_for/$rel_name/$distri\n";
  unless(-e "/var/virtual_hosts/download/$type/$stage_for/$rel_name/$distri") {
    print "This release doesn't exist!\n";
    print "you might want to choose one out of:\n";
    system("ls -1 /var/virtual_hosts/download/$type/$stage_for/");
    exit 0;
  }
}

if (!$opt_t or ($opt_t !~ m/^trunk$/i)) {
  $type = "releases";
  print "doing apt4rpm for -> $distri / $type / $stage_for / $rel_name\n"
} else {
  $type = "trunk";
  print "Ah no ... this is for release only!\n";
  exit 0;
}

my @tmp_apt_items = `/bin/ls -laA /var/virtual_hosts/download/$type/$stage_for/$rel_name/$distri/*.rpm | awk '{print \$9}'` or die "DIEDIEDIE: $!\n" if ("$type" eq "releases");

foreach $item (@tmp_apt_items) {
  chomp $item;
  my $tmp_name;
  $tmp_name = basename($item);
  push @rel_rpms, $tmp_name;
}

if ("$verbose" eq "yes") {
  print "RELEASE RPMS in $rel_name\n";
  print "@rel_rpms\n";
  print "---------------------------\n";
}

`mkdir -p "/var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/RPMS.$rel_name"`;
`rm -vf /var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/RPMS\.$rel_name/*`;

foreach $item(@rel_rpms) {
  chomp $item;
  #print "do: /bin/ln -s \"/var/virtual_hosts/download/$type/$stage_for/$rel_name/$distri/$item\" \"/var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/RPMS.$rel_name/$item\"\n";
  `/bin/ln -s /var/virtual_hosts/download/$type/$stage_for/$rel_name/$distri/$item /var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/RPMS.$rel_name/$item`;
}

`mkdir -p "/var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/base"`;

open(RELEASE, "> /var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/base/release.$rel_name");
print RELEASE "Archive: $rel_name\n";
print RELEASE "Component: $rel_name\n";
print RELEASE "Version: $type\n";
print RELEASE "Origin: http://download.opengroupware.org\n";
print RELEASE "Label: $distri\n";
print RELEASE "Architecture: i386\n" if (("$distri" eq "suse82") or ("$distri" eq "fedora-core2") or ("$distri" eq "fedora-core3") or ("$distri" eq "rhel3") or ("$distri" eq "fedora-core4") or ("$distri" eq "rhel4") or ("$distri" eq "redhat9") or ("$distri" eq "conectiva10"));
print RELEASE "Architecture: i586\n" if (("$distri" eq "suse91") or ("$distri" eq "suse92") or ("$distri" eq "suse93") or("$distri" eq "sles9") or ("$distri" eq "mdk-10.0") or ("$distri" eq "mdk-10.1"));
print RELEASE "NotAutomatic: false\n";
close(RELEASE);

my @tmp_dirs = `find /var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri/ -type d -name '*RPMS*'`;
my @rel_repos;
foreach $item (@tmp_dirs) {
  chomp $item;
  my $tmp_dir;
  $tmp_dir = basename($item);
  $tmp_dir =~ s/^RPMS\.//g;
  push @rel_repos, $tmp_dir;
}

`/usr/bin/genbasedir-0.5 --bz2only /var/virtual_hosts/download/$type/$stage_for/apt4rpm/$distri @rel_repos`;

