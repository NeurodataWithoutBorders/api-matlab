classdef UtilsTest < matlab.unittest.TestCase
    % Test class to test Utils helper functions
    % Currently fairly incomplete
    
    
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
        
        % create_short_path
        
        function test_create_short_path(test_case)
            full_path = 'x0x2F_processing_0x2F_Module_0x2F_custom_modules_0x2F__0x2F_Custom_Module_1';
            short_path = Utils.create_short_path(full_path);
            test_case.verifyEqual(short_path, 'x0x2A__0x2F_Module_0x2F_custom_modules_0x2F_Custom_Module_1');
        end
        
        % create_string_dataset, char
        
        function test_create_string_dataset_str(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            dataset = 'test';
            Utils.create_string_dataset(file_obj, '/', 'string_ds', dataset);
        end
        
        
        % create_string_dataset, cellstr
        
        function test_create_string_dataset_cellstr(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            dataset = {'test1', 'string2', 'longstring3'};
            Utils.create_string_dataset(file_obj, '/', 'string_ds', dataset);
        end
        
        % create_numeric_dataset
        
        function test_numeric_dataset(test_case)
            file_obj = File('test_file.h5', '../Test_Files/nwb_core.json', 'core', '../Test_Files/all_valid_options.json');
            dataset = [1 2 3];
            compression = 'gzip';
            Utils.create_numeric_dataset(file_obj, '/', 'numeric_ds', dataset, compression);
        end
    end
    
end

