
use GDC::RCheck::Pruit;

my $dash_identifier = 'abv26SHOaI4O';

$s->login();
$s->get_or_create_project(
	title => $s->get_cfg('project_name') || die "No project name provided.",
	token => $s->get_cfg('token') || undef,
	driver => $s->get_cfg('driver') || 'Pg',
);

my $dr = get_dr( $s );
$dr->get( $s->api_url );
$dr->get( $s->embeded_dashboard_url( identifier => $dash_identifier ) );
sleep 10;

my $fpath = $s->script_rep_fpath("../../Perl-6-GD/export/Summary - Compilers' features - GoodData.png");
print "Screenshot: '$fpath'\n";
screenshot( $dr, $fpath );
$dr->quit();
