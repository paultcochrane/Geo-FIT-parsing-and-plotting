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

done_testing;

# vim: expandtab shiftwidth=4
