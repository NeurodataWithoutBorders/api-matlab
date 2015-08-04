classdef Group < Node
    % Subclass of Node, manages and creates groups in the file
    
    properties
        parent_attributes
        description
        expanded_def
        includes
        mstats
    end
    
    methods
        
        %hdf5 group object
        function self = Group(file, sdef, name, path, attrs, parent, link_info)
        % Create group object
        % file - file object
        % sdef - dict with elements:
        %     type - 'group' or 'dataset'
        %     id - id in structures (or parent group) for node
        %     id_noslash - id without trailing slash (in case is a group)
        %     ns - namespace structure is in
        %     df - functioninition of node (dictionary)
        % name - name of node in case id is in <angle brackets>, OR other Group
        %     object if making link to that group, OR pattern for linking.  See link (below)
        % path - path of where node should be created
        % attrs - attribute values specified when creating group
        % parent - parent group if this node was made inside another specified group
        %     None otherwise
        % link_info - Either None, or info to to make link.  If linking to internal node,
        %     contains key "node".  If linking to external file, contains key: "extlink"
        %     and value is file,path (file, comma, then path). 

            if ~exist('link_info', 'var')
                link_info = {};
            end
            self@Node(file, sdef, name, path, attrs, parent, link_info)
            self.description = {};
            self.parent_attributes = struct();
            self.get_expanded_def_and_includes();
            self.get_member_stats();
            self.add_parent_attributes();
            self.merge_attrs();
            if ~isempty(self.link_info)
                % this group is linking to another.  Already done in Node class.  Nothing to do here
            else
                Utils.create_group(self.file.file_pointer, self.full_path);
            % add attribute values to node
            self.set_attr_values();
            end
        end


        function add_parent_attributes(self)
            %Add any parent attributes to parent group
            if numel(fieldnames(self.parent_attributes)) == 0
                return;
            end
            dest = self.parent.attributes;
            source = self.parent_attributes;
            changes = struct();
            [dest, changes] = self.merge_attribute_defs(dest, source, changes);
            chs = fieldnames(changes);
            for  i = 1:numel(chs)
                aid = chs{i};
                chs_value = changes.(chs{i}); 
                % may need modifying for MATLAB
                if ~Utils.node_exists(self.file.file_pointer, self.path)
                    % create parent node since it does not exist
                    disp('trying to set parent attributes on non-registered parent node:')
                    disp(fprintf('Non-registered parent node is: "%s"', self.path));
                    %dbstack
                    error('add_parent_attributes:non_registered_parent_node', 'Non-registered parent node');
                end
                Utils.write_att(self.file.file_pointer, self.file.file_name, self.path, aid, chs_value);
            end
        end
                   
                                    
        function get_expanded_def_and_includes(self)
        % Process any 'merge', 'parent_attribute' or 'description' entities.
        % Save copy of functioninition with merges done in self.expanded_def
        % Save all includes in self.includes
            self.expanded_def = struct();
            self.includes = struct();
            if isstruct(self.sdef.df)
                if ismember('merge', fieldnames(self.sdef.df))
                    self.process_merge(self.expanded_def, self.sdef.df.merge, self.includes);
                end
            end
            self.merge_def(self.expanded_def, self.sdef, self.includes);
            % merge any attributes to self.attributes for later processing
            if ismember('attributes', fieldnames(self.expanded_def))
                atts = fieldnames(self.expanded_def.attributes);
                for i = 1:numel(atts)
                    att = atts{i};
                    self.attributes.(att) = self.expanded_def.attributes.(att);
                end
               self.expanded_def = rmfield(self.expanded_def, 'attributes');
            end
        end
            
        function get_member_stats(self)
        % Build dictionary mapping key for each group member to information about the member.
        % Also processes includes.  Save in self.mstats 
            self.mstats = struct();
            % add in members from expanded_def (which includes any merges)
            expf = fieldnames(self.expanded_def);
            for i = 1:numel(expf)
                qid = expf{i};
                % check for trailing quantity specifier (!, *, +, ?).  Not for name space.
                % ! - required (functionault), * - 0 or more, + - 1 or more, ? - 0 or 1
                [id, qty] = self.file.parse_qty(Utils.convert_utf_to_uc(qid), '!');
                id_orig = id;
                id = Utils.convert_uc_to_utf(id);
                if ismember(id, fieldnames(self.mstats))
                    disp(fprintf('** Error, duplicate (%s) id in group', Utils.convert_utf_to_uc(id)));
                    %dbstack
                    error('get_member_stats:duplicate_id', 'Duplicate id in group');
                end
                if strcmp(id_orig(end),'/')
                    type = 'group'; 
                else
                    type = 'dataset';
                end
                self.mstats.(id) = struct( 'ns', self.sdef.ns, 'qty', qty,...
                    'df', self.expanded_def.(qid), 'created', [], 'type', type);
            end
            % add in members from any includes
            % print "** processing includes"
            incl = fieldnames(self.includes);
            for  i = 1:numel(incl)
                qidq = incl{i};
                [qid, qty] = self.file.parse_qty(Utils.convert_utf_to_uc(qidq), '!');
%                 qid_orig = qid;
%                 qid = Utils.convert_uc_to_utf(qid);
                % print "processing include", qid
                sdef = self.file.get_sdef(qid, self.sdef.ns, 'Referenced in include');
                % print "obtained sdef:"
                % pp.pprint(sdef)
                modifiers = self.includes.(qidq);
                if numel(modifiers) > 0
                    % need to incorporate modifications to functioninition of included child members
                    df = sdef.df; %deep copy
                    % self.modify(df, modifiers)
                    df = Group.merge(df, modifiers);  % merges modifiers into functioninition
                    % print "df after merging modifiers:"
                else
                    df = sdef.df;
                    % print "df after copy:"
                end
                id = sdef.id;
                type = sdef.type;
                % pp.pprint(df)
                % qty = '!'  % assume includes are required
                if ismember(id, fieldnames(self.mstats))
                    disp(fprintf('** Error, duplicate (%s) id in group, referenced by include',...
                        Utils.convert_utf_to_uc(id)));
                    % dbstack
                    error('get_member_stats:duplicate_id', 'Duplicate id_referenced_by include');
                end
                self.mstats.(id) = struct('ns', self.sdef.ns, 'qty', qty,...
                    'df', df, 'created', [], 'type', type );
            end
            % print "after processing all includes, mstats is:"
            % pp.pprint(self.mstats)
        end
    
            
        function display_g(self)
        % Displays information about group (used for debugging)
            disp('\n\n***********************\n');
            disp(fprintf('Info about group %s, name=%s, path=%s', self.sdef.id,... 
                self.name, self.path));
            disp('sdef=');
            disp(self.sdef);
            disp('expanded_def=');
            disp(self.expanded_def);
            disp('includes=');
            disp(self.includes);
            disp('parent_attributes=');
            disp(self.parent_attributes);
            disp('attributes=');
            disp(self.attributes);
            disp('mstats=');
            disp(self.mstats);
        end
                                 
        function process_merge(self, expanded_def, initial_to_merge, to_include)
            all_to_merge = self.find_all_merge(initial_to_merge);
            for i = 1:numel(all_to_merge)
                qid = Utils.convert_utf_to_uc(all_to_merge{i});
                sdef = self.file.get_sdef(qid, self.sdef.ns, 'Referenced in merge');
                self.merge_def(expanded_def, sdef, to_include);
            end
        end
        
        function checked = find_all_merge(self, initial_to_merge)
        % Builds list of all structures to be merged.
        % Includes merges containing a merge """
            to_check = initial_to_merge; %copy.copy
            checked = {};
            while numel(to_check) > 0
                qid = to_check{1};
                to_check(1) = [];
                if ismember(qid, checked)
                    continue;
                end
                sdef = self.file.get_sdef(...
                    Utils.convert_utf_to_uc(qid), self.sdef.ns, 'Referenced in merge');
                
                if ismember('merge', fieldnames(sdef.df));
                    for i = 1:numel(sdef.df.merge)
                        to_check{end+1} = sdef.df.merge{i};
                    end
                end
                checked{end+1} = qid;
            end
            
        end
            
            
        function merge_def(self, expanded_def, sdef, to_include)
        % Merge structure functionined by sdef into expanded_def.  Also
        % Also sets to_include to set of structures to include.
            if isstruct(sdef.df)
                ids = fieldnames(sdef.df);
            else
                ids = {};
            end
            for i = 1:numel(ids)
                id = ids{i};
                if (((strcmp(id,'description') && isa(sdef.df.(id), 'char')) && ...
                    ~ismember('_description', fieldnames(sdef.df))) || strcmp(id,'_description'))
                    % append this description to any other descriptions specified by previous merge
                    description = sprintf('%s:%s- %s', sdef.ns, ...
                        Utils.convert_utf_to_uc(sdef.id), Utils.convert_utf_to_uc(sdef.df.(id)));
                    self.description{end+1} = (description);
                    continue;
                end
                if strcmp(id,'merge')
                    continue;
                end
                if strcmp(id,'parent_attributes')
                    if isempty(self.parent_attributes)
                        self.parent_attributes = sdef.df.(id);
                    else
                        new_fields = fieldnames(sdef.df.(id));
                        for j = 1:numel(new_fields)
                            new_field = new_fields{j};
                            self.parent_attributes.(new_field) = sdef.df.(id).(new_field);
                        end
                    end
                    continue;
                end
                if strcmp(id,'include')
                    new_fields = fieldnames(sdef.df.(id));
                    for j = 1:numel(new_fields)
                        new_field = new_fields{j};
                        self.includes.(new_field) = sdef.df.(id).(new_field);
                    end
                    continue;
                end
                if ismember(id, fieldnames(self.expanded_def))
                    % means id from previous merge conflicts
                    if strcmp(id, 'attributes')
                        self.expanded_def.(id) = ...
                            self.merge_attribute_defs(self.expanded_def.(id), sdef.df.(id));
                    % if value for both are dictionaries, try recursive merge
                    else if isstruct(self.expanded_def.(id)) && isstruct(sdef.df.(id))
                        self.expanded_def.(id) = self.merge(self.expanded_def.(id), sdef.df.(id));
                        else
                            disp('** Error');
                            disp(fprintf('Conflicting key (%s) when merging "%s" when doing', id, sdef.id));
                            disp(fprintf('make_group(%s, %s, path=%s)' ,...
                                Utils.convert_utf_to_uc(self.sdef.id), Utils.convert_utf_to_uc(self.name),...
                                Utils.convert_utf_to_uc(self.path)));
                            disp('expanded_def is:');
                            disp(expanded_def.(id));
                            disp('sdef is:');
                            disp(sdef.df.(id));
                            %dbstack
                            error('merge_def:conflicting_key', 'Conflicting key during merging');
                        end
                    end
                else
                    % no conflict, just copy functioninition for id
                    % deep copy so future merges do not change original
                    self.expanded_def.(id) = sdef.df.(id); %deep copy
                end
            end
        end
        function grp = make_group(self, id, varargin) 
        % Create a new group inside the current group.
        % id - identifier of group
        % name - name of group in case name is not specified by id (id is in <angle brackets>)
        %     *OR* Group node linking to
        %     *OR* pattern specifying a link: link:path or extlink:file,path
        % attrs - attribute values for group that are specified in API call
        % link - specified link, of form link:path or extlink:file,path.  Only needed
        %     if name must be used to specify local name of group
        % abort - If group already exists, abort if abort is True, otherwise return previously
        %     existing group. 
            % parse input arguments
            arg_names = { 'name', 'attrs', 'link', 'abort'};
            arg_types = { 'char', 'cell',  'char', 'logical' };
            arg_default={ '',     {},      '',     true };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            link = arg_vals.link;
            abort = arg_vals.abort;
            gid = [id  '/'];
            sgd = self.get_sgd(gid, name);
            path = self.full_path;
            link_info = self.file.extract_link_info(name, link, 'Group');
            if abort
                % id = sgd['id'].rstrip('/')  % not sure if need this
                grp = self.file.get_existing_group(path, id, name);
                if ~isempty(grp)
                    return;
                end
            end
            grp = Group(self.file, sgd, name, path, attrs, self, link_info);
            % self.mstats[gid]['created'].append(grp)
        end
       
        function grp = make_custom_group(self, qid, varargin) 
        % Creates custom group.
        % qid - qualified id of structure or name of group if no matching structure.
        %     qid is id with optional namespace (e.g. core:<...>).  Path can
        %     also be specified in id (path and name are combined to produce full path)
        % name - name of group in case id specified is in <angle brackets>
        % path - specified path of where group should be created.  If not given
        %     or if relative path.  Only needed if location ambiguous
        % attrs - attribute values for group that are specified in API call
            % parse input arguments
            arg_names = { 'name', 'path', 'attrs'};
            arg_types = { 'char', 'char', 'cell' };
            arg_default={ '',     '',     {} };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            path = arg_vals.path;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            gslash = '/';
            parent = self;
            [sdef, name, path] = self.file.get_custom_node_info(qid, gslash, name, path, parent);   
            grp = Group(self.file, sdef, name, path, attrs, parent);
        end
            
        function node = get_node(self, path, abort)
        % returns node inside current group.  If node not present, return None
        % (if abort == False), otherwise return True 
            if ~exist('abort','var')
                abort = true;
            end
            if strcmp(path(1),'/')
                node = self.file.get_node(path, abort);
            else
                node = self.file.get_node([self.full_path '/' path], abort);
            end
        end
                    
            
        function sgd = get_sgd(self, id, name)
            % Get functioninition of group or dataset being created inside a group)
            % check if id exists in group functioninition
            id_orig = id;
            id = Utils.convert_uc_to_utf(id);
            if ismember(id, fieldnames(self.mstats)) && ismember('df', fieldnames(self.mstats.(id)))
                % print "id %s in mstats" % id
                if strcmp(id_orig(end), '/')
                    type = 'group';  
                else
                    type = 'dataset';
                end
                sgd = struct('id', id, 'type', type, 'ns', self.sdef.ns, 'df', self.mstats.(id).df);
                return;
            else
                % see if parent group is specified in locations; if so, check for id in 
                % locations list of members of parent group.  Example for nwb format is are
                % "UnitTimes/" inside <module>/.  <module> is parent group
                pid = self.sdef.id;  % parent id, e.g. "<module>"
                ns = self.sdef.ns;
                if ismember(pid, fieldnames(self.file.ddef.(ns).locations))
                    if ismember(id_orig, self.file.ddef.(ns).locations.(pid))
                        if strcmp(id_orig(end), '/')
                            type = 'group';  
                        else
                            type = 'dataset';
                        end
                        % add id to mstats so can register creation of group
                        self.mstats.(id) = struct('ns',ns, 'created', [], 'qty', '+',... 
                            'type', type); % todo: jeff, need to check df
                        sgd = self.file.get_sdef(id_orig, ns, 'referenced in make_subgroup');
                        return;
                    else
                        disp(fprintf('found parent %s in locations, but %s not inside',...
                            Utils.convert_utf_to_uc(pid), Utils.convert_utf_to_uc(id)));
                        disp('locations contains:');
                        disp(self.file.ddef.(ns).locations.(pid));
                    end
                else
                    disp(fprintf('did not find parent %s in locations for namespace %s',...
                        Utils.convert_utf_to_uc(pid), ns));
                end
            end
            disp(fprintf('** Error, attempting to create "%s" (name="%s") inside group:',...
                Utils.convert_utf_to_uc(id), name));
            disp(Utils.convert_utf_to_uc(self.full_path));
            disp(fprintf('But "%s" is not a member of the structure for the group',...
                Utils.convert_utf_to_uc(id)));
            disp('Valid options are:');
            disp(Utils.convert_utf_to_uc(strjoin(fieldnames(self.mstats), '\n'))); 
            disp(fprintf(...
                'Extra information (for debugging):  Unable to find functioninition for node %s',...
                Utils.convert_utf_to_uc(id)));
            disp('mstats=');
            disp(self.mstats)
%             dbstack
            error('get_sgd:m_stats_error', 'm_stats error');
        end
            
            
        function ds = set_dataset(self, id, value, varargin)
        % Create dataset inside the current group.
        % id - id of dataset.
        % name - name of dataset in case id is in <angle brackets>
        % value - value to store in dataset, or Dataset object (to link to another dataset,
        %     *OR* a string matching pattern: link:<path> or extlink:<file>,<path>
        %     *OR* a string matching pattern: link:<path> or extlink:<file>,<path>
        %     to specify respectively a link within this file or an external link.
        % path - specified path of where dataset should be created.  Only needed if location ambiguous
        % attrs = attributes specified for dataset
        % dtype - if provided, included in call to h5py.create_dataset
        % compress - if True, compress provided in call to create_dataset
            % parse input arguments
            arg_names = { 'name', 'attrs', 'dtype', 'compress'};
            arg_types = { 'char', 'cell',  'char', 'logical' };
            arg_default={ '',     {},      '',     false };
            arg_vals = Utils.parse_arguments(varargin, arg_names, arg_types, arg_default);
            name = arg_vals.name;
            attrs = struct();
            for i = 1:2:numel(arg_vals.attrs)
                attrs.(arg_vals.attrs{i}) = arg_vals.attrs{i+1};
            end
            dtype = arg_vals.dtype;
            compress = arg_vals.compress;
            sgd = self.get_sgd(id, name);
            link_info = self.file.extract_link_info(value, '', 'Dataset');
            path = self.full_path;
            ds = Dataset(self.file, sgd, name, path, attrs, self, value, dtype, compress, link_info);
            % self.mstats[id]['created'].append(ds) 
        end
    
           
        function ds = set_custom_dataset(self, qid, value, varargin) 
        % Creates custom dataset that is inside the current group.
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
            parent = self;
            [sdef, name, path] = self.file.get_custom_node_info(qid, gslash, name, path, parent);   
            ds = Dataset(self.file, sdef, name, path, attrs, parent, value, dtype, compress);
        end
    end
    
    
    methods(Static)
                
        function a = merge(a, b, path)
        % merges b into a
        % from: http://stackoverflow.com/questions/7204805/dictionaries-of-dictionaries-merge
            if ~exist('path', 'var')
                path = 'None';
            end
            if strcmp(path, 'None')
                path = {};
            end
            b_keys = fieldnames(b);
            for i = 1:numel(b_keys)
                key = b_keys{i};
                if ismember(key, fieldnames(a))
                    if isstruct(a.(key)) && isstruct(b.(key))
                        if strcmp(key,'attributes')
                            self.merge_attribute_defs(b, a);
                        else
                            a.(key) = Group.merge(a.(key), b.(key),[path  char(key)]);
                        end
                    else if strcmp(a.(key), b.(key))
                                % same leaf value
                        else
                            % raise Exception('Conflict at %s' % '.'.join(path + [str(key)]))
                            a = Node.append_or_replace(a,b,key, [path '/' char(key)]);
                        end
                    end
                        
                else
                    a.(key) = b.(key);
                end
            end
        end

    end
    
end

