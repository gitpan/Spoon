package Spoon::Registry;
use strict;
use warnings;
use Spoon '-Base';

const class_id => 'registry';
field 'lookup';

sub init {
    $self->use_class('config');
}

sub plugin_directory {
    './plugin';
}

sub registry_path {
    $self->plugin_directory . '/registry.dd';
}

sub load {
    return 1 if defined $self->lookup;
    my $path = $self->registry_path;
    my $lookup = eval ${io $path}; die "$@" if $@;
    die "$path seems to be corrupt:\n$@" if $@;
    $self->lookup(bless $lookup, $self->lookup_class);
    die "$path out of date. Try running 'index.cgi --plugins'\n"
      if $self->out_of_date;
    return 1;
}

# XXX Needs to be real
sub out_of_date {
    return 0;
}

sub update {
    my $lookup = {};
    $self->lookup($lookup);
    for my $class_name (@{$self->config->plugin_classes}) {
        eval "require $class_name"; die $@ if $@;
        my $object = $class_name->new($self->hub);
        my $class_id = $object->class_id
          or die "No class_id for $class_name\n";
        $lookup->{classes}{$class_id} = $class_name;
        $object->register;
    }
    $self->write;
    $self->lookup(bless $self->lookup, $self->lookup_class);
    return 1;
}

sub add {
    my $key = shift;
    my $value = shift;
    if (defined $value) {
        $self->lookup->{$key}{$value} = [ caller()->class_id, @_ ];
    }
    else {
        push @{$self->lookup->{$key}}, caller()->class_id;
    }
}

sub write {
    my $path = $self->registry_path;
    require Data::Dumper;
    { 
        no warnings;
        $Data::Dumper::Indent = 1;
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Sortkeys = 1;
    }
    Data::Dumper::Dumper($self->lookup) > io($path);
}

sub lookup_class {
    'Spoon::Lookup';
}

package Spoon::Lookup;
use strict;
use Spiffy 0.15 '-base';

field 'classes';
field 'action';
field 'has_preferences';

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
