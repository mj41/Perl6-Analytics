#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use lib '../Git-ClonesManager/lib';

use Perl6::Analytics::Projects;


my $do_update = $ARGV[0];
my $vl = $ARGV[1];

my $pr_obj = Perl6::Analytics::Projects->new( verbose_level => $vl );
$pr_obj->run();

# debug
if ( $vl >= 8 ) {
	my $pr_info = $pr_obj->pr_info();
	require Data::Dumper;
	print Data::Dumper::Dumper( $pr_info );
}
