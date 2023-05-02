function [header,thedata] = open_ris(openfilename)

% Update: 01.2021
% =========================================================================
%
% Opens a Cartool Results of Inverse Solution data file (.ris)
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the RIS file to open (with extension)
%
% OUTPUTS
% - 'header' structure including:
%   - 'NumSP' is the total number of channels
%   - 'NumTF' is the number of timeframes
%   - 'SamplingRate' is ...the sampling rate!
% - (optional) 'data' 2D numeric array with
%   - dimension one represents time-frames
%   - dimension two represents the solution points
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(openfilename,'file')
    error(['Specified file ' openfilename ' not found']);
elseif ~strcmpi(openfilename(end-3:end),'.ris')
    error(['Specified file ' openfilename ' is not a RIS file']);
end

% open file for reading
fileID = fopen(openfilename,'r');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' openfilename]);
end


%% READ HEADER

header.version = strcat(fread(fileID,4,'int8=>char')');
header.NumSP = fread(fileID,1,'int32');
header.NumTF = fread(fileID,1,'int32');
header.SamplingRate = fread(fileID,1,'float32');
header.type = fread(fileID,1,'int8'); % 1 if scalar, 0 if vectorial


%% READ DATA

if nargout > 1
    if header.type == 1
        thedata = fread(fileID,[header.NumSP,header.NumTF],'float32')';
    elseif header.type == 0
        thedata = fread(fileID,[3*header.NumSP,header.NumTF],'float32')'; % Not sure if this will work...
    end
end

fclose(fileID);