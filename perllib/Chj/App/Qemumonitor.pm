#
# Copyright 2009 by Christian Jaeger, chrjae at gmail com
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::App::Qemumonitor

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::App::Qemumonitor;

use strict;

use Class::Array -fields=>
  -publica=>
  #public. #wl yeh iknow fun.
  'servicename',
  #private?kindof:
  'servicefolder',
  'verbose',
  ;

sub new {
    my $cl=shift;
    @_==1 or die;
    my $s=$cl->SUPER::new;
    ($$s[Servicename])= @_;

    $$s[Servicefolder]= "$ENV{HOME}/tmp/cj-qemucontrol/".$s->servicesubfolder;
    -d $$s[Servicefolder]
      #or die "folder doesn't exit:
      or die "folder not accessible: '$$s[Servicefolder]': $!";

    $s
}

use IO::Socket;

#           As of VERSION 1.18 all IO::Socket objects have autoflush turned on by default. This
#           was not the case with earlier releases.

sub vprint {
    my $s=shift;
    print @_ # or die "Vprint: $!";
      if $s->verbose;
}


sub servicesubfolder {
    my $s=shift;
    my $servicename= $s->servicename;
    if ($servicename=~ m|^([^/]+)\z|s) {
	my $str=$1;
	die "'..' not allowed" if ($str eq "..");
	$str
    } else {
	die "contains slashes or is empty: '$servicename'";
    }
}

sub monitorsocketpath {
    my $s=shift;
    $s->servicefolder."/monitor"
}

sub send_receive {
    my $s=shift;
    my $send= join("",@_);
    my $monitorsocketpath= $s->monitorsocketpath;
    local our $socket= IO::Socket::UNIX->new (Type=> SOCK_STREAM,
					      Peer=> $monitorsocketpath,
					     )
      or die "can't open socket '$monitorsocketpath': $!";
    $socket->send ($send)
      #correct??
      or die "send: $!";
    $socket ->shutdown(SHUT_WR); # flushing would (ehr  have worked too? but it said above that it's on anyway?... so  then  'maybenot'). this is now how the socat single-call worked.
    {
	local $/;
	my $res= <$socket>;
	$socket->close
	  or die "close: $!";
	#^closing both?--ahnow only the other one, anyway.
	$res
    }
}

use Time::HiRes 'sleep';

sub poll_with_for {
#sub expect {
    my $s=shift;
    my ($querycmd,$regex)=@_;
    $s->vprint ("waiting with $querycmd for $regex ..\n");
    my $sleeptime= 0.2;
    while (1) {
	my $res= $s->send_receive("$querycmd\n"); # \n is essential! ! ! !. and interestingly doesn't need to be \r\n
	$s->vprint("  got '$res'\n");
	if ($res =~ /$regex/) {
	    last;
	}
	sleep $sleeptime;
	$sleeptime= $sleeptime * 1.2;#?
    }
}

sub send {
    my $s=shift;
    my $cmd= join("",@_)."\n";
    $s->vprint("sending $cmd");
    $s->send_receive($cmd);
    $s->vprint(" -> done.\n");
}


end Class::Array;
