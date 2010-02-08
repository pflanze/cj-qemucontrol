package My::IOException;

# $Id: IOException.pm,v 1.1 2002/04/02 14:28:02 chris Exp $

=head1 NAME

My::IOException 

=head1 DESCRIPTION


=cut


use strict;

use My::Exception -extend=> qw(
);


sub throw { # expects only an xml fragment, supplements it with the system error message
	my $class=shift;
	$class->SUPER::throw(shift, $!, $!+0)
}

1;
