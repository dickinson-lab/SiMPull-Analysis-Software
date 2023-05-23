%Inspector for automated spotcount program

function varargout = spotcount_inspector_GUI(varargin)
% SPOTCOUNT_INSPECTOR_GUI MATLAB code for spotcount_inspector_GUI.fig
%      SPOTCOUNT_INSPECTOR_GUI, by itself, creates a new SPOTCOUNT_INSPECTOR_GUI or raises the existing
%      singleton*.
%
%      H = SPOTCOUNT_INSPECTOR_GUI returns the handle to a new SPOTCOUNT_INSPECTOR_GUI or the handle to
%      the existing singleton*.
%
%      SPOTCOUNT_INSPECTOR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPOTCOUNT_INSPECTOR_GUI.M with the given input arguments.
%
%      SPOTCOUNT_INSPECTOR_GUI('Property','Value',...) creates a new SPOTCOUNT_INSPECTOR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before spotcount_inspector_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to spotcount_inspector_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help spotcount_inspector_GUI

% Last Modified by GUIDE v2.5 04-Aug-2016 14:56:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @spotcount_inspector_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @spotcount_inspector_GUI_OutputFcn, ...
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


% --- Executes just before spotcount_inspector_GUI is made visible.
function spotcount_inspector_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spotcount_inspector_GUI (see VARARGIN)

% Choose default command line output for spotcount_inspector_GUI
handles.output = hObject;

%Set up variables
b=1;
handles.arrayPos = b;
handles.circle = uint16([    0,      0,      0,  65500,  65500,  65500,  65500,  65500,      0,      0,      0;
                             0,      0,  65500,      0,      0,      0,      0,      0,  65500,      0,      0;
                             0,  65500,      0,      0,      0,      0,      0,      0,      0,  65500,      0;
                         65500,      0,      0,      0,      0,      0,      0,      0,      0,      0,  65500;
                         65500,      0,      0,      0,      0,      0,      0,      0,      0,      0,  65500;
                         65500,      0,      0,      0,      0,      0,      0,      0,      0,      0,  65500;
                         65500,      0,      0,      0,      0,      0,      0,      0,      0,      0,  65500;
                         65500,      0,      0,      0,      0,      0,      0,      0,      0,      0,  65500;
                             0,  65500,      0,      0,      0,      0,      0,      0,      0,  65500,      0;
                             0,      0,  65500,      0,      0,      0,      0,      0,  65500,      0,      0;
                             0,      0,      0,  65500,  65500,  65500,  65500,  65500,      0,      0,      0]);      
 

%Load data from the spot counter and set up figure window
handles = initializeData(handles);

%Show first image 
displayImages(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spotcount_inspector_GUI wait for user response (see UIRESUME)
% uiwait(handles.figureWindow);


% --- Outputs from this function are returned to the command line.
function varargout = spotcount_inspector_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on key press with focus on figureWindow or any of its controls.
function figureWindow_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figureWindow (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

%Decide what to do
b = handles.arrayPos;
if strcmp(eventdata.Key, 'n')
    b = b+1;
elseif strcmp(eventdata.Key, 'p')
    b = b-1;
elseif strcmp(eventdata.Key, 'r')
    b=round(rand(1)*handles.nElements);
end
if b<1 
    b=handles.nElements; 
end
if b>handles.nElements 
    b=1; 
end
handles.arrayPos = b;

%Display Images
displayImages(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in greenButton.
function greenButton_Callback(hObject, eventdata, handles)
% hObject    handle to greenButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of greenButton
set(handles.redButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in redButton.
function redButton_Callback(hObject, eventdata, handles)
% hObject    handle to redButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of redButton
set(handles.greenButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in traceButton.
function traceButton_Callback(hObject, eventdata, handles)
% hObject    handle to traceButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of traceButton
set(handles.histButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in histButton.
function histButton_Callback(hObject, eventdata, handles)
% hObject    handle to histButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of histButton
set(handles.traceButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);



function displayImages(handles)
b=handles.arrayPos;
showingTraces = get(handles.traceButton,'Value');  %Determine whether to display traces or a histogram

%Get images
if handles.nChannels == 1
    color = handles.channels{1};
else
    if get(handles.greenButton,'Value')    
        color = handles.channels{1};
    else
        color = handles.channels{2};
    end
end
handles.imageName = [handles.gridData(b).imageName '_' color 'avg'];
spotCount = handles.gridData(b).([color 'SpotCount']);
if ~showingTraces
    stepHist = handles.gridData(b).([color 'StepDist']);
    stepHistXmax = handles.([color 'HistXmax']);
end

timeAvg = imread([handles.imgPath filesep handles.imageName '.tif']);
[ymax, xmax] = size(timeAvg);
timeAvg = imadjust(timeAvg,stretchlim(timeAvg,0.0005),[]);

%For historical reasons the left panel is "timeAvg" and the center panel is "filteredImage"
filteredImage = timeAvg;

%Draw circles around spots
if handles.gridData(b).([color 'SpotCount']) > 0
    spotCount = handles.gridData(b).([color 'SpotCount']);
    for a = 1:spotCount
        xcoord = handles.gridData(b).([color 'SpotData'])(a).spotLocation(1);
        ycoord = handles.gridData(b).([color 'SpotData'])(a).spotLocation(2);
        filteredImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5) = max(handles.circle, filteredImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5));
    end
end

%Set up traces panel
if showingTraces  
    if handles.gridData(b).([color 'SpotCount']) > 0 
        intensityTraces = cell(size(handles.gridData(b).([color 'SpotData'])));
        [intensityTraces{:}] = handles.gridData(b).([color 'SpotData']).intensityTrace;
        intensityTraces = cell2mat(intensityTraces);
        [spotCount, tmax] = size(intensityTraces);
        intensityRange = [min(min(intensityTraces)),max(max(intensityTraces))];
        widthOfObjects = xmax*2 + tmax*3 + 120;
        heightOfObjects = max(ymax+250,spotCount*3+200);

    else
        intensityTraces = zeros(1,handles.tmax);
        spotCount = 0;
        tmax = handles.tmax;
        intensityRange = [0, 255];
    end
    widthOfObjects = xmax*2 + tmax*3 + 120;
    heightOfObjects = max(ymax+250,spotCount*3+200);
else
    widthOfObjects = xmax*2 + 400 + 120;
    heightOfObjects = max(ymax+250,300+200);
end
    
%Resize figure window if necessary
figureWidth = min(widthOfObjects,handles.screenSize(3));
figureHeight = min(heightOfObjects,handles.screenSize(4)-100);
scaleFactor = min([1, figureWidth/widthOfObjects, figureHeight/(ymax+200)]);
imageWidth = xmax*scaleFactor;
set(handles.figureWindow,'Units','pixels','Position',[(handles.screenSize(3)-figureWidth)/2 max([100,handles.screenSize(4)-figureHeight]) figureWidth figureHeight]);
if showingTraces
    tracePanelHeight = max(1, min(spotCount*scaleFactor*3,(handles.screenSize(4)-300)));
    set(handles.tracesPanel,'Units','pixels','Position',[imageWidth*2+90*scaleFactor 80 tmax*scaleFactor*3 tracePanelHeight]);
else
    tracePanelHeight = max(1,min(300,(handles.screenSize(4)-200)));
    set(handles.tracesPanel,'Units','pixels','Position',[imageWidth*2+90*scaleFactor 80 400*scaleFactor tracePanelHeight]);
end
set(handles.traceButtonPanel,'Units','pixels','Position',[imageWidth*2+90*scaleFactor tracePanelHeight+100 200 70]);

%Show images
imshow(timeAvg,'Parent',handles.filteredImagePanel);
imshow(filteredImage,'Parent',handles.peaksFoundPanel);
if showingTraces
    imshow(intensityTraces,'DisplayRange',intensityRange,'InitialMagnification',600,'Parent',handles.tracesPanel);
else
    xvalues = (1:stepHistXmax)';
    yvalues = stepHist(1:stepHistXmax);
    bar(handles.tracesPanel,xvalues,yvalues);
end
set(handles.spotCountText,'String',['Spot Count = ' num2str(handles.gridData(b).([color 'SpotCount']))]);
set(handles.positionText,'String',['Image Number = ' num2str(b)]);


function handles = initializeData(handles)
b=1;
handles.arrayPos = b;

%Get the data from the spot counter              
if isfield(handles, 'matPath')
    [handles.matFile, handles.matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter', handles.matPath);
else
    [handles.matFile, handles.matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter');
end
load([handles.matPath filesep handles.matFile]);
%locate image folder
nameIdx = strfind(handles.matFile,'_filtered.mat');
if ~isempty(nameIdx)
    handles.imgPath = [handles.matPath handles.matFile(1:nameIdx-1)];
else
    handles.imgPath = [handles.matPath filesep handles.matFile(1:end-4)];
end

handles.gridData = gridData; clear gridData;
handles.gridSize = size(handles.gridData);
handles.nElements = handles.gridSize(1)*handles.gridSize(2);
handles.channels = channels; 
handles.nChannels = nChannels; clear nChannels;

%Get first image
firstImageName = [handles.gridData(1).imageName '_' channels{1} 'avg.tif'];
firstImage = imread([handles.imgPath filesep firstImageName]);
[ymax xmax] = size(firstImage);
tmax = length(handles.gridData(1).([channels{1} 'SpotData'])(1).intensityTrace);
handles.tmax = tmax;
spotCount = handles.gridData(1).([channels{1} 'SpotCount']);

%Set up figure window
handles.screenSize = get(0,'ScreenSize');
widthOfObjects = xmax*2 + 400 + 120;
heightOfObjects = max(ymax+200,300+150);
figureWidth = min(widthOfObjects,handles.screenSize(3));
figureHeight = min(heightOfObjects,handles.screenSize(4)-100);
scaleFactor = min([1, figureWidth/widthOfObjects, figureHeight/(ymax+200)]);
imageWidth = xmax*scaleFactor;
imageHeight = ymax*scaleFactor;
set(handles.figureWindow,'Name',handles.matFile(1:end-4),'Units','pixels','Position',[(handles.screenSize(3)-figureWidth)/2 max([100,handles.screenSize(4)-figureHeight]) figureWidth figureHeight]);
set(handles.instructionText,'Units','pixels','Position',[imageWidth+60*scaleFactor+(imageWidth-200)/2 15 250 60]);
set(handles.filteredImagePanel,'Units','pixels','Position',[30*scaleFactor 80 imageWidth imageHeight]);
set(handles.peaksFoundPanel,'Units','pixels','Position',[imageWidth+60*scaleFactor 80 imageWidth imageHeight]);
set(handles.spotCountText,'Units','pixels','Position',[imageWidth+60*scaleFactor+(imageWidth-200)/2 imageHeight+90 200 20]);
set(handles.positionText,'Units','pixels','Position',[imageWidth+60*scaleFactor+(imageWidth-200)/2 imageHeight+110 200 20]);
tracePanelHeight = min(spotCount*scaleFactor*3,(handles.screenSize(4)-200));
set(handles.tracesPanel,'Units','pixels','Position',[imageWidth*2+90*scaleFactor 80 tmax*scaleFactor*3 tracePanelHeight]);
set(handles.colorButtonPanel,'Units','pixels','Position',[30*scaleFactor imageHeight+90 200 70]); 
set(handles.tossImageButton, 'Units','pixels','Position',[(figureWidth-120)/2 imageHeight+140 120 30]);
set(handles.loadButton, 'Units','pixels','Position',[400*scaleFactor imageHeight+90 150 30]);
set(handles.traceButtonPanel,'Units','pixels','Position',[imageWidth*2+90*scaleFactor tracePanelHeight+30 200 70]);
if handles.nChannels == 1
    set(handles.greenButton,'Value', 1);
    set(handles.greenButton,'Enable','off');
    set(handles.redButton,'Enable','off');
    set(handles.colorButtonPanel,'ForegroundColor',[0.5,0.5,0.5]);
end
for a=1:handles.nChannels
    color = channels{a};
    if isfield(statsByColor, [color 'StepHist'])
        handles.([color 'HistXmax']) = find(statsByColor.([color 'StepHist']),1,'last');
    else
        handles.([color 'HistXmax']) = 0;
        %Prevent us from trying to show a histogram if step counting hasn't been done
        set(handles.traceButton,'Value',true,'Enable','Off');
        set(handles.histButton,'Value',0,'Enable','Off');
    end
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Load data from the spot counter and set up figure window
handles = initializeData(handles);

%Display Images
displayImages(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in tossImageButton.
function tossImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to tossImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[gridData, ~] = tossImage(handles.matPath, handles.matFile, handles.arrayPos);
handles.gridData = gridData;
handles.gridData = gridData; clear gridData;
handles.gridSize = size(handles.gridData);
handles.nElements = handles.gridSize(1)*handles.gridSize(2);
if handles.arrayPos > handles.nElements
    handles.arrayPos = 1;
end
displayImages(handles);
guidata(hObject,handles);