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
my $vl = $ARGV[1];

my $pr_obj = Perl6::Analytics::Projects->new( verbose_level => $vl );
$pr_obj->run( skip_fetch => $skip_fetch );

# debug
if ( $vl >= 10 ) {
	my $projects_struct = $pr_obj->all_projects_struct();
	require Data::Dumper;
	print Data::Dumper::Dumper( $projects_struct );
}
