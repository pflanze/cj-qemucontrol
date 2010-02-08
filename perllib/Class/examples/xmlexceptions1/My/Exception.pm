package My::Exception;

# $Id: Exception.pm,v 1.1 2002/04/02 14:28:02 chris Exp $

=head1 NAME

My::Exception 

=head1 DESCRIPTION

Records an XML fragment in addition to the usual text/number exception arguments.

Still stringifies in the usual way - Read the XML off the public field [ExceptionXML]
if you want it.


This is merely experimental. I already have a better idea, namely to define the
xml in the exception (sub)class(es) itself. Then provide a method to rethrieve
it with maybe the txt/number etc. arguments included in the xml.

=cut


use strict;

use Class::Array::Exception -extend=> qw(
-public
	ExceptionXML
);



sub throw {
	my $class=shift;
	my ($xml,$txt,$num)=@_;
	my $self= $class->SUPER::new($txt,$num,2);
	$self->[ExceptionXML]= $xml;
	die $self
}
	

1;
