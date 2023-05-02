function [header,thedata] = open_freq(openfilename)

% Update: 01.2021
% =========================================================================
%
% Opens a Cartool frequency data file (.freq)
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the FREQ file to open (with extension)
%
% OUTPUTS
% - 'header' structure including:
%   - 'NumChan' is the total number of channels (incl. auxiliaries)
%   - 'NumFreq' is the number of frequencies
%   - 'NumBlocks'
%   - 'SamplingRate' is ...the sampling rate!
%   - 'Channels' is a 2D string array with the name of all the channels
%   - 'frequencies' is a 2D string array containing the frequencies
% - (optional) 'thedata' 2D or 3D numeric array with
%   - dimension one represents frequencies
%   - dimension two represents the channels
%   - (dimension three contains the blocks (=timeframes))
%
% ATTENTION: this function is unable to read FFT Complex files yet!
%
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(openfilename,'file')
    error(['Specified file ' openfilename ' not found']);
elseif ~strcmpi(openfilename(end-4:end),'.freq')
    error(['Specified file ' openfilename ' is not a FREQ file']);
end

% open file for reading
fileID = fopen(openfilename,'r');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' openfilename]);
end


%% READ HEADER

% read fixed part of header
header.version = strcat(fread(fileID,4,'int8=>char')'); % 'FR01' (obsolete) or 'FR02'
header.type = strcat(fread(fileID,32,'int8=>char')');
header.NumChan = fread(fileID,1,'int32'); % total number of channels
header.NumFreq = fread(fileID,1,'int32'); % number of frequencies saved in file
header.NumBlocks = fread(fileID,1,'int32'); % number of repeated analysis, or number of resulting "time-frames"
header.SamplingRate = fread(fileID,1,'double'); % sampling rate of the data in the ORIGINAL file (eg. 1024 Hz)
header.BlockFrequency = fread(fileID,1,'double'); % frequency of blocks'occurences (if 1 block is 0.5 s long amd don't overlap -> 2 Hz)
header.year = fread(fileID,1,'int16');
header.month = fread(fileID,1,'int16');
header.day = fread(fileID,1,'int16');
header.hour = fread(fileID,1,'int16');
header.minute = fread(fileID,1,'int16');
header.second = fread(fileID,1,'int16');
header.millisecond = fread(fileID,1,'int16');

% read variable part of header
header.Channels = strcat(fread(fileID,[8,header.NumChan],'int8=>char')');
header.frequencies = strcat(fread(fileID,[16,header.NumFreq],'int8=>char')');


%% READ DATA

if nargout > 1
    thedata = zeros(header.NumFreq,header.NumChan,header.NumBlocks);
    if strcmp(header.type,'FFT Complex') == 1
        error('Sorry, I do not know how to read FFT Complex files yet! :(');
    % elseif strcmp(header.type,'FFT Norm') || strcmp(header.type,'FFT Norm2') || strcmp(header.type,'FFT Approximation') == 1
    else
        for i = 1:header.NumBlocks
            thedata(:,:,i) = fread(fileID,[header.NumFreq,header.NumChan],'float32');
        end
    end
end

fclose(fileID);