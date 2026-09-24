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
        % All other coeffs are implicitly zero.
        
        if band_idx == n_bands
            % VJ band (Approximation)
            current_approx_recon = squeeze(wpt(n_bands, :, :));
            if n_channels == 1
                current_approx_recon = reshape(current_approx_recon, n_samples, 1);
            end
            
            for j = level:-1:1
                step = 2^(j-1);
                A_shifted = circshift(current_approx_recon, -step, 1);
                current_approx_recon = 0.5 * inv_sqrt2 * (current_approx_recon + A_shifted);
            end
        else
            % Wj bands (Details)
            % For j > band_idx, current_approx_recon remains 0, so we can skip those iterations.
            
            % Start at j = band_idx
            j = band_idx;
            step = 2^(j-1);
            
            D_j = squeeze(wpt(j, :, :));
            if n_channels == 1
                D_j = reshape(D_j, n_samples, 1); 
            end
            
            D_shifted = circshift(D_j, -step, 1);
            % Since current_approx_recon is 0, A_shifted is 0
            current_approx_recon = 0.5 * inv_sqrt2 * (D_shifted - D_j);
            
            % For j < band_idx
            for j = (band_idx-1):-1:1
                step = 2^(j-1);
                A_shifted = circshift(current_approx_recon, -step, 1);
                current_approx_recon = 0.5 * inv_sqrt2 * (current_approx_recon + A_shifted);
            end
        end
        
        % Store the full reconstruction for this band
        mra(band_idx, :, :) = current_approx_recon;
    end

end
