
% Reproduce topoplot crash with Brainstorm-like chanlocs

% Create 270 channels with valid X Y Z (Brainstorm format)
num_chans = 270;
for i = 1:num_chans
    chanlocs(i).labels = sprintf('MEG%03d', i);
    % Random positions on a sphere approximately
    theta = 2*pi*rand;
    phi = pi*rand - pi/2;
    r = 100; % mm
    chanlocs(i).X = r * cos(theta) * cos(phi);
    chanlocs(i).Y = r * sin(theta) * cos(phi);
    chanlocs(i).Z = r * sin(phi);
    chanlocs(i).type = 'MEG';
    
    % Ensure no other fields exist initially to mimic user struct
end

% Check structure fields
disp('fields in chanlocs:');
disp(fieldnames(chanlocs));

% Create dummy data
data = rand(num_chans, 1);

% Try topoplot
try
    disp('Calling topoplot with 270 channels...');
    figure;
    topoplot(data, chanlocs, 'electrodes', 'on');
    disp('Success!');
    close(gcf);
catch ME
    disp(['Error: ' ME.message]);
    disp(['Line: ' num2str(ME.stack(1).line)]);
    if length(ME.stack) > 1
        disp(['Caller Line: ' num2str(ME.stack(2).line)]);
    end
end

% Try adding some NaNs (simulating bad channels)
disp('--- Test with some NaNs ---');
chanlocs(1).X = NaN; chanlocs(1).Y = NaN; chanlocs(1).Z = NaN;
try
    topoplot(data, chanlocs);
    disp('Success with NaNs!');
    close(gcf);
catch ME
     disp(['Error with NaNs: ' ME.message]);
end

% Try adding empty fields
disp('--- Test with empty fields ---');
chanlocs(2).X = []; chanlocs(2).Y = []; chanlocs(2).Z = [];
try
    topoplot(data, chanlocs);
    disp('Success with empty fields!');
    close(gcf);
catch ME
     disp(['Error with empty: ' ME.message]);
end
