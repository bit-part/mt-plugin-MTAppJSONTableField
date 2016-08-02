package MTAppJSONTableField::Plugin;

use strict;
use warnings;

sub plugin {
    return MT->component('MTAppJSONTableField');
}

#----- Transformer
sub hdlr_insert_jsontable {
    my ($cb, $app, $param, $tmpl) = @_;

    # Get a host node
    my $cb_method = $cb->method;
    my $host_node_id;
    my $label_class;
    my $object_type;
    if ($cb_method eq 'MT::App::CMS::template_param.edit_entry') {
        $object_type = $param->{object_type};
        $host_node_id = 'text';
        $label_class = 'no-header';
    }
    elsif ($cb_method eq 'MT::App::CMS::template_param.cfg_prefs') {
        $object_type = 'blog';
        $host_node_id = 'description';
        $label_class = 'left-label';
    }
    my $host_node = $tmpl->getElementById($host_node_id);

    # Create a new node
    my $new_node_id = 'jsontable';
    my $new_node = $tmpl->createElement(
        'app:setting', {
            id => 'jsontable',
            label => 'JSONTable',
            label_class => $label_class
        });

    my $plugin = plugin();
    my $blog_id = $app->blog->id;
    my $scope = 'blog:' . $blog_id;
    my $setting_gui = $plugin->get_config_value('mtappjsontable_field_setting_' . $object_type . '_gui', $scope);
    my $setting_header = $plugin->get_config_value('mtappjsontable_field_setting_' . $object_type . '_header', $scope);
    my $setting_general = $plugin->get_config_value('mtappjsontable_field_setting_' . $object_type . '_general', $scope);

    my $innerHTML = <<"EOS";
<textarea name="$new_node_id" id="$new_node_id" class="text low" mt:watch-change="1"><mt:var name="$new_node_id" escape="html"></textarea>
EOS
    if ($setting_gui and $setting_header) {
        # Get JSONTable header settings
        my %op_inputType;
        my %op_header;
        my @op_headerOrder;

        my $setting_header_json = MT::Util::from_json($setting_header);
        my $setting_header_items = $setting_header_json->{items};
        foreach my $setting_header_item (@$setting_header_items) {
            my $_header_key  = $setting_header_item->{headerKey};
            my $_header_name = $setting_header_item->{headerName};
            my $_header_type = $setting_header_item->{headerType};
            push(@op_headerOrder, $_header_key);
            $op_inputType{ $_header_key } = $_header_type;
            $op_header{ $_header_key } = $_header_name;
        }

        # Get JSONTable general settings
        my $setting_general_json = MT::Util::from_json($setting_general);
        my $setting_general_item = $setting_general_json->{items}->[0];

        my %options = (
            'inputType' => \%op_inputType || 'null',
            'header' => \%op_header || 'null',
            'headerOrder' => \@op_headerOrder || 'null',
            'caption' => $setting_general_item->{caption} ? $setting_general_item->{caption} : 'null',
            'headerPosition' => $setting_general_item->{headerPosition} ? $setting_general_item->{headerPosition} : 'top',
            'footer' => $setting_general_item->{footer} ? $setting_general_item->{footer} : 'false',
            'edit' => $setting_general_item->{edit} ? $setting_general_item->{edit} : 'true',
            'add' => $setting_general_item->{add} ? $setting_general_item->{add} : 'false',
            'clear' => $setting_general_item->{clear} ? $setting_general_item->{clear} : 'true',
            'cellMerge' => $setting_general_item->{cellMerge} ? $setting_general_item->{cellMerge} : 'false',
            'sortable' => $setting_general_item->{sortable} ? $setting_general_item->{sortable} : 'false',
            'listingCheckbox' => 'false',
            'listingCheckboxType' => 'checkbox',
            'listingTargetKey' => 'null',
            'listingTargetEscape' => 'false',
            'debug' => $setting_general_item->{debug} ? $setting_general_item->{debug} : 'false'
        );
        my $options_str = MT::Util::to_json(\%options);
        $options_str =~ s/^\{|\}$//g;
        $options_str =~ s/"true"/true/g;
        $options_str =~ s/"false"/false/g;
        $options_str =~ s/"null"/null/g;

        my %options_objects = (
            'optionButtons' => $setting_general_item->{optionButtons} ? $setting_general_item->{optionButtons} : 'null',
            'cbAfterBuild' => $setting_general_item->{cbAfterBuild} ? $setting_general_item->{cbAfterBuild} : 'null',
            'cbBeforeAdd' => $setting_general_item->{cbBeforeAdd} ? $setting_general_item->{cbBeforeAdd} : 'null',
            'cbAfterAdd' => $setting_general_item->{cbAfterAdd} ? $setting_general_item->{cbAfterAdd} : 'null',
            'cbBeforeClear' => $setting_general_item->{cbBeforeClear} ? $setting_general_item->{cbBeforeClear} : 'null',
            'cbAfterSelectRow' => $setting_general_item->{cbAfterSelectRow} ? $setting_general_item->{cbAfterSelectRow} : 'null',
            'cbAfterSelectColumn' => $setting_general_item->{cbAfterSelectColumn} ? $setting_general_item->{cbAfterSelectColumn} : 'null',
        );
        my $options_objects_str = '';
        foreach my $key (keys(%options_objects)) {
            $options_objects_str .= '"' . $key . '"' . ':' . $options_objects{$key} . ',';
        }
        $options_str = $options_objects_str . $options_str;

        $innerHTML .= <<"EOS";
<script type="text/javascript">
jQuery('#$new_node_id').MTAppJSONTable({ $options_str });
</script>
EOS

        if ($object_type eq 'blog') {
            $innerHTML .= <<"EOS";
    <script type="text/javascript">
    jQuery('#jsontable-field div.mtapp-json-table').width('75%');
    </script>
EOS
        }
    }


    $new_node->innerHTML($innerHTML);

    # Insert new node
    $tmpl->insertAfter($new_node, $host_node);

    1;
}

sub hdlr_data_api_jsontable {
    my ($obj) = @_;
    my $jsontable = $obj->jsontable
      or return [];
    my $json = MT::Util::from_json($jsontable);
    my $items = $json->{items};
    return $items;
}

sub hdlr_data_api_pre_load_filtered_list {
    my ($cb, $app, $filter, $options) = @_;

    return 1 if exists $options->{total};
    if (my $value = $app->param('jsontable')) {
        $filter->append_item({
            'type' => 'jsontable',
            'args' => {
                'string' => $value,
                'option' => 'contains',
            }
        });
    }
}

1;
