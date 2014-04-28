package Perl6::Analytics::Role::JSON;

use strict;
use warnings;

use JSON::XS;

sub json_obj {
	my ( $self ) = @_;
	$self->{addons}{json_obj} = JSON::XS->new->canonical(1)->pretty(1)->utf8(0)->relaxed(1)
		unless $self->{addons}{json_obj};
	return $self->{addons}{json_obj};
}

1;
