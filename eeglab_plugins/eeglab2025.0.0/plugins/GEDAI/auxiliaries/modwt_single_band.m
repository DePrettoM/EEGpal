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
    
    % Step 1: Forward MODWT decomposition (computes all bands)
    % This is necessary - cannot skip levels in wavelet decomposition
    wpt = modwt_custom(data, wavelet_type, level);
    
    % Step 2: Reconstruct ONLY the target band
    band_signal = modwtmra_single_band(wpt, wavelet_type, target_band);
    
    % Note: wpt is cleared automatically when function exits
end
