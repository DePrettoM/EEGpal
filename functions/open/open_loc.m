function [ElectrodesTable,nElec] = open_loc(LOC_file)

% Update: 05.2024
% =========================================================================
%
% Opens an EEGLAB polar electrode coordinates file (.loc/.locs)
% https://urldefense.com/v3/__https://eeglab.org/tutorials/04_Import/Channel_Locations.html__;!!Dc8iu7o!2y0xODrAvoJaJ6zUzBQJ02E7hxVwU9WCt602nzZvJDpaKiC7JEClLEDDzpoYQojSIKCrQNyb28Ub5mKHL9khyke9DANfCIsUEEQ$ 
%
%
% INPUTS
% - full path and name of the LOC/LOCS file to open (with extension)
%
% OUTPUTS
% - 'ElectrodesTable' is a 3-colmun table containing:
%   - the number of each electrode
%   - the degree and radius coordinates of each electrode
%   - the label of each electrode
% - 'nElec' is the number of electrodes
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
nElec = length(loc);

ElectrodesTable = table('Size',[nElec 4],...
    'VariableTypes',{'double' 'double' 'double' 'string'},...
    'VariableNames',{'nr','theta','radius','labels'});

for elec = 1:nElec
    ElectrodesTable.nr(elec)        = sscanf(loc{elec},'%d',1);
    ElectrodesTable.theta(elec)     = sscanf(loc{elec},'%*d %d',1);
    ElectrodesTable.radius(elec)    = sscanf(loc{elec},'%*d %*d %f',1);
    ElectrodesTable.labels(elec)    = string(char(sscanf(loc{elec},'%*d %*d %*f %s',1)'));
end

fclose(fileID);