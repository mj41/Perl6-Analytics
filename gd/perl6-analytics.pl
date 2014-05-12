# Create project, run maql and upload data.

$s->login();
$s->get_or_create_project(
	title => $s->get_cfg('project_name') || die "No project name provided.",
	token => $s->get_cfg('token') || undef,
	driver => $s->get_cfg('driver') || 'Pg',
);

# Datasets names.
my @datanames = qw(
	projects
	commits
	commits_files
);
my @datanames_plus = qw(
	features
);
my $base_data_def_dir = $s->script_rel_fpath('../../Git-Analytics/gd/data-def');
my $plus_data_def_dir = $s->script_rel_fpath('data-def-plus');

my $dash_identifier = 'abv26SHOaI4O';

# maql
$s->run_maql_for_dataset(
	dataset => [ @datanames ],
	maql_dir => $base_data_def_dir,
);
$s->run_maql_for_dataset(
	dataset => [ @datanames_plus ],
	maql_dir => $plus_data_def_dir,
);

# delete all data
if (1) {
	my $maql = '';
	foreach my $ds_base_name ( @datanames, @datanames_plus ) {
		$maql .= "\n" if $maql;
		$maql .= sprintf( 'SYNCHRONIZE {%s};', 'dataset.'.$ds_base_name );
	}
	my $res = $s->run_maql($maql);
}

# projects
if (1) {
	$s->dataset_upload(
		dataset => 'projects',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'projects.csv' ),
	);
}

# commits
if (1) {
	$s->dataset_upload(
		dataset => 'commits',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits.csv' ),
		#csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits-small.csv' ),
	);
}

# commits_files
if (1) {
	$s->dataset_upload(
		dataset => 'commits_files',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits_files.csv' ),
	);
}

# features
if (0) {
	$s->dataset_upload(
		dataset => 'features',
		manifest_dir => $plus_data_def_dir,
		csv_rel_fpath => '../../../../dalsi/perl6-mj-features/data/features.csv'
	);

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