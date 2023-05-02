function GlobalPower = compute_gfp(thedata,type)

% Update: 01.2020
% =========================================================================
%
% Calculates the Global Field Power (GFP) or Global Power Spectra (GPS) of
% a data set
%
%
% INPUTS
% - 'thedata' 2D or 3D numeric array with
%   - dimension one: timeframes (GFP) or frequencies (GPS)
%   - dimension two: channels
%   - (GPS: dimension three contains the blocks (=timeframes))
% - (optional) 'GFP' (default) or 'GPS' type of computation
%
% OUTPUTS
% - 'GFP' or 'GPS' 2D numeric array with
%   - dimension one: timeframes (GFP) or frequencies (GPS)
%   - (GPS: dimension two represents the blocks (=timeframes))
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


if nargin == 1
    type = 'GFP';
end

%% GFP

if strcmpi(type,'GFP')
    % Define number of time frames and channels
    NumTF = size(thedata,1);
    NumChan = size(thedata,2);

    % Compute Global Field Power
    GlobalPower = zeros(NumTF,1);
    for tf = 1:NumTF
        GlobalPower(tf) = sqrt(sum((thedata(tf,:) - mean(thedata(tf,:))).^2)/NumChan);
    end
end


%% GPS

if strcmpi(type,'GPS')
    % Define number of frequencies, channels, and time frames
    NumFreq = size(thedata,1);
    % NumChan = size(thedata,2);
    NumTF = size(thedata,3);
    
    % Compute Global Power Spectra
    GlobalPower = zeros(NumFreq,NumTF);
    for tf = 1:NumTF
        for freq = 1:NumFreq
            GlobalPower(freq,tf) = mean(abs(thedata(freq,:,tf)));
        end
    end
end