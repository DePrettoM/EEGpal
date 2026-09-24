function [SIGNAL_subspace_similarity, NOISE_subspace_similarity, SENSAI_score] = SENSAI(artifact_threshold, refCOV, Eval, Evec, noise_multiplier, cov_total, evecs_Template_cov)

                       %   Evaluates GEDAI cleaning quality for a given threshold.
%%   Creative Commons License
%
%   Credits:  Tomas Ros & Abele Michela 
%             NeuroTuning Lab [ https://github.com/neurotuning ]
%             Center for Biomedical Imaging
%             University of Geneva
%             Switzerland
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its CONTRIBUTORS
% may be used to endorse or promote products derived from this software without
% specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

[cov_signal_epoched, cov_noise_epoched] = clean_SENSAI(artifact_threshold, refCOV, Eval, Evec, cov_total);

%% Estimate Signal Quality
top_PCs = 3;
num_chans = size(refCOV, 1);

% Top eigenvectors of reference covariance (Calculated outside and passed in)
% [evecs_Template_cov, evals_Template_cov] = eig(refCOV);
% [~, sidxS_Template_cov] = sort(diag(evals_Template_cov), 'descend');
% evecs_Template_cov = evecs_Template_cov(:, sidxS_Template_cov(1:top_PCs));

num_epochs = size(cov_signal_epoched, 3);

SIGNAL_subspace_similarity_distribution = zeros(1, num_epochs);
NOISE_subspace_similarity_distribution = zeros(1, num_epochs);

% Pre-allocate eigenvalue storage for RMT check
all_signal_evals = zeros(num_chans, num_epochs);
all_noise_evals = zeros(num_chans, num_epochs);

for epoch = 1:num_epochs
    % SIGNAL SUBSPACE similarity
    cov_signal = cov_signal_epoched(:,:,epoch);
    [evecs_signal, evals_signal] = eig(cov_signal);
    all_signal_evals(:, epoch) = diag(evals_signal); % Store for RMT
    [~, sidxS_EEGout] = sort(diag(evals_signal), 'descend');
    evecs_signal = evecs_signal(:, sidxS_EEGout(1:top_PCs));
    [SIGNAL_cos_theta] = subspace_angles(evecs_signal, evecs_Template_cov); 
    SIGNAL_subspace_similarity_distribution(epoch) = prod(SIGNAL_cos_theta);

    % NOISE SUBSPACE similarity
    cov_noise = cov_noise_epoched(:,:,epoch);
    [evecs_noise, evals_noise] = eig(cov_noise);
    all_noise_evals(:, epoch) = diag(evals_noise); % Store for RMT
    [~, sidxS_noise] = sort(diag(evals_noise), 'descend');
    evecs_noise = evecs_noise(:, sidxS_noise(1:top_PCs));
    [NOISE_cos_theta] = subspace_angles(evecs_noise, evecs_Template_cov); 
    NOISE_subspace_similarity_distribution(epoch) = prod(NOISE_cos_theta);

end

%% Compute SENSAI Score
SIGNAL_subspace_similarity = 100 * mean(SIGNAL_subspace_similarity_distribution);
NOISE_subspace_similarity = 100 * mean(NOISE_subspace_similarity_distribution);
SENSAI_score = SIGNAL_subspace_similarity - (noise_multiplier * NOISE_subspace_similarity);
end