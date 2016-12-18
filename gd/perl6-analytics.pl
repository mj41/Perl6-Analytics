# Create project, run maql and upload data.

my $do_synchronize = $s->get_cfg('do_synchronize');
my $do_uploads = $s->get_cfg('do_uploads');
my $do_addon_features = $s->get_cfg('do_addon_features');
my $dash_identifier = $s->get_cfg('dash_identifier') || 'aZ9Plococr2G';

$s->login();
$s->get_or_create_project(
	title => $s->get_cfg('project_name') || die "No project name provided.",
	token => $s->get_cfg('token') || undef,
	driver => $s->get_cfg('driver') || 'Pg',
);

print "Dashboard identifier: $dash_identifier\n";

# Datasets names.
my @datanames = qw(
	projects
	commits
	commits_files
);
my @datanames_plus = qw(
	features
	roastdata
);
my $base_data_def_dir = $s->script_rel_fpath('../../Git-Analytics/gd/data-def');
my $plus_data_def_dir = $s->script_rel_fpath('data-def-plus');

if ( $do_uploads ) {
	# maql - base
	foreach my $ds_base_name ( @datanames ) {
		$s->run_maql_for_dataset(
			dataset => $ds_base_name,
			maql_dir => $base_data_def_dir,
		);
	}
	foreach my $ds_base_name ( @datanames_plus ) {
		$s->run_maql_for_dataset(
			dataset => $ds_base_name,
			maql_dir => $plus_data_def_dir,
		);
	}
}

# synchronize - delete all data
if ( $do_synchronize ) {
	my $maql = '';
	foreach my $ds_base_name ( @datanames, @datanames_plus ) {
		$maql .= "\n" if $maql;
		$maql .= sprintf( 'SYNCHRONIZE {%s};', 'dataset.'.$ds_base_name );
	}
	my $res = $s->run_maql($maql);
}

# projects
if ( $do_uploads ) {
	$s->dataset_upload(
		dataset => 'projects',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'projects.csv' ),
	);
}

# commits
if ( $do_uploads ) {
	$s->dataset_upload(
		dataset => 'commits',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits.csv' ),
		#csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits-small.csv' ),
	);
}

# commits_files
if ( $do_uploads ) {
	$s->dataset_upload(
		dataset => 'commits_files',
		manifest_dir => $base_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'commits_files.csv' ),
	);
}

# features
if ( $do_uploads ) {
	$s->dataset_upload(
		dataset => 'features',
		manifest_dir => $plus_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'features.csv' ),
	);
}

# roastdata
if ( $do_uploads ) {
	$s->dataset_upload(
		dataset => 'roastdata',
		manifest_dir => $plus_data_def_dir,
		csv_abs_fpath => $s->script_rel_fpath( '..', 'data-out', 'roastdata.csv' ),
	);
}

if ( $do_addon_features ) {
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
		sub {
			my ( $item_struct_name, $item_body, $item_pos, $tab_obj, $tab_pos ) = @_;
			return 0 unless $item_struct_name eq 'textItem';
			print "'$item_struct_name' text: $item_body->{text} (tab $tab_pos, item $item_pos)\n";
			return 1 if $item_body->{text} =~ m{github\.com/perl6/features/blob/.*/features\.json};
			return 0;
		},
		{ text => $text },
	);
	#$s->dump_struct( 'dash_obj', $dash_obj );
	$s->cl_post( $dash_obj->{projectDashboard}{meta}{uri}, $dash_obj );
}
