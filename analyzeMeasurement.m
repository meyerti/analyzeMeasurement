function varargout = analyzeMeasurement(varargin)

addpath('C:\labhub\import');
%
Anal=OOvideoAnalysisGui();
%
Anal.peakFitType='sine';

Anal.bUseTinyXml= 0;
Anal.outLevel   = 0;
Anal.bFixXml    = true;

%C:\Users\meyer_tim\Documents
%
fState=fullfile( getenv('APPDATA'), '/matlab/analyzeMeasurement.xml');
%
%
% Loading optional arguments
bOk          = true;
bBatch       = false;
bQuiet       = true;       %suppress output to stdout
bInteractive = true;  %suppress wait for pop-ups
bToDb        = false;
bToFile      = true;
bOverwrite   = false;
bDefault     = false;

Anal.peakFitType='sine';          

fName='';

while ~isempty(varargin)
    switch lower(varargin{1})
        case '-o'
            bOverwrite=true;
        case '-default'
            bDefault=true;
        case '-quiet'
              bInteractive=false;              
              bQuiet=true;
        case '-batch'
              bBatch=true;
              bInteractive=false;
              bQuiet=true;              
          case '-todb'
              bToDb=true;
          case '-nofile'
              bToFile=false;
          case '-db'
              bToDb=true;
              varargin(1:1) = [];
              if exist(varargin{1}, 'file') == 2
                  Anal.dbCred = varargin{1};
              else
                  error(sprintf('Following -db file is expected, not %s', varargin{1}));
              end              
          case '-notinyxml'
              Anal.bUseTinyXml=false;              
          case '-nofixxml'
              Anal.bFixXml=false;
          case '-fittype'
              varargin(1:1) = [];
              Anal.peakFitType=varargin{1};          
          otherwise
              fName=varargin{1};
              if (~exist(fName,'file'))
                  error(['Unexpected option: ' fName]);
              end
      end
      varargin(1:1) = [];
end



if (~ bDefault)   Anal.loadState(fState);

Anal.set('bInteractive', bInteractive);
Anal.set('bQuiet',bQuiet);


disp(sprintf('Settings: useTinyXml %d',Anal.bUseTinyXml));
disp(sprintf('Settings: fixXml     %d',Anal.bFixXml));

if (~ exist(fName,'file')    )
    [name path]=uigetfile({'*.xml','All Files'},'Select Data File', Anal.fPathIn);
    fName=fullfile(path,name)
end
%
% save new default search path
%
if ~ exist(fName, 'file')
    h=errordlg('Xml File not found', 'File Error');
    waitfor(h)
    %quit force;
end
%
S=Anal.getFilenames(fName);



% test if all files are there
fPara=fullfile(S.fPathIn, S.fPara);

fDist=fullfile(S.fPathIn, S.fDist);
fDistMax=fullfile(S.fPathIn, S.fDistMax);
%fDistHough=fullfile(S.fPathIn, S.fDistMax);
%
%
if exist(fPara,'file')
    disp(fPara)
    Anal.loadState(fPara);   
elseif bBatch
    abort(Anal, bBatch);
else
    h=errordlg(sprintf('Parameter file %s not found',fPara),'File Error');
    uiwait(h)
    return
end

if exist(fDist,'file')
    FileInfo = dir(fDist);
    if FileInfo.bytes > 10
        %
        Anal.readDistances(fDist);
        %
        try
            Anal.recordingTimestamp=posixtime(datetime(FileInfo.datenum, 'ConvertFrom', 'dateNum'));
        catch 
            Anal.recordingTimestamp=0000000;
        end
    else
        disp(sprintf('Distance file %s is empty',fDist));
        bOk=false;
    end
elseif exist(fDistMax,'file')
    Anal.readDistances(fDistMax);   
elseif bBatch
    abort(Anal, bBatch);
else
    h=errordlg(sprintf('Distance file %s not found',fDist), 'File Error');
    uiwait(h)
    return
end
%
if ~bOk
    disp(sprintf('Something Failed %s ',fDist));
    abort(Anal, bBatch);
    return
end
% Loading of Analysis State File fPara may have overwritten the actual
Anal.setFilenames(fName);

fPeaks=fullfile(S.fPathIn, Anal.fPeaks);

if bBatch && exist(fPeaks) && ~bOverwrite
    disp(sprintf('Outfile %s exists, skip', Anal.fPeaks));
    abort(Anal, bBatch);
    return
end

%Anal.updateNames;
% Open Panel last so all data from Analysis state file can be employed
%Anal.bInteractive=bInteractive;
%

Panel=OOvideoAnalysisPanel(Anal);
Panel.loadState(fState);
%
%Panel.bQuiet=bQuiet;
Panel.set('bInteractive',bInteractive);
%
Panel.bRoi=false;     % do not plot Roi, only Graphs
Panel.hPlotParameter.bRoiPlot=false;


Panel.open_Gui;
%
disp(sprintf('Set max frequency to  %12.6f', Anal.maxFreq));

Anal.maxFrequency(Anal.maxFreq);
Anal.updateNames();
%
set(Panel.hFigure, 'Name',fName);
%
%
Panel.updateTraces();

%
if bBatch
    bInteractive=false;
    Anal.bInteractive=false;
    if (bToDb)        
        try
         Panel.save_toDb(bInteractive);    
      catch
         disp(sprintf('Failed to insert to Db %s', Anal.fPeaks));
      end
    end
    
    if (bToFile)        
        try
            Panel.save(bInteractive);
        catch
            disp(sprintf('Failed to Save %s', Anal.fPeaks));
        end
    end
    %
    abort(Anal, bBatch);
end

end

function abort(Anal,bBatch)
    Anal.close;
    close all;
    hFigure = findobj('Type','figure');    
    for i=1:numel(hFigure)
          hFigure(i).delete
    end    
    if bBatch
        %quit force;    
    end
