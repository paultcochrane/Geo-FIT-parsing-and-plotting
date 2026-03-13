package Geo::FIT::Utils;

use strict;
use warnings;

use Moo;
use Exporter 5.57 'import';
use Geo::FIT;
use Scalar::Util qw(reftype);
use List::Util qw(max sum);
use Chart::Gnuplot;
use DateTime::Format::Strptime;


has fit_file => (
    is => "ro",
);

sub BUILD {
    my ($self, $args) = @_;

    die "Require fit_file arg" unless exists $args->{fit_file};

    $self->extract_activity_data;
}

has _raw_data => (
    is => "ro",
);

sub raw_data {
    my $self = shift;

    return @{$self->_raw_data};
}

has manufacturer_name => (
    is => "ro",
);

our $date_parser = DateTime::Format::Strptime->new(
    pattern => "%Y-%m-%dT%H:%M:%SZ",
    time_zone => 'UTC',
);

sub extract_activity_data {
    my $self = shift;

    my $fit = Geo::FIT->new();
    $fit->file( $self->fit_file );
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

    my $file_id_callback = sub {
        my ( $self, $descriptor, $values ) = @_;
        my $manufacturer_name = $self->field_value( 'manufacturer', $descriptor, $values );

        # Return a scalar ref to distinguish a returned field value from a
        # successful callback call, which returns 1.  This way we can
        # capture the field value in the code which calls ->fetch() and
        # distinguish it from the scalar success value, i.e. 1.
        return \$manufacturer_name;
    };

    # register callbacks with fit object
    $fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;
    $fit->data_message_callback_by_name( 'file_id', $file_id_callback )
      or die $fit->error;

    my @header_things = $fit->fetch_header;

    my $event_data;
    my @activity_data;
    do {
        $event_data = $fit->fetch;
        my $reftype = reftype $event_data;
        if (defined $reftype && $reftype eq 'HASH' && defined %$event_data{'timestamp'}) {
            push @activity_data, $event_data;
        }

        if (defined $reftype && $reftype eq 'SCALAR' && !$self->manufacturer_name) {
            $self->{manufacturer_name} = ${$event_data};
        }
    } while ( $event_data );

    $fit->close;

    @{$self->{_raw_data}} = @activity_data;
}

sub field_names {
    my $self = shift;

    my @field_names = sort keys %{$self->{_raw_data}[0]};

    return @field_names
}

# extract and return the data from the given field name
sub field_data_from_name {
    my ($self, $field_name) = @_;

    my @field_data;
    for my $element ($self->raw_data) {
        my $full_field_value = $element->{$field_name};
        my $value;
        if (!(defined $full_field_value)) {
            $value = $field_data[-1];
        }
        else {
            $value = (split ' ', $full_field_value)[0];
        }

        push @field_data, $value;
    }

    return @field_data;
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

    my @speeds = get_field_data('speed', @activity_data);
    my $maximum_speed = max @speeds;
    my $maximum_speed_km = $maximum_speed*3.6;
    print "Maximum speed: $maximum_speed m/s = $maximum_speed_km km/h\n";

    my $average_speed = avg(@speeds);
    my $average_speed_km = sprintf("%0.2f", $average_speed*3.6);
    $average_speed = sprintf("%0.2f", $average_speed);
    print "Average speed: $average_speed m/s = $average_speed_km km/h\n";

    my @powers = get_field_data('power', @activity_data);
    my $maximum_power = max @powers;
    print "Maximum power: $maximum_power W\n";

    my $average_power = avg(@powers);
    $average_power = sprintf("%0.2f", $average_power);
    print "Average power: $average_power W\n";

    my @heart_rates = get_field_data('heart_rate', @activity_data);
    my $maximum_heart_rate = max @heart_rates;
    print "Maximum heart rate: $maximum_heart_rate bpm\n";

    my $average_heart_rate = avg(@heart_rates);
    $average_heart_rate = sprintf("%0.2f", $average_heart_rate);
    print "Average heart rate: $average_heart_rate bpm\n";
}

sub plot_activity_data {
    my $self = shift;

    # extract data to plot from full activity data
    my @times = $self->elapsed_times;
    my @heart_rates = $self->field_data_from_name('heart_rate');
    my @powers = $self->field_data_from_name('power');

    # plot data
    my $date = $self->date;
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

sub elapsed_times {
    my $self = shift;

    # get the epoch time for the first point in the time data
    my @timestamps = map { $_->{'timestamp'} } $self->raw_data;
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

sub date {
    my $self = shift;

    # determine date from timestamp data
    my @timestamps = map { $_->{'timestamp'} } $self->raw_data;
    my $dt = $date_parser->parse_datetime($timestamps[0]);
    my $date = $dt->strftime("%Y-%m-%d");

    return $date;
}

our @EXPORT_OK = qw(
    show_activity_statistics
    plot_activity_data
    get_field_data
    avg
);

1;
