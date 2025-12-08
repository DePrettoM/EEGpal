%   GEDAI() - This is the main function used to denoise EEG data using
%   generalized eigenvalue decomposition coupled with an EEG leadfield matrix
%
%   GEDAI (Generalized Eigenvalue Deartifacting Instrument)
%
% Usage:
% Example 1: Using all default values (and no bad epoch rejection)
%    >>  [EEG] = GEDAI(EEG);
%
% Example 2: Defining some parameters
%    >>  [EEG] = GEDAI(EEG, 'auto', 12, 0.5, 'precomputed', true, false, 0.9);
%
% Example 3: Using a "custom" [channel x channel] reference matrix 
%    >>  [EEG] = GEDAI(EEG, 'auto', 12, 0.5, your_refCOV);
%
% Inputs: 
% 
%   EEGin                       - EEG data in EEGlab format
% 
%   artifact_threshold_type     - Variable determining deartifacting
%                                 strength. Stronger threshold type
%                                 ("auto+") might remove more noise at the
%                                 expense of signal, while milder threshold
%                                 ("auto-") might retain more signal at the 
%                                 expense of noise. Possible levels:
%                                 "auto-", "auto" or "auto+". 
%                                 Default is "auto".
%                             
%   epoch_size_in_cycles        - Epoch size in number of wave cycles for each
%                                 wavelet band. Default is 12.
%
%   lowcut_frequency            - Low-cut frequency in Hz. Wavelet bands below this
%                                 frequency will be excluded. Default is 0.5 Hz.
% 
%   ref_matrix_type             - Matrix used as a reference for deartifacting.
%
%                                  The default "precomputed" uses a BEM leadfield for
%                                  standard electrode locations precomputed through 
%                                  OPENMEEG (343 electrodes) based on 10-5 system. 
%
%                                 "interpolated" uses the precomputed leadfield and 
%                                 interpolates it to non-standard electrode locations.
%
%                                 Altenatively, you can input a "custom" covariance matrix
%                                 (with dimensions channel x channel) via a matlab variable
% 
% 
%   parallel                    - Boolean for using parallel ('multicore') processing 
% 
%   visualize_artifacts         - Boolean for artifact visualization 
%                                 using vis_artifacts function from the ASR toolbox
%
%   ENOVA_threshold             - Threshold for rejecting epochs based on Explained
%                                 Noise Variance (ENOVA). Epochs with ENOVA >
%                                 ENOVA_threshold will be removed. Default is inf
%                                 (no rejection).
%    
% Outputs:
% 
%   EEGclean                - Cleaned EEG data in EEGLab struct format
% 
%   EEGartifacts            - EEG data containing only the removed artifacts
%                             (i.e. noise that was removed from EEGin)
%                             EEGin.data = EEGclean.data + EEGartifacts.data
% 
%   SENSAI_score            - Relative denoising quality score (%)
%
%   SENSAI_score_per_band   - Relative denoising quality score per band (%)
% 
%   artifact_threshold_per_band  - Vector of artifact thresholds used for each 
%                                  frequency band, starting with the broadband
%                                  approx: [broadband gamma beta alpha theta delta etc.]
%
%   mean_ENOVA              - Mean Explained Noise Variance (ENOVA) across all epochs.
%                             ENOVA is the variance of the removed noise, expressed as a 
%                             proportion of the variance of the original EEG data.
%
%   ENOVA_per_epoch         - Vector of ENOVA values for each epoch.
% 
%   com                     - output logging to EEG.history

% [Generalized Eigenvalue De-Artifacting Intrument (GEDAI) v 1.3]
% PolyForm Noncommercial License 1.0.0
% https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Copyright (C) [2025] Tomas Ros & Abele Michela
%             NeuroTuning Lab [ https://github.com/neurotuning ]
%             Center for Biomedical Imaging
%             University of Geneva
%             Switzerland
%
% For any questions, please contact:
% dr.t.ros@gmail.com

function [EEGclean, EEGartifacts, SENSAI_score, SENSAI_score_per_band, artifact_threshold_per_band, mean_ENOVA, ENOVA_per_epoch, com]=GEDAI(EEGin, artifact_threshold_type, epoch_size_in_cycles, lowcut_frequency, ref_matrix_type, parallel, visualize_artifacts, ENOVA_threshold)

if nargin < 2 || isempty(artifact_threshold_type)
    artifact_threshold_type = 'auto';
end
if nargin < 3 || isempty(epoch_size_in_cycles)
    epoch_size_in_cycles = 12;  % Note: Number of wave CYCLES per epoch across wavelet bands (default = 12 cycles)
end
if nargin < 4 || isempty(lowcut_frequency)
    lowcut_frequency = 0.5; %  exclude all wavelet bands below this frequency (default = 0.5 Hz)
end
if nargin < 5 || isempty(ref_matrix_type)
    ref_matrix_type = 'precomputed';
end
if nargin < 6 || isempty(parallel)
    parallel = true;
end
if nargin < 7 || isempty(visualize_artifacts)
    visualize_artifacts = false;
end
if nargin < 8 || isempty(ENOVA_threshold)
    ENOVA_threshold = inf; % If empty, set to infinity to disable rejection
end

p = fileparts(which('GEDAI'));
addpath(fullfile(p, 'auxiliaries'));
tStart = tic;  
% -- Ensure epoch size results in an even number of samples (for broadband)
 broadband_epoch_size = 1; % Note: IN SECONDS (this is now only the DEFAULT for broadband)
if rem(broadband_epoch_size*EEGin.srate, 2) ~= 0
    ideal_total_samples_double = broadband_epoch_size * EEGin.srate;
    nearest_integer_samples = round(ideal_total_samples_double);
    if rem(nearest_integer_samples, 2) ~= 0
        if abs(ideal_total_samples_double - (nearest_integer_samples - 1)) < abs(ideal_total_samples_double - (nearest_integer_samples + 1))
            target_total_samples_int = nearest_integer_samples - 1;
        else
            target_total_samples_int = nearest_integer_samples + 1;
        end
    else
        target_total_samples_int = nearest_integer_samples;
    end
    broadband_epoch_size = target_total_samples_int / EEGin.srate;
end
%% Pre-processing
EEGavRef = GEDAI_nonRankDeficientAveRef(EEGin); % non rank-deficient average referencing (Makoto's plugin)

%% Create Reference Covariance Matrix (refCOV)
if ~ischar(ref_matrix_type)
    refCOV = ref_matrix_type; % Use custom covariance matrix
    disp([newline 'Using custom covariance matrix']);
else
    switch ref_matrix_type
        case 'precomputed'
        disp([newline 'GEDAI Leadfield model: BEM precomputed'])
            L=load('fsavLEADFIELD_4_GEDAI.mat');
            electrodes_labels = {EEGin.chanlocs.labels};
            template_electrode_labels = {L.leadfield4GEDAI.electrodes.Name};
            [~, chanidx] = ismember(lower(electrodes_labels), lower(template_electrode_labels));
            if any(chanidx == 0)
                error('Electrode labels not found. Select "interpolated" leadfield matrix for non-standard locations.');
            end
            refCOV = L.leadfield4GEDAI.gram_matrix_avref(chanidx,chanidx);

        case 'interpolated'
            disp([newline 'GEDAI Leadfield model: BEM interpolated'])
            L=load('fsavLEADFIELD_4_GEDAI.mat');
            % The leadfield data needs to be average referenced before interpolation
            leadfield_EEG = L.leadfield4GEDAI.EEG;
            leadfield_EEG.data = L.leadfield4GEDAI.Gain - mean(L.leadfield4GEDAI.Gain, 1); % Average reference
            interpolated_EEG = interp_mont_GEDAI(leadfield_EEG, EEGavRef.chanlocs);
            refCOV = interpolated_EEG.data*interpolated_EEG.data';
    end
end
% --- Wavelet-based High-Pass Filtering ---
number_of_wavelet_levels = 3;
wavelet_type = 'haar';

% Decompose the signal
wpt_hp = modwt(EEGavRef.data', wavelet_type, number_of_wavelet_levels);
mra_hp = modwtmra(wpt_hp, wavelet_type); % bands x samples x channels

% Identify wavelet bands to remove based on lowcut_frequency
srate = EEGavRef.srate;
num_bands_hp = size(mra_hp, 1);
for f = 1:num_bands_hp
    upper_bound = srate / (2^f);
    if upper_bound <= lowcut_frequency
        mra_hp(f, :, :) = 0; % Remove bands below the cutoff
    end
end

% Reconstruct the high-passed signal
EEGavRef.data = squeeze(sum(mra_hp, 1))';

%% First pass: Broadband denoising
disp([newline 'SENSAI threshold detection...please wait']);
broadband_optimization_type = 'parabolic';
broadband_artifact_threshold_type = 'auto-';
[cleaned_broadband_data, ~, broadband_sensai, broadband_thresh] = GEDAI_per_band(double(EEGavRef.data), EEGavRef.srate, EEGavRef.chanlocs, broadband_artifact_threshold_type, broadband_epoch_size, refCOV, broadband_optimization_type, parallel);
% Initialize the output arrays with the broadband results
SENSAI_score_per_band = broadband_sensai;
artifact_threshold_per_band = broadband_thresh;
%% Second pass: Wavelet decomposition and per-band denoising
unfiltered_data = cleaned_broadband_data';
number_of_wavelet_levels = 3;
number_of_wavelet_bands = 2^number_of_wavelet_levels + 1;
wavelet_type = 'haar';
wpt_EEG = modwt(unfiltered_data, wavelet_type, number_of_wavelet_bands);
wpt_EEG = modwtmra(wpt_EEG, wavelet_type); % wavelet bands x samples x channels
number_of_discrete_wavelet_bands = size(wpt_EEG, 1);

% Pre-calculate center frequencies for each MRA wavelet band
center_frequencies = zeros(1, number_of_discrete_wavelet_bands);
lower_frequencies = zeros(1, number_of_discrete_wavelet_bands);
upper_frequencies = zeros(1, number_of_discrete_wavelet_bands);
for f = 1:number_of_discrete_wavelet_bands
    % The passband for MRA band 'f' is approx. [Fs/(2^(f+1)), Fs/(2^f)]
    lower_bound = srate / (2^(f + 1));
    upper_bound = srate / (2^f);
    center_frequencies(f) = (lower_bound + upper_bound) / 2;
    lower_frequencies(f) = lower_bound; 
    upper_frequencies(f) = upper_bound;
end


lowest_wavelet_bands_to_exclude = sum(upper_frequencies <= lowcut_frequency); 
num_bands_to_process = number_of_discrete_wavelet_bands - lowest_wavelet_bands_to_exclude;

% --- Check if data is long enough for the lowest frequency epoch size---
if num_bands_to_process > 0
    lowest_band_to_process_idx = num_bands_to_process;
    epoch_size_lowest_band = epoch_size_in_cycles / lower_frequencies(lowest_band_to_process_idx);
    required_samples = epoch_size_lowest_band * srate;

    while required_samples > size(EEGavRef.data, 2) && num_bands_to_process > 0
        warning('GEDAI:InsufficientData', 'EEG data length is too short for the epoch size required by the lowest frequency band (%g Hz). Increasing lowcut_frequency.', center_frequencies(lowest_band_to_process_idx));
        lowcut_frequency = upper_frequencies(lowest_band_to_process_idx);
        lowest_wavelet_bands_to_exclude = sum(upper_frequencies <= lowcut_frequency);
        num_bands_to_process = number_of_discrete_wavelet_bands - lowest_wavelet_bands_to_exclude;
        
        lowest_band_to_process_idx = num_bands_to_process;
        epoch_size_lowest_band = epoch_size_in_cycles / lower_frequencies(lowest_band_to_process_idx);
        required_samples = epoch_size_lowest_band * srate;
    end
end

%%  Define Frequency-Dependent Epoch Sizes ---

% Calculate the ideal epoch size for each band based on the rule
epoch_sizes_per_wavelet_band = epoch_size_in_cycles ./ lower_frequencies;

% --- Display wavelet band-widths and epoch sizes ---
disp(' '); 
left_margin = '  '; 
header1 = 'Wavelet Center Freq (Hz)';
header2 = 'Epoch Size (s)';
str_freqs = num2str(center_frequencies(1:num_bands_to_process)', '%.2g');
str_epochs = num2str(epoch_sizes_per_wavelet_band(1:num_bands_to_process)', '%.2g');
col1_width = max(length(header1), size(str_freqs, 2));
col2_width = max(length(header2), size(str_epochs, 2));
fprintf('%s%*s | %-*s\n', left_margin, col1_width, header1, col2_width, header2);
fprintf('%s%s-|- %s\n', left_margin, repmat('-', 1, col1_width), repmat('-', 1, col2_width));
for i = 1:num_bands_to_process
    fprintf('%s%*s | %-*s\n', left_margin, col1_width, str_freqs(i,:), col2_width, str_epochs(i,:));
end

disp([newline 'Excluding ', num2str(lowest_wavelet_bands_to_exclude), ' wavelet bands with upper frequency < ' num2str(lowcut_frequency) ' Hz.']);


% Correct each epoch size to ensure it corresponds to an even number of samples
for f = 1:num_bands_to_process
    ideal_samples = epoch_sizes_per_wavelet_band(f) * srate;
    rounded_samples = round(ideal_samples);
    if rem(rounded_samples, 2) ~= 0
        % If odd, choose the nearest even number
        if abs(ideal_samples - (rounded_samples - 1)) < abs(ideal_samples - (rounded_samples + 1))
            final_samples = rounded_samples - 1;
        else
            final_samples = rounded_samples + 1;
        end
    else
        final_samples = rounded_samples;
    end
    epoch_sizes_per_wavelet_band(f) = final_samples / srate;
end

%% Denoise each wavelet band
num_channels = size(cleaned_broadband_data, 1);
num_samples = size(cleaned_broadband_data, 2);
wavelet_band_filtered_data = zeros(num_bands_to_process, num_channels, num_samples);
if parallel
    temp_sensai_scores = zeros(1, num_bands_to_process);
    temp_thresholds = zeros(1, num_bands_to_process);
    
    parfor f = 1:num_bands_to_process
        wavelet_data_band = transpose(squeeze(wpt_EEG(f,:,:)));
        
        current_epoch_size = epoch_sizes_per_wavelet_band(f);
        [cleaned_band_data, ~, temp_sensai, temp_thresh] = GEDAI_per_band(double(wavelet_data_band), srate, EEGavRef.chanlocs, artifact_threshold_type, current_epoch_size, refCOV, 'parabolic', false);
        
        wavelet_band_filtered_data(f, :,:) = cleaned_band_data;
        temp_sensai_scores(f) = temp_sensai;
        temp_thresholds(f) = temp_thresh;
    end
    
    SENSAI_score_per_band = [SENSAI_score_per_band, temp_sensai_scores];
    artifact_threshold_per_band = [artifact_threshold_per_band, temp_thresholds];
    
else % Non-parallel version
    for f = 1:num_bands_to_process
        wavelet_data_band = transpose(squeeze(wpt_EEG(f,:,:)));
        
        current_epoch_size = epoch_sizes_per_wavelet_band(f);
        [cleaned_band_data, ~, sensai_val, thresh_val] = GEDAI_per_band(wavelet_data_band, srate, EEGavRef.chanlocs, artifact_threshold_type, current_epoch_size, refCOV, 'parabolic', false);
        
        wavelet_band_filtered_data(f, :,:) = cleaned_band_data;
        SENSAI_score_per_band(f+1) = sensai_val;
        artifact_threshold_per_band(f+1) = thresh_val;
    end
end
%% Finalization: Reconstruct EEG and calculate final scores
% Reconstruct EEG from cleaned wavelet bands
EEGclean = EEGavRef;
EEGclean.data = squeeze(sum(wavelet_band_filtered_data, 1));
% Create artifact structure
EEGartifacts = EEGclean;
EEGartifacts.data = EEGavRef.data(:, 1:size(EEGclean.data, 2)) - EEGclean.data;

% Calculate composite SENSAI score
noise_multiplier = 1;
[SENSAI_score, ~, ~, mean_ENOVA, ENOVA_per_epoch] = SENSAI_basic(double(EEGclean.data), double(EEGartifacts.data), EEGavRef.srate, broadband_epoch_size, refCOV, noise_multiplier);

epochs_to_remove = find(ENOVA_per_epoch > ENOVA_threshold);
regions = [];
if ~isempty(epochs_to_remove)
    epoch_samples = round(broadband_epoch_size * EEGavRef.srate);
    regions = zeros(length(epochs_to_remove), 2);
    for i = 1:length(epochs_to_remove)
        epoch = epochs_to_remove(i);
        start_sample = (epoch - 1) * epoch_samples + 1;
        end_sample = epoch * epoch_samples;
        if end_sample > size(EEGclean.data, 2)
            end_sample = size(EEGclean.data, 2);
        end
        regions(i,:) = [start_sample end_sample];
    end
end

tEnd = toc(tStart);


% Generate command history
if ~ischar(ref_matrix_type)
    ref_matrix_type = 'custom';
end
com = sprintf('EEG = GEDAI(EEG, ''artifact_threshold'', ''%s'', ''epoch_size_in_cycles'', %s, ''lowcut_frequency'', %s, ''ref_matrix_type'', ''%s'', ''parallel_processing'', %d, ''visualization_A'', %d, ''ENOVA_threshold'', %s);', ...
    artifact_threshold_type, num2str(epoch_size_in_cycles), num2str(lowcut_frequency), ref_matrix_type, parallel, visualize_artifacts, num2str(ENOVA_threshold));

if visualize_artifacts
    EEGclean_for_vis = EEGclean;
    if ~isempty(regions)
        clean_sample_mask = true(1, EEGclean_for_vis.pnts);
        for i = 1:size(regions, 1)
            clean_sample_mask(regions(i,1):regions(i,2)) = false;
        end
        EEGclean_for_vis.etc.clean_sample_mask = clean_sample_mask;
        EEGclean_for_vis.data = EEGclean_for_vis.data(:, clean_sample_mask);
        EEGclean_for_vis.pnts = size(EEGclean_for_vis.data, 2);
    end
    vis_artifacts(EEGclean_for_vis, EEGavRef, 'ScaleBy', 'noscale', 'YScaling', 3*mad(EEGavRef.data(:)));
end

if ~isempty(regions)
    disp([newline 'Removing bad epochs...']);
    EEGclean = eeg_eegrej(EEGclean, regions);
    EEGartifacts = eeg_eegrej(EEGartifacts, regions);
end

% Calculate final SENSAI score (after potential epoch rejection)
[SENSAI_score, ~, ~, mean_ENOVA, ENOVA_per_epoch] = SENSAI_basic(double(EEGclean.data), double(EEGartifacts.data), EEGavRef.srate, broadband_epoch_size, refCOV, noise_multiplier);

disp([newline 'SENSAI score: ' num2str(round(SENSAI_score, 2, 'significant'))]);
disp(['Mean ENOVA: ' num2str(round(mean_ENOVA, 2, 'significant'))]);

total_epochs = length(ENOVA_per_epoch);
num_rejected = length(epochs_to_remove);
if total_epochs > 0
    percentage_rejected = (num_rejected / total_epochs) * 100;
else
    percentage_rejected = 0;
end
disp(['Bad epochs rejected: ' num2str(round(percentage_rejected,1)) ' % (' num2str(num_rejected) ' out of ' num2str(total_epochs) ' epochs)']);

disp(['Elapsed time: ' num2str(round(tEnd, 2, 'significant')) ' seconds' newline]);

% Add command history to EEGLAB structure
if exist('eegh', 'file')
    EEGclean = eegh(com, EEGclean);
end
end