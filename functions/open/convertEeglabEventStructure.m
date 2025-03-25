function EEG = convertEeglabEventStructure(EEG, openfilename)
% This function has two purpose: 
% 1. convert the structure of event record by eeglab by the more simple
% structure of event use by EEGpal (and compatible with eeglab)
% 2. Convert string trigger to new num trigger (generate a txt file for the
% correspondance) 

sizeEventStruct=size(EEG.event, 2);

%specific case of eeg/vhdr file format, supress boundary trigger
tosupress=[];
for i=1:sizeEventStruct
    if (or(ischar(EEG.event(i).type),isstring(EEG.event(i).type)) && strcmp(EEG.event(i).type,'boundary'))
        tosupress=[tosupress,i];               
    end
end
EEG.event(tosupress)=[];
EEG.urevent(tosupress)=[];
sizeEventStruct=sizeEventStruct-length(tosupress);


if sizeEventStruct>0 %if the file contains triggers
    
    % convert char event name to num event name
    [origName,~,newNumName]=unique({EEG.event(:).type});
    
    
    
    % Record a txt file with the correspondance between new and old marker
    [tempPath,tempName,~] = fileparts(openfilename);
    FileID = fopen(fullfile(tempPath,strcat(tempName,'_Events.txt')),'w');
    fprintf(FileID,'%s\r\n%s\r\n\r\n','Information file about the event/trigger names',...
                    '======================================================================='); % header
    fprintf(FileID,'%s\r\n','The original event/trigger names have been changed. It was necessary to convert string names to numerical names.');
    fprintf(FileID,'\r\n%s\t%s\t%s\r\n','Original name','->' ,'New name');
    for j=1:size(origName,2)
        fprintf(FileID,'%s\t%s\t%d\r\n',origName{1,j},'->',j);
    end
    fclose(FileID);
    
    % generate the new event struct 
    for i=1:sizeEventStruct
        EEG.NEWevent(i).type = newNumName(i);
        EEG.NEWevent(i).latency = EEG.event(i).latency;
        EEG.NEWevent(i).urevent = i;
        EEG.NEWevent(i).duration = 0;
    
        EEG.NEWurevent(i).type = newNumName(i);
        EEG.NEWurevent(i).latency = EEG.event(i).latency;
        EEG.NEWurevent(i).duration = 0;
    end
    
    %replace the new event filed and remove the tempopary field
    EEG.event = EEG.NEWevent';
    EEG.urevent = EEG.NEWurevent';
    EEG = rmfield(EEG, 'NEWevent');
    EEG = rmfield(EEG, 'NEWurevent');
end


end