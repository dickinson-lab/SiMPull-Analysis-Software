% Tries to determine whether a file is located on a network volume or a
% local drive. 

function isNetwork = isNetworkDrive(filePath)
    if ispc
        driveLetter = regexp(filePath, '^[A-Z]:', 'match', 'once');
        if isempty(driveLetter)
            error('Invalid Windows path');
        end
        isNetwork = strcmp(System.IO.DriveInfo(System.IO.Path.GetPathRoot(driveLetter)).DriveType,'Network');
    else
        [~, result] = system(['df ', filePath]);
        result = split(result, newline);
        isNetwork = startsWith(result{2},'//'); % On a mac, network volumes start with '//' while local volumes don't.
    end
end

