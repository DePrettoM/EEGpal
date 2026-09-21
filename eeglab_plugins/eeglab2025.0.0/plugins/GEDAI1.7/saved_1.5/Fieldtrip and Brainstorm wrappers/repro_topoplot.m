
% Reproduce topoplot error with missing coordinates

% 1. Create a chanlocs struct with mixed valid and empty coordinates
clear chanlocs
chanlocs(1).labels = 'Ch1';
chanlocs(1).X = 1;
chanlocs(1).Y = 0;
chanlocs(1).Z = 0;
chanlocs(1).type = 'EEG';

chanlocs(2).labels = 'Ch2';
% Leave X, Y, Z empty (implicitly [])
chanlocs(2).X = []; 
chanlocs(2).Y = [];
chanlocs(2).Z = [];
chanlocs(2).type = 'EEG';

chanlocs(3).labels = 'Ch3';
chanlocs(3).X = -1;
chanlocs(3).Y = 0;
chanlocs(3).Z = 0;
chanlocs(3).type = 'EEG';

% 2. Create fake data
data = rand(3,1);

% 3. Call topoplot
try
    disp('Calling topoplot with empty coordinates...');
    figure;
    topoplot(data, chanlocs, 'electrodes', 'on');
    disp('Success!');
catch ME
    disp(['Error: ' ME.message]);
    disp(['Line: ' num2str(ME.stack(1).line)]);
end

% 4. Create chanlocs with NaNs
disp('--------------------------------');
clear chanlocs_nan
chanlocs_nan(1).labels = 'Ch1';
chanlocs_nan(1).X = 1; chanlocs_nan(1).Y=0; chanlocs_nan(1).Z=0;
chanlocs_nan(2).labels = 'Ch2';
chanlocs_nan(2).X = NaN; chanlocs_nan(2).Y=NaN; chanlocs_nan(2).Z=NaN;
chanlocs_nan(3).labels = 'Ch3';
chanlocs_nan(3).X = -1; chanlocs_nan(3).Y=0; chanlocs_nan(3).Z=0;

try
    disp('Calling topoplot with NaN coordinates...');
    figure;
    topoplot(data, chanlocs_nan, 'electrodes', 'on');
    disp('Success with NaN!');
catch ME
    disp(['Error: ' ME.message]);
    disp(['Line: ' num2str(ME.stack(1).line)]);
end
