function wpt = modwt_custom(data, wavelet_type, level)

% Usage:
%   wpt = modwt_custom(data, wavelet_type, level)
%
% Inputs:
%   data          - (Samples x Channels) matrix
%   wavelet_type  - 'haar' (currently only 'haar' supported for manual implementation)
%   level         - Decomposition level
%
% Output:
%   wpt           - (Level+1 x Samples x Channels) array
%                   Order: [W1, W2, ..., WJ, VJ] (Details ... Approx)

    if nargin < 2 || isempty(wavelet_type)
        wavelet_type = 'haar';
    end
    
    if ~strcmpi(wavelet_type, 'haar')
        error('modwt_custom currently only supports ''haar'' wavelet.');
    end
    
    % Ensure inputs are correct
    [n_samples, n_channels] = size(data);
    
    % Filters for Haar (normalized)
    inv_sqrt2 = 1 / sqrt(2);
    
    % Pre-allocate output

    wpt = zeros(level + 1, n_samples, n_channels, 'like', data);
    
    % Current approximation coefficients (starts as data)
    current_approx = data;
    
    for j = 1:level
        % Filter step (2^(j-1))
        step = 2^(j-1);
        
        % Circular shift for convolution correlation       
        shifted_approx = circshift(current_approx, step, 1);
        
        % Compute Approx (Low Pass): (x[n] + x[n-step]) * c
        next_approx = (current_approx + shifted_approx) * inv_sqrt2;
        
        % Compute Detail (High Pass): (x[n-step] - x[n]) * c ?
        detail = (shifted_approx - current_approx) * inv_sqrt2;
        
        % Store Detail Wj
        wpt(j, :, :) = detail;
        
        % Update Approx for next level
        current_approx = next_approx;
    end
    
    % Store Final Approx VJ
    wpt(level + 1, :, :) = current_approx;

end
