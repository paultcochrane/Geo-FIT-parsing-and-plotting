use strict;
use warnings;

use Geo::FIT;

my $fit = Geo::FIT->new();
$fit->file( "2025-05-08-07-58-33.fit" );
$fit->open or die $fit->error;

my $record_callback = sub {
    my ($self, $descriptor, $values) = @_;
    my $time= $self->field_value( 'timestamp',     $descriptor, $values );
    my $lat = $self->field_value( 'position_lat',  $descriptor, $values );
    my $lon = $self->field_value( 'position_long', $descriptor, $values );
    print "Time was: ", join("\t", $time, $lat, $lon), "\n"
};

$fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;

my @header_things = $fit->fetch_header;

1 while ( $fit->fetch );

$fit->close;
