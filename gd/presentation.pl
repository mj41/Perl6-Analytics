
use GDC::RCheck::Pruit;

$s->login();
$s->get_or_create_project(
	title => $s->get_cfg('project_name') || die "No project name provided.",
	token => $s->get_cfg('token') || undef,
	driver => $s->get_cfg('driver') || 'Pg',
);

my $gdc_title_prefix = $s->get_cfg('gdc_title_prefix')
	|| die "Dashboard prefix not provided (use --co 'gdc_title_prefix=PREF').";

my $dash_objs = $s->get_obj_contents_by( type => 'dashboard', title => qr/^\Q$gdc_title_prefix\E/ );
#$s->dump_struct('dashs', $dash_objs );

my $dashs_info = [];
foreach my $dash_obj ( @$dash_objs ) {

	# tabs
	my $tab_objs = $dash_obj->{projectDashboard}{content}{tabs};
	my $tabs = [];
	foreach my $tab_obj ( @$tab_objs ) {
		push @$tabs, {
			identifier => $tab_obj->{identifier},
			title => $tab_obj->{title},
		};
	}

	my $meta = $dash_obj->{projectDashboard}{meta};
	push @$dashs_info, {
		identifier => $meta->{title},
		uri => $meta->{uri},
		title => $meta->{title},
		tabs => $tabs,
	};
};

$s->dump_struct('dashs info', $dashs_info );

my $dr = get_dr( $s );
$dr->get( $s->api_url );

my $dash_num = 0;
foreach my $dashi ( sort { $a->{title} cmp $b->{title} } @$dashs_info ) {
	$dash_num++;

	my $tab_num = 0;
	foreach my $tab ( @{ $dashi->{tabs} } ) {
		$tab_num++;
		# next unless $tab_num == 7 && $dash_num == 3; # debug

		my $fname = sprintf( 'pres-d%02dt%02d.png', $dash_num, $tab_num );
		print "Taking screenshot of dasboard '$dashi->{title}' and tab '$tab->{title}' to '$fname'.\n";

		$dr->get(
			$s->embeded_dashboard_url(
				uri => $dashi->{uri},
				tab_identifier => $tab->{identifier},
			)
		);

		wait_till_loading($dr, 120);
		sleep 2;
		wait_till_computing($dr,100);

		my $els = $dr->find_elements('s-btn-show_anyway','class');
		if ( $els && scalar @$els ) {
			print "Too many data -> show anyway click.\n";
			gdc_click( $dr, 'class', 's-btn-show_anyway' );
			wait_till_computing($dr,100);
		};

		my $fpath = $s->script_rel_fpath('..','temp','presentation',$fname);
		print "Screenshot: '$fpath'\n";
		screenshot( $dr, $fpath );
	}
}

$dr->quit();
