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
    return 1 if defined $self->lookup;
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
        my $object = $class_name->new($self->hub);
        my $class_id = $object->class_id
          or die "No class_id for $class_name\n";
        $self->current_class_id($class_id);
        $lookup->{classes}{$class_id} = $class_name;
        $object->register($self);
    }
    $self->write;
    $self->load;
    return 1;
}

sub add {
    my $key = shift;
    my $value = shift;
    $self->lookup->{$key}{$value} = [ $self->current_class_id, @_ ];
}

sub write {
    $self->dumper_to_file($self->registry_path, $self->lookup);
}

package Spoon::Lookup;
use strict;
use Spiffy 0.15 '-base';

field 'classes' => {};
field 'action' => {};
field 'preference' => {};
field 'wafl' => {};
field 'preload' => {};

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
