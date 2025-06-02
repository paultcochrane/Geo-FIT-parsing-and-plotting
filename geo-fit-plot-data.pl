use strict;
use warnings;

use Geo::FIT::Utils qw(
    extract_activity_data
    show_activity_statistics
    plot_activity_data
);


sub main {
    my @activity_data = extract_activity_data();

    show_activity_statistics(@activity_data);
    plot_activity_data(@activity_data);
}

main();

# vim: expandtab shiftwidth=4 softtabstop=4
