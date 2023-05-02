function [ElectrodesTable,NumElec] = open_xyz(XYZ_file)

% Update: 02.2021
% =========================================================================
%
% Opens a Cartesian electrode coordinates file (.xyz)
% Either Matlab or Cartool files
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the XYZ file to open (with extension)
%
% OUTPUTS
% - 'ElectrodesTable' is a 5-colmun table containing:
%   - the number of each electrode
%   - the x, y, and z coordinates of each electrode
%   - the labe of each electrode
% - 'NumElec' is the number of electrodes
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% OPEN FILE

if ~exist(XYZ_file,'file')
    error(['Specified file ' XYZ_file ' not found']);
elseif ~strcmpi(XYZ_file(end-3:end),'.xyz')
    error(['Specified file ' XYZ_file ' is not an XYZ file']);
end

% open file for reading in text mode
fileID = fopen(XYZ_file,'rt');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' XYZ_file]);
end


%% READ FILE

xyz = textscan(fileID,'%s','delimiter','\n');
xyz = xyz{1};

if isempty(sscanf(xyz{1},'%*f %*f %f',1))
    disp('Cartool XYZ file detected')
    NumElec = sscanf(xyz{1},'%d',1);
    %Radius = sscanf(xyz{1},'%*d %f',1);
    pointer = 2;
else
    disp('Matlab XYZ file detected')
    NumElec = length(xyz);
    pointer = 1;
end

ElectrodesTable = table('Size',[NumElec 5],...
    'VariableTypes',{'double' 'double' 'double' 'double' 'string'},...
    'VariableNames',{'nr','x','y','z','labels'});

for elec = 1:NumElec
    ElectrodesTable.nr(elec) = elec;
    ElectrodesTable.x(elec) = sscanf(xyz{pointer},'%f',1);
    ElectrodesTable.y(elec) = sscanf(xyz{pointer},'%*f %f',1);
    ElectrodesTable.z(elec) = sscanf(xyz{pointer},'%*f %*f %f',1);
    ElectrodesTable.labels(elec) = string(char(sscanf(xyz{pointer},'%*f %*f %*f %s',1)'));
    pointer = pointer + 1;
end

fclose(fileID);