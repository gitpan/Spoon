package Spoon::Formatter;
use strict;
use warnings;
use Spoon '-Base';

const class_id  => 'formatter';
stub 'top_class';

sub text_to_html {
    require CGI;
    $self->text_to_parsed(@_)->to_html;
}

sub text_to_parsed {
    $self->top_class->new($self->hub, shift)->parse;
}

sub table { $self->{table} ||= $self->create_table }

sub create_table {
    my $class_prefix = $self->class_prefix;
    my %table = map {
        my $class = /::/ ? $_ : "$class_prefix$_";
        $class->can('formatter_id') ? ($class->formatter_id, $class) : ();
    } $self->formatter_classes;
    \ %table;
}

sub wafl_table { $self->{wafl_table} ||= $self->create_wafl_table }

sub create_wafl_table {
    my $class_prefix = $self->class_prefix;
    my %table = map {
        my $class = /::/ ? $_ : "$class_prefix$_";
        $class->can('wafl_id') ? ($class->wafl_id, $class) : ();
    } $self->wafl_classes;
    $self->add_external_wafl(\ %table);
    \ %table;
}

sub add_external_wafl {
    return unless defined $self->hub->registry;
    my $table = shift;
    my $map = $self->hub->registry->lookup->wafl;
    for my $wafl_id (keys %$map) {
        $table->{$wafl_id} = $map->{$wafl_id};
    }
}

sub wafl_classes { () }

package Spoon::Formatter::Unit;
use base 'Spoon';
const formatter_id => '';
const html_start => '';
const html_end => '';
const contains_blocks => [];
const contains_phrases => [];
# stub 'pattern_start'; # XXX messes multiple inheritance
const pattern_end => qr/.*?/;

field text => '';
field units => [];
field start_offset => 0;
field start_end_offset => 0;
field end_start_offset => 0;
field end_offset => 0;
field matched => '';
field 'next_unit';
field 'prev_unit';

sub new() {
    my $class = shift;
    my $self = bless {}, $class;
    $self->hub(shift);
    $self->text(shift);
    return $self;
}

sub parse {
    $self->parse_blocks;
    my $units = $self->units;

    if (@$units == 1 and not ref $units->[0] and @{$self->contains_phrases}) {
        $self->text(shift @$units);
        $self->start_offset(0);
        $self->end_offset(0);
        $self->parse_phrases;
    }
    return $self;
}
    
sub parse_blocks {
    my $text = $self->text;
    $self->text(undef);
    my $units = $self->units;
    my $table = $self->hub->formatter->table;
    my $contains = $self->contains_blocks;
    while ($text) {
        my $match;
        for my $format_id (@$contains) {
            my $class = $table->{$format_id}
              or die "No class for $format_id";
            my $unit = $class->new($self->hub);
            $unit->text($text);
            $unit->match or next;
            $match = $unit
              if not defined $match or 
                 $unit->start_offset < $match->start_offset;
            last unless $match->start_offset;
        }
        if (not defined $match) {
            push @$units, $text;
            last;
        }
        push @$units, substr($text, 0, $match->start_offset)
          if $match->start_offset;
        $text = substr($text, $match->end_offset);
        push @$units, $match;
    }
    for (my $i = 0; $i < @$units; $i++) {
        next unless ref $units->[$i];
        $units->[$i]->next_unit($units->[$i + 1]);
        $units->[$i]->prev_unit($units->[$i - 1]) if $i;
    }
    $_->parse for grep ref($_), @{$self->units};
}

sub match {
    return unless $self->text =~ $self->pattern_block;
    $self->set_match;
}

sub parse_phrases {
    my $text = $self->text;
    $self->text(undef);
    my $units = $self->units;
    my $table = $self->hub->formatter->table;
    my $contains = $self->contains_phrases;
    while ($text) {
        my $match;
        for my $format_id (@$contains) {
            my $class = $table->{$format_id}
              or die "No class for $format_id";
            my $unit = $class->new($self->hub);
            $unit->text($text);
            $unit->match_phrase or next;
            $match = $unit
              if not defined $match or 
                 $unit->start_offset < $match->start_offset;
            last if $match->start_offset == 0;
        }
        if ($self->start_end_offset) {
            if ($text =~ $self->pattern_end) {
                if (not defined $match or $-[0] < $match->start_offset) {
                    push @$units, substr($text, 0, $-[0]);
                    return substr($text, $+[0]);
                }
            }
            else {
                $self->end_offset(length $text);
                push @$units, $text;
                return '';
            }
        }
        if (not defined $match) {
            push @$units, $text;
            return '';
        }
        if ($match->end_start_offset) {
            push @$units, $match;
            $text = substr($text, $match->end_offset);
            next;
        }
        push @$units, substr($text, 0, $match->start_offset)
          if $match->start_offset;
        $text = substr($text, $match->start_end_offset);
        $match->text($text);
        $text = $match->parse_phrases;
        push @$units, $match;
    }
}

sub match_phrase {
    return unless $self->text =~ $self->pattern_start;
    $self->start_offset($-[0]);
    $self->start_end_offset($+[0]);
    $self->matched(substr($self->text, $-[0], $+[0] - $-[0]));
    my $pattern_end = $self->pattern_end
      or return 1;
    return substr($self->text, $+[0]) =~ $pattern_end;
}

sub set_match {
    my ($text, $start, $end) = @_;
    $text = $1 unless defined $text;
    $text = '' unless defined $text;
    $start = $-[0] unless defined $start;
    $end = $+[0] unless defined $end;
    $self->text($text);
    $self->start_offset($start);
    $self->end_offset($end);
    return 1;
}

sub to_html {
    my $units = $self->units;
    for (my $i = 0; $i < @$units; $i ++) {
        $units->[$i] = $self->escape_html($units->[$i])
          unless ref $units->[$i];
    }
    $self->html;
}

sub html {
    my $inner = $self->text_filter(join '', 
        map { 
            ref($_) ? $_->to_html : $_; 
        } @{$self->units}
    );
    $self->html_start . $inner . $self->html_end;
}

sub text_filter { shift }

sub escape_html { $self->html_escape(shift) }

################################################################################
package Spoon::Formatter::Container;
use base 'Spoon::Formatter::Unit';
sub contains_blocks {
    $self->hub->formatter->all_blocks;
}

################################################################################
package Spoon::Formatter::Block;
use base 'Spoon::Formatter::Unit';
sub contains_phrases {
    $self->hub->formatter->all_phrases;
}

################################################################################
package Spoon::Formatter::Phrase;
use base 'Spoon::Formatter::Unit';
sub contains_phrases {
    my $id = $self->formatter_id;
    [ grep {$_ ne $id} @{$self->hub->formatter->all_phrases} ];
}

################################################################################
package Spoon::Formatter::Wafl;
use Spoon::Base '-base';
const contains_phrases => [];

sub bless_wafl_class {
    my $package = caller;
    my $class = $self->hub->formatter->wafl_table->{$self->method};
    if (ref $class) {
        my $class_id;
        ($class_id, $class) = @$class;
        $self->hub->load_class($class_id);
    }
    bless $self, $class
      if defined $class and $class->isa($package);
    return 1;
}

################################################################################
package Spoon::Formatter::WaflBlock;
use base 'Spoon::Formatter::Wafl';
use base 'Spoon::Formatter::Block';
const formatter_id => 'wafl_block';
const html_end => "</div>\n";
field 'method';
field 'arguments';

sub html_start {
    '<div class="' . $self->method . '">';
}

sub match {
    return unless
      $self->text =~ /(?:^\.([\w\-]+)\ *\n)((?:.*\n)*?)(?:^\.\1\ *\n|\z)/m;
    $self->set_match($2);
    $self->method($1);
    $self->bless_wafl_class;
}

sub block_text {
    $self->units->[0];
}

################################################################################
package Spoon::Formatter::WaflPhrase;
use base 'Spoon::Formatter::Wafl';
use base 'Spoon::Formatter::Unit';
const formatter_id => 'wafl_phrase';
const pattern_start =>
  qr/(^|(?<=[\s\-]))\{\w+(\s*:)?\s*.*?\}(?=[^A-Za-z0-9]|\z)/;
field 'method';
field 'arguments';

sub html_start {
    '<span class="' . $self->method . '">' . $self->arguments . '</span>';
}

sub match_phrase {
    return unless super;
    return unless $self->matched =~ /^\{([\w\-]+)(?:\s*\:)?\s*(.*)\}$/;
    $self->arguments($2);
    $self->method($1);
    $self->bless_wafl_class;
}

sub wafl_error {
    join '',
      '<span class="wafl_error">{',
      $self->method,
      ': ',
      $self->arguments,
      '}</span>';
}

1;

__END__

=head1 NAME 

Spoon::Formatter - Spoon Formatter Base Class

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
