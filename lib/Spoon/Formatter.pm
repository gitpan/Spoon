package Spoon::Formatter;
use strict;
use warnings;
use Spoon '-base';

field const class_id  => 'formatter';
field stub 'top_class';

sub init {
    my $self = shift;
}

sub text_to_html {
    my $self = shift;
    $self->text_to_parsed(@_)->to_html;
}

sub text_to_parsed {
    my $self = shift;
    my $text = shift;
    my $block = $self->top_class->new($self->hub);
    $block->text($text);
    $block->parse;
}

sub table {
    my $self = shift;
    $self->{table} ||= $self->format_table;
}

sub format_table {
    my $self = shift;
    my %table = map {
        my $class = $_;
        $class->can('formatter_id') ? ($class->formatter_id, $class) : ();
    } $self->formatter_classes;
    \ %table;
}

package Spoon::Formatter::Unit;
use base 'Spoon';
field const html_start => '';
field const html_end => '';
field const contains_blocks => [];
field const contains_phrases => [];
field stub 'pattern_start';
field const pattern_end => qr/.*?/;

field text => '';
field units => [];
field start_offset => 0;
field start_end_offset => 0;
field end_start_offset => 0;
field end_offset => 0;
field matched => '';

sub parse {
    my $self = shift;
    $self->parse_blocks;
    my $units = $self->units;

    if (@$units == 1 and not ref $units->[0] and $self->contains_phrases) {
        $self->text(shift @$units);
        $self->start_offset(0);
        $self->end_offset(0);
        $self->parse_phrases;
    }
    return $self;
}
    
sub parse_blocks {
    my $self = shift;
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
            my $unit = $class->new;
            $text =~ s/^\s*\n//;
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
        $match->hub($self->hub);
        push @$units, substr($text, 0, $match->start_offset)
          if $match->start_offset;
        $text = substr($text, $match->end_offset);
        push @$units, $match;
    }
    $_->parse for grep ref($_), @{$self->units};
}

sub parse_phrases {
    my $self = shift;
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
            my $unit = $class->new;
            $unit->text($text);
            $unit->match or next;
            $match = $unit
              if not defined $match or 
                 $unit->start_offset < $match->start_offset;
            last unless $match->start_offset;
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
        $match->hub($self->hub);
        push @$units, substr($text, 0, $match->start_offset)
          if $match->start_offset;
        $text = substr($text, $match->start_end_offset);
        $match->text($text);
        $text = $match->parse_phrases;
        push @$units, $match;
    }
}

sub match {
    my $self = shift;
    return unless $self->text =~ $self->pattern_start;
    $self->start_offset($-[0]);
    $self->start_end_offset($+[0]);
    $self->matched(substr($self->text, $-[0], $+[0] - $-[0]));
    return 1;
}

sub set_match {
    my $self = shift;
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
    my $self = shift;
    my $units = $self->units;
    for (my $i = 0; $i < @$units; $i ++) {
        $units->[$i] = $self->escape_html($units->[$i])
          unless ref $units->[$i];
    }
    my $inner = $self->text_filter(join '', 
        map { 
            ref($_) ? $_->to_html : $_; 
        } @{$units}
    );
    $self->html_start . $inner . $self->html_end;
}

sub text_filter { $_[1] }

sub escape_html {
    my $self = shift;
    my $text = shift;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text;
}

package Spoon::WAFL::Block;
use base 'Spoon::Formatter::Unit';
field const formatter_id => 'wafl_block';

package Spoon::WAFL::Phrase;
use base 'Spoon::Formatter::Unit';
field const formatter_id => 'wafl_phrase';

1;

__DATA__

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
