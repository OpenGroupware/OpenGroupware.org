#!/usr/bin/perl -w
# 2004-12-30 <frank@opengroupware.org>
# removes outdated trunk/ sources

use strict;

my $keep_revisions = "5";

my $current_group;
my @groups = qw( gnustep-make
  libfoundation
  libical-sope
  libobjc-lf2
  opengroupware.org-nhsc
  opengroupware.org-pilot-link
  opengroupware.org
  sope-epoz
  sope-mod_ngobjweb
  sope
);

print "Not enough revisions to keep...\nYou asked me to keep $keep_revisions \$keep_revisions and I think this will most likely trash the dl area.\n" and exit 1 if($keep_revisions <= 0);
#write output into file which can then be executed on the commandline after rewview... for now (bc of testing.)
open(OUT, ">rm_candidates_sources.out");
foreach $current_group(@groups) {
  print "current group to check is: $current_group\n";
  opendir(DIR, "/var/virtual_hosts/download/sources/trunk");
  my @u_this_group_tarballs = grep(/^$current_group-trunk.*\.tar.gz$/,readdir(DIR));
  my $no_of_tarballs_in_group = @u_this_group_tarballs;
  next if($no_of_tarballs_in_group == 0);
  print "current group ($current_group) has -> $no_of_tarballs_in_group files.\n";
  my $most_recent = 0;
  my $sourcefile;
  my @versions;
  my $no_of_versions;
  my @this_group_tarballs = sort {uc($a) cmp uc($b)} @u_this_group_tarballs;
  foreach $sourcefile(@this_group_tarballs) {
    next if (($sourcefile =~ m/latest/i) or ($no_of_tarballs_in_group == 0));
    my ($exact_v,$exact_v_svn,$exact_v_date);
    $exact_v = $sourcefile;
    $exact_v =~ s/^$current_group.*trunk-r(.*)-(.*)\.tar.gz$//g;
    $exact_v_svn = $1;
    $exact_v_date = $2;
    $exact_v = "$exact_v_svn" . "." . "$exact_v_date";
    print "DEBUG >>> $exact_v\n";
    push(@versions, $exact_v) unless(grep /$exact_v/, @versions);
    #detect most recent one... useful? hm, no...
    $most_recent = $exact_v if($exact_v > $most_recent);
  }
  $no_of_versions = @versions;
  if ($no_of_tarballs_in_group > $keep_revisions) {
    my $i;
    my $delcount;
    $delcount = $no_of_versions - $keep_revisions;
    for($i=0; $i < $delcount; $i++) {
      my $dc;
      $dc = shift(@versions);
      $dc =~ s/\./-/g;
      #print "     could delete files from group $current_group*trunk_r$dc*\n";
      print OUT "rm -f /var/virtual_hosts/download/sources/trunk/$current_group-trunk-r$dc*.tar.gz\n";
    }
    print "\$keep_revisions = $keep_revisions is larger/equal $no_of_versions....\n";
    print "@versions\n";
    print "DEBUG >> most_recent thereof -> $most_recent\n";
  }
}
#exit 0;
print OUT "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/sources/trunk/\n";
print OUT "/home/www/scripts/do_LATESTVERSION.pl /var/virtual_hosts/download/sources/trunk/\n";
print OUT "#================================================================================================\n";
close(OUT);
