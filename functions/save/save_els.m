function save_els(savefilename,electrodestable,clusttype)

% Update: 02.2020
% =========================================================================
%
% Saves Cartool electrodes setup file (.els))
% Cartool: https://sites.google.com/site/cartoolcommunity/
%
%
% INPUTS
% - Full saving path and name (with extension)
% - Electrodes setup table where
%   - Columns 1 to 3 are the x y z coordinates
%   - (optional) Column 4 contains the labels
%     If there is only 3 columns, electrodes will be named 'e1', 'e2', etc.
%   - (optional) Column 5 contains the cluster names
%     If there is only 4 columns, all electrode will be grouped into one
%     cluster names 'ELECTRODES' (yeah, fancy!)
% - (optional) Numeric array representing the cluster type
%   - 0 for separated electrodes (like auxiliaries), or "points"
%   - 1 for a strip of electrodes, or "line"
%   - 2 for a grid of electrodes, or "array"
%   - 3 for a 3D set of electrodes
%   In no cluster type defined, the first will be set at 3 and all others
%   will be set at 0
%
% OUTPUTS
% - .els file
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


%% READ INPUTS
[~,~,ext] = fileparts(savefilename);
if ~strcmp(ext,'.els')
    error(['Specified file name ' savefilename ' is not an ELS file']);
end

nElec = height(electrodestable); % number of electrodes

% Name channels
if width(electrodestable) == 3 % only x y z, one cluster
    ElecNames = [rempat('e',[nElec 1]) num2str(1:nElec)'];
	electrodestable.ElecNames = ElecNames;
end

% Clusters information
if width(electrodestable) < 5 % no cluster information
    nClust = 1;
    ClustNames = "ELECTRODES";
	electrodestable.ClustNames = ClustNames;
elseif width(electrodestable) == 5
    ClustNames = unique(electrodestable.(5),'stable'); % name of clusters
    nClust = length(ClustNames); % number of clusters
end

% Cluster types
if nargin < 3
    clusttype = zeros(nClust,1);
    clusttype(1) = 3;
end

% Prepare output
OutputTable = table('Size',[3 4],'VariableTypes',{'cellstr','cellstr','cellstr','cellstr'});
OutputTable(:,1) = [{'ES01'}; {nElec}; {nClust}];

for clust = 1:nClust
    nElecClust = sum(strcmp(electrodestable.(5),ClustNames(clust)));
    tmpTable = table('Size',[3+nElecClust 4],'VariableTypes',{'cellstr','cellstr','cellstr','cellstr'});
    tmpTable(1:3,1) = [ClustNames(clust); {sum(strcmp(electrodestable.(5),ClustNames(clust)))}; {clusttype(clust)}];
    tmpTable(4:end,1) = cellstr(num2str(table2array(electrodestable(strcmp(electrodestable.(5),ClustNames(clust)),1))));
    tmpTable(4:end,2) = cellstr(num2str(table2array(electrodestable(strcmp(electrodestable.(5),ClustNames(clust)),2))));
    tmpTable(4:end,3) = cellstr(num2str(table2array(electrodestable(strcmp(electrodestable.(5),ClustNames(clust)),3))));
    tmpTable(4:end,4) = cellstr(electrodestable.(4)(strcmp(electrodestable.(5),ClustNames(clust))));
    OutputTable = [OutputTable; tmpTable];
end


% SAVE ELS
writetable(OutputTable,[savefilename '.txt'],'delimiter','\t','WriteVariableNames',0)
movefile([savefilename '.txt'],savefilename)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MORE EFFICIENT WHEN writematrix IS WELL IMPLANTED?

% % Prepare headers
% headers = cell(3,nClust+1);
% %headers(:,1) = ['ES01'; num2str(nElec); num2str(nClust)];
% headers(:,1) = [{'ES01'}; {nElec}; {nClust}];
% for clust = 1:nClust
%     headers(:,clust+1) = [ClustNames; {sum(strcmp(electrodestable.(5),ClustNames(clust)))}; {clusttype(clust)}];
% end
% 
% try % writematrix introduced in Matlab R2019a, 'WriteMode' introduced in R2020
%     writematrix(headers(:,1),[savefilename '.txt'],'Delimiter','tab');
%     for clust = 1:nClust
%         electrodesmatrix = table2cell(electrodestable(strcmp(electrodestable.(5),ClustNames(clust)),1:4));
%         writematrix(electrodesmatrix,[savefilename '.txt'],'Delimiter','tab','WriteMode','append');
%     end
%     movefile([savefilename '.txt'],savefilename)
% catch % dlmwrite not recommended, for compatibility only
%     delete([savefilename '.txt'])
%     dlmwrite(savefilename,headers(:,1),'delimiter','\t','Precision','%s');
%     for clust = 1:nClust
%         electrodesmatrix = table2cell(electrodestable(strcmp(electrodestable.(5),ClustNames(clust))));
% 		dlmwrite(savefilename,electrodesmatrix,'delimiter','\t','-append');
%     end
% end