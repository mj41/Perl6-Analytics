package Perl6::Analytics::Projects;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base qw(
	Perl6::Analytics::Base
	Perl6::Analytics::Role::JSON
	Perl6::Analytics::Role::ClonesManager
);

use JSON::XS;
use JSON::InFile;
use Text::CSV_XS;

sub new {
	my ( $class, %args )= @_;
	my $self = {
		pr_info => {},
	};
	$self->{vl} = $args{verbose_level} // 3;
	bless $self, $class;
}

sub all_projects_struct {
	my $self = shift;
	return $self->{pr_info};
}

sub project_struct {
	my ( $self, $project_alias ) = @_;
	return undef unless exists $self->{pr_info}{$project_alias};
	return $self->{pr_info}{$project_alias};
}

sub project_source_url {
	my ( $self, $project_alias ) = @_;
	my $struct = $self->project_struct( $project_alias );
	return undef unless defined $struct;
	return undef unless exists $struct->{source_url};
	return $struct->{source_url};
}

sub projects_base_fpath {
	return 'data/projects-base.json';
}

sub projects_final_fpath {
	return 'data/projects-final.json';
}

sub load_from_cache {
	my ( $self ) = @_;
	my $fpath = $self->projects_final_fpath;
	croak "Cache database '$fpath' not found.\n" unless -f $fpath;
	my $projects_db = JSON::InFile->new(fpath => $fpath, verbose_level => $self->{vl});
	$self->{pr_info} = $projects_db->load();
	return 1;
}

sub load_base_list {
	my ( $self ) = @_;

	my $projects_db = JSON::InFile->new(fpath => $self->projects_base_fpath, verbose_level => $self->{vl});
	my $projects_info = $projects_db->load();

	# Normalize formating - saved only if changed.
	$projects_db->save($projects_info);

	return $projects_info;
}

sub add_p6_modules {
	my ( $self, %args ) = @_;
	my $skip_fetch = $args{skip_fetch} // 0;

	my $ecos_alias = 'ecosystem';
	my $ecos_fpath = 'META.list';

	croak "Repository with alias '$ecos_alias' not defined.\n"
		unless $self->{pr_info}{$ecos_alias};

	my $ecos_repo_url = $self->{pr_info}{$ecos_alias}{source_url};

	my $repo = $self->git_repo_obj($ecos_alias, repo_url => $ecos_repo_url, skip_fetch => $skip_fetch );
	my @modules_meta_urls = $repo->run('show', 'HEAD:'.$ecos_fpath );

	my $mod_base_info = [];
	my $url_prefix = 'https://raw2.github.com';
	foreach my $meta_url ( @modules_meta_urls ) {
		if (
			my (                  $author,  $repo_name, $branch, $meta_fpath ) = $meta_url =~ m{^
				\Q$url_prefix\E / ([^/]+) / ([^/]+) /   ([^/]+) / (.*)
			$}x
		) {
			push @$mod_base_info, {
				author => $author,
				repo_name => $repo_name,
				branch => $branch,
				meta_fpath => $meta_fpath,
			};
		} else {
			croak "Can't parse module meta file url '$meta_url'.\n";
		}
	}
	$self->dump('modules info parsed from ecosystem list', $mod_base_info ) if $self->{vl} >= 8;

	my $json_obj = $self->json_obj;

	# ToDo - move to data/projects-skip.json
	my $skip_list = {
		'ajs/perl6-log' => 1,
	};
	my $mods_info = {};
	foreach my $mi ( @$mod_base_info ) {
		my $str_id = $mi->{author} . '/' . $mi->{repo_name};
		if ( $skip_list->{$str_id} ) {
			print "Skipping '$str_id' as module is on skip list.\n" if $self->{vl} >= 4;
			next;
		}
		print "Processing meta file for '$str_id'.\n" if $self->{vl} >= 5;

		my $repo_url = sprintf('git://github.com/%s/%s.git', $mi->{author}, $mi->{repo_name} );
		my $repo_obj = $self->git_repo_obj(
			$mi->{repo_name},
			repo_url => $repo_url,
			skip_fetch => $skip_fetch
		);
		my $meta = $repo_obj->run('show', $mi->{branch}.':'.$mi->{meta_fpath} );
		print "Meta file for '$str_id':\n$meta\n" if $self->{vl} >= 9;

		my $data = eval { $json_obj->decode( $meta ) };
		if ( my $err = $@ ) {
			print "Decoding meta failed: $@\n" if $self->{vl} >= 2;
		}
		$self->dump('meta for '.$str_id, $data ) if $self->{vl} >= 8;

		my $real_repo_url = $data->{'source-url'} // $data->{'repo-url'};
		unless ( $real_repo_url ) {
			croak "'source-url' nor 'repo-url' found for '$str_id'.\n";
			next;
		}

		my $real_repo_name;
		unless ( ($real_repo_name) = $real_repo_url =~ m{([^/]+)\.git$}x ) {
			croak "Can't parse source url '$real_repo_url'\n";
			next;
		}

		if ( exists $mods_info->{$real_repo_name} ) {
			croak "Duplicate repo name '$real_repo_name' found for '$str_id'.\n";
			next;
		}
		$mods_info->{$real_repo_name} = {
			name => $data->{name},
			description => $data->{description},
			source_url => $real_repo_url,
			type => 'module',
		};
	}
	$self->dump('modules info', $mods_info ) if $self->{vl} >= 8;

	foreach my $repo_name ( keys %$mods_info ) {
		if ( exists $self->{pr_info}{$repo_name} ) {
			croak "Duplicate repo name 'repo_name'.\n";
			next;
		}
		$self->{pr_info}{$repo_name} = $mods_info->{$repo_name};
	}
}

sub save_final {
	my ( $self ) = @_;

	my $final_pr_info = $self->projects_final_fpath;
	print "Saving final projects info to '$final_pr_info'.\n" if $self->{vl} >= 3;
	JSON::InFile->new(fpath => $final_pr_info, verbose_level => $self->{vl})->save( $self->{pr_info} );
	return 1;
}

sub process {
	my ( $self, %args ) = @_;
	$args{do_update} //= 1;

	$self->{pr_info} = $self->load_base_list();
	$self->add_p6_modules( %args );

	if ( $args{do_update} ) {
		$self->save_final();
	}
}

sub save_csv {
	my ( $self ) = @_;

	my $fpath = "data-out/projects.csv";

	open( my $fh, ">:encoding(utf8)", $fpath )
		or croak "Open '$fpath' for write failed: $!";

	my $csv = Text::CSV_XS->new();
	$csv->eol("\n");

	my @head_row = qw/ name url source_url type flavour /;
	$csv->print( $fh, \@head_row );
	foreach my $alias ( keys %{ $self->{pr_info} } ) {
		my $data = $self->{pr_info}{$alias};
		my $name = $data->{name};

		my $flavours = $data->{flavours};
		$flavours = [ "$name" ] unless $flavours;
		foreach my $flavour ( @$flavours ) {
			$csv->print( $fh, [
				$name,
				$data->{url},
				$data->{source_url},
				$data->{type},
				$flavour
			] );
		}
	}

	close($fh) or croak "Write to '$fpath' failed: $!";
}

1;
