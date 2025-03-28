package Omniframe::Role::Model;

use exact -role;
use Mojo::Util 'decamelize';

with qw( Omniframe::Role::Database Omniframe::Role::Logging );

class_has name => sub ($self) {
    my $name = ref $self;
    $name =~ s/^.*:://;
    return decamelize $name;
};
class_has id_name => sub ($self) { $self->name . '_id' };
class_has active  => 0;

has id         => undef;
has data       => sub { {} };
has saved_data => sub { {} };

sub create ( $self, $data ) {
    $data = $self->data_merge($data);
    $data = $self->freeze($data) if ( $self->can('freeze') );

    croak('create() data hashref contains no data') unless ( keys %$data );

    eval { $self->load(
        $self->dq->add( $self->name, $data ),
        'skip_active_in_search_setup',
    ) } or croak deat $@;

    return $self;
}

sub _setup_search ( $self, $search, $skip_active_in_search_setup = 0 ) {
    $search = ( ref $search ) ? { %$search } : { $self->id_name => $search // $self->id };

    if ( $self->active and not $skip_active_in_search_setup ) {
        $search->{active} = \'IS TRUE' unless ( exists $search->{active} );
        delete $search->{active} if (
            ref $search->{active} eq 'SCALAR' and
            not defined ${ $search->{active} }
        );
    }

    return $search;
}

sub load ( $self, $search = undef, $skip_active_in_search_setup = 0 ) {
    croak('load() called without input') unless ($search);

    my $data = $self->dq->get( $self->name )->where(
        $self->_setup_search( $search, $skip_active_in_search_setup )
    )->run->next;

    croak( 'Failed to load ' . $self->name ) unless ($data);

    $data = $data->data;
    $self->saved_data({%$data});
    $data = $self->thaw($data) if ( $self->can('thaw') );

    $self->data($data);
    $self->id( $self->data->{ $self->id_name } );

    return $self;
}

sub is_dirty ( $self, $name, $data = $self->data ) {
    return (
        not exists $data->{$name} and not exists $self->saved_data->{$name} or
        exists $data->{$name} and exists $self->saved_data->{$name} and
            not defined $data->{$name} and not defined $self->saved_data->{$name} or
        defined $data->{$name} and defined $self->saved_data->{$name} and
            $data->{$name} eq $self->saved_data->{$name}
    ) ? 0 : 1;
}

sub dirty ($self) {
    my %keys = map { $_ => 1 } map { keys %$_ } $self->data, $self->saved_data;
    my @dirty_keys = grep { $self->is_dirty($_) } sort keys %keys;
    return (wantarray) ? @dirty_keys : (@dirty_keys) ? 1 : 0;
}

sub save ( $self, $data = undef ) {
    $data = $self->data_merge($data);

    unless ( $self->id ) {
        $self->create($data);
    }
    else {
        $data = $self->freeze($data) if ( $self->can('freeze') );

        for ( grep { exists $self->saved_data->{$_} } keys %$data ) {
            delete $data->{$_} if (
                defined $data->{$_} and
                defined $self->saved_data->{$_} and
                $data->{$_} eq $self->saved_data->{$_} or
                not defined $data->{$_} and
                not defined $self->saved_data->{$_}
            );
        }

        if ( keys %$data ) {
            eval {
                $self->dq->update( $self->name, $data, { $self->id_name => $self->id } );
            } or croak deat $@;
        }

        $self->load( $self->id ) unless ( $self->active and not $self->data->{active} );
    }

    return $self;
}

sub delete ( $self, $search = undef ) {
    croak('Cannot delete() an object without loaded data') unless ( $self->id or $search );

    unless ( $self->active ) {
        $self->dq->rm( $self->name, $self->_setup_search($search) );
    }
    else {
        $self->data->{active} = 0;
        $self->save;
    }

    return $self;
}

sub every ( $self, $search = {}, $meta = {} ) {
    my @objects = map {
        my $data = {%$_};
        $data = $self->thaw($data) if ( $self->can('thaw') );

        $self->new(
            id                 => $data->{ $self->id_name },
            data               => $data,
            saved_data => $_,
        );
    } @{ $self->dq->get( $self->name )->where( $self->_setup_search( $search, $meta ) )->run->all({}) };

    return (wantarray) ? @objects : \@objects;
}

sub every_data ( $self, $search = {}, $meta = {} ) {
    my $objects = $self->dq->get( $self->name, undef, $self->_setup_search($search), $meta )->run->all({});

    if ( $self->can('thaw') ) {
        $_ = $self->thaw($_) for (@$objects);
    }

    return (wantarray) ? @$objects : $objects;
}

sub data_merge ( $self, $data ) {
    if ( not $data and $self->data ) {
        $data = { %{ $self->data } };
    }
    elsif ( $data and $self->data ) {
        $data = {%$data};
        for ( keys %{ $self->data } ) {
            $data->{$_} = $self->data->{$_} unless ( exists $data->{$_} );
        }
    }

    $data //= {};
    delete $data->{ $self->id_name };
    return $data;
}

sub resolve_id ( $self, $input = undef, $class_name = undef ) {
    return unless ( defined $input );
    return $input if ( $input =~ /^\d+$/ );

    if ( eval { $input->does(__PACKAGE__) } ) {
        croak( 'input does ' . __PACKAGE__ . ' but is not a ' . $class_name )
            if ( $class_name and not eval { $input->isa($class_name) } );
        return $input->id;
    }

    return (
        ($class_name)
            ? do {
                eval "require $class_name" or croak $@;
                $class_name;
            }
            : $self
    )->new->load($input)->id if ( ref $input eq 'HASH' );

    croak('unsupported input');
}

sub resolve_obj ( $self, $input = undef, $class_name = undef ) {
    return unless ( defined $input );

    if ( eval { $input->does(__PACKAGE__) } ) {
        croak( 'input does ' . __PACKAGE__ . ' but is not a ' . $class_name )
            if ( $class_name and not eval { $input->isa($class_name) } );
        return $input;
    }

    return (
        ($class_name)
            ? do {
                eval "require $class_name" or croak $@;
                $class_name;
            }
            : $self
    )->new->load($input) if ( ref $input eq 'HASH' or $input =~ /^\d+$/ );

    croak('unsupported input');
}

1;

=head1 NAME

Omniframe::Role::Model

=head1 SYNOPSIS

    package Model;

    use exact -class;

    with 'Omniframe::Role::Model';

    package main;

    use exact;

    my $obj = Model->new->create({ column_name => 'column_value' });
    $obj->data->{column_name} = 'new_value';
    $obj->save;
    $obj->save({ column_name => 42 });

    my $obj2 = Model->new->load( $obj->id );

    Model->new->load(1138)->delete;
    Model->new->load->delete(1138);

    my $hhgttg_rows_0 = Model->new->every({ answer => 42 });
    my $hhgttg_rows_1 = Model->new->every_data({ answer => 42 });

=head1 DESCRIPTION

This role provides functionality in a given class such that the class will
resemble a basic data model class. These model classes can be used like a
simplistic ORM, to a limited degree.

It's database system agnostic, inheriting whatever it needs from
L<Omniframe::Role::Database>, which provides an accessor to a L<DBIx::Query>
connection.

=head1 CLASS ATTRIBUTES

=head2 name

This optional class attribute represents the table name to be associated with
the class. If not defined, it will be generated using L<Mojo::Util>'s
C<decamelize> on the last node of the class name of the model class.

=head2 id_name

This class attribute is the name of the class's table's primary key name. The
value may be optionally defined. If not defined, C<id_name> will be set as
"<name>_id".

=head2 active

Set this value to true if the class's table contains an "active" column. See
L</"ACTIVE RECORDS"> below.

=head1 OBJECT ATTRIBUTES

=head2 id

When loaded, this object attribute will be the primary key value for the record.
It gets set automatically when the object loads a record from the database.  It
can be manually set and overridden.

=head2 data

When loaded, this object attribute will be a hashref containing the record that
is either in the database or will be (prior to a C<save> call) independent of
any freezing changes. It gets set automatically when the object loads a record
from the database. It can be manually set and overridden.

=head2 saved_data

When loaded, this object attribute will be a hashref containing the record that
is frozen in the database. It gets set automatically when the object loads a
record from the database.

=head1 METHODS

=head2 create

This method will create a database record using object data. Object data can be
supplemented (changed) by passing in a hashref of data. The method will return
the object.

    my $obj_0 = Model->new->create({ column_name => 'column_value' });
    my $obj_1 = Model->new( data => { column_name => 'column_value' } )->create;
    my $obj_2 = Model
        ->new( data => { column_name => 'column_value' } )
        ->create({ column_name => 'column_value' });

As part of the C<create> process, after creation of the record in the database,
the record will be loaded into the object's C<data> attribute and the primary
key value will be stored into C<id>.

=head2 load

This method will load a database record given either a primary key value or a
hashref representing a SQL WHERE clause. The method will return the object.

    my $obj_0 = Model->new->load(42);
    my $obj_1 = Model->new->load( { model_id => 42 } );

=head2 is_dirty

This method accepts a key name (and an optional hashref of alternative data to
use in place of object data), and it will return a 1 or 0 indicating true/false
if the value of the key has changed relative to what's saved.

Note that C<freeze>/C<thaw> operations may cause inaccurate results.

=head2 dirty

This method will, in a scalar context, return a 1 or 0 representing the
true/false state of whether the data loaded in the object is "dirty" (meaning
it has been changed but not saved to the database).

    my $is_dirty = $obj->dirty;

In list context, it will return the keys/names of data that is "dirty".

    my @dirty_key_names = $obj->dirty;

Note that C<freeze>/C<thaw> operations may cause inaccurate results.

=head2 save

This method will save object data to the database. Typically, this is used to
update data in the database, but if C<id> is not set, it will create the
database record. Similar to C<create>, the data saved will be the object's data
merged with any data passed in via a hashref. The method will return the object.

    my $obj = Model->new->load(1138);
    $obj->data->{column_name} = 'new_value';
    $obj->save;
    $obj->save({ column_name => 42 });

=head2 delete

This method will delete a record from the database. If called on a loaded object
without parameters, it will delete the row based on the object's C<id>
attribute. Otherwise, it expects either a hashref with a SQL WHERE clause or a
primary key value.

    Model->new->load(1138)->delete;
    Model->new->load->delete(1138);
    Model->new->load->delete({ model_id => 42 });

=head2 every

This method expects a hashref with a SQL WHERE clause and will return a set of
instantiated objects loaded with the results of a SQL query using the WHERE
clause. The method will return either an array or arrayref based on context.

    my @hhgttg_rows = Model->new->every({ answer => 42 });
    my $hhgttg_rows = Model->new->every({ answer => 42 });

You can optionally include a meta hashref:

    my $rows = Model->new->every( { answer => 42 }, { limit => 10 } );

=head2 every_data

This method is the same as C<every> except that instead of returning an array or
arrayref of objects, it returns an array or arrayref of hashrefs, each
representing one database record.

    my @hhgttg_rows = Model->new->every_data({ answer => 42 });
    my $hhgttg_rows = Model->new->every_data({ answer => 42 });

You can optionally include a meta hashref:

    my $rows = Model->new->every_data( { answer => 42 }, { limit => 10 } );

=head2 data_merge

This method will likely not need to be used or called directly. Its purpose is
to take a hashref of data and merge it with any existing object data. It's
exposed here to more easily allow role consuming classes to override its
behavior if ever necessary.

=head2 resolve_id

This method will resolve a theoretical primary key ID for a given set of inputs.
If passed nothing or a false value, it will return call C<id> and return that
value. If passed an integer, it will simply return that integer. If passed a
hashref, it will attempt to a C<load> based on the hashref, then return an ID.
If passed an object, it will call C<id> on that object.

    $obj->resolve_id;      # return $obj->id
    $obj->resolve_id(42);  # return 42
    $obj->resolve_id({});  # return $obj->new->load({})->id
    $obj->resolve_id($in); # return $in->id

If an optional class name is also provided, then in the case where a hashref is
provided, an object will be instantiated based on that name and used for the
C<load> operation.

    $obj->resolve_id( {}, 'SomeClassName' );
    # return 'SomeClassName'->new->load({})->id

In the case where an object and a class name are provided, the object passed in
will be checked that it does the class name.

=head2 resolve_obj

This method will verify a given input is an object of a class, and if it isn't
and is instead an integer or hashref, it'll try to create and return a loaded
object based on the class name.

    my $obj_42      = $obj->resolve_obj( 42, 'SomeClassName' );
    my $also_obj_42 = $obj->resolve_obj( $obj_42, 'SomeClassName' );

=head1 DATA SERIALIZATION

In classes with this role, you can optionally provide C<freeze> and C<thaw>
methods that will be called by C<create>, C<save>, and C<load> in appropriate
ways such that you can serialize and deserialize data.

    package Model;

    use exact -class;
    use Mojo::JSON qw( to_json from_json );

    with 'Omniframe::Role::Model';

    sub freeze ( $self, $data ) {
        $data->{data} = to_json $data->{data};
        return $data;
    }

    sub thaw ( $self, $data ) {
        $data->{data} = from_json $data->{data};
        return $data;
    }

Note that you probably shouldn't serialize and deserialize the entire C<$data>
because that will likely cause database commands to fail.

=head1 ACTIVE RECORDS

When the C<active> class attribute is set to a true value, we'll assume the
database table contains a column called "active", and thus the C<load>,
C<delete>, C<every>, and C<every_data> methods will respect this as a flag to
indicate the record may or may not be "virtually deleted". For example, if in a
user table there's an active column, a C<load> for users will not find users
where this active column's data contains a false value.

This behavior can be overridden by setting "active" to a reference to C<undef>,
which will result in "active" playing no factor in the record search.

    $obj->data->{active} = \undef;

=head1 WITH ROLES

L<Omniframe::Role::Database>, L<Omniframe::Role::Logging>.
