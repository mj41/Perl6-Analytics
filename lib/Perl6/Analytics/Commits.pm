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
			return 'std'          if $fpath =~ m{^src/perl6/};
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
	);
	$ga_obj->open_out_csv_files(
		'data-out/commits.csv',
		'data-out/commits_files.csv'
	);
	$ga_obj->print_csv_headers();

	my $num = 1;
	foreach my $project_alias ( sort keys %$projects ) {
		if ( $args{skip} ) {
			print "Skipping project '$project_alias' - flag 'skip' is set.\n" if $self->{vl} >= 4;
			return 0;
		}

		my $repo_url = $projects->{$project_alias}{source_url};
		my $project_name = $projects->{$project_alias}{name};
		my $base_repo_obj = $self->git_repo_obj(
			$project_alias,
			repo_url => $repo_url,
			skip_fetch => $skip_fetch,
		);
		my $git_lograw_obj = Git::Repository::LogRaw->new( $base_repo_obj, $self->{vl} );
		$ga_obj->process_one(
			$project_alias,
			$project_name,
			$git_lograw_obj,
			to_sub_project_tr_closure => $self->get_to_sub_project_tr_closure( $project_alias, $project_name ),
		);
		$num++;
	}

	$ga_obj->close_csv_files();
	return 1;
}

1;
