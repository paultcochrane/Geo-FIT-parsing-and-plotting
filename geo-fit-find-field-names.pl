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

    return \@all_field_names;
};

$fit->data_message_callback_by_name('record', $record_callback ) or die $fit->error;

my @header_things = $fit->fetch_header;

my $found_field_names = 0;
do {
    my $field_names = $fit->fetch;
    my $reftype = reftype $field_names;
    if (defined $reftype && $reftype eq 'ARRAY') {
        print "Number of field names found: ", scalar @{$field_names}, "\n";

        while (my @next_field_names = splice @{$field_names}, 0, 5) {
            my $joined_field_names = join ", ", @next_field_names;
            print $joined_field_names, "\n";
        }
        $found_field_names = 1;
    }
} while ( !$found_field_names );

$fit->close;

# vim: expandtab shiftwidth=4 softtabstop=4
