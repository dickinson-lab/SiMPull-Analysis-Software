%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loads a user-specified portion of an NDTiff dataset
%
% Required argument: path = location of the dataset (directory)
%
% Additional arguments (all optional) are provided as name-value pairs:
%   subregion: Specify sub-region of each image to load, as an array of
%       pixel values ([xmin, ymin, width, height])
%   channels: Specify which channels to load. Accepts either a single value
%       or a vector, e.g. <'channels', 1> or <'channels',[1 2]> . 
%   slices: Specify which z slices to load. Accepts either a single value
%       or a vector, e.g. <'slices', 5> or <'slices',[1:5]> .
%   frames: Specify which frames to load. Accepts either a single value
%       or a vector, e.g. <'frames', 1> or <'frames',[1:500]> .
%   positions: Specify which stage positions to load. Accepts either a 
%       single value or a vector, e.g. <'positions', 1> or <'positions',
%       [1 2]> .
%   
%   If any arguments are omitted or if provided coordinates exceed the
%   datset size, the entire dataset along that dimension will be loaded. 
%
%   Important: All optional arguments shoudl be 1-based (MATLAB convention). 
%   so the first frame of the image is frame 1, not frame 0. 
%
% Returns: 
%   image: A multi-dimensional array containing the image data. The axis
%          order is x, y, channel, z-slice, time, position; any singleton
%          dimensions are eliminated. 
%   smd: A MATLAB structure containing the summary metadata.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [image, smd] = loadNDTiffDataset(path, varargin)

    % Check that a correct path was provided 
    if ~isa(path,'char') || ~isfolder(path)
        error('Wrong input type - provide the image directory as a string.');
    end

    % Get image size
    [xmax, ymax, nChannels, zmax, tmax, nPositions] = getNDTiffImageSize(path);
    if isempty(zmax); zmax = 1; end %Corrects for the fact that NDTiffs with only a single z position return empty for z coordinates.

    % Set defaults
    defaultChannels = 1:nChannels;
    defaultSlices = 1:zmax;
    defaultFrames = 1:tmax;
    defaultPositions = 1:nPositions;

    % Parse & validate input
        p = inputParser;
        addRequired(p,'path');
        addParameter(p, 'subregion', [], @isnumeric);
        addParameter(p, 'channels', defaultChannels, @isnumeric);
        addParameter(p, 'slices', defaultSlices, @isnumeric);
        addParameter(p, 'frames', defaultFrames, @isnumeric);
        addParameter(p, 'positions', defaultPositions, @isnumeric);
        parse(p,path,varargin{:});
        if isfield(p.Results,'subregion') && ~isempty(p.Results.subregion)
            subregion(1) = max(p.Results.subregion(1), 1);
            subregion(2) = max(p.Results.subregion(2), 1);
            subregion(3) = min(p.Results.subregion(3), xmax-subregion(1));
            subregion(4) = min(p.Results.subregion(4), ymax-subregion(2));
        else
            subregion = [];
        end
        channels = p.Results.channels;
        if min(channels) < 1 || max(channels) > nChannels; channels = defaultChannels; end
        slices = p.Results.slices;
        if min(slices) < 1 || max(slices) > zmax; slices = defaultSlices; end
        frames = p.Results.frames;
        if min(frames) < 1 || max(frames) > tmax; frames = defaultFrames; end
        positions = p.Results.positions;
        if min(positions) < 1 || max(positions) > nPositions; positions = defaultPositions; end
        clear p varargin
    % else
    %     channels = defaultChannels;
    %     slices = defaultSlices;
    %     frames = defaultFrames;
    %     positions = defaultPositions;
    % end

    % Convert coords to 0-based indexing
    channels = channels - 1;
    slices = slices - 1;
    frames = frames - 1;
    positions = positions - 1;
    
    % Get metadata from first image to determine bit depth; allocate memory
    dataset = javaObject('org.micromanager.ndtiffstorage.NDTiffStorage', path);
    axes = java.util.HashMap();
    axes.put("channel", 0);
    axes.put("time",0);
    axes.put("z",0);
    axes.put("position",0);
    MD = dataset.getEssentialImageMetadata(axes);
    depth = MD.bitDepth;
    if depth <= 8; type = 'uint8'; 
    elseif depth <= 16; type = 'uint16';
    elseif depth <= 32; type = 'single';
    else; error('Unrecognized image data type!'); 
    end
    if isempty(subregion) %we'll grab the whole image
        xsize = xmax;
        ysize = ymax;
    else %just a subregion
        xsize = subregion(3);
        ysize = subregion(4);
    end
    image = zeros(ysize,xsize,length(channels),length(slices),length(frames),length(positions),type);

    % Load image data
    for c = channels
        axes.put("channel",c);
        for z = slices
            axes.put("z",z);
            for t = frames
                axes.put("time",t);
                for p = positions
                    axes.put("position",p);
                    if isempty(subregion)
                        taggedImg = dataset.getImage(axes);
                    else
                        taggedImg = dataset.getSubImage(axes,subregion(1),subregion(2),subregion(3),subregion(4));
                    end
                    pixels = taggedImg.pix;
                    singleImg = reshape(pixels,[xsize,ysize])'; %Note the traspose operator (') to make image come out matlab-shaped
                    image(:,:,c+1,z+1,t+1,p+1) = singleImg;
                end
            end
        end
    end
    image = squeeze(image);

    % Load & convert summary metadata
    smdJSON = dataset.getSummaryMetadata();
    smd = jsonObjectToStruct(smdJSON);
end