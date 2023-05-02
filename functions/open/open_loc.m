function [ElectrodesTable,NumElec] = open_loc(LOC_file)

% Update: 11.2022
% =========================================================================
%
% Opens an EEGLAB polar electrode coordinates file (.loc/.locs)
% https://eeglab.org/tutorials/04_Import/Channel_Locations.html
%
%
% INPUTS
% - full path and name of the LOC/LOCS file to open (with extension)
%
% OUTPUTS
% - 'ElectrodesTable' is a 3-colmun table containing:
%   - the number of each electrode
%   - the degree and radius coordinates of each electrode
%   - the labe of each electrode
% - 'NumElec' is the number of electrodes
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(LOC_file,'file') == 2
    error(['Specified file ' LOC_file ' not found']);
elseif ~(strcmpi(LOC_file(end-3:end),'.loc') || strcmpi(LOC_file(end-4:end),'.locs'))
    error(['Specified file ' LOC_file ' is not an EEGLAB LOC file']);
end

% open file for reading in text mode
fileID = fopen(LOC_file,'rt');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' LOC_file]);
end


%% READ FILE

loc = textscan(fileID,'%s','delimiter','\n');
loc = loc{1};
NumElec = length(loc);

ElectrodesTable = table('Size',[NumElec 4],...
    'VariableTypes',{'double' 'double' 'double' 'string'},...
    'VariableNames',{'Nr','Degree','Radius','Label'});

for elec = 1:NumElec
    ElectrodesTable.nr(elec) = sscanf(loc{elec},'%d',1);
    ElectrodesTable.theta(elec) = sscanf(loc{elec},'%*d %d',1);
    ElectrodesTable.radius(elec) = sscanf(loc{elec},'%*d %*d %f',1);
    ElectrodesTable.label(elec) = string(char(sscanf(loc{elec},'%*d %*d %*f %s',1)'));
end

fclose(fileID);