package Perl6::Features;

use strict;
use warnings;


sub arrayify {
    my ($r, $key) = @_;
    if (defined $r && ref($r) eq 'ARRAY') {
        return [ map { { $key => $_ } } @{$r} ];
    }
    if ($r) {
        return [ { $key => $r } ];
    }
    [ ];
}

sub process {
	my $data = shift;

	# place the column numbers for each compiler into %comp_index
	my %comp_index;
	my $comp_count = 0;
	for my $c (@{$data->{'COMPILERS'}}) {
		$comp_index{$c->{'abbr'}} = $comp_count++;
	}

	# walk through all of the items, filling in @ratings for each item
	# and populating footnotes
	my %footnotes;
	my $foot_count;
	my %rating_class = (
		'+'  => 'implemented',
		'-'  => 'missing',
		'+-' => 'partial',
		'?'  => 'unknown',
	);
	my %rating_text = ( '+-' => "\N{U+00B1}", '-' => "\N{U+2212}" );
	for my $sec (@{$data->{'sections'}}) {
		for my $item (@{$sec->{'items'}}) {
			my $status = $item->{'status'};
			my @ratings;
			while ($status =~ m/(\w+)([+-]+)\s*(?:\(([^()]+)\))?/g) {
				my ($abbr, $rating, $comment) = ($1, $2, $3);
				die "Unknown abbreviation '$abbr'"
					unless exists $comp_index{$abbr};
				my $r = {
					status => $rating_text{$rating} // $rating,
					class  => $rating_class{$rating},
				};
				if ($comment) {
					$footnotes{$comment} //= ++$foot_count;
					$r->{footnote} = $footnotes{$comment};
					$r->{foottext} = $comment;
				}
				$ratings[$comp_index{$abbr}] = $r;
			}
			for (0..($comp_count-1)) {
				$ratings[$_] //= { status => '?', class => 'unknown' } # / todo
			}
			$item->{'ratings'} = \@ratings;
			$item->{'code'} = arrayify($item->{'code'}, 'code');
			$item->{'spec'} = arrayify($item->{'spec'}, 'spec');
		}
	}
}

1;
