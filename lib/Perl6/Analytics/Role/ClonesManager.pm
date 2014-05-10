package Perl6::Analytics::Role::ClonesManager;

use strict;
use warnings;

use Git::ClonesManager;

sub gcm_obj_extra_args {
	return {};
}

sub gcm_obj {
	my ( $self ) = @_;
	$self->{addons}{gcm_obj} = Git::ClonesManager->new(
		verbose_level => $self->{vl},
		%{ $self->gcm_obj_extra_args() }
	) unless $self->{addons}{gcm_obj};
	return $self->{addons}{gcm_obj};
}

sub git_repo_obj {
	my ( $self, $project_alias, %args ) = @_;
	return $self->gcm_obj->get_repo_obj( $project_alias, %args );
}

1;
