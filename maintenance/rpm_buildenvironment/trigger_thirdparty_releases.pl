#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

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
my $tprel;
my $buildtarget;
my $hpath = "$ENV{HOME}/";
my @tp_packages = qw( epoz gnustep-objc libFoundation libical-sope );
my @skip_list = qw( );

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @tp_releases;

@tp_releases = `wget -q --proxy=off -O - http://$dl_host/sources/releases/MD5_INDEX`;
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
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/sources/releases/$tprel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$tprel http://$dl_host/sources/releases/$tprel");
    #print "cleaning up prior actual build...\n";
    #system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
    print "extracting specfile from $tprel\n";
    system("mkdir $ENV{HOME}/spec_tmp/") unless (-e "$ENV{HOME}/spec_tmp/");
    #system("tar xfzO $ENV{HOME}/rpm/SOURCES/$tprel sope/maintenance/sope.spec >$ENV{HOME}/spec_tmp/$buildtarget.spec");
    print "TP_REL: building RPMS for ThirdParty $tprel\n";
    #print "calling `purveyor_of_rpms.pl -p sope $build_opts -c $tprel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    #system("$ENV{HOME}/purveyor_of_rpms.pl -p sope $build_opts -c $tprel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    print KNOWN_TP_RELEASES "$tprel\n";
    print "recreating apt-repository for: $host_i_runon\n";
    #open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    #print SSH "/home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n $buildtarget\n";
    #close(SSH);
  }
}
close(KNOWN_TP_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  if($host_i_runon eq "fedora-core2") {
    print "building yum-repo for $host_i_runon\n";
    #system("sh $ENV{HOME}/prepare_yum_fcore2.sh");
  }
  if($host_i_runon eq "fedora-core3") {
    print "building yum-repo for $host_i_runon\n";
    #system("sh $ENV{HOME}/prepare_yum_fcore3.sh");
  }
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  #system("sudo rpm -e `rpm -qa|grep -i ^sope` --nodeps");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  #system("$ENV{HOME}/purveyor_of_rpms.pl -p sope -v yes -u no -d no -f yes -b no");
}
