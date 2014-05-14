#!/usr/bin/perl

# perl dev/dev-commits-refresh.pl 1 5 mu f68908d 100

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
my $alias = $ARGV[2];
my $rev_range = $ARGV[3];
my $number_limit = $ARGV[4];

my $features_obj = Perl6::Analytics::Commits->new( verbose_level => $vl );

system('rm -rf temp/dev-out-dir');
mkdir 'temp/dev-out-dir';
system('rm -rf temp/dev-cache-dir');
mkdir 'temp/dev-cache-dir';

my $git_log_args = {};
$git_log_args->{number_limit} = $number_limit if $number_limit;
$git_log_args->{rev_range} = $rev_range if $rev_range;

$features_obj->process_and_save_csv(
	skip_fetch => $skip_fetch,
	project_alias => $alias,
	data_out_dir => 'temp/dev-out-dir',
	data_cache_dir => 'temp/dev-cache-dir',
	git_log_args => $git_log_args,
);
