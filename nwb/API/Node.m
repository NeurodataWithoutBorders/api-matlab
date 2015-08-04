classdef Node < handle
    % node (either group or dataset) in created file 

    
    properties
        file
        sdef
        link_node
        name
        path
        full_path
        attrs
        attributes
        parent
        link_info
    end
    
    methods
         
        function self = Node(file, sdef, name, path, attrs, parent, link_info)
        % Create node object
        % file - file object
        % sdef - dict with elements:
        %     type - 'group' or 'dataset'
        %     id - id in structures (or parent group) for node
        %     ns - namespace structure is in
        %     df - functioninition of node (dictionary)
        % name - name of node in case id is in <angle brackets>
        %      *OR* another Group object if making link to that group
        % path - path of where node should be created
        % attrs - dictionary of attribute values specified in API call creating node
        % parent - parent Group object if this node was made inside another specified group
        %     None otherwise
        % link_info - Either None, or info used to make link.  If linking to internal node,
        %     contains key "node".  If linking to external file, contains key: "extlink"
        %     and value is file,path (file, comma, then path).

            self.file = file;
            self.sdef = sdef;
            id_orig = Utils.convert_utf_to_uc(sdef.id);
            id_noslash = strrep(id_orig, '/', '');  % remove trailing slash in case it's a group
            v_id = regexp(id_noslash, '^<[^>]+>$', 'match'); % True if variable_id (in < >)
        if isa(name, 'Group')
            % linking to a group
            self.link_node = name;
            % if variable id, use name of target group, otherwise keep name the same
             
            if ~isempty(v_id)
                name = name.name;
            else
                name = id_noslash;
            end
        else
            self.link_node = {};
            if ~isempty(v_id)
                if strcmp(name, '')
                    disp(fprintf(...
                        '** Error: name for %s "%s" must be specified', sdef.type, id_noslash));
                    % dbstack
                    error('Node:unspecified_name', 'Name not specified');
                end
            else
                if ~strcmp(name, '')
                    disp(fprintf(...
                        '** Error: %s name "%s" is fixed.  Cannot create (or link) with name "%s"',...
                        sdef.type, id_noslash, name));
                    % dbstack
                    error('Node:fixed_name', 'Name is fixed');
                else
                    name = id_noslash;  
                end
            end
        end
        self.name = name;
        self.path = Utils.convert_uc_to_utf(path);
        self.full_path = Utils.convert_uc_to_utf(self.file.make_full_path(path, name));
        self.attrs = attrs;
        self.attributes = struct(); % for attributes functionined in specification language
        self.add_schema_attribute()
        self.parent = parent;
        self.link_info = link_info;
        self.create_link()   
        self.save_node()
        end

        
   
    function create_link(self)
        % If node is being linked to another node, create the link in the hdf5 file%
        if ~isempty(self.link_info)
            link_type = self.file.options.link_type;
            if ismember('node', fieldnames(self.link_info))
                target_path = Utils.convert_utf_to_uc(self.link_info.node.full_path);
                if strcmp(link_type,'string')
                    % create string dataset containing link path
                    data=['h5link:/' target_path];
                    Utils.create_string_dataset(self.file.file_pointer, ...
                        Utils.convert_utf_to_uc(self.path), Utils.convert_utf_to_uc(self.name), data); 
                else
                    if strcmp(link_type,'hard')
                        % create hard link to target.  
                        Utils.create_softlink(self.file.file_pointer, target_path,...
                            Utils.convert_utf_to_uc(self.path), Utils.convert_utf_to_uc(self.name));
                    else 
                        disp(fprintf('Invalid option value for link_type (%s)', link_type));
                        error('create_link:invalid_link_type', 'Invalid link option');
                    end
                end
            else
                if ismember('extlink', fieldnames(self.link_info))
                    file_l  = self.link_info.extlink{1};
                    path_l  = self.link_info.extlink{2};
                    % link to external file
                    if strcmp(link_type,'string')
                        % create string dataset containing link path
                        target_path = sprintf('%s,%s', file_l, path_l);
                        data=['h5extlink:/'  target_path];
                        Utils.create_string_dataset(self.file, Utils.convert_utf_to_uc(self.path), ...
                            Utils.convert_utf_to_uc(self.name), data);
                    else
                        if strcmp(link_type,'hard')
                        % create link to external file
                        Utils.create_external_link(self.file.file_pointer, ...
                            Utils.convert_utf_to_uc(self.full_path), path_l, file_l);
                        else
                            disp(fprintf('Invalid option value for link_type (%s)', link_type));
                            error('create_link:invalid_link', 'Invalid link option');
                        end
                    end
                else
                    links = fieldnames(self.link_info);
                    disp(fprintf('** Error: invalid key in link_info %s', links{1}));
                    error('create_link:invalid_key_in_link_info', 'invalid link_info');
                end
            end
        end
    end

         
    function save_node(self)
        % Save newly created node in id_lookups (if node is functionined structure created
        % at top level) and in "all_nodes".  Nodes stored in both of these are later used
        % for validating that required nodes are present.
        % Also save in 'path2nodes' - that's used for file object get_node method%
        % save node in path2node
        if ismember(self.full_path, self.file.path2node)
            disp(fprintf('** Error, created node with path twice:\n%s', self.full_path));
            % dbstack
            error('save_node:duplicate_node', 'created node with path twice');
        end
        self.file.path2node{end+1} = self.full_path;
        self.file.nodes{end+1} = self; 
        % save node in id_lookups
        id = self.sdef.id;
        ns = self.sdef.ns;
        type = self.sdef.type;
        if ismember('custom', fieldnames(self.sdef)) && ~isempty(self.sdef.custom) 
            custom = true;
        else
            custom = false;
        end
        if strcmp(self.parent, 'None') && ~isempty(self.sdef.df) && ~custom
            % structure (not custom) created at top level, save in id_lookups
            if ~ismember(id, fieldnames(self.file.id_lookups.(ns)))
                disp(fprintf('** Error: Unable to find id "%s" in id_lookups when saving node', id));
                % dbstack
                error('save_node:missing_id', 'Missing id in id_lookups');
            end
            if ~ismember(self.path, fieldnames(self.file.id_lookups.(ns).(id)))
                disp(fprintf('** Error: Unable to find path "%s" in id_lookups when saving node %s',...
                    Utils.convert_utf_to_uc(self.path), Utils.convert_utf_to_uc(id)));
                % dbstack
                error('save_node:no_path', 'No valid path');
            end
            self.file.id_lookups.(ns).(id).(self.path).created{end+1} = self;
        end
        % save node in all_nodes, either at top level (if no parent) or inside
        % mstats structure of parent node
        if strcmp(self.parent, 'None')
            if ismember(self.path, fieldnames(self.file.all_nodes))
                self.file.all_nodes.(self.path){end+1} = self;
            else
                self.file.all_nodes.(self.path) = {self};
            end
        else
            if ~ismember(id, fieldnames(self.parent.mstats))
                if custom
                    % custom node created, add id to mstats of parent
                    self.parent.mstats.(Utils.convert_uc_to_utf(id)) = ...
                        struct( 'df', [], 'type',type, 'ns', ns, 'created', {{self}}, 'qty','?' );
                else
                    disp(fprintf('** Error: Unable to find key "%s" in parent mstats',  id));
                    disp('self.parent.mstats is');
                    disp(self.parent.mstats);
                    % dbstack
                    error('save_node:missing_key', 'Missing key in parents mstats');
                end
            else          
                % append node to parent created mstats                   
                self.parent.mstats.(id).created{end+1} = self;
            end
        end
    end

    function add_schema_attribute(self)
        % Add in attribute specifying id in schema or custom if requested in options
        schema_id = self.file.options.schema_id_attr;
        if ~isempty(fieldnames(self.sdef.df)) && strcmp(self.file.options.include_schema_id, 'True')
            % Normal functionined entity
            ns = self.sdef.ns;
            id = self.sdef.id;
            id = Utils.convert_utf_to_uc(id);
            schema = [ns  ':'  id];
            self.attributes.(schema_id) = struct('value', schema);
        else if strcmp(self.file.options.flag_custom_nodes, 'True')
            self.attributes.(schema_id) = struct('value', 'custom');
            end
        end
    end

    function merge_attrs(self)
        % Merge attributes specified by 'attrs=' option when creating node into
        %attributes functionined in specification language.  Save values using key 'nv'
        %(stands for 'new_value')
        if isstruct(self.attrs)
            aids = fieldnames(self.attrs);
            for i = 1:numel(aids)
                aid = aids{i};
                new_val = self.attrs.(aid);
                if ismember(aid, fieldnames(self.attributes))
                    if (ismember('value', fieldnames(self.attributes.(aid))) &&...
                        isequal(self.attributes.(aid).value, new_val))
                        continue;
                    end
                else
                    self.remember_custom_attribute(self.name, aid, new_val);
                    self.attributes.(aid) = {};
                end
                self.attributes.(aid).nv = new_val;
            end
        end
    end
         
    function set_attr_values(self)
        % set attribute values of hdf5 node.  Values to set are stored in
        % self.attributes, either in the values key (for values specified in
        % the specification language or in the 'nv' key (for values specified
        % via the API
        
        ats = self.attributes;  % convenient short name
        if isstruct(ats)
            aids = fieldnames(ats);
            for i = 1:numel(fieldnames(ats))
                aid = aids{i};
                if ismember('nv', fieldnames(ats.(aid)))
                    value = ats.(aid).nv;
                else if ismember('value', fieldnames(ats.(aid)))
                    value = ats.(aid).value;  
                    else
                        value = 'None';
                    end
                end
                if ~strcmp(value, 'None')
                    Utils.write_att(self.file.file_pointer, self.file.file_name,...
                        Utils.convert_utf_to_uc(self.full_path), aid, value);
                end
            end
        end
    end        
                
    function set_attr(self, aid, value, custom)
        if ~exist('custom', 'var')
                custom = '';
        end
        % Set attribute with key aid to value 'value' %
        if ~ismember(aid, fieldnames(self.attributes)) && strcmp(custom, '')
            self.remember_custom_attribute(self.name, aid, value);
            self.attributes.aid = {};
        else
            % TODO: validate data_type   
        end
        self.attributes.aid.nv = value;
        % Prevent segfault due to timing
        pause on; pause(0.5); pause off;
        Utils.write_att(self.file.file_pointer, self.file.file_name, self.path, aid, value);
    end
        
    function remember_custom_attribute(self, node_name, aid, value)
        % save custom attribute for later reporting %
        if ismember(node_name, fieldnames(self.file.custom_attributes))
            self.file.custom_attributes.(node_name).(aid)=value;
        else
            self.file.custom_attributes.(node_name) = struct( aid, value); 
        end
    end

    function [dest, changes] = merge_attribute_defs(self, dest, source, changes)
        % Merge attribute functioninitions.  This used for merges, 'parent_attributes',
        % and includes where attributes are specified.  Any changes to values are
        % stored in "changes" as a dictionary giving old and new values for each changed
        % attribute. The changes are used to update node attribute values in the hdf5 file
        % for the case of the parent_attributes merge.  If attribute key already
        % exist and merged attribute value starts with "+", append value, separated by
        % a comma.
        
        if ~exist('changes', 'var')
                changes = {};
        end
        aids = fieldnames(source);
        for i = 1:numel(aids)
            aid = aids{i};
            if ~ismember(aid, fieldnames(dest))
                % copy attribute, then check for append
                dest.(aid) = source.(aid); %check for deep copy
                if ismember('value', fieldnames(dest.(aid)))
                    if isa(dest.(aid).value, 'char') && strcmp(dest.(aid).value(1),'+')
                        dest.(aid).value = strrep(dest.(aid).value, '+', '');
                    end
                    changes.(aid) = dest.(aid).value;
                end
                continue;
            end
            if ~ismember('value', fieldnames(dest.(aid)))
                if isstruct(source.(aid))
                    if ismember('value', fieldnames(source.(aid)))
                        dest.(aid).value = source.(aid).value;
                        if isa(dest.(aid).value, 'char') && strcmp(dest.(aid).value(1),'+')
                            dest.(aid).value = strrep(dest.(aid).value, '+', '');                              
                        changes.(aid) = dest.(aid).value;
                        end
                        continue
                    end
                else
                    disp(fprintf(...
                        '** Error, merging attribute "%s" but value not specified in source or destination', aid));
                    % dbstack
                    error('merge_attribute_functions:unspecified_value',...
                        'Merging attribute without specified value');
                end
            else
                if ismember('value', fieldnames(source.(aid)))                       
                    % value given in both source and destination
                    dest.(aid) = Node.append_or_replace(dest.(aid), source.(aid),...
                        'value', sprintf('attribute %s', Utils.convert_utf_to_uc(aid)));
                    changes.(aid) = dest.(aid).value; % save changed value
                else
                    disp(fprintf(...
                        '** Warning, node at:\n%s\nmerging attribute "%s" but value to merge not specified.',...
                        Utils.convert_utf_to_uc(self.full_path), Utils.convert_utf_to_uc(aid)));
                    disp(' source attributes:');
                    disp(source.(aid));
                    disp('dest attributes:');
                    disp(dest.(aid));
                    error('merge_attribute_functions:unspecified_value',...
                        'Merging attribute without specified value');
                end
            end
        end
    end
  end
           
  methods(Static)
    function dest = append_or_replace(dest, source, key, ident)
        % dest and source are both dictionaries with common key 'key'.  If both
        % values of key are type str, and source[key] starts with "+", append the value
        % to dest[key], otherwise replace dest[key].  This is to implement appends
        % or replacing in 'include' directives.  ident is descriptive identifier
        % used for warning or error message. 
        prev_val = dest.(key); 
        new_val = source.(key);
        if isa(prev_val, 'char') && isa(new_val,'char') 
            if strcmp(Utils.convert_utf_to_uc(new_val(1)), '+')
                % need to append
                new_val = strrep(new_val, '+', '');
                if ~strcmp(prev_val,'')
                    dest.(key) = [prev_val  ',' new_val];
                    return;
                end
            end
        end
		% replace previous value by new value
		% first do some validation
		if ~strcmp(class(prev_val), class(new_val))
			disp(fprintf(...
                '** Error, type mismatch when setting %s, previous_type=%s, new type=%s;',...
                ident, class(prev_val), class(new_val)));
			disp('Previous value=')
            disp(prev_val);
			disp('New value=');
			disp(new_val);
			% dbstack
			error('append_or_replace:type_mismatch', 'Type mismatch');
        end
		if ~isa(new_val, 'char') || isa(new_val, 'int8') || isa(new_val, 'int16') || ...
                isa(new_val, 'int32') || isa(new_val, 'int64') || isa(new_val, 'double') || ...
                isa(new_val, 'single')
			disp(fprintf('** Error, invalid type (%s) assignd to %s' , class(new_val), ident));
			disp('Should be string, int or float.  Value is:');
			disp(new_val)
			% dbstack
			error('append_or_replace:invalid_type', 'Invalid type'); 
        end
		% TODO: check for data_type matching value type
		dest.(key) = new_val;
    end
                   
    
    end
end




