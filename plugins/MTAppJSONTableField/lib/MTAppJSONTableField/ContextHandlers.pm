package MTAppJSONTableField::ContextHandlers;

use strict;
use warnings;

#----- Tags
sub hdlr_jsontableitems {
    my ($ctx, $args, $cond) = @_;

    my $tag_name = $ctx->stash('tag');
    $tag_name = lc $tag_name;
    my $model;
    if ($tag_name eq 'entryjsontableitems') {
        $model = 'entry';
    }
    elsif ($tag_name eq 'pagejsontableitems') {
        $model = 'entry';
    }
    elsif ($tag_name eq 'blogjsontableitems') {
        $model = 'blog';
    }

    my $object = $ctx->stash($model);
    my $jsontable = $object->jsontable;

    my $json;
    my $items;
    if ($jsontable) {
        $json = MT::Util::from_json($jsontable);
        $items = $json->{items};
    }
    else {
        return MT::Template::Context::_hdlr_pass_tokens_else(@_);
    }

    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $out     = '';
    my $i       = 1;
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my $glue    = $args->{glue};

    foreach my $item (@$items) {
        local $vars->{__first__}   = $i == 1;
        local $vars->{__last__}    = $i == scalar @$items;
        local $vars->{__odd__}     = ( $i % 2 ) == 1;
        local $vars->{__even__}    = ( $i % 2 ) == 0;
        local $vars->{__counter__} = $i;

        local $vars->{__jsontable_item__} = $item;

        my $res = $builder->build($ctx, $tokens, $cond);
        return $ctx->error( $builder->errstr ) unless defined $res;
        if ( $res ne '' ) {
            $out .= $glue
                if defined $glue && $i > 1 && length($out) && length($res);
            $out .= $res;
            $i++;
        }
    }

    return $out;
}

sub hdlr_jsontableitem {
    my ($ctx, $args) = @_;

    my $vars = $ctx->{__stash}{vars} or return '';
    my $item = $vars->{__jsontable_item__} or return '';

    my $out = '';
    my $key = $args->{key};
    if ($key) {
        $out = $item->{$key};
    }
    else {
        return $item;
    }
    return $out;
}

sub hdlr_if_jsontableitem {
    my ($ctx, $args, $cond) = @_;

    my $vars = $ctx->{__stash}{vars} or return 0;
    my $item = $vars->{__jsontable_item__} or return 0;
    my $key = $args->{key} or return 0;

    if (defined($item->{$key}) and $item->{$key} ne '') {
        return 1;
    }
    return 0;
}

1;
