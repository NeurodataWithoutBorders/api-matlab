classdef File < handle
    % Class to create File objects
    % The major methods are used to the output file, create groups and datasets in the file
    % close the file
    % Additional helper functions are provided to e.g. manage options, readout the specification
    % language file, gather information, validate inputs, validate the parts of the file
    
    properties
        file_name
        file_pointer
        ddef
        default_ns
        options
        id_lookups
        all_nodes
        path2node
        nodes
        custom_attributes
    end
    
    methods
        
        function self = File(fname, ddef, default_ns,  options)
        % Created file.
        % fname - name of file
        % ddef - data definition (written in h5gate specification language)
        % default_ns - default name space for referencing elements in ddef
        % options - specified options:
        % link_type  - type of links when linking one dataset to another. 
        % Either:
        % hard - hdf5 hard links
        % string - make string dataset containing path to link
            
            % check for missing input arguments
            if ~exist('options', 'var')
                options = {};
            end
            
            if ~exist('default_ns', 'var')
                default_ns = 'core';
            end
            
            self.file_name = fname;
            self.ddef = loadjson(ddef);
            self.default_ns = default_ns;
            self.options = loadjson(options);
            self.validate_options();
            self.validate_ddef();
            self.id_lookups = self.mk_id_lookups();
            self.create_output_file;
            self.all_nodes = struct();
            self.path2node = {};
            self.nodes = {};
            self.custom_attributes = struct();
            
        end
        
        function validate_options(self)
        % Validate provided options and adds defaults for those not
        % specified
        
            all_options = struct(...
            'link_type', struct(...
                'description', 'Type of links when linking one dataset to another',...
                'values', struct(... 
                    'hard', 'hdf5 hard links',...
                    'string', 'make string dataset containing path to link'),...
                'default', 'hard'),...
            'include_schema_id', struct(...
                'description', 'Include schema id as attributed in generated file',...
                'values', struct(...
                    'True', 'yes, include id',...
                    'False', 'no, do not include id'),...
                'default', 'True'),...
            'schema_id_attr', struct(...
                'description', 'Id to use attributes for schema id',...
                'default', 'h5g8id'),...
            'flag_custom_nodes', struct(...
                'description', 'Include schema_id: "custom" in attributes for custom nodes',...
                'values', struct(...
                    'True', 'yes, include id',...
                    'False', 'no, do not includ id'),...
                'default', 'True'),...
            'default_compress_size', struct(...
                'description', ...
                ['Compress datasets that have total size larger than this value,'...
                'or 0 if should not do any compress based on size'],...
                'default', 512)...
            );          

        
            all_options_str = ...
                {'link_type'...
                '     description' ...
                '     values'... 
                '          hard'...
                '          string'...
                '     default'...
                'include_schema_id'...
                '     description'...
                '     values'...
                '          True'...
                '          False'...
                '     default'...
                'schema_id_attr'...
                '     description' ...
                '     default' ...
                'flag_custom_nodes'...
                '     description'...
                '     values' ...
                '          True'...
                '          False'...
                '     default'...
                'default_compress_size'...
                '     description'...
                '     default'};
                
            errors = {};
            opt_fields = fieldnames(self.options);
            for i = 1:numel(opt_fields)
                opt = opt_fields{i};
                value = self.options.(opt);
                % check if option is in all_options
                if ~ismember(opt, fieldnames(all_options))
                    errors{end+1} = sprintf('Invalid option specified ("%s")', opt);
                % check if 'value' is valid
                else if ismember('values', fieldnames(all_options.(opt)))...
                            && ~ismember(value, fieldnames(all_options.(opt).values))
                        vals = fieldnames(all_options.(opt).values);
                        errors{end+1} = ...
                            [sprintf('Invalid value specified for option (%s),should be one of: )',opt) ...
                            sprintf('\t%s', vals{:})];
                    end
                end
            end
            if ~isempty(errors)
                disp(strjoin(errors, '\n'));
                disp('valid options are: ');
                disp(strjoin(all_options_str, '\n'))
                error('validate_options:options_not_valid', 'Options not valid');
            end
            % Add default values for options that were not specified
            all_opt_fields = fieldnames(all_options);
            for i = 1:numel(all_opt_fields)
                if ~ismember(all_opt_fields{i}, opt_fields)
                    self.options.(all_opt_fields{i}) = all_options.(all_opt_fields{i}).default;
                end
            end
    
        end
        
        function validate_ddef(self)
        % Make sure that each namespace has both a "structures" and "locations"
        % and that the default name space is defined
            ddef_ns = fieldnames(self.ddef);
            % check for default namespace
            if ~ismember(self.default_ns, ddef_ns)
                disp('Error \n');
                disp(fprintf('Default name space ("%s") does not appear in data definitions',...
                    self.default_ns));
                error('validate_ddef:missing_namespace', 'Missing default name space');
            end
            errors = {};
            for i = 1:numel(ddef_ns)
                % check for structures
                if ~ismember('structures', fieldnames(self.ddef.(ddef_ns{i})))
                    errors{end+1} = ...
                        sprintf('Namespace "%s" is missing .structures definition', ddef_ns{i});
                end
                % check for locations
                if ~ismember('locations', fieldnames(self.ddef.(ddef_ns{i})))
                    errors{end+1} = ...
                        sprintf('Namespace "%s" is missing .locations definition', ddef_ns{i});
                end
            end
            if ~isempty(errors)
                disp('** Error');
                disp(strjoin(errors, '\n')); 
                error('validate_ddef:invalid_data_definition', 'Invalid data definition' );
            end
        end
        
        function create_output_file(self)
        % open output file and add initial structure
            % open file
            try 
                fp = H5F.create(self.file_name,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
            catch
                disp(fprintf('Unable to open output file "%s"',  self.file_name));
                error('create_output_file:unable_to_open_file','Cannot open output file');
            end
            % remember file pointer
            self.file_pointer = fp;
        end
        
        function close(self)
            self.validate_file();
            if H5I.is_valid(self.file_pointer)
                H5F.close(self.file_pointer);
            end
        end
        
        function id_lookups = mk_id_lookups(self)
        % Makes id_lookup for each namespace.  See "mk_id_lookup" (singular) for structure.
            id_lookups = struct();
            ddef_ns = fieldnames(self.ddef);
            for i = 1:numel(ddef_ns)
                id_lookups.(ddef_ns{i}) = self.mk_id_lookup(ddef_ns{i});
            end
        end
        
        function id_lookup = mk_id_lookup(self, ns)
        % Creates dictionary mapping id's in definitions to dictionary of locations these
        % items may be stored.  For each location, store a dictionary of allowed 
        % quantity for the item ('*' - any, '?' - optional, '!' - required, 
        % '+' - 1 or more) and
        % list of actual names used to create item (used to keep track if required items
        % are set.
            if ~ismember('structures', fieldnames(self.ddef.(ns)))
                    disp(fprintf('** Error.  Namespace "%s" does not contain key "structures"', ns));
                    error('mk_id_lookup:missing_structures', 'Missing structures');
            end
            if ~ismember('locations', fieldnames(self.ddef.(ns)))
                    disp(fprintf('** Error.  Namespace "%s" does not contain key "locations"', ns));
                    error('mk_id_lookup:missing_locations', 'Missing locations');
            end
            id_lookup = struct();
            referenced_structures = {};
            locs = fieldnames(self.ddef.(ns).locations);
            for j = 1:numel(locs)
                if isstruct(self.ddef.(ns).locations.(locs{j}))
                    ids = fieldnames(self.ddef.(ns).locations.(locs{j}));
                else
                    ids = self.ddef.(ns).locations.(locs{j});
                end
                for i = 1:numel(ids)
                    [id_str, qty_str] = self.parse_qty(Utils.convert_utf_to_uc(ids{i}), '?');
                    id_str_orig = id_str;
                    id_str = Utils.convert_uc_to_utf(id_str);
                    if ~ismember(id_str, fieldnames(self.ddef.(ns).structures))...
                            && ~strcmp(id_str_orig, '__custom')
                        disp(fprintf('** Error, in namespace "%s": \n' ,ns));
                        disp(fprintf('structure "%s" referenced in nwb.%s.locations.%s,' ,...
                            id_str, ns, locs{j}))
                        disp(fprintf('but is not defined in nwb.%s.structures', ns))
                        error('mk_id_lookup:structure_location_mismatch',...
                            'structure location mismatch');
                    end
                    referenced_structures{end+1} = id_str;
                    if strcmp(id_str_orig(end), '/')
                        type = 'group';
                    else
                        type = 'dataset';
                    end
                    if ~ismember(id_str, fieldnames(id_lookup))
                        id_lookup.(id_str) = struct(); %initialize struct of locations
                    end
                    id_lookup.(id_str).(locs{j}) = ...
                        struct('type', type, 'qty', qty_str, 'created', []);
                end
            end
            no_location = {};
            ddef_ns_struct = fieldnames(self.ddef.(ns).structures);
            for i = 1:numel(ddef_ns_struct)
                if ~ismember(ddef_ns_struct{i}, referenced_structures)
                    no_location{end+1} = ddef_ns_struct{i};
                end
            end
        end
        
        function sdef = get_sdef(self, qid, default_ns, errmsg)
        % Return structure definition of item as well as namespace and id within
        % name space.  If structure does not exist, display error message (if given)
        % or return None.
        % qid - id, possibly qualified by name space, e.g. "core:<timeStamp>/", 'core' is
        %     is the name space.
        % default_ns - default namespace to use if qid does not specify
        % errmsg - error message to display if item not found.
            if ~exist('errmsg', 'var')
                errmsg = '';
            end
            [ns, id] = self.parse_qid(qid, default_ns);
            id_orig = id;
            id = Utils.convert_uc_to_utf(id);
            if ismember(id, fieldnames(self.ddef.(ns).structures))
               df = self.ddef.(ns).structures.(id);
               if strcmp(id_orig(end), '/')
                    type = 'group';
               else
                    type = 'dataset';
               end
               sdef = struct('type', type, 'qid', qid, 'id', id, 'ns', ns, 'df', df);
               return;
            end
            if ~strcmp(errmsg, '')
                disp(fprintf('Structure "%s" (in name space "%s") referenced but not defined.' , id, ns));
                disp(errmsg);
                error('get_sdef:strucure_not_in_ns', 'Structure not in namespace');
            end
            sdef = {};
        end
        
        function [id, qty] = parse_qty(~, qid, default_qty)
        % Parse id which may have a quantity specifier at the end. 
        % Quantity specifiers are: ('*' - any, '!' - required,
        % '+' - 1 or more, '?' - optional, or '' - unspecified)
            match_obj = regexp(qid, '([^*!+?]+)([*!+?]?)', 'tokens');
            if isempty(match_obj)
                disp(fprintf('** Error: Unable to find match in pattern "%s"', qid));
                error('parse_qty:no_match', 'No match in pattern');
            end
            id = match_obj{1}{1};
            qty = match_obj{1}{2};
            if isempty(qty)
                qty = default_qty;
            end
        end
        
        function [ns, id] = parse_qid(self, qid, default_ns)
        % Parse id, which may be qualified by namespace
        % qid - possibly qualified id, e.g. "core:<id>", 'core' is a namespace,
        % default_ns - default namespace to use of qid not specified.
        % Returns namespace and id as tuple (ns, id).            
            match_obj = regexp(qid, '([^:]+:)?(.+)', 'tokens');
            if isempty(match_obj)
                disp(fprintf('** Error: Unable to find match in pattern "%s"', qid));
                error('parse_qid:no_match', 'No match in pattern');
            end
            ns = strtrim(match_obj{1}{1}(1:end-1));
            id = strtrim(match_obj{1}{2});
            if isempty(ns)
                ns = default_ns;
            end
            self.validate_ns(ns);
        end
        
        function validate_ns(self, ns)
            if ~ismember(ns, fieldnames(self.ddef))
                disp(fprintf('Namespace "%s" referenced, but not defined' , ns));
%                 dbstack
                error('validate_ns:undefined_ns', 'Namespace not defined');
            end
        end
        
        function grp = make_group(self, qid, varargin) 
        % Creates groups that are in the top level of the definition structures.
        % qid - qualified id of structure.  id, with optional namespace (e.g. core:<...>).
        % name - name of group in case name is not specified by id (id is in <angle brackets>)
        %     *OR* Group node linking to
        %     *OR* pattern to specify link: link:path or extlink:file,path
        % path - specified path of where group should be created.  Only needed if
        %     location ambiguous
        % link - specified link, of form link:path or extlink:file,path.  Only needed
        %     if name must be used to specify local name of group
        % attrs - attribute values for group that are specified in API call
        % abort - If group already exists, abort if abort is True, otherwise return previously
        %     existing group.
            % parse input arguments
            arg_names = { 'name', 'path', 'attrs', 'link', 'abort'};
            arg_types = { 'char', 'char', 'cell',  'char', 'logical' };
            arg_default={ '',     '',      {},     '',     true };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            path = arg_vals.path;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            link = arg_vals.link;
            abort = arg_vals.abort;
            gqid = strcat(qid, '/');
            sdef = self.get_sdef(gqid, self.default_ns, 'referenced in make_group');
            id = sdef.id;
            ns = sdef.ns;
            id = Utils.convert_uc_to_utf(id);
            path = self.deduce_path(id, ns, path);
            if ~strcmp(abort, 'true')
                id_noslash = strrep(id,'/','');
                grp = self.get_existing_group(path, id_noslash, name);
                if ~isempty(grp)
                    return;
                end
            end
            link_info = self.extract_link_info(name, link, 'Group');
            parent = 'None';
            grp = Group(self, sdef, name, path, attrs, parent, link_info);
        end
        
        function node = get_existing_group(self, path, id, name)
        % Return existing Group object if attempting to create group again, otherwise,
        % return None.  This called by make_group to check for existing group if abort
        % is False.
            v_id = regexp( id, '^<[^>]+>$', 'match'); % True if variable_id (in < >)
            if ~isempty(v_id)
                lookup_name = name;  
            else
                lookup_name = id;
            end
            full_path = [path  '/' lookup_name];
            node = self.get_node(full_path, false);
            if  ~isempty(node) && strcmp(node.sdef.type, 'group')
                % found already existing group
                return; 
            else
                node = {};
            end
        end
        
        function path = deduce_path(self, id, ns, path)
        % Deduce location based on id, namespace and specified_path
        % and using locations section of namespace, which is stored in
        % id_lookups.  Return actual path, or abort if none.
            id = Utils.convert_uc_to_utf(id);
            locations = self.id_lookups.(ns).(id);
            if ~strcmp(path, '')
                path_orig = path;
                path = Utils.convert_uc_to_utf(path);
                if ~ismember(path, fieldnames(locations))
                    disp('** Error');
                    disp(fprintf('Specified path "%s" not in name space "%s" locations for id "%s"',...
                        Utils.convert_utf_to_uc(path_orig), ns, Utils.convert_utf_to_uc(id)));
%                     dbstack
                    error('deduce_path:path_not_in_ns', 'Specified path not in ns locations');
                end
                path = path_orig;
            else
                if numel(fieldnames(locations)) > 1
                    disp('** Error');
                    disp(fprintf('Path not specified for "%s", but must be since' ,...
                        Utils.convert_utf_to_uc(id)));
                    disp( ['there are multiple locations:'...
                        Utils.convert_utf_to_uc(strjoin(fieldnames(locations), ', '))]);
                    % dbstack
                    error('deduce_path:path_not_specified', 'Path not specified');
                end
                locs = fieldnames(locations);
                path = locs{1};
                path = Utils.convert_utf_to_uc(path);
            end
        end
        
        function link_info = extract_link_info(self, val, link, node_type)
        % Gets info about any specified link.
        % Links can be specified in three ways:
        %     1. By setting the name of a group or the value of a dataset to a target node
        %     2. By setting the name of a group or the value of a dataset to a link pattern
        %     3. By specifying a link pattern explicitly (only for groups, since make_group
        %         does not have a "value" option, an extra parameter (link) is made available
        %         if needed to specify the link.  (Needed means the name is used to specify
        %         the name of the group).
        % Function parameters are:
        %     val - name of group or value of dataset (used for methods 1 & 2)
        %     link - explicitly specified link pattern (used for method 3.
        %     node_type, type of node being linked.  Either Group or Dataset.  (used
        %     for method 1). 
        link_info = {};
        if strcmp(class(val), node_type)
            % method 1
            link_info = struct('node', val);
        else
            % method 2
            link_info = self.extract_link_str(val);
            if isempty(link_info)
                % method 3
                link_info = self.extract_link_str(link);
            end
        end
        end
        
        function link_info = extract_link_str(self, link)
        % Checks if link is a string matching a pattern for a link.  If so,
        % return "link_info" dictionary
            if isa(link, 'char')
                if ~isempty(regexp(link, '^link:', 'match'))
                    % assume intending to specify a link, now match for rest of pattern            
                    matchObj = regexp( link, '^link:([^ ]+)$', 'tokens');
                    if ~isempty(matchObj)
                        path =  matchObj{1}{1};
                        node = self.get_node(path, true);
                        link_info = struct('node', node);
                        return;
                    else
                        disp('** Error, invalid path specified in link string, must not have spaces');
                        disp(fprintf('link string is: "%s"', ...
                            Utils.convert_utf_to_uc(link)));
                        % dbstack
                        error('extract_link_str:invalid_path', 'Invalid path specified in link string');
                    end
                else if ~isempty(regexp(link, '^extlink:', 'match'))
                        % assume intending to specify an external link, now match for rest of pattern
                        matchObj = regexp(link, '^extlink:([^ ,]*)[ ,]([^ ,]+)$', 'tokens');
                        if ~isempty(matchObj)
                            file = matchObj{1}{1};
                            path = matchObj{1}{2};
                            link_info.extlink = {file, path};
                            return;
                        else
                            disp('** Error, invalid file or path specified in extlink string');
                            disp(' must not have spaces and file name must not end in comma');
                            disp(fprintf('extlink string is: "%s"', Utils.convert_utf_to_uc(link)));
                            % dbstack
                            error('extract_link_str:invalid_ext_path',...
                                'Invalid path specified in link string');
                        end
                     end
                end
            end
            link_info = {};             
        end
        
        function validate_custom_name(~, name)
        %Make sure valid name used for custom group or dataset
            if isempty(regexp(name, '(/?[a-zA-Z_][a-zA-Z0-9_]*)+$', 'match'))
                disp(fprintf('Invalid name for node (%s)', Utils.convert_utf_to_uc(name)));
                error('validate_custom_name:invalid_custom_name', 'Invalid custom name');
            end
            return;
        end
        
        function path_valid = validate_path(~, path)
            %Make sure path is valid
            path_valid = 'true';  %  Allow anything in path, even spaces
    %         return;
            pattern = '^([^ ]+)$';       % allow anything except spaces
            if strcmp(path,'') || ~isempty(regexp(path, pattern, 'match'))
                return;
            end
            disp(fprintf('Invalid path (spaces not allowed):\n"%s"' ,...
                Utils.convert_utf_to_uc(path)));
            error('validate_path:path_with_spaces', 'Path with spaces' );
        end
        
        function full_path = make_full_path(self, path, name)
        %Combine path and name to make full path
        if ~strcmp(path, '')
            path = strrep(path, '//', '/');
            full_path = [path  '/' name];  
        else
            full_path = name;
        end
        % remove any duplicate slashes
        full_path = strrep(full_path, '//', '/');
        self.validate_path(full_path);
        end
        
        function [sdef, name, path] = ...
                get_custom_node_info(self, qid, gslash, name, path, parent)
        % gets sdef structure, and if necessary modifies name and path to get
        % sdef structure into format needed for creating custom node (group or dataset).
        % gslash is '/' if creating a group, '' if creating a dataset.
        % parent - parent group if creating node inside (calling from) a group.
            if ~exist('parent','var')
                parent = 'None';
            end
            gqid = [qid gslash];
            sdef = self.get_sdef(Utils.convert_utf_to_uc(gqid), self.default_ns);
            if ~isempty(sdef)
                % found id in structure, assume creating pre-defined node in custom location
                id = sdef.id;
                ns = sdef.ns;
                if strcmp(path,'')
                    disp('** Error');
                    disp(fprintf(...
                        'Path must be specified if creating "%s" in a custom location using name space "%s".' ,...
                        Utils.convert_utf_to_uc(id), ns));
                    % dbstack
                    error('get_custom_node_info:empty_path', 'Path must be specified in a custom location');
                end
                sdef.custom = 'true';
            else
                % did not find id in structures.  Assume creating custom node in custom location
                [ns, id] = self.parse_qid(Utils.convert_utf_to_uc(qid), self.default_ns);
                full_path = self.make_full_path(path, id);
                if ~strcmp(parent, 'None')
                    if ~isempty(full_path) && strcmp(full_path(1),'/')
                        disp(fprintf(...
                            ['** Error:  Specified absolute path "%s" when creating node\n'...
                            'inside group, with namespace "%s"'],...
                            Utils.convert_utf_to_uc(full_path), ns));
                        % dbstack
                        error('get_custom_node_info:invalid_full_path',...
                            'Specified absolute path when creating node inside a group');
                    end
                % ok, relative path is specified, make full path using parent
                full_path = self.make_full_path(parent.full_path, full_path);                       
                else
                % not creating from inside a group.  Require absolute path, or default to __custom location
                    if strcmp(full_path,'') || ~strcmp(full_path(1), '/')
                        if ~ismember(Utils.convert_uc_to_utf('__custom'), fieldnames(self.id_lookups.(ns)))
                            disp(fprintf(...
                                ['** Error:  Attempting to make "%s" but path is relative and\n'...
                                '"__custom" not specified in "%s" name space locations'], ...
                                Utils.convert_utf_to_uc(full_path), ns));
                            disp('id_lookups is')
                            disp(Utils.convert_utf_to_uc(strjoin(fieldnames(self.id_lookups.(ns)), '\n')));
                            % dbstack
                            error('get_custom_node_info:invalid_relative_path',...
                                'Only relative path given, while full path is required');
                        end
                        if numel(self.id_lookups.(ns).x_custom) > 1
                            disp(fprintf(...
                                '** Error:  "__custom" is specified in more than location in namespace "%s"', ns)); 
                            error('get_custom_node_info:multiple_custom_in_ns',...
                                '"__custom" is specified in more than location');
                        end
                        id_lookups_cust = fieldnames(self.id_lookups.(ns).x_custom);
                        default_custom_path = id_lookups_cust{1};
                        full_path = self.make_full_path(default_custom_path, full_path);
                    end
                end
                % split full path back to path and group name
                matchObj = regexp( full_path, '^(.*/)([^/]*)$', 'tokens');
                if isempty(matchObj)
                    disp(fprintf('** Error: Unable to find match pattern for full_path in "%s"',...
                        Utils.convert_utf_to_uc(full_path)));
                    error('get_custom_node_info:no_pattern_for_full_path',...
                        'Unable to find match pattern for full_path'); 
                end
                path = matchObj{1}{1};
                if strcmp(strrep(path,'/', ''), '')
                    path = '/';
                end
                path = Utils.convert_uc_to_utf(path);
                id_str = matchObj{1}{2};
                % make sdef for custom node.  Has empty definition (df)
                if strcmp(gslash, '/')
                    type = 'group';
                else
                    type = 'dataset';
                end
                sdef = struct(...
                    'type', type, 'qid', qid, 'id', [id_str gslash], 'ns',ns, 'df', struct(), 'custom', 'true' );
                name = '';
            end
                
        end
        
        function grp = make_custom_group(self, qid, varargin) 
        % Creates custom group.
        % qid - qualified id of structure or name of group if no matching structure.
        %     qid is id with optional namespace (e.g. core:<...>).  Path can
        %     also be specified in id (path and name are combined to produce full path)
        % name - name of group in case id specified is in <angle brackets>
        % path - specified path of where group should be created.  If not given
        %     or if relative pateOnly needed if
        %     location ambiguous
        % attrs - attribute values for group that are specified in API call
            % parse input arguments
            arg_names = { 'name', 'path', 'attrs'};
            arg_types = { 'char', 'char', 'cell'};
            arg_default={ '',     '',      {}};
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            path = arg_vals.path;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            gslash = '/';
            [sdef, name, path] = self.get_custom_node_info(qid, gslash, name, path);   
            parent = 'None';  % no parent since this node created from File object (top level)
            grp = Group(self, sdef, name, path, attrs, parent);
        end
        
        function ds = set_dataset(self, qid, value, varargin)  
        % Creates datasets that are in the top level of the definition structures.
        % qid - qualified id of structure.  id, with optional namespace (e.g. core:<...>).
        % value - value to store in dataset, or Dataset object (to link to another dataset,
        %    *OR* a string matching pattern: link:<path> or extlink:<file>,<path>
        %    to specify respectively a link within this file or an external link.
        % name - name of dataset in case name is unspecified (id is in <angle brackets>)
        % path - specified path of where dataset should be created.  Only needed if location ambiguous
        % attrs - attributes (dictionary of key-values) to assign to dataset
        % dtype - if provided, included in call to h5py.create_dataset
        % compress - if True, compress provided in call to create_dataset
            % parse input arguments
            arg_names = { 'name', 'path', 'attrs', 'dtype', 'compress'};
            arg_types = { 'char', 'char', 'cell',  'char', 'logical' };
            arg_default={ '',     '',     {},      '',     false };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            path = arg_vals.path;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            dtype = arg_vals.dtype;
            compress = arg_vals.compress;
            sdef = self.get_sdef(qid, self.default_ns, 'referenced in set_dataset');
            id = sdef.id;
            ns = sdef.ns;
            path = self.deduce_path(id, ns, path);
            link_info = self.extract_link_info(value, '', 'Dataset');

            % finally, create the dataset
            parent = 'None';  % no parent since this node created from File object (top level)
            ds = Dataset(self, sdef, name, path, attrs, parent, value, dtype, compress, link_info);
        end
        
        function ds = set_custom_dataset(self, qid, value, varargin) 
        % Creates custom datasets that are in the top level of the definition structures.
        % qid - qualified id of structure.  id, with optional namespace (e.g. core:<...>).
        % name - name of dataset in case name is unspecified (id is in <angle brackets>)
        % path - specified path of where dataset should be created if not specified in qid
        % attrs - attributes (dictionary of key-values) to assign to dataset
        % dtype - if provided, included in call to h5py.create_dataset
        % compress - if True, compress provided in call to create_dataset
            % parse input arguments
            arg_names = { 'name', 'path', 'attrs', 'dtype', 'compress'};
            arg_types = { 'char', 'char', 'cell',  'char', 'logical' };
            arg_default={ '',     '',     {},      '',     false };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            path = arg_vals.path;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            dtype = arg_vals.dtype;
            compress = arg_vals.compress;
            gslash = '';
            [sdef, name, path] = self.get_custom_node_info(qid, gslash, name, path);   
            parent = 'None';  % no parent since this node created from File object (top level)
            ds = Dataset(self, sdef, name, path, attrs, parent, value, dtype, compress);  
        end
        
        function validate_file(self)
        % Validate that required nodes are present.  This is done by checking
        % nodes referenced in id_lookup structure (built from 'locations' section
        % of specification language) and also by checking the tree of all nodes
        % that are included in the "all_nodes" array. 
            disp('******');
            disp(' Done creating file.  Validation messages follow.');
            missing_nodes = struct('group', [], 'dataset', []);
            custom_nodes = struct('group', [], 'dataset', []);
            nss = fieldnames(self.id_lookups);
            for i = 1:numel(nss)
                ns = nss{i};
                ids = fieldnames(self.id_lookups.(ns));
                for j = 1:numel(ids)
                    id = ids{j};
                    paths = fieldnames(self.id_lookups.(ns).(id));
                    for k = 1:numel(paths)
                        path = paths{k};
                        qty = self.id_lookups.(ns).(id).(path).qty;
                        type = self.id_lookups.(ns).(id).(path).type;
                        count = numel(self.id_lookups.(ns).(id).(path).created);
                        if (strcmp(qty, '!') ||  strcmp(qty,'+')) && count == 0
                            missing_node = sprintf('%s:%s/%s', ns,...
                                Utils.convert_utf_to_uc(path), Utils.convert_utf_to_uc(id));
                            % remove double slashes
                            missing_nodes.(type){end+1} = strrep(missing_node, '//', '/');
                        end
                    end
                end
            end
            all_nodes = fieldnames(self.all_nodes);
            for i = 1:numel(all_nodes)
                node_name = all_nodes{i};
                curr_nodes = self.all_nodes.(node_name);
                for j = 1:numel(curr_nodes)
                    [missing_nodes, custom_nodes] = ...
                        self.validate_nodes(curr_nodes{j}, missing_nodes, custom_nodes);
                end
            end
            self.report_problems(missing_nodes, 'missing');
            self.report_problems(custom_nodes, 'custom');
            if ~isempty(fieldnames(self.custom_attributes))
                count = numel(fieldnames(self.custom_attributes));
                disp(fprintf('%i nodes with custom attributes' , numel(self.custom_attributes)));
                if count > 20
                    disp('Only first 20 shown;')
                names = fieldnames(self.custom_attributes);
                names = names{1:min(count,20)};
                nlist = {};
                for i = 1:numel(names)
                    nlist{end+1} = [name '->' self.customattributes.name];
                end       
                disp(nlist);
                end
            else
                disp('No custom attributes.  Good.');
            end
        end
        
        function [missing_nodes, custom_nodes] =...
                validate_nodes(~, root_node, missing_nodes, custom_nodes)
        % Check if node contains all required components or if it is custom.
            to_check = {};
            to_check{end+1} = root_node;
            while numel(to_check) > 0 
                node = to_check{1};
                to_check(1) = [];
                if isfield(node.sdef, 'custom')
                    custom = node.sdef.custom;
                else
                    custom = false;
                end
                type = node.sdef.type;
                if custom
                    custom_nodes.(type){end+1} = node.full_path;
                end
                if strcmp(type,'group')
                    % check if any nodes required in this group are missing
                    mstats = fieldnames(node.mstats);
                    for i = 1:numel(mstats)
                        id = mstats{i};
                        qty = node.mstats.(id).qty;
                        type = node.mstats.(id).type;
                        created = node.mstats.(id).created;
                        if ~custom && (strcmp(qty, '!') || strcmp(qty, '+')) && numel(created) == 0
                            missing_nodes.(type){end+1} = sprintf('%s/%s' ,...
                                Utils.convert_utf_to_uc(node.full_path), Utils.convert_utf_to_uc(id));
                        end
                        % add nodes to list to check
                        for j = 1:numel(created)
                            to_check{end+1} = created{j};
                        end
                    end
                end
            end
        end

        
        function report_problems(~, nodes, problem)
        % Display nodes that have problems (missing or are custom)
            limit = 30;
            node_types = {'group', 'dataset'};
            for i = 1:numel(node_types)
                type = node_types{i};
                count = numel(nodes.(type));
                if count > 0
                    if count > limit
                        limit_msg = sprintf(' (only the first %i shown)', limit);
                        endi = limit;
                    else
                        limit_msg = '';
                        endi = count;
                    end
                    if count>1
                        types = [type  's'];  
                    else
                        types = type;
                    end
                    disp(fprintf(' ------ %i %s %s%s:' , count, types, problem, limit_msg));
                    for j = 1:endi
                        disp(Utils.convert_utf_to_uc(nodes.(type){j}));
                    end
                else
                    disp(fprintf(' ------ No %s %ss.  Good.' , problem, type));
                end
            end
        end
        
        function node = get_node(self, full_path, abort)
        % Returns node at full_path.  If no node at that path then
        % either abort (if abort is True) or return None
            if ~exist('abort', 'var')
                abort = true;
            end
            paths = self.path2node;
            full_path = Utils.convert_uc_to_utf(full_path);
            if ismember(full_path, paths)
                [~,idx] = ismember(full_path, self.path2node);
                node = self.nodes{idx};
                return;
            else if abort
                    disp(fprintf('Unable to get node for path\n%s', Utils.convert_utf_to_uc(full_path)));
                    % dbstack
                    error('get_node:unable_to_get_node', 'Unable to get node for path');
                else
                    node = {};
                end
            end
        end
        
  
    end
    
end

