#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use lib '../Git-ClonesManager/lib';

use Perl6::Analytics::Projects;


my $skip_fetch = $ARGV[0];
my $skip_process = $ARGV[1];
my $vl = $ARGV[2];

my $pr_obj = Perl6::Analytics::Projects->new( verbose_level => $vl );
if ( $skip_process ) {
	$pr_obj->load_from_cache();
} else {
	$pr_obj->process( skip_fetch => $skip_fetch );
}
$pr_obj->save_csv();

# debug
if ( $vl >= 10 ) {
	my $projects_struct = $pr_obj->all_projects_struct();
	require Data::Dumper;
	print Data::Dumper::Dumper( $projects_struct );
}
