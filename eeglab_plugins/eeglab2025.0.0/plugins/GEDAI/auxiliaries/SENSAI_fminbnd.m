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

function [optimalThreshold, maxSENSAIScore] = SENSAI_fminbnd(minThreshold, maxThreshold, EEGdata_epoched, srate, epoch_size, refCOV, Eval, Evec, noise_multiplier)

max_number_of_epochs = 500; % if EEG recording is long (default = 500 epochs)
number_of_epochs = size (EEGdata_epoched,3);

if  number_of_epochs > max_number_of_epochs
rng(2,"twister") ; % for reproducibility
random_epochs =  randi(number_of_epochs, max_number_of_epochs,[1]);
EEGdata_epoched = EEGdata_epoched (:, :, random_epochs);
Eval = Eval (:, :, random_epochs);
Evec = Evec (:, :,random_epochs);

else
end

sensaifunc = @(artifactThreshold) SENSAIObjective(artifactThreshold, EEGdata_epoched, srate, epoch_size, refCOV, Eval, Evec, noise_multiplier);
options = optimset('Display', 'off', 'TolX', 1e-1);
[optimalThreshold, negMaxSENSAIScore] = fminbnd(sensaifunc, minThreshold, maxThreshold, options);
maxSENSAIScore = -negMaxSENSAIScore;

    function objective = SENSAIObjective(artifact_threshold, EEGdata_epoched, srate, epoch_size, refCOV, Eval, Evec, noise_multiplier_obj)
        % Compute the negative SENSAI score for the objective function
        [~, ~, SENSAI_score] = SENSAI(EEGdata_epoched, srate, epoch_size, artifact_threshold, refCOV, Eval, Evec, noise_multiplier_obj);
        objective = -SENSAI_score;
    end
end