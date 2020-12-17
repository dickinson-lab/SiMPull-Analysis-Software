function varargout = trace_inspector_GUI(varargin)
% TRACE_INSPECTOR_GUI MATLAB code for trace_inspector_GUI.fig
%      TRACE_INSPECTOR_GUI, by itself, creates a new TRACE_INSPECTOR_GUI or raises the existing
%      singleton*.
%
%      H = TRACE_INSPECTOR_GUI returns the handle to a new TRACE_INSPECTOR_GUI or the handle to
%      the existing singleton*.
%
%      TRACE_INSPECTOR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACE_INSPECTOR_GUI.M with the given input arguments.
%
%      TRACE_INSPECTOR_GUI('Property','Value',...) creates a new TRACE_INSPECTOR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trace_inspector_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trace_inspector_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trace_inspector_GUI

% Last Modified by GUIDE v2.5 17-Dec-2020 07:45:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trace_inspector_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @trace_inspector_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before trace_inspector_GUI is made visible.
function trace_inspector_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trace_inspector_GUI (see VARARGIN


% Choose default command line output for trace_inspector_GUI
handles.output = hObject;

%Get the data from the spot counter              
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the step counter');
load([matPath filesep matFile]);

if nChannels > 1
    channel = questdlg('Multi-Channel Data Found. Select Channel to Display',...
                       'Select Channel',...
                       channels{:},channels{1});
else
    channel = channels{1};
end

if ~isfield(statsByColor, [channel 'StepHist'])
    msgbox('This program requires photobleaching step data.  Please run the step counter first');
    return
end


%Set up figure window
handles.screenSize = get(0,'ScreenSize');
figureWidth = 650;
figureHeight = 650;
set(handles.figureWindow,'Units','pixels','Position',[(handles.screenSize(3)-figureWidth)/2 handles.screenSize(4)-figureHeight-100 figureWidth figureHeight]);
set(handles.instructionText,'Units','pixels','Position',[(figureWidth-260) (figureHeight-70) 250 60]);
set(handles.extractButton,'Units','pixels','Position',[(figureWidth-260) (figureHeight-85) 150 30]);
set(handles.infoButton,'Units','pixels','Position',[(figureWidth-260) (figureHeight-120) 150 30]);
set(handles.saveButton,'Units','pixels','Position',[(figureWidth-260) (figureHeight-155) 150 30]);
set(handles.countMenu,'Units','pixels','Position',[30 (figureHeight-50) 150 25]);
set(handles.radioButtonPanel,'Units','pixels','Position',[30 (figureHeight-120) 180 65]);
set(handles.axes1,'Units','pixels','Position',[75 50 500 400]);
set(handles.axes2,'Units','pixels','Position',[75 50 500 400]);
set(handles.stepCountText,'Units','pixels','Position',[200 460 200 20]);

%Prepare Data
for b = 1:length(gridData)
    index2(b) = isfield(gridData(b).([channel 'SpotData']),'nSteps');
end
index2 = logical(index2);
spotData = {gridData(index2).([channel 'SpotData'])};
handles.spotData = vertcat(spotData{ cellfun(@length, spotData) > 1 }); % The argument inside {} tosses images with no spots
clear gridData spotData
handles.activeSpotData = handles.spotData;
handles.nTraces = length(handles.spotData);
handles.tmax = length(handles.spotData(1).intensityTrace);
handles.arrayPos = 1;

%Test whether step data has been filtered (required for displaying data processed with older versions)
if ~isfield(handles.activeSpotData(1), 'allchangepoints')
    handles.showChangepoints = 'changepoints';
    set(handles.allChangepointsButton, 'Enable', 'off');
    set(handles.acceptedChangepointsButton, 'Enable', 'off');
else
    handles.showChangepoints = 'allchangepoints';
end

%Plot the First Trajectory
b = 1;
handles = updatePlot(b,handles);

%Set initial count of trajectories dumped
handles.dumped = 1;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes trace_inspector_GUI wait for user response (see UIRESUME)
% uiwait(handles.figureWindow);


% --- Outputs from this function are returned to the command line.
function varargout = trace_inspector_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on selection change in countMenu.
function countMenu_Callback(hObject, eventdata, handles)
% hObject    handle to countMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns countMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from countMenu
selection = get(hObject,'Value');
counts = {handles.spotData.nSteps};

%Update active traces to the selection
if selection == 1  %All Traces
    index = true(1,handles.nTraces);
elseif selection == 2  %Rejected Traces
    index = strcmp(counts,'Rejected');
else   %0-10 Steps
    index = cellfun(@(x) any(x(:)==(selection-3)),counts);
end   
handles.activeSpotData = handles.spotData(index,:);
handles.nTraces = length(handles.activeSpotData);
handles.tmax = length(handles.spotData(1).intensityTrace);
handles.arrayPos = 1;

%Update plot
if handles.nTraces > 0
    b = 1;
    handles = updatePlot(b, handles);
else
    cla(handles.axes1);
    cla(handles.axes2);
    set(handles.stepCountText,'String',['No trajectories with ', num2str(selection-3), ' Steps']);
end

% Update handles structure
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function countMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to countMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'All Traces', 'Rejected Traces', 'Traces with 0 Steps', 'Traces with 1 Step', 'Traces with 2 Steps', 'Traces with 3 Steps', 'Traces with 4 Steps', 'Traces with 5 Steps', 'Traces with 6 Steps', 'Traces with 7 Steps', 'Traces with 8 Steps', 'Traces with 9 Steps', 'Traces with 10 Steps'});


function handles = updatePlot(b, handles)
%Generate the Fit for the New Trajectory
if isempty(handles.activeSpotData(b).changepoints)
    nChangepoints = 0;
else
    [nChangepoints, ~] = size(handles.activeSpotData(b).changepoints);
end
lastchangepoint = 1;
traj = handles.activeSpotData(b).intensityTrace;
tmax = length(traj);
fit = zeros(1,tmax);
for a = 1:nChangepoints+1
    if a>nChangepoints
        changepoint = tmax;
    else 
        changepoint = handles.activeSpotData(b).changepoints(a,1);
    end
    if changepoint == 0
        continue
    end
    try
        fit(lastchangepoint:changepoint) = handles.activeSpotData(b).steplevels(a);
    catch
        fit(lastchangepoint:changepoint) = handles.activeSpotData(b).steplevels(end); %Protects against having too few step levels because a changepoint was rejected
    end
    lastchangepoint = changepoint+1; %"+1" just keeps the segments from overlapping
end

bars = zeros(tmax,1);
if ~isempty(handles.activeSpotData(b).(handles.showChangepoints))
    bars(handles.activeSpotData(b).(handles.showChangepoints)(:,1)) = handles.activeSpotData(b).(handles.showChangepoints)(:,2);
end

%Plot the New Trajectory
xaxis = 1:length(traj);
if nChangepoints > 0
    bar(handles.axes1,xaxis,bars,'FaceColor',[0 0.5 0],'EdgeColor','none','Barwidth',0.5);
else
    cla(handles.axes1);
end
set(handles.axes1,'YAxisLocation','right','Box','off','YColor',[0 0.5 0],'xlim',[0 tmax]);
ylabel(handles.axes1,'Changepoint Log Odds');  
plot(handles.axes2,xaxis,traj);
set(handles.axes2,'Nextplot','add');
plot(handles.axes2,xaxis,fit,'r','LineWidth',3);
ylabel(handles.axes2,'Fluorescence Intensity');  
set(handles.axes2,'Color','none','Box','off','Nextplot','replace','xlim',[0 tmax]);

if ischar(handles.activeSpotData(b).nSteps)
    set(handles.stepCountText,'String','Trace Rejected')
elseif handles.activeSpotData(b).nSteps == 1
    set(handles.stepCountText,'String','1 Step');
else    
    set(handles.stepCountText,'String',[num2str(handles.activeSpotData(b).nSteps), ' Steps']);
end

% --- Executes on key press with focus on figureWindow or any of its controls.
function figureWindow_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figureWindow (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

%Decide what to do
if isempty(handles.activeSpotData)
    return
end
b = handles.arrayPos;
if strcmp(eventdata.Key, 'n')
    b = b+1;
elseif strcmp(eventdata.Key, 'p')
    b = b-1;
elseif strcmp(eventdata.Key, 'r')
    b=round(rand(1)*handles.nTraces);
end
if b<1 
    b=handles.nTraces; 
end
if b>handles.nTraces 
    b=1; 
end
handles.arrayPos = b;
handles = updatePlot(b, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in extractButton.
function extractButton_Callback(hObject, eventdata, handles)
% hObject    handle to extractButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
b = handles.arrayPos;
traj = handles.activeSpotData(b).intensityTrace;
varname = ['traj' num2str(handles.dumped)];
assignin('base',varname,traj);
handles.dumped = handles.dumped + 1;

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in infoButton.
function infoButton_Callback(hObject, eventdata, handles)
% hObject    handle to infoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
b = handles.arrayPos;
handles.activeSpotData(b)


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figureWidth = 650;
figureHeight = 500;
newfig1 = figure('Units','pixels','Position',[(handles.screenSize(3)-figureWidth)/2 handles.screenSize(4)-figureHeight-100 figureWidth figureHeight],'Visible','off'); 
copyobj(handles.axes1, newfig1);
copyobj(handles.axes2, newfig1);

[outfile,outpath] = uiputfile('plot.pdf','Save File Name');
if verLessThan('matlab','9.8')
    export_fig([outpath filesep outfile],newfig1,'-pdf','-png','-transparent');
else
    exportgraphics(newfig1,[outpath filesep outfile]);
end
close(newfig1);



% --- Executes when selected object is changed in radioButtonPanel.
function radioButtonPanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in radioButtonPanel 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag')
    case 'allChangepointsButton'
        handles.showChangepoints = 'allchangepoints';
    case 'acceptedChangepointsButton'
        handles.showChangepoints = 'changepoints';
end
b = handles.arrayPos;
handles = updatePlot(b, handles);

% Update handles structure
guidata(hObject, handles);
