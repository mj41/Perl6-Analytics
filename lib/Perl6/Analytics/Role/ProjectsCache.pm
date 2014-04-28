package Perl6::Analytics::Role::ProjectsCache;

use strict;
use warnings;

use Perl6::Analytics::Projects;

sub projects_obj {
	my ( $self ) = @_;
	unless ( $self->{addons}{projects_obj} ) {
		my $projects_obj = Perl6::Analytics::Projects->new( verbose_level => $self->{vl} );
		$projects_obj->load_from_cache();
		$self->{addons}{projects_obj} = $projects_obj;
	}
	return $self->{addons}{projects_obj};
}

1;
