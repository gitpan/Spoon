package Spoon::Hub;
use strict;
use Spoon::Base '-Base';

const class_id => 'hub';
const action => '_default_';
field 'config';
field 'registry';
field 'config_files' => [];
field 'loaded_objects' => [];
field 'post_process_actions' => [];

sub load_registry {
    return if defined $self->registry;
    $self->load_class('registry');
    $self->registry->load;
}

sub process {
    $self->load_registry;
    my $action = $self->action;
    die "No plugin for action '$action'"
      unless defined $self->registry->lookup->action->{$action};
    my ($class_id, $method) = 
      @{$self->registry->lookup->action->{$action}};
    $method ||= $action;
    $self->load_class($class_id);
    $self->$class_id->pre_process;
    return $self->$class_id->$method;
}

sub add_post_process {
    push @{$self->post_process_actions}, [@_];
}

sub post_process {
    for my $object (@{$self->loaded_objects}) {
        $object->post_process;
    }
    for my $tuple (@{$self->post_process_actions}) {
        my ($class, $method, @args) = @$tuple;
        $self->load_class($class);
        $self->$class->$method(@args);
    }
}

sub cleanup {
    for my $object (@{$self->loaded_objects}) {
        $object->cleanup;
    }
    $self->config(undef);
    #XXX Maybe need to undef class_id fields for other loaded classes
}

sub require_class {
    my $class_id = shift;
    my $class_id_class = "${class_id}_class";
    my $class = $self->config->$class_id_class;
    eval "require $class";
    die $@ if $@;
}

sub load_class {
    my ($class_id) = @_;
    return $self if $class_id eq 'hub';
    return $self->$class_id 
      if $self->can($class_id) and defined $self->$class_id;
    my $class_class = $class_id . '_class';
    my $class_name = $self->config->can($class_class)
        ? $self->config->$class_class
        : defined $self->registry
          ? defined $self->registry->lookup
            ? $self->registry->lookup->classes->{$class_id}
            : die "Can't find a class for class_id '$class_id'"
          : die "Can't find a class for class_id '$class_id'";
    $self->create_class_object($class_name, $class_id);
}

sub create_class_object {
    my ($class_name, $class_id) = @_;
    die "No class defined for class_id '$class_id'"
      unless $class_name;
    eval qq{ require $class_name }; die "require $class_name $@" if $@;
    my $object = $class_name->new($self);
    push @{$self->loaded_objects}, $object;
    $class_id ||= $object->class_id;
    die "No class_id defined for class: '$class_name'\n"
      unless $class_id;
    field $class_id;
    $self->$class_id($object);
    $object->init;
    return $object;
}

1;

__END__

=head1 NAME 

Spoon::Hub - Spoon Hub Base Class

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
