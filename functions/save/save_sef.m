function save_sef(savefilename,thedata,SamplingRate,Channels,events,firstindex,nAux)

% Update: 11.2022
% =========================================================================
%
% Saves data as a Cartool simple EEG data file
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full saving path and name (with extension)
% - data as a 2-D numeric array where
%   - dimension 1 contains the timeframes
%   - dimension 2 contains the channels
% - samplingrate as 1-D numeric array
% - (optional) 'Channels' is a character array with channel labels
% - (optional) 'events' is a 2D or 3D array
%   - onsets of each event are in column 1 (used as offset for a 2D array)
%   - offsets of each event are in column 2 of a 3D array
%   - the code of each event are in the last column
%   /!\ IMPORTANT: The time-frames must be set according to a first index
%   position of 0, as in Cartool.
% - (optional) 'nAux' is the number of auxiliary channels
% - (optional) 'firstindex' is the position index of the first time-frame
%   (0 or 1). Because Cartool counts time-frames starting from 0, if the
%   first index is 1, 1 will be removed from each event values. Any other
%   value will be refused, because it doesn't make any sense!
%   Default: empty
%
% OUTPUTS
% - .sef file
% - .mrk file if 'events' as an input
%
% FUNCTION CALLED (for events)
% - create_mrk
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% Check inputs

if nargin > 4
    if ~isempty(firstindex) && (firstindex ~= 0 && firstindex ~= 1)
        error(['This input argument must be either empty (default), 0, or 1. First index value entered: ' num2str(firstindex)]);
    end
else
    firstindex = [];
end


%% Header

% define fixed part of header
version = 'SE01';
numchannels = size(thedata,2);
if nargin == 7 && isnumeric(nAux)
    numauxchannels = nAux;
elseif nargin == 7 && isempty(nAux)
    numauxchannels = 0;
elseif nargin == 7
    disp('Number of auxiliary channels not understood, set to 0.')
    numauxchannels = 0;
else
    numauxchannels = 0;
end
numtimeframes = size(thedata,1);
year = 0;
month = 0;
day = 0;
hour = 0;
minute = 0;
second = 0;
millisecond = 0;

% open savefilename for writing
fileID = fopen(savefilename,'w');

%write fixed part of header
fwrite(fileID,version,'int8');
fwrite(fileID,numchannels,'int32');
fwrite(fileID,numauxchannels,'int32');
fwrite(fileID,numtimeframes,'int32');
fwrite(fileID,SamplingRate,'float32');
fwrite(fileID,year,'int16');
fwrite(fileID,month,'int16');
fwrite(fileID,day,'int16');
fwrite(fileID,hour,'int16');
fwrite(fileID,minute,'int16');
fwrite(fileID,second,'int16');
fwrite(fileID,millisecond,'int16');

% define and write variable part of header
if nargin > 3 && ~isempty(Channels)
    if isstring(Channels)
        Channels = char(Channels);
    end
    
    for channel = 1:numchannels
        Label = int8(zeros(8,1));
        Label(1:length(Channels(channel,:))) = unicode2native(Channels(channel,:));
        fwrite(fileID,Label,'int8');
    end
else
    for i = 1:numchannels
        fwrite(fileID,101,'int8'); % letter 'e'
        currentchannel=uint8(num2str(i)); % numbering electrodes
        for j=1:size(currentchannel,2)
            fwrite(fileID,currentchannel(j),'int8');
        end
        for k=j+2:8
            fwrite(fileID,0,'int8');
        end
    end
end


%% Write data
fwrite(fileID,thedata','float32');

% close file
fclose(fileID);


%% Create MRK file
if nargin > 4 && ~isempty(events)
    MRK_file = savefilename; % name of MRK file
    create_mrk(MRK_file,events,firstindex)
end