function [data_clean, EEGartifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band] = ft_denoise_gedai(cfg, data)
% ft_denoise_gedai FieldTrip wrapper for the GEDAI plugin.
%
% Use:
      % [data_clean, EEGartifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band] = ft_gedai(cfg, data)
      % or
      % data_clean = ft_gedai(cfg, data)
%
% Inputs:
      % cfg.dataset                   (char) - The path to dataset
      % cfg.artifact_threshold_type   (char)  - Variable determining deartifacting
      %                               strength. Stronger threshold type
      %                               ("auto+") might remove more noise at the
      %                               expense of signal, while milder threshold
      %                               ("auto-") might retain more signal at the 
      %                               expense of noise. Possible levels:
      %                               "auto-", "auto" or "auto+". 
      %                               [Default: "auto" which strikes a
      %                               balance]
      % 
      % cfg.epoch_size                (double)- Epoch size in number of wave cycles for each
      %                               wavelet band. Default is 12.
      %                               [Default: 12]
      % 
      % cfg.ref_matrix_type           (char or matrix) - Matrix used as a reference for deartifacting.
      %                               "precomputed" uses a leadfield for standard 
      %                               electrode locations precomputed through 
      %                               OPENMEEG (343 electrodes) based on 10-5 system 
      %                               "warp" uses an electrode warping
      %                               leadfield based on the Fieldtrip ICBM152
      %                               head model. Can be used for standard and non-standard
      %                               electrode location.
      %                               [Default: "precomputed"]
      % 
      % cfg.parallel                  (logical) - Boolean for using parallel ('multicore') processing.
      % 
      % cfg.visualize_artifacts       (logical)  - Boolean for artifact visualization 
      %                               using vis_artifacts function from the ASR
      %                               toolbox.
      %                               [default: false]
      % 
      % cfg.cat_trials                (logical) if performe gedai on each trials (false) or concatenate all EEG together(true; recommended) 
      %                               if performe gedai on each trials, then the output is a set of n cells, where n is the trials number.
      %                               Remember you should select the trials before denoise pipline. 
      %                               [default: true]

% Outputs:
      % data_clean: FieldTrip data struct with same topology as input, but cleaned.
      % EEGartifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band :
      % passthrough outputs from GEDAI (see more in the original paper/code).

% WARNING : 
      % for now, GEDAI only have leadfield model for EEG, if you want to
      % apply on MEG data, please define your own model, the labels of the model
      % should contains all the data.labels.

% Author : Yingqi Huang, University of Geneva, 2025

% ---------- defaults & sanity ----------
if nargin < 2 || ~isstruct(cfg) || ~isstruct(data)
    error('Usage: [data_clean,...] = ft_gedai(cfg, data)');
end

def.artifact_threshold_type = 'auto';
def.epoch_size = 1.2;           % seconds
def.ref_matrix_type = 'precomputed';
def.parallel = true;
def.visualize_artifacts = false;
def.cat_trials  = true;

cfg = applyDefaults(cfg, def);

% Basic FieldTrip checks
reqFields = {'trial','time','label','fsample'};
for f = reqFields
    if ~isfield(data, f{1})
        error('Input "data" lacks required FieldTrip field: %s', f{1});
    end
end
if ~isfield(cfg, 'dataset')
        error('Input "data" lacks required FieldTrip field: %s', f{1});
end

if ~iscell(data.trial) || ~iscell(data.time)
    error('FieldTrip data.trial and data.time must be cell arrays.');
end
if numel(data.trial) ~= numel(data.time)
    error('data.trial and data.time must have the same number of trials.');
end


% ---------- process trials ----------
% concatenate trials
if cfg.cat_trials
    nTrials = numel(data.trial);
    nChan = numel(data.label);
    lenTrials =  numel(data.time{1});
    total_points = nTrials*lenTrials;
    data_concat = zeros(nChan,total_points);
    time_concat = zeros(1,total_points);
    idx_start = 1;
    for i = 1:nTrials
        idx_end  = idx_start + lenTrials - 1;
        data_concat(:, idx_start:idx_end) = data.trial{i};
        time_concat(1, idx_start:idx_end) = data.time{i};
        idx_start = idx_end + 1;
    end
    data.trial = {data_concat};
    data.time = {time_concat};
end


data_clean = data;
EEGartifacts = cell(numel(data.trial),1);
SENSAI_score = cell(numel(data.trial),1);
SENSAI_score_per_band = cell(numel(data.trial),1);
artifact_threshold_per_band = cell(numel(data.trial),1);

nTr = numel(data.trial);
for t = 1:nTr
    [data_clean.trial{t}, data_clean.time{t} EEGart, Sscore, Sband, artThr] = do_gedai(data, t, cfg);
    EEGartifacts{t} = EEGart;
    SENSAI_score{t} = Sscore;
    SENSAI_score_per_band{t} = Sband;
    artifact_threshold_per_band{t} = artThr;
end


% ---------- subfunctions ----------
    function [dataClean, timeClean, EEGart, Sscore, Sband, Athr] = do_gedai(data, t, cfg)
        EEGin = buildEEGin(data,t,cfg);

        [EEGclean, EEGart, Sscore, Sband, Athr, ~] = GEDAI( ...
            EEGin, ...
            cfg.artifact_threshold_type, ...
            cfg.epoch_size, ...
            cfg.ref_matrix_type, ...
            cfg.parallel, ...
            cfg.visualize_artifacts);
        dataClean = EEGclean.data;
        tlim = size(dataClean,2);
        timeClean = EEGclean.times(1:tlim);
    end

    function EEGin = buildEEGin(data, t, cfg)
        EEGin = struct();
        EEGin.data = data.trial{t};
        EEGin.srate = data.fsample;
        EEGin.nbchan = size(data.trial{t},1);
        EEGin.pnts = size(data.trial{t},2);
        EEGin.times = data.time{t};
        EEGin.chanlocs = struct('labels', data.label(:)');
        EEGin.etc = struct('T0',[2018 3 6 0 44 36],'eeglabvers','2024.0');
        EEGin.event = [];
        EEGin.xmin = EEGin.times(1);
        EEGin.xmax = EEGin.times(end);  
        [EEGin.filepath,EEGin.filename,~] = fileparts(cfg.dataset);

        EEGin.comments = 'Created by ft_gedai wrapper';
        EEGin.ref = 'average';
        EEGin.chaninfo = struct();

        % EEGin.event = ft_read_event(cfg.dataset);
        % if isfield(EEGin.event, 'sample')
        %     EEGin.event.latency = deal(double([EEGin.event.sample])); 
        %     EEGin.event = rmfield(EEGin.event, 'sample');
        % end

        EEGin.event = [];
        EEGin.epoch = []; 


        EEGin.reject = struct();
        EEGin.stats = struct();
        EEGin.specdata = [];
        EEGin.specicaact= [];
        EEGin.saved = 'no';
        EEGin.history = 'EEGin created in ft_gedai wrapper';
        EEGin.trial = 1;
        EEGin.subject = '';
        EEGin.group = '';
        EEGin.condition = '';
    end

    function cfg2 = applyDefaults(cfg1, def1)
        cfg2 = def1;
        fns  = fieldnames(cfg1);
        for k = 1:numel(fns)
            cfg2.(fns{k}) = cfg1.(fns{k});
        end
    end
end
