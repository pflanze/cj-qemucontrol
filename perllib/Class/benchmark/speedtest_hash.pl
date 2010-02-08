#!/usr/bin/perl -w

# Test whether speed is greater than with hashes

package H::a;

sub new {
	my $class=shift;
	my $self={A=>0, B=>0, C=>0};
	bless $self,$class;
}


package H::b;

@H::b::ISA= ('H::a');

sub dosomething {
	my $self=shift;
	$self->{C}++;
	$self->{A}= $self->{B} + $self->{C};
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
