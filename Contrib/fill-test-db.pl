#!/usr/bin/perl -w
# Frank Reppin <frank@opengroupware.org>

use strict;
use Frontier::Client;

my $how_much = '5000';
my $xmlrpc_host = 'localhost/RPC2';
my $xmlrpc_user = 'root';
my $xmlrpc_pass = '';
my $url = "http://$xmlrpc_user:$xmlrpc_pass\@$xmlrpc_host";

my $surname;
my $firstname;
my $company_id_person;
my $company_id_enterprise;
my $birthday_raw;
my $birthday_datetime;
my $email1;

my @extendedKeys;
my %extendedAttrs;
my $extendedKeys = \@extendedKeys;
my $extendedAttrs = \%extendedAttrs;

my @yob = ( 1945.. 1980);
my @mob = qw( 01 02 03 04 05 06 07 08 09 10 11 12 );
my @dob = qw( 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 );
my @surnames = qw(mueller meier schubert schuart picard mull lee bush diesel taylor tucker thorpe usher vacher verney tierney tennant vandermeer hamerlinck roegiers vicar voyce waine wagner wright whitaker wakefield wetherby warden wild wilde wicke waterfield winch westwood weston zimmermann wymark woodley ripley winter vyse yarrow addison ackland aird ambler alvarez ashcroft alder anderson ashe ash austen avery allard aldrich bach bain badley ballister berg bennett barclay blair bigg beverley bannister barker baker bakerman bishop burton cannon cohen callaghan coates clifton carson carpenter cooper collins chapman chavez christensen croft carroll cruz cutlar dalton danvers daw deacon dove diaz dickson dunlop dyall dyer davenport davidson dell ellis evan eastwood fairfax flower fielding franklin flint flores french friedman foss ford fowler fisher fay garcia gordon goswell);
my @firstnames = qw(emily megan charlotte jessica lauren sophie olivia hannah lucy kieran jamie jacob michael ben ethan charlie bradley brandon aaron max dylan reece robert christopher alice leah laura rachel amber phoebe zoe paige emma oliver ryan samuel harry daniel luke nichole louis jake jordan rhys thijs lily nathan cameron kieran ken connor andrew max caleb carlos ajax alric cecil clayton clark alison bob boris aisling aithne ena cathleen ina marie morna amber sorcha tara liam kevin tomas neil brian colm fergus alexander amos andrew ambrose albert angus axel baldwin arvel barry bert bevis bruce brooke calvert chandler chester colin curtis cyril craig allana amanda aimee anastasia alma angela april audrey jade joanna jennifer jasmine justine glynnis gloria gwynne gwendolyn germaine gabrielle kyla kay kirstyn kerri karen kacey lorelei maia mandy martina maude mabel merle miriam myra mona monica moira miranda michelle mavis maxine marissa maggie norma nancy nora noelle nina nerita nell naomi nadine orva opal olga octavia odette pandora pamela page penelope prunella robin rosa roxanne ruby rebecca rachel rhoda sarah sheila scarlett shannon sibley tabitha tanya tatum tess thea tiffany tuesday tina uma violet veronica virginia vanessa valerie wanda wendy winone wynne wilma );
my @domainnames = qw(gmx.de gmx.at zulu.net hotmail.com msn.com web.de web.at t-online.de t-com.de xs4all.nl tiscali.de tiscali.com blah.org mekker.com abba.de suse.de mandrake.de aol.com host-europe.de hosteurope.de palm.de krake.de linux.de freshmeat.net);

# 
# array of companies (id's) to randomly assign the aforementioned persons
# (triggered if activated [yes|no]... the companies should be already present in the OGo db!)
my $assign_persons_to_companies = "no";
# fill in the company_id's of the already present companies in the array below (separated by space):
my @company_id_enterprises = qw( 13600 15200 );

my $client = Frontier::Client->new( url=>$url,debug=>0 );

for(my $i=1;$i <= $how_much;$i++) {
  my @result_a;
  my $element_a;
  $birthday_raw = join("", @yob[ map {rand @yob } (1) ],"-",@mob[ map {rand @mob } (1) ],"-",@dob[ map {rand @dob } (1) ], " 00",":","00",":","00");
  $birthday_datetime = $client->date_time("$birthday_raw");
  $surname = ucfirst(join("", @surnames[ map {rand @surnames} (1) ]));
  $firstname = ucfirst(join("", @firstnames[ map {rand @firstnames } (1) ]));
  $email1 = join("", lcfirst($firstname), ".", lcfirst($surname), "@", @domainnames[ map {rand @domainnames } (1) ]);
  $company_id_enterprise = join("", @company_id_enterprises[ map {rand @company_id_enterprises } (1) ]);
  ##
  $element_a->{"name"} = $surname;
  $element_a->{"firstname"} = $firstname;
  $element_a->{"birthday"} = $birthday_datetime;
  $extendedAttrs->{'email1'} = $email1;
  $element_a->{'extendedKeys'} = $extendedKeys;
  $element_a->{'extendedAttrs'} = $extendedAttrs;
  ##
  @result_a = $client->call('person.insert', $element_a);
  $company_id_person = $result_a[0];
  if($assign_persons_to_companies eq "no") {
    print "Generated no. $i:" . " $surname" . " $firstname" . " $email1" . " $birthday_raw" . " (company_id = $company_id_person)\n";
  } elsif($assign_persons_to_companies eq "yes") {
    print "Generated no. $i:" . " $surname" . " $firstname" . " $email1" . " $birthday_raw" . " (company_id = $company_id_person)" . " will add person to company $company_id_enterprise\n";
    assign_person_to_company();
  } else {
    exit 1;
  }
}

sub assign_person_to_company {
  my @result_b;
  @result_b = $client->call('enterprise.insertPerson', "$company_id_enterprise", "$company_id_person");
}

#
# DO NOT REMOVE THIS EXAMPLE SUB!
#
#sub assign_person_to_company {
#  my @result_b;
#  my $assigned_persons_count = 0;
#  my @array_of_persons;
#  print "assign persons to $company_id_enterprise\n";
#  @result_b = $client->call('enterprise.getPersons', "$company_id_enterprise");
#  #uhm - no better way to determine the current state?
#  if(ref($result_b[0]) eq "ARRAY") {
#    $assigned_persons_count = @{$result_b[0]};
#    print "$assigned_persons_count assigned persons\n";
#    for(my $c = 0; $c < $assigned_persons_count; $c++) {
#      my $current_person_id;
#      $current_person_id = $result_b[0][$c]->{'number'};
#      $current_person_id =~ s/\D+//g;
#      push(@array_of_persons, $current_person_id);
#    }
#    push(@array_of_persons, $company_id_person);
#    #add xml method here that would require that you 'update' the current
#    #list with your new element
#    #(adding accounts to teams require to do so)
#  } else {
#    print "no persons assigned yet...\n";
#  }
#}
