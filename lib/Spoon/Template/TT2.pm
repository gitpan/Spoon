package Spoon::Template::TT2;
use strict;
use warnings;
use Spoon::Template '-Base';
use Template;

sub render {
    my $template = shift;
    my $directives = {};
    $directives = shift if ref $_[0];

    my $include_path = $self->get_include_path;
    my $output;
    my $t = Template->new({
        %$directives,
        INCLUDE_PATH => $include_path,
#         PLUGINS => $self->plugins,
        OUTPUT => \$output,
        TOLERANT => 0,
    });
    eval {
        $t->process($template, {@_}) or die $t->error;
    };
    die "Template Toolkit error:\n$@" if $@;
    return $output;
}

# sub plugins {
#     $self->hub->registry->template_lookup;
# }

1;
