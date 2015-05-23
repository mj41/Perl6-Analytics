#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use lib '../Git-ClonesManager/lib';
use lib '../Git-Repository-LogRaw/lib';

use Perl6::Analytics::RoastData;


my $skip_fetch = $ARGV[0];
my $vl = $ARGV[1];

my $roastdata_obj = Perl6::Analytics::RoastData->new( verbose_level => $vl );
$roastdata_obj->process( skip_fetch => $skip_fetch );
$roastdata_obj->save_csv();
