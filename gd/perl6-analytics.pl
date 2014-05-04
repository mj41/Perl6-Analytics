# Create project, run maql and upload data.

my $datanames = [ qw(
	projects
	commits
	features
)];
my $dash_identifier = 'abv26SHOaI4O';

$s->login();
$s->get_or_create_project(
	title => $s->get_cfg('project_name') || die "No project name provided.",
	token => $s->get_cfg('token') || undef,
	driver => $s->get_cfg('driver') || 'Pg',
);

# maql
$s->run_maql_for_dataset(
	dataset => $datanames,
	maql_dir => $s->script_rel_fpath('data-def'),
);

# delete all data
if (0) {
	my $maql = '';
	foreach my $ds_base_name ( sort @$datanames ) {
		$maql .= "\n" if $maql;
		$maql .= sprintf( 'SYNCHRONIZE {%s};', 'dataset.'.$ds_base_name );
	}
	my $res = $s->run_maql($maql);
}

# projects
if (1) {
	$s->dataset_upload(
		dataset => $datanames->[0],
		manifest_dir => $s->script_rel_fpath('data-def'),
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', $datanames->[0].'.csv' ),
	);
}
# commits
if (0) {
	$s->dataset_upload(
		dataset => $datanames->[1],
		manifest_dir => $s->script_rel_fpath('data-def'),
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', $datanames->[1].'.csv' ),
	);
}

# features
if (0) {
	$s->dataset_upload( dataset => $datanames->[2], csv_rel_fpath => '../../../../dalsi/perl6-mj-features/data/features.csv' );

	use JSON::XS;
	my $json_obj = JSON::XS->new->canonical(1)->pretty(1)->utf8(0)->relaxed(1);

	my $meta_fpath = $s->script_rel_fpath('..','data-out','features-meta.json');
	my $meta_json = File::Slurp::read_file( $meta_fpath );
	my $meta_data = $json_obj->decode( $meta_json );
	my $text = '['.$meta_data->{commiter_gmtime_str}.'|'.$meta_data->{url}.']';
	print "Meta loaded from '$meta_fpath' and text '$text' prepared.\n";

	my $dash_obj = $s->get_first_obj_content_by( identifier => $dash_identifier );
	$self->update_dashboard_item(
		$dash_obj,
		{ tab_pos => 0, item_pos => 9 }, # todo - more dynamic aproach
		{ text => $text },
	);
	#$s->dump_struct( 'dash_obj', $dash_obj );
	$s->cl_post( $dash_obj->{projectDashboard}{meta}{uri}, $dash_obj );
}