package Spoon;
use strict;
use warnings;
use Spiffy '-base';
our $VERSION = '0.11';

field const class_id => 'main';
field const config_class => 'Spoon::Config';
field 'hub';
field 'used_classes' => [];

sub new {
    my $class = shift;
    my $self = bless {}, ref($class) || $class;
    $self->hub(shift);
    return $self;
}

sub load_hub {
    my $self = shift;
    my @config_files = @_;
    my $config_class = $self->config_class;
    eval "require $config_class";
    die "Can't require $config_class:\n$@" if $@;
    my $config = $config_class->new(@config_files);
    my $hub_class = $config->hub_class;
    eval qq{ require $hub_class }; die $@ if $@;
    my $hub = $hub_class->new($config);
    $config->hub($hub);
    $hub->config_files(\@config_files);
    $self->hub($hub);
    return $hub;
}

sub use_class {
    my $self = shift;
    my ($class_id) = @_;
    $self->hub->load_class($class_id);
    my $package = caller;
    field -package => $package, $class_id;
    $self->$class_id($self->hub->$class_id);
    push @{$self->used_classes}, $class_id;
}       
        
sub init { }

my $global_die;
sub debug {
    my $self = shift;
    my $level = shift || 1;
    if ($level == 0) {
        *CORE::GLOBAL::die = $self->global_die
          if $self->global_die;
    }
    elsif ($level == 1) {
        *CORE::GLOBAL::die =
          sub { require Carp; goto &Carp::confess };
    }
    else {
        die "Undefined debug level '$level'";
    }
    return $self;
}

1;

__END__

=head1 NAME

Spoon - Spoon Passed Over Our Network

=head1 SYNOPSIS

    Out of the Cutlery Drawer
    And onto the Dinner Table

=head1 DESCRIPTION

Spoon is an Application Framework that is designed primarily for
building Social Software web applications. The Kwiki wiki software is
built on top of Spoon.

Spoon.pm is the primary base class for all the Spoon::* modules.
Spoon.pm inherits from Spiffy.pm.

Spoon is not an application in and of itself. (As compared to Kwiki)
You need to build your own applications from it.

=head1 SEE ALSO

Kwiki, Spiffy

=head1 DEDICATION

This project is dedicated to the memory of Iain "Spoon" Truskett.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
