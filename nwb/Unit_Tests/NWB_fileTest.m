classdef NWB_fileTest < matlab.unittest.TestCase
    % Test class to test creation of NWB files
    
    
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
        %% Constructor NWB_file
        function test_nwb_file_constructor_simple(test_case)
            nwb_file_obj = NWB_file('test_file.h5')
        end
    end
    
end

