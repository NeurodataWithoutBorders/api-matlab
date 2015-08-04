classdef DatasetTest < matlab.unittest.TestCase
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

    methods(Test)
        %% Dataset Constructor
        
        % number
        function test_dataset_constructor_number(test_case)
            file_obj = ...
                File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/general/extracellular_ephys');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'electrode_map');
            data = h5read(file_obj.file_name, '/general/extracellular_ephys/electrode_map');
            test_case.verifyEqual(data, value);
        end
        
        % number cell
        function test_dataset_constructor_number_cell(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = {0,1};
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/general/extracellular_ephys');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'electrode_map');
            data = h5read(file_obj.file_name, '/general/extracellular_ephys/electrode_map');
            test_case.verifyEqual(data, [0, 1]);
        end
        
        % logical
        function test_dataset_constructor_logical(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [false,true];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/general/extracellular_ephys');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'electrode_map');
            data = h5read(file_obj.file_name, '/general/extracellular_ephys/electrode_map');
            test_case.verifyEqual(data, [0, 1]);
        end
        
        % logical cell
        function test_dataset_constructor_logical_cell(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = {false,true};
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Groups.Name, '/general/extracellular_ephys');
            test_case.verifyEqual(info.Groups.Groups.Datasets.Name, 'electrode_map');
            data = h5read(file_obj.file_name, '/general/extracellular_ephys/electrode_map');
            test_case.verifyEqual(data, [0,1]);
        end
        
        % char
        function test_dataset_constructor_char(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('experimenter', file_obj.default_ns, '');
            value = 'Someone';
            dataset_obj = Dataset(file_obj, sdef, '', '/general', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Name, '/general');
            test_case.verifyEqual(info.Groups.Datasets.Name, 'experimenter');
            data = h5read(file_obj.file_name, '/general/experimenter');
            test_case.verifyEqual(data, {'Someone'});
        end
        
        % cellstr
        function test_dataset_constructor_cellstr(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('experimenter', file_obj.default_ns, '');
            value = {'Some' 'One'};
            dataset_obj = Dataset(file_obj, sdef, '', '/general', {}, 'None', value, 'None', '', {});
            H5F.close(file_obj.file_pointer);
            info = h5info(file_obj.file_name);
            test_case.verifyEqual(info.Groups.Name, '/general');
            test_case.verifyEqual(info.Groups.Datasets.Name, 'experimenter');
            data = h5read(file_obj.file_name, '/general/experimenter');
            test_case.verifyEqual(data, {'Some'; 'One'});
        end
        
        
        %% mk_dsinfo
        
        % TO DO
        % link to other dataset, node
        function test_mk_dsinfo_node(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
        end
        
        % link to other dataset, external link
        function test_mk_dsinfo_ext_link(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            link_info = file_obj.extract_link_str('extlink:images.h5,/images/image_1');
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.link_info = link_info;
            dataset_obj.dsinfo = dataset_obj.mk_dsinfo(value);
            test_case.verifyEqual(dataset_obj.dsinfo.dtype, '');
            test_case.verifyEqual(dataset_obj.dsinfo.shape, '');
        end
        
        % link to other dataset, no valid key
        function test_mk_dsinfo_inv_key(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            link_info = struct('nonsense', {'images.h5' '/images/image_1'});
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.link_info = link_info;
            test_case.verifyError(@()dataset_obj.mk_dsinfo(value), 'mk_dsinfo:invalid_key_in_link_info');
        end
        
        % no link, dimensions in df, scalar
        function test_mk_dsinfo_dim_scalar(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = 1;
            test_case.verifyError(...
                @()Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {}),...
                'mk_ds_info:scalar_mismatch');
        end
        
        % no link, dimensions in df, dimension-shape mismatch
%         function test_mk_dsinfo_dim_shape_mismatch(test_case)
%             file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
%             sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
%             value = [0,1,2];
%             test_case.verifyWarning(...
%                 @()Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {}),...
%                 'mk_ds_info:dimension_mismatch');
%         end
        
        % no link, empty df
        function test_mk_dsinfo_empty_df(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.sdef.df = struct();
            dataset_obj.dsinfo = dataset_obj.mk_dsinfo(value);
            test_case.verifyEqual(isempty(fieldnames(dataset_obj.dsinfo.dimensions)), true);
            test_case.verifyEqual(dataset_obj.dsinfo.dtype, 'float');
            test_case.verifyEqual( dataset_obj.dsinfo.data_type, '');
        end
        
        % no link, no data_type in df
        function test_mk_dsinfo_no_data_type_df(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.sdef.df = struct('nonsense', 'nothing');
            test_case.verifyError(@()dataset_obj.mk_dsinfo(value), 'mk_ds_info:unspecified_data_type'); 
        end
        
        % no link, type mismatch
        function test_mk_dsinfo_type_mismatch(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = {'0', '1'};
            test_case.verifyError(...
                @()Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {}),...
                'mk_ds_info:type_mismatch');
        end
        
        % no link, invalid key in df
        function test_mk_dsinfo_invalid_df_key(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.sdef.df.nonsense = 'nothing';
            test_case.verifyError(@()dataset_obj.mk_dsinfo(value),'mk_ds_info:invalid_key');
        end
        
        % no link, dimensions in df, running through
        function test_mk_dsinfo_valid(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            sdef = file_obj.get_sdef('electrode_map', file_obj.default_ns, '');
            value = [0,1];
            dataset_obj = ...
                Dataset(file_obj, sdef, '', '/general/extracellular_ephys', {}, 'None', value, 'None', '', {});
            dataset_obj.dsinfo = dataset_obj.mk_dsinfo(value);
            test_case.verifyEqual(dataset_obj.dsinfo.dimensions, {'electrode_number' 'xyz'});
            test_case.verifyEqual(dataset_obj.dsinfo.dtype, 'float');
            test_case.verifyEqual(dataset_obj.dsinfo.dimdef.electrode_number.scope, 'local');
        end
        
        
        %% valid_dtype
        
        % Invalid value for expected data_type
        function test_valid_dtype_inv_exp(test_case)
            test_case.verifyError(...
                @()Dataset.valid_dtype('new', 'logical'), 'valid_dtype:invalid_expected_value');
        end
        
        % expected value 'any'
        function test_valid_dtype_exp_any(test_case)
            valid = Dataset.valid_dtype('any', 'logical');
            test_case.verifyEqual(valid, true);
        end
        
        % unknown found datatype
        function test_valid_dtype_unknown_found(test_case)
            test_case.verifyError(...
                @()Dataset.valid_dtype('bool', 'unknown'), 'valid_dtype:unknown_data_type');
        end
        
        % valid found data type, mismatch
        function test_valid_dtype_mismatch(test_case)
            valid = Dataset.valid_dtype('bool', 'integer');
            test_case.verifyEqual(valid, false);
        end
        
        % valid found data type, match
        function test_valid_dtype_match(test_case)
            valid = Dataset.valid_dtype('bool', 'logical');
            test_case.verifyEqual(valid, true);
        end
    end
    
end

