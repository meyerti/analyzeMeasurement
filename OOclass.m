classdef OOclass < handle
    %
    % Housekeeping functions, usefull for any app
    %    
    properties
        %
        dateFormat='uuuu-MM-dd HH:mm:ss';
        %dateFormat='yyyy-mm-dd HH:MM:SS';
        time;
        %
        name='';
        tag='';
        %
        stateFile=false
        paraFile=false
        %
        fName    = '';
        fNameIn  = '';
        fNameOut = '';
        fExt     = '';
        fRoot    = '';
        pRoot    = '';
        fPathIn  = '';
        fPathOut = '';
        pTmp = '';
        %
        % handles
        %
        fFile=0;  %OOfile Object
        hFileIn=0;
        hFileOut=0;
        
        hMsgBox=0;
        hMsgTxt=0;
        %
        %
        experimentName  = '';
        measurementName = '';
        %
        outLevel=0;
        bInteractive=true;
        
        bQuiet=false;
        %
        % boolean
        bUseTinyXml=0
        bFixXml=false;
        %
        startTime=0;
        %
        stateVars={'fNameIn','fNameOut','fExt','fRoot','fPathIn','fPathOut'}
        paraVars={};
        userData
        bActive=1;
        cmap=vertcat(colormap(autumn(32)), flipud(colormap(summer(32))));
        %
    end
    
    methods
        function Self=OOclass
            Self.stateFile=[getenv('APPDATA') '\' class(Self) '.xml'];
            Self.startTime=tic;
            Self.pTmp=getenv('temp');
            Self.time=datetime;
            Self.time.Format=Self.dateFormat;
            
        end
        %
        function empty(Self)
          % keep as required by OOlist
        end
        
        function color=getColor(Self, Val, Min, Max)
            %
            if Min > Max                
              % reverse sorting
              %cr = relativ position %
              cr  = min(1, 1- (Val - Max) / (Min - Max)) ;                 
            else
              % max is 100%
              cr  = min(1,    (Val - Min) / (Max - Min)) ;                
            end
            %
            cn = max( 1,  floor(cr*length(Self.cmap)) );
            %[frcData(3) peak.height frcData(4) cr cn]                 
            color  = Self.cmap(cn,:);
        end
        
        function fName=fParameter(Self)
         fName=fullfile(Self.fPathOut, [Self.fRoot '.xml']);
        end
        %
        % Saves Parameters in State List
        %
        function fName=saveState(Self, fName)
            %
            if ~exist('fName', 'var')
                fName=Self.stateFile;
            end
            disp(sprintf('Saving State to %s', fName));
            %
            fh=OOfile(fName)
            fh.bUseTinyXml=Self.bUseTinyXml;
            fh.bFixXml=Self.bFixXml;
            fh.saveXml(Self.getState, fName);
            %
        end
        %
        % Saves State and Parameter Values
        %
        function fName=saveParameter(Self, fName)
            if ~exist('fName', 'var') | ~fName
                fName=Self.stateFile;
            end
            %
            disp(sprintf('Saving Parameter to %s', fName));            
            %
            S={Self.stateVars{:}, Self.paraVars{:}};
            
            %Self.saveXml(getParameter(Self, S), fName);
            
        end
        %        
         function str=timestamp(Self, posixTime)
             if exist('posixTime','var')
                 dt=datetime(posixTime, 'ConvertFrom','Posixtime');
             else
                %take current time
                %dt=datetime('now', 'TimeZone','local','Format',Self.dateFormat);  
                dt=datetime('now');  
             end
             str = datestr(dt, Self.dateFormat,'local');                        
         end
         %
        function name=genDateString(Self)
            v=datevec(date);
            name=sprintf('%4i%02i%02ia',v(1:3)); 
        end
        %        
        function fName=saveXml(Self, S, fName)
            %
            fh=OOfile(fName);
            fh.bUseTinyXml=Self.bUseTinyXml;            
            fh.saveXml(S);
            delete(fh);            
        end
        %
        %
        %
        %
        function state=loadParameter(Self, xmlFile)
            Self.paraFile=xmlFile;
            S={Self.stateVars{:}, Self.paraVars{:}};
            state=Self.loadXml(xmlFile, S);            
        end
        %
        function iOut=odd(Self, dIn)
           iOut=2*floor(dIn/2)+1;
        end
        
        
        function state=loadState(Self, fName)            %
            %
            Self.stateFile=fName;
            %
            fh=OOfile(fName);
            fh.bUseTinyXml=Self.bUseTinyXml;
            fh.bFixXml    =Self.bFixXml;
            state         =fh.readXml(fName);
            delete(fh);
            %
            vars=Self.stateVars;
            %
            for i=1:numel(vars)
                if isfield(state, vars{i}) && isprop(Self, vars{i})
                    %
                    %disp(sprintf('type of >%s< is >%s< vs >%s<\n', vars{i}, class(Self.(vars{i})), class(state.(vars{i}))));
                    
                    if isa(state.(vars{i}),'numeric') && isa(Self.(vars{i}),'numeric')
                        Self.(vars{i})=state.(vars{i});
                        %fprintf('value of >%s< type >%s< is %12.5f\n', vars{i}, class(state.(vars{i})), state.(vars{i}));
                    elseif isa(state.(vars{i}),'char') && isa(Self.(vars{i}),'char')
                        Self.(vars{i})=state.(vars{i});
                    elseif isa(state.(vars{i}),'char') &&  isa(Self.(vars{i}),'numeric')
                        Self.(vars{i})=str2double(state.(vars{i}));
                    elseif isa(state.(vars{i}),'struct') &&  isa(Self.(vars{i}),'char') && isfield(state.(vars{i}), 'Text')
                        Self.(vars{i})=state.(vars{i}).Text;                    
                    elseif isa(state.(vars{i}),'struct') &&  isa(Self.(vars{i}),'double') && isfield(state.(vars{i}), 'Text')
                        Self.(vars{i})=str2num(state.(vars{i}).Text);            
                    else                        
                        disp(sprintf('Var %s is of type %s, Self of type %s, no conversion rule\n', ...
                            vars{i}, class(state.(vars{i})), class(Self.(vars{i})) ));
                    end
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
        function set(Self, par, val)
            if isprop(Self, par)
                Self.(par)=val;
            end            
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
        
        function str=initializeMessageBox(Self,str)
            if (Self.hMsgBox==0)
                Self.hMsgBox=figure('Toolbar','none','NumberTitle','off','MenuBar','none', 'Name', 'Message Box');
                S=struct('style','text','FontSize',8,'Units','Normalized', 'Parent',Self.hMsgBox);            
                Self.hMsgTxt = uicontrol(S, 'Position', [0.05 0.05 .9 .9]);
                Self.hMsgTxt.String=date;
                Self.hMsgTxt.String={Self.hMsgTxt.String,str};
            end
        end
    
        function str=addMessage(Self,str)
            if Self.hMsgBox~=0
                Self.hMsgTxt.String={Self.hMsgTxt.String{:},str};
            end
            disp(str);
        end
        
        function deleteMessageBox(Self)
           if Self.hMsgBox~=0
               delete(Self.hMsgBox);
           end
           Self.hMsgBox=0;
        end

        function delete(Self)
           Self.deleteMessageBox;
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