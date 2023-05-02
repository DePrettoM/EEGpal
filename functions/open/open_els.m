function [Electrodes,NumElec,ELSclusters] = open_els(ELS_file)

% Update: 02.2021
% =========================================================================
%
% Opens a Cartool electrode coordinates file (.els)
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the ELS file to open (with extension)
%
% OUTPUTS
% - 'Electrodes' is a 1D string array containing the name of all
%   electrodes of all clusters
% - 'NumElec' is the number of electrodes
% - 'ELSclusters' is a structure containing
%   - the name of each cluster
%   - the number of electrode of each cluster
%   - the type of each cluster
%   - an 'electrodes' structure with the name and coordinates of the
%     electrodes of the cluster
%
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(ELS_file,'file')
    error(['Specified file ' ELS_file ' not found']);
elseif ~strcmpi(ELS_file(end-3:end),'.els')
    error(['Specified file ' ELS_file ' is not an ELS file']);
end

% open file for reading in text mode
fileID = fopen(ELS_file,'rt');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' ELS_file]);
end


%% READ FILE

els = textscan(fileID,'%s','delimiter','\n');
els = els{1};
magicnumber = els{1};
NumElec = str2double(els{2});
numclusters = str2double(els{3});
pointer = 4;

% prepare for reading data
ELSclusters = struct('name',strings(numclusters,1),'numelectrodes',zeros(numclusters,1),'type',zeros(numclusters,1),'electrodes',struct('labels',strings,'x',0,'y',0,'z',0));
Electrodes = strings(NumElec,1);
elec = 1;

for i=1:numclusters
    ELSclusters(i).name = els{pointer};
    ELSclusters(i).numelectrodes = str2double(els{pointer+1});
    ELSclusters(i).type = str2double(els{pointer+2});
    pointer = pointer+3;
    for j = 1:ELSclusters(i).numelectrodes
        ELSclusters(i).electrodes(j).labels = char(sscanf(els{pointer},'%*f %*f %*f %s',1)');
        ELSclusters(i).electrodes(j).x = sscanf(els{pointer},'%f',1);
        ELSclusters(i).electrodes(j).y = sscanf(els{pointer},'%*f %f',1);
        ELSclusters(i).electrodes(j).z = sscanf(els{pointer},'%*f %*f %f',1);
        pointer = pointer+1;
        Electrodes(elec,1) = convertCharsToStrings(ELSclusters(i).electrodes(j).labels);
        elec = elec + 1;
    end
end

fclose(fileID);