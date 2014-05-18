#!/bin/bash

set -e
#set -x

if [ -z "$1" ]; then
	echo "Instance type missing. Use 'prod' or 'pi'."
	exit 1
fi
if [ "$1" == "prod" ]; then
	echo "Running on production."
elif [ "$1" == "pi" ]; then
	PI_HOSTNAME=`perl -e'open($fh,$ARGV[0]);$/=undef;print $1 if <$fh>=~/Host\s+pi\s+HostName\s+(\S+)/m' ~/.ssh/config`
	echo "Running on PI '$PI_HOSTNAME'"
else
	echo "Uknown istance type '$1'"
	exit 1
fi
INSTANCE_TYPE="$1"

if [ -z "$2" ]; then
	echo "Project name not provided"
	exit 1
fi
GD_PROJ_NAME="$2"

if [ -z "$3" ]; then
	SKIP_FETCH=1
elif [ "$3" == "fetch_no" ]; then
	SKIP_FETCH=1
elif [ "$3" == "fetch_yes" ]; then
	SKIP_FETCH=0
else
	echo "Uknown value of 'fetch' parameter. Use: nothing, 'fetch_no'  or 'fetch_yes'"
	exit 1
fi

echo "Project name: '$GD_PROJ_NAME'"


CWD=`pwd`

cd /home/mj/gd/rolapps/third-part/Perl6-Analytics
echo "Removing old caches"
rm -rf data-cache/git-analytics-state/* data-cache/git-analytics-state-commits.json data-out/commits.csv data-out/commits_files.csv
echo "Runing projects refresh script"
perl bin/projects-refresh.pl 1 1 5
echo "Runing commits refresh script"
perl bin/commits-refresh.pl $SKIP_FETCH 5
echo "Runing features refresh script"
perl bin/features-refresh.pl $SKIP_FETCH 5

cd /home/mj/gd/rolapps/apps/rcheck/
echo "Updating GD project"
if [ "$INSTANCE_TYPE" == "prod" ]; then
	perl rcheck.pl -vl 8 -cf config/secure-na.yaml -sc ~/gd/rolapps/third-part/Perl6-Analytics/gd/perl6-analytics.pl --co do_uploads=1 --co do_synchronize=1 --co do_addon_features=1 -p $GD_PROJ_NAME
else
	perl rcheck.pl --base_url "https://$PI_HOSTNAME" -vl 8 -cf config/dev-machine.yaml -sc ~/gd/rolapps/third-part/Perl6-Analytics/gd/perl6-analytics.pl --co do_uploads=1 --co do_synchronize=1 --co do_addon_features=1 -p $GD_PROJ_NAME
fi

echo "Done"
cd "$CWD"
