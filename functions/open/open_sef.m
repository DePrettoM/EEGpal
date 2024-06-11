function [header,thedata,events] = open_sef(openfilename)

% Update: 06.2024
% =========================================================================
%
% Opens a Cartool simple EEG data file (.sef)
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full path and name of the SEF file to open (with extension)
%
% OUTPUTS
% - 'header' structure including:
%   - 'NumChan' is the total number of channels (incl. auxiliaries)
%   - 'NumTF' is the number of timeframes
%   - 'SamplingRate' is ...the sampling rate!
%   - 'Channels' is a 1D string array with the name of all the channels
% - (optional) 'data' 2D numeric array with
%   - dimension one represents time-frames
%   - dimension two represents the electrodes
% - (optional) 'events' as a 3D cell array
%   - column 1 is a array of numeric onsets for each event
%   - column 2 is a array of numeric offsets for each event
%   - column 2 is a array of numeric or string codes for each event
%
% FUNCTION CALLED (for events)
% - open_mrk
%
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unifr.ch)
% Update by Michael Mouthon is order the events are num array and not a cell
% =========================================================================


%% OPEN FILE

if ~exist(openfilename,'file')
    error(['Specified file ' openfilename ' not found']);
elseif ~strcmpi(openfilename(end-3:end),'.sef')
    error(['Specified file ' openfilename ' is not a SEF file']);
end

% open filename for reading
fileID = fopen(openfilename,'r');
if fileID == -1
    % ferror(fileID);
    error(['fopen cannot open the file ' openfilename]);
end


%% READ

% read fixed part of header
header.version = strcat(fread(fileID,4,'int8=>char')');
header.NumChan = fread(fileID,1,'int32'); % including auxiliary channels
header.NumAuxChan = fread(fileID,1,'int32'); % only auxiliary channels
header.NumTF = fread(fileID,1,'int32');
header.SamplingRate = fread(fileID,1,'float32');
header.year = fread(fileID,1,'int16');
header.month = fread(fileID,1,'int16');
header.day = fread(fileID,1,'int16');
header.hour = fread(fileID,1,'int16');
header.minute = fread(fileID,1,'int16');
header.second = fread(fileID,1,'int16');
header.millisecond = fread(fileID,1,'int16');

% read channels (variable part of header)
header.Channels = strcat(fread(fileID,[8,header.NumChan],'int8=>char')');
% for channel = 1:size(header.Channels,1)
%     character = 1;
%     byte = 1;
%     while byte ~= 0
%         character = character + 1;
%         if character == 8
%             break
%         end
%         byte = native2unicode(header.Channels(channel,character));
%     end
%     header.Channels(channel,character+1:end) = ' ';
% end


%% READ DATA

if nargout > 1
    thedata = fread(fileID,[header.NumChan,header.NumTF],'float32')';
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