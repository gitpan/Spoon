package Spoon::Base;
use Spiffy 0.21 -Base;
use Spiffy qw(-XXX -yaml);
# WWW - Creating a wrapper sub to require() IO::All caused spurious segfaults
use IO::All 0.32;
our @EXPORT = qw(io hook trace);
our @EXPORT_OK = qw(conf);

sub init { }
sub pre_process { }
sub post_process { }

field 'used_classes' => [];
field 'encoding';
field hub => -weak;
const plugin_base_directory => './plugin';

sub assert {
    die "Assertion failed" unless shift;
}

sub hook() {
    require Spoon::Hook;
    no warnings;
    *hook = sub {
        Spoon::Hook->hook(@_);
    };
    goto &hook;
}

sub trace() {
    require Spoon::Trace;
    no warnings;
    *trace = \ &Spoon::Trace::trace;
    goto &trace;
}

sub t {
    trace->mark;
    return $self;
}

sub conf() {
    my ($name, $default) = @_;
    my $package = caller;
    no strict 'refs';
    *{$package . '::' . $name} = sub {
        my $self = shift;
        return $self->{$name}
          if exists $self->{$name};
        $self->{$name} = exists($self->hub->config->{$name})
        ? $self->hub->config->{$name}
        : $default;
    };
}

sub clone {
    return bless {%$self}, ref $self;
}

sub use_class {
    my ($class_id) = @_;
    Carp::confess("No hub in '$class_id' object")  
      unless $self->hub;
    my $object = $self->hub->load_class($class_id);
    my $package = ref($self);
    field -package => $package, $class_id;
    $self->$class_id($self->hub->$class_id);
    push @{$self->used_classes}, $class_id;
    return $object;
}       
        
sub use_cgi {
    my $class = shift
      or die "use_cgi requires a class name";
    eval qq{require $class} unless $class->can('new');
    my $package = ref($self);
    field -package => $package, 'cgi';
    my $object = $class->new(hub => $self->hub);
    $object->init;
    $self->cgi($object);
}

sub is_in_cgi {
    defined $ENV{GATEWAY_INTERFACE};
}

sub is_in_test {
    defined $ENV{SPOON_TEST};
}

sub have_plugin {
    my $hub = $self->class_id eq 'hub'
    ? $self
    : $self->hub;
    local $@;
    eval { $hub->load_class(shift) }
}
    
sub plugin_directory {
    my $dir = join '/',
        $self->plugin_base_directory,
        $self->class_id,
    ;
    mkdir $dir unless -d $dir;
    return $dir;
}
    
our ($UPPER, $LOWER, $ALPHA, $NUM, $ALPHANUM, $WORD, $WIKIWORD);
push @EXPORT_OK, qw($UPPER $LOWER $ALPHA $NUM $ALPHANUM $WORD $WIKIWORD);
our %EXPORT_TAGS = (char_classes => [@EXPORT_OK]);
if ($] < 5.008) {
    $UPPER    = 'A-Z\xc0-\xde';
    $LOWER    = 'a-z\xdf-\xff';
    $ALPHA    = $UPPER . $LOWER;
    $NUM      = '0-9';
    $ALPHANUM = $ALPHA . $NUM;
    $WORD     = $ALPHANUM . '_';
    $WIKIWORD = $WORD;
}
else {
    $UPPER    = '\p{UppercaseLetter}';
    $LOWER    = '\p{LowercaseLetter}';
    $ALPHA    = '\p{Letter}';
    $NUM      = '\p{Number}';
    $ALPHANUM = '\p{Letter}\p{Number}\pM';
    $WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
    $WIKIWORD = "$UPPER$LOWER$NUM" . '\p{ConnectorPunctuation}\pM';
}

sub cleanup {
    for my $class_id (@{$self->used_classes}, 'hub') {
        $self->$class_id(undef);
    }
}

sub env_check {
    my $variable = shift;
    die "Environment variable '$variable' not set"
      unless defined $ENV{$variable};
}

sub dumper_to_file {
    my $path = shift;
    require Data::Dumper;
    no warnings;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = (@_ == 1) ? 1 : 0;
    local $Data::Dumper::Sortkeys = 1;
    io("$path")->assert->print(Data::Dumper::Dumper(@_));
}

# Codecs and Escaping
my $use_utf8;
sub use_utf8 {
    $use_utf8 = shift if @_;
    return $use_utf8 if defined($use_utf8);
    $use_utf8 = $] < 5.008 ? 0 : 1;
}

sub utf8_decode {
    require Encode;
    utf8::decode($_[0]) if $self->use_utf8 and defined $_[0] and
                           not Encode::is_utf8($_[0]);
    return $_[0] if defined wantarray;
}

sub utf8_encode {
    utf8::encode($_[0]) if $self->use_utf8 and defined $_[0];
    return $_[0] if defined wantarray;
}

sub uri_escape {
    my $data = shift;
    $self->utf8_encode($data);
    return CGI::Util::escape($data);
}

sub uri_unescape {
    my $data = shift;
    $data = CGI::Util::unescape($data);
    $self->utf8_decode($data);
    return $data;
}

# The CGI.pm version is broken in Chinese
sub html_escape {
    my $val = shift;
    $val =~ s/&/&#38;/g;
    $val =~ s/</&lt;/g; 
    $val =~ s/>/&gt;/g;
    $val =~ s/\(/&#40;/g;
    $val =~ s/\)/&#41;/g;
    $val =~ s/"/&#34;/g;
    $val =~ s/'/&#39;/g;
    return $val;
}

sub html_unescape { 
    CGI::unescapeHTML(shift);
}

sub base64_encode {
    require MIME::Base64;
    MIME::Base64::encode_base64(@_);
}

sub base64_decode {
    require MIME::Base64;
    MIME::Base64::decode_base64(@_);
}

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
