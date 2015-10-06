package Perl6::Analytics::RoastData;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base qw(
	Perl6::Analytics::Base
	Perl6::Analytics::Role::ProjectsCache
	Perl6::Analytics::Role::ClonesManager
);

use Text::CSV_XS;
use Git::Repository::LogRaw;

sub csv_error {
	my ( $self, $csv_obj ) = @_;
	croak "CSV parsing failed: ".$csv_obj->error_diag."\non argument: ".$csv_obj->error_input."\n";
}

sub parse_csv {
	my ( $self, $csv_str ) = @_;

	my $csv_obj = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

	my @lines = split /\n/, $csv_str;
	my $header_line = shift @lines;
	my $status = $csv_obj->parse($header_line);
	$self->csv_error( $csv_obj ) unless $status;
	my $header = [ $csv_obj->fields() ];

	my $rows;
	while ( my $line = shift @lines ) {
		my $status = $csv_obj->parse($line);
		$self->csv_error( $csv_obj ) unless $status;
		my $row = [ $csv_obj->fields() ];
		push @$rows, $row;
	}
	return ( $header, $rows );
}

sub get_all_sha1 {
	my ( $self, $project_alias, $source_url ) = @_;

	my $base_repo_obj = $self->git_repo_obj(
		$project_alias,
		repo_url => $source_url,
		skip_fetch => 1,
	);
	my $git_lograw_obj = Git::Repository::LogRaw->new( $base_repo_obj, $self->{vl} );
	return $git_lograw_obj->get_all_sha1();
}

sub add_to_short_to_full_map {
	my ( $self, $map, $sha1s, @data ) = @_;
	foreach my $sha1 ( @$sha1s ) {
		next unless $sha1;
		my ( $ch1_5, $ch6, $ch7, $ch8, $ch9, $ch10 ) = $sha1 =~ /^(.{5})(.)(.)(.)(.)(.)/;
		if ( exists $map->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}{$ch10} ) {
			croak "Duplication found $ch1_5, $ch6, $ch7, $ch8, $ch9, $ch10";
		}
		croak "$sha1 error: $ch1_5, $ch6, $ch7, $ch8, $ch9, $ch10" unless defined $ch10;
		$map->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}{$ch10} = [ $sha1, @data ];
	}
}

sub find_full_sha1 {
	my ( $self, $short2full, $short_sha1 ) = @_;

	my $len = length($short_sha1);
	croak "Minimum sha1 length is 5 characters but string '$short_sha1' provided." if $len < 5;

	my ( $ch1_5, $ch6, $ch7, $ch8, $ch9, $ch10 ) = $short_sha1 =~ /^(.....)(.?)(.?)(.?)(.?)(.?)/;

	if ( $len >= 5 ) {
		croak "No $ch1_5 (5 chars)"
			unless exists $short2full->{$ch1_5};
	}
	if ( $len == 5 ) {
		croak "To many for 5 characters $ch1_5*: ".$self->dump('data',$short2full->{$ch1_5})
			if keys %{$short2full->{$ch1_5}} > 1;
		$ch6 = (keys %{$short2full->{$ch1_5}})[0];
		$len = 6;
	}

	if ( $len >= 6 ) {
		croak "No $ch1_5$ch6 (6 chars)"
			unless exists $short2full->{$ch1_5}{$ch6};
	}
	if ( $len == 6 ) {
		croak "To many for 6 characters $ch1_5$ch6*: ".$self->dump('data',$short2full->{$ch1_5}{$ch6})
			if keys %{$short2full->{$ch1_5}{$ch6}} > 1;
		$ch7 = (keys %{$short2full->{$ch1_5}{$ch6}})[0];
		$len = 7;
	}

	if ( $len >= 7 ) {
		croak "No $ch1_5$ch6$ch7 (7 chars)"
			unless exists $short2full->{$ch1_5}{$ch6}{$ch7};
	}
	if ( $len == 7 ) {
		croak "To many for 7 characters $ch1_5$ch6$ch7*: ".$self->dump('data',$short2full->{$ch1_5}{$ch6}{$ch7})
			if keys %{$short2full->{$ch1_5}{$ch6}{$ch7}} > 1;
		$ch8 = (keys %{$short2full->{$ch1_5}{$ch6}{$ch7}})[0];
		$len = 8;
	}

	if ( $len >= 8 ) {
		croak "No $ch1_5$ch6$ch7$ch8 (8 chars)"
			unless exists $short2full->{$ch1_5}{$ch6}{$ch7}{$ch8};
	}
	if ( $len == 8 ) {
		croak "To many for 8 characters $ch1_5$ch6$ch7$ch8*: ".$self->dump('data',$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8})
			if keys %{$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}} > 1;
		$ch9 = (keys %{$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}})[0];
		$len = 9;
	}

	if ( $len >= 9 ) {
		croak "No $ch1_5$ch6$ch7$ch8$ch9"
			unless exists $short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9};
	}
	if ( $len == 9 ) {
		croak "To many for 9 characters $ch1_5$ch6$ch7$ch8$ch9*: ".$self->dump('data',$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9})
			if keys %{$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}} > 1;
		$ch10 = (keys %{$short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}})[0];
		$len = 10;
	}

	if ( $len >= 10 ) {
		croak "No $ch1_5$ch6$ch7$ch8$ch9$ch10"
			unless exists $short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}{$ch10};
	}

	return @{ $short2full->{$ch1_5}{$ch6}{$ch7}{$ch8}{$ch9}{$ch10} };
}

sub get_short_to_full_sha1 {
	my ( $self, $projects, @aliases ) = @_;

	my $map = {};
	foreach my $project_alias ( @aliases ) {
		my $source_url = $projects->{$project_alias}{source_url};
		my ( @sha1s ) = $self->get_all_sha1( $project_alias, $source_url );
		$self->dump( 'sha1s', \@sha1s ) if $self->{vl} >= 10;
		$self->add_to_short_to_full_map( $map, \@sha1s, $project_alias );
	}
	return $map;
}

sub impl_aliases {
	return 'rakudo', 'niecza', 'mu', 'pugs.hs';
}

sub process {
	my ( $self, %args ) = @_;
	my $skip_fetch = $args{skip_fetch} // 0;

	my $roastdata_alias = 'roast-data';
	my $roastdata_repo_url = $self->projects_obj->project_source_url( $roastdata_alias );
	my $roastdata_fpath = 'perl6_pass_rates.csv';

	my $repo_obj = $self->git_repo_obj(
		$roastdata_alias,
		repo_url => $roastdata_repo_url,
		skip_fetch => $skip_fetch
	);

	my $roastdata_csv = $repo_obj->run('show', 'HEAD:'.$roastdata_fpath );
	my ( $header, $raw_data ) = $self->parse_csv( $roastdata_csv );
	$self->dump( 'roast-data header', $header ) if $self->{vl} >= 9;
	$self->dump( 'roast-data raw data', $raw_data ) if $self->{vl} >= 9;

	my $projects = $self->projects_obj->all_projects_struct();

	my $short2full_roast = $self->get_short_to_full_sha1( $projects, 'roast' );
	$self->dump( 'short2full_roast', $short2full_roast ) if $self->{vl} >= 9;
	my $short2full_impl = $self->get_short_to_full_sha1( $projects, $self->impl_aliases );
	$self->dump( 'short2full_impl', $short2full_impl ) if $self->{vl} >= 9;

	# todo
	my $sha1_roast_fallback = {};
	my $sha1_impl_fallback = {};

	my $clean_flavour = {
		'rakudo.jvm' => 'Rakudo JVM',
		'rakudo.moar' => 'Rakudo MoarVM',
		'rakudo.moar-jit' => 'Rakudo MoarVM',
		'rakudo.moar-glr' => 'Rakudo MoarVM GLR',
		'rakudo.parrot' => 'Rakudo Parrot',
		'niecza' => 'Niecza',
		'pugs' => 'Pugs.hs',
	};

	foreach my $row ( @$raw_data ) {
		my $flavour_raw = $row->[0];
		if ( not exists $clean_flavour->{$flavour_raw} ) {
			croak "Unknown project flavour: $flavour_raw\n";
		} elsif ( not defined $clean_flavour->{$flavour_raw} ) {
			next;
		}
		my $flavour = $clean_flavour->{$flavour_raw};

		my $short_roast_sha1 = $row->[3]; # roast sha1
		my $short_impl_sha1 = $row->[10]; # impl sha1
		my ( $roast_sha1 ) = ( $short_roast_sha1 )
				? $self->find_full_sha1( $short2full_roast, $short_roast_sha1 )
				: $sha1_roast_fallback->{$row->[0]}{$row->[1]} || ''; # && croak "Fall back for roast not found.";
		;
		my ( $impl_sha1, $project ) = ( $short_impl_sha1 )
				? $self->find_full_sha1( $short2full_impl, $short_impl_sha1 )
				: $sha1_impl_fallback->{$row->[0]}{$row->[1]} || ''; # croak "Fall back for impl not found.";
		;
		push @{$self->{data}}, [
			$flavour,     # Impl - project_flavour
			$row->[1],    # date
			#$row->[2],   # percentage
			#$roast_sha1, # roast sha1 - roast_sha1
			$row->[4],    # pass
			$row->[5],    # fail
			$row->[6],    # todo
			$row->[7],    # skip
			$row->[8],    # plan
			$row->[9],    # spec
			$impl_sha1,   # impl sha1 - impl_sha1
			#$row->[11],  # notes
		];
	}
	return 1;
}

sub save_csv {
	my ( $self ) = @_;

	my $fpath = "data-out/roastdata.csv";

	open( my $fh, ">:encoding(utf8)", $fpath )
		or croak "Open '$fpath' for write failed: $!";

	my $csv = Text::CSV_XS->new();
	$csv->eol("\n");

	my @head_row = qw/ project_flavour date pass fail todo skip plan spec impl_sha1 /;
	$csv->print( $fh, \@head_row );
	foreach my $row ( @{ $self->{data} } ) {
		$csv->print( $fh, $row );
	}
	close($fh) or croak "Write to '$fpath' failed: $!";
}

1;
