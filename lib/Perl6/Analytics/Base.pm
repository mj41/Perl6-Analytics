package Perl6::Analytics::Base;

use strict;
use warnings;
use Carp qw(carp croak verbose);

sub new {
	my ( $class, %args )= @_;
	my $self = {};
	$self->{vl} = $args{verbose_level} // 3;
	bless $self, $class;
}

sub get_ipos_str {
	my ( $self, $offset ) = @_;
	$offset //= 0;
	my $line = (caller(1+$offset))[2] || 'l';
	my $sub = (caller(2+$offset))[3] || 's';
	return "$sub($line)";
}

sub dump {
	croak "Missing parameter for 'dump'.\n" if scalar @_ < 3;
	my ( $self, $text, $struct, $offset ) = @_;
	unless ( $self->{dumper_loaded} ) {
		require Data::Dumper;
		$self->{dumper_loaded} = 1;
	};

	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Pad = '';
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Deparse = 1;
	unless ( $text ) {
		print Data::Dumper->Dump( [ $struct ] );
		return;
	}
	print $text . ' on ' . $self->get_ipos_str($offset) . ': ' . Data::Dumper->Dump( [ $struct ] );
}

1;
