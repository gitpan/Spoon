package Spoon::Cookie;
use Spoon::Base -Base;

field 'preferences';
field 'jar' => {};
const expires => '+5y';
const path => '/';
const prefix => 'Spoon-';
const domain => '';

sub init {
    $self->use_class('config');
    $self->use_class('cgi');
    $self->fetch();
}

sub write {
    my ($cookie_name, $hash) = @_;
    require Storable;
    $self->jar->{$cookie_name} = $hash;
}

sub read {
    my $cookie_name = shift;
    my $jar = $self->jar;
    my $cookie = $jar->{$cookie_name};
    $cookie ||= {};
    return $cookie;
}

sub set_cookie_headers {
    my $jar = $self->jar;
    return () unless keys %$jar;
    my $cookies = [];
    @$cookies = map {
	CGI::cookie(
            -name => $self->prefix . $_,
            -value => Storable::freeze($jar->{$_} || {}),
            -path => $self->path,
            -expires => $self->expires,
            -domain => $self->domain,
        );
    } keys %$jar;
    return @$cookies ? (-cookie => $cookies) : ();
}

sub fetch {
    require Storable;
    my $prefix = $self->prefix;
    my $jar = { 
        map {
            (my $key = $_) =~ s/^\Q$prefix\E//;
            my $object = eval { Storable::thaw(CGI::cookie($_)) };
            $@ ? () : ($key => $object) 
        }
        grep { /^\Q$prefix\E/ } CGI::cookie() 
    };
    $self->jar($jar);
}

__END__

=head1 NAME 

Spoon::Cookie - Spoon Cookie Base Class

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
