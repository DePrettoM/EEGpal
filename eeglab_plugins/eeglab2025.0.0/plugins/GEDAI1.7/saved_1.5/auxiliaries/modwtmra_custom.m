function mra = modwtmra_custom(wpt, wavelet_type)
%(Inverse Stationary Wavelet Transform)
%
% Usage:
%   mra = modwtmra_custom(wpt, wavelet_type)
%
% Inputs:
%   wpt           - (Bands x Samples x Channels) matrix
%                   Order: [W1, ..., WJ, VJ]
%   wavelet_type  - 'haar'
%
% Output:
%   mra           - (Bands x Samples x Channels)
%                   Reconstructed time-domain signal for each band.
%                   Order: [D1, ..., DJ, AJ] (Matches W1...WJ, VJ)

    if nargin < 2 || isempty(wavelet_type)
        wavelet_type = 'haar';
    end
    
    if ~strcmpi(wavelet_type, 'haar')
        error('modwtmra_custom currently only supports ''haar'' wavelet.');
    end
    
    [n_bands, n_samples, n_channels] = size(wpt);
    level = n_bands - 1;
    
    inv_sqrt2 = 1 / sqrt(2);
    
    % Pre-allocate output
    mra = zeros(n_bands, n_samples, n_channels, 'like', wpt);   
    
    for band_idx = 1:n_bands
        % We are reconstructing the signal using ONLY coeff from 'band_idx'.
        % All other coeffs are zero suitable for the ISWT.
        
        % Initialize Approximation at Level J.
        % If band_idx == n_bands (VJ), this starts non-zero. Else zero.
        if band_idx == n_bands
            current_approx_recon = squeeze(wpt(n_bands, :, :));
            % Reshape if squeeze removed dim
            if n_channels == 1
                current_approx_recon = reshape(current_approx_recon, n_samples, 1);
            end
        else
            current_approx_recon = zeros(n_samples, n_channels, 'like', wpt);
        end
        
        % Iterate backwards from Level J to 1
        for j = level:-1:1
            step = 2^(j-1);
                       
            if band_idx == j
                D_j = squeeze(wpt(j, :, :));
                if n_channels == 1, D_j = reshape(D_j, n_samples, 1); end
            else
                D_j = zeros(n_samples, n_channels, 'like', wpt);
            end
            
            % Compute Estimates shifted
            A_shifted = circshift(current_approx_recon, -step, 1);
            D_shifted = circshift(D_j, -step, 1);           
            current_approx_recon = 0.5 * inv_sqrt2 * ( (current_approx_recon + A_shifted) + (D_shifted - D_j) );
            
        end
        
        % Store the full reconstruction for this band
        mra(band_idx, :, :) = current_approx_recon;
    end

end
