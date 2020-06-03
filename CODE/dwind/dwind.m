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

Name:       dwind.m
Purpose:    Download Reanalysis wind data
Author:     Sebastien Biass
Created:    February 2017
Updates:    February 2017 
                - Changed access strategy to get NOAA data, now downloads
                entire years on the entire grid and subsets/interpolates at
                post-processing. Although slower to download, files are
                preserved if same years need to be accessed
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


function dwind(varargin)
% function DWIND(varargin)
%   Opens the GUI for downloading wind
%   
% DWIND(lat, lon, startMonth, endMonth, startYear, endYear, name, dataset)
%   Download wind from the command line
%       lat, lon      : Target coordinates (decimal degrees, WGS84)
%       start/endMonth: Start and end months (1-12)
%       start/endYear : Start and end years (e.g. 2019)
%       name          : Name of output file (string)
%       dataset       : Reanalysis dataset to retrieve, accepts 'Reanalysis1', 'Reanalysis2', 'Interim', 'ERA5'
%
% Optional arguments:
%       'intMeth'     : Interpolation method, accepts 'Linear' (default), 'Nearest', 'Pchip', 'Cubic', 'Spline'
%       'intExt'      : Number of cells (�x, �y) around vent used for interpolation (default: 2)
%       'outDir'      : Output folder (default = windName)

if nargin==0
    dwindGUI;
else
    % Required values
    wind.lat    = num2str(varargin{1});
    wind.lon    = num2str(varargin{2});
    wind.mt_s   = num2str(varargin{3});
    wind.mt_e   = num2str(varargin{4});
    wind.yr_s   = num2str(varargin{5});
    wind.yr_e   = num2str(varargin{6});
    wind.name   = varargin{7};
    wind.db     = varargin{8};
    
    % Default values
    wind.meth   = 'linear';
    wind.int_ext= 2;
    wind.folder = wind.name;
    
    % Go through varargin
    % Interpolation method
    if ~isempty(findCell(varargin, 'intMeth'))                               
        wind.meth = varargin{findCell(varargin, 'intMeth')+1};  
    end
    if ~isempty(findCell(varargin, 'intExt'))                               
        wind.int_ext = varargin{findCell(varargin, 'intExt')+1};  
    end
    if ~isempty(findCell(varargin, 'outDir'))                               
        wind.folder = varargin{findCell(varargin, 'outDir')+1};  
    end
    
    download(wind);
end

function dwindGUI
% Check that you are located in the correct folder!
if ~exist(fullfile(pwd, 'tephraProb.m'), 'file')
    errordlg(sprintf('You are located in the folder:\n%s\nIn Matlab, please navigate to the root of the TephraProb\nfolder, i.e. where tephraProb.m is located. and try again.', pwd), ' ')
    return
end

global yrs mts ;     % Strings for popup menus

%%%%%%%%%%%%%%%%%%%%%%%
scr = get(0,'ScreenSize');
wd   = 500;
h    = 400;
w.fig = figure(...
    'position', [scr(3)/2-wd/2 scr(4)/2-h/2 wd h],...
    'Color', [.25 .25 .25],...
    'Resize', 'off',...
    'Tag', 'Configuration',...
    'Toolbar', 'none',...
    'Menubar', 'none',...
    'Name', 'TephraProb: dWind',...
    'NumberTitle', 'off');

% Menu
w.menu = uimenu(w.fig, 'Label', 'File');
    w.m11 = uimenu(w.menu, 'Label', 'Load', 'Accelerator', 'O');

w.wind1 = uipanel(...
    'units', 'normalized',...
    'position', [.025 .025 .95 .95],...
    'title', 'Download atmospheric data',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.9 .5 0],...
    'HighlightColor', [.9 .5 0],...
    'BorderType', 'line');

% Coordinates
w.wind2 = uipanel(...
    'Parent', w.wind1,...
    'units', 'normalized',...
    'position', [.03 .7 .94 .27],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.5 .5 .5],...
    'HighlightColor', [.3 .3 .3],...
    'Title', 'Spatial extent',...
    'BorderType', 'line');

w.wind2_text_lat = uicontrol(...
    'parent', w.wind2,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.05 .6 .2 .2],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Latitude:',...
    'Tooltip', 'Decimal degrees. Positive in N hemisphere, negative in S hemisphere');

w.wind2_text_lon = uicontrol(...
    'parent', w.wind2,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.05 .2 .2 .2],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Longitude:',...
    'Tooltip', 'Decimal degrees. Positive in E hemisphere, negative in W hemisphere');

w.wind2_lat = uicontrol(...
    'parent', w.wind2,...
    'style', 'edit',...
    'unit', 'normalized',...
    'position', [.225 .55 .2 .3],...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', [1 1 1],...
    'BackgroundColor', [.35 .35 .35],...
    'Tooltip', 'Decimal degrees. Positive in N hemisphere, negative in S hemisphere');


w.wind2_lon = uicontrol(...
    'parent', w.wind2,...
    'style', 'edit',...
    'unit', 'normalized',...
    'position', [.225 .15 .2 .3],...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', [1 1 1],...
    'BackgroundColor', [.35 .35 .35],...
    'Tooltip', 'Decimal degrees. Positive in E hemisphere, negative in W hemisphere');

w.wind2_text_ext = uicontrol(...
    'parent', w.wind2,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.475 .6 .2 .2],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Subset:',...
    'Tooltip', sprintf('Number of grid points used in each direction to interpolate on the vent coordinates.\nFor instance, 2 implies the interpolation of a 4x4 matrix on the central point.'));

w.wind2_ext = uicontrol(...
    'parent', w.wind2,...
    'style', 'edit',...
    'unit', 'normalized',...
    'position', [.645 .55 .2 .3],...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', [1 1 1],...
    'BackgroundColor', [.35 .35 .35],...
    'String', '2',...
    'Tooltip', sprintf('Number of grid points used in each direction to interpolate on the vent coordinates.\nFor instance, 2 implies the interpolation of a 4x4 matrix on the central point.'));


w.wind2_text_int = uicontrol(...
    'parent', w.wind2,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.475 .2 .2 .2],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Interpolation:',...
    'Tooltip', 'Interpolation method');

w.wind2_int = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind2,...
    'units', 'normalized',...
    'position', [.643 .25 .3 .15],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'Tag', 'int_meth',...
    'String', {'Linear', 'Nearest', 'Pchip', 'Cubic', 'Spline'},...
    'Tooltip', 'Interpolation method');

% Time range
w.wind3 = uipanel(...
    'Parent', w.wind1,...
    'units', 'normalized',...
    'position', [.03 .04 .55 .37],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.5 .5 .5],...
    'HighlightColor', [.3 .3 .3],...
    'Title', 'Time range',...
    'BorderType', 'line');

w.wind3_start = uicontrol(...
    'parent', w.wind3,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.32 .8 .25 .15],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Start');

w.wind3_end = uicontrol(...
    'parent', w.wind3,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.62 .8 .25 .15],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'End');

% Sets years
yr  = datevec(now); yr = yr(1);
yrs = arrayfun(@num2str, 1949:yr, 'UniformOutput', false);
mts = arrayfun(@num2str, 1:12, 'UniformOutput', false);

w.wind3_s_year = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind3,...
    'units', 'normalized',...
    'position', [.35 .57 .285 .15],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'Tag', 'year_start',...
    'String', yrs);

w.wind3_e_year = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind3,...
    'units', 'normalized',...
    'position', [.65 .57 .285 .15],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'Tag', 'year_end',...
    'String', yrs);

w.wind3_year = uicontrol(...
    'parent', w.wind3,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.075 .55 .25 .15],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Year:');

w.wind3_s_month = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind3,...
    'units', 'normalized',...
    'position', [.35 .27 .285 .15],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'Tag', 'month_start',...
    'String', mts);

w.wind3_e_month = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind3,...
    'units', 'normalized',...
    'position', [.65 .27 .285 .15],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'Tag', 'month_end',...
    'String', mts);

w.wind3_months = uicontrol(...
    'parent', w.wind3,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.075 .25 .25 .15],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Month:');

% Dataset type
w.wind6 = uipanel(...
    'Parent', w.wind1,...
    'units', 'normalized',...
    'position', [.03 .43 .55 .25],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.5 .5 .5],...
    'HighlightColor', [.3 .3 .3],...
    'Title', 'Dataset',...
    'BorderType', 'line');
w.wind6_dataset = uicontrol(...
    'Style', 'popupmenu',...
    'Parent', w.wind6,...
    'units', 'normalized',...
    'position', [.1 .2 .8 .3],...
    'ForegroundColor', [.75 .75 .75],...
    'BackgroundColor', [.35 .35 .35],...
    'String', {'NOAA Reanalysis 1', 'NOAA Reanalysis 2', 'ECMWF ERA-Interim', 'ECMWF ERA5', 'ECMWF ERA-Interim (offline)', 'ECMWF ERA5 (offline)'});

%     'String', {'NOAA Reanalysis 1', 'NOAA Reanalysis 2', 'ECMWF ERA-Interim', 'ECMWF ERA-5', 'ECMWF ERA-Interim (offline)', 'ECMWF ERA-5 (offline)'});

w.wind6_txt = uicontrol(...
    'parent', w.wind6,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.1 .6 .8 .3],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Reanalysis dataset:');

% Name
w.wind4 = uipanel(...
    'Parent', w.wind1,...
    'units', 'normalized',...
    'position', [.61 .43 .36 .25],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.5 .5 .5],...
    'HighlightColor', [.3 .3 .3],...
    'Title', 'Output',...
    'BorderType', 'line');

w.wind4_txt = uicontrol(...
    'parent', w.wind4,...
    'style', 'text',...
    'units', 'normalized',...
    'position', [.1 .65 .8 .25],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [1 1 1],...
    'String', 'Output name:');

w.wind4_name = uicontrol(...
    'parent', w.wind4,...
    'style', 'edit',...
    'unit', 'normalized',...
    'position', [.1 .25 .8 .35],...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', [1 1 1],...
    'BackgroundColor', [.35 .35 .35]);

w.wind5 = uipanel(...
    'Parent', w.wind1,...
    'units', 'normalized',...
    'position', [.61 .04 .36 .35],...
    'BackgroundColor', [.25 .25 .25],...
    'ForegroundColor', [.5 .5 .5],...
    'HighlightColor', [.3 .3 .3],...
    'BorderType', 'line');


w.wind5_but_download = uicontrol(...
    'parent', w.wind5,...
    'Style', 'pushbutton',...
    'units', 'normalized',...
    'position', [.05 .05 .9 .9],...
    'BackgroundColor', [.3 .3 .3],...
    'ForegroundColor', [.9 .5 .0],...
    'String', 'Download');

set(w.wind5_but_download, 'callback', {@but_wind5_download, w})
set(w.wind6_dataset, 'callback', {@but_wind6_dataset,w});
set(w.m11, 'callback', {@load_wind, w})

% Adapt display accross plateforms
set_display

function load_wind(~,~,w)
% Select run file
[flname, flpath] = uigetfile('WIND/*.mat', 'Select a WIND file to open');
tmp = load(fullfile(flpath, flname));
wind = tmp.wind;

db = {'Reanalysis1', 'Reanalysis2', 'Interim', 'ERA5', 'InterimOff', 'ERA5Off'};

w.wind2_lat.String      = wind.lat;
w.wind2_lon.String      = wind.lon;
w.wind2_ext.String      = num2str(wind.int_ext);
w.wind2_int.Value       = find(strcmp(w.wind2_int.String,wind.meth)==1);
w.wind6_dataset.Value   = find(strcmp(db,wind.db)==1);
w.wind4_name.String     = wind.name;
w.wind3_s_year.Value    = find(strcmp(w.wind3_s_year.String,wind.yr_s)==1);
w.wind3_e_year.Value    = find(strcmp(w.wind3_e_year.String,wind.yr_e)==1);
w.wind3_s_month.Value   = find(strcmp(w.wind3_s_month.String,wind.mt_s)==1);
w.wind3_e_month.Value   = find(strcmp(w.wind3_e_month.String,wind.mt_e)==1);

function but_wind6_dataset(hObject,~,w)
set(findobj('tag', 'year_start'), 'Value', 1);
set(findobj('tag', 'year_end'), 'Value', 1);
yr  = datevec(now); yr = yr(1);
if get(hObject, 'Value') == 1       % Reanalysis 1
    yrs = arrayfun(@num2str, 1949:yr, 'UniformOutput', false);   
else          % Reanalysis 2 or ERA-Interim
    yrs = arrayfun(@num2str, 1979:yr, 'UniformOutput', false);
end

if get(hObject, 'Value') >= 5       % If processing offline ERA-Interim
    set(w.wind5_but_download, 'String', 'Process');
    set(w.wind3_s_year, 'Enable', 'off');
    set(w.wind3_e_year, 'Enable', 'off');
    set(w.wind3_s_month, 'Enable', 'off');
    set(w.wind3_e_month, 'Enable', 'off');
else
    set(w.wind5_but_download, 'String', 'Download');
    set(w.wind3_s_year, 'Enable', 'on');
    set(w.wind3_e_year, 'Enable', 'on');
    set(w.wind3_s_month, 'Enable', 'on');
    set(w.wind3_e_month, 'Enable', 'on');
end
        
set(findobj('tag', 'year_start'), 'String', yrs);
set(findobj('tag', 'year_end'), 'String', yrs);

% Function for DOWNLOAD button in main panel
function w =  but_wind5_download(~, ~, w)
global mts     % Strings for popup menus
global wind yrs
%load(fl2l);

if isempty(get(w.wind4_name, 'String')) || isempty(get(w.wind2_lon, 'String')) || isempty(get(w.wind2_lat, 'String'))
    errordlg('Please fill up all fields', ' ');
    return
end

yrs = findobj('tag', 'year_start');
yrs = get(yrs, 'String');
% Retrieve data and stores it in a structure
wind = struct;

wind.lat     = get(w.wind2_lat, 'String');
wind.lon     = get(w.wind2_lon, 'String');
wind.name    = get(w.wind4_name, 'String');

db           = {'Reanalysis1', 'Reanalysis2', 'Interim', 'ERA5', 'InterimOff', 'ERA5Off'};
wind.db      = db{get(w.wind6_dataset, 'Value')};
wind.int_ext = str2double(get(w.wind2_ext, 'String'));
meth         = {'Linear', 'Nearest', 'Pchip', 'Cubic', 'Spline'};
wind.meth    = meth{get(w.wind2_int, 'Value')};

wind.yr_s    = yrs{get(w.wind3_s_year, 'Value')};
wind.yr_e    = yrs{get(w.wind3_e_year, 'Value')};
wind.mt_s    = mts{get(w.wind3_s_month, 'Value')};
wind.mt_e    = mts{get(w.wind3_e_month, 'Value')};
wind.folder  = fullfile('WIND', wind.name);

download(wind);

function download(wind)
% Define extent
if strcmp(wind.db, 'Interim') || strcmp(wind.db, 'InterimOff') || strcmp(wind.db, 'ERA5')|| strcmp(wind.db, 'ERA5Off')
    interv = 0.25;
else
    interv = 2.5;
end
lat_vec    = -90:interv:90; 
lon_vec    = 0:interv:360-interv;

% If the vent latitude is expressed as negative, correct it to degrees E
if str2double(wind.lon) < 0; wind.lon = num2str(360+str2double(wind.lon)); end

wind.lat_min = lat_vec(nnz(lat_vec<str2double(wind.lat)) - wind.int_ext + 1);
wind.lat_max = lat_vec(nnz(lat_vec<str2double(wind.lat)) + wind.int_ext);

wind.lon_min = lon_vec(nnz(lon_vec<str2double(wind.lon)) - wind.int_ext + 1);
wind.lon_max = lon_vec(nnz(lon_vec<str2double(wind.lon)) + wind.int_ext);



% Create folder
if exist(wind.folder, 'dir') == 7
    choice = questdlg('This name is already taken. Overwrite?', ...
        '', 'Yes','No','No');
    switch choice
        case 'Yes'
            rmdir(wind.folder, 's');
        case 'No'
            return
    end
end

mkdir(wind.folder);
mkdir(fullfile(wind.folder, 'nc'));
mkdir(fullfile(wind.folder, 'ascii'));

% In case ERA offline, retrieve netcdf files
if strcmp(wind.db, 'InterimOff') || strcmp(wind.db, 'ERA5Off')
    fprintf('Select folder containing the ERA-Interim .nc files\n');
    wind.ncDir = uigetdir( ...
    'Select folder containing the ERA-Interim .nc files');
end

save(fullfile(wind.folder, 'wind.mat'),'wind')


%% DOWNLOAD DATA
%% ERA-INTERIM
if strcmp(wind.db, 'Interim') || strcmp(wind.db, 'ERA5')

    if strcmp(wind.db, 'Interim')        
        txt     = fileread('download_ECMWF_tmp.py');
        txt_new = strrep(txt, 'ECMWFclass', 'ei');
        txt_new = strrep(txt_new, 'ECMWFdataset', 'interim');
    elseif strcmp(wind.db, 'ERA5')
        txt     = fileread('download_ERA5_tmp.py');
        txt_new = txt;
    end
    
    txt_new = strrep(txt_new, 'var_year_start', wind.yr_s);
    txt_new = strrep(txt_new, 'var_year_end', wind.yr_e);
    txt_new = strrep(txt_new, 'var_month_start', wind.mt_s);
    txt_new = strrep(txt_new, 'var_month_end', wind.mt_e);
    txt_new = strrep(txt_new, 'var_north', num2str(wind.lat_max));
    txt_new = strrep(txt_new, 'var_south', num2str(wind.lat_min));
    txt_new = strrep(txt_new, 'var_west', num2str(wind.lon_min));
    txt_new = strrep(txt_new, 'var_east', num2str(wind.lon_max));
    txt_new = strrep(txt_new, 'var_out', strrep([wind.folder, filesep, 'nc', filesep], '\', '/'));

    
    fid = fopen('download_ECMWF.py', 'w');
    fprintf(fid, '%s', txt_new);
    fclose(fid);
    
    !python download_ECMWF.py
    
    delete('download_ECMWF.py');
    
% Offline mode
elseif strcmp(wind.db, 'InterimOff')
    
%% NOAA
else
    % Work on input coordinates
    if wind.lon_min < 0; wind.lon_min = 360+wind.lon_min; end
    if wind.lon_max < 0; wind.lon_max = 360+wind.lon_max; end
    
    % Reanalysis
    %  - Now downloads worldwide files per year, and the zone extration is
    %    done during post processing. The download time is longer, but files
    %    are preserved, so donwload is skipped if the file already exists.
    %  - Now works the same for Reanalysis 1 and 2
    
    
    if strcmp(wind.db, 'Reanalysis1')
        target_dir = 'WIND/_Reanalysis1_Rawdata/';
        ftp_dir    = 'Datasets/ncep.reanalysis/pressure/';
        if ~exist('WIND/_Reanalysis1_Rawdata/', 'dir'); mkdir('WIND/_Reanalysis1_Rawdata/'); end
    elseif strcmp(wind.db, 'Reanalysis2')
        target_dir = 'WIND/_Reanalysis2_Rawdata/';
        ftp_dir    = 'Datasets/ncep.reanalysis2/pressure/';
        if ~exist('WIND/_Reanalysis2_Rawdata/', 'dir'); mkdir('WIND/_Reanalysis2_Rawdata/'); end
    else
        error('Unknown dataset requested')
    end
    
    disp('Connecting to NOAA... (That can take time, go have a coffee!)')
    
    % Files are now preserved in the folder Reanalyisi_data/
    if ~exist(target_dir, 'dir')
        mkdir(target_dir);
    end
    
    varList = {'hgt', 'uwnd', 'vwnd'}; % List of variables to download
    
    for iV = 1:length(varList)
        for iY = str2double(wind.yr_s):str2double(wind.yr_e)
            fl = [varList{iV}, '.', num2str(iY), '.nc'];
            if exist([target_dir, fl], 'file')     % If the file exists
                fprintf('\t%s already exists, skipping download...\n', fl)
            else                                                        % Else request ftp
                fprintf('\tDownloading %s, please wait...\n', fl)
                ftpobj  = ftp('ftp.cdc.noaa.gov');
                cd(ftpobj, ftp_dir);
                mget(ftpobj, fl, target_dir);
            end
        end
        
    end
    disp('Done!');
end

process_wind(wind)

% Finds the cell index of a string in a cell array
function idx = findCell(cell2find, str2find)
cell2find   = cellfun(@num2str, cell2find, 'UniformOutput', false);
%[~,idx]     = find(not(cellfun('isempty', strfind(cell2find, str2find)))==1);
idx     = find(not(cellfun('isempty', strfind(cell2find, str2find))),1);
