classdef NWB_file < File
    % subclass of File. Creates NWB hdf5 file
    
    properties
    end
    
    methods
        function self = NWB_file(fname, start_time, extensions,...
        default_ns, core, options)
        % Create NWB file.
        % fname  - file name
        % start_time - session starting time.  If not specified, current time is used.  
        % extensions - extensions to NWB core.  Specified in JSON specification language
        % using keys:
        % extensions[<ns>]['structures'] and
        % extensions[<ns>]['locations']
        % where <ns> is an identifier associated with extension (like an xml namespace).
        % default_ns - default namespace
        % core - python file to import as core (contains definition of nwb format)
        % options - h5gate options.  Options are:
        % 'link_type': {
        %     'description': 'Type of links when linking one dataset to another',
        %     'values': { % following tuples have description, then 'Default' if default value
        %         'hard': 'hdf5 hard links',
        %         'string': 'make string dataset containing path to link'},
        %     'default': 'hard' },
        % 'include_schema_id': {
        %     'description': 'Include schema id as attributed in generated file',
        %     'values': {
        %         True: 'yes, include id',
        %         False: 'no, do not includ id'},
        %     'default': True },
        % 'schema_id_attr': {
        %     'description': 'Id to use attributes for schema id',
        %     'default': 'h5g8id', },
        % 'flag_custom_nodes': {
        %     'description': "Include schema_id: custom' in attributes for custom nodes",
        %     'values': {
        %         True: 'yes, include id',
        %         False: 'no, do not includ id'},
        %     'default': True },  
            if ~exist('start_time','var')
                start_time = '';
            end
            if ~exist('extensions','var')
                extensions = 'None';
            end
            if ~exist('default_ns','var')
                default_ns = 'core';
            end
            if ~exist('core','var')
                core = 'nwb_core.json';
            end
            if ~exist('options','var')
                options = savejson('',struct());
            end
            VERS_MAJOR = 0;
            VERS_MINOR = 1;
            VERS_PATCH = 1;
            FILE_VERSION_STR = sprintf('NWB-%d.%d.%d', VERS_MAJOR, VERS_MINOR, VERS_PATCH);
            IDENT_PREFIX = ['Neurodata h5gate testing'  FILE_VERSION_STR  ': '];
            options = loadjson(options);
            if isempty(options)
                options = struct();
            end
            if ~ismember('schema_id_attr', fieldnames(options));
                options.schema_id_attr = 'nwb_sid';
            end
            options = savejson('',options);
              
            % add in any extensions
            if ~strcmp(extensions, 'None')
                 % does import nwb_core as core
                core = loadjson(core); 
                extensions = loadjson(extensions)
                ns_ext = fieldnames(extensions);
                for i = 1:numel(ns_ext)
                    if ~strcmp(ns_ext{i}, default_ns)
                        core.(ns_ext{i}) = extensions.(ns_ext{i})
                    end
                end
                core = savejson(core);
            end
            % create nwb file
            self@File(fname, core, default_ns, options);
            % setup initial metadata        
            self.set_dataset('neurodata_version', FILE_VERSION_STR);
            hstr = [IDENT_PREFIX datestr(now, 'ddd mmm dd HH:MM:SS yyyy') '--' self.file_name];
            self.set_dataset('identifier', hstr);
            self.set_dataset('file_create_date', datestr(now, 'ddd mmm dd HH:MM:SS yyyy'));
            if strcmp(start_time, '')
                sess_start_time = datestr(now, 'ddd mmm dd HH:MM:SS yyyy');
            else
                sess_start_time = start_time;
            end
            self.set_dataset('session_start_time', sess_start_time);
        end
        
    end
    
end

