classdef OOfileSet < OOList
    %PropertyReference Reference to a property in another object
    properties
        %
        fOffset=0;
        fSize=0;
        maxFile=10000;
        %
        %searchStr='(?<fRoot>.+)_(?<fIndex>\d+)';
        % SiSo Graber always adds 5 digit index
        rootStr={'.+' ''};
        sepStr ={'_'  ''};
        indStr ={'\d{5}' '\d{4}' '\d{3}'};
        %
        searchStr ='(?<fRoot>.+)_\w*(?<fIndex>\d{5})';
    
    end
    
    methods
        function Self = OOfileSet(fName)
            %
            Self.stateVars=unique({Self.stateVars{:}, 'fNameIn','fPathIn','fPathOut','fRoot'});
            %
            if exist('fName','var')
                Self.loadFiles(fName);
            end
            %
        end
        %
        % read Frame is to match the corresponding videoReader function. It
        % loads the next frame
        %
        function img=readFrame(Self)
            Self.iFile=Self.iFile+1;
            %
            img=imread(Self.fullfile(Self.iFile));
        end
        %  to match VideoReader Function
        function n=NumberOfFrames(Self)
            n=Self.n;
        end
        %
        function n=currentFrame(Self,n)
            if exist('n', 'var')
                Self.iFile=n;
            else
                n=Self.iFile;
            end
        end
        %
        function goto(Self,i)
            if (i <= Self.n)
                Self.i=i;
            else
                error(sprintf('OOfileSet::goto: %d is larger than filenumber %d', i, Self.nFile));
            end
        end
        
        %
        function n=dwTotalFrames(Self)
            n=Self.n;
        end
        %
        
        function bSet=isSet(Self, ffName)
            %
            [fPath, fName, fExt] = fileparts(ffName);
            %
            %rootStr=['.+' ''];
            %sepStr =['_'  ''];
            %indStr =['\d{d}'];
            searchStr='';
            bSet=false;
            %
            % possible filenames are
            % 20160828_00001    //coplete
            % 2016082800001     //no Separator
            % _00001            //no root
            % 00001             //no root and separator
            % whole plate00000.bmp //
            % etc
            %
            for i=1:numel(Self.rootStr)
                for j=1:numel(Self.sepStr)
                    for k=1:numel(Self.indStr)
                        if ~bSet
                            searchStr=sprintf('^(?<fRoot>%s)(?<fSep>%s)(?<fIndex>%s)$',...
                                Self.rootStr{i},Self.sepStr{j}, Self.indStr{k});
                            token = regexp(fName, searchStr, 'names');
                            %
                            % only search until the first functional pattern is found
                            if numel(token)
                                bSet=true;
                            end
                        end
                        
                    end
                end
            end
            %
            if bSet
                disp(sprintf('file %s belongs to set matching searchStr %s', fName, searchStr))
                disp(sprintf('Root\t\t=>%s<', token.fRoot))
                disp(sprintf('Separator\t=>%s<', token.fSep))
                disp(sprintf('Index\t\t=>%s<', token.fIndex))
                Self.fRoot  =token.fRoot;
                Self.fPathIn=fPath;
                Self.fExt   =fExt;
                Self.searchStr=searchStr;
            else
                error(sprintf('No string matching %s found', fName));
            end
            
        end
        %        addRelAgeFromName
        function addRelAgeFromName(Self)
          s_time=datetime;
          for i=1:Self.n
            S=Self.get(i);
            %fName=Self.get(i).name;
            S.time=datetime();
            S.time.Year   = str2num(S.name(13:16));
            S.time.Month  = str2num(S.name(18:19));
            S.time.Day    = str2num(S.name(21:22));
            S.time.Hour   = str2num(S.name(24:25));
            S.time.Minute = str2num(S.name(26:27));
            S.time.Second = str2num(S.name(28:29));
            if i==1
                s_time=S.time
            end
            %
            S.age=etime(datevec(S.time), datevec(s_time))/60/60;
            %
            Self.put(i,S);
            %
          end
        end
        
        function loadFiles(Self, path, pattern, bRecursive, maxSize, excludePattern)
            dirnames={path};
            if (bRecursive)
                list=dir(path);
                isfile=~[list.isdir];               %determine index of files vs folders
                dirnames={list([list.isdir]).name}; % directories names (including . and ..)
                %dirnames=dirnames(~strcmp('.',dirnames));
                dirnames=dirnames(~strcmp('..',dirnames));
            else
                dirnames={path};
            end
            %
            for i = 1:length(dirnames) %
                subDir=char(dirnames(i));
                fileDir = char(fullfile(path, subDir));           % current directory name
                fileAll = dir(fullfile(fileDir,'*.tsv')); % get list of data files in directory according to name structure 'Sheeta*.xlsx'
                nFile=numel(fileAll);
                for f=1:nFile
                    if (maxSize && fileAll(f).bytes>maxSize)
                        sprintf('Skipping large %d file %s', fileAll(f).bytes, fileAll(f).name);
                    elseif regexp(fileAll(f).name, excludePattern)
                        sprintf('Skipping exclude %s pattern file %s', excludePattern, fileAll(f).name);
                    else
                        fileAll(f).tag=subDir;
                        fileAll(f).dir=fileDir;
                        fileAll(f).age=0.0;
                        Self.add(fileAll(f));
                    end
                end
            end
        end
        
        function fName = fullfile(Self, i)
              fName=fullfile(Self.get(i).dir, Self.get(i).name);
        end
              
        function keep(Self, pattern)
            %
            iHave=Self.n;
            for i=Self.n:-1:1
                ele=Self.get(i);
                if isempty(regexp(ele.name, pattern))
                    ele=Self.remove(i);
                    fprintf('remove %s from list\n', ele.name);                    
                end                
            end            
            fprintf('removed %d of %d emelents\n', iHave-Self.n, iHave);
            %
        end
        
        function removeByAge(Self, minAge, maxAge)
            %
            iHave=Self.n;
            for i=Self.n:-1:1
                ele=Self.get(i);
                if ele.age < minAge || ele.age > maxAge
                    ele=Self.remove(i);
                    fprintf('remove age %.1f file %s from list\n', ele.age, ele.name);                    
                end                
            end            
            fprintf('removed %d of %d emelents\n', iHave-Self.n, iHave);
            %
        end
        
        function sortByFilename(Self, nChar)
            %important: Naming must be as from myoFarm
            for ii = 1:Self.n-1
                for jj = ii+1:Self.n
                    if stringCmpAB(Self.list{ii}.name, Self.list{jj}.name,nChar)>0
                        tmp=Self.list(ii);
                        Self.list(ii)=Self.list(jj);
                        Self.list(jj)=tmp;
                    end
                end
            end
        end
        
        function setFilenames(Self,fName)
            %
            [fPath name ext]=fileparts(fName);
            %
            dirs=regexp(fPath,'\','split');
            %
            Self.fPathIn=fPath;
            Self.fNameIn=[name ext];
            Self.pRoot=dirs{end};
            %
            if Self.outLevel==0
                Self.fPathOut = fPath;
                Self.fRoot = name;
            elseif Self.outLevel==-1
                Self.fPathOut   = strjoin(dirs(1:end-1),'\');
                Self.fRoot   = dirs{end};
            else
                error(sprintf('outLevel %d nOK', Self.outLevel));
            end
            %
            %Self.saveState;
            %
            %
            
        end
        
        
        function  fileArr=loadSet(Self, fName)
            %
            %Basler acA2000-50gm (21424070)_20170919_170415810_0103.bmp
            %
            if Self.isSet(fName)
                %
                % dangerous, Directory must contain only one set
                files=dir([Self.fPathIn '\' '*' Self.fExt]);
                %
                Self.nFile=numel(files);
                %
                [fPath, fName, fExt] = fileparts(files(1).name);
                
                token = regexp(fName, Self.searchStr,'names');
                isFrame=str2num(token.fIndex)
                maxFrame=10000;
                %
                if isFrame > maxFrame
                    numShift=isFrame-maxFrame;
                elseif isFrame==1
                    numShift=0;
                else
                    numShift = 1;
                end
                Self.file={};
                %
                for i=1:Self.nFile
                    %
                    [fPath name ext]=fileparts(files(i).name);
                    token = regexp(name, Self.searchStr,'names');
                    %
                    if numel(token)
                        fNum=numShift + str2num(token.fIndex);
                        Self.file{fNum}=files(i);
                        %
                        if fNum > Self.maxFile
                            errordlg(sprintf('Frame number %i > %i, reduce to %d', fNum, maxFrame,mod(fNum,maxFrame)));
                            %fNum = mod(fNum,maxFrame);
                        end
                        %
                    else
                        h=errordlg(sprintf('filename %s can not be dissected', fName));
                        uiwait(h);
                    end
                end
                
                %
            else
                Self.nFile=1;
                Self.file= dir(fName);
            end
            %
            Self.iFile=1;
        end
        %
        %function fName=fullfile(Self, N)
        %    if N < 1
        %        error('cant access N');
        %    end
        %    fName=fullfile(Self.fPathIn, Self.file{N}.name);
        %end
    end
end
