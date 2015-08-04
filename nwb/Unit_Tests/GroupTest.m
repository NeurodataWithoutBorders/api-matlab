classdef GroupTest < matlab.unittest.TestCase
    % Test class to test the methods of Dataset objects
    
    
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
        
        %% Group constructor
        
        % test if group is in file and has expected attributes
        function test_group_constructor(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<TimeSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'TimeSeries', '/acquisition/timeseries', {}, 'None', {});
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(info.Groups.Name, '/acquisition');
            test_case.verifyEqual(info.Groups.Groups.Name, '/acquisition/timeseries');
            test_case.verifyEqual(info.Groups.Groups.Groups.Name, '/acquisition/timeseries/TimeSeries');
            test_att = h5readatt(file_obj.file_name, '/acquisition/timeseries/TimeSeries', 'ancestry');
            test_case.verifyEqual(test_att, 'TimeSeries');
        end
        %% add_parent_attributes
        
        % TO DO
        
        
        
        %% get_expanded_def_and_includes
        
        % merge
        function test_get_expanded_def_and_includes(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<TimeSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'TimeSeries', '/acquisition/timeseries', {}, 'None', {});
            group_obj.get_expanded_def_and_includes();
            test_case.verifyEqual(fieldnames(group_obj.expanded_def.timestamps),...
                {'description'; 'data_type'; 'unit'; 'dimensions'; 'semantic_type'; 'attributes'});
            test_case.verifyEqual(group_obj.expanded_def.num_samples.data_type, 'int');
            test_case.verifyEqual(group_obj.expanded_def.data.attributes.unit.data_type, 'text'); 
        end
        
        % no merge, attributes update
        function test_get_expanded_def_and_includes_no_merge_attrs(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<module>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'Module', '/processing', {}, 'None', {});
            group_obj.get_expanded_def_and_includes();
            test_case.verifyEqual(group_obj.attributes.interfaces.data_type, 'text');
            test_case.verifyEqual(group_obj.attributes.source.data_type, 'text');
            test_case.verifyEqual(group_obj.attributes.source.description,...
                'Source of data that was processed');
            test_case.verifyEqual(group_obj.attributes.description.data_type, 'text');
            test_case.verifyEqual(group_obj.attributes.neurodata_type.data_type, 'text');
            test_case.verifyEqual(group_obj.attributes.neurodata_type.value, 'Module');
        end
        
        %% get_member_stats
        
        
        % running through expanded_def
        function test_get_member_stats_valid_ex(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<TimeSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'TimeSeries', '/acquisition/timeseries', {}, 'None', {});
            group_obj.get_expanded_def_and_includes();
            group_obj.get_member_stats();
            test_case.verifyEqual(fieldnames(group_obj.mstats), ...
                {'timestamps';'starting_time';'num_samples';'data'});
            test_case.verifyEqual(group_obj.mstats.num_samples.df.data_type, 'int');
            test_case.verifyEqual(group_obj.mstats.data.df.dimensions, {'timeIndex'});
        end
        
        % duplicate in include
        function test_get_member_stats_dupl_incl(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<module>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'Module', '/processing', {}, 'None', {});
            group_obj.expanded_def = struct(Utils.convert_uc_to_utf('<TimeSeries>/'),...
                struct('data', struct('semantic_type', '+BehavorialEvent')));
            group_obj.includes = struct(Utils.convert_uc_to_utf('<TimeSeries>/'),...
                struct('data', struct('semantic_type', '+BehavorialEvent')));
            test_case.verifyError(@()group_obj.get_member_stats(),...
                'get_member_stats:duplicate_id');
        end
        
        % running through include, modifiers>0
        function test_get_member_stats_valid_incl(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<module>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'Module', '/processing', {}, 'None', {});
            group_obj.includes = struct(Utils.convert_uc_to_utf('<TimeSeries>/'),...
                struct('data', struct('semantic_type', '+BehavorialEvent')));
            group_obj.get_member_stats();
            test_case.verifyEqual(fieldnames(group_obj.mstats.x0x3C_TimeSeries_0x3E__0x2F_.df.data),...
                {'dimensions'; 'data_type'; 'semantic_type'});
            test_case.verifyEqual(group_obj.mstats.x0x3C_TimeSeries_0x3E__0x2F_.df.merge,...
                {'<timestamps>/'}),
            test_case.verifyEqual(...
                group_obj.mstats.x0x3C_TimeSeries_0x3E__0x2F_.df.attributes.ancestry.value, 'TimeSeries');
            
        end
        
        %% process_merge
        function test_process_merge(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('core:<module>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'Module', '/processing', {}, 'None', {});
            group_obj.expanded_def = struct();
            group_obj.includes = struct();
            group_obj.process_merge(group_obj.expanded_def, {'<PatchClampSeries>/'}, group_obj.includes);
            test_case.verifyEqual(fieldnames(group_obj.expanded_def),...
                {'attributes'; 'data'; 'electrode'; 'gain'; 'initial_access_resistance'; 'seal'; ...
                'timestamps'; 'starting_time_0x3F_'; 'num_samples'});
            test_case.verifyEqual(group_obj.expanded_def.data.data_type, 'number');
            test_case.verifyEqual(group_obj.expanded_def.seal.unit, 'Ohm');
        end
            
        
        %% find_all_merge
        
        % check with multiple output
        function test_find_all_merge(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = ...
                Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            initial_to_merge = group_obj.sdef.df.merge;
            checked = group_obj.find_all_merge(initial_to_merge);
            test_case.verifyEqual(checked, {'<ImageSeries>/','<timestamps>/'});
        end
        
        %% merge_def
        
        % description
        function test_merge_def_descr(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            group_obj.description = {'old description'};
            sdef_t = struct('df',struct('description', 'new description'), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes)
            test_case.verifyEqual(...
                group_obj.description, {'old description', 'core:test_id- new description'});
        end
        
        % parent_attributes
        function test_merge_def_parent_att(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = ...
                Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            group_obj.parent_attributes = struct('att0', 'oldatt');
            sdef_t = ...
                struct('df',struct('parent_attributes', struct('att1', 'test_att')), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes)
            test_case.verifyEqual(group_obj.parent_attributes, struct('att0', 'oldatt', 'att1', 'test_att'));
        end
        
        % include
        function test_merge_def_include(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            sdef_t = struct('df',struct('include', struct('incl1', 'test_inc')), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes);
            test_case.verifyEqual(group_obj.includes, struct('incl1', 'test_inc'));
        end
        
        % id in exp_def, attribute
        function test_merge_def_attribute(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            sdef_t = ...
                struct('df',struct('attributes', struct('field1', struct('value','val'))), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def.attributes = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes);
            test_case.verifyEqual(group_obj.expanded_def.attributes, struct('field1', struct('value','val')));
        end
        
        % id in exp_def, no conflict
        function test_merge_def_no_conflict(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            sdef_t = ...
                struct('df',struct('other', struct('value','otherentry')), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def.other = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes);
            test_case.verifyEqual(group_obj.expanded_def.other, struct('value','otherentry'));
        end
        
        % id in exp_def, conflict
        function test_merge_def_conflict(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            sdef_t = struct('df',struct('other', struct('value','otherentry')), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def.other = 'otherstring';
            group_obj.includes = struct();
            test_case.verifyError(...
                @()group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes),...
                'merge_def:conflicting_key'); 
        end
        
        % id not in exp_def
        function test_merge_def_simple(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            sdef_t = struct('df',struct('other', 'otherval'), 'ns', 'core', 'id', 'test_id');
            group_obj.expanded_def = struct();
            group_obj.includes = struct();
            group_obj.merge_def(group_obj.expanded_def, sdef_t, group_obj.includes)
            test_case.verifyEqual(group_obj.expanded_def.other, 'otherval');
        end
        
        %% merge
        
        % two structs with different keys
        function test_merge_diff_keys(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = ...
                Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            a.field1 = 'string1';
            b.field2 = 'to_merge';
            a = Group.merge(a,b);
            test_case.verifyEqual(a.field1, 'string1');
            test_case.verifyEqual(a.field2, 'to_merge');
        end
        
        % identical structs
        function test_merge_ident_structs(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            a.field1 = 'string1';
            b.field1 = 'string1';
            a = group_obj.merge(a,b);
            test_case.verifyEqual(a.field1, 'string1');
        end
        
        % struct with simple keys and overlap
        function test_merge_simple_keys(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            a.field1 = 'old_string';
            b.field1 = 'new_string';
            a = group_obj.merge(a,b);
            test_case.verifyEqual(a.field1, 'new_string');
        end
        
        % structs of structs
        function test_merge_two_structs(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('<OpticalSeries>/', file_obj.default_ns, '');
            group_obj = ...
                Group(file_obj, sdef, 'OpticalSeries', '/acquisition/timeseries', {}, 'None', {});
            a.field1 = struct('field1_1', 'string1');
            b.field1 = struct('field1_2', 'string2');
            a = group_obj.merge(a,b);
            test_case.verifyEqual(a.field1.field1_1, 'string1');
            test_case.verifyEqual(a.field1.field1_2, 'string2');
        end
            
        
        %% make_group
        
        % new group, no link
        function test_make_group_new_group(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<module>', 'Module');
            grp = group_obj.make_group('BehavioralEvent');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(...
                info.Groups.Groups.Groups.Name, '/processing/Module/BehavioralEvent');
% TO DO: check on parent attributes
%             test_case.verifyEqual(info.Groups.Groups.Attributes.Name, 'neurodata_type');
%             test_case.verifyEqual(info.Groups.Groups.Attributes.Value, 'Module');
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
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            file_obj.make_group('<module>', 'Module_1');
            group_obj = file_obj.make_group('<module>', 'Module');
            grp = group_obj.make_group('BehavioralEvent', '', {},'link:/processing/Module_1');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5'); 
            test_case.verifyEqual(info.Groups.Groups(1).Links.Name, 'BehavioralEvent');
            test_case.verifyEqual(info.Groups.Groups(1).Links.Type, 'soft link');
            test_case.verifyEqual(info.Groups.Groups(1).Links.Value, {'/processing/Module_1'});
        end
        
        %% make_custom_group
        
         % make common group in custom location
        function test_make_custom_group_pre_def(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_custom_group('Custom_Module_1', '', '/custom_modules');
            grp = ...
                group_obj.make_custom_group('<module>', 'Module', '/custom_modules/Custom_Module_1');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(...
                info.Groups.Groups.Groups.Name, '/custom_modules/Custom_Module_1/Module');
        end
        
        % make custom group in custom location
        function test_make_custom_group_(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<module>', 'Module');
            grp = group_obj.make_custom_group('Custom_Module_1', '', 'custom_modules');
            H5F.close(file_obj.file_pointer);
            info = h5info('../API/test_file.h5');
            test_case.verifyEqual(...
                info.Groups.Groups.Groups.Groups.Name,...
                '/processing/Module/custom_modules/Custom_Module_1');
        end
        
        %% get_node
        
        % TO DO
        
        %% get_sgd
        
        % group is in mstats
        function test_get_sgd_mstats(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<module>', 'Module');
            gsdef = file_obj.get_sdef('BehavioralEvent/','core', '');
            group_obj.mstats.BehavioralEvent_0x2F_ = struct('ns', 'core', 'qty', '!',...
                'df', gsdef.df, 'created', [], 'type', 'group');
            sgd = group_obj.get_sgd('BehavioralEvent/', '');
            test_case.verifyEqual(sgd.df.parent_attributes.interfaces.data_type, 'text');
            test_case.verifyEqual(sgd.type, 'group');
        end
        
        % parent not in locations
        function test_get_sgd_inv_parent(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_custom_group('myGroup','','/');
            test_case.verifyError(...
                @()group_obj.get_sgd('BehavioralEvent/', ''), 'get_sgd:m_stats_error');
        end
        
        % group not in parent locations
        function test_get_sgd_group_not_in_parent_loc(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<module>', 'Module');
            test_case.verifyError(@()group_obj.get_sgd('general/', ''), 'get_sgd:m_stats_error');
        end
        
        % not in mstats, running through
        function test_get_sgd_valid(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<module>', 'Module');
            sgd = group_obj.get_sgd('BehavioralEvent/', '');
            test_case.verifyEqual(sgd.type, 'group');
            test_case.verifyEqual(sgd.df.parent_attributes.interfaces.data_type, 'text');
        end
        
        %% set_dataset
        
        % dataset
        function test_set_dataset(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<epoch>', 'Trial_1');
            group_obj.set_dataset('start_time', 15);
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/epochs/Trial_1');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'start_time');
            data = h5read(file_obj.file_name, '/epochs/Trial_1/start_time');
            test_case.verifyEqual(data, [15]);
        end
        
        % link
        function test_set_dataset_link(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<epoch>', 'Trial_1');
            group_obj.set_dataset('start_time', 15);
            group_obj.set_dataset('stop_time','link:/epochs/Trial_1/start_time');
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Links.Name, 'stop_time');
            test_case.verifyEqual(info.Groups.Groups.Links.Type, 'soft link');
            test_case.verifyEqual(...
                info.Groups.Groups.Links.Value, {'/epochs/Trial_1/start_time'});
            data = h5read(file_obj.file_name, '/epochs/Trial_1/stop_time');
            test_case.verifyEqual(data, [15]);          
        end
        
        %% set_custom_dataset
        
        function test_set_custom_dataset(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            group_obj = file_obj.make_group('<epoch>', 'Trial_1');
            group_obj.set_custom_dataset('custom_dataset', 'custom', '', '');
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/epochs/Trial_1');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'custom_dataset');
            data = h5read(file_obj.file_name, '/epochs/Trial_1/custom_dataset');
            test_case.verifyEqual(data, {'custom'});
        end
        
        
    end
    
end

