#!/usr/bin/perl -w
#
# Beerware license applies ...
# written by frank@opengroupware.org
# for OpenGroupware.org
#

use strict;
use Getopt::Std;
our ($opt_d,$opt_t,$opt_v);
my $item;
my @sope_rpms;
my @ogo_rpms;
my @tp_rpms;
my $distri;
my $repo;
my @repos = qw( OGo SOPE ThirdParty );
my $type = "trunk";
my $verbose = "no";
my @distris = qw( fedora-core3
  fedora-core2
  suse82
  suse91
  suse92
  sles9
  mdk-10.1
  mdk-10.0
  slss8
  rhel3
  redhat9
  conectiva10
);

getopt('dtv');
if (!$opt_d) {
  print "No distribution specified!\n";
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

if (!$opt_t or ($opt_t !~ m/^release$/i)) {
  $type = "trunk";
  print "doing apt4rpm for -> $distri / $type\n"
} else {
  $type = "release";
  print "Ah no ... this is for trunk only!\n";
  exit 0;
}

if (!$opt_v or ($opt_v !~ m/^yes$/i)) {
  $verbose = "no";
} else {
  $verbose = "yes";
}


my @apt_items = `/bin/ls -laA /var/virtual_hosts/download/packages/$distri/$type/*latest*.rpm | awk '{print \$11}'` or die "DIEDIEDIE: $!\n" if ("$type" eq "trunk");

#redirect apt_items into either sope,ogo or tp rpms for the different repos
foreach $item (@apt_items) {
  chomp $item;
  push @tp_rpms, $item if ($item =~ m/^libfoundation.*$|^libobjc.*$|^ogo-gnustep.*$|^epoz.*$/i);
  push @ogo_rpms, $item if (($item =~ m/^ogo-.*$/i) and ($item !~ m/^ogo-gnustep_make.*/i));
  push @sope_rpms, $item if ($item =~ m/^sope.*$|^libical-sope.*$|^mod_ngobjweb.*$/i);
}

if ("$verbose" eq "yes") {
  print "TP RPMS:\n";
  print "@tp_rpms\n";
  print "---------------------------\n";
  print "OGo RPMS:\n";
  print "@ogo_rpms\n";
  print "---------------------------\n";
  print "SOPE RPMS:\n";
  print "@sope_rpms\n";
  print "---------------------------\n";
}


`mkdir -p "/var/virtual_hosts/download/packages/apt4rpm/$distri/$type/base"`;

for $repo (@repos) {
  chomp $repo;
  `mkdir -p "/var/virtual_hosts/download/packages/apt4rpm/$distri/$type/RPMS.$repo"`;
  `rm -f -v /var/virtual_hosts/download/packages/apt4rpm/$distri/$type/RPMS.$repo/*`;
  open(RELEASE, "> /var/virtual_hosts/download/packages/apt4rpm/$distri/$type/base/release.$repo");
  print RELEASE "Archive: $repo\n";
  print RELEASE "Component: $repo\n";
  print RELEASE "Version: $type\n";
  print RELEASE "Origin: http://download.opengroupware.org\n";
  print RELEASE "Label: $distri\n";
  print RELEASE "Architecture: i386\n" if (("$distri" eq "suse82") or ("$distri" eq "fedora-core2") or ("$distri" eq "fedora-core3") or ("$distri" eq "rhel3") or ("$distri" eq "redhat9") or ("$distri" eq "conectiva10"));
  print RELEASE "Architecture: i586\n" if (("$distri" eq "suse91") or ("$distri" eq "suse92") or ("$distri" eq "sles9") or ("$distri" eq "mdk-10.0") or ("$distri" eq "mdk-10.1"));
  print RELEASE "NotAutomatic: false\n";
  close(RELEASE);
}

foreach $item (@tp_rpms) {
  chomp $item;
  `/bin/ln -s "/var/virtual_hosts/download/packages/$distri/$type/$item" /var/virtual_hosts/download/packages/apt4rpm/$distri/$type/RPMS.ThirdParty/$item`;
}

foreach $item (@ogo_rpms) {
  chomp $item;
  `/bin/ln -s "/var/virtual_hosts/download/packages/$distri/$type/$item" /var/virtual_hosts/download/packages/apt4rpm/$distri/$type/RPMS.OGo/$item`;
}

foreach $item (@sope_rpms) {
  chomp $item;
  `/bin/ln -s "/var/virtual_hosts/download/packages/$distri/$type/$item" /var/virtual_hosts/download/packages/apt4rpm/$distri/$type/RPMS.SOPE/$item`;
}


`/usr/bin/genbasedir-0.5 --bz2only /var/virtual_hosts/download/packages/apt4rpm/$distri/$type OGo SOPE ThirdParty`;

exit 0;
