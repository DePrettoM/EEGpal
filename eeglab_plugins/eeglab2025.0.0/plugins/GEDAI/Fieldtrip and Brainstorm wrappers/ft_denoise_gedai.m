function [data_clean, data_artifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band] = ft_denoise_gedai(cfg, data)
% ft_denoise_gedai  FieldTrip wrapper for the GEDAI plugin.
%
% Usage:
%   [data_clean, data_artifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band] = ft_denoise_gedai(cfg, data)
%   data_clean = ft_denoise_gedai(cfg, data)
%
% Required inputs:
%   cfg.dataset               (char)    - Path to the original dataset file
%   data                      (struct)  - FieldTrip data structure (ft_read_data output)
%
% Optional cfg fields:
%   cfg.artifact_threshold_type  (char)    - 'auto-', 'auto', or 'auto+'. [Default: 'auto']
%                                 Or integer determining deartifacting strength with range [0 10]. Stronger threshold type ("auto+") might remove more noise at the
%                                 expense of signal, while milder threshold. ("auto-") might retain more signal at the expense of noise.
%                         
%   cfg.epoch_size               (double)  - Epoch size in wave CYCLES. [Default: 12]
%   cfg.lowcut_frequency         (double)  - Low-cut frequency in Hz. [Default: 0.5]
%   cfg.ref_matrix_type          (char or matrix) - Leadfield reference. [Default: 'precomputed']
%                                   Matrix used as a reference for deartifacting.
%                                  The default "precomputed" uses a BEM leadfield for
%                                  standard electrode locations precomputed through 
%                                  OPENMEEG (343 electrodes) based on 10-5 system. 
%                                 "interpolated" uses the precomputed leadfield and 
%                                 interpolates it to non-standard electrode locations.
%                                 Altenatively, you can input a "custom" covariance matrix
%                                 (with dimensions channel x channel) using the name of its matlab variable
%   cfg.parallel                 (logical) - Use parallel processing. [Default: true]
%   cfg.visualize_artifacts      (logical) - Visualize artifacts. [Default: false]
%   cfg.cat_trials               (logical) - Concatenate trials before denoising. [Default: true]
%   cfg.signal_type              (char)    - 'eeg' or 'meg'. Auto-detected if not set.
%
% Outputs:
%   data_clean                - FieldTrip struct, cleaned data
%   data_artifacts            - FieldTrip struct, artifact signal
%   SENSAI_score              - Per-trial SENSAI scores (cell)
%   SENSAI_score_per_band     - Per-trial per-band SENSAI scores (cell)
%   artifact_threshold_per_band - Per-trial per-band thresholds (cell)
%
% Notes:
%   - For MEG data with both magnetometers (MEG MAG) and gradiometers (MEG GRAD),
%     GEDAI is run separately on each sensor type and the results are recombined.
%     This mirrors the behaviour of the Brainstorm wrapper (process_gedai.m).
%   - signal_type is auto-detected from data.grad / data.elec / ft_chantype.
%     Set cfg.signal_type explicitly to override.

% Author: Yingqi Huang & Tomas Ros, University of Geneva, 2025-2026
% Updated: auto signal-type detection and MAG/GRAD split processing

% ---------- input validation ----------
if nargin < 2 || ~isstruct(cfg) || ~isstruct(data)
    error('Usage: [data_clean,...] = ft_denoise_gedai(cfg, data)');
end

% ---------- defaults ----------
def.artifact_threshold_type = 'auto';
def.epoch_size              = 12;       % wave cycles (= epoch_size_in_cycles in GEDAI)
def.lowcut_frequency        = 0.5;
def.ref_matrix_type         = 'precomputed';
def.parallel                = true;
def.visualize_artifacts     = false;
def.cat_trials              = true;
def.signal_type             = '';       % empty = auto-detect

cfg = applyDefaults(cfg, def);

% Allow numeric threshold (e.g. cfg.artifact_threshold_type = 3.5)
% GEDAI_per_band expects a string; convert so str2double() works correctly.
if isnumeric(cfg.artifact_threshold_type)
    cfg.artifact_threshold_type = num2str(cfg.artifact_threshold_type);
end

% ---------- FieldTrip field checks ----------
reqFields = {'trial', 'time', 'label', 'fsample'};
for fi = reqFields
    if ~isfield(data, fi{1})
        error('Input "data" lacks required FieldTrip field: %s', fi{1});
    end
end
if ~isfield(cfg, 'dataset')
    error('cfg.dataset is required (path to the original data file).');
end
if ~iscell(data.trial) || ~iscell(data.time)
    error('FieldTrip data.trial and data.time must be cell arrays.');
end
if numel(data.trial) ~= numel(data.time)
    error('data.trial and data.time must have the same number of trials.');
end

% ---------- auto-detect signal type ----------
if isempty(cfg.signal_type)
    cfg.signal_type = detectSignalType(data);
    disp(['ft_denoise_gedai> Auto-detected signal type: ' cfg.signal_type]);
else
    cfg.signal_type = lower(cfg.signal_type);
end

% ---------- detect MAG / GRAD split for MEG ----------
process_mag_grad_separately = false;
mag_idx = [];
grad_idx = [];

if strcmp(cfg.signal_type, 'meg')
    chantypes = ft_chantype(data);
    mag_idx  = find(ismember(chantypes, {'megmag'}));
    grad_idx = find(ismember(chantypes, {'meggrad', 'megplanar'}));
    if ~isempty(mag_idx) && ~isempty(grad_idx)
        process_mag_grad_separately = true;
        disp('ft_denoise_gedai> Mixed MAG+GRAD detected: processing sensor types separately.');
    end
end

% ---------- concatenate trials if requested ----------
if cfg.cat_trials
    nTrials   = numel(data.trial);
    nChan     = numel(data.label);
    lenTrials = numel(data.time{1});
    total_pts = nTrials * lenTrials;
    data_concat = zeros(nChan, total_pts);
    time_concat = zeros(1, total_pts);
    idx_start = 1;
    for i = 1:nTrials
        idx_end = idx_start + lenTrials - 1;
        data_concat(:, idx_start:idx_end) = data.trial{i};
        time_concat(1, idx_start:idx_end) = data.time{i};
        idx_start = idx_end + 1;
    end
    data.trial = {data_concat};
    data.time  = {time_concat};
end

% ---------- process each trial ----------
data_clean     = data;
data_artifacts = data;
SENSAI_score              = cell(numel(data.trial), 1);
SENSAI_score_per_band     = cell(numel(data.trial), 1);
artifact_threshold_per_band = cell(numel(data.trial), 1);

nTr = numel(data.trial);
for t = 1:nTr
    [data_clean.trial{t}, data_clean.time{t}, EEGart, Sscore, Sband, artThr] = ...
        do_gedai(data, t, cfg, process_mag_grad_separately, mag_idx, grad_idx);
    data_artifacts.trial{t}       = EEGart;
    SENSAI_score{t}               = Sscore;
    SENSAI_score_per_band{t}      = Sband;
    artifact_threshold_per_band{t} = artThr;
end

% Unwrap single-trial outputs to plain values for convenience
if nTr == 1
    SENSAI_score              = SENSAI_score{1};
    SENSAI_score_per_band     = SENSAI_score_per_band{1};
    artifact_threshold_per_band = artifact_threshold_per_band{1};
end


% ==========================================================================
%  SUBFUNCTIONS
% ==========================================================================

% ---------- do_gedai: run GEDAI on one trial ----------
function [dataClean, timeClean, artifactData, Sscore, Sband, Athr] = ...
        do_gedai(data, t, cfg, process_mag_grad_separately, mag_idx, grad_idx)

    trial_data = data.trial{t};   % [nChan x nTime]
    trial_time = data.time{t};

    if process_mag_grad_separately
        % --- Run GEDAI separately on MAG and GRAD ---
        EEGin_MAG  = buildEEGin(trial_data(mag_idx, :),  trial_time, data.label(mag_idx),  cfg);
        EEGin_GRAD = buildEEGin(trial_data(grad_idx, :), trial_time, data.label(grad_idx), cfg);

        [EEGclean_MAG,  EEGart_MAG,  Sscore_MAG,  Sband_MAG,  Athr_MAG]  = runGEDAI(EEGin_MAG,  cfg);
        [EEGclean_GRAD, EEGart_GRAD, Sscore_GRAD, Sband_GRAD, Athr_GRAD] = runGEDAI(EEGin_GRAD, cfg);

        % --- Recombine into full channel matrix ---
        nChan = size(trial_data, 1);
        nTime = size(trial_data, 2);
        dataClean    = zeros(nChan, nTime);
        artifactData = zeros(nChan, nTime);

        % Trim each sensor type to original length (GEDAI may pad or trim)
        nT_MAG  = min(size(EEGclean_MAG.data,  2), nTime);
        nT_GRAD = min(size(EEGclean_GRAD.data, 2), nTime);
        dataClean(mag_idx,  1:nT_MAG)  = EEGclean_MAG.data(:,  1:nT_MAG);
        dataClean(grad_idx, 1:nT_GRAD) = EEGclean_GRAD.data(:, 1:nT_GRAD);
        artifactData(mag_idx,  1:nT_MAG)  = EEGart_MAG.data(:,  1:nT_MAG);
        artifactData(grad_idx, 1:nT_GRAD) = EEGart_GRAD.data(:, 1:nT_GRAD);

        timeClean = trial_time;

        % Merge per-band outputs
        Sscore = struct('MAG', Sscore_MAG, 'GRAD', Sscore_GRAD);
        Sband  = struct('MAG', Sband_MAG,  'GRAD', Sband_GRAD);
        Athr   = struct('MAG', Athr_MAG,   'GRAD', Athr_GRAD);

    else
        % --- Single pass (EEG or homogeneous MEG) ---
        nTime = size(trial_data, 2);
        EEGin = buildEEGin(trial_data, trial_time, data.label, cfg);
        [EEGclean, EEGart, Sscore, Sband, Athr] = runGEDAI(EEGin, cfg);

        % EEGclean.data may be longer (padded) or shorter (epochs rejected)
        % than the original. Always trim/pad to the original length.
        nOut = size(EEGclean.data, 2);
        if nOut >= nTime
            dataClean    = EEGclean.data(:, 1:nTime);
            artifactData = EEGart.data(:,   1:nTime);
        else
            dataClean    = [EEGclean.data, zeros(size(EEGclean.data,1), nTime-nOut)];
            artifactData = [EEGart.data,   zeros(size(EEGart.data,1),   nTime-nOut)];
        end
        timeClean = trial_time;
    end
end

% ---------- runGEDAI: call GEDAI with all parameters ----------
function [EEGclean, EEGart, Sscore, Sband, Athr] = runGEDAI(EEGin, cfg)
    [EEGclean, EEGart, Sscore, Sband, Athr] = GEDAI( ...
        EEGin, ...
        cfg.artifact_threshold_type, ...
        cfg.epoch_size, ...
        cfg.lowcut_frequency, ...
        cfg.ref_matrix_type, ...
        cfg.parallel, ...
        cfg.visualize_artifacts, ...
        [], ...              % ENOVA_threshold: [] -> GEDAI default (inf = disabled)
        cfg.signal_type);
end

% ---------- buildEEGin: construct EEGLAB-style struct from FieldTrip data ----------
function EEGin = buildEEGin(trial_data, trial_time, labels, cfg)
    EEGin          = struct();
    EEGin.data     = trial_data;
    EEGin.srate    = 1 / mean(diff(trial_time));
    EEGin.nbchan   = size(trial_data, 1);
    EEGin.pnts     = size(trial_data, 2);
    EEGin.times    = trial_time * 1000;  % s -> ms (EEGLAB convention)
    EEGin.xmin     = trial_time(1);
    EEGin.xmax     = trial_time(end);
    EEGin.trials   = 1;
    EEGin.chanlocs = struct('labels', labels(:)');
    EEGin.etc      = struct();
    EEGin.event    = [];
    EEGin.epoch    = [];
    EEGin.reject   = struct();
    EEGin.stats    = struct();
    EEGin.specdata = [];
    EEGin.specicaact = [];
    EEGin.saved    = 'no';
    EEGin.history  = 'EEGin created in ft_denoise_gedai wrapper';
    EEGin.subject  = '';
    EEGin.group    = '';
    EEGin.condition = '';
    EEGin.ref      = 'average';
    EEGin.chaninfo = struct();
    EEGin.comments = 'Created by ft_denoise_gedai wrapper';
    [EEGin.filepath, EEGin.filename, ~] = fileparts(cfg.dataset);
end

% ---------- detectSignalType: infer 'eeg' or 'meg' from data struct ----------
function signal_type = detectSignalType(data)
    if isfield(data, 'grad') && ~isfield(data, 'elec')
        signal_type = 'meg';
    elseif isfield(data, 'elec') && ~isfield(data, 'grad')
        signal_type = 'eeg';
    else
        % Fallback: inspect channel type labels
        try
            chantypes = ft_chantype(data);
            if any(ismember(chantypes, {'megmag', 'meggrad', 'megplanar', 'meg'}))
                signal_type = 'meg';
            else
                signal_type = 'eeg';
            end
        catch
            warning('ft_denoise_gedai:signalTypeUnknown', ...
                'Could not auto-detect signal type. Defaulting to ''eeg''. Set cfg.signal_type explicitly.');
            signal_type = 'eeg';
        end
    end
end

% ---------- applyDefaults ----------
function cfg2 = applyDefaults(cfg1, def1)
    cfg2 = def1;
    fns  = fieldnames(cfg1);
    for k = 1:numel(fns)
        cfg2.(fns{k}) = cfg1.(fns{k});
    end
end

end
