function [NewRefData,AuxData] = ref_change(thedata,ref,aux)

% Update: 02.2021
% =========================================================================
%
% Changes the reference of a data set
%
%
% INPUTS
% - Data as a 2-D numeric array where
%   - Dimension 1 contains the timeframes
%   - Dimension 2 contains the channels
% - Reference as either
%   - 'avg' or 'avgref' string for average reference
%   - A number corresponding to the index of the new reference electrode
%     If the size is bigger than 1 (e.g., [x y]), the reference will
%     be the average of all these channels.
% - (optional) 'aux' or 'ext' string specifying if the new reference is an
%   auxiliary electrode (e.g., earlobes). In such case, the data from this
%   channel will be removed from the output data.
%
% OUTPUTS
% - New referenced data as a 2-D numeric array where 
%   - Dimension 1 contains the timeframes
%   - Dimension 2 contains the channels
% - Data from auxiliary channels as a 2-D numeric array where 
%   - Dimension 1 contains the timeframes
%   - Dimension 2 contains the channels
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


% Read the data
nChan = size(thedata,2); % Number of channels


%% Compute data against selected reference

% Average Reference
if ischar(ref) && (strcmpi(ref,'avg') || strcmpi(ref,'avgref'))
    refdata = mean(thedata,2);
    
% Unknown string or char
elseif ischar(ref)
    error(cell2mat(strcat('Unknown input code for referemce:',{' '},ref)))
    
% Scalp electrode reference
elseif isnumeric(ref) && (min(ref) >= 1 && max(ref) <= nChan)
    refdata = mean(thedata(:,ref),2);

% Reference not identified
elseif isnumeric(ref) && (min(ref) <1 || max(ref) > nChan)
    error('Reference index beyond data range.');
else
    error('Unsupported type of input. Must be a string or a numeric value.');
end

% Isolate auxiliary channels
if nargin == 3 && (strcmpi(aux,'aux') || strcmpi(aux,'ext'))
    AuxData = thedata(:,aux);
    thedata(:,aux) = [];
elseif nargout == 2
    AuxData = [];
end

% Compute data against new reference
NewRefData = thedata - refdata;