function [header,thedata,events] = open_eeglab_struct(EEG)

% Update: 06.2025
% =========================================================================
%
% Convert EEGlab struct into variable compatible for EEGpal 
%
%
% INPUTS
% - EEG data struct
%
% OUTPUTS
% - 'header' structure including:
%   - 'NumChan' is the total number of channels
%   - 'Channels' is a character array with the name of the channels
%   - 'NumTF' is the number of timeframes
%   - 'SamplingRate' is ...the sampling rate!
%   - 'Channels' is a 1D string array with the name of all the channels
% - (optional) 'data' 2D numeric array with
%   - dimension one represents time-frames
%   - dimension two represents the electrodes
% - (optional) 'events' structure including:
%   - 'latency' is the onset (and offset) of each event
%   - 'type' is the code of each event
%   - ('epoch' counts the epochs)
%
%
% Author: Michaël Mouthon (michael.mouthon@unifr.ch)
% adapted from open_eeglab function of Michael DePretto
%
% =========================================================================


%% EEG struct (HEADER)

% read header
header.NumChan = EEG.nbchan;
%Channels = strings(NumChan,1);
for channel = 1:header.NumChan
    header.Channels(channel,1:length(EEG.chanlocs(channel).labels)-1) = EEG.chanlocs(channel).labels(2:end);
end
header.NumTF = EEG.pnts; % Is the epoch size...
header.SamplingRate = EEG.srate;
header.firstindex = 1; % indices of values a counted starting from 1 (not from 0 as in Cartool for example)


%% (DATA)

if nargout > 1
    thedata = EEG.data';
end


%% EVENTS
events=[]; %No event export !!
[NbEvents,~]=size(EEG.event); %number of Event
if nargout > 2 && ~isempty(EEG.event)
    if isfield(EEG.event,'duration')
        header.firstindex = 1; % In EEGlab, 1st time-frame is 1
        events=zeros(NbEvents,3);
        if ischar(EEG.event(1).type) %test if the event are text
            errordlg('Unfortunately, this function can not handle text in the event', 'text in event')
            return
        end
        for k=1:NbEvents
            events(k,1)=EEG.event(k).latency;
            events(k,2)=EEG.event(k).latency+EEG.event(k).duration;
            events(k,3)=EEG.event(k).type;
        end
    else
        [~,NbEvents]=size(EEG.event); 
        header.firstindex = 1; % In EEGlab, 1st time-frame is 1
        events=zeros(NbEvents,3);
        if ischar(EEG.event(1).edftype) %test if the event are text
            errordlg('Unfortunately, this function can not handle text in the event', 'text in event')
            return
        end
        for k=1:NbEvents
            events(k,1)=EEG.event(k).latency;
            events(k,2)=EEG.event(k).latency;
            events(k,3)=EEG.event(k).edftype;
        end
        disp('This .set file has been saved with EEGlab. The event duration is missing. The duration of each event are set to one Time Frame');
    end

elseif isempty(EEG.event)
    disp('The file contains no events.')
    events = [];
end