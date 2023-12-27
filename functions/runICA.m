


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%load dataset
EEG = pop_loadset('filename','Interoception_CAS_P006_20112023_synch1_filtered.set','filepath','C:\\software\\EEG_processing_pipeline\\EEGpalCS\\EEGpal\\temp\\ICA_with_EEGlab\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%load EEGlab coordinate file
EEG = pop_editset(EEG, 'chanlocs', 'S:\\Resource\\EEG_processing\\biosemi64AB.locs');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%run ICA
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%save dataset
EEG = pop_saveset( EEG, 'filename','Interoception_CAS_P006_20112023_synch1_filtered_ICA.set','filepath','C:\\software\\EEG_processing_pipeline\\EEGpalCS\\EEGpal\\temp\\ICA_with_EEGlab\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%Tag the EEG component
EEG = pop_iclabel(EEG, 'default'); 
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

%display the 24 first ICA components
pop_selectcomps(EEG, [1:24] );
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%plot the ICA compounds
pop_eegplot( EEG, 0, 1, 1);

%remove coumpont and save results
EEG = pop_subcomp( EEG, [], 0);

EEG = pop_saveset( EEG, 'filename','Interoception_CAS_P006_20112023_synch1_filtered_ICA_pruned2.set','filepath','C:\\software\\EEG_processing_pipeline\\EEGpalCS\\EEGpal\\temp\\ICA_with_EEGlab\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);