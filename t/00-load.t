use strict;
use warnings;

use Test::More;

use_ok("Geo::FIT::Utils");

my $activity = Geo::FIT::Utils->new(
    fit_file => "2025-05-08-07-58-33.fit"
);

is $activity->fit_file, "2025-05-08-07-58-33.fit", "fit_file attr sets value";

is $activity->manufacturer_name, "zwift", "manufacturer name read from FIT file";

my @raw_data = $activity->raw_data;

is scalar @raw_data, 3273, "all raw data fetched";

my @field_names = $activity->field_names;

my @expected_field_names = qw(
    altitude cadence distance heart_rate
    position_lat position_long power speed timestamp
);
is_deeply(\@field_names, \@expected_field_names,"all non-dummy field names returned");

my $date = $activity->date;

is $date, "2025-05-08", "date read from FIT data correctly";

my @elapsed_times = $activity->elapsed_times;

is scalar @elapsed_times, 3273, "all elapsed time data returned";
is $elapsed_times[0], 0, "first elapsed time value correct";
is $elapsed_times[-1], 54.5333333333333, "last elapsed time value correct";

my @timestamps = $activity->field_data_from_name("timestamp");
my $last_timestamp = $timestamps[-1];
my @latitudes = $activity->field_data_from_name("position_lat");
my $last_latitude = $latitudes[-1];
my @longitudes = $activity->field_data_from_name("position_long");
my $last_longitude = $longitudes[-1];

is $last_timestamp, "2025-05-08T06:53:17Z", "final timestamp correct";
is $last_latitude, "-11.6379452", "final latitude correct";
is $last_longitude, "166.9561233", "final longitude correct";

done_testing;

# vim: expandtab shiftwidth=4
