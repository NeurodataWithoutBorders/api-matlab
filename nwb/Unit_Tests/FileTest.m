classdef FileTest < matlab.unittest.TestCase
    % Test class to test the methods of File objects
    
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
    
    % Tests
    methods(Test)
        
        %% File constructor

        
        %% validate_options         

        % check with valid options
        function test_with_valid_options(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end 
        
        % check if option is in all_options
        function test_for_invalid_option(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/invalid_option.json'),...
                'validate_options:options_not_valid');
        end
        
        % check if values are valid
        function test_for_invalid_value(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/invalid_value_options.json'),...
                'validate_options:options_not_valid');        
        end
        
        % Add default values for options that were not specified
        function test_for_adding_default_values(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/incomplete_options.json');
            test_case.verifyEqual(file_obj.options.link_type, 'string');
            test_case.verifyEqual(file_obj.options.include_schema_id, 'True');
            test_case.verifyEqual(file_obj.options.schema_id_attr, 'h5g8id');
            test_case.verifyEqual(file_obj.options.flag_custom_nodes, 'True');
            test_case.verifyEqual(file_obj.options.default_compress_size, 512);
        end
        
        %% validate validate_ddef
        
        % check for default namespace
        function test_for_default_namespace(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core_missing_dns.json', 'core', '../Test_Files/all_valid_options.json'),...
                'validate_ddef:missing_namespace');
        end
        
        % check for structures
        function test_for_missing_structures(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core_nostr.json', 'core', '../Test_Files/all_valid_options.json'),...
                'validate_ddef:invalid_data_definition');    
        end
        
        % check for locations
        function test_for_missing_locations(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core_noloc.json', 'core', '../Test_Files/all_valid_options.json'),...
                'validate_ddef:invalid_data_definition');
        end
        
        % both missing
        function test_for_missing_structures_and_locations(test_case)
            test_case.verifyError(...
                @()File('test_file.h5', '../Test_Files/nwb_core_nostr_noloc.json', 'core', '../Test_Files/all_valid_options.json'),...
                'validate_ddef:invalid_data_definition');
        end
       
        %% create_output_file
        
        % create file that should work
        function create_h5_file(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.file_name = 'test_file2.h5';
            file_obj.create_output_file;
            test_case.verifyEqual(H5I.is_valid(file_obj.file_pointer),1);
        end
        
        % create file that should not work
        function fail_to_create_h5_file(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.file_name = 'test_file2.h5';
            file_obj.create_output_file;
            test_case.verifyError(...
                @()create_output_file(file_obj), 'create_output_file:unable_to_open_file');
        end
        
        %% close
        
        % test if file gets closed
        function test_close_file(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.close;
            test_case.verifyEqual(H5I.is_valid(file_obj.file_pointer),0);
        end
        
        %% mk_id_lookups
        
        % test for extra ns
        function test_mk_id_lookups_extra_ns(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core_extra_ns.json', 'core', '../Test_Files/all_valid_options.json');
            id_lookups = file_obj.mk_id_lookups();
            test_case.verifyEqual(fieldnames(id_lookups.extra.neurodata_version), {'x0x2F_'});
            test_case.verifyEqual(id_lookups.extra.neurodata_version.x0x2F_.type, 'dataset' );
            test_case.verifyEqual(id_lookups.extra.neurodata_version.x0x2F_.qty, '!');
            test_case.verifyEqual(id_lookups.extra.neurodata_version.x0x2F_.created, []);
        end
        
        %% mk_id_lookup
        
        % test valid input
        function test_mk_id_lookup_valid_input(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            id_lookup = file_obj.mk_id_lookup('core');
            test_case.verifyEqual(fieldnames(id_lookup.neurodata_version), {'x0x2F_'});
            test_case.verifyEqual(id_lookup.neurodata_version.x0x2F_.type, 'dataset' );
            test_case.verifyEqual(id_lookup.neurodata_version.x0x2F_.qty, '!');
            test_case.verifyEqual(id_lookup.neurodata_version.x0x2F_.created, []);
            test_case.verifyEqual(id_lookup.x0x3C_image_0x3E_.x0x2F_acquisition_0x2F_images.qty, '*');
            test_case.verifyEqual(id_lookup.x0x3C_epoch_0x3E__0x2F_.x0x2F_epochs.type, 'group');
        end
        
        % test for missing "structures"
        function test_mk_id_lookup_missing_structures(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.ddef.core = rmfield(file_obj.ddef.core, 'structures');
            test_case.verifyError(@()file_obj.mk_id_lookup('core'), 'mk_id_lookup:missing_structures');
        end
        
        % test for missing "locations"
        function test_mk_id_lookup_missing_locations(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.ddef.core = rmfield(file_obj.ddef.core, 'locations');
            test_case.verifyError(@()file_obj.mk_id_lookup('core'), 'mk_id_lookup:missing_locations');
        end
        
        % test for entry mismatch
        function test_mk_id_lookup_entry_mismatch(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.ddef.core.locations.extra = {'invalid entry'};
            test_case.verifyError(@()file_obj.mk_id_lookup('core'), 'mk_id_lookup:structure_location_mismatch');
        end
        
        %% get_sdef
        
        % valid qid
        function test_get_sdef_valid_qid(test_case)
             file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
             sdef = file_obj.get_sdef('core:session_id', 'core');
             test_case.verifyEqual(sdef.type, 'dataset');
             test_case.verifyEqual(sdef.qid, 'core:session_id');
             test_case.verifyEqual(sdef.id, 'session_id');
             test_case.verifyEqual(sdef.ns, 'core');
             test_case.verifyEqual(sdef.df.data_type, 'text');
             test_case.verifyEqual(sdef.df.description, 'Lab-specific ID for the session.');
        end
        
        % invalid qid, no message
        function test_get_sdef_inv_qid_no_msg(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('nonsense', 'core');
            test_case.verifyEqual(sdef, {});
        end
        
        % invalid qid, nmessage
        function test_get_sdef_inv_qid_msg(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.get_sdef('nonsense', 'core', 'nonsense input'), 'get_sdef:strucure_not_in_ns');
        end
        
 
        
        %% parse_qty
        
        % test input with quantifier
        function test_parse_qty_with_quantifier(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            [id, qty] = file_obj.parse_qty('neurodata_version!', '?');
            test_case.verifyEqual(id, 'neurodata_version');
            test_case.verifyEqual(qty, '!');
        end
        
        % test input without quantifier
        function test_parse_qty_without_quantifier(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            [id, qty] = file_obj.parse_qty('start_session_time', '?');
            test_case.verifyEqual(id, 'start_session_time');
            test_case.verifyEqual(qty, '?');
            [id, qty] = file_obj.parse_qty('neurodata_version', 'l');
            test_case.verifyEqual(id, 'neurodata_version');
            test_case.verifyEqual(qty, 'l');
        end
        
        % test invalid input
        function test_parse_qty_invalid_expr(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.parse_qty('****', '?'), 'parse_qty:no_match');
        end
        
        %% parse_qid
        
        % valid qid with namespace
        function test_parse_qid_valid_with_ns(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core_extra_ns.json', 'core', '../Test_Files/all_valid_options.json');
            [ns, id] = file_obj.parse_qid('core: <timestamps>/', 'core');
            test_case.verifyEqual(id, '<timestamps>/');
            test_case.verifyEqual(ns, 'core');
            [ns, id] = file_obj.parse_qid(' extra: neurodata_version ', 'core');
            test_case.verifyEqual(id, 'neurodata_version');
            test_case.verifyEqual(ns, 'extra');  
        end
        
        % valid qid without namespace
        function test_parse_qid_valid_no_ns(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core_extra_ns.json', 'core', '../Test_Files/all_valid_options.json');
            [ns, id] = file_obj.parse_qid('neurodata_version', 'core');
            test_case.verifyEqual(id, 'neurodata_version');
            test_case.verifyEqual(ns, 'core');
        end
        
        % invalid qid
        function test_parse_qid_invalid_qid(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core_extra_ns.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(@()file_obj.parse_qid('', 'core'), 'parse_qid:no_match');
        end
        
        %% validate_ns
        
        % test with valid ns
        function test_validate_ns_valid_ns(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core_extra_ns.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.validate_ns('core');
            file_obj.validate_ns('extra');
        end
        
        % test for unknown namespace
        function test_validate_ns_invalid_ns(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(@()file_obj.validate_ns('unknown'), 'validate_ns:undefined_ns');
        end
        
        %% make_group
        
        % new group, no link
        function test_make_group_new_group(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.make_group('<module>', 'Module');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(info.Groups.Name, '/processing');
            test_case.verifyEqual(info.Groups.Groups.Name, '/processing/Module');
            test_case.verifyEqual(info.Groups.Groups.Attributes(2).Name, 'neurodata_type');
            test_case.verifyEqual(info.Groups.Groups.Attributes(2).Value, 'Module');
        end
        
        % TO DO: create content, then don't overwrite
        % make group twice, abort true
        function test_make_group_dupl_abort(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
%             file_obj.make_group();
        end
        
         % TO DO: create content, then overwrite
        % make group twice, abort false
        function test_make_group_dupl_no_abort(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
%             file_obj.make_group();
        end
        
        % create group that links to another group
        function test_make_group_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.make_group('<module>', 'Module_1');
            file_obj.make_group('<module>', 'Module_2', '', {},'link:/processing/Module_1');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5'); 
            test_case.verifyEqual(info.Groups.Groups.Name, '/processing/Module_1');
            test_case.verifyEqual(info.Groups.Links.Name, 'Module_2');
            test_case.verifyEqual(info.Groups.Links.Type, 'soft link');
            test_case.verifyEqual(info.Groups.Links.Value, {'/processing/Module_1'});
        end
        
        
        
        %% get_existing_group
        
        % TO DO
        % test with existing group
        function test_get_existing_group_exist_group(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        
        % test with non-existing group
        function test_get_existing_group_non_exist_group(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            node = file_obj.get_existing_group('/epochs', '<epoch>/', 'Trial_1');
            test_case.verifyEqual(node, {});
        end
        
        %% deduce_path
        
        % test for valid input
        function test_deduce_path_valid_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            % multiple options, given path
            path = file_obj.deduce_path('<TimeSeries>/', 'core', '/stimulus/presentation');
            test_case.verifyEqual(path, '/stimulus/presentation');
            % one option, no path
            path = file_obj.deduce_path('electrode_map', 'core', '');
            test_case.verifyEqual(path, '/general/extracellular_ephys');
        end
        
        % test for non valid path
        function test_deduce_path_nonvalid_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.deduce_path('<TimeSeries>/', 'core','/general/extracellular_ephys'), ...
                'deduce_path:path_not_in_ns');
        end
        
        % test for required path specification
        function test_deduce_path_no_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.deduce_path('<TimeSeries>/', 'core', ''), 'deduce_path:path_not_specified');
        end
        
        %% extract_link_info
        
        % TO DO
        % method 1
        function test_extract_link_info_method1(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        % method 2
        function test_extract_link_info_method2(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            link_info = file_obj.extract_link_info('extlink:image_1,/user/images/', '','');
            test_case.verifyEqual(link_info.extlink, {'image_1', '/user/images/'});
        end
        % method 3
        function test_extract_link_info_method3(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            link_info = file_obj.extract_link_info('','extlink:image_1,/user/images/', '');
            test_case.verifyEqual(link_info.extlink, {'image_1', '/user/images/'});
        end
        
        %% extract_link_str
        
        % TO DO
        % valid link, node found
        function test_extract_link_str_link_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end 
        
        % valid link, node not found
        function test_extract_link_str_link_no_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.extract_link_str('link:/epochs/Trial_1/'), 'get_node:unable_to_get_node')
        end
        % invalid link
        function test_extract_link_str_invalid_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.extract_link_str('link:/epo chs/Trial_1/'), 'extract_link_str:invalid_path');
        end
        % valid external link
        function test_extract_link_str_ext_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            link_info = file_obj.extract_link_str('extlink:image_1,/user/images/');
            test_case.verifyEqual(link_info.extlink,  {'image_1', '/user/images/'});
        end
        % invalid external link
        function test_extract_link_str_invalid_ext_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.extract_link_str('extlink:image_1,,/user/images/'), 'extract_link_str:invalid_ext_path');
        end
        % no link pattern
        function test_extract_link_str_no_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            link_info = file_obj.extract_link_str('nonsense');
            test_case.verifyEqual(link_info, {});
        end
        
        
        %% validate_custom_name
        
        % valid custom name
        function test_validate_custom_name_valid_name(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.validate_custom_name('custom_name');
        end
        
        % invalid custom name
        function test_validate_custom_name_invalid_name(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(@()file_obj.validate_custom_name('???'), 'validate_custom_name:invalid_custom_name');
        end
        
        %% validate_path
        
        % valid path
        function test_validate_path_valid(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.validate_path('/epochs/Trial_1/');
        end
        
        % path with spaces
        function test_validate_path_invalid(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.validate_path('/epochs/ Trial_1 /'), 'validate_path:path_with_spaces');
        end
        
        %% make_full_path
        
        % empty path
        function test_make_full_path_empty_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            full_path = file_obj.make_full_path('', 'file');
            test_case.verifyEqual(full_path, 'file');
        end
        
        % valid path with //
        function test_make_full_path_double_slash(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            full_path = file_obj.make_full_path('//path//', 'file');
            test_case.verifyEqual(full_path, '/path/file');
        end
        
        % invalid path
        function test_make_full_path_invalid_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.make_full_path('/ path /', 'file'), 'validate_path:path_with_spaces');
        end
        
        
        %% get_custom_node_info
        
        % creating pre-defined node in custom location
        function test_get_custom_node_info_pre_def(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            [sdef, name, path] = ...
                file_obj.get_custom_node_info('<module>', '/', 'Module', '/custom_modules', 'None');
            test_case.verifyEqual(sdef.qid, '<module>/');
            test_case.verifyEqual(sdef.df.attributes.interfaces.data_type, 'text');
            test_case.verifyEqual(sdef.custom, 'true');
            test_case.verifyEqual(name, 'Module');
            test_case.verifyEqual(path, '/custom_modules');
        end
        
        % creating pre-defined node in custom location, empty_path
        function test_get_custom_node_info_pre_def_empty_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            test_case.verifyError(...
                @()file_obj.get_custom_node_info('<module>', '/', 'Module', '', 'None'),...
                'get_custom_node_info:empty_path');      
        end
        
        % creating custom node in custom location, parent
        function test_get_custom_node_info_custom_parent(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            Modules.full_path = '/Custom_Groups/Modules';
            [sdef, name, path] = file_obj.get_custom_node_info('Custom_Module_1', '/', '', '', Modules);
            test_case.verifyEqual(sdef.custom, 'true');
            test_case.verifyEqual(sdef.qid, 'Custom_Module_1');
            test_case.verifyEqual(sdef.df, struct());
            test_case.verifyEqual(name, '');
            test_case.verifyEqual(path, 'x0x2F_Custom_Groups_0x2F_Modules_0x2F_');
        end
        
        % creating custom node in custom location, parent, absolute path
        function test_get_custom_node_info_parent_abs_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            Modules.full_path = '/Custom_Groups/Modules';
            test_case.verifyError(...
                @()file_obj.get_custom_node_info('Custom_Module_1', '/', '', '/full_path', Modules),...
                'get_custom_node_info:invalid_full_path');
        end
        
        % creating custom node in custom location, no parent, relative
        % path, no __custom
        function test_get_custom_node_info_rel_path_no_cust_loc(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.id_lookups.core = rmfield(file_obj.id_lookups.core, 'x_custom');
            test_case.verifyError(...
                @()file_obj.get_custom_node_info('Custom_Module_1', '/', '', 'rel_path', 'None'),...
                'get_custom_node_info:invalid_relative_path');
        end
        
        % TO DO
        % creating custom node in custom location, no parent, __custom in
        % multiple locations
        function test_get_custom_node_info_mult_cust_loc(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        
        % TO DO
        % creating custom node in custom location, no parent, relative
        % path, __custom given
        function test_get_custom_node_info_rel_path_cust_loc(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        
        % TO DO
        % creating custom node in custom location, no parent,no pattern
        % match for full_path
        function test_get_custom_node_info_invalid_full_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        
        % creating custom node in custom location, no parent, valid
        % full_path
        function test_get_custom_node_info_no_parent_valid_path(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            [sdef, name, path] = ...
                file_obj.get_custom_node_info('Custom_Module_1', '/', '', '/Modules', 'None');
            test_case.verifyEqual(sdef.custom, 'true');
            test_case.verifyEqual(sdef.qid, 'Custom_Module_1');
            test_case.verifyEqual(sdef.df, struct());
            test_case.verifyEqual(name, '');
            test_case.verifyEqual(path, 'x0x2F_Modules_0x2F_');
        end
        
        %% make_custom_group
        
        % make common group in custom location
        function test_make_custom_group_pre_def(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            grp = file_obj.make_custom_group('<module>', 'Module', '/custom_modules');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(info.Groups.Name, '/custom_modules');
            test_case.verifyEqual(info.Groups.Groups.Name, '/custom_modules/Module');
        end
        
        % make custom group in custom location
        function test_make_custom_group_(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            grp = file_obj.make_custom_group('Custom_Module_1', '', '/custom_modules');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(info.Groups.Name, '/custom_modules');
            test_case.verifyEqual(info.Groups.Groups.Name, '/custom_modules/Custom_Module_1');
        end
        
        %% set_dataset
        
        % top level
        function test_set_dataset(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.set_dataset('identifier', 'Exp_1', '','', {'descr', 'Exp number'});
            H5F.close(file_obj.file_pointer)
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Datasets.Name, 'identifier');
            data = h5read(file_obj.file_name, '/identifier');
            attr = h5readatt(file_obj.file_name, '/identifier', 'descr');
            test_case.verifyEqual(data, {'Exp_1'});
            test_case.verifyEqual(attr, 'Exp number');
        end
        
        % multi-level
        function test_set_dataset_multi_level(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.set_dataset('electrode_map', [0 1]);
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/general/extracellular_ephys');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'electrode_map');
            data = h5read(file_obj.file_name, '/general/extracellular_ephys/electrode_map');
            test_case.verifyEqual(data, [0 1]);
        end
        
        % link
        function test_set_dataset_link(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            ident = file_obj.set_dataset('identifier', 'Exp_1');
%             file_obj.set_dataset('neurodata_version','link:/identifier');
            file_obj.set_dataset('neurodata_version',ident);
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Links.Name, 'neurodata_version');
            test_case.verifyEqual(info.Links.Type, 'soft link');
            test_case.verifyEqual(info.Links.Value, {'/identifier'});
            data = h5read(file_obj.file_name, '/neurodata_version');
            test_case.verifyEqual(data, {'Exp_1'});
        end
        
        %% set_custom_dataset
        function test_set_custom_dataset(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.set_custom_dataset('custom_dataset', 'custom', '', '/custom_group');
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Name, '/custom_group');
            test_case.verifyEqual(info.Groups.Datasets.Name, 'custom_dataset');
            data = h5read(file_obj.file_name, '/custom_group/custom_dataset');
            test_case.verifyEqual(data, {'custom'});
        end
        
        
        %% validate_file
        
        % custom groups
        function test_validate_file_custom_nodes(test_case)
           file_obj = ...
               File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
           file_obj.set_custom_dataset('custom_dataset', 'custom', '', '/custom_group');
           grp = file_obj.make_custom_group('Custom_Module_1', '', '/custom_modules');
        end
        
        % empty nwb file
        
        % group and datsets missing
        function test_validate_file(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            g = file_obj.make_group('<module>', 'Module');
            g.make_group('BehavioralEvent');
            for i = 1:10
                name = ['Trial_' num2str(i)];
                group_obj = file_obj.make_group('<epoch>', name);
                group_obj.set_dataset('start_time', i*15);
                group_obj.set_dataset('stop_time','link:/epochs/Trial_1/start_time');
            end
            file_obj.validate_file();
        end
        
        %% validate_nodes
        
        % custom nodes
        
        % add missing nodes
        
        %% report_problems
        
        % more than 30 nodes
        function test_report_problems(test_case)
        file_obj = ...
            File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            g = file_obj.make_group('<module>', 'Module');
            g.make_group('BehavioralEvent');
            for i = 1:40
                name = ['Trial_' num2str(i)];
                group_obj = file_obj.make_group('<epoch>', name);
                group_obj.set_dataset('start_time', i*15);
                group_obj.set_dataset('stop_time','link:/epochs/Trial_1/start_time');
            end
            file_obj.validate_file();
        end
        
        %% get_node
        
        % TO DO
        % test for existing node
        function test_get_node_exising_node(test_case)
             file_obj = ...
                 File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
        end
        
        % test for non-existing node
        function test_get_node_non_existing_node(test_case)
             file_obj = ...
                 File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
             node = file_obj.get_node('/general', false);
             test_case.verifyEqual(node, {});
        end
        
        % test for non-existing node with abort
        function test_get_node_non_existing_node_abort(test_case)
             file_obj = ...
                 File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
             test_case.verifyError(...
                 @()file_obj.get_node('/general', true), 'get_node:unable_to_get_node');
        end
    end
    
end

