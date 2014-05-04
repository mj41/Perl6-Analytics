#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use lib '../Git-ClonesManager/lib';
use lib '../Git-Repository-LogRaw/lib';
use lib '../Git-Analytics/lib';

use Perl6::Analytics::Commits;


my $skip_fetch = $ARGV[0];
my $vl = $ARGV[1];

my $features_obj = Perl6::Analytics::Commits->new( verbose_level => $vl );
$features_obj->process_and_save_csv( skip_fetch => $skip_fetch );
