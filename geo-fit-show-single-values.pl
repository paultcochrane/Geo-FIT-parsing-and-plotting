use strict;
use warnings;

use Geo::FIT;
use Scalar::Util qw(reftype);

my $fit = Geo::FIT->new();
$fit->file( "2025-05-08-07-58-33.fit" );
$fit->open or die $fit->error;

my $record_callback = sub {
    my ($self, $descriptor, $values) = @_;
    my @all_field_names = $self->fields_list($descriptor);

    my %event_data;
    for my $field_name (@all_field_names) {
        my $field_value = $self->field_value($field_name, $descriptor, $values);
        $event_data{$field_name} = $field_value;
    }

    return \%event_data;
};

$fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;

my @header_things = $fit->fetch_header;

my $found_event_data = 0;
do {
    my $event_data = $fit->fetch;
    my $reftype = reftype $event_data;
    if (defined $reftype && $reftype eq 'HASH' && !defined %$event_data{'timestamp'}) {
        for my $key ( sort keys %$event_data ) {
            print "$key = ", $event_data->{$key}, "\n";
        }
        $found_event_data = 1;
    }
} while ( !$found_event_data );

$fit->close;

# vim: expandtab shiftwidth=4 softtabstop=4
