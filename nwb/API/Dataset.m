classdef Dataset < Node
    % Subclass of Node, manages and creates datasets in the file
    
    properties
        dsinfo
    end
    
    methods
        
            function self = ...
                    Dataset(file, sdef, name, path, attrs, parent, value, dtype, compression, link_info)
            % Create Dataset object
            % file - file object
            % sdef - dict with elements:
            %     type - 'group' or 'dataset'
            %     id - id in structures (or parent group) for node
            %     id_noslash - id without trailing slash (in case is a group)
            %     ns - namespace structure is in
            %     df - functioninition of node (dictionary)
            % name - name of node in case id is in <angle brackets>
            % path - path of where node should be created
            % attrs - dictionary of attribute values specified in API call creating node
            % parent - parent group if this node was made inside another specified group
            %     None otherwise
            % value - value to store in dataset *OR* a Datasets object to make a link to
            %     an internal Dataset, *OR* a string matching either of the patterns:
            %     h5link:<path> or h5extlink:<file>,<path>
            %     to specify respectively a link within this file or an external link.
            % dtype - if specified, datatype used in call to h5py.create_dataset
            % compression - True if should do compression.  used in call to hfpy.create_dataset
            % link_info - Either None, or info used to make link.  If linking to internal node,
            %     contains key "node".  If linking to external file, contains key: "extlink"
            %     and value is file,path (file, comma, then path).  
                if ~exist('link_info', 'var')
                    link_info = '';
                end
                self@Node(file, sdef, name, path, attrs, parent, link_info);
                if ismember('attributes', fieldnames(self.sdef.df))
                    self.attributes = self.sdef.df.attributes; %deepcopy
                end
                self.dsinfo = self.mk_dsinfo(value);
                self.merge_attribute_defs(self.attributes, self.dsinfo.atags);
                self.merge_attrs();
                if isempty(self.link_info)
                    % creating new dataset (normally done)
                    self.link_node = 'None';
                    if ~isempty(compression)
                        compress = 'gzip'; 
                    else
                        compress = 0;
                    end
                    if ismember(self.dsinfo.dtype, {'integer', 'float', 'integer cell', 'float cell'})
                        if ismember(self.dsinfo.dtype, {'integer cell', 'float cell'})
                            value = cell2mat(value);
                        end
                        Utils.create_numeric_dataset(self.file, self.path, self.name, value, compress);
                    end
                    if ismember(self.dsinfo.dtype, {'logical', 'logical cell'})
                        if strcmp(self.dsinfo.dtype, 'logical cell')
                            value = cell2mat(value);
                        end
                        value = double(value);
                         Utils.create_numeric_dataset(self.file, self.path, self.name, value, compress);
                    end
                    if ismember(self.dsinfo.dtype, {'char', 'cellstr'})
                        Utils.create_string_dataset(self.file, self.path, self.name, value, compress);
                    end
                end
                self.set_attr_values();
            end


            function atags = ds_atags(self)
                % Returns tags in dataset functioninition that are mapped to attributes in
                % hdf5 file.  Tags are in JSON like structure, giving the description and
                % mapping (new name in attributes) of each tag.
                atags = struct(...
                    'unit', struct(...
                        'atname', 'unit',...
                        'data_type', 'text',...
                        'description', 'Unit of measure for values in data'),...
                    'description', struct(...
                        'atname', 'description',...
                        'data_type', 'text',...
                        'description', 'Human readable description of data'),...
                    'comments', struct(...
                        'atname', 'comments',...
                        'data_type', 'text',...
                        'description', 'Comments about the data set'),...
                    'references', struct(...
                        'atname', 'references',...
                        'data_type', 'text',...
                        'description', 'path to group, diminsion index or field being referenced'),...
                    'semantic_type', struct(...
                        'atname', 'semantic_type',...
                        'data_type', 'text',...
                        'description', 'Semantic type of data stored'),...
                    'scale', struct(...
                        'atname', 'conversion',...
                        'data_type', 'float',...
                        'description', 'Scale factor to convert stored values to units of measure'));
            end
               

            function dsinfo = mk_dsinfo(self, val)
            % Make 'dsinfo' - dataset info structure.  This structure is saved and
            % will later be used to validate relationship created by common dimensions and
            % by references.  val (parameter) is the value being assigned to the dataset.
            % The returned structure 'dsinfo' contains:
            %     dimensions - list of dimensions
            %     dimdef - functioninition of each dimension
            %         scope - local/global (local is local to containing folder)
            %         type - type of dimension (set, step, structure)
            %         parts - components of structure dimension
            %         len - actual length of dimension in saved dataset
            %     atags - values for special tags that are automatically mapped to
            %         attributes.  These are specified by structure functionined in ds_atags.
            %         values are returned in a structure used for attributes which
            %         includes a data_type, value and description.
            %     dtype - data type
            
                dsinfo = struct();
                atags = self.ds_atags();
                dsinfo.dimensions = struct();
                dsinfo.dimdef = struct();
                dsinfo.dtype = '';     % type actually present in val, e.g. 'int32'
                dsinfo.data_type = ''; % type specified in functioninition, e.g. int, float, number, text
                dsinfo.shape = '';     % shape of array or string 'scalar'
                dsinfo.atags = struct();
                df = self.sdef.df;
                % save all referenced atags
                tags = fieldnames(atags);
                for i = 1:numel(tags)
                    tag = tags{i};
                    if ismember(tag, fieldnames(df)) && ~strcmp(tag, 'description')  % don't save descriptions by functionault
                        dsinfo.atags.(atags.(tag).atname) = struct(...
                            'data_type', atags.(tag).data_type, ...
                            'description', atags.(tag).description, ...
                            'value', df.(tag));
                    end
                end
                if ~isempty(self.link_info) % link to other dataset
                    % setting this dataset to another dataset by a link
                    % get previously saved info about dataset linking to
                    % import pdb; pdb.set_trace()
                    if ismember('node', fieldnames(self.link_info))
                        % linking to node in current file
                        node = self.link_info.node;
                        dsinfo.shape = node.dsinfo.shape;
                        dsinfo.dtype = node.dsinfo.dtype;
                    else if ismember('extlink', fieldnames(self.link_info))
                        % linking to external file.  Cannot do validation of datatype
                        % leave dsinfo.shape. and dsinfo.dtype. empty to indicate both are unknown
                            
                        else
                            disp('** Error: invalid key in link_info');
                            error('mk_dsinfo:invalid_key_in_link_info','invalid key in link_info');
                        end
                    end
                else
                    % get type of object as string
                    % currently supported: numeric, boolean, char, 
                    % cells of uniform type char, boolean or numeric
                    if isnumeric(val)
                        if isinteger(val)
                            dsinfo.dtype = 'integer';
                        else if isfloat(val)
                                dsinfo.dtype = 'float';
                            else
                                dsinfo.dtype = 'unknown';
                            end
                        end
                        if max(size(val)) == 1
                            dsinfo.shape = 'scalar';
                        else
                            dsinfo.shape = size(val);
                        end
                    else if islogical(val)
                            dsinfo.dtype = 'logical';
                            if max(size(val)) == 1
                                dsinfo.shape = 'scalar';
                            else
                                dsinfo.shape = size(val);
                            end
                        else if ischar(val)
                            dsinfo.dtype = 'char';
                            dsinfo.shape = 'scalar';
                            else if iscellstr(val)
                                    dsinfo.shape = size(val);
                                    dsinfo.dtype = 'cellstr';
                                else if isa(val, 'cell')
                                        dsinfo.shape = size(val);
                                        try 
                                            valarr = cell2mat(val);
                                            if isnumeric(valarr)
                                                if isfloat(valarr)
                                                    dsinfo.dtype = 'float cell';
                                                else if isinteger(valarr)
                                                        dsinfo.dtype = 'integer cell';
                                                    else
                                                        dsinfo.dtype = 'unknown cell';
                                                    end
                                                end
                                            else if islogical(valarr)
                                                    dsinfo.dtype = 'logical cell';
                                                else
                                                    dsinfo.dtype = 'unknown cell';
                                                end
                                            end
                                        catch
                                            dsinfo.dtype = 'mixed cell';
                                        end
                                    else 
                                        dsinfo.dtype = 'unknown';
                                        dsinfo.shape = '';
                                    end
                                end
                            end
                        end
                    end                                                                
                end
                if ismember('dimensions', fieldnames(df))
                    if strcmp(dsinfo.shape,'scalar')
                        disp('** Error, scalar dimension mismatch');
                        %dbstack
                        error('mk_ds_info:scalar_mismatch', 'scalar dimension mismatch'); 
                    end
                    dsinfo.dimensions = df.dimensions;
                    if ~isempty(dsinfo.shape) && max(size(dsinfo.dimensions) ~= dsinfo.shape)
%                         disp(fprintf(...
%                             ['** Warning, %i dimensions functionined in data set,'...
%                             'but number of dimensions in value assigned is %i'],...
%                             numel(dsinfo.dimensions),dsinfo.shape(2)));
                        %dbstack
%                         warning('mk_ds_info:dimension_mismatch', 'Dimension mismatch in dataset'); 
                    else
                    % check for any dimensions functionined in dataset
                        dims = dsinfo.dimensions;
                        for i = 1:numel(dims)
                            if strcmp(dims{i}(end), ('^'))
                                scope = 'global';
                            else
                                scope = 'local';
                            end
                            if ~isempty(dsinfo.shape)
                                dsinfo.dimdef.(dims{i}) = ...
                                    struct('scope',scope, 'len', dsinfo.shape(i)); % TO DO: check len value, taking shape doesn't seem correct
                            else
                                dsinfo.dimdef.(dims{i}) = struct('scope',scope, 'len', 0);
                            end
                            if ismember(dims{i}, fieldnames(df))
                                dsinfo.dimdef.(dims{i}) = Group.merge( dsinfo.dimdef.(dims{i}),df.(dims{i}));
                            end
                        end
                    end
                end
                if ismember('attributes', fieldnames(df))
                     % do nothing here, attributes moved to self.attributes 
                end
                if ismember('data_type', fieldnames(df))
                    dsinfo.data_type = df.data_type;
                else
                    if isempty(fieldnames(df))
                        % nothing specified for dataset functioninition.  Must be custom dataset
                        % (being created by "set_custom_dataset").  Do no validation
                        return;
                    end
                    disp('** Error: "data_type" not specified in dataset functioninition');
                    disp('functioninition is:');
                    disp(df)
                    %dbstack
                    error('mk_ds_info:unspecified_data_type', 'Unspecified datatype');
                end
                % Now, some simple validation
                if ~isempty(dsinfo.dtype) && ~Dataset.valid_dtype(dsinfo.data_type, dsinfo.dtype)
                    disp(fprintf(...
                        '** Error, expecting type "%s" assinged to dataset, but value being stored is type %s',...
                        dsinfo.data_type, dsinfo.dtype));
                    error('mk_ds_info:type_mismatch', 'data type mismatch');
                end
                % make sure everything functionined in dataset functioninition is valid
                keys = fieldnames(df);
                for i = 1:numel(keys)
                    if (ismember(keys{i}, {'dimensions', 'data_type', 'attributes'}) || ...
                        ismember(keys{i}, fieldnames(atags)) || ismember(keys{i}, dsinfo.dimensions))
                        continue;
                    end
                    disp(fprintf('** Error, invalid key (%s) in dataset functioninition' , keys{i}));
                    disp('dataset functioninition is:');
                    disp(df)
                    %dbstack
                    error('mk_ds_info:invalid_key', 'Invalid key in dataset');
                end
            end
    end
                                                                  
    methods(Static)
        function valid = valid_dtype(expected, found)
            % Return True if found data type is consistent with expected data type.
            % found - data type generated by python dtype converted to a string.
            % expected - one of: 'bool', 'byte', 'text', 'number', 'int', 'float' or 'any' 
            if ~ismember(expected, {'bool', 'byte', 'text', 'number', 'int', 'float', 'any'})
                disp(fprintf(...
                    '** Error: invalid value (%s) in functioninition file for expected data type"',...
                    expected))
                error('valid_dtype:invalid_expected_value', 'Invalid value for expected data_type');
            end
            if strcmp(expected,'any')
                valid = true;
                return;
            end
            if ismember(found, {'char', 'cellstr'})...
                    || ~isempty(regexp(found, '^\|S\d+$', 'match')) || strcmp('byte', found)
                % print "found dtype '%s', interpreting as string" % dtype
                dtype = 'text';
            else if ismember('logical', found)
                dtype = 'bool';
                else if ismember(found, {'integer', 'integer cell'})
                    dtype = 'int';
                    else if ismember(found, {'float', 'float cell'})
                        dtype = 'float';
                        else
                            disp(fprintf(...
                                ['** Error: unable to recognize data type (%s) for validation.'...
                                'Expecting compatible with "%s"'], found, expected));
                            error('valid_dtype:unknown_data_type','Unknown found data_type');
                        end
                    end
                end
            end
            valid = (strcmp(dtype, expected) ||...
                (ismember(dtype, {'int', 'float', 'bool'} ) && strcmp(expected,'number')));
        end
            
    end
    
end

