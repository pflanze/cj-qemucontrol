#!/usr/bin/perl -w

# Test whether speed is greater than with hashes

use lib '.';

package H::a;
use strict;
use Class::Array -members=> qw//;
sub A { 0 };
sub B { 1 };
sub C { 2 };

sub new {
	my $class=shift;
	my $self=[];
	@{$self}[A,B,C] = (0,0,0);
	bless $self,$class;
}


package H::b;
use strict;
use Class::Array -extend=> qw//, -class=> 'H::a';
sub A { 0 };
sub B { 1 };
sub C { 2 };

sub dosomething {
	my $self=shift;
	$self->[B]++;
	$self->[A]= $self->[B] + $self->[C];
}


package main;
use Time::HiRes 'time';
use strict;
use constant ANZOBJ=> 10000;
use constant ANZITER=> 100000;



my @objects; $objects[ANZOBJ]=1;
my $start=time;
for (0..ANZOBJ) {
	$objects[$_]= H::b->new;
}
my $step1=time;
for (my $i=0; $i<ANZOBJ; $i+=2000) {
	my $o= $objects[$i];
	for (1..ANZITER) {
		$o->dosomething;
	}
}
my $step2=time;


print "Step 1: ".($step1-$start)."\n";
print "Step 2: ".($step2-$step1)."\n";

sleep 100;

__END__

chris@G3 t > ./speedtest_hash.pl
Step 1: 0.264108061790466
Step 2: 5.6385749578476
chris@G3 t > ./speedtest_hash.pl
Step 1: 0.267836928367615
Step 2: 5.6886340379715
chris@G3 t > ./speedtest_hash.pl
Step 1: 0.299815058708191
Step 2: 5.51392090320587


chris@G3 t > ./speedtest_array.pl
Step 1: 0.293471932411194
Step 2: 5.28328108787537
chris@G3 t > ./speedtest_array.pl
Step 1: 0.289607048034668
Step 2: 5.27212500572205
chris@G3 t > ./speedtest_array.pl
Step 1: 0.292579054832458
Step 2: 5.41358995437622
chris@G3 t > 


chris@G3 t > ./speedtest_array_realconstant.pl
Step 1: 0.291193008422852
Step 2: 5.27445197105408
chris@G3 t > ./speedtest_array_realconstant.pl
Step 1: 0.290555953979492
Step 2: 5.40502893924713
chris@G3 t > ./speedtest_array_realconstant.pl
Step 1: 0.292360067367554
Step 2: 5.28830599784851
chris@G3 t >


chris@G3 t > ./speedtest_array_notconstant.pl
Step 1: 0.396031022071838
Step 2: 11.9981939792633
chris@G3 t > ./speedtest_array_notconstant.pl
Step 1: 0.399051904678345
Step 2: 12.1493080854416
chris@G3 t > ./speedtest_array_notconstant.pl
Step 1: 0.399729013442993
Step 2: 12.1426559686661


