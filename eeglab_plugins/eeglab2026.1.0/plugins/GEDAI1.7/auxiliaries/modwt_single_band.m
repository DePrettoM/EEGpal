function band_signal = modwt_single_band(data, wavelet_type, level, target_band)
% MODWT_SINGLE_BAND - Decompose and reconstruct a single wavelet band
%
% Convenience wrapper that performs MODWT decomposition and then reconstructs
% only the requested band. Optimized for memory efficiency in incremental
% band processing.
%
% Usage:
%   band_signal = modwt_single_band(data, wavelet_type, level, target_band)
%
% Inputs:
%   data          - (Samples × Channels) input signal
%   wavelet_type  - 'haar' (currently only Haar supported)
%   level         - Decomposition level (e.g., 3 = 8 detail bands + 1 approx)
%   target_band   - Which band to extract (1 to 2^level for details, 2^level+1 for approx)
%
% Output:
%   band_signal   - (Samples × Channels) reconstructed signal for target_band only
%
% Example:
%   % Extract band 3 from a Level-3 decomposition
%   band3 = modwt_single_band(data, 'haar', 3, 3);
%
% Memory Efficiency:
%   This function still computes the full decomposition but only reconstructs
%   one band, saving memory on the reconstruction side (~89% for 9 bands).
%   Use this in loops to process bands incrementally without storing full MRA.

    if nargin < 2 || isempty(wavelet_type)
        wavelet_type = 'haar';
    end
    
    if nargin < 4 || isempty(target_band)
        error('target_band must be specified (1 to 2^level+1)');
    end
    
    if ~strcmpi(wavelet_type, 'haar')
        error('modwt_single_band currently only supports ''haar'' wavelet.');
    end
    
    % --- FORWARD DECOMPOSITION ---
    % Compute ONLY the coefficients for target_band to save memory
    inv_sqrt2 = 1 / sqrt(2);
    current_approx = data;
    n_bands = level + 1;
    
    % If target_band is an approximation (n_bands), we need to go up to 'level'
    % If it's a detail band (target_band <= level), we only need to go up to 'target_band'
    max_level_needed = min(target_band, level);
    
    for j = 1:max_level_needed
        step = 2^(j-1);
        shifted_approx = circshift(current_approx, step, 1);
        
        if j == target_band
            % This is the detail band we want!
            target_coefs = (shifted_approx - current_approx) * inv_sqrt2;
        else
            % We just need the approximation to proceed to the next level
            current_approx = (current_approx + shifted_approx) * inv_sqrt2;
        end
    end
    
    if target_band == n_bands
        % The target is the final approximation band
        target_coefs = current_approx;
    end
    
    % --- INVERSE RECONSTRUCTION ---
    % Reconstruct using ONLY target_coefs, bypassing full wpt array allocation
    current_recon = target_coefs;
    
    if target_band == n_bands
        for j = level:-1:1
            step = 2^(j-1);
            A_shifted = circshift(current_recon, -step, 1);
            current_recon = 0.5 * inv_sqrt2 * (current_recon + A_shifted);
        end
    else
        % It's a detail band. We start reconstruction at j = target_band
        j = target_band;
        step = 2^(j-1);
        
        D_shifted = circshift(current_recon, -step, 1);
        current_recon = 0.5 * inv_sqrt2 * (D_shifted - current_recon);
        
        for j = (target_band-1):-1:1
            step = 2^(j-1);
            A_shifted = circshift(current_recon, -step, 1);
            current_recon = 0.5 * inv_sqrt2 * (current_recon + A_shifted);
        end
    end
    
    band_signal = current_recon;
end
