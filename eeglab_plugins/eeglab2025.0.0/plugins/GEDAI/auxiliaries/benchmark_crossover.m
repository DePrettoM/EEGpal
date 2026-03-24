% benchmark_crossover.m
% Sweeps matrix size to find where eig(full) becomes faster than eigs(k).
% Mimics SENSAI usage: extract top_PCs eigenvectors from a covariance matrix.

top_PCs = 3;
N_epochs = 50;   % epochs per timing call
N_reps   = 5;    % repetitions for stable mean
sizes    = [10 20 30 50 75 100 150 200 300 400 500 750 1000];

rng(42);
fprintf('%-8s  %10s  %10s  %8s\n', 'Size', 'eigs(ms)', 'eig(ms)', 'Speedup');
fprintf('%s\n', repmat('-', 1, 44));

mean_eigs_all = zeros(1, numel(sizes));
mean_eig_all  = zeros(1, numel(sizes));

for si = 1:numel(sizes)
    N = sizes(si);
    A = randn(N, N + 50);
    C = (A * A') / (N + 50);

    % eigs
    t = zeros(1, N_reps);
    for r = 1:N_reps
        tic;
        for ep = 1:N_epochs
            [V, ~] = eigs(C, top_PCs); %#ok<NASGU>
        end
        t(r) = toc;
    end
    mean_eigs = mean(t) * 1000;

    % eig
    t = zeros(1, N_reps);
    for r = 1:N_reps
        tic;
        for ep = 1:N_epochs
            [Vf, Df] = eig(C);
            [~, idx] = sort(diag(Df), 'descend');
            Vt = Vf(:, idx(1:top_PCs)); %#ok<NASGU>
        end
        t(r) = toc;
    end
    mean_eig = mean(t) * 1000;

    mean_eigs_all(si) = mean_eigs;
    mean_eig_all(si)  = mean_eig;

    speedup = mean_eig / mean_eigs;
    winner = '';
    if mean_eig < mean_eigs, winner = ' <-- eig wins'; end
    fprintf('%-8d  %10.1f  %10.1f  %7.2fx%s\n', N, mean_eigs, mean_eig, speedup, winner);
end

% Find crossover
crossover = NaN;
for si = 1:numel(sizes)-1
    if mean_eig_all(si) >= mean_eigs_all(si) && mean_eig_all(si+1) < mean_eigs_all(si+1)
        crossover = sizes(si+1);
    end
end
if ~isnan(crossover)
    fprintf('\nCrossover: eig becomes faster around N = %d\n', crossover);
else
    fprintf('\nNo crossover detected in tested range.\n');
end
