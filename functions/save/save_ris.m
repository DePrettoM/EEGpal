function save_ris(savefilename,thedata,SamplingRate)

% Update: 05.2019
% =========================================================================
%
% Saves data as a Cartool Results of Inverse Solution data file (.ris)
% Original author of this script: MDP
%
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - full saving path and name (with extension)
% - data as a 2-D numeric array where
%   - dimension 1 contains the timeframes
%   - dimension 2 contains the solution points
% - (optional) sampling rate as 1-D numeric array
%
%
% OUTPUTS
% - .ris file
%
%
% =========================================================================


% define fixed part of header
version = 'RI01';
numsolutionpoints = size(thedata,2);
numtimeframes = size(thedata,1);
if nargin < 3
    SamplingRate = 0;
end

% open savefilename for writing
fileID=fopen(savefilename,'w');

%write fixed part of header
fwrite(fileID,version,'char');
fwrite(fileID,numsolutionpoints,'int32');
fwrite(fileID,numtimeframes,'int32');
fwrite(fileID,SamplingRate,'float32');
fwrite(fileID,1,'char'); % Always saves RIS as scalar (type should be 0 if vectorial)

% write data
fwrite(fileID,thedata','float32');


% close file
fclose(fileID);