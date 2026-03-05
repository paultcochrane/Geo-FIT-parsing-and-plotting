use strict;
use warnings;

use Test::More;

use_ok("Geo::FIT::Utils");

my $activity = Geo::FIT::Utils->new(
    fit_file => "2025-05-08-07-58-33.fit"
);

is $activity->fit_file, "2025-05-08-07-58-33.fit", "fit_file attr sets value";

my @raw_data = $activity->raw_data;

is scalar @raw_data, 3273, "all raw data fetched";

done_testing;

# vim: expandtab shiftwidth=4
