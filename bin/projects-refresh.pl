#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use lib 'lib';
# Temporary paths (not released to CPAN yet). Clone them from GitHub.
use lib '../JSON-InFile/lib';
use JSON::InFile;

my $projects_base_fpath = 'data/projects-base.json';

my $do_update = $ARGV[0];
my $vl = $ARGV[1];

my $projects_db = JSON::InFile->new(fpath => $projects_base_fpath, verbose_level => $vl);
my $projects_info = $projects_db->load();
$projects_db->save($projects_info); # normalize formating
