#!/usr/bin/perl -w
#frank reppin <frank@opengroupware.org> 2004

use strict;
my $host_i_runon;
my $mod_ngobjweb_to_use;
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
my @skip_list = qw( libical-sope1-r30.tar.gz
  libFoundation-1.0.59-r29.tar.gz
  libFoundation-1.0.64-r61.tar.gz
  libFoundation-1.0.65-r63.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @tp_releases;
eval getconf("$ENV{'HOME'}/purveyor_of_rpms.conf") or die "FATAL: $@\n";

sub getconf {
  my $conffile = shift;
  local *F;
  open F, "< $conffile" or die "Error opening '$conffile' for read: $!";
  if(not wantarray){
    local $/ = undef;
    my $string = <F>;
    close F;
    return $string;
  }
  local $/ = "";
  my @a = <F>;
  close F;
  return @a;
}

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
  #print "checking for buildtarget: $buildtarget\n";
  unless(grep /\b$tprel\b/, @already_known_tp_rel) {
    my $cleanup;
    my $mapped_temp_specfilename;
    my $package_to_build; # <-p> switch for 'purveyor_of_rpms.pl'
    my $tardirname; #HINT... specified during sourcetarball creation (svn_update.sh)
    my $buildtargetspecfilesize;
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/sources/releases/$tprel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/rpm/SOURCES/$tprel http://$dl_host/sources/releases/$tprel");
    $cleanup = "epoz" if ($tprel =~ m/epoz/i);
    $mapped_temp_specfilename = "epoz.spec" if ($tprel =~ m/epoz/i);
    $package_to_build = "epoz" if ($tprel =~ m/epoz/i);
    $tardirname = "sope-epoz" if ($tprel =~ m/epoz/i);
    ##
    $cleanup = "libobjc-lf2" if ($tprel =~ m/gnustep-objc/i);
    $mapped_temp_specfilename = "libobjc-lf2.spec" if ($tprel =~ m/gnustep-objc/i);
    $package_to_build = "libobjc-lf2" if ($tprel =~ m/gnustep-objc/i);
    $tardirname = "libobjc-lf2" if ($tprel =~ m/gnustep-objc/i);
    ##
    $cleanup = "libfoundation" if ($tprel =~ m/libfoundation/i);
    $mapped_temp_specfilename = "libfoundation.spec" if ($tprel =~ m/libfoundation/i);
    $package_to_build = "libfoundation" if ($tprel =~ m/libfoundation/i);
    $tardirname = "libfoundation" if ($tprel =~ m/libfoundation/i);
    ##
    $cleanup = "libical-sope" if ($tprel =~ m/libical-sope/i);
    $mapped_temp_specfilename = "libical-sope.spec" if ($tprel =~ m/libical-sope/i);
    $package_to_build = "libical-sope" if ($tprel =~ m/libical-sope/i);
    $tardirname = "libical-sope" if ($tprel =~ m/libical-sope/i);
    ##
    print "cleaning up prior actual build... going to remove rpms for: $cleanup\n";
    system("sudo rpm -e `rpm -qa|grep -i ^$cleanup` --nodeps");
    system("sudo /sbin/ldconfig");
    print "extracting specfile ($mapped_temp_specfilename) from $tprel into spec_tmp/ dir\n";
    system("mkdir $ENV{HOME}/spec_tmp/") unless (-e "$ENV{HOME}/spec_tmp/");
    system("tar xfzO $ENV{HOME}/rpm/SOURCES/$tprel $tardirname/$mapped_temp_specfilename >$ENV{HOME}/spec_tmp/$buildtarget.spec");
    $buildtargetspecfilesize = -s "$ENV{HOME}/spec_tmp/$buildtarget.spec";
    #extracted spec should have a reasonable size
    if( $buildtargetspecfilesize <= 1 ) {
      print "extracted specfile has a size of: $buildtargetspecfilesize\n";
      print "this is most likely an error and thus I'll quit here building $buildtarget.spec\n";
      #give hint about the most likely reason for this failure;
      print "HINT: make sure that $mapped_temp_specfilename is present in $tprel\n";
      exit 1;
    }
    print "TP_REL: building release RPMS for ThirdParty $tprel\n";
    if ( $package_to_build eq "libfoundation" ) {
      #we must ensure that we have a debug=no libobjc-lf2 present...
      print "We're building a release for $package_to_build - ensuring that we have a debug=no libobjc-lf2 present...\n";
      system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
      system("sudo /sbin/ldconfig");
      system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -d yes -u no -t release -c libobjc-lf2-trunk-latest.tar.gz -f yes -b no");
    }
    print "calling `purveyor_of_rpms.pl -p $package_to_build $build_opts -c $tprel -s $ENV{HOME}/spec_tmp/$buildtarget.spec\n";
    system("$ENV{HOME}/purveyor_of_rpms.pl -p $package_to_build $build_opts -c $tprel -s $ENV{HOME}/spec_tmp/$buildtarget.spec");
    system("sudo /sbin/ldconfig");
    if ( $package_to_build eq "libfoundation" ) {
      #we're done - go back to debug=yes libobjc-lf2
      print "We've built a release for $package_to_build - restoring (force) to debug=yes libobjc-lf2\n";
      system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
      system("sudo /sbin/ldconfig");
      system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -d yes -u no -t trunk -c libobjc-lf2-trunk-latest.tar.gz -f yes -b no");
    }
    print KNOWN_TP_RELEASES "$tprel\n";
    print "recreating apt-repository for: $host_i_runon\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    print SSH "/home/www/scripts/release_apt4rpm_build.pl -d $host_i_runon -n ThirdParty\n";
    print SSH "/home/www/scripts/do_md5.pl /var/virtual_hosts/download/packages/$host_i_runon/releases/ThirdParty/\n";
    close(SSH);
  }
}
close(KNOWN_TP_RELEASES);

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
  system("sudo rpm -e `rpm -qa|grep -i ^libobjc-lf2` --nodeps");
  system("sudo rpm -e `rpm -qa|grep -i ^libfoundation` --nodeps");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libobjc-lf2 -v yes -u no -d yes -f yes -b no");
  system("$ENV{HOME}/purveyor_of_rpms.pl -p libfoundation -v yes -u no -d yes -f yes -b no");
}
