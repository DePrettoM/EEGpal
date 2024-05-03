function save_eph(savefilename,thedata,samplingrate,events,firstindex)

% Update: 11.2022
% =========================================================================
%
% Saves data as a Cartool evoked potential data file (.ep(h/sd/se))
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by MDP
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full saving path and name (with extension)
% - data as a 2-D numeric array where
%   - dimension 1 contains the timeframes
%   - dimension 2 contains the channels
% - samplingrate as 1-D numeric array (mandatory only for EPH files)
% - (optional) 'events' is a 2D or 3D array
%   - onsets of each event are in column 1 (used as offset for a 2D array)
%   - offsets of each event are in column 2 of a 3D array
%   - the code of each event are in the last column
%   /!\ IMPORTANT: The time-frames must be set according to a first index
%   position of 0, as in Cartool.
% - (optional) 'firstindex' is the position index of the first time-frame
%   (0 or 1). Because Cartool counts time-frames starting from 0, if the
%   first index is 1, 1 will be removed from each event values. Any other
%   value will be refused, because it doesn't make any sense!
%   Default: empty
%
% OUTPUTS
% - .ep(h/sd/se) file
% - .mrk file if 'events' as an input
%
% FUNCTION CALLED (for events)
% - create_mrk
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


%% SAVE EPH
if strcmp(savefilename(end-3:end),'.eph') == 1
    numtimeframes = size(thedata,1);
    numchannels = size(thedata,2);
    if ~exist('samplingrate','var') || isempty(samplingrate)
        samplingrate = 1;
    end
    theheader = [numchannels numtimeframes samplingrate];
    try % writematrix introduced in Matlab R2019a, 'WriteMode' introduced in R2020
        writematrix(theheader,[savefilename '.txt'],'Delimiter','tab');
        writematrix(thedata,[savefilename '.txt'],'Delimiter','tab','WriteMode','append');
        movefile([savefilename '.txt'],savefilename)
    catch % dlmwrite not recommended, for compatibility only
        dlmwrite(savefilename,theheader,'delimiter','\t','precision','%d');
        dlmwrite(savefilename,thedata,'delimiter','\t','-append');
    end
    
    
%% SAVE EP
elseif strcmp(savefilename(end-2:end),'.ep') == 1
    try % writematrix introduced in Matlab R2019a
        writematrix(thedata,[savefilename '.txt'],'Delimiter','tab');
        movefile([savefilename '.txt'],savefilename)
    catch % dlmwrite not recommended, for compatibility only
        dlmwrite(savefilename,thedata,'delimiter','\t','-append');
    end
    
    
%% SAVE EPSD/EPSE
elseif strcmp(savefilename(end-4:end),'.epsd') == 1 || strcmp(savefilename(end-4:end),'.epse') == 1
    if nargin == 2
        dlmwrite(savefilename,thedata,'delimiter','\t','-append');
    elseif nargin == 3
        numtimeframes = size(thedata,1);
        numchannels = size(thedata,2);
        if ~exist(samplingrate,'var') || isempty(samplingrate)
            samplingrate = 1;
        end
        theheader = [numchannels numtimeframes samplingrate];
        dlmwrite(savefilename,theheader,'delimiter','\t','precision','%d');
        dlmwrite(savefilename,thedata,'delimiter','\t','-append');
    end
end


%% CREATE MRK FILE
if nargin > 3 && ~isempty(events)
    MRK_file = [savefilename '.mrk']; % name of MRK file
    create_mrk(MRK_file,events,firstindex)
end