% benchmark_eigs_vs_eig.m
% Compares speed of eigs(k) vs eig (full decomposition) for SENSAI-style
% usage on a MEG-sized covariance matrix (300 x 300).

N = 300;          % MEG-like channel count
top_PCs = 3;      % as used in SENSAI
N_epochs = 100;   % typical number of epochs per band
N_reps = 10;      % repetitions for stable timing

fprintf('=== eigs vs eig benchmark: %d x %d covariance, %d epochs, %d reps ===\n\n', ...
    N, N, N_epochs, N_reps);

% Generate a random SPD covariance matrix (same structure as epoch COVs)
rng(42);
A = randn(N, N+50);
C = (A * A') / (N + 50);   % SPD covariance-like matrix

%% --- eigs(k) ---
t_eigs = zeros(1, N_reps);
for r = 1:N_reps
    tic;
    for ep = 1:N_epochs
        [V, ~] = eigs(C, top_PCs);
        %#ok<NASGU>
    end
    t_eigs(r) = toc;
end
mean_eigs = mean(t_eigs) * 1000;
std_eigs  = std(t_eigs)  * 1000;

%% --- eig (full) ---
t_eig = zeros(1, N_reps);
for r = 1:N_reps
    tic;
    for ep = 1:N_epochs
        [V_full, D_full] = eig(C);
        % Mimic SENSAI: sort and take top_PCs columns
        [~, idx] = sort(diag(D_full), 'descend');
        V_top = V_full(:, idx(1:top_PCs)); %#ok<NASGU>
    end
    t_eig(r) = toc;
end
mean_eig = mean(t_eig) * 1000;
std_eig  = std(t_eig)  * 1000;

%% --- Results ---
fprintf('eigs(%d):  %6.1f ms  ±%.1f ms  per %d epochs\n', top_PCs, mean_eigs, std_eigs, N_epochs);
fprintf('eig (full): %6.1f ms  ±%.1f ms  per %d epochs\n', mean_eig, std_eig, N_epochs);
fprintf('\nSpeedup (eig/eigs): %.2fx\n', mean_eig / mean_eigs);
fprintf('Per-epoch:  eigs = %.3f ms,  eig = %.3f ms\n', mean_eigs/N_epochs, mean_eig/N_epochs);
