classdef OOfile < OOclass
    %
    % Housekeeping functions, usefull for any app
    %
    
    properties
        %
        %File Handle wor read/write
        %fRoot=''
        %fPath=''
        %fExt=''
        bWrite=false
        bRead=true
        fh=0;
        %        
    end
    
    methods
        function Self=OOfile(fName, io)
            Self.startTime=tic;
            if exist('io','var')
                switch io
                    case 'w'
                        Self.bWrite=true;
                        Self.bRead=false;
                    case 'rw'
                        Self.bWrite=true;
                        Self.bRead=true;
                    otherwise 
                        Self.bWrite=false;
                        Self.bRead=true;
                end
            end
            
            if exist('fName','var') && Self.bRead
                Self.fNameIn=fName;
            end
            
            if exist('fName','var') && Self.bWrite
                Self.fNameOut=fName;
            end
        end
        %
        function fName = fileTmp(Self, ext)
           if exist('ext','var')
               fName = [Self.pTmp, '\tmp.' ext];
           else
               fName = [Self.pTmp, '\tmp.txt'];
           end
        end
        
        function fOut=fixXmlParameterBlock(Self, fIn)
           if exist('fIn','var')
               fid=fopen(fIn);
           else
               fid=fopen(Self.fNameIn);
           end           
           fOut = Self.fileTmp('fixParameterBlock.xml');
           fod = fopen(fOut, 'w');
           %
           tline = fgetl(fid);
           iMatch=0;
           src='</P>';
           tgt='</Parameter>';
           
           while ischar(tline)
              if (strcmp(tline,src))
                 iMatch=iMatch+1;
                 nline = strrep(tline,src,tgt)
                 disp([' found:' tline])
                 disp(['became:' nline])
                 tline=nline;
               end
               fprintf(fod,'%s\n',tline);
               tline = fgetl(fid);
           end
           fclose(fid);          
           fclose(fod);                     
        end
        
        function fOut=filterXmlComments(Self, fIn)
           if exist('fIn','var')
               fid=fopen(fIn);
           else
               fid=fopen(Self.fNameIn);
           end
           
           Self.fNameOut = Self.fileTmp('filter.xml');
           fOut=Self.fNameOut
           fod = fopen(fOut, 'w');
           %
           tline = fgetl(fid);
           iMatch=0;
           while ischar(tline)
             pos=regexp(tline,'<!');
             if (pos)
                nline = tline(1:pos-1);
                disp(['found : ' tline])
                disp(['became: ' nline])
                tline=nline;
             end
             pos=regexp(tline,'<\?');
             if (pos)
                disp(['skipping: ' tline])
                tline='';
             end
             fprintf(fod,'%s\n',tline);
             tline = fgetl(fid);
           end
           fclose(fid);          
           fclose(fod);          
        end
        
        function fName=fParameter(Self)
         fName=fullfile(Self.fPathOut, [Self.fRoot '.xml']);
        end
        %
        % Saves Parameters in State List
        %
        function fPath=Path(Self, fPath)
           if exist('fPath','var')
               if (Self.bWrite)
                    Self.fPathOut=fPath;
               else
                    Self.fPathIn=fPath;
               end               
           end           
           %
           if (Self.bWrite)
              fPath=Self.fPathOut;
           else
              fPath=Self.fPathIn;
           end
        end
        
        
        function cat(Self, fName)
            if exist(fName,'file')
                fid = fopen(fName);
                tline = fgetl(fid);
                while ischar(tline)
                    disp(tline)
                    tline = fgetl(fid);
                end
                fclose(fid);          
            end            
        end
        
        
        function iMatch = strrep(Self, fName, src, tgt, fOut)
            if exist(fName,'file')
                fid = fopen(fName);
                fod = fopen(fOut,'w');
                tline = fgetl(fid);
                iMatch=0;
                while ischar(tline)
                    if (strcmp(tline,src))
                        iMatch=iMatch+1;
                        nline = strrep(tline,src,tgt)
                        disp('found:')
                        disp(tline)
                        disp('became:')
                        disp(nline)
                        tline=nline;
                    end
                    fprintf(fod,'%s\n',tline);
                    tline = fgetl(fid);
                end
                fclose(fid);          
                fclose(fod);          
            end            
        end
        
        
        function fExt=Ext(Self, fExt)
            if nargin==2
               Self.fExt=fExt;
           else
               fExt=Self.fExt;
            end
        end
        
        function fRoot=Root(Self, fRoot)
           if nargin==2
               Self.fRoot=fRoot;
           else
               fRoot=Self.fRoot;
           end
        end
        
        function fName=fullname(Self)
           fName=fullfile(Self.Path(), [Self.fRoot '.' Self.Ext]);
        end
        
        function bExist=exists(Self)
           fName=Self.fullname();
           bExist= exist(fName, 'file') == 2;
        end
        
        function bOk=delete(Self)            
            if Self.exists()
                delete(Self.fullname)
            end
            bExist = Self.exists();
            bOk = ~bExist;
        end
        
        function fName=saveState(Self, fName)
            if ~exist('fName', 'var')
                fName=Self.stateFile;
            end
            disp(sprintf('Saving State to %s', fName));
            Self.saveXml(Self.getState, fName);
        end
        %
        % Saves State and Parameter Values
        %
        function fName=saveParameter(Self, fName)
            if ~exist('fName', 'var')
                fName=Self.stateFile;
            end
            %
            disp(sprintf('Saving Parameter to %s', fName));
            
            %
            S={Self.stateVars{:}, Self.paraVars{:}};
            para=getParameter(Self, S)
            Self.saveXml(getParameter(Self, S), fName);
        end
        %
        %        
        function fName=saveXml(Self, S, fName)
            %
            if exist('fName','var')
                fOut=fName;
            else
                fOut=Self.fNameOut;
            end
            
            [fPath name ext]=fileparts(fOut);
            %
            if ~exist(fPath, 'dir')
                mkdir(fPath);
            end
            %
            if Self.bUseTinyXml
                tinyxml2_wrap('save', fName, S);
            else
                struct2xml(struct('root',S), fName);
            end
        end
        %        
        %
        function state=loadState(Self, xmlFile)
            Self.stateFile=xmlFile;
            state=Self.loadXml(xmlFile, Self.stateVars);            
        end
        %
        function state=loadParameter(Self, xmlFile)
            Self.paraFile=xmlFile;
            S={Self.stateVars{:}, Self.paraVars{:}};
            state=Self.loadXml(xmlFile, S);            
        end
        %
        function state=readXml(Self, fName)
            state=struct;
            if exist(fName,'file')
                %
                if Self.bFixXml
                   fh=OOfile();
                   fTmp=fh.filterXmlComments(fName);
                   fName=fh.fixXmlParameterBlock(fTmp);
                end
                %
                if Self.bUseTinyXml
                    state=tinyxml2_wrap('load', fName);
                else
                    s=xml2struct(fName);
                    if isfield(s, 'root')
                        state=s.root;
                    else
                        state=s;
                        %error('No field >root< in structure obtained from %s',fName);
                    end
                end
            end
        end
        
        function state=loadXml(Self, fName, vars)
            %
            state=Self.readXml(fName);
            %
            for i=1:numel(vars)
                if isfield(state, vars{i}) && isprop(Self,vars{i})
                    Self.(vars{i})=state.(vars{i});
                end
            end
            %
        end
        %
        %
        function state=getState(Self)
            %
            state=struct;
            %
            for i=1:numel(Self.stateVars)
                stateVar=Self.stateVars{i};
                if isprop(Self, stateVar)
                    state.(stateVar)=Self.(stateVar);
                elseif ismethod(Self, stateVar)
                    state.(stateVar)=Self.(stateVar);
                end
            end
            %
        end
        %
        function para=getParameter(Self, paraVars)
            para=struct;
            for i=1:numel(paraVars)
                stateVar=paraVars{i};
                if isprop(Self, stateVar)
                    para.(stateVar)=Self.(stateVar);
                elseif ismethod(Self, stateVar)
                    para.(stateVar)=Self.(stateVar);
                end
            end
            %
        end
        %
        function fh=open(Self, rw)
            fh=0;
            switch rw
                case 'r' 
                    Self.fh=fopen(Self.fNameIn, 'r');    
                    Self.hFileIn=fh;
                case 'w' 
                    fh=fopen(Self.fNameOut, 'w');
                    Self.hFileOut=fh;
                otherwise
                    die('Can only read or write to file');                        
            end
            Self.fh=fh;  % The last handle to be obened in fh
        end
        
        function close(Self, fh)
            if exist('fh', 'var')
                fclose(fh);
            elseif Self.hFileIn
                fclose(Self.hFileIn);
            elseif Self.hFileOut;
                fclose(Self.hFileOut);
            else
                error('OOfile::out ho handle specisied or open');
            end
        end
        
        function closeIn(Self)
            fclose(Self.hFileIn);
        end
        function closeOut(Self)
            fclose(Self.hFileOut);
        end
        
        
        function setFilenames(Self,fName)
            %
            [fPath name ext]=fileparts(fName);
            %
            dirs=regexp(fPath,'\','split');
            %
            Self.fExt=ext;
            Self.fPathIn=fPath;
            Self.fNameIn=[name ext];
            %
            if Self.outLevel == 0
                Self.fPathOut = fPath;
                Self.fRoot = name;
                Self.experimentName=dirs{end};
                Self.measurementName=Self.fRoot;
                %
            elseif Self.outLevel == -1
                Self.fPathOut       = strjoin(dirs(1:end-1),'\');
                Self.fRoot          = dirs{end};
                Self.experimentName = dirs{end-1};
                Self.measurementName= Self.fRoot;
                %
            elseif Self.outLevel == 1
                Self.fPathOut   = fullfile(fPath,name);
                Self.fRoot      = name;
                Self.experimentName=dirs{end};
                Self.measurementName=Self.fRoot;
                %
            else
                error(sprintf('outLevel %d nOK', Self.outLevel));
            end
        end
        
    end
    methods(Static)
        %
        %
        function closeMain_Callback(hObj, event,Self)
            disp('closing all')
            %
            %
            delete(hObj);
        end
    end
end