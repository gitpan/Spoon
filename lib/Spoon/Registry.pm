package Spoon::Registry;
use strict;
use warnings;
use Spoon '-Base';

const class_id => 'registry';
const registry_file => 'registry.dd';
const registry_directory => '.';
const lookup_class => 'Spoon::Lookup';

field 'lookup';
field 'current_class_id';

sub registry_path {
    join '/', $self->registry_directory, $self->registry_file; 
}

sub load {
    return 1 if defined $self->lookup and
                ref $self->lookup eq $self->lookup_class;
    my $path = $self->registry_path;
    my $lookup = eval ${io $path}; die "$@" if $@;
    die "$path seems to be corrupt:\n$@" if $@;
    $self->lookup(bless $lookup, $self->lookup_class);
    return 1;
}

sub update {
    my $lookup = {};
    $self->lookup($lookup);
    for my $class_name (@{$self->hub->config->plugin_classes}) {
        eval "require $class_name"; die $@ if $@;
        my $object = $class_name->new(hub => $self->hub);
        my $class_id = $object->class_id
          or die "No class_id for $class_name\n";
        $self->current_class_id($class_id);
        $lookup->{classes}{$class_id} = $class_name;
        push @{$lookup->{plugins}}, {
            id => $class_id,
            title => $object->class_title,
        };
        $object->register($self);
    }
    $self->write;
    $self->load;
    return 1;
}

sub add {
    my $key = shift;
    my $value = shift;
    my $class_id = $self->current_class_id;
    $self->lookup->{$key}{$value} = [ $class_id, @_ ];
    push @{$self->lookup->{add_order}{$class_id}{$key}}, $value;
}

sub write {
    $self->dumper_to_file($self->registry_path, $self->lookup);
}

package Spoon::Lookup;
use strict;
use Spiffy 0.20 '-base';

field action => {};
field add_order => {};
field classes => {};
field plugins => [];
field preference => {};
field preload => {};
field wafl => {};

1;

__END__

=head1 NAME 

Spoon::Registry - Spoon Registry Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
