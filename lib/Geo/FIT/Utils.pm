package Geo::FIT::Utils;

use strict;
use warnings;

use Exporter 5.57 'import';
use Geo::FIT;
use Scalar::Util qw(reftype);
use List::Util qw(max sum);
use Chart::Gnuplot;
use DateTime::Format::Strptime;


our $date_parser = DateTime::Format::Strptime->new(
    pattern => "%Y-%m-%dT%H:%M:%SZ",
    time_zone => 'UTC',
);

sub extract_activity_data {
    my $fit = Geo::FIT->new();
    $fit->file( "2025-05-08-07-58-33.fit" );
    $fit->open or die $fit->error;

    my $record_callback = sub {
        my ($self, $descriptor, $values) = @_;
        my @all_field_names = $self->fields_list($descriptor);

        my %event_data;
        for my $field_name (@all_field_names) {
            my $field_value = $self->field_value($field_name, $descriptor, $values);
            if ($field_value =~ /[a-zA-Z]/) {
                $event_data{$field_name} = $field_value;
            }
        }

        return \%event_data;
    };

    $fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;

    my @header_things = $fit->fetch_header;

    my $event_data;
    my @activity_data;
    do {
        $event_data = $fit->fetch;
        my $reftype = reftype $event_data;
        if (defined $reftype && $reftype eq 'HASH' && defined %$event_data{'timestamp'}) {
            push @activity_data, $event_data;
        }
    } while ( $event_data );

    $fit->close;

    return @activity_data;
}

# extract and return the numerical parts of an array of FIT data values
sub num_parts {
    my $field_name = shift;
    my @activity_data = @_;

    return map { (split ' ', $_->{$field_name})[0] } @activity_data;
}

# return the average of an array of numbers
sub avg {
    my @array = @_;

    return (sum @array) / (scalar @array);
}

sub show_activity_statistics {
    my @activity_data = @_;

    print "Found ", scalar @activity_data, " entries in FIT file\n";
    my $available_fields = join ", ", sort keys %{$activity_data[0]};
    print "Available fields: $available_fields\n";

    my $total_distance_m = (split ' ', ${$activity_data[-1]}{'distance'})[0];
    my $total_distance = $total_distance_m/1000;
    print "Total distance: $total_distance km\n";

    my @speeds = num_parts('speed', @activity_data);
    my $maximum_speed = max @speeds;
    my $maximum_speed_km = $maximum_speed*3.6;
    print "Maximum speed: $maximum_speed m/s = $maximum_speed_km km/h\n";

    my $average_speed = avg(@speeds);
    my $average_speed_km = sprintf("%0.2f", $average_speed*3.6);
    $average_speed = sprintf("%0.2f", $average_speed);
    print "Average speed: $average_speed m/s = $average_speed_km km/h\n";

    my @powers = num_parts('power', @activity_data);
    my $maximum_power = max @powers;
    print "Maximum power: $maximum_power W\n";

    my $average_power = avg(@powers);
    $average_power = sprintf("%0.2f", $average_power);
    print "Average power: $average_power W\n";

    my @heart_rates = num_parts('heart_rate', @activity_data);
    my $maximum_heart_rate = max @heart_rates;
    print "Maximum heart rate: $maximum_heart_rate bpm\n";

    my $average_heart_rate = avg(@heart_rates);
    $average_heart_rate = sprintf("%0.2f", $average_heart_rate);
    print "Average heart rate: $average_heart_rate bpm\n";
}

sub plot_activity_data {
    my @activity_data = @_;

    # extract data to plot from full activity data
    my @times = get_time_data(@activity_data);
    my @heart_rates = num_parts('heart_rate', @activity_data);
    my @powers = num_parts('power', @activity_data);

    # plot data
    my $date = get_date(@activity_data);
    my $chart = Chart::Gnuplot->new(
        output => "watopia-figure-8-heart-rate-and-power.png",
        title  => "Figure 8 in Watopia on $date: heart rate and power over time",
        xlabel => "Elapsed time (min)",
        ylabel => "Heart rate (bpm)",
        terminal => "png size 1024, 768",
        xtics => {
            incr => 5,
        },
        ytics => {
            mirror => "off",
        },
        y2label => 'Power (W)',
        y2range => [0, 1100],
        y2tics => {
            incr => 100,
        },
    );

    my $heart_rate_ds = Chart::Gnuplot::DataSet->new(
        xdata => \@times,
        ydata => \@heart_rates,
        style => "lines",
    );

    my $power_ds = Chart::Gnuplot::DataSet->new(
        xdata => \@times,
        ydata => \@powers,
        style => "lines",
        axes => "x1y2",
    );

    $chart->plot2d($power_ds, $heart_rate_ds);
}

sub get_time_data {
    my @activity_data = @_;

    # get the epoch time for the first point in the time data
    my @timestamps = map { $_->{'timestamp'} } @activity_data;
    my $first_epoch_time = $date_parser->parse_datetime($timestamps[0])->epoch;

    # convert timestamp data to elapsed minutes from start of activity
    my @times = map {
        my $dt = $date_parser->parse_datetime($_);
        my $epoch_time = $dt->epoch;
        my $elapsed_time = ($epoch_time - $first_epoch_time)/60;
        $elapsed_time;
    } @timestamps;

    return @times;
}

sub get_date {
    my @activity_data = @_;

    # determine date from timestamp data
    my @timestamps = map { $_->{'timestamp'} } @activity_data;
    my $dt = $date_parser->parse_datetime($timestamps[0]);
    my $date = $dt->strftime("%Y-%m-%d");

    return $date;
}

our @EXPORT_OK = qw(
    extract_activity_data
    show_activity_statistics
    plot_activity_data
    get_time_data
    num_parts
);

1;
