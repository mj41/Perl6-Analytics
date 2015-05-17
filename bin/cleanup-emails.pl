#!/usr/bin/env perl

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

my $commits_obj = Perl6::Analytics::Commits->new( verbose_level => $vl );
my $emails = $commits_obj->load_repo_emails_tr( undef, 'common-emtr' );
$commits_obj->dump( 'emails', $emails );

sub cmp_str {
    my ( $str ) = @_;
    my $norm_str = lc $str;
    $norm_str =~ s/\s+[a-zA-Z]\.?\s+/ /g;
    $norm_str =~ s/\s+[a-zA-Z]\.?$//g;
    $norm_str =~ s/^[a-zA-Z]\.?\s+//g;
    $norm_str =~ s{\([^\)\(]+\)}{}g;
    $norm_str =~ s/[^a-zA-Z0-9 ]//g;
    return $norm_str;
}

my $name_to_email;
print "Sorted by lowercase email:\n";
foreach my $email ( sort { cmp_str($a) cmp cmp_str($b) } keys %$emails ) {
    my ( $norm_email, $name ) = @{$emails->{$email}};
    if ( $norm_email eq $email ) {
        $name_to_email->{$name} = $email;
    } else {
        $name = $emails->{$norm_email}[1];
        next;
    }
    my $cmp_email = cmp_str( $email ); 
    print qq/"$email" "$norm_email" "$name" (cmp_email: "$cmp_email")\n/;
}
print "\n";

print "Sorted by lowercase names:\n";
foreach my $name( sort { cmp_str($a) cmp cmp_str($b) } keys %$name_to_email ) {
    my $email = $name_to_email->{$name};
    my $cmp_name = cmp_str( $name ); 
    print qq/"$name" "$email" (cmd_name: "$cmp_name")\n/;

}
print "\n";
