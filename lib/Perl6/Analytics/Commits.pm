package Perl6::Analytics::Commits;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base qw(
	Perl6::Analytics::Base
	Perl6::Analytics::Role::ProjectsCache
	Perl6::Analytics::Role::ClonesManager
);

use Git::Analytics;
use Git::Repository::LogRaw;
use JSON::InFile;


sub data_out_dir {
    my ( $self, $val ) = @_;
    $self->{data_out_dir} = $val if defined $val;
    return $self->{data_out_dir} if exists $self->{data_out_dir};
    return 'data-out';
}

sub data_cache_dir {
    my ( $self, $val ) = @_;
    $self->{data_cache_dir} = $val if defined $val;
    return $self->{data_cache_dir} if exists $self->{data_cache_dir};
    return 'data-cache';
}

sub prepare_dirs {
	my ( $self ) = @_;

	foreach my $dir ( 'data-out', 'data-cache', 'data-cache/git-analytics-state' ) {
		next if -d $dir;
		mkdir( $dir ) || croak "Can't create directory '$dir': $!\n";
	}
}

sub get_to_sub_project_tr_closure {
	my ( $self, $project_alias, $project_name ) = @_;

	if ( $project_alias eq 'mu' ) {
		return sub {
			my ( $fpath, $dir_l1, $dir_l2, $fname ) = @_;
			# moved
			return 'p5-modules'   if $fpath =~ m{^perl5/};
			return 'Pugs.hs'      if $fpath =~ m{^pugs/};
			return 'roast'        if $fpath =~ m{^spectests/};
			return 'roast'        if $fpath =~ m{^t/spec/};
			return 'specs'        if $fpath =~ m{^docs/Perl6/Spec/};
			return 'perl6.org'    if $fpath =~ m{^docs/feather/perl6.org/};
			return 'p5-modules'   if $fpath =~ m{^perl5/};
			return 'evalbot'      if $fpath =~ m{^misc/evalbot/};
			# others
			return 'Pugs.hs'      if $fpath =~ m{^src/Pugs/};
			return 'perl6advent'  if $fpath =~ m{^misc/perl6advent\-\d*/};
			return 'pugscode.org' if $fpath =~ m{^docs/feather/pugscode.org};
			return 'v6-MiniPerl6' if $fpath =~ m{^v6/v6-MiniPerl6};
			return 'tests'        if $fpath =~ m{^t/};
			return 'tests'        if $fpath =~ m{^tests?/};
			return 'docs'         if $fpath =~ m{^docs?/};
			return 'readme'       if $fpath =~ m{^readme\.}i;
			# not known sub-project
			return $project_name unless $dir_l1;
			return $dir_l1 unless $dir_l2;
			return $dir_l2;
		}
	}

	return undef;
}

sub repo_emails_fpath {
	my ( $self, $base_fname ) = @_;
	return File::Spec->catfile( 'data', 'emails', $base_fname.'.json' );
}

sub load_repo_emails_tr {
	my ( $self, $project_alias, $base_fname ) = @_;
	$base_fname //= $project_alias;

	$self->{repo_emails_tr} = {};
	$self->{repo_emails_tr}{fpath} = $self->repo_emails_fpath( $base_fname );
	if ( -e $self->{repo_emails_tr}{fpath} ) {
		my $projects_db = JSON::InFile->new(
			fpath => $self->{repo_emails_tr}{fpath},
			verbose_level => $self->{vl}
		);
		$self->{repo_emails_tr}{data} = $projects_db->load();
	} else {
		$self->{repo_emails_tr}{data} = {};
	}
	return $self->{repo_emails_tr}{data};
}

sub one_project_finished {
	my ( $self, $project_alias, $project_name ) = @_;

	if ( defined $self->{repo_emails_tr} ) {
		my $projects_db = JSON::InFile->new(
			fpath => $self->{repo_emails_tr}{fpath},
			verbose_level => $self->{vl}
		);
		$projects_db->save( $self->{repo_emails_tr}{data} );
		delete $self->{repo_emails_tr};
	}
}

sub get_author_committer_tr_closure {
	my ( $self, $project_alias, $project_name ) = @_;

	my $repo_emails_tr_data = $self->load_repo_emails_tr(
		$project_alias,
		'common-emtr'
	);
	return sub {
		my ( $a_name, $a_email, $c_name, $c_email ) = @_;
		# author
		if ( exists $repo_emails_tr_data->{$a_email} ) {
			( $a_email, $a_name ) = @{ $repo_emails_tr_data->{$a_email} };
			$a_name = $repo_emails_tr_data->{$a_email}[1] unless $a_name;
		} else {
			$repo_emails_tr_data->{$a_email} = [
				$a_email, $a_name
			];
		}
		$a_name = $a_email unless $a_name;

		# committer
		if ( exists $repo_emails_tr_data->{$c_email} ) {
			( $c_email, $c_name ) = @{ $repo_emails_tr_data->{$c_email} };
			$c_name = $repo_emails_tr_data->{$c_email}[1] unless $c_name;
		} else {
			$repo_emails_tr_data->{$c_email} = [
				$c_email, $c_name
			];
		}
		$c_name = $c_email unless $c_name;

		return ( $a_name, $a_email, $c_name, $c_email );
	}
}

sub process_and_save_csv {
	my ( $self, %args ) = @_;
	my $skip_fetch = $args{skip_fetch} // 0;

	my $projects = $self->projects_obj->all_projects_struct();
	# Only one selected.
	if ( $args{project_alias} ) {
		my $project_alias = $args{project_alias};
		croak "Project with alias '$project_alias' not found.\n"
			unless exists $projects->{$project_alias};
		my $one_info = delete $projects->{$project_alias};
		$projects = {
			$project_alias => $one_info,
		};
	}

	$self->prepare_dirs();

	my $ga_obj = Git::Analytics->new(
		verbose_level => $self->{vl},
		also_commits_files => 1,
		data_cache_dir => $self->data_cache_dir,
	);
	$ga_obj->open_out_csv_files(
		File::Spec->catfile( $self->data_out_dir, 'commits.csv' ),
		File::Spec->catfile( $self->data_out_dir, 'commits_files.csv' ),
	);
	$ga_obj->print_csv_headers();

	my $git_log_args_base = $args{git_log_args} // {};

	my $num = 1;
	foreach my $project_alias ( sort keys %$projects ) {
		if ( $args{skip} ) {
			print "Skipping project '$project_alias' - flag 'skip' is set.\n" if $self->{vl} >= 4;
			return 0;
		}

		my $branch = $projects->{$project_alias}{branch} // 'master';
		my $base_repo_obj = $self->git_repo_obj(
			$project_alias,
			repo_url => $projects->{$project_alias}{source_url},
			skip_fetch => $skip_fetch,
		);

		my $project_name = $projects->{$project_alias}{name};
		my $git_lograw_obj = Git::Repository::LogRaw->new( $base_repo_obj, $self->{vl} );
		$ga_obj->process_one(
			$project_alias,
			$project_name,
			$git_lograw_obj,
			to_sub_project_tr_closure => $self->get_to_sub_project_tr_closure( $project_alias, $project_name ),
			author_committer_tr_closure => $self->get_author_committer_tr_closure( $project_alias, $project_name ),
			git_log_args => {
				( %$git_log_args_base, reverse => 1 ),
				branch => $branch,
			},
		);
		$self->one_project_finished( $project_alias, $project_name );
		$num++;
	}

	$ga_obj->close_csv_files();
	return 1;
}

1;
