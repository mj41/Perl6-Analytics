#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use lib '../Git-ClonesManager/lib';
use lib '../Git-Repository-LogRaw/lib';

use Perl6::Analytics::Features;


my $skip_fetch = $ARGV[0];
my $vl = $ARGV[1];

my $features_obj = Perl6::Analytics::Features->new( verbose_level => $vl );
$features_obj->process( skip_fetch => $skip_fetch );
$features_obj->save_csv();
