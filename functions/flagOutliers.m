function ChanOutliers = flagOutliers(thedata,MADlod,MADrange)

% Update: 03.2021
% =========================================================================
%
% Identifies EEG channel outliers by computing the standard deviation
% across all time-frames of each channel and flags potential channels to
% interpolate using the median absolute deviation (MAD; Leys et al., 2013)
%
% => mad(x,1) * 1.4826 = MAD, then MAD * LOD
%    Outliers are outside the range MEAN +/- (MAD*LOD)
%
%
% INPUTS
% - Data as a 2-D numeric array where
%   - Dimension 1 contains the timeframes
%   - Dimension 2 contains the channels
% - (optional) Level of decision (MADlod):
%   - 3 (very conservative)
%   - 2.5 (moderately conservative)
%   - 2 (poorly conservative)
%   Default: 2.5
% - (optional) MAD range around the median (assuming normal distribution)
%   Default: 1.4826
%
%
% OUTPUT
% - Logical array indicating outliers (=1)
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


% Check inputs
if nargin == 1 || isempty(MADlod)
    MADlod = 2.5;
end
if nargin < 3 || isempty(MADrange)
    MADrange = 1.4826;
end


% Read the data
%nChan = size(thedata,2); % Number of channels
stdAllPnts  = std(thedata(:,:),0,1); % Standard deviation for all channels

% Identify outliers
OutliersDist = (mad(stdAllPnts,1) * MADrange) * MADlod;
SupLim = median(stdAllPnts) + OutliersDist;
InfLim = median(stdAllPnts) - OutliersDist;

ChanOutliers = max(stdAllPnts > SupLim, stdAllPnts < InfLim);