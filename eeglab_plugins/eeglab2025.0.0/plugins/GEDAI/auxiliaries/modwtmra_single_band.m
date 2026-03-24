function band_signal = modwtmra_single_band(wpt, wavelet_type, target_band)
% MODWTMRA_SINGLE_BAND - Reconstruct a single band from MODWT coefficients
%
% Optimized function to reconstruct only ONE wavelet band instead of all bands.
% Eliminates the need to allocate the full (Bands × Samples × Channels) MRA array.
%
% Usage:
%   band_signal = modwtmra_single_band(wpt, wavelet_type, target_band)
%
% Inputs:
%   wpt           - (Bands x Samples x Channels) MODWT coefficients
%                   Order: [W1, ..., WJ, VJ] from modwt_custom
%   wavelet_type  - 'haar'
%   target_band   - Band index to reconstruct (1 to Bands)
%
% Output:
%   band_signal   - (Samples × Channels) reconstructed signal for ONLY target_band
%
% Memory Advantage:
%   Instead of (Bands × Samples × Channels), returns (Samples × Channels)
%   For 9 bands: ~89% memory reduction for this operation

    if nargin < 2 || isempty(wavelet_type)
        wavelet_type = 'haar';
    end
    
    if ~strcmpi(wavelet_type, 'haar')
        error('modwtmra_single_band currently only supports ''haar'' wavelet.');
    end
    
    [n_bands, n_samples, n_channels] = size(wpt);
    level = n_bands - 1;
    
    inv_sqrt2 = 1 / sqrt(2);
    
    % Initialize approximation at Level J based on target_band
    if target_band == n_bands
        % Reconstructing the approximation band (VJ)
        current_approx = squeeze(wpt(n_bands, :, :));
        if n_channels == 1
            current_approx = reshape(current_approx, n_samples, 1);
        end
    else
        % Reconstructing a detail band, start with zeros
        current_approx = zeros(n_samples, n_channels, 'like', wpt);
    end
    
    % Iterate backwards from Level J to 1
    % Only use coefficients from target_band, all others are zero
    for j = level:-1:1
        step = 2^(j-1);
        
        % Extract detail coefficients only if this is the target band
        if target_band == j
            D_j = squeeze(wpt(j, :, :));
            if n_channels == 1
                D_j = reshape(D_j, n_samples, 1);
            end
        else
            % Not our target band, use zeros
            D_j = zeros(n_samples, n_channels, 'like', wpt);
        end
        
        % IMODWT reconstruction step
        A_shifted = circshift(current_approx, -step, 1);
        D_shifted = circshift(D_j, -step, 1);
        
        current_approx = 0.5 * inv_sqrt2 * ...
            ((current_approx + A_shifted) + (D_shifted - D_j));
    end
    
    % Return the reconstructed band signal
    band_signal = current_approx;
end
