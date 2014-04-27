package Perl6::Analytics::Projects;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use JSON::InFile;
use Git::ClonesManager;

sub new {
	my ( $class, %args )= @_;
	my $self = {
		pr_info => {},
	};
	$self->{vl} = $args{verbose_level} // 3;
	bless $self, $class;
}

sub pr_info {
	my $self = shift;
	return $self->{pr_info};
}

sub projects_base_fpath {
	return 'data/projects-base.json';
}

sub projects_final_fpath {
	return 'data/projects-final.json';
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

sub load_base_list {
	my ( $self ) = @_;

	my $projects_db = JSON::InFile->new(fpath => $self->projects_base_fpath, verbose_level => $self->{vl});
	my $projects_info = $projects_db->load();

	# Normalize formating - saved only if changed.
	$projects_db->save($projects_info);

	return $projects_info;
}

sub gcm_obj {
	my ( $self ) = @_;
	$self->{gcm_obj} = Git::ClonesManager->new( verbose_level => $self->{vl} )
		unless $self->{gcm_obj};
	return $self->{gcm_obj};
}

sub git_repo_obj {
	my ( $self, $project_alias, %args ) = @_;
	return $self->gcm_obj->get_repo_obj( $project_alias, %args );
}

sub add_p6_modules {
	my ( $self ) = @_;
}

sub save_final {
	my ( $self ) = @_;

	my $final_pr_info = $self->projects_final_fpath;
	print "Saving final projects info to '$final_pr_info'.\n" if $self->{vl} >= 3;
	JSON::InFile->new(fpath => $final_pr_info, verbose_level => $vl)->save( $self->{pr_info} );
	return 1;
}

sub run {
	my ( $self, %args ) = @_;
	$args{do_update} //= 1;

	$self->{pr_info} = $self->load_base_list();
	$self->add_p6_modules();

	if ( $args{do_update} ) {
		$self->save_final();
	}
}

1;
