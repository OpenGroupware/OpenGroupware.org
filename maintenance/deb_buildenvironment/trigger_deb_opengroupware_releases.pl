#!/usr/bin/perl -w
# frank reppin <frank@opengroupware.org> 2004
# 
use strict;
#die "WARNING: not yet configured!\n";
my $host_i_runon = "sarge";
#my $host_i_runon = "sid";
my $svn_host = 'svn.opengroupware.org';
my $svn = '/usr/bin/svn';
my $dl_host = "download.opengroupware.org";
my $www_user = "www";
my $www_host = "download.opengroupware.org";
$ENV{'COLUMNS'} = "230";
my $i_really_had_sth_todo = "no";
my @latest;
my $tarball_name;
my $orel;
my $buildtarget;
my $apttarget;
my $hpath = "$ENV{HOME}/";
my @skip_list = qw( opengroupware.org-0.9pre-r4.tar.gz
opengroupware.org-1.0alpha1-shapeshifter-r34.tar.gz
opengroupware.org-1.0alpha2-shapeshifter-r49.tar.gz
opengroupware.org-1.0alpha3-shapeshifter-r59.tar.gz
opengroupware.org-1.0alpha4-shapeshifter-r84.tar.gz
opengroupware.org-1.0alpha5-shapeshifter-r86.tar.gz
opengroupware.org-1.0alpha6-shapeshifter-r89.tar.gz
opengroupware.org-1.0alpha7-shapeshifter-r158.tar.gz
opengroupware.org-1.0alpha8-shapeshifter-r452.tar.gz
);

my $build_opts = "-v yes -u yes -t release -d yes -f yes";
my @ogo_releases;
my @ogo_spec;
my $line;
my $sope_spec;
my $sope_src;

@ogo_releases = `wget -q --proxy=off -O - http://$dl_host/nightly/sources/releases/MD5_INDEX`;
open(KNOWN_OGo_RELEASES, ">> $hpath/OGo.known.rel");
foreach $orel (@ogo_releases) {
  chomp $orel;
  $orel =~ s/^.*\s+//g;
  next unless($orel =~ m/^opengroupware.org/i);
  my @already_known_ogo_rel = `cat $hpath/OGo.known.rel`;
  next if (grep /$orel/, @skip_list);
  $buildtarget = $orel;
  $buildtarget =~ s/-r\d+.*$//g;
  unless(grep /\b$orel\b/, @already_known_ogo_rel) {
    $i_really_had_sth_todo = "yes";
    print "Retrieving: http://$dl_host/nightly/sources/releases/$orel\n";
    system("wget -q --proxy=off -O $ENV{HOME}/sources/$orel http://$dl_host/nightly/sources/releases/$orel");
    #since we build the OGo release using a specific SOPE release... we must 
    #cleanup prior OGo *and* SOPE builds
    #I guess we don't need to do it exactly this way bc apt-get install in a later stage
    #will remove packages we don't need too. But hey - why not?
    print "cleaning up previous libobjc-lf2/libfoundation build...\n";
    system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(libfoundation|libobjc-lf2)'`");
    print "cleaning up previous SOPE build...\n";
    system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
    print "cleaning up previous OGo build...\n";
    system("sudo dpkg --purge `dpkg -l |awk '{print \$2}'|grep -iE '(^libopengroupware|opengroupware)'`");
    print "preparing SOPE... and libfoundation/libobjc-lf2\n";
    if ($orel =~ m/alpha9/i) {
      #major hack... bc I didn't saw the builddeps file.
      my $srel = "sope-4.3.9-shapeshifter-r301.tar.gz";
      print "TEMPORARY WORKAROUND: need sope 4.3.9... or 4.3.10?\n";
      #warn "This will fetch the most recent 4.3 ... but what to do\n"
      #warn "if we want to use a specific 4.3 (ie 4.3.9 vs 4.3.10)??\n"
      #system("sudo apt-get install libsope-core4.3-dev --assume-yes");
      warn "HACK? isn't it better to do it my way (that is rebuilding from source\n";
      warn "without doing an apt-get install <wanted_sope_release>:\n";
      print "calling `purveyor_of_debs.pl -p sope -v yes -t release -u no -d yes -f yes -c $srel`\n";
      system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -t release -u no -d yes -f yes -c $srel");
    }
    if ($orel =~ m/alpha10/i) {
      #major hack... bc I didn't saw the builddeps file.
      my $srel = "sope-4.4beta.2-voyager-r527.tar.gz";
      #warn "This will fetch the most recent 4.3 ... but what to do\n"
      #warn "if we want to use a specific 4.3 (ie 4.3.9 vs 4.3.10)??\n"
      #system("sudo apt-get install libsope-core4.4-dev --assume-yes");
      warn "HACK? isn't it better to do it my way (that is rebuilding from source\n";
      warn "without doing an apt-get install <wanted_sope_release>:\n";
      print "calling `purveyor_of_debs.pl -p sope -v yes -t release -u no -d yes -f yes -c $srel`\n";
      system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -t release -u no -d yes -f yes -c $srel");
    }
    if ($orel =~ m/alpha11/i) {
      my $dep;
      my @prereq;
      #major pain.... this hack makes my dog cry :/
      warn "HACK? isn't it better to do it my way (that is rebuilding from source\n";
      warn "without doing an apt-get install <wanted_sope_release>:\n";
      open(OGO_DEPS, "$ENV{HOME}/sarge_opengroupware_release.hints") || die "Arrr: $!\n";
      @prereq = <OGO_DEPS>;
      close(OGO_DEPS);
      print "installing prequired packages to satisfy automatic dependency generator...\n";
      foreach $dep(@prereq) {
        chomp $dep;
        #keep order in file...
        system("$ENV{HOME}/purveyor_of_debs.pl -p libobjc-lf2 -t release -v yes -u no -d yes -c $dep") if($dep =~ m/gnustep-objc-lf2/i);
        system("$ENV{HOME}/purveyor_of_debs.pl -p libfoundation -t release -v yes -u no -d yes -c $dep") if($dep =~ m/libfoundation/i);
        system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -t release -u no -d yes -f yes -c $dep") if($dep =~ m/sope/i);
      }
    }
    print "OGo_REL: building debs for OGo $orel\n";
    print "calling `purveyor_of_debs.pl -p opengroupware $build_opts -c $orel\n";
    system("$ENV{HOME}/purveyor_of_debs.pl -p opengroupware.org $build_opts -c $orel");
    print KNOWN_OGo_RELEASES "$orel\n";
    print "recreating apt-repository for: $host_i_runon >>> $buildtarget\n";
    open(SSH, "|/usr/bin/ssh $www_user\@$www_host");
    #these differ...
    $apttarget = $buildtarget;
    $apttarget =~ s/^opengroupware\.org/opengroupware/g;
    print "thus calling: /home/www/scripts/release_in_nightly_debian_apt.sh $host_i_runon $apttarget\n";
    print SSH "/home/www/scripts/release_in_nightly_debian_apt.sh $host_i_runon $apttarget\n";
    close(SSH);
  }
}
close(KNOWN_OGo_RELEASES);

if($i_really_had_sth_todo eq "yes") { 
  #polish buildenv after we're done...
  print "we're almost at the end... cleaning up what we've done so far...\n";
  system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(^libsope|^sope|^libical-sope)'`");
  system("sudo dpkg --purge `dpkg -l | awk '{print \$2}' | grep -iE '(^libopengroupware|opengroupware)'`");
  #go back to latest trunk build - that is, before we grabbed a new release we had
  #the most current sope trunk built/installed
  print "restoring latest build state...\n";
  system("$ENV{HOME}/purveyor_of_debs.pl -p sope -v yes -u no -d yes -f yes -b no");
  system("$ENV{HOME}/purveyor_of_debs.pl -p opengroupware.org -v yes -u no -d yes -f yes -b no");
}
