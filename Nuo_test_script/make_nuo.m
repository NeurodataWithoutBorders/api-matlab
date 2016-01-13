function [ ds, md ] = make_nuo( path, base_name )
%Convert Nuo Li sample data set to NWB format using matlab API
%  path (optional) - path to location of Nuo Li MatLab files
%  base_name (optional) - base name of MatLab files, e.g.:
% _NL_example20140905_ANM219037_20131117.mat.  The strings:
% "data_structure" and "meta_data" are prepended to the base_name to
% get the full file name.
% Returns structures for both source matlab files (md=meta_data,
% ds=data_structure).  This useful for testing references to structure.
% in the matlab command window. To use this, call with [ds, md] = make_nuo()


default_path = './';
default_base_name = 'NL_example20140905_ANM219037_20131117.mat';
if nargin<1 || isempty(path)
    path = default_path;
end
if nargin<2 || isempty(base_name)
    base_name = default_base_name;
end
[~,name,~] = fileparts(base_name);
output_file_name = fullfile(path, strcat(name, '_nwb.h5'));

ds_infile = fullfile(path,strcat('data_structure_', base_name));
md_infile = fullfile(path,strcat('meta_data_', base_name));
ds = load(ds_infile);
md = load(md_infile);
% shorten abbrev to just ds and md:
ds = ds.obj;
md = md.meta_data;

    function [val] = getHashValue(hash, key)
        % returns value array corresponding to key in hash
        idx = find(strcmp(hash.keyNames, key));
        val = hash.value{idx};
    end

    function create_trials(f, epoch_tags, epoch_units)
        % initialize trials with basic fields and behavioral data
        % f - nwb file handle
        trial_id = ds.trialIds;
        trial_t = ds.trialStartTimes;
        good_trials = getHashValue(ds.trialPropertiesHash, 'GoodTrials');
        ival = (trial_t(end) - trial_t(1)) / (length(trial_t) - 1);
        trial_t(end+1) = trial_t(end) + 2 * ival;
        ep = f.make_group('epochs');
        for i = 1:length(trial_id)
            tid = trial_id(i);
            trial = sprintf('Trial_%03i', tid);
            fprintf('%i ', tid); % DEBUG
            if mod(tid, 50) == 0
                fprintf('\n');
            end
            start = trial_t(i);
            stop = trial_t(i+1);
            e = ep.make_group('<epoch_X>', trial);
            e.set_dataset('start_time', start);
            e.set_dataset('stop_time', stop);
            e.set_dataset('tags', epoch_tags{tid});
            e.set_custom_dataset('units', epoch_units{tid});
            raw_file = ds.descrHash.value{tid};
            if isempty(raw_file)
                raw_file = 'na';
            else
                % convert from cell array to string
                raw_file = raw_file{1};
            end
            description = sprintf('Raw Voltage trace data files used to acuqire spike times data: %s', raw_file);
            e.set_dataset('description', description);
            Utils.add_epoch_ts(e, start, stop, 'lick_trace', lick_trace_ts);
            Utils.add_epoch_ts(e, start, stop, 'aom_input_trace', aom_input_trace_ts);
        end
    end
            
    function [epoch_tags] = get_trial_types()
        % add trial types to epoch for indexing
        epoch_tags = {};
        trial_id = ds.trialIds;
        trial_type_string = ds.trialTypeStr;
        photostim_types = getHashValue(ds.trialPropertiesHash, 'PhotostimulationType');
        for i = 1:length(trial_id)
            tid = trial_id(i);
            trial_type_mat = ds.trialTypeMat;
            found_types = {};
            for j = 1:8
                if trial_type_mat(j,i) == 1
                    found_types{end+1} = trial_type_string{j};
                end
            end
            ps_type_value = photostim_types(i);
            if ps_type_value == 0
                photostim_type = 'non-stimulation trial';
            elseif ps_type_value == 1
                photostim_type = 'PT axonal stimulation';
            elseif ps_type_value == 2
                photostim_type = 'IT axonal stimulation';
            else
                photostim_type = 'discard';
            end
            found_types{end+1} = photostim_type;
            epoch_tags{tid} = found_types;
        end
    end

    function [epoch_units] = get_trial_units(num_of_units)
        % collect unit information for a given trial
        % pre-fill cell array with empty list of units for each trial
        trial_id = ds.trialIds;
        epoch_units = {};
        for i = 1:length(trial_id)
            tid = trial_id(i);
            epoch_units{tid} = {};
        end
        for unit_id = 1:num_of_units
            unit_name = sprintf('unit_%02i', unit_id);
            trial_ids = ds.eventSeriesHash.value{unit_id}.eventTrials;
            trial_ids = unique(trial_ids);
            for j = 1:length(trial_ids)
                tid = trial_ids(j);
                if ~ismember(unit_name, epoch_units{tid})
                    % append unit
                    epoch_units{tid} = [ epoch_units{tid}, unit_name];
                end
            end
        end
    end
     
            

% load general metadata
fprintf('Reading meta data\n');
% start time
dateOfExperiment = md.dateOfExperiment{1};
timeOfExperiment = md.timeOfExperiment{1};
[year, month, day] = deal(dateOfExperiment(1:4),dateOfExperiment(5:6),dateOfExperiment(7:8));
[hour, min, sec] = deal(timeOfExperiment(1:2), timeOfExperiment(3:4), timeOfExperiment(5:6));
start_time = sprintf('%s-%s-%s %s:%s:%s', year,month,day,hour,min,sec);

% create nwb file with session start time
f = NWB_file(output_file_name, start_time);

g = f.make_group('subject');
genotype = sprintf('Animal gene modification: %s;\nAnimal genetic background: %s;\nAnimal gene copy: %s',...
    md.animalGeneModification{1}, md.animalGeneticBackground{1}, num2str(md.animalGeneCopy{1}));
g.set_dataset('genotype', genotype);
g.set_dataset('sex', md.sex{1});
g.set_dataset('age', '>P60');
g.set_dataset('species', md.species{1});
g.set_dataset('weight', 'Before: 20, After: 21');
f.set_dataset('related_publications', md.citation{1});

experimentType = strjoin(md.experimentType, ', '); %% was string array in borg
f.set_dataset('notes',experimentType);
f.set_dataset('experimenter', md.experimenters{1});
f.set_custom_dataset('reference_atlas', md.referenceAtlas{1});

f.set_dataset('surgery', fileread('nl_files/surgery.txt'));
f.set_dataset('data_collection', fileread('nl_files/data_collection.txt'));
f.set_dataset('experiment_description', fileread('nl_files/experiment_description.txt'));

f.set_custom_dataset('whisker_configuration', md.whiskerConfig{1});


probe = [...
        0,   0,  0 ;     0, 100,  0 ;     0, 200,  0 ;     0, 300,  0; ...
        0, 400,  0 ;     0, 500,  0 ;     0, 600,  0 ;     0, 700,  0; ...
      200,   0,  0 ;   200, 100,  0 ;   200, 200,  0 ;   200, 300,  0; ...
      200, 400,  0 ;   200, 500,  0 ;   200, 600,  0 ;   200, 700,  0; ...
      400,   0,  0 ;   400, 100,  0 ;   400, 200,  0 ;   400, 300,  0; ...
      400, 400,  0 ;   400, 500,  0 ;   400, 600,  0 ;   400, 700,  0; ...
      600,   0,  0 ;   600, 100,  0 ;   600, 200,  0 ;   600, 300,  0; ...
      600, 400,  0 ;   600, 500,  0 ;   600, 600,  0 ;   600, 700,  0];

shank = [repmat({'shank0'},1,8), repmat({'shank1'},1,8), ...
         repmat({'shank2'},1,8), repmat({'shank3'},1,8) ];
     
g = f.make_group('extracellular_ephys');

% electrode_map and electrode_group
g.set_dataset('electrode_map', probe');
g.set_dataset('electrode_group', shank);

% TODO fix location info. also check electrode coordinates
fprintf('Warning: shank locations hardcoded in script and are likely incorrect\n');
shank_info = {...
    'shank0', 'P: 2.5, Lat:-1.2. vS1, C2, Paxinos. Recording marker DiI'; ...
    'shank1', 'P: 2.5, Lat:-1.4. vS1, C2, Paxinos. Recording marker DiI'; ...
    'shank2', 'P: 2.5, Lat:-1.6. vS1, C2, Paxinos. Recording marker DiI'; ...
    'shank3', 'P: 2.5, Lat:-1.8. vS1, C2, Paxinos. Recording marker DiI'};

% extracellular_ephys/electrode_group_N
for i = 1:4
	g2 = g.make_group('<electrode_group_X>', shank_info{i,1});
	g2.set_dataset('description', shank_info{i,2});
	% g.set_dataset('location',eg_info.location)
	% g.set_dataset('device', eg_info.device)
end

% 
% % behavior
task_kw = md.behavior.task_keyword;
f.set_custom_dataset('task_keyword', task_kw);

% virus
inf_coord = md.virus.infectionCoordinates;
inf_loc = md.virus.infectionLocation{1};
inj_date = md.virus.injectionDate{1};
inj_volume = md.virus.injectionVolume;
virus_id = md.virus.virusID{1};
virus_lotNr = md.virus.virusLotNumber;
virus_src = md.virus.virusSource{1};
virus_tit = md.virus.virusTiter{1};

virus_text = sprintf(['Infection Coordinates: %s' ...
  '\nInfection Location: %s\nInjection Date: %s\nInjection Volume: %s' ... 
  '\nVirus ID: %s\nVirus Lot Number: %s\nVirus Source: %s\nVirus Titer: %s'],...
  [mat2str(inf_coord{1}) mat2str(inf_coord{2})],...
  inf_loc, inj_date, [mat2str(inj_volume{1}) mat2str(inj_volume{2})], virus_id, ...
  char(virus_lotNr), virus_src, virus_tit);
 
f.set_dataset('virus', virus_text);

%fiber
impl_date = md.fiber.implantDate{1};
tip_coord = md.fiber.tipCoordinates{1};
tip_loc   = md.fiber.tipLocation{1};
fiber_text = sprintf('Implant Date: %s\nTip Coordinates: %s', ...
  impl_date, mat2str(tip_coord));
% g = f.make_group('optophysiology');
g = f.make_group('optogenetics');
g = g.make_group('<site_X>', 'site_1');
g.set_dataset('description', fiber_text);
g.set_dataset('location', tip_loc);

% #photostim
phst_id_method = md.photostim.identificationMethod{1};
phst_coord = md.photostim.photostimCoordinates{1};
phst_loc = md.photostim.photostimLocation{1};
phst_wavelength = md.photostim.photostimWavelength{1};
stim_method = md.photostim.stimulationMethod{1};
 
photostim_text = sprintf(['Identification Method: %s'...
  '\nPhotostimulation Coordinates: %s' ...
  '\nPhotostimulation Location: %s'...
  '\nPhotostimulation Wavelength: %s' ...
  '\nStimulation Method: %s'],...
  phst_id_method,  mat2str(phst_coord), phst_loc,...
  mat2str(phst_wavelength), stim_method);

f.set_dataset('stimulus', photostim_text);
    
    
% raw data section
% lick trace is stored in acquisition
% photostimulation wave forms is stored in stimulus/processing
fprintf('Reading raw data\n');
% get times
timestamps = ds.timeSeriesArrayHash.value{1}.time;
% calculate sampling rate
rate = (length(timestamps)-1)/(timestamps(end) - timestamps(1));
% get data
valueMatrix = ds.timeSeriesArrayHash.value{1}.valueMatrix;
lick_trace = valueMatrix(:,1);
aom_input_trace = valueMatrix(:,2);
laser_power = valueMatrix(:,3);
% get descriptions
comment1 = ds.timeSeriesArrayHash.keyNames{1};
comment2 = ds.timeSeriesArrayHash.descr{1};
comments = sprintf('%s : %', comment1, comment2);
descr = ds.timeSeriesArrayHash.value{1}.idStrDetailed;
% create timeseries for lick_trace
g = f.make_group('<TimeSeries>', 'lick_trace', 'path', '/acquisition/timeseries', 'attrs',...
    {'comments', comments, 'description', char(descr(1)), 'rate', rate});
g.set_dataset('data', lick_trace', 'attrs',...  % tranpose lick_trace, so 1xn
    {'conversion', 1, 'resolution', 0, 'unit', 'unknown'}, 'compress', true );
t1 = g.set_dataset('timestamps', timestamps', 'compress', true);      % transpose time_stamps, so 1xn
g.set_dataset('num_samples', int64(length(lick_trace)));

lick_trace_ts = g;  % save for referencing when making epochs
% laser_power
g = f.make_group('<TimeSeries>', 'laser_power', 'path', '/stimulus/presentation', 'attrs',...
    {'comments', comments, 'description', char(descr(2)) });
g.set_dataset('data', laser_power', 'attrs' ,...
    {'unit', 'Watts', 'conversion', 1000.0, 'resolution', 0}, 'compress', true);
g.set_dataset('timestamps', t1);  % sets link to other timestamp dataset
g.set_dataset('num_samples', int64(length(lick_trace)));
lasar_power_ts = g;  % save for referencing when making epochs

% aom_input_trace
g = f.make_group('<TimeSeries>', 'aom_input_trace', 'path', '/stimulus/presentation');
g.set_attr('comments', comments);
g.set_attr('description', char(descr(3)));
d = g.set_dataset('data', aom_input_trace', 'compress', true);
d.set_attr('unit', 'Volts');
d.set_attr('conversion', 1.0);
g.set_dataset('timestamps', t1);
g.set_dataset('num_samples', int64(length(lick_trace)));
aom_input_trace_ts = g; % save for referencing when making epochs




% Create module 'Units' for ephys data
% Interface 'UnitTimes' contains spike times for the individual units
% Interface 'EventWaveform' contains waveform data and electrode information
% Electrode depths and cell types are collected in string arrays at the top level
% of the module
fprintf('Reading Event Series Data\n');

% create module units
mod_name = 'Units';
m = f.make_group('<module>', mod_name);
% below set_attr call causes matlab to crash.  source is not
% an attribute of module.
% m.set_attr('source', 'Data as reported in Nuo''s data file');
% make UnitTimes and EventWaveform interfaces
spk_waves_iface = m.make_group('EventWaveform');
spk_waves_iface.set_attr('source', 'Data as reported in Nuo''s file');
spk_times_iface = m.make_group('UnitTimes');
spk_times_iface.set_attr('source', 'EventWaveform in this module');
unit_ids = {};
% top level folder
unit_num = length(ds.eventSeriesHash.value);
% initialize cell_types and electrode_depth arrays with default values
cell_types = repmat({'unclassified'}, 1, unit_num);
electrode_depths = NaN(1, unit_num);
% unit_descr = ds.eventSeriesHash.descr;  % not used.  Should it be?
for i = 1:unit_num
    unit = sprintf('unit_%02i',i);
    unit_ids{end+1} = unit;
    % get data
    grp_top_folder = ds.eventSeriesHash.value{i};
    timestamps = grp_top_folder.eventTimes;
    trial_ids = grp_top_folder.eventTrials;
    % calculate sampling rate
    rate = (timestamps(end) - timestamps(1))/(length(timestamps)-1);
    waveforms = grp_top_folder.waveforms;
    dims = size(waveforms); % e.g. 10227, 29
    sample_length = dims(2);  % e.g. 29
    channel = grp_top_folder.channel; % shape is 10227, 1
    % read in cell types and update cell_type array
    cell_type = grp_top_folder.cellType;
    cell_type = strjoin(cell_type, ' and ');
    cell_types{i} = cell_type;
    % read in electrode depths and update electrode_depths array
    depth = grp_top_folder.depth;
    electrode_depths(i) = 0.001 * depth;
%     # fill in values for the timeseries
%     spk.set_value("sample_length", sample_length)
%     spk.set_time(timestamps)
%     spk.set_data(waveforms, "Volts", 0.1,1)
%     spk.set_value("electrode_idx", [channel[0]])
%     spk.set_description("single unit %d with cell-type information and approximate depth, waveforms sampled at 19531.25Hz" %i)
%     spk_waves_iface.set_timeseries("waveform_timeseries", spk)
%     # add spk to interface
%     description = unit_descr[i-1]
%     spk_times_iface.add_unit(unit, timestamps, description)
%     spk_times_iface.append_unit_data(unit, trial_ids, "trial_ids")

    % create UnitTimes group
    gt = spk_times_iface.make_group('<unit_N>', unit);
    ts = gt.set_dataset('times', timestamps', 'compress', true);
    gt.set_dataset('unit_description', cell_type);
    gt.set_dataset('source', 'Data from processed matlab file');
    gt.set_custom_dataset('trial_ids', trial_ids);
    % create EventWaveform group
    gw = spk_waves_iface.make_group('<SpikeEventSeries>', unit);
    gw.set_attr('description', cell_type);
    [nevents, nsamples] = size(waveforms);
    gw.set_dataset('data', waveforms', 'attrs',...
          {'unit', 'Volt', 'conversion', 0.1, 'resolution', 1}, 'compress', true);
    gw.set_dataset('timestamps', ts);
    gw.set_dataset('num_samples', int64(nevents));
    gw.set_custom_dataset('sample_length', int64(nsamples));
    gw.set_dataset('source', '---');
    if nevents ~= length(timestamps)
        error('nevents=%i, len(timestamps)=%i',nevents, length(timestamps));
    end
    gw.set_dataset('electrode_idx', int32([channel(1), channel(1)]) );  % make array to prevent error
end
spk_times_iface.set_dataset('unit_list', unit_ids);
spk_times_iface.set_custom_dataset('CellTypes', cell_types);
spk_times_iface.set_custom_dataset('ElectrodeDepths', electrode_depths);


fprintf('Creating epochs\n');
epoch_tags = get_trial_types();
unit_num = length(ds.eventSeriesHash.value);
epoch_units = get_trial_units(unit_num);
create_trials(f, epoch_tags, epoch_units);


f.close();


end
