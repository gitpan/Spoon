package Spoon::CGI;
use strict;
use warnings;
use Spoon '-base';
use CGI;
our @EXPORT = qw(cgi_field);

field const class_id => 'cgi';

sub all {
    my ($self) = @_;
    return (
        CGI::Vars(),
    );
}

sub cgi_field {
    my $package = caller;
    my $field = shift;
    no strict 'refs';
    return if defined &{"${package}::$field"};
    *{"${package}::$field"} = 
    sub { 
        my $self = shift;
        $self->cgi->get_raw($field);
    };
}

sub get_raw {
    my $self = shift;
    my $field = shift;
    if (@_) {
        $self->{$field} = shift;
        return $self;
    }
    my @values = defined $self->{$field}
      ? $self->{$field}
      : CGI::param($field);
    return wantarray
      ? @values 
      : defined $values[0]
        ? $values[0]
        : ''; 
}

1;

__END__

=head1 NAME 

Spoon::CGI - Spoon CGI Base Class

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
