function save_freq(savefilename,thedata,SamplingRate,Resolution,FrequencyName,Channels)

% Update: 04.2020
% =========================================================================
%
% Saves data as a Cartool frequency data file
% Author of this script: MDP
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full saving path and name (with extension)
% - data as a 3-D numeric array where
%   - dimension 1 contains the frequencies
%   - dimension 2 contains the channels
%   - dimension 3 contains the timeframes
% - SamplingRate as 1-D numeric array
% - Resolution as 1-D numeric array
% - (optional) 'FrequencyName' is a character array with frequency labels
%   If 'FrequencyName' = 'compute', the script will create the names from
%   SamplingRate and Resolution
% - (optional) 'Channels' is a character array with channel labels
%
%
% OUTPUTS
% - .freq file
%
%
% FROM CARTOOL HELP
%
% // some strings size
% #define   NumFreqTypes            6
% #define   MaxCharFreqType         32
% #define   MaxCharFrequencyName	16
%
% // type of content in the file, coded as text
% char    FreqTypesNames[ NumFreqTypes ][ MaxCharFreqType ] = {
%   "Unknown",
%   "FFT Norm",
%   "FFT Norm2",
%   "FFT Complex",
%   "FFT Approximation",
%   "S Transform"    };
%
% =========================================================================


%% Define fixed part of header
Version = 'FR02';                   % 'FR01' (obsolete) or 'FR02'
Type = 'Unknown                         ';  % of the analysis, and also data stored
%Type = 'FFT Norm2                       ';  % of the analysis, and also data stored
%Type = 'FFT Approximation               ';  % of the analysis, and also data stored
%Type = 'S Transform                     ';  % of the analysis, and also data stored
NumChannels = size(thedata,2);      % total number of electrodes
NumFrequencies = size(thedata,1);   % saved in file
NumBlocks = size(thedata,3);        % of repeated analysis, or number of resulting "time frames"
year = 0;                           % Date of the recording
month = 0;                          % (can be 00-00-0000 if unknown)
day = 0;
hour = 0;                           % Time of the recording
minute = 0;                         % (can be 00:00:00:0000 if unknown)
second = 0;
millisecond = 0;

% Open savefilename for writing
fileID = fopen(savefilename,'w');

% write fixed part of header
fwrite(fileID,Version,'int8');
fwrite(fileID,Type,'int8'); % 'char' ???
fwrite(fileID,NumChannels,'int32');
fwrite(fileID,NumFrequencies,'int32');
fwrite(fileID,NumBlocks,'int32');
fwrite(fileID,SamplingRate,'double');
fwrite(fileID,Resolution,'double');  % BlockFrequency; // frequency of blocks'occurences (if 1 block is 0.5 s long amd don't overlap -> 2 Hz)
fwrite(fileID,year,'int16');
fwrite(fileID,month,'int16');
fwrite(fileID,day,'int16');
fwrite(fileID,hour,'int16');
fwrite(fileID,minute,'int16');
fwrite(fileID,second,'int16');
fwrite(fileID,millisecond,'int16');


%% Define and write variable part of header

% Channel names
if nargin > 5 && ~isempty(Channels)
    for channel = 1:NumChannels
        ChanLabel = int8(zeros(8,1));
        ChanLabel(1:length(Channels(channel,:))) = unicode2native(Channels(channel,:));
        fwrite(fileID,ChanLabel,'int8');
    end
else
    for i = 1:NumChannels
        fwrite(fileID,101,'int8'); % letter 'e'
        CurrentChannel = uint8(num2str(i)); % numbering electrodes
        for j = 1:size(CurrentChannel,2)
            fwrite(fileID,CurrentChannel(j),'int8');
        end
        for k = j + 2:8
            fwrite(fileID,0,'int8');
        end
    end
end

% Frequency names
if nargin > 4 && ~isempty(FrequencyName)
    if strcmpi(string(FrequencyName),'compute')
        FreqBins        = (0:Resolution:SamplingRate/2)';
        FrequencyName   = strcat(num2str(FreqBins,'%.2f'),repmat('Hz',height(FreqBins),1));
    end
    for frequency = 1:NumFrequencies
        FreqLabel = int8(zeros(16,1));
        FreqLabel(1:length(FrequencyName(frequency,:))) = unicode2native(FrequencyName(frequency,:));
        fwrite(fileID,FreqLabel,'int8');
    end
else
    for i = 1:NumFrequencies
        fwrite(fileID,102,'int8'); % letter 'f'
        CurrentFrequency = uint8(num2str(i)); % numbering frequencies
        for j = 1:size(CurrentFrequency,2)
            fwrite(fileID,CurrentFrequency(j),'int8');
        end
        for k = j + 2:16
            fwrite(fileID,0,'int8');
        end
    end
end


%% write data
fwrite(fileID,thedata,'float32');

fclose(fileID);