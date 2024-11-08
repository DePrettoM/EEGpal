% Parametric ANOVA for ERPs/Inverse solutions 
% Update: 11.2019
%
% =========================================================================
%
% Computes parametric ANOVAs on each time-frame of each channel of EEG
% ERPs/Inverse solutions.
% Currently, the script can read the following formats:
% - BDF (Biosemi)
% - SET/FDT (EEGlab)
% - EP, EPH, SEF, RIS (Cartool)
%
% For now, it works only for fully within-subject designs. Future updates
% will implement betwee-subject designs.
% Analysis on ROIs must also be implemented.
%
% It is possible to save the input parameters into a Matlab MAT file that
% will pre-fill inputs to save time for subsequent analyses. If you don't
% want to save it, just press cancel when the saving window opens.
%
% INPUTS
% - Individual inverse solution .eph files
%   - File names must include the code for the participants and for the
%     conditions (in that order)
%     - Participants code must be of same length for all participants (eg.
%       S01=S12).
% - [CURRENTLY NOT USED] Region of interest file (.rois)
% - 'Exact code of the FIRST participant' is necessary to identify to which
%   subject each file belongs.
% - 'Extension of input files' will determine which files to select and
%   whether such files are supported
% - 'Filtering string for selecting subset of files (optional)' will
%   further refine selection of files (leave blank if not useful).
% - 'Number of conditions' corresponds to the number of measurement in the
%   within-subject design.
%   - For example, in a 2 x 2 within-subject ANOVA, there is 4 conditions
% - 'Number of Factors' corresponds to the number of... well... factors...
%   - For example, in a 2 x 2 ANOVA, there is 2 factors (each with 2
%     levels).
% - 'Alpha threshold' is the threshold of significance.
% - Design
%   - Conditions names: Name of the conditions as they appear in the file
%     names
%   - Factor levels: For each factor, identify which condition belongs to
%     which level of the factor. You can enter either number or more
%     explicit codes. HOWEVER, CURRENTLY THESE ARE NOT USED FOR THE OUTPUT,
%     SO IT DOESN'T REALLY MATTER IF THEY ARE EXPLICIT...
%
%
% OUTPUTS
% - ANOVAs folder
%   - In that folder, for each term of the ANOVA design:
%     - Two files containing either p-values or F-values of the significant
%       data points.
%       - Files CURRENTLY IN RIS FORMAT, CHOICE SHOULD BE GIVEN
%   - Information text file summarizing the inputs/outputs
% 
% 
% FUNCTIONS CALLED
% - open_bdf.m
% - open_eeglab.m
% - open_eph.m
% - open_sef.m
% - open_ris.m
% - open_freq.m [currently only for files with one frequency]
% - save_ris.m
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% Preliminary setting

% clear variables; close all
StartTime = datetime('now');
tic

% Hello!
uiwait(msgbox(sprintf('%s\n%s\n%s\n\n%s\n%s','Hello!', ...
        'This script will allow you to compute ANOVAs on either ERPs, FFTs, or Inverse solutions.',...
        'Make sure to enter everything properly, if not, the blame is on YOU!',...
        'You can save your paramters to ease your life.',...
        'If you upload already saved parameters, you will still be able to change your inputs.'),'Information','help'));

% Path of all needed functions
p = strcat(mfilename('fullpath'),'.m');
I_p = strfind(p,'\'); % index of the \ characters in the path and name of the script
p2 = p(1:I_p(end)-1); % path of the script
addpath(strcat(p2,'\SP_Functions'));

% Supported file extensions
InputFileExt = {'.bdf','.set','.ep','.eph','.sef','.ris','.freq'}; % ,'.freq' -> freq files probably need additional processing...


%% PARAMETERS

PromptSetup = {'Did you already save your input parameters (y/n)?',...
    'Would you like to apply statistics to a ROI (y/n) [NOT IMPLEMENTED YET]?'};
PromptInputs = inputdlg(PromptSetup,'Parameters',1,{'n','n'});
SavedParameters = PromptInputs{1};
ApplyToROI = PromptInputs{2};

% Input
if SavedParameters == 'y'
    uiopen('Design_Parameters.mat')
    % Files
    FirstSubjCode = Design_Parameters.Files.FirstSubjCode;
    FilesExtension = Design_Parameters.Files.FilesExtension;
    FilterString = Design_Parameters.Files.FilterString;
    % Design
    NumCond = num2str(Design_Parameters.Design.NumCond);
    NumFact = num2str(Design_Parameters.Design.NumFact);
    Alpha = num2str(Design_Parameters.Design.Alpha);
    COND = Design_Parameters.Design.COND;
    FACT = Design_Parameters.Design.FACT;
    CONDxFACT = Design_Parameters.Design.CONDxFACT;
    % SUBJ = Design_Parameters.Design.SUBJ; % recomputed anyway...
else
    FirstSubjCode = 'S01';
    FilesExtension = '';
    FilterString = '';
    NumCond = '';
    NumFact = '';
    Alpha = '0.05';
end
PromptSetup = {'Exact code of the FIRST participant:',...
    strcat('Extension of input files (',strjoin(InputFileExt,','),'):'),...
    'Filtering string for selecting subset of files (optional):',...
    'Number of conditions:',...
    'Number of Factors:',...
    'Alpha threshold:'};
PromptInputs = inputdlg(PromptSetup,'Design',1,{FirstSubjCode,FilesExtension,FilterString,NumCond,NumFact,Alpha});
FirstSubjCode = PromptInputs{1};
FilesExtension = PromptInputs{2};
% If filter string entered, add '*' for file selection
if ~isempty(PromptInputs{3})
    FilterString = strcat(PromptInputs{3},'*');
else
    FilterString = PromptInputs{3};
end
NumCond = str2double(PromptInputs{4});
NumFact = str2double(PromptInputs{5});
Alpha = str2double(PromptInputs{6});

% Check if file extension is supported
while ~any(strcmpi(InputFileExt,FilesExtension))
    PromptFileExtSetup = {strcat('Invalid file extension (',FilesExtension,'). Please try again (',strjoin(InputFileExt,','),'):')};
    PromptFileExtInputs = inputdlg(PromptFileExtSetup,'File Extension',1,{''});
    FilesExtension = PromptFileExtInputs{1};
end

% ========================================================
% !!! MAYBE DO CHECKS ON NumCond/NumFact !!!
% -> NumFact must be smaller than NumCond
% -> NumCond must be divisible by NumFact (and result > 1)
% ========================================================


%% Select files

% Path of your upper folder containing your data
root_folder = uigetdir('title',...
    'Choose the path of your most upper folder containing the files');
cd(root_folder)
FilesList = dir(['**/*' FilterString FilesExtension]);
% If no files found, re-ask for files parameters
while isempty(FilesList)
    PromptFilesSetup = {sprintf('%s\n%s\n\n%s%s\n%s%s\n%s%s\n\n%s\n\n%s','No files found.', ...
        'Please make sure to select the correct files or enter the correct parameters.',...
        'Files extension entered: ',FilesExtension,...
        'Filtering string entered: ',FilterString,...
        'Path of your most upper folder containing the files: ',root_folder,...
        'Please try again!',...
        strcat('Extension of input files (',strjoin(InputFileExt,','),'):')),...
        'Filtering string for selecting subset of files (optional):'};
    PromptFilesInputs = inputdlg(PromptFilesSetup,'No files found',1,{'',''});
    FilesExtension = PromptFilesInputs{1};
    % If filter string entered, add '*' for file selection
    if ~isempty(PromptFilesInputs{2})
        FilterString = strcat(PromptFilesInputs{2},'*');
    else
        FilterString = PromptFilesInputs{2};
    end
    root_folder = uigetdir('title',...
        'Choose the path of your most upper folder containing the files');
    cd(root_folder)
    FilesList = dir(['**/*' FilterString FilesExtension]);
end

% Path of the folder where to save the output
save_folder = uigetdir(root_folder,...
    'Enter the path of the folder where you want to save your results');

% ROI file
if ApplyToROI == 'y'
    [ROIfile, ROI_PathName] = uigetfile('*.rois','Select the ROI file');
    ROIfileID = fopen(strcat(ROI_PathName,ROIfile),'rt'); % open ROI file for reading in text mode
    
    % read ROI file
    roi = textscan(ROIfileID,'%s','delimiter','\n');
    roi = roi{1}; % Removes an unnecessary cell "level"
    magicnumber = roi{1};
    NumSP = str2double(roi{2});
    NumROIS = str2double(roi{3});
    pointer = 4; % line of the first ROI
end


%% Design

% Identify subjects
SUBJ = strings([length(FilesList),1]); % Create array for subject codes
SubjNameIndex = strfind(FilesList(1).name,FirstSubjCode); % Index of Subject code in the file name

% Check subject code could be identified
while isempty(SubjNameIndex)
    PromptSubjSetup = {sprintf('%s\n%s\n\n%s%s\n%s%s\n\n%s','Couldn''t find the code of the first subject in the name of the first file.', ...
        'Please make sure to select the correct files or enter the correct parameters.',...
        'Name of files: ',FilesList(1).name,...
        'Code of the first subject entered: ', FirstSubjCode,...
        'Please try again! It must be in the file name (case sensitive):')};
    PromptSubjInputs = inputdlg(PromptSubjSetup,'Error in subject name identification',1,{''});
    FirstSubjCode = PromptSubjInputs{1};
    SubjNameIndex = strfind(FilesList(1).name,FirstSubjCode); % Index of Subject code in the file name (second try!)
end
% Extract subject codes from files
for file = 1:length(FilesList)
    if SubjNameIndex+strlength(FirstSubjCode)-1 > length(FilesList(file).name)
        continue
    else
        SUBJ(file,:) = FilesList(file).name(SubjNameIndex:SubjNameIndex+strlength(FirstSubjCode)-1);
    end
end
[FilesList.SUBJ] = SUBJ{:}; % Subject attribute for each file (used for removing unwanted subjects)
FilesList = FilesList(~strcmp({FilesList.SUBJ},'')); % remove files with empty SUBJ (added if name of file was shorter than the index of SubjNameIndex)
NumFilesFirstSubj = sum(SUBJ==FirstSubjCode); % Number of files for the first subject
SUBJ = unique(SUBJ(SUBJ~='')); % SUBJ list, removing empty rows (added if name of file was shorter than the index of SubjNameIndex)
NumSubj = length(SUBJ); % number of subjects for analysis

% =========================================================================
% Intermediate parameters file preparation
Design_Parameters.Files.FirstSubjCode = FirstSubjCode;
Design_Parameters.Files.FilesExtension = FilesExtension;
Design_Parameters.Files.FilterString = FilterString(1:end-1); % Remove '*' character at the end

Design_Parameters.Design.NumCond = NumCond;
Design_Parameters.Design.NumFact = NumFact;
Design_Parameters.Design.Alpha = Alpha;
Design_Parameters.Design.SUBJ = SUBJ;
% =========================================================================

% Default condition names
if SavedParameters == 'n'
    COND = strings(NumCond,1); % empty string (nr rows = nr of conditions)
    for cond = 1:NumCond
        COND(cond,1) = strcat('Condition',{' '},num2str(cond)); % Default condition names
    end
    % Default factor names
    FACT = strings(1,NumFact); % empty string (nr rows = nr of conditions)
    for fact = 1:NumFact
        FACT(1,fact) = strcat('Factor',{' '},num2str(fact)); % Default condition names
    end
    CONDxFACT = strings(length(COND),length(FACT)+1);
    CONDxFACT(:,1) = COND;
end


% Prompt subjects identified and design check
DesignCheck = '';
while ~strcmpi(DesignCheck,'OK')
    DesignCheck = questdlg(sprintf('%s%d%s\n%s%d\n\n%s\n%s\n\n%s%s%s%d\n\n%s\n\n%s\n%s','I (me, the script) found ',length(FilesList),' files matching your criteria.', ...
        'Number of subjects identified: ',NumSubj,...
        'Subject codes: ', strjoin(SUBJ,', '),...
        'Number of files for ',FirstSubjCode,': ',NumFilesFirstSubj,...
        'If you press Select Subjects, you will be able to select specific subjects to include',...
        'If you press Cancel, the script will terminate (it''s up to you!)',...
        'You will be able to save the design parameters already entered before termination.'),'Design check','OK','Select Subjects/Folders','Cancel','OK');
    if strcmpi(DesignCheck,'Select Subjects/Folders')
        
        % Prepare folders names
        Folders = unique({FilesList.folder}); % Retrieve names from the FileList structure
        SubFolders = cellfun(@(x) x(length(root_folder)+2:end),Folders,'UniformOutput',false); % Removing the consistant part of the path name
        
        % Prompt subjects and folders selection for inclusion in the analysis
        SUBJlist = [cellstr(SUBJ), repmat({true},[size(SUBJ,1) 1])];
        SUBJselection = SUBJlist;
        FOLDERSlist = [cellstr(SubFolders'), repmat({true},[size(SubFolders,2) 1])];
        FOLDERSselection = FOLDERSlist;
        figure('Name','Select Subjects','Position', [500 400 460 500],'MenuBar','none',...
            'NumberTitle','off','color',[0.9333 0.9765 0.9569])
        SUBJtable = uitable('Data',SUBJlist,'Position',[20 20 204 340],'FontSize',10,...
            'ColumnEdit',[false true],'ColumnName',{'Subject','Include?'},'CellEditCallBack','SUBJselection = get(gco,''Data'');');
        FOLDERtable = uitable('Data',FOLDERSlist,'Position',[234 20 204 340],'FontSize',10,...
            'ColumnEdit',[false true],'ColumnName',{'Folder','Include?'},'CellEditCallBack','FOLDERSselection = get(gco,''Data'');');
        uicontrol('Style', 'text', 'Position', [20 360 330 130],'FontSize',10,'HorizontalAlignment','left','BackgroundColor',[0.9333 0.9765 0.9569],...
            'String',{'Select the subjects and folders to include in the analysis',...
            ' ','...',' ',...
            'Actually... just untick the ones you don''t want to include',...
            ' ','When done, close window or press ''Ctrl+F4'''});
        
        % Wait for CONDtable to be closed before running the rest of the script
        waitfor(SUBJtable)
        FilesList = FilesList(~contains({FilesList.SUBJ},SUBJselection(cell2mat(SUBJselection(:,2))==0,1))); % remove unticked subjects from FilesList
        FilesList = FilesList(~contains({FilesList.folder},FOLDERSselection(cell2mat(FOLDERSselection(:,2))==0,1))); % remove unticked folders from FilesList
        SUBJ = unique(string({FilesList.SUBJ}')); % update SUBJ
        NumSubj = length(SUBJ); % update number of subjects for analysis
        NumFilesFirstSubj = sum(contains({FilesList.SUBJ},FirstSubjCode)); % Number of files for the first subject
        % FilesList = FilesList(~contains({FilesList.name},SUBJselection(cell2mat(SUBJselection(:,2))==0,1))); % remove unticked subjects from FilesList

    elseif strcmpi(DesignCheck, 'Cancel')
        Design_Parameters.Design.COND = COND;
        Design_Parameters.Design.FACT = FACT;
        Design_Parameters.Design.CONDxFACT = CONDxFACT;
        uisave('Design_Parameters','Design_Parameters.mat')
        % User said Cancel, so exit.
        fprintf('%s\n%s\n','Apparently, you were not happy with something in your design and you pressed cancel.',...
            'The script has now terminated. You can do additional checks and try again (and again, and again...)');
        return;
    end
end
% % Check if number of files matches number of subjects * number of conditions
% if length(EPHfiles) ~= NumSubj * NumCond
%     f = errordlg(sprintf('%s\n%s\n%s%d\n%s%d','Number of files doesn''t match number of subjects * number of conditions.', ...
%         'Please make sure to select the correct files or enter the correct parameters.',...
%         'Number of files: ', length(EPHfiles), ...
%         'Number of subjects * number of conditions: ', NumSubj * NumCond),'Error in number of files and/or parameters');
% end

% Prompt table asking for the condition names
figure('Name','Define Factorial Design','Position', [500 400 400 500],'MenuBar','none',...
    'NumberTitle','off','color',[0.9333 0.9765 0.9569])
CONDtable = uitable('Data',cellstr(CONDxFACT),'Position',[20 80 360 160],'FontSize',10,...
    'ColumnEditable',true,'ColumnName',cellstr(['Condition name',FACT]),'CellEditCallBack','CONDxFACT = get(gco,''Data'');');
FACTtable = uitable('Data',cellstr(FACT),'Position',[20 20 360 50],'FontSize',10,...
    'ColumnEditable',true,'ColumnName',cellstr(FACT),'CellEditCallBack','FACT = get(gco,''Data'');');
uicontrol('Style', 'text', 'Position', [20 270 360 210],'FontSize',10,'HorizontalAlignment','left','BackgroundColor',[0.9333 0.9765 0.9569],...
    'String',{'Enter condition names as they appear in the file name (case sensitive).',...
    'If only one condition, please enter any string present in all input file names.',' ',...
    'In the factor columns, enter the appropriate level names (text or number) next to each condition.',...
    'You can rename factor in the second table.',...
    ' ','When done, close window or press ''Ctrl+F4'''});
% Wait for CONDtable to be closed before running the rest of the script
waitfor(CONDtable)

COND = CONDxFACT(:,1); % applies modifications to condition names if any

% Prepare factor levels as categorical arrays
% (and changes strings to numbers if needed)
Measurements = array2table(categorical(CONDxFACT(:,2:end)),'VariableNames',FACT); % Used to prepare rmANOVA
for fact = 1:NumFact
    Levels = unique(Measurements{:,fact},'stable');
    for level = 1:length(Levels)
        Measurements(Measurements{:,fact}==Levels(level,1),fact) = {categorical(level)};
    end
    Measurements.(fact) = removecats(Measurements.(fact));
end


%=================================================
Design_Parameters.Design.COND = COND;
Design_Parameters.Design.FACT = FACT;
Design_Parameters.Design.CONDxFACT = CONDxFACT;
Design_Parameters.Design.SUBJ = SUBJ;
uisave('Design_Parameters','Design_Parameters.mat')
%=================================================


%% ANALYSIS


%% Preparation

% Check header from first file
openfilename = [FilesList(1).folder,'\',FilesList(1).name]; % full path and name of the file
if strcmpi(FilesExtension,'.bdf')
    [header] = open_bdf(openfilename);
elseif strcmpi(FilesExtension,'.set')
    [header] = open_eeglab(openfilename);
elseif strcmpi(FilesExtension,'.sef')
    [header] = open_sef(openfilename);
elseif strcmpi(FilesExtension,'.ep') % EP files don't have a header, so it needs to load the data to know the number of TFs and Channels
    [header,~] = open_eph(openfilename); 
elseif strcmpi(FilesExtension,'.eph')
    [header] = open_eph(openfilename);
elseif strcmpi(FilesExtension,'.ris')
    [header] = open_ris(openfilename);
    header.NumChan = header.NumSP;
elseif strcmpi(FilesExtension,'.freq')
    [header] = open_freq(openfilename);
    header.NumTF = header.NumBlocks;
end

% Prepare matrix for the data per condition
DataMatrix = zeros(NumSubj,header.NumTF,header.NumChan,NumCond);


%% Load the data

disp('Loading files...')
for subj = 1:NumSubj
    for cond = 1:NumCond
        for file = 1:length(FilesList)
            if contains(FilesList(file).name,SUBJ(subj,1)) && contains(FilesList(file).name,COND(cond,1))
                openfilename = [FilesList(file).folder,'\',FilesList(file).name]; % full path and name of the file
                if strcmpi(FilesExtension,'.bdf')
                    [header,data] = open_bdf(openfilename);
                elseif strcmpi(FilesExtension,'.set')
                    [header,data] = open_eeglab(openfilename);
                elseif strcmpi(FilesExtension,'.sef')
                    [header,data] = open_sef(openfilename);
                elseif strcmpi(FilesExtension,'.ep') || strcmpi(FilesExtension,'.eph')
                    [header,data] = open_eph(openfilename);
                elseif strcmpi(FilesExtension,'.ris')
                    [header,data] = open_ris(openfilename);
                    header.NumChan = header.NumSP;
                elseif strcmpi(FilesExtension,'.freq')
                    [header,data] = open_freq(openfilename);
                    header.NumTF = header.NumBlocks;
                    data = squeeze(data); % Currently only for files with one frequency!
                end
                DataMatrix(subj,:,:,cond) = data;
            end
        end
    end
end
disp('Files loaded!')


%% Model specifications

% % Wilkinson notation for between-subjects
% from "simple_mixed_anova.m", Copyright 2017, Laurent Caplette
% betweenModel = '';
% for ii = 1:nBetween
%     betweenModel = [betweenModel,measureNames{nMeas+ii},'*'];
% end
% betweenModel = betweenModel(1:end-1); % remove last star
% if isempty(betweenModel)
%     betweenModel = '1'; % if no between-subjects factor, put constant term (usually implicit)
% end
betweenModel = '1';

% Wilkinson notation for within-subject model
withinModel = strjoin(FACT,'*');

ModelSpecs = sprintf('%s-%s~%s', COND{1},COND{NumCond},betweenModel);

% Number of Main and Interaction effects
nEff = NumFact;
for n = NumFact-1:-1:1
    nEff = nEff + (n * (n + 1)) / 2;
end

% Results matrices
Pvals = zeros(header.NumChan,header.NumTF,nEff);
Fvals = zeros(header.NumChan,header.NumTF,nEff);


%% ANOVAs

tANOVAs = tic; % Start time (for progression bar)
bar_tf = waitbar(0,'Computing ANOVAs','Name','Computing ANOVAs'); % Progression bar

for tf = 1:header.NumTF
    for channel = 1:header.NumChan
        waitbar(((tf-1)*header.NumChan+channel)/(header.NumTF*header.NumChan),bar_tf,strcat('Computing ANOVAs, remaining time:',{' '},...
            num2str(floor((((toc(tANOVAs)/((tf-1)*header.NumChan+channel))*(header.NumTF*header.NumChan))-toc(tANOVAs))/86400)),' day(s)',... % 86400 is the number of seconds in a day
            datestr(seconds(((toc(tANOVAs)/((tf-1)*header.NumChan+channel))*(header.NumTF*header.NumChan))-toc(tANOVAs)),' HH:MM:SS'))); % = elapsed time / steps completed * Tot number of steps - elapsed time
        DataTable = array2table(squeeze(DataMatrix(:,tf,channel,:)),'VariableNames',COND);
        % Fit repeated measures model
        rm = fitrm(DataTable,ModelSpecs,'WithinDesign',Measurements);
        rmANOVA = ranova(rm,'WithinModel',withinModel);
        % Extract p-values and F-values 
        for effect = 1:nEff
            if rmANOVA.pValue(2*effect+1) < Alpha % Report only values for significant channels
                Pvals(channel,tf,effect) = 1 - rmANOVA.pValue(2*effect+1);
                Fvals(channel,tf,effect) = rmANOVA.F(2*effect+1);
            end
        end
    end
    disp(['Completed time-frame ',num2str(tf),' out of ',num2str(header.NumTF)])
    disp(['Duration until now: ',datestr(seconds(toc(tANOVAs)),'HH:MM:SS')])
    disp('...............................................................')
end
close(bar_tf)


%% OUTPUT

EffectNames = strings(nEff,1); % For effect denominations
for effect = 1:nEff
    Name = char(rmANOVA.Properties.RowNames(2*effect+1));
    if effect <= NumFact
        EffectNames(effect,1) = strcat('MainEffect_',strrep(upper(Name(13:end)),':','x'));
    else
        EffectNames(effect,1) = strcat('Interaction_',strrep(upper(Name(13:end)),':','x'));
    end
    
    % Output files
    mkdir(save_folder,strcat('ANOVAs_alpha',num2str(Alpha))) % Create ANOVAs folder in which results will be saved
%     save_ris(strcat(save_folder,'\ANOVAs_alpha',num2str(Alpha),'\',num2str(effect,'%02.0f'),'.',EffectNames(effect,1),'_Pvals.ris'),Pvals(:,:,effect)',header.SamplingRate)
%     save_ris(strcat(save_folder,'\ANOVAs_alpha',num2str(Alpha),'\',num2str(effect,'%02.0f'),'.',EffectNames(effect,1),'_Fvals.ris'),Fvals(:,:,effect)',header.SamplingRate)
    save_eph(strcat(save_folder,'\ANOVAs_alpha',num2str(Alpha),'\',num2str(effect,'%02.0f'),'.',EffectNames(effect,1),'_Pvals.eph'),Pvals(:,:,effect)',header.SamplingRate)
    save_eph(strcat(save_folder,'\ANOVAs_alpha',num2str(Alpha),'\',num2str(effect,'%02.0f'),'.',EffectNames(effect,1),'_Fvals.eph'),Fvals(:,:,effect)',header.SamplingRate)
end


%% INFORMATION SHEET

currentfile = dir(p); % Information about current file

% Last official update
fileID = fopen(strcat(currentfile.folder,'\',currentfile.name)); % open this file
update = char(string(textscan(fileID,'%s',1,'HeaderLines',1,'delimiter','\n'))); % Extract 'Update' line

% Create a .txt file for PIF (Processing Info File)
PifFileID = fopen([save_folder '\ANOVAs_alpha' num2str(Alpha) '\PIF_ANOVAs_' datestr(now,'dd-mm-yy_HHMMSS') '.txt'],'w');
fprintf(PifFileID,'%s\r\n%s\r\n\r\n','Parametric ANOVA for ERPs/Inverse solutions',...
    '======================================================================='); % header

fprintf(PifFileID,'%s\r\n\r\n',char(strcat('Date:',{' '},datestr(datetime))));
fprintf(PifFileID,'%s%s\r\n','Name of script: ',currentfile.name);
fprintf(PifFileID,'%s%s\r\n','Script last official update: ',update(11:end));
fprintf(PifFileID,'%s%s\r\n\r\n','Script last save: ',currentfile.date);

fprintf(PifFileID,'%s\r\n','PARAMETERS');
fprintf(PifFileID,'%s%s\r\n','Filter for files selection: ',['*' FilterString FilesExtension]);
fprintf(PifFileID,'%s%d\r\n','Number of conditions: ',NumCond);
fprintf(PifFileID,'%s%d\r\n','Number of Factors: ',NumFact);
fprintf(PifFileID,'%s%s\r\n\r\n','Alpha threshold: ',num2str(Alpha));
fprintf(PifFileID,'%s\r\n','Design:');
fprintf(PifFileID,[repmat('\t%s\t',1,1+NumFact) '\r\n'],'Conditions',string(FACT));
fprintf(PifFileID,[repmat('\t%s\t\t',1,1+NumFact) '\r\n'],string(CONDxFACT)');

fprintf(PifFileID,'\r\n%s\r\n','Subjects included:');
fprintf(PifFileID,'\t%s\r\n',SUBJ(:,:));

fprintf(PifFileID,'\r\n%s\r\n','INPUT FILES (file name  /  folder)');
Files = [{FilesList.name}',{FilesList.folder}']';
fprintf(PifFileID,'%s\t\t%s\r\n',Files{:});

fclose('all');

disp('Finished :)')
EndTime = datetime('now');
disp(['Start Time: ' datestr(StartTime)])
disp(['End Time: ' datestr(EndTime)])
disp(['Total duration: ',datestr(seconds(toc),'HH:MM:SS')])


%% SP_LABELS

% Prompt subjects identified and design check
LaunchSPlabels = questdlg(sprintf('%s',...
    'Would you like to launch script for clustering and labelling results?'),...
    'Launch SP_Labels_2_5_1?','Yes','No','Yes');
if strcmpi(LaunchSPlabels, 'Yes')
    run('SP_Labels_2_5_1')
end