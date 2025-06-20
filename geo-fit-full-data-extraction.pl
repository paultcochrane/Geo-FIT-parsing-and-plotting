use strict;
use warnings;

use Geo::FIT;
use Scalar::Util qw(reftype);
use List::Util qw(max sum);

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

# extract and return the numerical parts of an array of FIT data values
sub num_part {
    my $field_name = shift;
    my @activity_data = @_;

    return map { (split ' ', $_->{$field_name})[0] } @activity_data;
}

# return the average of an array of numbers
sub avg {
    my @array = @_;

    return (sum @array) / (scalar @array);
}

print "Found ", scalar @activity_data, " entries in FIT file\n";
my $available_fields = join ", ", sort keys %{$activity_data[0]};
print "Available fields: $available_fields\n";

my $total_distance_m = (split ' ', ${$activity_data[-1]}{'distance'})[0];
my $total_distance = $total_distance_m/1000;
print "Total distance: $total_distance km\n";

# my @speeds = map { (split ' ', $_->{'speed'})[0] } @activity_data;
my @speeds = num_part('speed', @activity_data);
my $maximum_speed = max @speeds;
my $maximum_speed_km = $maximum_speed*3.6;
print "Maximum speed: $maximum_speed m/s = $maximum_speed_km km/h\n";

# my $average_speed = (sum @speeds) / (scalar @speeds);
my $average_speed = avg(@speeds);
my $average_speed_km = sprintf("%0.2f", $average_speed*3.6);
$average_speed = sprintf("%0.2f", $average_speed);
print "Average speed: $average_speed m/s = $average_speed_km km/h\n";

my @powers = map { (split ' ', $_->{'power'})[0] } @activity_data;
my $maximum_power = max @powers;
print "Maximum power: $maximum_power W\n";

my $average_power = (sum @powers) / (scalar @powers);
$average_power = sprintf("%0.2f", $average_power);
print "Average power: $average_power W\n";

my @heart_rates = map { (split ' ', $_->{'heart_rate'})[0] } @activity_data;
my $maximum_heart_rate = max @heart_rates;
print "Maximum heart rate: $maximum_heart_rate bpm\n";

my $average_heart_rate = (sum @heart_rates) / (scalar @heart_rates);
$average_heart_rate = sprintf("%0.2f", $average_heart_rate);
print "Average heart rate: $average_heart_rate bpm\n";

# vim: expandtab shiftwidth=4 softtabstop=4
