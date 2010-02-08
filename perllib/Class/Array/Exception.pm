package Class::Array::Exception;

# Copyright 2001-2008 by Christian Jaeger, christian at jaeger mine nu

=head1 NAME

Class::Array::Exception - exception base class

=head1 SYNOPSIS

 use My::IOException; # let's assume this inherits from My::Exception, 
        # which in turn inherits from Class::Array::Exception
 
 try {
     open FILE, $file or die "Could not open $file: $!";
     try {
         ..
         throw My::IOException "You don't have permission", EPERM;
         ..
     }
     catch My::Exception {
         print LOG "Some of my exceptions occured: $@";
     }
     catch Some::Other::Exception, Foreign::Exception {
         print LOG "Some other exception that I know of: $@";
     }
     catch * {
         print LOG "Some unknown exception or error: $@";
     }
 }
 catch * {
     print LOG $@;
 }
 finally {
     close FILE; # guaranteed to be executed
 }

=head1 DESCRIPTION

Base class for building Class::Array based Exception classes
acting similar to Error.pm.

Whenever a subclass of Class::Array::Exception is use'd,
it invokes a perl source filter (Error::Filter) that 
translates try, catch, otherwise and finally keywords to native perl.
For details see L<Error::Filter>.

Class::Array::Exception defines a few public fields (sorry
about the namespace pollution, should I keep them protected?):

    ExceptionText       Text,
    ExceptionValue      value given as arguments to throw.
    ExceptionPackage    Package,
    ExceptionFile       file and
    ExceptionLine       line from where throw was called.
    ExceptionRethrown   True if rethrown (it's an array ref of
                        arrayrefs containing package/file/line
                        of the 'caller' of rethrow[/throw];
                        each rethrow[/throw] pushes another row)
    ExceptionStacktrace May be filled upon calling 'throw' or 
                        'ethrow' (see below)
    ExceptionStacktraceHasfullargs 
                        Is set tostacktrace_keepfullargs (see 
                        below) by throw/ethrow 

The class is overloaded so you can simply access $@ in string
or number context and get a nice error summary or the ExceptionValue
respectively.

'ExceptionStacktrace' is only set if stacktraces have been switched on
prior to throwing the exception using the set_stacktrace() class method.


=head1 CLASS METHODS

=over 4

=item new( text, value [, caller_i ] )

=item throw( text, value [, caller_i ]  )

These are the same except that throw actually calls die, and
that throw always records the package/file/line where it is called from
whereas new only does this if caller_i is defined. caller_i defines 
which caller should be recorded (how many call frames should be
skipped).

NOTE: you can use throw as an object method as well, it then behaves
identically to rethrow. (I find it better to explicitely use "rethrow" 
for this purpose though, since it expresses better what it does.
'throw' is only a hybrid class/object method since
Error.pm uses 'throw' to rethrow an exception (as does C++).)

=item set_stacktrace( key [=> value] [, key=>value,... ] )

Changes stacktracing settings (the values of the Class::Array::Exception::
package globals 
$stacktrace_record,
$stacktrace_output,
$stacktrace_nargs,
$stacktrace_maxarglen and $stacktrace_keepfullargs -- 
using an inheritable method seems cooler for this purpose since
users of your derived exception class don't have to remember that your
class inherits from Class::Array::Exception, and also typos will
be discovered immediately.)

If only a key is given, a reference to the scalar containing the
setting is given. This allows for example to use 'local' on a value
(my $settingref= Class::Array::Exception->set_stacktrace('record');
local $$settingref= 1;).

Description of the options:

=over 4

=item record

false (which is the default) means that the 'ExceptionStacktrace' will not
be set upon throwing an exception (which will be faster). 

=item output

true (which is the default) means that the stacktrace will 
also be included in the output of 'stringify' (if you happen to override 
stringify, you should make it append the output of the 'stacktrace' object method)

=item nargs

0 means that 'ExceptionStacktrace'
will be set to contain only the caller information (file,line,subname),
a higher value means that also up to the n first subroutine arguments of each stack 
frame will be included in 'ExceptionStacktrace' (as arrayref stored in column 10).
(defaults to 8)

=item maxarglen

the maximum length of each string subroutine argument before truncation (default: 16).

=item keepfullargs

if true (and nargs>0 of course), the full 
subroutine arguments are kept (as a copy) in ExceptionStacktrace. The default
of false means that only a substr of strings and only the stringified representation
of references are kept.
Note that including the full subroutine arguments could take up much memory and
inhibit referenced objects from being destroyed, and if
you don't dispose of the exception object soon (i.e. because you reuse it by means of
throw_existing) this could potentially be a problem. (On the other hand it could
allow you to examine the arguments in detail.)

=back

=back

=head1 OBJECT METHODS

=over 4

=item ethrow ([ caller_i ])

=item throw_existing ([ caller_i ])

These two do the same (I didn't find a really good name for them,
I would have liked to just use 'throw' for that purpose but that's already
used for compatibility (see above)), though C<throw_existing> is 
slightly deprecated since C<ethrow> is shorter and it's better only to use
one method. Think "economical throw" if you want.

They throw an existing exception object
that has been created by 'new'. 
They record the package/file/line where they are called from,
erase the ExceptionRethrown field and then call die.
This makes it possible to reuse exception objects.
For caller_i see 'new'/'throw'.

=item rethrow

Pushes package, file and line where rethrow has been called from
into ExceptionRethrown and then calls die. 

=item record_stacktrace(caller_i)

Used internally.

=item stringify

=item value

The two methods used for overloading in string or number context.
stringify uses the 'text' method to retrieve the contents of the
exception, so you should only ever need to override the text method.

=item text

Returns the contents of the exception as text, without class, line or
rethrow tracing information (by default "ExceptionText (ExceptionValue)").

=item stacktrace

If switched on by means of set_stacktrace (package var stacktrace_output), 
returns the stacktrace formatted as text, otherwise returns the empty string.

=item stacktrace_loa

Returns a list of arrays each representing a frame of the stacktrace (containing
[ file, line, "subroutine(args)"], where args are shortened according to the 
stacktrace settings).
Used by the 'stacktrace' method.

=back

=head1 BUGS

Maybe throw() should always use new() internally, so you only have to override
new and not also throw in subclasses if you want to use more than 2 arguments.
But then the caller_i argument handling would get in the way.

Maybe the caller_i mechanism should be replaced by something better (class 
name to start backtracing?, or?).

=head1 SEE ALSO

L<Error::Filter>

=head1 AUTHOR

Christian Jaeger, christian at jaeger mine nu

=cut


use strict;
require Error::Filter; # we don't need to be filtered here so don't use it.

use Class::Array -fields=> qw(
-public
	ExceptionText
	ExceptionValue
	ExceptionPackage
	ExceptionFile
	ExceptionLine
	ExceptionRethrown
	ExceptionStacktrace
	ExceptionStacktraceHasfullargs
); # ExceptionDepth   what for?



use overload (
	'""'	   =>	'stringify',
	'0+'	   =>	'value',
	'bool'     =>   sub (){1}, # short cut this segfaulting bool 
	'fallback' =>	1  # 1 will give segfaults under 5.6.1 when falling back from boolean test, and since the fallen back boolean operation would probably be slow anyway, be sure to test for ref($@) *first* and only after that for trueness ($@ seems to never be undef so you can't test for that)
);

sub import {
	my $class=shift;
	my $caller=caller;
	$class->SUPER::import(-caller=> $caller, @_);
	no strict 'refs';
	if (${"${caller}::".__PACKAGE__."::filtered"}) {
		#print "$caller Already filtered\n";
	} else {
		Error::Filter->import;
		${"${caller}::".__PACKAGE__."::filtered"}=1;
	}
}

use vars qw/$stacktrace_record $stacktrace_output $stacktrace_nargs $stacktrace_maxarglen
		$stacktrace_keepfullargs/;
$stacktrace_record= undef;
$stacktrace_output=1;
$stacktrace_nargs= 8;
$stacktrace_maxarglen= 16;
$stacktrace_keepfullargs= undef;
my %settingsrefs= (
	record=>\$stacktrace_record,
	output=>\$stacktrace_output,
	nargs=>\$stacktrace_nargs,
	maxarglen=>\$stacktrace_maxarglen,
	keepfullargs=>\$stacktrace_keepfullargs,
);
sub set_stacktrace {
	my $class=shift;
	if (@_ == 1) {
		if (my $ref=$settingsrefs{$_[0]}) {
			$ref
		} else {
			my ($p,$f,$l)=caller;
			die "set_stacktrace: unknown key '$_[0]' at $f line $l\n";
		}
	} else {
		if (@_ % 2) {
			my ($p,$f,$l)=caller;
			die "set_stacktrace: uneven number of arguments at $f line $l\n";
		}
		while (@_) {
			my $key=shift;
			if (my $ref=$settingsrefs{$key}) {
				$$ref= shift;
			} else {
				my ($p,$f,$l)=caller;
				die "set_stacktrace: unknown key '$key' at $f line $l\n";
			}
		}
	}
}

sub new {
	my $class=shift;
	my ($text,$value,$caller_i)=@_;
	#my $self= $class->SUPER::new;
	my $self = bless [], $class;
	@$self[ExceptionText,ExceptionValue]= ($text,$value);
	if (defined $caller_i) {
		@$self[ExceptionPackage,ExceptionFile,ExceptionLine]= caller($caller_i) ;
		$self->record_stacktrace($caller_i+1) if $stacktrace_record;
	}
	$self
}

sub throw {
	my $class=shift;
	if (ref $class) {
		#if ($self->[ExceptionRethrown]) {
			if (defined $class->[ExceptionPackage]) {
				# rethrow
				push @{$class->[ExceptionRethrown]}, [ caller ];
				die $class
			} else {
				my ($p,$f,$l)=caller;
				die "'throw' of a pristine exception object not allowed, use ethrow instead at $f line $l\n";
			}
		#} else {
		#	# throw the existing but never thrown exception object
		#	...see below
		#	$class->[ExceptionRethrown]=[];
		#	die $class
		#}
		#  We *could* do all this, to make it possible to 'throw' a 'new'ly created
		#  exception object so it is distinct from being rethrown, but I doubt this
		#  makes much sense, I think it's better to always use ethrow for that purpose.
	} else {
		# create new object
		my ($text,$value,$caller_i)=@_;
		my $self = bless [], $class; # my $self= $class->SUPER::new;
		@$self[ExceptionText,ExceptionValue]= ($text,$value);
		@$self[ExceptionPackage,ExceptionFile,ExceptionLine]= caller($caller_i||0); ## is this a costly operation?
		$self->record_stacktrace($caller_i||0+1) if $stacktrace_record;
		# do this   $self->[ExceptionRethrown]=[];  and then check above so throw $@ can decide if it's the first throw or not?
		die $self
	}
}

sub throw_existing { # throw existing  (erase rethrow data before doing so)
	my $self=shift;
	undef $self->[ExceptionRethrown];# or: $self->[ExceptionRethrown]=[];
	undef $self->[ExceptionStacktrace];
	@$self[ExceptionPackage,ExceptionFile,ExceptionLine]= caller(@_);
	$self->record_stacktrace($_[0]||0+1) if $stacktrace_record;
	die $self
}

*ethrow = *throw_existing{CODE};

sub record_stacktrace {
	my $self=shift;
	my ($caller_i)=@_;
	my $i= $caller_i + 1; # (we already got the primary caller)
	if ($stacktrace_nargs) {
		if ($self->[ExceptionStacktraceHasfullargs]= $stacktrace_keepfullargs) {
			{ 	package DB; 
				while (caller($i)) {
					push @{$self->[Class::Array::Exception::ExceptionStacktrace]}, 
						[ caller($i), ## should we check if caller is '(eval)' so we don't waste memory copying stale args? 8//
							[@DB::args <= $Class::Array::Exception::stacktrace_nargs ? 
								@DB::args 
								: ( @DB::args[0..$Class::Array::Exception::stacktrace_nargs-1], "...")
							] 
						];
					$i++ 
				};
			}
		} else {
			{ 	package DB; 
				while (caller($i)) {
					push @{$self->[Class::Array::Exception::ExceptionStacktrace]}, 
						[ caller($i), ## should we check if caller is '(eval)' so we don't waste memory copying stale args? 8//
							[	
								map {
									defined() ?
									  (ref() ?
										"r$_"
										: "s".substr($_,0,$Class::Array::Exception::stacktrace_maxarglen+1))
									    : "rundef"
								}
								@DB::args <= $Class::Array::Exception::stacktrace_nargs ? 
									@DB::args 
									: ( @DB::args[0..$Class::Array::Exception::stacktrace_nargs-1], "...")
							] 
						];
					$i++ 
				};
			}
		}
	} else {
		while (push @{$self->[ExceptionStacktrace]}, [ caller($i) ]) { $i++ };
	}
}

sub rethrow {
	my $self=shift;
	push @{$self->[ExceptionRethrown]}, [ caller ];
	die $self
}

sub stringify {
	my $self=shift;
	my $txt= $self->text;
	ref($self)
	.($txt ? ": $txt " : "")
	.( defined($$self[ExceptionFile]) and !defined($self->[ExceptionText]) || $self->[ExceptionText]!~/\n$/s
		? " at $self->[ExceptionFile] line $self->[ExceptionLine].\n"
			.join("",map { "\t...rethrown at $_->[1] line $_->[2]\n" } @{$self->[ExceptionRethrown]})
			.($stacktrace_record ? $self->stacktrace : "")
		: "")
}

sub stacktrace {
	my $self=shift;
	if ($stacktrace_output and $self->[ExceptionStacktrace]) {
		"\tStacktrace:\n"
		.join("", map { 
				#"\t$_->[0] line $_->[1] called $_->[2]\n"
                                "\t$$_[2]\n". 
                                "\t\tat $$_[0] line $$_[1]\n" 
			} $self->stacktrace_loa)
	} else {
		""
	}
}

sub stacktrace_loa {
	my $self=shift;
	map {
		[$_->[1],$_->[2],
			($_->[3] eq '(eval)' ?
			"eval{} or try{}"  ##possibly we get here from eval""?
			: $_->[4] ? 
				# sub call has args
				$_->[3]
				.($_->[10] ? 
					do {
						# format argument list; code affected by Carp::Heavy
						my $c; # this works! :)
						"(".join(", ", map {
							if (ref) {
								"$_"
							} else {
								if (!$self->[ExceptionStacktraceHasfullargs] and /^r/) {
									# once was a ref
									substr($_,1)
								} else {
									if ($self->[ExceptionStacktraceHasfullargs]) {
										$c= length > $stacktrace_maxarglen ? 
											substr($_,0,$stacktrace_maxarglen)."..."
											: $_;
									} else {
										$c= length > $stacktrace_maxarglen + 1 ? 
											substr($_,1,$stacktrace_maxarglen)."..."
											: substr($_,1);
									}
									$c=~ /^-?[\d.]+$/s ? 
										$c
									: 	do{
										$c=~ s/'/\\'/g;
										$c=~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
										$c=~ s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
										"'$c'"
									}
									# (Hmm, thread id stuff?)
								}
							}
						} @{$_->[10]} )
						.")"
					}
					: "")
				: '&'.$_->[3] # no args
			)
		]
	} @{$self->[ExceptionStacktrace]}
}

sub text {
	my $self=shift;
	(defined $self->[ExceptionText] ? "$self->[ExceptionText]" : "")
	.(defined $self->[ExceptionValue] ? " ($self->[ExceptionValue])" : "(no value)")
}

sub value {
	shift->[ExceptionValue]
}


1;
