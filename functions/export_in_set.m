function export_in_set(app, openfilename)
% export an input eegfile into a .set

    events = ''; % In case no events in input file
    nOutFiles = 1; % FREQ files will yield 1 file per frequence, other formats: just 1

    % Load file
    [~,FileName,FileExtension] = fileparts(openfilename);
    if strcmpi(FileExtension,'.bdf')
        [header,data,events] = open_bdf(openfilename);
    elseif strcmpi(FileExtension,'.set')
        [header,data,events] = open_eeglab(openfilename);

    elseif strcmpi(FileExtension,'.sef')
        [header,data,events] = open_sef(openfilename);
    elseif strcmpi(FileExtension,'.ep') || strcmpi(FileExtension,'.eph')
        [header,data,events] = open_eph(openfilename);
        if strcmpi(FileExtension,'.ep')
            header.SamplingRate = app.DataFilesTable.Data.SamplingRate(file);
        end
    elseif strcmpi(FileExtension,'.ris')
        [header,data] = open_ris(openfilename);
    elseif strcmpi(FileExtension,'.freq')
        [header,data] = open_freq(openfilename);
        data = permute(data,[3 2 1]); %  rearranges dimensions for conversion in another format
        nOutFiles = header.NumFreq;
    else
        disp('File extension not recognized.')
        disp('File skipped.')
    end
    disp('File loaded!')
    
    %initialisation
    FreqName = "";
    nOutFiles = 1;
    
    savefilename=strcat(openfilename(1:end-4),'_exported.set');
    
    %save
     try
        ElectrodeSetting    = app.SessionParameters.Electrodes.SettingTable([app.SessionParameters.Electrodes.SettingTable.include{:}],:);
        Channels            = ElectrodeSetting(:,2);
        %Channels.labels     = char(ElectrodeSetting.labels);

        % Recompute Theta and Radius to match EEGlab orientation
        [az,elev,~]         = cart2sph(ElectrodeSetting.y,-ElectrodeSetting.x,ElectrodeSetting.z); % Nasion: in Cartool = Y+, in EEGlab = X+; 
        Channels.theta      = -rad2deg(az);
        Channels.radius     = 0.5 - rad2deg(elev)/180;
        Channels.sph_theta  = -Channels.theta;
        Channels.sph_phi    = (0.5 - Channels.radius) * 180;
        Channels.X          = ElectrodeSetting.y;
        Channels.Y          = -ElectrodeSetting.x;
        Channels.Z          = ElectrodeSetting.z;
%                         Channels.ref        = char(repmat({''},height(Channels),1));
%                         Channels.sph_radius = repmat({[]},height(Channels),1);
%                         Channels.types      = char(repmat({''},height(Channels),1));
%                         Channels.urchan     = repmat({[]},height(Channels),1);
        Channels            = table2struct(Channels);
        save_eeglab(savefilename,data(:,:,1),header.SamplingRate,events,header.firstindex,Channels)
    catch
        save_eeglab(savefilename,data(:,:,1),header.SamplingRate,events,header.firstindex)
    end

end

