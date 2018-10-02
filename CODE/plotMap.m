%{
 ______                __                     ____               __        
/\__  _\              /\ \                   /\  _`\            /\ \       
\/_/\ \/    __   _____\ \ \___   _ __    __  \ \ \_\ \_ __   ___\ \ \____  
   \ \ \  /'__`\/\ '__`\ \  _ `\/\`'__\/'__`\ \ \ ,__/\`'__\/ __`\ \ '__`\ 
    \ \ \/\  __/\ \ \_\ \ \ \ \ \ \ \//\ \_\.\_\ \ \/\ \ \//\ \_\ \ \ \_\ \
     \ \_\ \____\\ \ ,__/\ \_\ \_\ \_\\ \__/.\_\\ \_\ \ \_\\ \____/\ \_,__/
      \/_/\/____/ \ \ \/  \/_/\/_/\/_/ \/__/\/_/ \/_/  \/_/ \/___/  \/___/ 
                   \ \_\                                                   
                    \/_/                                                   
___________________________________________________________________________

Name:       plot_map_PIM.m
Purpose:    Plot isomass maps
Author:     Sebastien Biass
Created:    April 2015
Updates:    April 2015
Copyright:  Sebastien Biass, University of Geneva, 2015
License:    GNU GPL3

This file is part of TephraProb

TephraProb is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TephraProb is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TephraProb.  If not, see <http://www.gnu.org/licenses/>.
%}


function plotMap(mapType)
% Type 0 = probability, 1 = isomass

% Check that you are located in the correct folder!
if ~exist(fullfile(pwd, 'tephraProb.m'), 'file')
    errordlg(sprintf('You are located in the folder:\n%s\nIn Matlab, please navigate to the root of the TephraProb\nfolder, i.e. where tephraProb.m is located. and try again.', pwd), ' ')
    return
end

% Load preference file
load(['CODE', filesep, 'VAR', filesep, 'prefs'], 'prefs');

% Load project file
project = load_run;
if project.run_pth == -1
    return
end

% Check that simulations were done on a matrix
if project.grd_type == 1
    errordlg('Maps can only be produced if simulations were performed on a grid')
    return
end

% Check that dataProb.mat exists
if ~exist([project.run_pth, 'DATA/dataProb.mat'] , 'file')
    errordlg('No probability calculation found, please run post processing');
    return
end
load([project.run_pth, 'DATA/dataProb.mat'] , 'dataProb')

if ~isfield(dataProb, 'massT')
    errordlg('No probability calculation found, please run post processing');
    return
end

% Case 1: Probability map
if mapType == 0
    md      = 'prob';
    thresh  = dataProb.massT';
    unit    = ' kg/m2';
    ylab    = 'Probability of tephra accumulation';
    ctVal   = prefs.maps.prob_contour;
    minVal  = prefs.maps.min_prob;
    cmapV   = prefs.maps.prob_cmap;
    cmap    = prefs.cmap{cmapV};
% Case 2: Isomass maps
elseif mapType == 1
    md      = 'IM';
    thresh  = dataProb.probT'; 
    unit    = ' %';
    ylab    = 'Tephra accumulation (kg m^-^2)';
    ctVal   = prefs.maps.mass_contour;
    minVal  = prefs.maps.min_mass;
    cmapV   = prefs.maps.mass_cmap;
    cmap    = prefs.cmap{cmapV};
end

% Create the list of files
seas    = fieldnames(dataProb.(md));
threshT = cellstr(num2str(thresh));
threshT = cellfun(@(c)[' ' strtrim(c) unit],threshT,'uni',false);
[a, b]  = ndgrid(1:numel(seas),1:numel(threshT));
str     = strcat(seas(a(:)), threshT(b(:)));

s       = listdlg('PromptString','Select one or multiple files to plot:',...
                'SelectionMode','multiple',...
                'ListString',str);
% Check output
if isempty(s); return; end 

fprintf('_____________________________________________________________________________________________\n');
fprintf('To save all opened maps to the MAPS/ folder of your project, type:\n')
fprintf('\t  >> saveAllMaps(format)\n\twhere format can be ''png'', ''eps'' or ''pdf''.\n')
fprintf('_____________________________________________________________________________________________\n')

% Load grid
XX      = load(['GRID', filesep, project.grd_pth, filesep, project.grd_pth, '_lon.dat']);
YY      = load(['GRID', filesep, project.grd_pth, filesep, project.grd_pth, '_lat.dat']);
res     = (XX(1,2)-XX(1,1))/2;
[vent_lat, vent_lon] = utm2ll(project.vent.east, project.vent.north, project.vent.zone);

for i = 1:length(s)

    % Retrieve index of name file into matrix
    strParts = strsplit(str{s(i)});
    seasI    = strcmp(seas, strParts{1});
    threshI  = thresh == str2double(strParts{2});
    file     = dataProb.(md).(seas{seasI})(:,:,threshI);

    file(file<minVal) = nan; % Remove min masses for display
    
    % Prepare map title
    figData.pth  = project.run_pth;
    figData.name = project.run_name;
    figData.fl   = strrep(str{s(i)}, ' ' ,'_');
    figData.fl   = strrep(figData.fl, '/' ,'_');
    figData.md   = md;
    
    % Plot
    figure('Name',str{s(i)}, 'UserData', figData);    
    ax = axes;
    % If log isomass
    if mapType == 1 && prefs.maps.mass_log == 1
        hd = pcolor(XX-res,YY-res,log10(file)); shading flat; hold on;
    else
        hd = pcolor(XX-res,YY-res,file); shading flat; hold on;
    end
    
    % Colormap: makes sure than parula, HSV and jet are plotted in normal
    % way, else invert
    if cmapV <= 3
        colormap(cmap);
    else
        colormap(flipud(eval(cmap)));
    end
    
    [c,h]       = contour(XX,YY,file,ctVal, 'Color', 'k');
    if prefs.maps.plot_labels == 1
        clabel(c,h, ctVal, 'LabelSpacing', 1000, 'FontWeight', 'bold')
    end
    set(hd, 'FaceAlpha', 0.5)

    % Define scaling
    if mapType == 1 && prefs.maps.scale_pim == 1 && prefs.maps.mass_log == 0
       caxis([prefs.maps.mass_contour(1), prefs.maps.mass_contour(end)]); 
    elseif mapType == 1 && prefs.maps.scale_pim == 1 && prefs.maps.mass_log == 1
        caxis([log10(prefs.maps.mass_contour(1)), log10(prefs.maps.mass_contour(end))]); 
    elseif mapType == 1 && prefs.maps.scale_pim == 0 && prefs.maps.mass_log == 1
        caxis([log10(prefs.maps.min_mass), log10(max(max(file)))]); 
    elseif mapType == 0 && prefs.maps.scale_prob == 1
       caxis([prefs.maps.prob_contour(1), prefs.maps.prob_contour(end)]); 
    end
   
    
    % Tidies season labels
    if  mapType == 0; ttlLab = 'Probability map - ';
    else ttlLab = 'Probabilistic isomass map - ';
    end
    
    for iS = 1:length(project.seasons)
        if ~isempty(regexp(str{s(i)}, project.seasons{iS}, 'once'))
            ttl = [ttlLab, strrep(str{s(i)}, project.seasons{iS}, project.seasons_tag{iS})];
        end
    end

    title({project.run_name; ttl},'Interpreter', 'none');
    xlabel('Longitude');
    ylabel('Latitude');
    c = colorbar;
    ylabel(c, ylab, 'FontSize', ax.XLabel.FontSize);
    
    % Adjust color ramp
    % Make sure that the lowest tephra accumulation is labeled
    if mapType == 1 && prefs.maps.mass_log == 0 && c.Ticks(1) > prefs.maps.min_mass
        c.Limits(1)  = prefs.maps.min_mass;
        c.Ticks      = [prefs.maps.min_mass, c.Ticks];
    elseif mapType == 1 && prefs.maps.mass_log == 1
        c.Ticks      = log10(prefs.maps.mass_contour);
        c.TickLabels = cellfun(@strtrim, cellstr(num2str(prefs.maps.mass_contour')), 'UniformOutput', false);
    end
    
    
    %% Extra plotting
    % Plot google backgroud
    plot_google_map('maptype', 'terrain', 'MapScale', 1);
    
    % Plot vent
    plot(vent_lon, vent_lat, '^k', 'LineWidth', 1, 'MarkerFaceColor', 'r', 'MarkerSize', 15);
    
    % Plot locations of hazard curves
    if prefs.maps.plot_pointC == 1 && isfield(dataProb, 'points')
        plot(dataProb.points.lon, dataProb.points.lat, '.k', 'MarkerSize', 6);
        if prefs.maps.plot_labC == 1
            text(dataProb.points.lon, dataProb.points.lat, dataProb.points.name, 'FontSize', 8)
        end
    end
    
    % Plot grid extent
    if prefs.maps.plot_extent == 1
        gX = [XX(1,1), XX(1,end), XX(end,end), XX(end,1), XX(1,1)];
        gY = [YY(1,1), YY(1,end), YY(end,end), YY(end,1), YY(1,1)];
        plot(gX, gY, '-r', 'linewidth',0.5);
    end
    set(gca, 'Layer', 'top');
    
end
