classdef NodeTest < matlab.unittest.TestCase
    % Test class to test the methods of Node objects
    
    
    % setup and close up instructions 
    methods(TestMethodSetup)
        function switch_path(test_case)
            cd('../API');
        end
    end
    
    methods(TestMethodTeardown)
        function clean_up(test_case)
            if exist('../API/test_file.h5', 'file')
                delete('../API/test_file.h5');
            end
            if exist('../API/test_file2.h5', 'file')
                delete('../API/test_file2.h5');
            end
        end
        
        function switch_path_back(test_case)
            cd('../Unit_Tests');
        end
    end
    
    methods(Test)
        
        %% Node constructor
        
        % TO DO
        % linking to a group, variable id
        function test_node_constructor_link_group_var_id(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % TO DO
        % linking to a group, no variable id
        function test_node_constructor_link_group_non_var_id(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % not linking to a group, variable id, valid name
        function test_node_constructor_var_id_valid_name(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % not linking to a group, variable id, no name
        function test_node_constructor_var_id_no_name(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            test_case.verifyError(...
                @()Node(file_obj, sdef, '', '/epochs', {}, 'None', {}), 'Node:unspecified_name');
        end
        
        % not linking to a group, no variable id, no name
        function test_node_constructor_no_var_id_no_name(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:electrode_map', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', {});
        end
        
        % not linking to a group, no variable id, name given
        function test_node_constructor_no_var_id_name(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:electrode_map', file_obj.default_ns, '');
            test_case.verifyError(...
                @()Node(file_obj, sdef, 'Trial_1', '/general/extracellular_ephys', {}, 'None', {}),...
                'Node:fixed_name');
        end
        
     
        
        %% create_link
        
        % link_info empty
        function test_create_link_empty(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % TO DO
        % link to node, string
        function test_create_link_node_string(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % TO DO
        % link to node, hard
        function test_create_link_node_hard(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % ext link, string
        function test_create_link_ext_string(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_string_link.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            link_info = file_obj.extract_link_str('extlink:images.h5,/images/image_1');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', link_info);
            H5F.close(file_obj.file_pointer);
            link = h5read('../API/test_file.h5', '/epochs/Trial_1');
            test_case.verifyEqual(link{1}, 'h5extlink:/images.h5,/images/image_1');
        end
        
        % ext link, hard
        function test_create_link_ext_hard(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            link_info = file_obj.extract_link_str('extlink:images.h5,/images/image_1');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', link_info);
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(info.Groups.Links.Name, 'Trial_1');
            test_case.verifyEqual(info.Groups.Links.Type, 'external link');
            test_case.verifyEqual(info.Groups.Links.Value{1}, '/images/image_1');
            test_case.verifyEqual(info.Groups.Links.Value{2}, 'images.h5');
        end
        
        % invalid link option
        function test_create_link_invalid_link_opt(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            link_info = file_obj.extract_link_str('extlink:images.h5,/images/image_1');
            file_obj.options.link_type = 'supersoft';
            test_case.verifyError(...
                @()Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', link_info), 'create_link:invalid_link');
        end
        
        % invalid key in link_info
        function test_create_link_invalid_key(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            link_info = struct('nolink','to_nowhere');
            test_case.verifyError(...
                @()Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', link_info),...
                'create_link:invalid_key_in_link_info');
        end
        
        %% save_node
        
        % TO DO
        % check for duplicate node
        function test_save_node_duplicate_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % node not custom, nonvalid id
        function test_save_node_nonvalid_id(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            sdef.id = 'nonsense';
            test_case.verifyError(...
                @()Node(file_obj, sdef, '', '/epochs', {}, 'None', {}),'save_node:missing_id');
        end
        
        % node not custom, nonvalid path
        function test_save_node_nonvalid_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            test_case.verifyError(...
                @()Node(file_obj, sdef, 'Trial_1', '/epoch', {}, 'None', {}), 'save_node:no_path');
        end
        
        % node not custom, add valid node in id_lookup
        function test_save_node_non_custom_valid_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            id = node_obj.sdef.id;
            ns = node_obj.sdef.ns;
            test_case.verifyEqual(node_obj.file.id_lookups.(ns).(id).(node_obj.path).created{1}, node_obj);
            test_case.verifyEqual(node_obj.file.all_nodes.(node_obj.path), {node_obj});
        end
        
        % save node in all_nodes, top level, second node
        function test_save_node_all_nodes_top_level_two(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj1 = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            node_obj2 = Node(file_obj, sdef, 'Trial_2', '/epochs', {}, 'None', {});
            test_case.verifyEqual(node_obj2.file.all_nodes.(node_obj2.path), {node_obj1, node_obj2});
        end
        
        % TO DO
        % save node in all_nodes, id not in parent mstats, custom node
        function test_save_node_custom_node_invalid_id(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % TO DO
        % save node in all_nodes, id not in parent mstats
        function test_save_node_invalid_id(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        % TO DO
        % save node in all_nodes, id in parent mstats, custom node
        function test_save_node_valid_custom_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
        end
        
        
         %% add_schema_attribute
        
        % include schema_id
        function test_add_schema_attribute_incl_schema_id(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            node_obj.add_schema_attribute();
            test_case.verifyEqual(node_obj.attributes.h5g8id, struct('value', 'core:<epoch>/'));
        end
        
        % flag_custom_node
        function test_add_schema_attribute_flag_custom_node(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            node_obj.add_schema_attribute();
            test_case.verifyEqual(node_obj.attributes.h5g8id,struct('value', 'custom'));
        end
        %% merge_attrs
        
        % attr in self.attributes, inconsistent value
        function test_merge_attrs_def_new_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.attributes = struct('unit', struct('value', 'mV'), 'conversion', struct('value', 2));
            node_obj.merge_attrs();
            test_case.verifyEqual(node_obj.attributes.unit.nv, 'Volt');
            test_case.verifyEqual(node_obj.attributes.conversion.nv, 1);
        end
        
        % new attr
        function test_merge_attrs_new_attr(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.merge_attrs();
            test_case.verifyEqual(node_obj.attributes.unit.nv, 'Volt');
            test_case.verifyEqual(node_obj.attributes.conversion.nv, 1);
        end

        % attr in self.attributes, consistent value
        function test_merge_attrs_def_old_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.attributes = struct('unit', struct('value', 'Volt'), 'conversion', struct('value', 1));
            node_obj.merge_attrs();
            test_case.verifyEqual(node_obj.attributes.unit.value, 'Volt');
            test_case.verifyEqual(node_obj.attributes.conversion.value, 1);
        end
        
        %% set_attr_values
        
        % TO DO
        % new value
        function test_set_attr_values_nv(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.merge_attrs();
%             node_obj.set_attr_values();
%             h5disp(node_obj.file.file_name);
        end
        
        %TO DO
        % original value
        function test_set_attr_values_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.attributes = struct('unit', struct('value', 'Volt'), 'conversion', struct('value', 1));
            node_obj.merge_attrs();
%             node_obj.set_attr_values();
%             h5disp(node_obj.file.file_name);
        end
        
        % no value
        function test_set_attr_values_None(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.attributes = struct('unit', struct('value', 'None'));
            node_obj.set_attr_values();
            h5disp(node_obj.file.file_name);
        end
        
        %% set_attr
        
        % TO DO
        % not in self.attributes, not custom
        
        %% remember_custom_attribute
        
        % node already has custom attribute
        function test_remember_custom_attribute_cust_attr(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.file.custom_attributes.Trial_1 = struct('type', 'lick_left');
            node_obj.remember_custom_attribute(node_obj.name, 'unit', 'Volt');
            test_case.verifyEqual(node_obj.file.custom_attributes.Trial_1.type, 'lick_left');
            test_case.verifyEqual(node_obj.file.custom_attributes.Trial_1.unit, 'Volt');
            test_case.verifyEqual(numel(fieldnames(node_obj.file.custom_attributes.Trial_1)),2);
        end
        
        % new custom attribute
        function test_remember_custom_attribute_new(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options_custom_flag.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            attrs = struct('unit', 'Volt', 'conversion', 1);
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', attrs, 'None', {});
            node_obj.remember_custom_attribute(node_obj.name, 'unit', 'Volt');
            test_case.verifyEqual(node_obj.file.custom_attributes.Trial_1.unit, 'Volt');
            test_case.verifyEqual(numel(fieldnames(node_obj.file.custom_attributes.Trial_1)),1);
        end
        
        %% merge_attributes_defs
        
        % new field with append string
        function test_merge_attributes_defs_new_field(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest = struct();
            source.field1.value = '+teststring';
            [dest, changes] = node_obj.merge_attribute_defs(dest, source);
            test_case.verifyEqual(dest.field1.value, 'teststring');
            test_case.verifyEqual(changes.field1, 'teststring');
        end
        
        % existing field, but value is new, with append string
        function test_merge_attributes_defs_ex_field_new_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1.test = 'test';
            source.field1.value = '+teststring';
            [dest, changes] = node_obj.merge_attribute_defs(dest, source);
            test_case.verifyEqual(dest.field1.value, 'teststring');
            test_case.verifyEqual(dest.field1.test, 'test');
            test_case.verifyEqual(changes.field1, 'teststring');
        end
        
        % existing field but no value is specified
        function test_merge_attributes_defs_ex_field_no_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1.test = 'test';
            source.field1 = '+teststring';
            test_case.verifyError(...
                @()node_obj.merge_attribute_defs(dest, source),...
                'merge_attribute_functions:unspecified_value');
        end
        
        % existing field with value
        function test_merge_attributes_defs_ex_field_value(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1.value = 'test';
            source.field1.value = '+teststring';
            [dest, changes] = node_obj.merge_attribute_defs(dest, source);
            test_case.verifyEqual(dest.field1.value, 'test,teststring');
            test_case.verifyEqual(changes.field1, 'test,teststring');
        end
        
        % existing field with value, but no value specified
        function test_merge_attributes_defs_ex_field_value_not_spec(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1.value = 'test';
            source.field1.test = '+teststring';
            test_case.verifyError(...
                @()node_obj.merge_attribute_defs(dest, source),...
                'merge_attribute_functions:unspecified_value');
        end
        
        %% append_or_replace
        
        % append case
        function test_append_or_replace_append(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1 = 'teststring';
            source.field1 = '+appendstring';
            key = 'field1';
            dest = node_obj.append_or_replace(dest, source, key, '');
            test_case.verifyEqual(dest.(key), 'teststring,appendstring');
        end
        
        % replace case
        function test_append_or_replace_replace(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1 = 'teststring';
            source.field1 = 'replacestring';
            key = 'field1';
            dest = node_obj.append_or_replace(dest, source, key, '');
            test_case.verifyEqual(dest.(key), 'replacestring');
        end
        
        % replace case, type mismatch
        function test_append_or_replace_type_mismatch(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1 = 'teststring';
            source.field1 = 1;
            key = 'field1';
            test_case.verifyError(...
                @()node_obj.append_or_replace(dest, source, key, ''),...
                'append_or_replace:type_mismatch');
        end
        
        % replace case, invalid type
        function test_append_or_replace_inv_type(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<epoch>/', file_obj.default_ns, '');
            node_obj = Node(file_obj, sdef, 'Trial_1', '/epochs', {}, 'None', {});
            dest.field1 = {'teststring1'};
            source.field1 = {'teststring2'};
            key = 'field1';
            test_case.verifyError(...
                @()node_obj.append_or_replace(dest, source, key, ''),...
                'append_or_replace:invalid_type');
        end
    end
    
end

