package Spoon::Base;
use strict;
use warnings;
use Spiffy 0.16 '-Base', ':XXX' , 'field';
use IO::All 0.17 ();
our @EXPORT = qw(io XXX);

# Indented to avoid $self ishness. Parens mess it up. Spiffy should remove the
# parens in this case.
    sub io { IO::All->new(@_) }

field 'hub';
field 'used_classes' => [];

sub new() {
    my $class = shift;
    my $self = $class->SUPER::new;
    $self->hub(shift);
    return $self;
}

sub use_class {
    my ($class_id) = @_;
    Carp::confess()  unless $self->hub;
    $self->hub->load_class($class_id);
    my $package = caller;
    field -package => $package, $class_id;
    $self->$class_id($self->hub->$class_id);
    push @{$self->used_classes}, $class_id;
}       
        
sub init { }
sub pre_process { }
sub post_process { }

our ($UPPER, $LOWER, $ALPHANUM, $WORD, $WIKIWORD);
our @EXPORT_OK = qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD);
our %EXPORT_TAGS = 
  (char_classes => [qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD)]);
if ($] < 5.008) {
    $UPPER    = "A-Z\xc0-\xde";
    $LOWER    = "a-z\xdf-\xff";
    $ALPHANUM = "A-Za-z0-9\xc0-\xff";
    $WORD     = "A-Za-z0-9\xc0-\xff_";
    $WIKIWORD = $WORD;
}
else {
    $UPPER    = '\p{UppercaseLetter}';
    $LOWER    = '\p{LowercaseLetter}';
    $ALPHANUM = '\p{Letter}\p{Number}\pM';
    $WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
    $WIKIWORD = "$UPPER$LOWER\\p{Number}\\p{ConnectorPunctuation}\\pM";
}

sub cleanup {
    for my $class_id (@{$self->used_classes}, 'hub') {
        $self->$class_id(undef);
    }
}

sub assert_dirpath {
    my $dirpath = shift;
    unless (-d $dirpath) {
        mkdir($dirpath, 0755) or
        do {
            require File::Path;
            File::Path::mkpath($dirpath);
        } or
        die "Can't make directory $dirpath";
    }
    return $dirpath;
}

sub assert_filepath {
    my $filepath = shift;
    my $dirpath = $filepath;
    $dirpath =~ s/(.*\/).*/$1/;
    $self->assert_dirpath($dirpath);
}

sub env_check {
    my $variable = shift;
    die "Environment variable '$variable' not set"
      unless defined $ENV{$variable};
}

# i18n stuff
my $use_utf8;
field 'encoding';

sub use_utf8 {
    $use_utf8 = shift if @_;
    return $use_utf8 if defined($use_utf8);
    return($use_utf8 = 0) if $] < 5.008;
    return 1 unless $self->config;
    return($use_utf8 = (lc($self->config->encoding) =~ /^utf-?8$/));
}

sub loc {
    my $i18n_class = $self->hub->config->i18n_class or die;
    eval "use $i18n_class; 1" or return $_[0];
    $i18n_class->initialize($self->use_utf8 || 0);
    return $i18n_class->loc(@_);
}

sub decode {
    utf8::decode($_[0]) if $self->use_utf8 and defined $_[0];
    return $_[0] if defined wantarray;
}

sub encode {
    utf8::encode($_[0]) if $self->use_utf8 and defined $_[0];
    return $_[0] if defined wantarray;
}

sub escape {
    my $data = shift;
    $self->encode($data);
    return CGI::Util::escape($data);
}

sub unescape {
    my $data = shift;
    $data = CGI::Util::unescape($data);
    $self->decode($data);
    return $data;
}

1;

__END__

=head1 NAME 

Spoon::Base - Generic Spoon Base Class

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
