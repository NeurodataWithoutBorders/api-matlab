classdef Utils
    % helper functions from TAPI, Jeff's hybrid and special functions to
    % handle the fields of structs and their output and for reading and
    % writing to hdf5
    

    
    methods(Static)
    
    %% Utility routines useful for creating NWB files 
    
        function content = load_file(filename)
            %Load content of a file.  Useful 
            % for setting metadata to content of a text file
            f = open(filename, 'r');
            content = f.read();
            f.close();
        end
        


    %% Imaging utilities, from: borg_modules.py
    % These functions are untested, use at your own risk
        
        function add_roi_mask_pixels(seg_iface, image_plane, name, desc, pixel_list, weights, width, height, start_time)

        % Adds an ROI to the module, with the ROI defined using a list of pixels.
        % 
        % Args:
        %     *image_plane* (text) name of imaging plane
        % 
        %     *name* (text) name of ROI
        % 
        %     *desc* (text) description of ROI
        % 
        %     *pixel_list* (2D int array) array of [x,y] pixel values
        % 
        %     *weights* (float array) array of pixel weights
        % 
        %     *width* (int) width of reference image, in pixels
        % 
        %     *height* (int) height of reference image, in pixels
        % 
        %     *start_time* (double) <ignore for now>
        % 
        % Returns:
        %     *nothing*

            if ~exist('start_time','Value')
                start_time = 0;
            end
            % create image out of pixel list
            img = zeros(height, width);
            for i =1:numel(pixel_list)
                y = pixel_list(i,1);
                x = pixel_list(i,2);
                img(y,x) = weights(i);
            add_masks(seg_iface, image_plane, name, desc, pixel_list, weights, img, start_time);
            end
        end
        
        function add_roi_mask_img(seg_iface, image_plane, name, desc, img, start_time)
        % Adds an ROI to the module, with the ROI defined within a 2D image.
        % 
        % Args:
        %     *seg_iface* (h5gate Group object) ImageSegmentation folder
        % 
        %     *image_plane* (text) name of imaging plane
        % 
        %     *name* (text) name of ROI
        % 
        %     *desc* (text) description of ROI
        % 
        %     *img* (2D float array) description of ROI in a pixel map (float[y][x])
        % 
        %     *start_time* <ignore for now>
        % 
        % Returns:
        %     *nothing*
            if ~exist('time','Value')
                time = 0;
            end
            % create pixel list out of image
            pixel_list = [];
            for y = 1:numel(img)
                row = img(y)
                for x = 1:numel(row)
                    if row(x) ~= 0
                        pixel_list(end) = [x, y];
                        weights(end) = row(x);
                    end
                end
            end
            add_masks(seg_iface, image_plane, name, pixel_list, weights, img, start_time);
        end
        
        function add_masks(seg_iface, image_plane, name, desc, pixel_list, weights, img, start_time)
        % Internal/private function to store the masks. 
        % The public functions (add_roi_*) take either a pixel list or an image, and they generate the missing one
        % from the specified one. This procedure takes both pixel list and pixel map and writes them to the HDF5
        % file.
        % 
        % Note: Multiple sequential masks are suppored by the spec. The API only supports one presently
        % 
        % Args:
        %     *seg_iface* (h5gate Group object) ImageSegmentation folder
        % 
        %     *image_plane* (text) name of imaging plane
        % 
        %     *name* (text) name of ROI
        % 
        %     *desc* (text) description of ROI
        % 
        %     *pixel_list* (2D int array) array of [x,y] pixel values
        % 
        %     *weights* (float array) array of pixel weights
        % 
        %     *img* (2D float array) description of ROI in a pixel map (float[y][x])
        % 
        %     *start_time* <ignore for now>
        % 
        % Returns:
        %     *nothing*

            % create folder for imaging plane if it doesn't exist
            %- if image_plane not in self.iface_folder:
            folder_path = [seg_iface.full_path  '/'  image_plane];
            abort=False;
            ip = seg_iface.file.get_node(folder_path, abort);
            if strcmp(ip, 'None')
                %- ip = self.iface_folder.create_group(image_plane)
                ip = seg_iface.make_group('<image_plane>', image_plane);
                % array for roi list doesn't exist either then -- create it
                %- self.roi_list[image_plane] = []
            end
            %- else:
            %-    ip = self.iface_folder[image_plane]
            % create ROI folder
            %- ip.create_group(name)
            roi_folder = ip.make_group('<roi_name>', name);
            % save the name of this ROI
            %- self.roi_list[image_plane].append(name)
            % add data
            %- roi_folder = ip[name]
            %- pm = roi_folder.create_dataset('pix_mask_0', data=pixel_list, dtype='i2', compression=True)
            compression=true; dtype='i2';
            pm = roi_folder.set_dataset('pix_mask_0', pixel_list, dtype, compression); 
            %- pm.attrs['weight'] = weights
            pm.set_attr('weight', weights);
            %- pm.attrs['help'] = 'Pixels stored as (x, y). Relative weight stored as attribute.'
            pm.set_attr('help', 'Pixels stored as (x, y). Relative weight stored as attribute.');
            % im = roi_folder.create_dataset('img_mask_0', data=img, dtype='f4', compression=True)
            compression=true; dtype='f4';
            im = roi_folder.set_dataset('img_mask_0', img, dtype, compression);
            %- im.attrs['help'] = 'Image stored as [y][x] (ie, [row][col])'
            im.set_attr('help', 'Image stored as [y][x] (ie, [row][col])');
            %- roi_folder.create_dataset('start_time_0', data=start_time, dtype='f8')
            dtype='f8';
            roi_folder.set_dataset('start_time_0', start_time, dtype);
            %- roi_folder.create_dataset('roi_description', data=desc)
            roi_folder.set_dataset('roi_description', desc);
        end
        
        function add_reference_image(seg_iface, plane, name, img)
        % Add a reference image to the segmentation interface
        % 
        % Args: 
        %     *seg_iface*  Group folder having the segmentation interface
        % 
        %     *plane* (text) name of imaging plane
        % 
        %     *name* (text) name of reference image
        % 
        %     *img* (byte array) raw pixel map of image, 8-bit grayscale
        % 
        % Returns:
        %     *nothing*

            %- import borg_timeseries as ts
            %- path = 'processing/%s/ImageSegmentation/%s/reference_images' % (self.module.name, plane)
            %- grp = self.iface_folder[plane]
            %- if 'reference_images' not in grp:
            %-     grp.create_group('reference_images')
            grp = seg_iface.get_node(plane);
            abort=false;
            ri = grp.make_group('reference_images', abort);
            %- img_ts = ts.ImageSeries(name, self.module.borg, 'other', path)
            img_ts = ri.make_group('<ImageSeries>', name);
            %- img_ts.set_format('raw')
            img_ts.set_dataset('format', 'raw');
            %- img_ts.set_bits_per_pixel(8)
            img_ts.set_dataset('bits_per_pixel', 8);
            %- img_ts.set_dimension([len(img[0]), len(img)])
            img_ts.set_dataset('dimension', [numel(img(0)), numel(img)])
            %- img_ts.set_time([0])
            img_ts.set_dataset('timestamps', 0.0)
            %- img_ts.set_data(img, 'grayscale', 1, 1)
            attrs=struct('unit','grayscale');
            img_ts.set_dataset('data', img, attrs);
            img_ts.set_dataset('num_samples', 1);
            %- img_ts.finalize()
        end


    %% Helper functions created to make Matlab API work
    % String conversion functions
    
        function new_str = convert_uc_to_utf( old_str )
        % This function converts certain parts of the specification
        % language to utf, so matlab can use them for fields in structs
            new_str = strrep(old_str, '/', '_0x2F_');
            new_str = strrep(new_str, '<', '_0x3C_');
            new_str = strrep(new_str, '>', '_0x3E_');
            new_str = strrep(new_str, '?', '_0x3F_');
            new_str = strrep(new_str, '+', '_0x2B_');
            new_str = strrep(new_str, '*', '_0x2A_');
            if ~isempty(new_str)
                if strcmp(new_str(1), '_') %&& ~strcmp(new_str, '__custom')
                    new_str(1) = 'x';
                end
            end
        end
        
        function new_str = convert_utf_to_uc( old_str )
        % This function converts back from utf to uc to make the fields of
        % structures readable 
            new_str = strrep(old_str,'_0x2F_', '/');
            new_str = strrep(new_str,'x0x2F_', '/');
            new_str = strrep(new_str,'_0x3C_', '<');
            new_str = strrep(new_str,'x0x3C_', '<');
            new_str = strrep(new_str, '_0x3E_', '>');
            new_str = strrep(new_str, 'x0x3E_', '>');
            new_str = strrep(new_str, '_0x3F_', '?');
            new_str = strrep(new_str, 'x0x3F_', '?');
            new_str = strrep(new_str, '_0x2B_', '+');
            new_str = strrep(new_str, 'x0x2B_', '+');
            new_str = strrep(new_str, '_0x2A_', '*');
            new_str = strrep(new_str, 'x0x2A_', '*');
            new_str = strrep(new_str, '_0x5F_', '_');
            new_str = strrep(new_str, 'x0x5F_', '_');
        end
        
        % This function is currently not used, does shorten input to the
        % maximum allowed length for fields in structs
        function short_path = create_short_path(full_path)
            full_path = Utils.convert_utf_to_uc(full_path);
            full_path = strrep(full_path, '//', '/');
            path_parts = strsplit(full_path, '/');
            short_path = '';
            len_path = 65;
            i = 1;
            while(len_path > 61)
                short_path = strjoin(path_parts(i:end), '/');
                extra = (numel(path_parts) - i)*5;
                len_path = numel(short_path)+ extra;
                i = i+1;
            end
            short_path = ['*/' short_path];
            short_path = Utils.convert_uc_to_utf(short_path);     
        end
        
    % Functions for HDF5
        
        % create link
        function create_softlink(fid, targetpath, path, name)
            plist = 'H5P_DEFAULT';
            try
                gid = H5G.open(fid, path);
%                 disp('Group exists');
            catch
%                 disp('Group is created');
                gid = H5G.create(fid,path,plist,plist,plist);
            end
            lcpl = 'H5P_DEFAULT';
            lapl = 'H5P_DEFAULT';
            H5L.create_soft(targetpath, gid,name,lcpl,lapl);
            H5G.close(gid);
        end
        
        % create external link
        function create_external_link(fid, path, targetpath, targetobj)
            path = Utils.convert_utf_to_uc(path);
            targetpath = Utils.convert_utf_to_uc(targetpath);
            targetobj = Utils.convert_utf_to_uc(targetobj);
            plist = 'H5P_DEFAULT';
            path_parts = strsplit(path, '/');
            group_path = strjoin(path_parts(1:end-1), '/');
            try
                gid = H5G.open(fid, group_path);
%                 disp('Group exists');
            catch
%                 disp('Group is created')
                gid = H5G.create(fid,group_path,plist,plist,plist);
            end
            H5L.create_external(targetpath,targetobj,fid,path,plist,plist);
            H5G.close(gid);
        end
        
        % create attribute
        function write_att(fid, filename,path,attname,attvalue)
            path = Utils.convert_utf_to_uc(path);
            attname = Utils.convert_utf_to_uc(attname);
            h5writeatt(filename,path,attname,attvalue);
        end
        
        % check if node exists
        function exist = node_exists(fid, path)
            if strcmp(path(end), '/')
                group_path = path;
                node = '';
            else
                path_parts = strsplit(path, '/');
                group_path = strjoin(path_parts(1:end-1), '/');
                node = path_parts(end);
            end
                
            try
                gid = H5F.open(fid, group_path);
                H5G.close(gid);
                exist = 'true';
            catch
                exist = 'false';
                return;
            end
            if ~strcmp(node, '')
                exist = H5L.exists(gid,node,'H5P_DEFAULT') 
            end
        end
        
        % create group
        function gid = create_group(fid, path)
            plist = 'H5P_DEFAULT';
            path = Utils.convert_utf_to_uc(path);
            path_parts = strsplit(path, '/');
            top_path = '/';
            for i = 1:numel(path_parts)
                if strcmp(path_parts(i), '')
                    continue;
                end
                top_path = [top_path path_parts{i} '/'];
                try
                    gid = H5G.open(fid, top_path);
                    H5G.close(gid);
                    continue;
                catch
                    gid = H5G.create(fid,top_path,plist,plist,plist);
                    H5G.close(gid);
                end
            end
            gid = H5G.open(fid, path);
        end
        
        
        % create dataset for char or cellstr input
        function create_string_dataset(file_obj,path, name, dataset, compression)
        % writes a string dataset to an hdf5 file at a given location
            if ~exist('compression', 'var')
                compression = 0;
            end
            if strcmp(compression, 'gzip')
                compression = 5;
            end
            path = Utils.convert_utf_to_uc(path);
            name = Utils.convert_utf_to_uc(name);
            type_id = H5T.copy('H5T_C_S1');
            if isa(dataset, 'char')
               str_len = numel(dataset);
               H5T.set_size(type_id,str_len);
               h5_dims = [1 1];
               h5_maxdims = h5_dims;
               space_id = H5S.create_simple(2,h5_dims,h5_maxdims);
               plist = H5P.create('H5P_DATASET_CREATE');
               H5P.set_chunk(plist,h5_dims); % 2 strings per chunk
               H5P.set_deflate(plist,compression);
            else if iscellstr(dataset)
                    H5T.set_size(type_id,'H5T_VARIABLE');
                    H5S_UNLIMITED = H5ML.get_constant_value('H5S_UNLIMITED');
                    space_id = H5S.create_simple(1,numel(dataset),H5S_UNLIMITED);
                    plist = H5P.create('H5P_DATASET_CREATE');
                    H5P.set_chunk(plist,2); % 2 strings per chunk
                    H5P.set_deflate(plist,compression);
                else
                    error('create_string_dataset:wrong_datatype', 'Input has to be a string dataset');
                end
            end
            
            try
                gid = H5G.open(file_obj.file_pointer, path);
%                 disp('Group exists');
            catch
%                 disp('Group is created')
                gid = Utils.create_group(file_obj.file_pointer, path);
            end
            
%             dcpl = 'H5P_DEFAULT';
            dset_id = H5D.create(gid,name,type_id,space_id,plist);
            H5D.write(dset_id,type_id,'H5S_ALL','H5S_ALL','H5P_DEFAULT',dataset); % 'H5ML_DEFAULT swapped for type_id
            H5S.close(space_id);
            H5T.close(type_id);
            H5D.close(dset_id);
            H5G.close(gid);
        end
        
        % create datset for numeric input, uses high level function to
        % manage datatype
        function create_numeric_dataset(file_obj, path, name, dataset, compression)
            if ~exist('compression', 'var')
                compression = 0;
            end
            if strcmp(compression, 'gzip')
                compression = 5;
            end
            path = Utils.convert_utf_to_uc(path);
            name = Utils.convert_utf_to_uc(name);
            try
                gid = H5G.open(file_obj.file_pointer, path);
%                 disp('Group exists');
            catch
%                 disp('Group is created')
                gid = Utils.create_group(file_obj.file_pointer, path);
            end
            if strcmp(path(end), '/')
                dataset_path = [path name];
            else
                dataset_path = [path '/' name];
            end
            dataset_size = size(dataset);
            H5G.close(gid);
            H5F.close(file_obj.file_pointer);
            h5create(file_obj.file_name,dataset_path, dataset_size, 'Chunksize', dataset_size, 'Deflate', compression);
            h5write(file_obj.file_name, dataset_path, dataset);
            file_obj.file_pointer = H5F.open(file_obj.file_name, 'H5F_ACC_RDWR','H5P_DEFAULT');
        end
        
        
        %% Jeff's functions
        
        function [arg_vals] = parse_arguments(args,  arg_names, arg_types, arg_default)
            % parse variable arguements passed to function, return
            % values for each defined in arg_defs.  arg_names has argument
            % names, arg_types, the expected type, either 'char' (string) or 'cell'
            % 'cell' is cell array used for list of alternate key, values
            % set up default values to empty string or empty cell array
            arg_vals = struct;
            for i=1:numel(arg_names)
                arg_vals.(arg_names{i}) = arg_default{i};
            end
            found_named_arg = '';
            i = 1;
            while i <= numel(args)
                arg = args{i};
                if ischar(arg) && ismember(arg, arg_names)
                    % found named argument
                    val = args{i+1};
                    [~, idx] = ismember(arg, arg_names);
                    if ~strcmp(class(val), arg_types{idx})
                        error('Unexpected type (%s) for parameter "%s", expecting "%s"', ...
                            class(val), arg, arg_types{i})
                    end
                    found_named_arg = arg;
                    arg_vals.(arg) = val;
                    i = i + 2;
                    continue
                end
                if found_named_arg
                    error('Unnamed argument appears after named argument "%s"', ...
                        found_named_arg)
                end
                % maybe found valid un-named argument
                if i > numel(arg_names)
                    error('Too many un-named arguments in function call');
                end
                if ~strcmp(class(arg), arg_types{i})
                    error('Unnamed argment "%s" is type "%s"; expected type "%s"', ...
                        arg_names{i}, class(arg), arg_types{i});
                end
                % seems to be valid, save it
                arg_vals.(arg_names{i}) = arg;
                i = i + 1;
            end
        end 
        
        function add_epoch_ts(e, start_time, stop_time, name, ts)
            % Add timeseries_X group to nwb epoch.
            % e - h5gate.Group containing epoch
            % start_time - start time of epoch
            % stop_time - stop time of epoch
            % name - name of <timeseries> group to be added to epoch
            % ts - timeseries to be added, must be a h5g8.Group
            % object or path to timeseries
            if ischar(ts)
                % ts is path to node rather than node.  Get the node
                error('add_epoch_ts using path not yet implemented');
                % ts = e.file.get_node(ts)
            end
            [start_idx, cnt] = Utils.get_ts_overlaps(ts, start_time, stop_time);
            if isempty(start_idx)
                % no overlap, don't add timeseries
                return
            end
            f = e.make_group('<timeseries_X>', name);
            f.set_dataset('idx_start', int64(start_idx));
            f.set_dataset('count', int64(cnt));
            % f.make_group('timeseries', ts);  % makes a link to ts group
            timeseries_link = sprintf('link:%s/timestamps', Utils.convert_utf_to_uc(ts.full_path));
            f.make_group('timeseries', 'link', timeseries_link);  % makes a link to ts group
        end
    
        function [start_idx, cnt] = get_ts_overlaps(tsg, start_time, stop_time)
            % Get starting index and count of overlaps between timeseries timestamp
            % and interval between t_start and t_stop.  This is adapted from
            % borg_epoch.py add_timeseries.
            % Inputs:
            %  tsg - h5g8.Group object containing timeseries timestamp.
            %  start_time - starting time of interval (epoch)
            %  stop_time - ending time of interval
            % returns tuple with:
            %  start_idx - starting index of interval in time series, [] if no overlap
            %  cnt - number of elements in timeseries overlapping, zero 0 if no overlap
            timestamps_path = sprintf('%s/timestamps', Utils.convert_utf_to_uc(tsg.full_path));
            fid = tsg.file.file_pointer;  % pointer to hdf5 file
            dset_id = H5D.open(fid,timestamps_path);
            timestamps = H5D.read(dset_id);
            H5D.close(dset_id);
            [start_idx,upper_index] = Utils.myFindDrGar(timestamps,start_time,stop_time);
            if ~isempty(start_idx)
                cnt = upper_index - start_idx + 1;
            end
        end
        
        function [lower_index,upper_index] = myFindDrGar(x,LowerBound,UpperBound)
        % From: http://stackoverflow.com/questions/20166847/faster-version-of-find-for-sorted-vectors-matlab
        % fast O(log2(N)) computation of the range of indices of x that satify the
        % upper and lower bound values using the fact that the x vector is sorted
        % from low to high values. Computation is done via a binary search.
        %
        % Input:
        %
        % x-            A vector of sorted values from low to high.       
        %
        % LowerBound-   Lower boundary on the values of x in the search
        %
        % UpperBound-   Upper boundary on the values of x in the search
        %
        % Output:
        %
        % lower_index-  The smallest index such that
        %               LowerBound<=x(index)<=UpperBound
        %
        % upper_index-  The largest index such that
        %               LowerBound<=x(index)<=UpperBound

        if LowerBound>x(end) || UpperBound<x(1) || UpperBound<LowerBound
            % no indices satify bounding conditions
            lower_index = [];
            upper_index = [];
            return;
        end

        lower_index_a=1;
        lower_index_b=length(x); % x(lower_index_b) will always satisfy lowerbound
        upper_index_a=1;         % x(upper_index_a) will always satisfy upperbound
        upper_index_b=length(x);

        %
        % The following loop increases _a and decreases _b until they differ 
        % by at most 1. Because one of these index variables always satisfies the 
        % appropriate bound, this means the loop will terminate with either 
        % lower_index_a or lower_index_b having the minimum possible index that 
        % satifies the lower bound, and either upper_index_a or upper_index_b 
        % having the largest possible index that satisfies the upper bound. 
        %
        while (lower_index_a+1<lower_index_b) || (upper_index_a+1<upper_index_b)

            lw=floor((lower_index_a+lower_index_b)/2); % split the upper index

            if x(lw) >= LowerBound
                lower_index_b=lw; % decrease lower_index_b (whose x value remains \geq to lower bound)   
            else
                lower_index_a=lw; % increase lower_index_a (whose x value remains less than lower bound)
                if (lw>upper_index_a) && (lw<upper_index_b)
                    upper_index_a=lw;% increase upper_index_a (whose x value remains less than lower bound and thus upper bound)
                end
            end

            up=ceil((upper_index_a+upper_index_b)/2);% split the lower index
            if x(up) <= UpperBound
                upper_index_a=up; % increase upper_index_a (whose x value remains \leq to upper bound) 
            else
                upper_index_b=up; % decrease upper_index_b
                if (up<lower_index_b) && (up>lower_index_a)
                    lower_index_b=up;%decrease lower_index_b (whose x value remains greater than upper bound and thus lower bound)
                end
            end
        end

        if x(lower_index_a)>=LowerBound
            lower_index = lower_index_a;
        else
            lower_index = lower_index_b;
        end
        if x(upper_index_b)<=UpperBound
            upper_index = upper_index_b;
        else
            upper_index = upper_index_a;
        end

        end

    end
    
end

