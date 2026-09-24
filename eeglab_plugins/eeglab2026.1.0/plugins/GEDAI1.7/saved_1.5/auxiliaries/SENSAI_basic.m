% [Generalized Eigenvalue De-Artifacting Intrument (GEDAI)]
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

function [SENSAI_score, SIGNAL_subspace_similarity, NOISE_subspace_similarity, mean_ENOVA, ENOVA_per_epoch] = SENSAI_basic(signal_data, noise_data, srate, epoch_size, refCOV, NOISE_multiplier, signal_type)

    %   Calculates the Signal & Noise Subspace Alignment Index (SENSAI) from raw EEG data
    
regularization_lambda = 0.05;
reg_val = trace(refCOV) / length(refCOV);
refCOV_reg = (1-regularization_lambda)*refCOV + regularization_lambda*reg_val*eye(length(refCOV), 'like', refCOV);

%% Estimate Signal Quality
if nargin < 7 || isempty(signal_type)
    signal_type = 'eeg';
end

if strcmpi(signal_type, 'meg')
    refCOV_top_PCs = 5;
else
    refCOV_top_PCs = 3;
end
top_PCs = 3; % Always keep subspace comparison at 3 PCs 
num_chans = size(refCOV, 1);
epoch_samples = srate * epoch_size;
% Top eigenvectors of refCOV subspace
[evecs_Template_cov, evals_Template_cov] = eig(refCOV_reg);
[~, sidxS_Template_cov] = sort(diag(evals_Template_cov), 'descend');
evecs_Template_cov = evecs_Template_cov(:, sidxS_Template_cov(1:refCOV_top_PCs));

% --- FIX START: Truncate data to contain a whole number of epochs ---
pnts = size(signal_data, 2);
num_epochs_possible = floor(pnts / epoch_samples);
new_length = num_epochs_possible * epoch_samples;

signal_data = signal_data(:, 1:new_length);
noise_data = noise_data(:, 1:new_length);
% --- FIX END ---

% Epoch signal and noise data
signal_EEG_epoched = reshape(signal_data, num_chans, epoch_samples, []);
noise_EEG_epoched = reshape(noise_data, num_chans, epoch_samples, []);
num_epochs = size(signal_EEG_epoched, 3);
SIGNAL_subspace_similarity_distribution = zeros(1, num_epochs);
NOISE_subspace_similarity_distribution = zeros(1, num_epochs);
ENOVA_per_epoch = zeros(1, num_epochs);
for epoch = 1:num_epochs
    % SIGNAL SUBSPACE
    cov_signal_EEG = cov(signal_EEG_epoched(:,:,epoch)');
    [evecs_signal_EEG, evals_signal_EEG] = eig(cov_signal_EEG);
    [~, sidxS_signal_EEG] = sort(diag(evals_signal_EEG), 'descend');
    evecs_signal_EEG = evecs_signal_EEG(:, sidxS_signal_EEG(1:top_PCs));
    [SIGNAL_cos_theta] = subspace_angles(evecs_signal_EEG, evecs_Template_cov); 
    SIGNAL_subspace_similarity_distribution(epoch) = prod(SIGNAL_cos_theta);
    % NOISE SUBSPACE
    cov_noise = cov(noise_EEG_epoched(:,:,epoch)');
    [evecs_noise, evals_noise] = eig(cov_noise);
    [~, sidxS_noise] = sort(diag(evals_noise), 'descend');
    evecs_noise = evecs_noise(:, sidxS_noise(1:top_PCs));
    [NOISE_cos_theta] = subspace_angles(evecs_noise, evecs_Template_cov); 
    NOISE_subspace_similarity_distribution(epoch) = prod(NOISE_cos_theta);

    % Explained Noise Variance (ENOVA)
    original_epoch = signal_EEG_epoched(:,:,epoch) + noise_EEG_epoched(:,:,epoch);
    var_original = var(original_epoch(:));
    var_noise = var(reshape(noise_EEG_epoched(:,:,epoch), [], 1));
    ENOVA_per_epoch(epoch) = var_noise / var_original;
end
mean_ENOVA = mean(ENOVA_per_epoch);
SIGNAL_subspace_similarity = 100 * mean(SIGNAL_subspace_similarity_distribution);
NOISE_subspace_similarity = 100 * mean(NOISE_subspace_similarity_distribution);
SENSAI_score = SIGNAL_subspace_similarity - NOISE_multiplier * NOISE_subspace_similarity;
end