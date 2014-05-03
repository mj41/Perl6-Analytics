package Perl6::Analytics::Features;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base qw(
	Perl6::Analytics::Base
	Perl6::Analytics::Role::JSON
	Perl6::Analytics::Role::ProjectsCache
	Perl6::Analytics::Role::ClonesManager
);

use JSON::InFile;
use Perl6::Features;
use Text::CSV_XS;
use Git::Repository::LogRaw;


sub process {
	my ( $self, %args ) = @_;
	my $skip_fetch = $args{skip_fetch} // 0;

	my $features_alias = 'features';
	my $features_repo_url = $self->projects_obj->project_source_url( $features_alias );
	my $features_fpath = 'features.json';

	my $repo_obj = $self->git_repo_obj(
		$features_alias,
		repo_url => $features_repo_url,
		skip_fetch => $skip_fetch
	);

	my $features_json = $repo_obj->run('show', 'HEAD:'.$features_fpath );
	my $data = $self->json_obj->decode($features_json);
	$self->dump( 'features raw', $data ) if $self->{vl} >= 9;

	Perl6::Features::process( $data );
	$self->dump( 'features processed', $data ) if $self->{vl} >= 9;

	$self->{data} = $data;

	my $gitlog_obj = Git::Repository::LogRaw->new( $repo_obj, $self->{vl} );
	my $log = $gitlog_obj->get_log( undef, number_limit => 1, fpath => $features_fpath );
	$self->dump( 'features meta', $log ) if $self->{vl} >= 9;

	my $commit = $log->[0]{commit};
	my $commiter_gmtime = $log->[0]{committer}{gmtime};
	my $commiter_gmtime_str = gmtime( $commiter_gmtime );
	my $features_url = 'https://github.com/perl6/features/blob/'.$commit.'/'.$features_fpath;
	my $meta = {
		commit => $commit,
		commiter_gmtime => $commiter_gmtime,
		commiter_gmtime_str => $commiter_gmtime_str,
		url => $features_url,
	};

	my $features_meta_json_fpath = 'data-out/features-meta.json';
	my $features_meta_json_obj = JSON::InFile->new(
		fpath => $features_meta_json_fpath, verbose_level => $self->{vl}
	);
	$features_meta_json_obj->save( $meta );
	return 1;
}

sub save_csv {
	my ( $self ) = @_;

	my $fpath = "data-out/features.csv";

	open( my $fh, ">:encoding(utf8)", $fpath )
		or croak "Open '$fpath' for write failed: $!";

	my $csv = Text::CSV_XS->new();
	$csv->eol("\n");

	my @head_row = qw/ project_flavour section item state fact /;

	$csv->print( $fh, \@head_row );
	my $increment = 1;
	foreach my $section ( @{ $self->{data}{sections} } ) {
		my $section_name = $section->{section};
		foreach my $item ( @{ $section->{items} } ) {
			my $item_name = $item->{item};
			my $ratings = $item->{ratings};
			foreach my $rating_num ( 0..$#$ratings ) {
				my $rating_class = $ratings->[ $rating_num ]{class};
				my $compiler = $self->{data}{COMPILERS}[ $rating_num ]{name};
				$csv->print( $fh, [ $compiler, $section_name, $item_name, $rating_class, '1' ] );
				$increment++;
			}
		}
	}

	close($fh) or croak "Write to '$fpath' failed: $!";
}


1;
