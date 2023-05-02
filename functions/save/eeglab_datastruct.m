function EEG = eeglab_datastruct(filename,thedata,SamplingRate,events,channels)

% Update: 05.2019
% =========================================================================
%
% Saves data as EEGlab files (.set/.fdt)
%
% Designed for quick conversion of EEG data into EEGlab format in order to
% use a specific EEGlab module. It creates a minimaliste header that should
% work for most modules. If not, or for more complete use of EEGlab, juste
% use EEGlab from the start!
%
% EEGlab: https://eeglab.org/
%
%
% INPUTS
% - full saving path and name (with '.set' extension)
% - data as a 2-D numeric array where
%   - dimension 1 contains the timeframes
%   - dimension 2 contains the channels
% - samplingrate as 1-D numeric array
%   If unknown, enter 1
% - (optional) 'events' is a 2D numeric array where
%   - column 1 contains the onset of each event in units of data sample
%     points.
%     /!\ EEGlab counts samples from 1. If the original data are base on
%         time points starting at 0 (like Cartool), add +1 in the input
%   - column 2 contains the code of each event
%   If no events, enter []
% - (optional) 'channels' can be either
%   - the path and filename of an EEGlab chanlocs file
%   - an EEGlab chanlocs structure
%   - a cell array with channel labels
%   If unknown and you need the subsequent inputs, enter []
%   Best is to convert without the channels and import the channel info
%   from a .locs file in EEGlab:
%   Edit -> Dataset Info -> Channel location file or info -> Browse
%
% ===
% - (optional) Reference: either inform on reference or ask to compute
%   - 'avgref': average reference (only for pre-processed data!)
%   - 'Cz'/48 or other name/number of electrode
%   - 'computeAVG', 'computeCz', 'compute48', or other ther name/number of
%     electrode to ask for a new reference
%
%
% OUTPUTS
% - EEGlab data structures
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================



%% Prepare information
iDOT = strfind(filename,'.');
SETfilename = strcat(filename(1:iDOT(end)),'set');
iBS = strfind(SETfilename,'\');
tUnit = 1000/SamplingRate; % time unit in seconds
% if contains(Reference,'compute') % CHECK WHAT HAPPENS IF REFERENCE IS A DOUBLE
%     Reference = Reference(8:end); % remove 'compute' %%% USE str2double IF A NUMBER (CHECK HOW)
%     thedata = ref_change(thedata,ref);
% end


%% HEADER
% https://github.com/sccn/eeglab/blob/develop/functions/adminfunc/eeg_checkset.m

%% Basic dataset information:
EEG.setname = 'imported_EEG';          % descriptive name|title for the dataset
EEG.filename = SETfilename(iBS(end)+1:end); % filename of the dataset file on disk
EEG.filepath = SETfilename(1:iBS(end)-1);   % filepath (directory/folder) of the dataset file(s)
EEG.trials = 1;                             % number of epochs (or trials) in the dataset (1 = continuous data)
EEG.pnts = size(thedata,1);                 % number of time points (or data frames) per trial/epoch (total number of time points for continuous data)
EEG.nbchan = size(thedata,2);               % number of channels
EEG.srate = SamplingRate;                   % data sampling rate (in Hz)
EEG.xmin = 0;                               % epoch start latency|time (in sec. relative to the time-locking event at time 0)
EEG.xmax = ((EEG.pnts - 1) ./ EEG.srate);   % epoch end latency|time (in seconds) so that number of frames = (xmax-xmin)*srate+1
EEG.times = 0:tUnit:(EEG.pnts-1)*tUnit;     % vector of latencies|times in miliseconds (one per time point)
EEG.ref = 'common';                         % ['common'|'averef'|integer] reference channel type or number
EEG.history = '';                           % cell array of ascii pop-window commands that created
                                            % or modified the dataset
EEG.comments = 'file created using the save_eeglab.m sciprt by Michael De Pretto';
                                            % comments about the nature of the dataset
                                            % (edit this via menu selection Edit > About this dataset)
% EEG.etc           - miscellaneous (technical or temporary) dataset information
    EEG.etc.eeglabvers = '14.1.2';          % this script is based mainly on eeglab 14.1.2b data structure
EEG.saved = 'no';                           % ['yes'|'no'] 'no' flags need to save dataset changes before exit


%% The data:
EEG.data = thedata';        % two-dimensional continuous data array (chans, frames)
                            % ELSE, three-dim. epoched data array (chans, frames, epochs)


%% The channel locations sub-structures:
if nargin < 5
    EEG.chanlocs = [];  % structure array containing names and locations
                        % of the channels on the scalp
elseif (isstring(channels) || ischar(channels)) && isfile(channels)
    CHAN_fileID = fopen(channels,'r'); % open FDTfilename for writing
    chanlocs = textscan(CHAN_fileID,'%d%f%f%s','delimiter','\n');
    indices = (chanlocs{1})';
    chan_theta = num2cell(chanlocs{2})';
    chan_radius = num2cell(chanlocs{3})';
    chan_labels = chanlocs{4}';
    chan_sph_theta = num2cell(-[chan_theta{:}]);
    chan_sph_phi = num2cell((0.5 - [chan_radius{:}]) * 180);
    chan_sph_radius(1:length(indices)) = {[]};
    [chan_X,chan_Y,chan_Z] = sph2cart([chan_sph_theta{indices}]' / 180 * pi,...
        [chan_sph_phi{indices}]' / 180 * pi,1);
    chan_X = num2cell(chan_X)';
    chan_Y = num2cell(chan_Y)';
    chan_Z = num2cell(chan_Z)';
    chan_ref(1:length(indices)) = {''};
    chan_type(1:length(indices)) = {''};
    chan_urchan(1:length(indices)) = {''};
    EEG.chanlocs = struct('theta',chan_theta,'radius',chan_radius,'labels',chan_labels,...
        'sph_theta',chan_sph_theta,'sph_phi',chan_sph_phi,...
        'X',chan_X,'Y',chan_Y,'Z',chan_Z,...
        'ref',chan_ref,'sph_radius',chan_sph_radius,'type',chan_type,'urchan',chan_urchan);
    fclose(CHAN_fileID);
elseif isstruct(channels)
    EEG.chanlocs = channels;
else
    EEG.chanlocs = struct('labels',channels);
end
EEG.urchanlocs = [];    % original (ur) dataset chanlocs structure containing
                        % all channels originally collected with these data
                        % (before channel rejection)
% EEG.chaninfo - structure containing additional channel info (see below)
EEG.splinefile = '';    % location of the spline file used by headplot() to plot
                        % data scalp maps in 3-D

                        
%% The event and epoch sub-structures:
if nargin < 4 || isempty(events)
    EEG.event = [];         % event structure containing times and nature of experimental
                            % events recorded as occurring at data time points
else
    type = num2cell(events(:,2));               % event type
    latency = num2cell(events(:,1));            % event latency in data sample unit
    urevent = num2cell((1:size(events,1))');    % index of the event
    EEG.event = struct('type',type,'latency',latency,'urevent',urevent);    
end
EEG.urevent = [];           % original (ur) event structure containing all experimental
                            % events recorded as occurring at the original data time points
                            % (before data rejection)
EEG.epoch = [];             % epoch event information and epoch-associated data structure array (one per epoch)
EEG.eventdescription = {};  % cell array of strings describing event fields.
EEG.epochdescription = {};  % cell array of strings describing epoch fields.


%% ICA (or other linear) data components:
EEG.icasphere = [];             % sphering array returned by linear (ICA) decomposition
EEG.icaweights = [];            % unmixing weights array returned by linear (ICA) decomposition
EEG.icawinv = [];               % inverse (ICA) weight matrix. Columns gives the projected
                                % topographies of the components to the electrodes.
EEG.icaact = [];                % ICA activations matrix (components, frames, epochs)
                                % Note: [] here means that 'compute_ica' option has been set
                                % to 0 under 'File > Memory options' In this case,
                                % component activations are computed only as needed.
EEG.icasplinefile = '';         % location of the spline file used by headplot()
                                % to plot component scalp maps in 3-D
EEG.chaninfo.icachansind = [];  % indices of channels used in the ICA decomposition
EEG.icachansind = [];           % same?
EEG.dipfit = [];                % array of structures containing component map dipole models


%% Variables indicating membership of the dataset in a studyset:
EEG.subject = '';	% studyset subject code
EEG.group = '';     % studyset group code
EEG.condition = '';	% studyset experimental condition code
EEG.run = [];       % studyset run number
EEG.session = [];   % studyset session number


%% Variables used for manual and semi-automatic data rejection:
EEG.specdata = [];          % data spectrum for every single trial
%EEG.specica = [];           % data spectrum for every single trial
EEG.specicaact = [];
% EEG.stats - statistics used for data rejection
  % !!! CHECK IF FIELDS DEPEND ON EEGLAB VERSION !!!
    EEG.stats.kurtc = [];   % component kurtosis values
    EEG.stats.kurtg = [];   % global kurtosis of components
    EEG.stats.kurta = [];   % kurtosis of accepted epochs
	EEG.stats.kurtr = [];   % kurtosis of rejected epochs
    EEG.stats.kurtd = [];   % kurtosis of spatial distribution
% EEG.reject - statistics used for data rejection
  % !!! CHECK IF FIELDS DEPEND ON EEGLAB VERSION !!!
	EEG.reject.entropy = [];                % entropy of epochs
	EEG.reject.entropyc = [];               % entropy of components
	EEG.reject.threshold = [0.8,0.8,0.8];   % rejection thresholds
	EEG.reject.icareject= [];               % epochs rejected by ICA criteria
    EEG.reject.gcompreject = [];            % rejected ICA components
	EEG.reject.sigrejec= [];                % epochs rejected by single-channel criteria
    EEG.reject.elecreject= [];              % epochs rejected by raw data criteria

% ALLEEG = EEG;
% CURRENTSTUDY = 0;