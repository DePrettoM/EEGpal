function create_mrk(savefilename,events,firstindex)

% Update: 10.2022
% =========================================================================
%
% Creates a Cartool markers file ('.mrk')
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
%
% INPUTS
% - full saving path and name (without extension)
% - 'events' is a 2D or 3D array
%   - onsets of each event are in column 1 (used as offset for a 2D array)
%   - offsets of each event are in column 2 of a 3D array
%   - the code of each event are in the last column
% - (optional) 'firstindex' is the position index of the first time-frame
%   (0 or 1). Because Cartool counts time-frames starting from 0, if the
%   first index is 1, 1 will be removed from each event values. Any other
%   value will be refused, because it doesn't make any sense!
%   Default: 0
%
% OUTPUTS
% - .mrk file
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% Check inputs

if nargin == 3
    if ~isempty(firstindex) && (firstindex ~= 0 && firstindex ~= 1)
        error(['This input argument must be either empty, 0 (default), or 1. First index value entered: ' num2str(firstindex)]);
    end
    if isempty(firstindex)
        firstindex = 0; % if firstindex not definded, do not correct
    end
else
    firstindex = 0; % if firstindex not definded, do not correct
end

if size(events,2) ~= 2 && size(events,2) ~= 3
    error(['The ''events'' input must contain 2 or 3 columns: onsets, (offsets), trigger code. Size of input: ' num2str(size(events,2))]);
end

if size(events,2) == 2
    events(:,3) = events(:,2); % Put codes in 3rd column
    events(:,2) = events(:,1); % Copy onset column as offsets (time-point events)
end

% Check format and convert to string
if isnumeric(events)
    events(:,1:2) = events(:,1:2) - firstindex; % In Cartool, 1st time-frame is 0
    events = string(events);
elseif iscell(events)
    try
        events = string(events);
        events(:,1:2) = string(str2double(events(:,1:2)) - firstindex); % In Cartool, 1st time-frame is 0
    catch
        error('Format of input data unsupported. Events array must be either numeric, or cell of numeric, string or char arrays.');
    end
%     if (isnumeric(cell2mat(events(:,1))) || isstring(cell2mat(events(:,1))) || ischar(cell2mat(events(:,1)))) &&...
%             (isnumeric(cell2mat(events(:,2))) || isstring(cell2mat(events(:,2))) || ischar(cell2mat(events(:,2)))) &&...
%             (isnumeric(cell2mat(events(:,3))) || isstring(cell2mat(events(:,3))) || ischar(cell2mat(events(:,3))))
%         events = string(events);
%         events(:,1:2) = string(str2double(events(:,1:2)) - firstindex); % In Cartool, 1st time-frame is 0
%     else
%         error('Format of input data unsupported. Events array must be either numeric, string, or cell of numeric or string arrays.');
%     end
elseif ~isstring(events)
    error('Format of input data unsupported. Events array must be either numeric, or cell of numeric, string or char arrays.');
end

% Saving name
[~,~,ext] = fileparts(savefilename); 
if strcmpi(ext,'.mrk')
    MRKfilename = savefilename;
else
    MRKfilename = char(strcat(savefilename,'.mrk'));
end


%% create MRK file if event variable defined

% save data
disp(['writing marker file for ' savefilename]);
MRKfid = fopen(MRKfilename,'w');
fprintf(MRKfid,'%s\r\n','TL02'); % use \r\n for notepad (not notepad++)
fprintf(MRKfid,'%s\t%s\t%s\r\n',events'); % use \r\n for notepad (not notepad++)
fclose(MRKfid);