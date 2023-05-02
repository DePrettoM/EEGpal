function MRKevents = open_mrk(MRK_file)
% OLD: function [MRKonset,MRKoffset,MRKname] = open_mrk(MRK_file)

% Update: 03.2021
% =========================================================================
%
% Opens a Cartool markers file ('.mrk')
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - MRK file name
%
% OUTPUTS
% - 'MRKevents' as a 3D cell array
%   - column 1 is a cell array of numeric onsets for each event
%   - column 2 is a cell array of numeric offsets for each event
%   - column 3 is a cell array of numeric or string codes for each event
% OLD:
% - 'MRKonset' is a 1D numeric array with onset value for each marker in
%   time-frames.
% - 'MRKoffset' is a 1D numeric array with offset value for each marker in
%   time-frames.
% - 'MRKname' is a 1D numeric array with coding value for each marker.
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(MRK_file,'file')
    error(['Specified file ' MRK_file ' not found']);
elseif ~strcmpi(MRK_file(end-3:end),'.mrk')
    error(['Specified file ' MRK_file ' is not a MRK file']);
end

% open file for reading in text mode
fileID = fopen(MRK_file,'rt');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' MRK_file]);
end


%% READ FILE

mrk = textscan(fileID,'%s','delimiter','\n');
mrk = mrk{1};
header = mrk{1};
pointer = 2;

MRKonset = cell(length(mrk)-1,1); % '-1' because of header line
MRKoffset = cell(length(mrk)-1,1);
MRKname = cell(length(mrk)-1,1);

for i=1:length(mrk)-1
    MRKonset(i,1) = {sscanf(mrk{pointer},'%d',1)};
    MRKoffset(i,1) = {sscanf(mrk{pointer},'%*d %d',1)};
    if ~isempty(sscanf(mrk{pointer},'%*d %*d %d',1))
        MRKname(i,1) = {sscanf(mrk{pointer},'%*d %*d %d',1)};
    else
        MRKstring = strcat((sscanf(mrk{pointer},'%*d %*d %s',1))');
        MRKname(i,1) = {string(erase(MRKstring,'"'))};
        %MRKname(i,1) = {strcat((sscanf(mrk{pointer},'%*d %*d %s',1))')};
    end
    pointer = pointer + 1;
end
MRKevents = [MRKonset,MRKoffset,MRKname];

fclose(fileID);