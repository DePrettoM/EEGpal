function [header,thedata,events] = open_eph(openfilename)

% Update: 06.2024
% =========================================================================
%
% Opens a Cartool evoked potential data file (.ep(h))
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the EP(H) file to open (with extension)
%
% OUTPUTS
% - 'header' structure containing:
%   - 'NumChan' is the number of channels
%   - 'NumTF' is the number of timeframes
%   - 'SamplingRate' is ...the sampling rate! (only for EPH files)
% - (optional) 'data' 2D numeric array with
%   - dimension one represents time-frames
%   - dimension two represents the electrodes
% - (optional) 'events' as a 3D cell array
%   - column 1 is a array of numeric onsets for each event
%   - column 2 is a array of numeric offsets for each event
%   - column 3 is a array of numeric or string codes for each event
%
% FUNCTION CALLED (for events)
% - open_mrk
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unifr.ch)
% - Update by Michael Mouthon is order the events are num array and not a cell
% - Modification at line 81 in order that the provide the number of TF, number of channel in the
% header. The sampling rate still need to be enter manually after import.
% -25.09.2024
% =========================================================================


%% OPEN FILE

if ~exist(openfilename,'file')
    error(['Specified file ' openfilename ' not found']);
elseif ~(strcmpi(openfilename(end-3:end),'.eph') || strcmpi(openfilename(end-2:end),'.ep'))
    error(['Specified file ' openfilename ' is not an EPH or EP file']);
end

% open file for reading in text mode
fileID = fopen(openfilename,'rt');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' openfilename]);
end


%% EPH

if strcmp(openfilename(end-3:end),'.eph')
    
    % read header
    eph = textscan(fileID,'%f %f %f',1);
    header.NumChan = eph{1};
    header.NumTF = eph{2};
    header.SamplingRate = eph{3};
    
    % read data
    if nargout > 1
        % prepare for reading data
        eph = textscan(fileID,'%s','delimiter','\n');
        eph = eph{1};
        
        formatstring = strings(1,header.NumChan);
        formatstring(1,:) = '%f';
        formatstring = char(strjoin(formatstring,' '));
        
        thedata = zeros(header.NumTF,header.NumChan);
        for i = 1:header.NumTF
            thedata(i,:) = sscanf(eph{i+1},formatstring);
        end
    end


%% EP

elseif strcmp(openfilename(end-2:end),'.ep')
%     if nargout > 1 %modification done by MM the 25.09.2024 because need to have the NumTF at the EEGpal import
        thedata = load(openfilename);
        header.NumTF = size(thedata,1);
        header.NumChan = size(thedata,2);
        header.SamplingRate = 1;
%     else
%         header = 'EP file';
%     end
else
    error('incorrect file type');
end

fclose(fileID);


%% EVENTS (optional)

if nargout > 2
    header.firstindex = 0; % In Cartool, 1st time-frame is 0
    MRK_file = [openfilename '.mrk']; % name of MRK file
    if isfile(MRK_file)
        % OLD VERSION of open_mrk.m
        %[MRKonset,~,MRKname] = open_mrk(MRK_file);
        %events = [MRKonset MRKname];
        events = open_mrk(MRK_file);
        try
            events=cell2mat(events);
        catch
            disp('Marker files contrains text which is not managed.')
        end
    else
        %disp('MRK file not found. Events output created as empty cell array')
        %events = {};
        disp('MRK file not found. Events output created as empty num array')
        events = [];
    end
end