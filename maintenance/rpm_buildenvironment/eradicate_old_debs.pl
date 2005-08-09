#!/usr/bin/perl -w
# 2005-04-04 <frank@opengroupware.org>
# removes outdated trunk/ packages

use strict;

my $keep_revisions = "10";
my $current_distri;
my $must_rebuild_sth = "no";
my @distris = qw( sarge sid );

my $current_group;
my @groups = qw( libapache-mod-ngobjweb
  libapache2-mod-ngobjweb
  libfoundation-data
  libfoundation-tools
  libfoundation1.0-dev
  libfoundation1.0
  libical-sope-dev
  libobjc-lf2-dev
  libobjc-lf2
  libopengroupware.org-db-project5.1-dev
  libopengroupware.org-db-project5.2-dev
  libopengroupware.org-db-project5.3-dev
  libopengroupware.org-db-project5.1
  libopengroupware.org-db-project5.2
  libopengroupware.org-db-project5.3
  libopengroupware.org-docapi5.1-dev
  libopengroupware.org-docapi5.2-dev
  libopengroupware.org-docapi5.3-dev
  libopengroupware.org-docapi5.1
  libopengroupware.org-docapi5.2
  libopengroupware.org-docapi5.3
  libopengroupware.org-fs-project5.1-dev
  libopengroupware.org-fs-project5.2-dev
  libopengroupware.org-fs-project5.3-dev
  libopengroupware.org-fs-project5.1
  libopengroupware.org-fs-project5.2
  libopengroupware.org-fs-project5.3
  libopengroupware.org-logic5.1-dev
  libopengroupware.org-logic5.2-dev
  libopengroupware.org-logic5.3-dev
  libopengroupware.org-logic5.1
  libopengroupware.org-logic5.2
  libopengroupware.org-logic5.3
  libopengroupware.org-pda5.1-dev
  libopengroupware.org-pda5.2-dev
  libopengroupware.org-pda5.3-dev
  libopengroupware.org-pda5.1
  libopengroupware.org-pda5.2
  libopengroupware.org-pda5.3
  libopengroupware.org-webmail5.1-dev
  libopengroupware.org-webmail5.2-dev
  libopengroupware.org-webmail5.3-dev
  libopengroupware.org-webmail5.1
  libopengroupware.org-webmail5.2
  libopengroupware.org-webmail5.3
  libopengroupware.org-webui-foundation5.1-dev
  libopengroupware.org-webui-foundation5.2-dev
  libopengroupware.org-webui-foundation5.3-dev
  libopengroupware.org-webui-foundation5.1
  libopengroupware.org-webui-foundation5.2
  libopengroupware.org-webui-foundation5.3
  libopengroupware.org-zidestore1.3-dev
  libopengroupware.org-zidestore1.4-dev
  libopengroupware.org-zidestore1.5-dev
  libopengroupware.org-zidestore1.3
  libopengroupware.org-zidestore1.4
  libopengroupware.org-zidestore1.5
  libsope-appserver4.5-dev
  libsope-appserver4.5
  libsope-core4.5-dev
  libsope-core4.5
  libsope-gdl1-4.5-dev
  libsope-gdl1-4.5
  libsope-ical4.5-dev
  libsope-ical4.5
  libsope-ldap4.5-dev
  libsope-ldap4.5
  libsope-mime4.5-dev
  libsope-mime4.5
  libsope-xml4.5-dev
  libsope-xml4.5
  libsope4.5-dev
  opengroupware.org-database-scripts
  opengroupware.org-environment
  opengroupware.org
  opengroupware.org-misc-tools
  opengroupware.org-skyaptnotify
  opengroupware.org-webmail-tools
  opengroupware.org-zidestore1.3
  opengroupware.org1.0a-database
  opengroupware.org1.0a-epoz
  opengroupware.org1.0a
  opengroupware.org1.0a-nhsd
  opengroupware.org1.0a-webui-app
  opengroupware.org1.0a-webui-contact
  opengroupware.org1.0a-webui-core
  opengroupware.org1.0a-webui-i18n-de
  opengroupware.org1.0a-webui-i18n-dk
  opengroupware.org1.0a-webui-i18n-en
  opengroupware.org1.0a-webui-i18n-es
  opengroupware.org1.0a-webui-i18n-eu
  opengroupware.org1.0a-webui-i18n-fr
  opengroupware.org1.0a-webui-i18n-hu
  opengroupware.org1.0a-webui-i18n-it
  opengroupware.org1.0a-webui-i18n-jp
  opengroupware.org1.0a-webui-i18n-nl
  opengroupware.org1.0a-webui-i18n-no
  opengroupware.org1.0a-webui-i18n-pl
  opengroupware.org1.0a-webui-i18n-pt
  opengroupware.org1.0a-webui-i18n-ptbr
  opengroupware.org1.0a-webui-i18n-se
  opengroupware.org1.0a-webui-i18n-sv
  opengroupware.org1.0a-webui-job
  opengroupware.org1.0a-webui
  opengroupware.org1.0a-webui-mailer
  opengroupware.org1.0a-webui-news
  opengroupware.org1.0a-webui-project
  opengroupware.org1.0a-webui-scheduler
  opengroupware.org1.0a-webui-theme-blue
  opengroupware.org1.0a-webui-theme-default
  opengroupware.org1.0a-webui-theme-kde
  opengroupware.org1.0a-webui-theme-ooo
  opengroupware.org1.0a-webui-theme-orange
  opengroupware.org1.0a-xmlrpcd
  opengroupware.org1.1-database
  opengroupware.org1.1-epoz
  opengroupware.org1.1
  opengroupware.org1.1-nhsd
  opengroupware.org1.1-webui-app
  opengroupware.org1.1-webui-contact
  opengroupware.org1.1-webui-core
  opengroupware.org1.1-webui-i18n-de
  opengroupware.org1.1-webui-i18n-dk
  opengroupware.org1.1-webui-i18n-en
  opengroupware.org1.1-webui-i18n-es
  opengroupware.org1.1-webui-i18n-eu
  opengroupware.org1.1-webui-i18n-fr
  opengroupware.org1.1-webui-i18n-hu
  opengroupware.org1.1-webui-i18n-it
  opengroupware.org1.1-webui-i18n-jp
  opengroupware.org1.1-webui-i18n-nl
  opengroupware.org1.1-webui-i18n-no
  opengroupware.org1.1-webui-i18n-pl
  opengroupware.org1.1-webui-i18n-pt
  opengroupware.org1.1-webui-i18n-ptbr
  opengroupware.org1.1-webui-i18n-se
  opengroupware.org1.1-webui-i18n-sv
  opengroupware.org1.1-webui-job
  opengroupware.org1.1-webui
  opengroupware.org1.1-webui-mailer
  opengroupware.org1.1-webui-news
  opengroupware.org1.1-webui-project
  opengroupware.org1.1-webui-scheduler
  opengroupware.org1.1-webui-theme-blue
  opengroupware.org1.1-webui-theme-default
  opengroupware.org1.1-webui-theme-kde
  opengroupware.org1.1-webui-theme-ooo
  opengroupware.org1.1-webui-theme-orange
  opengroupware.org1.1-xmlrpcd
  sope-tools
  sope4.5-appserver
  sope4.5-gdl1-postgresql
  sope4.5-libxmlsaxdriver
  sope4.5-stxsaxdriver
  sope4.5-versitsaxdriver
);

print "Not enough revisions to keep...\nYou asked me to keep $keep_revisions \$keep_revisions and I think this will most likely trash the repo.\n" and exit 1 if($keep_revisions <= 1);
#write output into file which can then be executed on the commandline after rewview... for now (bc of testing.)
open(OUT, ">rm_candidates_deb.out");
foreach $current_distri(@distris) {
  print "checking in $current_distri\n";
  foreach $current_group(@groups) {
    print "current group to check is: $current_group\n";
    #/var/virtual_hosts/download/nightly/packages/debian/dists/sarge/trunk/binary-i386
    opendir(DIR, "/var/virtual_hosts/download/nightly/packages/debian/dists/$current_distri/trunk/binary-i386");
    my @u_this_group_debs = grep(/^$current_group.*svn.*\.deb$/,readdir(DIR));
    my $no_of_debs_in_group = @u_this_group_debs;
    next if($no_of_debs_in_group == 0) and print "Skipping group $current_group bc $no_of_debs_in_group packages found\n########################################### next one .... \n";
    print "current group ($current_group) has -> $no_of_debs_in_group files.\n";
    my $deb;
    my $most_recent = 0;
    my @versions;
    my $no_of_versions;
    my @this_group_debs = sort {uc($a) cmp uc($b)} @u_this_group_debs;
    foreach $deb(@this_group_debs) {
      next if (($deb =~ m/latest/i) or ($no_of_debs_in_group == 0));
      my $exact_v;
      $exact_v = $deb;
      chomp $exact_v;
      $exact_v =~ s/^$current_group.*svn(.*)_(i386|all)\.deb$//g;
      $exact_v = $1;
      $exact_v =~ s/-/\./g;
      push(@versions, $exact_v) unless(grep /$exact_v/, @versions);
      #detect most recent one... useful? hm, no...
      $most_recent = $exact_v if($exact_v > $most_recent);
    }
    my @sorted_versions = sort { $a <=> $b } @versions;
    $no_of_versions = @sorted_versions;
    if ($no_of_debs_in_group > $keep_revisions) {
      my $i;
      my $delcount;
      my @for_removal;
      $delcount = $no_of_versions - $keep_revisions;
      for($i=0; $i < $delcount; $i++) {
        my $dc;
        $dc = shift(@sorted_versions);
        $dc =~ s/\./-/g;
        push(@for_removal, $dc);
        #print OUT "rm -f /var/virtual_hosts/download/nightly/packages/$current_distri/trunk/$current_group*trunk_r$dc*.rpm\n";
        print OUT "rm -f /var/virtual_hosts/download/nightly/packages/debian/dists/$current_distri/trunk/binary-i386/$current_group\_*svn$dc*.deb\n";
        $must_rebuild_sth = "yes" if(@for_removal);
      }
      print "\$keep_revisions = $keep_revisions is larger/equal $no_of_versions....\n";
      print "will kick -> @for_removal\n";
      print "will keep -> @sorted_versions\n";
      print "DEBUG >> most_recent thereof -> $most_recent\n";
      print "########################################### next one ....\n";
    } else {
      print "Not enough DEBS in group $current_group\n";
      print "Minimum required package count to be left in repo is: $keep_revisions\n";
      print "... but I found only $no_of_versions DEB(s) here.\n";
      print "########################################### next one ....\n";
      $must_rebuild_sth = "no";
    }
  }
  #exit 0;
  if($must_rebuild_sth eq "yes") {
    #print OUT "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/nightly/packages/$current_distri/trunk/\n";
    #print OUT "/home/www/scripts/do_LATESTVERSION.pl /var/virtual_hosts/download/nightly/packages/$current_distri/trunk/\n";
    #print OUT "/home/www/scripts/trunk_apt4rpm_build.pl -d $current_distri\n";
    print OUT "#================================================================================================\n";
  }
}
close(OUT);
