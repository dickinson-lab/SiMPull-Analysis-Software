%Inspector for automated spotcount program

function varargout = colocalization_inspector_GUI(varargin)
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

% Last Modified by GUIDE v2.5 07-Apr-2017 10:05:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @colocalization_inspector_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @colocalization_inspector_GUI_OutputFcn, ...
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
function colocalization_inspector_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to spotcount_inspector_GUI (see VARARGIN)

% Choose default command line output for spotcount_inspector_GUI
handles.output = hObject;

%Set up variables
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

%Display Images
displayImages(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes spotcount_inspector_GUI wait for user response (see UIRESUME)
% uiwait(handles.figureWindow);


% --- Outputs from this function are returned to the command line.
function varargout = colocalization_inspector_GUI_OutputFcn(hObject, eventdata, handles) 
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

%Update Image Display
displayImages(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in averageImageButton.
function averageImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to averageImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of averageImageButton
set(handles.filteredImageButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in filteredImageButton.
function filteredImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to filteredImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filteredImageButton
set(handles.averageImageButton,'Value',0);
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in greenCheckbox.
function greenCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to greenCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of greenCheckbox
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in redCheckbox.
function redCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to redCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of redCheckbox
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in colocCheckbox.
function colocCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to colocCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of colocCheckbox
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in leftBlueButton.
function leftBlueButton_Callback(hObject, eventdata, handles)
% hObject    handle to leftBlueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of leftBlueButton
set(handles.leftGreenButton,'Value',0);
set(handles.leftRedButton,'Value',0);
set(handles.leftFarRedButton,'Value',0);
set(handles.greenCheckbox,'String','Blue Spots');
if get(handles.centerBlueButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in leftGreenButton.
function leftGreenButton_Callback(hObject, eventdata, handles)
% hObject    handle to leftGreenButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of leftGreenButton
set(handles.leftBlueButton,'Value',0);
set(handles.leftRedButton,'Value',0);
set(handles.leftFarRedButton,'Value',0);
set(handles.greenCheckbox,'String','Green Spots');
if get(handles.centerGreenButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in leftRedButton.
function leftRedButton_Callback(hObject, eventdata, handles)
% hObject    handle to leftRedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of leftRedButton
set(handles.leftBlueButton,'Value',0);
set(handles.leftGreenButton,'Value',0);
set(handles.leftFarRedButton,'Value',0);
set(handles.greenCheckbox,'String','Red Spots');
if get(handles.centerRedButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in leftFarRedButton.
function leftFarRedButton_Callback(hObject, eventdata, handles)
% hObject    handle to leftFarRedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of leftFarRedButton
set(handles.leftBlueButton,'Value',0);
set(handles.leftGreenButton,'Value',0);
set(handles.leftRedButton,'Value',0);
set(handles.greenCheckbox,'String','Far Red Spots');
if get(handles.centerFarRedButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in centerBlueButton.
function centerBlueButton_Callback(hObject, eventdata, handles)
% hObject    handle to centerBlueButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of centerBlueButton
set(handles.centerGreenButton,'Value',0);
set(handles.centerRedButton,'Value',0);
set(handles.centerFarRedButton,'Value',0);
set(handles.redCheckbox,'String','Blue Spots');
if get(handles.leftBlueButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in centerGreenButton.
function centerGreenButton_Callback(hObject, eventdata, handles)
% hObject    handle to centerGreenButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of centerGreenButton
set(handles.centerBlueButton,'Value',0);
set(handles.centerRedButton,'Value',0);
set(handles.centerFarRedButton,'Value',0);
set(handles.redCheckbox,'String','Green Spots');
if get(handles.leftGreenButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in centerRedButton.
function centerRedButton_Callback(hObject, eventdata, handles)
% hObject    handle to centerRedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of centerRedButton
set(handles.centerBlueButton,'Value',0);
set(handles.centerGreenButton,'Value',0);
set(handles.centerFarRedButton,'Value',0);
set(handles.redCheckbox,'String','Red Spots');
if get(handles.leftRedButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


% --- Executes on button press in centerFarRedButton.
function centerFarRedButton_Callback(hObject, eventdata, handles)
% hObject    handle to centerFarRedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of centerFarRedButton
set(handles.centerBlueButton,'Value',0);
set(handles.centerGreenButton,'Value',0);
set(handles.centerRedButton,'Value',0);
set(handles.redCheckbox,'String','Far Red Spots');
if get(handles.leftFarRedButton,'Value')
    set(handles.colocCheckbox,'Value',0,'Enable','off');
end
displayImages(handles);
guidata(hObject,handles);


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


function displayImages(handles)
b=handles.arrayPos;

%Figure out which channels are selected
leftLogical = false(length(handles.channels), 1);
centerLogical = false(length(handles.channels), 1);
for c = 1:length(handles.channels)
    color = handles.channels{c};
    leftLogical(c) = get(handles.(['left' color 'Button']),'Value');
    centerLogical(c) = get(handles.(['center' color 'Button']),'Value');
end
leftChannel = handles.channels{leftLogical};
centerChannel = handles.channels{centerLogical};

%Get images
if get(handles.averageImageButton,'Value')
    greenImageName = [handles.gridData(b).imageName '_' leftChannel 'avg.tif'];
    redImageName = [handles.gridData(b).imageName '_' centerChannel 'avg.tif'];
else
    greenImageName = [handles.gridData(b).imageName '_green_filt.tif'];
    redImageName = [handles.gridData(b).imageName '_red_filt.tif'];    
end
greenCh = imread([handles.gridData(b).tiffDir filesep greenImageName]);
[ymax xmax] = size(greenCh);
greenCh = imadjust(greenCh,stretchlim(greenCh,0.0005),[]);
if isfield(handles.statsByColor, [leftChannel 'RegistrationData']) %Apply registration correct if applicable
    greenCh = imwarp(greenCh,handles.statsByColor.([leftChannel 'RegistrationData']).SpatialRefObj, handles.statsByColor.([leftChannel 'RegistrationData']).Transformation,'OutputView', imref2d(size(greenCh)));
end

redCh = imread([handles.gridData(b).tiffDir filesep redImageName]);
redCh = imadjust(redCh,stretchlim(redCh,0.0005),[]);
if isfield(handles.statsByColor, [centerChannel 'RegistrationData']) %Apply registration correct if applicable
    redCh = imwarp(redCh,handles.statsByColor.([centerChannel 'RegistrationData']).SpatialRefObj, handles.statsByColor.([centerChannel 'RegistrationData']).Transformation,'OutputView', imref2d(size(redCh)));
end

%Create images for display
greenImage = uint16(zeros(ymax,xmax,3));
greenImage(:,:,1) = greenCh;
greenImage(:,:,2) = greenCh;
greenImage(:,:,3) = greenCh;

redImage = uint16(zeros(ymax,xmax,3));
redImage(:,:,1) = redCh;
redImage(:,:,2) = redCh;
redImage(:,:,3) = redCh;

mergedImage = uint16(zeros(ymax,xmax,3));
mergedImage(:,:,1) = redCh;
mergedImage(:,:,2) = greenCh;

%Draw circles around spots
greenOn = get(handles.greenCheckbox,'Value');
redOn = get(handles.redCheckbox,'Value');
colocOn = get(handles.colocCheckbox,'Value');

if handles.gridData(b).([leftChannel 'SpotCount']) > 0 && (greenOn || colocOn)
    for a = 1:handles.gridData(b).([leftChannel 'SpotCount'])
        if isfield(handles.statsByColor, [leftChannel 'RegistrationData']) %Apply registration correct if applicable
            [xcoord,ycoord] = transformPointsForward(handles.statsByColor.([leftChannel 'RegistrationData']).Transformation, handles.gridData(b).([leftChannel 'SpotData'])(a).spotLocation(1), handles.gridData(b).([leftChannel 'SpotData'])(a).spotLocation(2));
            xcoord = round(xcoord);
            ycoord = round(ycoord);
            if (xcoord < 5 || xcoord+5 > xmax || ycoord < 5 || ycoord+5 > ymax)
                continue
            end
        else
            xcoord = handles.gridData(b).([leftChannel 'SpotData'])(a).spotLocation(1);
            ycoord = handles.gridData(b).([leftChannel 'SpotData'])(a).spotLocation(2);
        end
        
        %Green Circles for Spots in Green Channel
        if greenOn || (colocOn && isnumeric( handles.gridData(b).([leftChannel centerChannel 'ColocSpots']) ) && handles.gridData(b).([leftChannel 'SpotData'])(a).(['coloc' centerChannel]))
            greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
            redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
            mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
        end
        %Yellow Circles for Colocalized Spots
        if colocOn && isnumeric( handles.gridData(b).([leftChannel centerChannel 'ColocSpots']) ) && handles.gridData(b).([leftChannel 'SpotData'])(a).(['coloc' centerChannel])
            greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
            redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
            mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
        end
    end
end

if handles.gridData(b).([centerChannel 'SpotCount']) > 0 && (redOn || colocOn)
    for a = 1:handles.gridData(b).([centerChannel 'SpotCount'])
        if isfield(handles.statsByColor, [centerChannel 'RegistrationData']) %Apply registration correct if applicable
            [xcoord,ycoord] = transformPointsForward(handles.statsByColor.([centerChannel 'RegistrationData']).Transformation, handles.gridData(b).([centerChannel 'SpotData'])(a).spotLocation(1), handles.gridData(b).([centerChannel 'SpotData'])(a).spotLocation(2));
            xcoord = round(xcoord);
            ycoord = round(ycoord);
            %Skip this circle if it would fall outside the image after registration
            if (xcoord < 5 || xcoord+5 > xmax || ycoord < 5 || ycoord+5 > ymax)
                continue
            end
        else
            xcoord = handles.gridData(b).([centerChannel 'SpotData'])(a).spotLocation(1);
            ycoord = handles.gridData(b).([centerChannel 'SpotData'])(a).spotLocation(2);
        end
        %Red Circles for Spots in Red Channel
        if redOn || (colocOn && isnumeric( handles.gridData(b).([centerChannel leftChannel 'ColocSpots']) ) && handles.gridData(b).([centerChannel 'SpotData'])(a).(['coloc' leftChannel]))
            greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
            redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
            mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1) = max(handles.circle, mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,1));
        end
        %Yellow Circles for Colocalized Spots
        if colocOn && isnumeric( handles.gridData(b).([centerChannel leftChannel 'ColocSpots']) ) && handles.gridData(b).([centerChannel 'SpotData'])(a).(['coloc' leftChannel])
            greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, greenImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
            redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, redImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
            mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2) = max(handles.circle, mergedImage(ycoord-5:ycoord+5,xcoord-5:xcoord+5,2));
        end
    end
end

%Show images
imshow(greenImage,'Parent',handles.greenImagePanel,'InitialMagnification',handles.scale*100);
imshow(redImage,'Parent',handles.redImagePanel,'InitialMagnification',handles.scale*100);
imshow(mergedImage,'Parent',handles.mergedImagePanel,'InitialMagnification',handles.scale*100);
set(handles.greenText,'String',[num2str(handles.gridData(b).([leftChannel 'SpotCount'])) ' ' leftChannel ' spots']);
set(handles.redText,'String',[num2str(handles.gridData(b).([centerChannel 'SpotCount'])) ' ' centerChannel ' spots'])
if strcmp(leftChannel, centerChannel)
    set(handles.colocText,'Visible','off');
else
    set(handles.colocText,'Visible','on');
    if isnumeric( handles.gridData(b).([centerChannel leftChannel 'ColocSpots']) )
        set(handles.colocText,'String',[num2str(handles.gridData(b).([leftChannel centerChannel 'ColocSpots'])) ' colocalized spots']);
    else
        set(handles.colocText,'String',handles.gridData(b).([centerChannel leftChannel 'ColocSpots']));
    end
end
xPos = mod(b,handles.gridSize(2));
if xPos == 0 
    xPos = handles.gridSize(2);
end
yPos = ceil(b/handles.gridSize(1));
set(handles.positionText,'String',['Stage Position: ' handles.gridData(b).imageName]);


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


function handles = initializeData(handles)
b=1;
handles.arrayPos = b;

%Get the data from the spot counter              
if isfield(handles, 'matPath')
    startPath = handles.matPath;
else
    startPath = pwd;
end
[matFile matPath] = uigetfile('*.mat','Choose a .mat file with data from the spot counter',startPath);
load([matPath filesep matFile]);
handles.matPath = matPath; clear matPath;
handles.matFile = matFile; 
handles.gridData = gridData; clear gridData;
handles.channels = channels; 
handles.statsByColor = statsByColor; clear statsByColor;
handles.gridSize = size(handles.gridData);
handles.nElements = handles.gridSize(1)*handles.gridSize(2);

%Get first image
firstImageName = [handles.gridData(b).imageName '_' channels{1} 'avg.tif'];
firstImage = imread([handles.gridData(b).tiffDir filesep firstImageName]);
[ymax xmax] = size(firstImage);
    
%Set up figure window
handles.screenSize = get(0,'ScreenSize');
figureWidth = handles.screenSize(3);
imageWidth = (figureWidth-120) / 3;
xscale = imageWidth / xmax;
figureHeight = handles.screenSize(4);
imageHeight = figureHeight - 350;
yscale = imageHeight / ymax;
handles.scale = min([xscale yscale]);
imageWidth = handles.scale * xmax;
figureWidth = imageWidth*3 + 120;
imageHeight = handles.scale * ymax;
figureHeight = imageHeight + 350;
set(handles.figureWindow,'Name',matFile(1:end-4), 'Units','pixels', 'Position',[(handles.screenSize(3)-figureWidth)/2 handles.screenSize(4)-figureHeight-100 figureWidth figureHeight]);
set(handles.instructionText,'Units','pixels','Position',[(figureWidth-250)/2 15 250 60]);
set(handles.greenImagePanel,'Units','pixels','Position',[30 80 imageWidth imageHeight]);
set(handles.redImagePanel,'Units','pixels','Position',[imageWidth+60 80 imageWidth imageHeight]);
set(handles.mergedImagePanel,'Units','pixels','Position',[imageWidth*2+90 80 imageWidth imageHeight]);

set(handles.leftPanel,'Units','pixels','Position',[30+(imageWidth-200)/2 imageHeight+120 200 nChannels*30]);
set(handles.centerPanel,'Units','pixels','Position',[imageWidth+60+(imageWidth-200)/2 imageHeight+120 200 nChannels*30]);
for a = 1:nChannels
    color = channels{a};
    set(handles.(['left' color 'Button']), 'Units','pixels','Position',[5 5+(nChannels-a)*30 190 30],'Visible','on');
    set(handles.(['center' color 'Button']), 'Units','pixels','Position',[5 5+(nChannels-a)*30 190 30],'Visible','on');
end
set(handles.(['left' channels{1} 'Button']), 'Value',1);
set(handles.greenCheckbox, 'String', [channels{1} ' Spots']);
if nChannels>1
    set(handles.(['center' channels{2} 'Button']), 'Value',1);
    set(handles.redCheckbox, 'String', [channels{2} ' Spots']);
else
    set(handles.(['center' channels{1} 'Button']), 'Value',1);
    set(handles.redCheckbox, 'Value', 0, 'Enable', 'off');
    set(handles.colocCheckBox, 'Value', 0, 'Enable', 'off');
end

set(handles.greenText,'Units','pixels','Position',[30+(imageWidth-200)/2 imageHeight+90 200 20]);
set(handles.redText,'Units','pixels','Position',[imageWidth+60+(imageWidth-200)/2 imageHeight+90 200 20]);
set(handles.colocText,'Units','pixels','Position',[2*imageWidth+90+(imageWidth-200)/2 imageHeight+90 200 20]);
set(handles.positionText,'Units','pixels','Position',[(figureWidth-500)/2 imageHeight+250 500 20]);
set(handles.buttonPanel,'Units','pixels','Position',[30 imageHeight+200 350 100]); 
if ~(exist([handles.gridData(b).tiffDir filesep handles.gridData(b).imageName '_red_filt.tif'],'file')==2)
    set(handles.averageImageButton,'Enable','off');
    set(handles.filteredImageButton,'Enable','off');
end
set(handles.tossImageButton, 'Units','pixels','Position',[(figureWidth-120)/2 imageHeight+200 120 30]);
set(handles.loadButton, 'Units','pixels','Position',[400 imageHeight+250 150 30]);
