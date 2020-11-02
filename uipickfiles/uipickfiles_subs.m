classdef uipickfiles_subs
    %UIPICKFILES_SUBS contains functions pulled out of uipickfiles for use
    %elsewhere.
        
    methods(Static)

        function [c,network_vol] = path2cell(p)
        % Turns a path string into a cell array of path elements.
        if ispc
            p = strrep(p,'/','\');
            c1 = regexp(p,'(^\\\\[^\\]+\\[^\\]+)|(^[A-Za-z]+:)|[^\\]+','match');
            vol = c1{1};
            c = [{'My Computer'};c1(:)];
            if strncmp(vol,'\\',2)
                network_vol = vol;
            else
                network_vol = '';
            end
        else
            c = textscan(p,'%s','delimiter','/');
            c = [{filesep};c{1}(2:end)];
            network_vol = '';
        end
        end

        % --------------------

        function p = cell2path(c)
        % Turns a cell array of path elements into a path string.
        if ispc
            p = fullfile(c{2:end},'');
            if p(end) == ':'
                p = [p,filesep];
            end
        else
            p = fullfile(c{:},'');
        end
        end

        % --------------------

        function d = filtered_dir(full_filter,re_filter,filter_both,sort_fcn)
        % Like dir, but applies filters and sorting.
        % Args: full_filter = path to the starting directory. String end specifices file type, 
        %                     e.g. '/' finds only subdirectories, '/*' finds all files, '/*.tif' finds only tiffs, etc.
        %       re_filter = regexp filter for files
        %       filter_both = logical switch for filtering (not sure what 'both' refers to - just call with false for now)
        %       sort_fcn = anonymous function handle of the form @(x,c)file_sort(x,sort_state,c)
        %          where  sort_state is a 3-element logical vector; [1 0 0 ] is the default value           
        % 
        p = fileparts(full_filter);
        if isempty(p) && full_filter(1) == '/'
            p = '/';
        end
        if uipickfiles_subs.fdexist(full_filter,'dir')
            dfiles = repmat(dir(char(127)),0,1);
        else
            dfiles = dir(full_filter);
        end
        if ~isempty(dfiles)
            dfiles([dfiles.isdir]) = [];
        end

        ddir = dir(p);
        ddir = ddir([ddir.isdir]);
        [unused,index0] = sort(lower({ddir.name})); %#ok<ASGLU>
        ddir = ddir(index0);
        ddir(strcmp({ddir.name},'.') | strcmp({ddir.name},'..')) = [];

        % Additional regular expression filter.
        if nargin > 1 && ~isempty(re_filter)
            if ispc || ismac
                no_match = cellfun('isempty',regexpi({dfiles.name},re_filter));
            else
                no_match = cellfun('isempty',regexp({dfiles.name},re_filter));
            end
            dfiles(no_match) = [];
        end
        if filter_both
            if nargin > 1 && ~isempty(re_filter)
                if ispc || ismac
                    no_match = cellfun('isempty',regexpi({ddir.name},re_filter));
                else
                    no_match = cellfun('isempty',regexp({ddir.name},re_filter));
                end
                ddir(no_match) = [];
            end
        end
        % Set navigator style:
        %	1 => list all folders before all files, case-insensitive sorting
        %	2 => mix files and folders, case-insensitive sorting
        %	3 => list all files before all folders, case-insensitive sorting
        %	4 => list all folders before all files, case-sensitive sorting
        %	5 => mix files and folders, case-sensitive sorting
        %	6 => list all files before all folders, case-sensitive sorting
        nav_style = 1;
        switch nav_style
            case 1
                [unused,index1] = sort_fcn(dfiles,false); %#ok<ASGLU>
                [unused,index2] = sort_fcn(ddir,false); %#ok<ASGLU>
                d = [ddir(index2);dfiles(index1)];
            case 2
                d = [dfiles;ddir];
                [unused,index] = sort_fcn(d,false); %#ok<ASGLU>
                d = d(index);
            case 3
                [unused,index1] = sort_fcn(dfiles,false); %#ok<ASGLU>
                [unused,index2] = sort_fcn(ddir,false); %#ok<ASGLU>
                d = [dfiles(index1);ddir(index2)];
            case 4
                [unused,index1] = sort_fcn(dfiles,true); %#ok<ASGLU>
                [unused,index2] = sort_fcn(ddir,true); %#ok<ASGLU>
                d = [ddir(index2);dfiles(index1)];
            case 5
                d = [dfiles;ddir];
                [unused,index] = sort_fcn(d,true); %#ok<ASGLU>
                d = d(index);
            case 6
                [unused,index1] = sort_fcn(dfiles,true); %#ok<ASGLU>
                [unused,index2] = sort_fcn(ddir,true); %#ok<ASGLU>
                d = [dfiles(index1);ddir(index2)];
        end
        end

        % --------------------

        function [files_sorted,index] = file_sort(files,sort_state,casesen)
        switch find(sort_state)
            case 1
                if casesen
                    [files_sorted,index] = sort({files.name});
                else
                    [files_sorted,index] = sort(lower({files.name}));
                end
                if sort_state(1) < 0
                    files_sorted = files_sorted(end:-1:1);
                    index = index(end:-1:1);
                end
            case 2
                if sort_state(2) > 0
                    [files_sorted,index] = sort([files.datenum]);
                else
                    [files_sorted,index] = sort([files.datenum],'descend');
                end
            case 3
                if sort_state(3) > 0
                    [files_sorted,index] = sort([files.bytes]);
                else
                    [files_sorted,index] = sort([files.bytes],'descend');
                end
        end
        end

        % --------------------

        function drives = getdrives(other_drives)
        % Returns a cell array of drive names on Windows.
        letters = char('A':'Z');
        num_letters = length(letters);
        drives = cell(1,num_letters);
        for i = 1:num_letters
            if fdexist([letters(i),':\'],'dir')
                drives{i} = [letters(i),':'];
            end
        end
        drives(cellfun('isempty',drives)) = [];
        if nargin > 0 && iscellstr(other_drives)
            drives = [drives,unique(other_drives)];
        end
        end

        % --------------------

        function [filenames,dir_listing] = ...
            annotate_file_names(filenames,dir_listing,fsdata)
        % Adds a trailing filesep character to folder names and, optionally,
        % prepends a folder icon or bullet symbol.
        if ispc
            for i = 1:length(filenames)
                if ~isempty(regexpi(filenames{i},'\.lnk')) && ...
                        is_shortcut_to_dir(dir_listing(i).name)
                    filenames{i} = sprintf('%s%s%s%s',fsdata.pre_sc,filenames{i},...
                        fsdata.filesep,fsdata.post);
                    dir_listing(i).isdir = true;
                elseif dir_listing(i).isdir
                    filenames{i} = sprintf('%s%s%s%s',fsdata.pre,filenames{i},...
                        fsdata.filesep,fsdata.post);
                end
            end
        else
            for i = 1:length(filenames)
                if dir_listing(i).isdir
                    filenames{i} = sprintf('%s%s%s%s',fsdata.pre,filenames{i},...
                        fsdata.filesep,fsdata.post);
                end
            end
        end
        end

        % --------------------

        function history = update_history(history,current_dir,time,history_size)
        if ~isempty(current_dir)
            % Insert or move current_dir to the top of the history.
            % If current_dir already appears in the history list, delete it.
            match = strcmp({history.name},current_dir);
            history(match) = [];
            % Prepend history with (current_dir,time).
            history = [struct('name',current_dir,'time',time),history];
        end
        % Trim history to keep at most <history_size> newest entries.
        history = history(1:min(history_size,end));
        end

        % --------------------

        function success = generate_folder_icon(icon_path)
        % Black = 1, manila color = 2, transparent white = 3.
        im = [ ...
            3 3 3 1 1 1 1 3 3 3 3 3;
            3 3 1 2 2 2 2 1 3 3 3 3;
            3 1 1 1 1 1 1 1 1 1 1 3;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 1 1 1 1 1 1 1 1 1 1 1];
        cmap = [0 0 0;255 220 130;255 255 255]/255;
        fid = fopen(icon_path,'w');
        if fid > 0
            fclose(fid);
            imwrite(im,cmap,icon_path,'Transparency',[1 1 0])
        end
        success = uipickfiles_subs.fdexist(icon_path,'file');
        end

        % --------------------

        function success = generate_foldersc_icon(icon_path)
        % Black = 1, blue color = 2, darker blue = 3, transparent white = 4.
        im = [ ...
            4 4 4 1 1 1 1 4 4 4 4 4;
            4 4 1 2 2 2 2 1 4 4 4 4;
            4 1 1 1 1 1 1 1 1 1 1 4;
            1 2 2 2 2 2 3 2 2 2 2 1;
            1 2 2 2 2 2 2 1 2 2 2 1;
            1 2 2 2 1 1 1 1 1 2 2 1;
            1 2 2 1 2 2 2 1 2 2 2 1;
            1 2 1 2 2 2 3 2 2 2 2 1;
            1 2 2 2 2 2 2 2 2 2 2 1;
            1 1 1 1 1 1 1 1 1 1 1 1];
        cmap = [0 0 0;163 185 255;65 83 128;255 255 255]/255;
        fid = fopen(icon_path,'w');
        if fid > 0
            fclose(fid);
            imwrite(im,cmap,icon_path,'Transparency',[1 1 1 0])
        end
        success = uipickfiles_subs.fdexist(icon_path,'file');
        end

        % --------------------

        function success = generate_house_icon(icon_path)
        im = [6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6;
            6 6 6 6 6 6 6 5 5 6 6 6 6 6 6 6;
            6 6 6 6 6 6 5 8 8 5 6 8 8 8 6 6;
            6 6 6 6 6 5 8 3 3 8 5 2 9 2 6 6;
            6 6 6 6 5 8 3 3 3 3 8 5 9 2 6 6;
            6 6 6 5 8 3 7 4 4 7 3 8 5 2 6 6;
            6 6 5 8 3 3 1 1 1 1 3 3 8 5 6 6;
            6 5 8 3 3 3 2 4 4 2 3 3 3 8 5 6;
            5 8 2 3 3 3 3 3 3 3 3 3 3 2 8 5;
            6 6 2 3 3 3 1 1 1 1 3 3 3 2 6 6;
            6 6 2 3 3 3 1 8 8 1 3 3 3 2 6 6;
            6 6 2 3 3 3 1 8 8 1 3 3 3 2 6 6;
            6 6 2 3 3 3 1 1 2 1 3 3 3 2 6 6;
            6 6 2 3 3 3 1 5 5 1 3 3 3 2 6 6;
            6 6 2 3 3 3 1 7 7 1 3 3 3 2 6 6;
            6 6 8 8 8 8 4 4 4 4 8 8 8 8 6 6];
        im = [im,6*ones(16,5)];
        cmap = [70 24 9;174 172 166;244 240 230;93 96 97;32 33 33;...
            255 255 255;153 71 21;66 52 39;255 255 254]/255;
        fid = fopen(icon_path,'w');
        if fid > 0
            fclose(fid);
            imwrite(im,cmap,icon_path,'Transparency',[1 1 1 1 1 0 1 1 1])
        end
        success = uipickfiles_subs.fdexist(icon_path,'file');
        end

        % --------------------

        function success = generate_logo_icon(icon_path)
        im = [9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9;
            9 9 9 9 9 9 9 9 9 9 10 9 9 9 9 9;
            9 9 9 9 9 9 9 9 9 10 8 6 9 9 9 9;
            9 9 9 9 9 9 9 9 9 4 3 7 10 9 9 9;
            9 9 9 9 9 9 9 9 2 1 7 7 6 9 9 9;
            9 9 9 9 9 9 9 2 1 1 7 7 3 9 9 9;
            9 9 9 9 9 10 4 1 1 8 7 7 3 5 9 9;
            9 9 9 9 10 1 1 1 1 8 7 7 3 6 5 9;
            9 9 10 2 4 4 1 1 8 8 7 7 3 3 9 9;
            10 2 2 2 4 4 1 1 8 3 3 7 7 3 6 9;
            9 2 2 4 4 4 1 8 8 3 7 7 7 3 6 5;
            9 9 10 2 4 1 8 8 8 3 7 7 6 6 3 5;
            9 9 9 9 9 1 8 3 3 7 7 9 9 9 6 6;
            9 9 9 9 9 5 3 7 7 7 5 9 9 9 9 5;
            9 9 9 9 9 9 6 7 7 5 9 9 9 9 9 9;
            9 9 9 9 9 9 5 6 5 9 9 9 9 9 9 9];
        im = [im,9*ones(16,5)];
        cmap = [73 50 49;132 193 188;182 60 15;97 146 141;246 224 205;...
            223 153 109;230 113 15;123 33 18;255 255 255;202 212 210]/255;
        fid = fopen(icon_path,'w');
        if fid > 0
            fclose(fid);
            imwrite(im,cmap,icon_path,'Transparency',[1 1 1 1 1 1 1 1 0 1])
        end
        success = uipickfiles_subs.fdexist(icon_path,'file');
        end

        % --------------------

        function fsdata = set_folder_style(folder_style_pref)
        % Set style to preference.
        fsdata.style = folder_style_pref;
        % If style = 1, check to make sure icon image file exists.  If it doesn't,
        % try to create it.  If that fails set style = 2.
        if fsdata.style == 1
            icon1_path = fullfile(prefdir,'uipickfiles_folder_icon.png');
            icon2_path = fullfile(prefdir,'uipickfiles_foldersc_icon.png');
            if ~(uipickfiles_subs.fdexist(icon1_path,'file') && uipickfiles_subs.fdexist(icon2_path,'file'))
                success1 = uipickfiles_subs.generate_folder_icon(icon1_path);
                success2 = uipickfiles_subs.generate_foldersc_icon(icon2_path);
                if ~(success1 && success2)
                    fsdata.style = 2;
                end
            end
        end
        % Set pre and post fields.
        if fsdata.style == 1
            icon1_url = ['file:///',strrep(strrep(icon1_path,':','|'),'\','/')];
            icon2_url = ['file:///',strrep(strrep(icon2_path,':','|'),'\','/')];
            fsdata.pre = sprintf('<html><img width=12 height=10 src="%s">&nbsp;',icon1_url);
            fsdata.pre_sc = sprintf('<html><img width=12 height=10 src="%s">&nbsp;',icon2_url);
            fsdata.post = '</html>';
        elseif fsdata.style == 2
            fsdata.pre = '<html><b>&#8226;</b>&nbsp;';
            fsdata.pre_sc = '<html><b>&#8226;</b>&nbsp;';
            fsdata.post = '</html>';
        elseif fsdata.style == 3
            fsdata.pre = '';
            fsdata.pre_sc = '';
            fsdata.post = '';
        end
        fsdata.filesep = filesep;

        end

        % --------------------

        function csdata = set_cmenu_style(cmenu_style_pref)
        % Set style to preference.
        csdata.style = cmenu_style_pref;
        % If style = 1, check to make sure icon image files exist.  If they don't,
        % try to create them.  If that fails set style = 2.
        if csdata.style == 1
            icon1_path = fullfile(prefdir,'uipickfiles_home_icon.png');
            icon2_path = fullfile(prefdir,'uipickfiles_logo_icon.png');
            if ~(uipickfiles_subs.fdexist(icon1_path,'file') && uipickfiles_subs.fdexist(icon2_path,'file'))
                success1 = uipickfiles_subs.generate_house_icon(icon1_path);
                success2 = uipickfiles_subs.generate_logo_icon(icon2_path);
                if ~(success1 && success2)
                    csdata.style = 2;
                end
            end
        end
        % Set pre and post fields.
        if csdata.style == 1
            icon1_url = ['file:///',strrep(strrep(icon1_path,':','|'),'\','/')];
            icon2_url = ['file:///',strrep(strrep(icon2_path,':','|'),'\','/')];
            csdata.pre_home = sprintf('<html><img width=21 height=16 src="%s">',icon1_url);
            csdata.pre_logo = sprintf('<html><img width=21 height=16 src="%s">',icon2_url);
            csdata.post = '</html>';
        elseif csdata.style == 2
            csdata.pre_home = '';
            csdata.pre_logo = '';
            csdata.post = '';
        end

        % Get MATLAB folders from userpath.
        matlab_folders = regexp(userpath,pathsep,'split');
        matlab_folders(cellfun(@isempty,matlab_folders)) = [];
        if ispc
            csdata.home_folder = getenv('USERPROFILE');
        else
            csdata.home_folder = getenv('HOME');
        end
        csdata.matlab_folders = matlab_folders;

        end

        % --------------------

        function prop = parsepropval(prop,varargin)
        % Parse property/value pairs and return a structure.
        properties = fieldnames(prop);
        arg_index = 1;
        while arg_index <= length(varargin)
            arg = varargin{arg_index};
            if ischar(arg)
                prop_index = uipickfiles_subs.match_property(arg,properties);
                prop.(properties{prop_index}) = varargin{arg_index + 1};
                arg_index = arg_index + 2;
            elseif isstruct(arg)
                arg_fn = fieldnames(arg);
                for i = 1:length(arg_fn)
                    prop_index = match_property(arg_fn{i},properties);
                    prop.(properties{prop_index}) = arg.(arg_fn{i});
                end
                arg_index = arg_index + 1;
            else
                error(['Properties must be specified by property/value pairs',...
                    ' or structures.'])
            end
        end
        end

        % --------------------

        function prop_index = match_property(arg,properties)
        % Utility function for parsepropval.
        prop_index = find(strcmpi(arg,properties));
        if isempty(prop_index)
            prop_index = find(strncmpi(arg,properties,length(arg)));
        end
        if length(prop_index) ~= 1
            error('Property ''%s'' does not exist or is ambiguous.',arg)
        end
        end

        % --------------------

        function r = fdexist(item_path,type)
        %fdexist: Check if file or directory exists.  Does not search MATLAB path.
        %  type must be 'dir' or 'file'.
        if strncmpi(type,'dir',length(type))
            r = java.io.File(item_path).isDirectory();
        elseif strncmpi(type,'file',length(type))
            r = java.io.File(item_path).isFile();
        end
        end

        % --------------------

        function r = is_shortcut_to_dir(filename)
        r = false;
        % jFile = java.io.File(filename);
        % sf = sun.awt.shell.ShellFolder.getShellFolder(jFile);
        % r = sf.isDirectory();
        end

        % --------------------

        function d = subdirs(basedir,depth,exclusions)
        %subdirs: Recursive directory finder.
        % Recursively find all subdirectories of a specified directory.
        %
        % Syntax:
        %   dirs = subdirs;
        %
        % will return all subdirectories of the current directory, including the
        % current directory, in a cell array of strings.
        %
        %   dirs = subdirs(base);
        %
        % starts at the directory in the string, base, rather than the current
        % directory.
        %
        %   dirs = subdirs(base,depth);
        %
        % only searches to a limited depth (default is Inf).  A depth of zero
        % returns only the base directory, depth = 1 returns the base directory and
        % its immediate decendants, etc.

        % Version: 1.1, 8 November 2014
        % Author:  Douglas M. Schwarz
        % Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
        % Real_email = regexprep(Email,{'=','*'},{'@','.'})

        % If base directory not specified, use current directory.
        if nargin < 1
            basedir = pwd;
        end

        % If depth not specified, search to infinite depth.
        if nargin < 2 || isempty(depth)
            depth = inf;
        end

        if nargin < 3 || isempty(exclusions)
            exclusions = '';
        end

        % If instructed not to search deeper, return basedir in a cell.
        if depth == 0
            d = {basedir};
            return
        end

        % Check exclusions for 'p' => exclude 'private' directories.  Other
        % exclusions characters exclude directories beginning with that character,
        % e.g., '.@+'.
        exclu = exclusions;
        no_private = any(exclu == 'p');
        exclu(exclu == 'p') = [];

        % Get directory contents.
        items = dir(basedir);

        % Get the name of each item in basedir.  Remove items that are not
        % directories and the special directories named '.' and '..', leaving only
        % the desired subdirectories.
        item_names = {items.name};
        item_names(~[items.isdir] | strcmp(item_names,'.') | ...
            strcmp(item_names,'..')) = [];

        % Remove private directories, if desired.
        if no_private
            item_names(strcmpi(item_names,'private')) = [];
        end

        % Remove directories beginning with the characters in exclu, e.g., '.@+'.
        for i = 1:length(exclu)
            item_names(strncmp(item_names,exclu(i),1)) = [];
        end

        % Run this function recursively on each subdirectory and return basedir and
        % those subdirectories.
        num_items = length(item_names);
        subitems = cell(1,num_items);
        for i = 1:num_items
            subitems{i} = subdirs(fullfile(basedir,item_names{i},''),...
                depth - 1,exclusions);
        end
        d = [{basedir},subitems{:}];
        end
    end
end

