function [header,thedata,events] = open_eeglab(SETfilename)

% Update: 04.2026
% =========================================================================
%
% Opens an EEGlab data file (.set/.fdt)
%
%
% INPUTS
% - full path and name of the SET file to open (with extension)
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
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% Update by Michaël Mouthon:
% - open when all data are record in the .set file without .fdt file
% (27.04.2026)
% - Manage if the event are record in text (e.g. convert '131' into 131 and
% ignore all type which is only text like 'border') (03.05.2026)
% - Add floor function to take account when latency or duration contains a
% decimal number (03.05.2026)
%
%
% =========================================================================


%% SET FILE (HEADER)

if ~exist(SETfilename,'file')
    error(['Specified file ' SETfilename ' not found']);
elseif ~strcmpi(SETfilename(end-3:end),'.set')
    error(['Specified file ' SETfilename ' is not a SET file']);
end

% load SET file
SETfile = load('-mat',SETfilename);
if isfield(SETfile,'EEG') % in some cases, there might be a "subfield"...
    SETfile = SETfile.EEG;
end


% read header
header.NumChan = SETfile.nbchan;
%Channels = strings(NumChan,1);
if ~isempty(SETfile.chanlocs) 
    for channel = 1:header.NumChan
        header.Channels(channel,1:length(SETfile.chanlocs(channel).labels)) = SETfile.chanlocs(channel).labels;
        %Channels = char(Channels); % format adapted to Cartool SEF files (maybe not necessary)
    end
end
header.NumTF = SETfile.pnts; % Is the epoch size...
header.SamplingRate = SETfile.srate;
header.firstindex = 1; % indices of values a counted starting from 1 (not from 0 as in Cartool for example)


%% FDT FILE (DATA)

if nargout > 1
    
    FDTfilename = strcat(SETfilename(1:end-3),'fdt');
    
    if ~exist(FDTfilename,'file')
        %case where there is no fdt file and data are in the set file.
        thedata=SETfile.data';
    else
        %case where there is a fdt file which contains the data
        FDT_fileID = fopen(FDTfilename);
        if FDT_fileID == -1
            % ferror(fileID);
            error(['fopen cannot open the file ' FDTfilename]);
        end
    
        thedata = fread(FDT_fileID,[header.NumChan,Inf],'float32','ieee-le');
        thedata = thedata';
        % NumTF = length(thedata);
    
        fclose(FDT_fileID);
    end
end
%header.NumTF = length(thedata);


%% EVENTS
events=[]; %No event export !!
[NbEvents,~]=size(SETfile.event); %number of Event

if nargout > 2 && ~isempty(SETfile.event)
    header.firstindex = 1; % In EEGlab, 1st time-frame is 1
    
    if isfield(SETfile.event,'duration')
        if NbEvents == 1
            [~,NbEvents]=size(SETfile.event); %other organization of event struct (added the 03.05.2026)
        end        
        
        if ischar(SETfile.event(1).type) %test if the event are text
            indice=0;
            for k=1:NbEvents
                if ~isempty(str2num(SETfile.event(k).type)) %remove any trigger which are not numerical
                    indice=indice+1;
                    events(indice,1)=floor(SETfile.event(k).latency);                    
                    events(indice,2)=floor(SETfile.event(k).latency+SETfile.event(k).duration);        
                    events(indice,3)=str2num(SETfile.event(k).type); %convert string number into number
                end
            end
            % errordlg('Unfortunately, this function can not handle text in the event', 'text in event')
            % return
        else % case where event are number
            for k=1:NbEvents
                events(k,1)=floor(SETfile.event(k).latency);                
                events(k,2)=floor(SETfile.event(k).latency+SETfile.event(k).duration);                
                events(k,3)=SETfile.event(k).type;
            end
        end
    elseif isfield(SETfile.event,'type') & ~isfield(SETfile.event,'duration')
        NbEvents=size(SETfile.event,2); %number of Event
        
        if ischar(SETfile.event(1).type) %test if the event are text
            indice=0;
            for k=1:NbEvents
                if ~isempty(str2num(SETfile.event(k).type)) %remove any trigger which are not numerical
                    indice=indice+1;
                    events(indice,1)=floor(SETfile.event(k).latency);
                    events(indice,2)=floor(SETfile.event(k).latency);
                    events(indice,3)=str2num(SETfile.event(k).type); %convert string number into number
                end
            end
            % errordlg('Unfortunately, this function can not handle text in the event', 'text in event')
            % return
        else        
            for k=1:NbEvents
                events(k,1)=floor(SETfile.event(k).latency);
                events(k,2)=floor(SETfile.event(k).latency);
                events(k,3)=SETfile.event(k).type;
            end
        end
    elseif isfield(SETfile.event,'edftype')
        [~,NbEvents]=size(SETfile.event); 
        if ischar(SETfile.event(1).edftype) %test if the event are text
            indice=0;
            for k=1:NbEvents
                if ~isempty(str2num(SETfile.event(k).edftype)) %remove any trigger which are not numerical
                    indice=indice+1;
                    events(indice,1)=floor(SETfile.event(k).latency);
                    events(indice,2)=floor(SETfile.event(k).latency);
                    events(indice,3)=str2num(SETfile.event(k).edftype); %convert string number into number
                end
            end
            % errordlg('Unfortunately, this function can not handle text in the event', 'text in event')
            % return
        else
            for k=1:NbEvents
                events(k,1)=floor(SETfile.event(k).latency);
                events(k,2)=floor(SETfile.event(k).latency);
                events(k,3)=SETfile.event(k).edftype;
            end
        end
        disp('This .set file has been saved with EEGlab. The event duration is missing. The duration of each event are set to one Time Frame');
    end

elseif isempty(SETfile.event)
    disp('The file contains no events.')
    events = [];
end

