% Wrapper function to get TIFF header information using imfinfo instead of tiffread

function [TIF, HEADER, INFO] = imf_wrapper(file_name)
    info = imfinfo(file_name,'tif');
    
    TIF = struct('ByteOrder','ieee-le', 'SamplesPerPixel',1, 'PlanarConfiguration',1,...
                 'tiff_id',info(1).FormatSignature(3), 'strIFDNumEntriesSize','uint16',...
                 'strIFDClassSize','uint32', 'nIFDTagBytes',12, 'nIFDClassBytes',2,...
                 'strTagSizeClass','uint32', 'nInlineBytes',4, 'ImageLength',info(1).Height,...
                 'BitsPerSample',info(1).BitsPerSample, 'BytesPerSample',info(1).BitsPerSample/8,...
                 'PhotometricInterpretation',1,'BytesPerPlane',info(1).StripByteCounts,...
                 'classname','uint16');
    
    % - Open file for reading
    TIF.file = fopen(file_name,'r','l');
                      
    % - Obtain the short file name
    [~, name, ext] = fileparts(file_name);
    TIF.image_name = [name, ext];
    TIF.file_name = file_name;     
             
    HEADER = struct( 'SamplesPerPixel',[], 'index', [], 'ifd_pos', {info.Offset}, ...
                     'width', {info.Width}, 'height', {info.Height}, 'bits', {info.BitDepth},...
                     'StripOffsets', {info.StripOffsets}, 'StripNumber',[], 'RowsPerStrip', {info.RowsPerStrip},... 
                     'StripByteCounts', {info.StripByteCounts}, 'cmap', [], 'colors', []);
                 
    [HEADER.SamplesPerPixel] = deal(1);
    [HEADER.StripNumber] = deal(1);
    C = num2cell((1:length(info))');
    [HEADER.index] = C{:};
    
    INFO = struct('SamplesPerPixel', {info.SamplesPerPixel}, 'ByteOrder', {info.ByteOrder},...
                  'Width', {info.Width}, 'Height', {info.Height}, 'BitsPerSample', {info.BitsPerSample}, ...
                  'RowsPerStrip', {info.RowsPerStrip}, 'PlanarConfiguration', {info.PlanarConfiguration}, ...
                  'MaxSampleValue', {info.MaxSampleValue}, 'MinSampleValue', {info.MinSampleValue});
              
    
    
              
end

