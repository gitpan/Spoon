package Spoon::Plugin;
use strict;
use Spoon::Base '-Base';

sub class_id {
    my $package = ref $self;
    $package =~ s/.*:://;
    lc($package);
}

sub register {
    $self->hub->registry->add(action => $self->class_id, 'process')
      if $self->can('process');
    return $self;
}

sub plugin_directory {
    my $dir = join '/',
        $self->hub->registry->plugin_directory,
        $self->class_id,
    ;
    mkdir $dir unless -d $dir;
    return $dir;
}
    
1;

__END__

=head1 NAME 

Spoon::Plugin - Spoon Plugin Base Class

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
