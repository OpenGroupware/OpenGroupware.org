#!/usr/bin/perl -w
# 2004-12-30 <frank@opengroupware.org>
# removes outdated trunk/ packages
# but keeps at least $keep_revisions package sets foreach @group available

use strict;

my $keep_revisions = "4";
my $current_distri;
my @distris = qw(fedora-core2
  fedora-core3
  mdk-10.0
  mdk-10.1
  redhat9
  rhel3
  sles9
  slss8
  suse82
  suse91
  suse92
);

my $current_group;
my @groups = qw( epoz
  libfoundation
  libobjc-lf2
  ogo-docapi
  ogo-environment
  ogo-gnustep_make
  ogo-logic
  ogo-pda
  ogo-theme
  ogo-tools
  ogo-webui
  ogo-xmlrpcd
  ogo-zidestore
  sope43
  sope44
  sope45
);

print "Not enough revisions to keep...\nYou asked me to keep $keep_revisions \$keep_revisions but I think this will most likely trash the repo.\n" and exit 1 if($keep_revisions <= 0);
#write output into file which can then be executed on the commandline after review... for now (bc of testing.)
open(OUT, ">rm_candidates.out");
foreach $current_distri(@distris) {
  print "checking in $current_distri\n";
  foreach $current_group(@groups) {
    print "current group to check is: $current_group\n";
    opendir(DIR, "/var/virtual_hosts/download/packages/$current_distri/trunk");
    my @u_this_group_rpms = grep(/^$current_group.*trunk.*\.rpm$/,readdir(DIR));
    my $no_of_rpms_in_group = @u_this_group_rpms;
    next if($no_of_rpms_in_group == 0);
    print "current group ($current_group) has -> $no_of_rpms_in_group files.\n";
    my $rpm;
    my $most_recent = 0;
    my @versions;
    my $no_of_versions;
    my @this_group_rpms = sort {uc($a) cmp uc($b)} @u_this_group_rpms;
    foreach $rpm(@this_group_rpms) {
      next if (($rpm =~ m/latest/i) or ($no_of_rpms_in_group == 0));
      my $exact_v;
      $exact_v = $rpm;
      $exact_v =~ s/mdk//g;
      $exact_v =~ s/^$current_group.*trunk_r(.*)\.i.*$//g;
      $exact_v = $1;
      push(@versions, $exact_v) unless(grep /$exact_v/, @versions);
      #detect most recent one... useful? hm, no...
      $most_recent = $exact_v if($exact_v > $most_recent);
    }
    $no_of_versions = @versions;
    if ($no_of_rpms_in_group > $keep_revisions) {
      my $i;
      my $delcount;
      $delcount = $no_of_versions - $keep_revisions;
      for($i=0; $i < $delcount; $i++) {
        my $dc;
        $dc = shift(@versions);
        #print "     could delete files from group $current_group*trunk_r$dc*\n";
        print OUT "rm -f /var/virtual_hosts/download/packages/$current_distri/trunk/$current_group*trunk_r$dc*.rpm\n";
      }
      print "\$keep_revisions = $keep_revisions is larger/equal $no_of_versions....\n";
      print "@versions\n";
      print "DEBUG >> most_recent thereof -> $most_recent\n";
    }
  }
  #exit 0;
  print OUT "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/packages/$current_distri/trunk/\n";
  print OUT "/home/www/scripts/do_LATESTVERSION.pl /var/virtual_hosts/download/packages/$current_distri/trunk/\n";
  print OUT "/home/www/scripts/trunk_apt4rpm_build.pl -d $current_distri\n";
  print OUT "#================================================================================================\n";
}
close(OUT);