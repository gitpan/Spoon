package Spoon::CGI;
use strict;
use warnings;
use Spoon '-Base';
use CGI qw(-no_debug -nosticky);
our @EXPORT = qw(cgi);

my $all_params_by_class = {};

const class_id => 'cgi';

sub cgi() {
    my $package = caller;
    my ($field, @flags);
    for (@_) {
        (push @flags, $1), next if /^-(\w+)$/;
        $field ||= $_;
    }
    push @{$all_params_by_class->{$package}}, $field;
    no strict 'refs';
    no warnings;
    *{"$package\::$field"} = @flags 
    ? sub {
        my $self = shift;
        die "Setting CGI params not implemented" if @_;
        my $param = $self->_get_raw($field);
        for my $flag (@flags) {
            my $method = "_${flag}_filter";
            $self->$method($param);
        }
        return $param;
    } 
    : sub { 
        my $self = shift;
        die "Setting CGI params not implemented" if @_;
        $self->_get_raw($field);
    } 
}

sub add_params {
    my $class = ref($self);
    push @{$all_params_by_class->{$class}}, @_;
}

sub defined {
    my $param = shift;
    defined CGI::param($param);
}

sub all {
    my $class = ref($self);
    map { ($_, scalar $self->$_) } @{$all_params_by_class->{$class}};
}

sub vars {
    map $self->utf8_decode($_), CGI::Vars();
}

sub _get_raw {
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

sub _utf8_filter {
    $self->utf8_decode($_[0]);
}

sub _trim_filter {
    $_[0] =~ s/^\s*(.*?)\s*$/$1/mg;
    $_[0] =~ s/\s+/ /g;
}

sub _newlines_filter {
    if (length $_[0]) {
        $_[0] =~ s/\015\012/\n/g;
        $_[0] =~ s/\015/\n/g;
        $_[0] .= "\n"
          unless $_[0] =~ /\n\z/;
    }
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
