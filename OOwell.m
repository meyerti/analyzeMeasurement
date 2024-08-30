classdef OOwell < OOtimeSeries
    %
    properties
        %
        hWaypoint=[];
        
        hImgAxes=0
        hImage=0
        hFigure=0
        hPlotParameter=struct();
        %
        bPan=false; %pan axes
        mousePos=[0 0];
        
        hPlotAxes=0;    %axes for distance plot
        hPlot=0;        %Raw Data Plot, no smoothin
        hPeakPlot=0;    %Peak Plot
        hPeakStimPlot=0;
        hRunAvgPlot=0;  %fast avgerage, 
        hRunAvgSPlot=0; %slow average, used für runMax
        
        hRunPeakPlot=0;  % Running Maximum of fast running Average
        hRunBasePlot=0;  % Running Minimum of slow running Average 
        
        hThreshPlot=0;
        hStretchPlot=0;
        %
        pixSum
        hP_pixSum
        hP_centerLine
        
        hSelect=0;
        %
        hActBox=0;
        hActPeakBox=0;
        %
        hFreqAxes=0; %axes for freq and force plot
        %
        hRect=0;   %rectangle for heat map plot
        %
        % for performance reasons do not plot Freq for now
        %plotFrequencies=false;
        hFreqPlot=0; %frequency plot
        hForceAxes=0;
        hForcePlot=0;  %force plot
        %
        hTextBox=0
        hFreqBox=0
        hForceBox=0
        hForceStimBox=0
        hRelStimBox  =0
        %
        hForce=0;  %Force for selected Area
        hFreq=0;   %Frequency for selected Area
        %
        hImgTitle=0
        %
        hPcAxes=0;
        %
        image=[]
        %
        circRange=[2 10]
        %
        cutL=255
        cutR=255
        %
        bUseAnimatedLine=false;
        bChangesPending=false;
        %
        nKeepL
        nKeepR
        minL=0
        minR=0
        %
        bPlot=true;    % turn on/of single update
        %
        bPlotDistance=true;
        plotDirection='reverse';
        
        bOK=false;
        bActPeak=1;     % Active->green, else red
        Frequency=[]
        FreqTime=[]
        Fit=[];
        FitPos=[];
        %
        residuals=nan(1,200)
        skipped=0
        %
        iRow=1
        sRow='A'    %row string
        iCol=1      %col number
        sCol='1'
        %
        %hParent=0
        %kHooke=1;          %Hooke's spring constant
        %
        distFile
        freqFile
        peakFile
        %
        % image scaling
        grayRange=30;
        binWidth=2;
        imageScale=[];
        %
        houghX=[];
        houghY=[];
        houghR=[];
        houghDist=0;
        %
        curDist
        %
        pole_length=14;
        ehm_pos = 8.5;  %mm height on pole
    end
    
    methods
        %
        function Self = OOwell(hParent, name)
            %            
            if exist('name','var')
                Self.sWell(name);
            end            
            %
            Self.hParent=hParent;
            %
            hParent.copyParameter(Self);
            %
        end
        %
        function plotForce(Self)
            bPlotDictance=false;
            plotDirection='normal';
        end
        
        function plotDistance(Self)
            bPlotDictance=true;
            plotDirection='reverse';
        end
        
        function empty(Self)
            Self.Distance=[];
            %Self.Peak=[];
            Self.PeakList.empty();
        end
        %        
        function destroy(Self)
            
        end                
        %
        %  very rudimentary form to conver distance to force
        %
        function distance_to_force(Self)
            %pixel_per_mm=1;
            %mN_per_mm = 1.5;   %default value for TM5MED as measured
            %equi_dist_mm=3.9;  %nominal pole equilibrium distance
            dist_mm = Self.Distance / Self.pixel_per_mm;
            max_mm=max(dist_mm);
            Self.Force = (max_mm - dist_mm) * Self.mN_per_mm * Self.ehm_pos / Self.pole_length;                              
        end
        
        
        function name=sWell(Self, name)
            %
            if exist('name','var')
                Self.name=upper(name);
                S=regexp(Self.name,['(?<row>[A-Z]+)(?<col>[0-9]+)'], 'names');
                %
                Self.sRow=S.row;
                Self.iRow=abc2num(S.row);
                Self.iCol=S.col;
            end
            %
            if (Self.hTextBox~=0)
                Self.updateName;
            end
            %
            name=Self.name;
        end
        
        function id=iWell(Self, id)
            if exist('id','var')
                Self.id=id;
            end
            id=Self.id;
        end
        
        function f=time(Self,n)
            f=Self.Time(n)            
        end
                
  
        
        
        function initializeWellSelector(Self, hAxes)
            %
            Self.hSelect=rectangle('Position', [Self.iCol-0.3, Self.iRow-0.3, 0.6, 0.6 ],...
                'Parent', hAxes, 'Curvature',1, 'FaceColor','g', ...
                'Selected','off', 'ButtonDownFcn', {@OOwell.select_Callback, Self});
            %
        end
        
        function f=minPeakHeight(Self)
            f=Self.minPeakHeight;
        end
        %
        function initializePlot(Self, w)
            %
            Self.hPlotParameter=w;
            %
            y_pos=0.2;
            height=0.2;
            %
            img_width=0.3;
            img_height=0.1;
            %
            % starting position for pos string
            %
            pos=[w.xOff y_pos w.Id height];
            %
            % place text box with string
            %
            S=struct('style','text','FontSize',12, 'Parent', w.hFigure, 'Units','normalized');
            S.HorizontalAlignment='Center';
            %S.VerticalAlignment='Center';
            %S.style='edit';
            %
            Self.hTextBox=uicontrol(S,'String',Self.name);
            set(Self.hTextBox,'Position',pos);
            set(Self.hTextBox,'BackgroundColor',[0.5 0.5 0.5]);
            %
            % place Frequency box
            %
            %move the box            
            pos= [pos(1)+pos(3) y_pos w.Frq height];            
            Self.hFreqBox=uicontrol(S,'String','0');
            set(Self.hFreqBox,'Position',pos);
            set(Self.hFreqBox,'BackgroundColor','r');
            %
            % Ratio of stimulated versus unstimulated peaks
            if Self.bStimulated
                pos= [pos(1)+pos(3) y_pos w.Frq height];            
                Self.hRelStimBox=uicontrol(S,'String','0');
                set(Self.hRelStimBox,'Position',pos);
                set(Self.hRelStimBox,'BackgroundColor','y');
            end
            %
            % place Force box
            pos= [pos(1)+pos(3) y_pos w.Frc height];
            %
            Self.hForceBox=uicontrol(S,'String','0');
            set(Self.hForceBox,'Position',pos);
            set(Self.hForceBox,'BackgroundColor','r');
            %
            % place Force Stimulated box
            % to copare stimulated and unstimulated peaks
            %especially intersting for mech. stimulation where we see 
            %Franck-Starling response 
            if Self.bStimulated
                pos= [pos(1)+pos(3) y_pos w.Frc height];
                %
                Self.hForceStimBox=uicontrol(S,'String','0');
                set(Self.hForceStimBox,'Position',pos);
                set(Self.hForceStimBox,'BackgroundColor','r');
            end
            %
            %
            % place the Image if needed
            %
            if w.bRoiPlot
                initializeRoiPlot(Self, w.hFigure, [pos(1)+pos(3) y_pos w.Img img_height]);
            end
            %
            % Place bActive Checkbox
            %
            pos= [pos(1)+pos(3) y_pos w.Act height];
            Self.hActBox=uicontrol(w.hFigure,'Style','checkbox','Value',1,'Units','normalized','Position',pos);
            %
            pos= [pos(1)+pos(3) y_pos w.Act height];
            Self.hActPeakBox=uicontrol(w.hFigure,'Style','checkbox','Value',1,'Units','normalized','Position',pos);
            %
            pos= [pos(1)+pos(3) y_pos 1-w.xOff-pos(1)-pos(3) height];
            %
            Self.hPlotAxes=axes('Parent',w.hFigure, 'Position',pos, 'ytick',[]);
            %
            %Self.initializeGraphs();
            %
            set(Self.hPlotAxes, 'ButtonDownFcn', {@OOwell.mouse_Callback, Self});       
            
            
            set(Self.hActBox,     'Callback',    {@OOwell.bActive_Callback, Self});
            set(Self.hActPeakBox, 'Callback',    {@OOwell.bActPeak_Callback, Self});            
        end
        
        function initializeRoiPlot(Self, pos)
            %
            hFig=Self.hPlotParameter.hFigure;            
            Self.hImgAxes = axes('Parent',hFig, 'Units', hFig.Units, 'Position',pos,...
                               'YTickLabel', '{}','XTickLabel', '{}', 'NextPlot','Add');
           Self.hImgAxes.YDir='reverse';
           %Self.image=ones(Self.roiRows,Self.roiCols,'uint8')*180;
           %
           Self.scaleImage;
           Self.hImage   = image(Self.imageScale, 'Parent',Self.hImgAxes);
           Self.hImgAxes.Visible='off'; 
           Self.hImgAxes.XLim=[1 Self.roiCols]; 
           Self.hImgAxes.YLim=[1 Self.roiRows];
           Self.updateImage;
        end
        
        function n=roiRows(Self)
            n=Self.hParent.roiRows;
        end
        
        function n=roiCols(Self)
            n=Self.hParent.roiCols;
        end
        
        function initializePixSumPlot(Self)
           Self.pixSum=sum(Self.image);            %
           Self.hP_pixSum = plot(Self.pixSum/max(Self.pixSum)*0.75*Self.roiRows, 'Parent',Self.hImgAxes);
        end
        
        function initializeCenterLinePlot(Self)
           Self.hP_centerLine = plot([Self.roiCols/2 Self.roiCols/2], [0 Self.roiRows], 'Parent',Self.hImgAxes);
        end
        
        function initializeGraphs(Self)
            %
            lastFrame = 500;            
            %
            Self.hPlotAxes.NextPlot='Add';
            Self.hPlotAxes.YDir=Self.plotDirection;
            %
            set(Self.hPlotAxes, 'yLimMode', 'auto');
            set(Self.hPlotAxes, 'UserData', Self);
            set(Self.hPlotAxes, 'Tag','Axes');
            %
            %hRunAvgPlot
            %
            Self.hRunAvgPlot  = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','b', 'Tag','runAvg', 'Marker','none');
            Self.hRunAvgSPlot = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','b', 'Tag','runAvgS', 'Marker','none');            
            %raw data
            Self.hPlot       = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'LineStyle','none', 'Marker','.');
            %
            Self.hRunBasePlot = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','g');
            Self.hRunPeakPlot = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','r');
            Self.hThreshPlot = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','y');
            % these ones should be on top
            %
            Self.hStretchPlot = plot(nan(1,lastFrame),'Parent',Self.hPlotAxes,'Color','green');
            
            Self.hRunBasePlot.Visible='On';
            Self.hThreshPlot.Visible='On';
            Self.hRunAvgPlot.Visible='On';
            Self.hRunAvgSPlot.Visible='On';
            Self.hStretchPlot.Visible='On';
            %
            Self.hPeakPlot     = plot([nan],[nan],'vr', 'Parent',Self.hPlotAxes, 'MarkerFaceColor', 'r', 'Tag','Peak');
            Self.hPeakStimPlot = plot([nan],[nan],'vg', 'Parent',Self.hPlotAxes, 'MarkerFaceColor', 'g', 'Tag','PeakStim');
            %
            % have the Xgrid moving with distance and the Y-grid static
            set(Self.hPlotAxes,'XGrid','on');
            set(Self.hPlotAxes,'Box','on');
            %
            %
            hX=get(Self.hPlotAxes,'XLabel');
            hY=get(Self.hPlotAxes,'YLabel');
            %
            set(hX,'String','Frame');
            set(hY,'String','Distance [pixel]');
            set(hY,'Visible','off');
            %
        end
        
        function hidePlots(Self)
            error('do not use');
            
        end
        
        
        
        function reset(Self)
            Self.Distance=[];
            %Self.Time=[];
            Self.PeakList.empty();
            cmap=winter(16);
            set(Self.hPlot,'YData',[]);
            set(Self.hPeakPlot,'XData',[],'YData',[]);
            set(Self.hPeakStimPlot,'XData',[],'YData',[]);
            set(Self.hFreqBox,'String',sprintf('%1.2f', 0));
            set(Self.hFreqBox,'BackgroundColor',cmap(1,:));
            set(Self.hForceBox,'String',sprintf('%1.2f%%', 0));
            set(Self.hForceBox,'BackgroundColor',cmap(1,:));
        end
        
        function resetPlot(Self)
            lastFrame=Self.hParent.lastFrame;
            set(Self.hPlot, 'YData', nan(1,lastFrame));
            %axis(Self.hPlotAxes,'tight');
        end
        %
        function n=nPeak(Self)
            n=Self.PeakList.n;
        end
        %
        function n=lastMinimum(Self)
            %
            if Self.PeakList.n
                n=Self.PeakList.last.Position.minR;
            else
                n=1;
            end
        end
        
        function n=lastMaximum(Self)
            %
            if Self.nPeak
                n=Self.PeakList.last.Position.max;
            else
                n=1;
            end
        end
        
        function f=pixel_per_mm(Self)
            f=Self.hParent.pixel_per_mm;
        end
        
        function peaks=analyzePeaks(Self)
            %
            Self.PeakList.empty;
            %
            %frame=find( ~isnan(Self.Minimum) );
            frame=find( ~isnan(Self.Peaks) );
            %
            npeak=numel(frame);
            %
            bIgnoreWarnings=false;
            %
            for i=1:npeak
                %
                peak=OOpeak(Self);
                peak.fitType=Self.peakFitType;
                peak.fps    = Self.framesPerSecond;
                %    analyze(Self, i,   base,  rAvg, dist,  prev, next)
                pPos=frame(i);
                %
                if Self.bAnalyzeForces
                    bOK=peak.analyze(pPos, Self.runBase(pPos), Self.runAvg, Self.Force); 
                    continue
                end
                %analyse Distances
                
                
                %bOK=peak.analyze(pPos, Self.runBase(pPos), Self.runAvg, Self.Distance);    
                
                bOK=peak.timepoints(pPos, Self.runBase(pPos), Self.runAvg);    
                %
                
                if (~bOK)
                    continue;
                end
                ny=peak.stop-peak.start+1;
                peak.fitWeight = ones(ny ,1);
                %
                if i > 1    && peak.start < frame(i-1)
                    %have a double peak
                    yy = Self.runAvg(frame(i-1):pPos-1);
                    pp = intersect(flipud(yy), max(yy));
                    peak.t1=i-pp;
                end              
                %
                if i < npeak && peak.stop > frame(i+1)
                    %have a double peak
                    yy =Self.runAvg(pPos+1 : frame(i+1));
                    pp = intersect(yy, max(yy));
                    peak.t4=pPos+pp;
                end                                
                %                
                
                peak.fit(pPos, Self.runBase(pPos),Self.Distance);
                %
                if pPos > numel(Self.bStimOn)
                    %fprintf('OOwell::analyzePeaks: problem peak %d pos %d > numel %d\n', i, pPos, numel(Self.bStimOn));
                    peak.bStim=0;
                    peak.bStimOn=0;
                else
                    peak.bStim   = Self.bStim(pPos);
                    peak.bStimOn = Self.bStimOn(pPos);
                end
                %
                if (bOK && ~peak.bNoise)                    
                    %
                    if (Self.PeakList.n > 0)
                        peak.RR=peak.time - Self.PeakList.last.time;
                    end
                    %
                    %peak.energy(Self.pixel_per_mm, Self.mN_per_mm, Self.equi_dist_mm, Self.dFramesPerSecond);
                    
                    Self.PeakList.add(peak);                    
                elseif (Self.PeakList.bEmpty || i==npeak)
                    %if iOK is flase we have so far no valid peaks and this one would be the first
                    if (~ Self.bQuiet)
                      disp('OOwell::analyzePeaks: skip first/last  peak');
                    end
                else
                  msg=sprintf('WARNING OOwell: %s Peak %i of %i at %i is Noise', Self.sWell, i, npeak, pPos);
                  if (Self.bInteractive && ~bIgnoreWarnings)                    
                    %answer = questdlg('Noise Peak in Trace','Ignore','Ignore All');
                    answer = questdlg(msg, 'Noise Peak in Trace','Ignore','Ignore All','Cancel','Ignore');
                    switch answer
                        case 'Ignore All'
                            bIgnoreWarnings=true;
                        case 'Cancel'
                            break;
                    end
                    %h=msgbox(msg, 'Noise Peak in Trace');
                    %uiwait(h)
                  else
                      disp(msg);
                  end
                end
            end            
        end
        %
        function removePeaks(Self)
            Self.removePeaksPlot();
            Self.PeakList.empty;            
            set(Self.hPeakPlot,'XData',[],'YData',[]);
            set(Self.hPeakStimPlot,'XData',[],'YData',[]);
            set(Self.hFreqBox,'String',sprintf('%1.2f', 0));
            set(Self.hForceBox,'String', sprintf('%1.2f%%', 0));            
        end
        %
        %        
        function data=peakTime(Self)
            nPeak = Self.PeakList.n;
            %
            data=zeros(nPeak,1);
            %
            for i=1:nPeak
                data(i)=Self.PeakList.get(i).timepoint;
            end            
        end
        
        function data=peakForce(Self)
            nPeak = Self.PeakList.n;
            %
            data=zeros(nPeak,1);
            %
            for i=1:nPeak
                data(i)=Self.PeakList.get(i).force;
            end
            
        end
        %
        function data=peakHeight(Self)
            nPeak = Self.PeakList.n;
            %
            data=zeros(nPeak-2,1);
            %
            for i=2:nPeak-1
                data(i-1)=Self.PeakList.get(i).height;
            end
            
        end
        %
        function data=fitTime(Self)
            nPeak = Self.PeakList.n;
            %
            data=[];
            %
            for i=2:nPeak-1
                data=vertcat(data, Self.PeakList.get(i).fitTime);
            end
            
        end
        %
        function data=fitForce(Self)
            %
            data=[];
            %
            for i=2:Self.PeakList.n-1
                data=vertcat(data, Self.PeakList.get(i).fitForce);
            end
            
        end
        %
        function inactive(Self)
            if Self.hImage ~=0
                set(Self.hImage,    'Visible','off');
            end
            set(Self.hPlot,     'Visible','off');
            set(Self.hPeakPlot, 'Visible','off');
            set(Self.hPeakStimPlot, 'Visible','off');
            set(Self.hPlotAxes, 'Visible','off');
            %
            set(Self.hTextBox, 'Visible','Off');
            set(Self.hFreqBox, 'Visible','Off');
            set(Self.hForceBox, 'Visible','Off');
            set(Self.hActBox, 'Visible','Off');
            %
            %
            hX1=get(Self.hPlotAxes,'XLabel');
            set(hX1,'Visible','off');
            hX2=get(Self.hPlotAxes,'XLabel');
            set(hX2,'Visible','off');
        end
        
        function active(Self)
            %
            if Self.hImage~=0
                set(Self.hImage,   'Visible','on');
            end
                Self.hPlot.Visible='On';
                Self.hPeakPlot.Visible='On';
                Self.hPeakStimPlot.Visible='On';
                Self.hPlotAxes.Visible='On';
                Self.hTextBox.Visible='On';
                Self.hFreqBox.Visible='On';
                Self.hForceBox.Visible='On';
                Self.hActBox.Visible='On';
            %set(Self.hFit,      'Visible','on');
            %set(Self.hMiss,     'Visible','on');
            %set(Self.bBox1,    'Visible','on');
            %set(Self.bBox2,    'Visible','on');
            %set(Self.bBox3,    'Visible','on');
            %set(Self.hFreqPlot,'Visible','on');
        end
        %
        function n=curFrame(Self)
            n=Self.hParent.curFrame;
        end
        %
        function fName=writeDistances(Self, fileRoot);
            %
            fName = [fileRoot '_' Self.sWell '.csv'];
            fh=fopen(fName, 'w');
            fps=Self.hParent.framesPerSecond;
            %
            %fprintf('Well %s write frames %d to %d, have %d\n', Self.sWell, 1, Self.curFrame, numel(Self.Distance) )
            %
            for i=1:Self.curFrame
                
                fprintf(fh, '%6.2f, %6.2f\r\n', i/fps, Self.Distance(i));
            end
            fclose(fh);
            Self.distFile=fName;
        end
        %
        
        
        %
        function fName=writePeaks(Self, fileRoot);
            %
            fName = [fileRoot '_' Self.sWell '.csv'];
            %
            fh=fopen(fName, 'w');
            %
            fps=Self.hParent.framesPerSecond;
            %
            last_peak = Self.PeakList.get(1);
            for i=2:Self.nPeak
                peak = Self.PeakList.get(i)
                pos  = peak.Position.max;
                time = peak.timepoint/fps;
                force= peak.force;
                RR   = (peak.timepoint-last_peak.timepoint)/fps;
                %fprintf(fh, '%8i %6.2f %6.2f %6.2f\r\n', Self.PeakPos(i), t, Self.Peak(i), RR);
                vAsc  = peak.Asc.slope/fps;
                vDesc = peak.Asc.slope/fps;
                %Self.Asc.tmin
                fprintf(fh, '%8i, %6.2f, %6.2f, %6.2f, %6.2f, %6.2f\r \n', pos, time, force, RR, peak.Asc.tmin, peak.Asc.tmax,peak.Desc.tmax,peak.Desc.tmin);
                last_peak=peak;
            end
            fclose(fh);
            Self.peakFile=fName;
        end
        %
        function readPeaks(Self, fName)
            Self.peakFile=fName;
            S = dir(fName);
            if S.bytes == 0
                sprintf('File %s has only %d bytes, skip\n', fName, S.bytes)
                return
            end
            %
            [path,filename,ext] = fileparts(fName);
            %
            fprintf('Loading %s\n', fName)
            %
            switch ext
                case ['.' Self.sWell]
                    fid=fopen(fName,'r');
                    data = fscanf(fid,'%f',[4 inf]);
                    Self.PeakPos=data(1,:);
                    Self.Peak=data(3,:);
                    %
                    fclose(fid);
                case '.csv'
                    data=dlmread(fName,';');
                    Self.PeakPos=data(1,:);
                    Self.Peak=data(3,:);
                otherwise
                    error(sprintf('Filetype >%s< of %s nOK', ext, fName))
            end
            
            
        end
        %
        function distance2force(Self)            
            Self.Force = Self.kHooke * (Self.maxDistance()-Self.Distance);
        end
        
        function nDist=readDistances(Self, fName)
            %
            s = dir(fName);
            if s.bytes < 20
                disp(sprintf('file %s is (almost) empty', fName))
            else
                Self.distFile=fName;
                fid=fopen(fName,'r');
                %
                bBinary=max(fread(fid,100)) > 255;
                fseek(fid, 0,-1);
                %
                if bBinary
                    %assume FMI Data
                    data = fread(fid,inf,'uint16');
                    Self.Force=data;
                else
                    [path,filename,ext] = fileparts(fName);
                    switch ext
                        case ['.' Self.sWell]
                            data = fscanf(fid,'%f',[2 inf]);
                            Self.Distance=data(2,:)';
                            Self.Time    =data(1,:)';
                        case '.csv'
                            data=dlmread(fName,';');
                            Self.Distance=data(2,:)';
                            Self.Time    =data(1,:)';
                        otherwise
                            error(sprintf('Filetype >%s< of %s nOK', ext, fName))
                            
                    end
                end
                fclose(fid);
            end
            nDist=numel(Self.Distance);
        end
        %
        function loadDistances(Self, data)
            %
            [cols rows]=size(data);
            %
            if cols==1
                Self.Distance=data(1,:)';
                Self.Time    =1:rows;
            elseif cols==2
                Self.Time    =data(1,:)'
                Self.Distance=data(2,:)';
            else
                error(sprintf('can not handle %d cols', cols));
            end
        end
        %
        function scaleImage(Self)
            % make Histogram of gray values and scale image to
            % range around max
            N=histcounts(Self.image, Self.binWidth-1:Self.binWidth:255);
            [val pos] = max(N);
            minVal=Self.binWidth*pos-Self.grayRange/2;
            maxVal=Self.binWidth*pos+Self.grayRange/2;                    
            Self.imageScale=(Self.image-minVal)*(256/Self.grayRange);
                    
        end
        %
        function updateImage(Self)
            set(Self.hImage, 'CData', Self.imageScale);
        end
        %
        function updatePixelSum(Self)
            Self.pixSum=sum(Self.image);            %
            Self.hP_pixSum.YData=Self.pixSum/max(Self.pixSum)*0.75*Self.roiRows;
        end
        
        function internal(Self)
            % remove X Label from all internal plots
            Self.hPlotAxes.XTickLabelMode='manual';
            Self.hPlotAxes.XTickLabel=[];            
            Self.hPlotAxes.XLabel.Visible='off';            
            %Y
            Self.hPlotAxes.YTickLabelMode='manual';
            Self.hPlotAxes.YTickLabel=[];            
            Self.hPlotAxes.YLabel.Visible='off';            
        end
        %
        function last(Self)
            set(Self.hPlotAxes,'XTickMode','auto','XTickLabelMode','auto');
            hX1=get(Self.hPlotAxes,'XLabel');
            set(hX1,'Visible','on');            
        end
        %        
        %
        function save(Self)
            %
            bIncr= Self.hParent.curFrame > 1;
            %
            if isnan(Self.curDist)
                %Self.skipped             = Self.skipped+1;
                %Self.missTime(end+bIncr) = Self.hParent.curTime;
                %Self.Miss(end+bIncr)     = -0.01;
            else
                %Self.hParent.Time(end+bIncr)     = Self.hParent.curTime;
                Self.Distance(end+bIncr) = Self.curDist;
            end
            
        end
        %
        function saveTraces(Self)
            %save deconvoluted Data
            n=numel(Self.Time);
            A=nan(n,5);
            A(:,1)=Self.Time;
            A(:,2)=Self.DistanceStretch;
            A(:,3)=Self.ForceRaw;
            A(:,4)=Self.Force;                 
            A(:,5)=Self.ForceStretch;
            %Self.stretchFactor=An(1);
            [path fRoot ext]=fileparts(Self.fName);
            path=Self.fPathIn;
            fOut=fullfile(path, [fRoot '.traces.csv'])
            dlmwrite(fOut, A, ',');
            
            
        end
        
        function savePlotData(Self, hAxes)
           lines=hAxes.Children;
           cols=numel(lines);
           Len=zeros(cols,1);
           
           for j=1:numel(lines)
               Len(j)=numel( lines(j).YData);
           end
           [rows, lPos]=max(Len);
           %           
           [path fRoot ext]=fileparts(Self.fName);
           path=Self.fPathIn;
           fOut=fullfile(path, [fRoot '.peaks.csv'])
           fid  = fopen(fOut,'w');
           %
           for i=0:rows
                   for j=0:cols
                       if j==0
                           if i==0
                               fprintf(fid,'peaks num,');
                           else
                             %print x data into col 0
                             fprintf(fid,' %.2f,',lines(lPos).XData(i));
                           end
                       elseif j < cols
                          if i==0
                              %write header
                              fprintf(fid,''' %.0f,',j);
                          else
                              %write data
                              if  i<Len(j) && ~isnan(lines(j).YData(i))
                                  fprintf(fid,' %.2f,',lines(j).YData(i));
                              else
                                  fprintf(fid,' ,');
                              end
                          end
                       else
                           if i==0
                              %write header w/o comma
                              fprintf(fid,''' %.0f',j);
                          else
                              %write data w/o comma
                              if i<Len(j) && ~isnan(lines(j).YData(i))
                                  fprintf(fid,' %.2f',lines(j).YData(i));
                              else
                                  %fprintf(fid,',');
                              end
                          end
                       end
                   end
                   fprintf(fid,'\n');
           end
           fclose(fid);           
           
        end
        
        function stats(Self)
            %
            nDist=numel(Self.Distance);
            %
            if Self.hParent.bStats &&  nDist > 1
                % stat the last xxx distances
                start=max(1,nDist-Self.hParent.fitWinFrame);
                %
                Self.maxDist =  max(Self.Distance(start:end));
                Self.avgDist = mean(Self.Distance(start:end));
                Self.devDist =  std(Self.Distance(start:end));
            else
                Self.maxDist=Self.curDist;
                Self.avgDist=Self.curDist;
                Self.devDist=Self.curDist*0.3;
            end
            %
            Self.curForce=Self.kHooke*(Self.maxDist-Self.curDist);
            Self.fitForce=fit_sine_power( Self.fitParameter{end}, [Self.hParent.curTime]);
            Self.curRes=abs(Self.curForce-Self.fitForce);
            Self.avgRes=mean(Self.residuals);
            %
            Self.relFitRes=Self.curRes/Self.avgRes;
            % circular buffer
            Self.residuals = [Self.curRes, Self.residuals(1:end-1)];
            %
        end
        
        function rescalePlot(Self)
            nWell=Self.hPlotParameter.nWell;
            iWell=Self.iWell;
            hSpace=Self.hPlotParameter.headSpace;
            fSpace=Self.hPlotParameter.footSpace;
            Self.scalePlot(nWell,iWell,hSpace,fSpace);  
        end
        
        function rescale(Self)
            nWell=Self.hPlotParameter.nWell;
            iWell=Self.iWell;
            hSpace=Self.hPlotParameter.headSpace;
            fSpace=Self.hPlotParameter.footSpace;
            Self.scalePlot(nWell,iWell,hSpace,fSpace);
            Self.scaleControl(nWell,iWell,hSpace,fSpace);        
        end
        
        function scalePlot(Self, nWell, iWell, headSpace, footSpace)
            %
            height = (1-headSpace-footSpace)/nWell;
            yOff=1-headSpace-height*iWell;
            %
            pos=get(Self.hPlotAxes,'Position');
            set(Self.hPlotAxes,  'Position', [pos(1) yOff pos(3) height]);
            %
        end
        %
        function scaleControl(Self, nWell, iWell, headSpace, footSpace)
            %
            height = (1-headSpace-footSpace)/nWell;
            yOff=1-headSpace-height*iWell;
            %
            %
            pos=get(Self.hTextBox,'Position');
            set(Self.hTextBox,  'Position', [pos(1) yOff pos(3) height]);
            %
            pos=get(Self.hFreqBox,'Position');
            set(Self.hFreqBox,  'Position', [pos(1) yOff pos(3) height]);
            %
            if isobject(Self.hRelStimBox)
                pos=get(Self.hRelStimBox,'Position');
                set(Self.hRelStimBox,  'Position', [pos(1) yOff pos(3) height]);
            end
            %
            pos=get(Self.hForceBox,'Position');
            set(Self.hForceBox,  'Position', [pos(1) yOff pos(3) height]);
            %
            %
            if isobject(Self.hForceStimBox)
                pos=get(Self.hForceStimBox,'Position');
                set(Self.hForceStimBox,  'Position', [pos(1) yOff pos(3) height]);
            end
            %
            pos=get(Self.hActBox,'Position');
            set(Self.hActBox,  'Position', [pos(1) yOff pos(3) height]);
            %
            pos=get(Self.hActPeakBox,'Position');
            set(Self.hActPeakBox,  'Position', [pos(1) yOff pos(3) height]);
            %
            if Self.hImgAxes~=0
                pos=get(Self.hImgAxes,'Position');
                set(Self.hImgAxes,  'Position', [pos(1) yOff pos(3) height]);
            end            
        end
        %
        function updatePlots(Self)
            if (Self.bPlotDistance)
                Self.updateDistancePlot;
            else
                Self.updateForcePlot;
            end
            Self.updatePeaksPlot;
            Self.updateAveragePlot;
            Self.updateAverageSPlot
            Self.updateMinPlot;
            Self.updateMaxPlot;
            Self.updateThreshPlot;
            Self.scaleXaxis;
            Self.scaleYaxis;
            Self.updateBasePlot
        end
        
        function updateName(Self)
            set(Self.hTextBox,  'String',  Self.name);
        end
        
        function updatePeaksPlot(Self)
            %set(Self.hPeakPlot, 'XData', Self.Frame,'YData', Self.Minimum);
            set(Self.hPeakPlot, 'XData', Self.Frame,'YData', Self.Peaks);
        end
        
        
        
        function updateDistancePlot(Self)
            % set new Y data
            set(Self.hPlot, 'XData', Self.Frame, 'YData', Self.Distance);
            % scale X axes
            Self.scaleXaxis();
            Self.scaleYaxis();
        end
        %
        function updateForcePlot(Self)
            % set new Y data
            set(Self.hPlot, 'XData', Self.Frame, 'YData', Self.Force);
            % scale X axes
            Self.scaleXaxis();
            Self.scaleYaxis();
        end
        %
        function scaleYaxis(Self)
            %
            Ymin=min(Self.Distance(Self.firstFrame:Self.lastFrame));
            Ymax=max(Self.Distance(Self.firstFrame:Self.lastFrame));
            %
            if ~isnan(Ymin) && ~isnan(Ymax) && Ymin ~= Ymax
                dR=diff([Ymin Ymax]);
                set(Self.hPlotAxes,'YLim', [Ymin-dR*0.1 Ymax+dR*0.1]);
            end
        end
        %
        function scaleXaxis(Self, range)
           % set new Y data
           if ~exist('range','var')      
              range=Self.range;
           end
           set(Self.hPlotAxes,'XLim', range);           
        end
        %
        function updateDistancePlotData(Self, range, ydata)
            error('no use')
            % set new Y data
            set(Self.hPlot, 'XData', range(1):range(2), 'YData', ydata);           
        end
        %
        function updateAveragePlot(Self)
            % set new Y data
            set(Self.hRunAvgPlot, 'XData', Self.Frame, 'YData', Self.runAvg);
        end
        %
        function updateAverageSPlot(Self)
            % set new Y data
            set(Self.hRunAvgSPlot, 'XData', Self.Frame, 'YData', Self.runAvgS);
            set(Self.hRunAvgSPlot, 'Visible', 'Off');
        end
        %
        function updateMinPlot(Self)
            set(Self.hRunBasePlot, 'XData', Self.Frame, 'YData', Self.runMin);
        end
        
        function updateMaxPlot(Self)
            set(Self.hRunPeakPlot, 'XData', Self.Frame, 'YData', Self.runMax);
        end
        
        function updateBasePlot(Self)
            set(Self.hRunBasePlot, 'XData', Self.Frame, 'YData', Self.runBase);
        end
        
        function updatePeakPlot(Self)
            set(Self.hRunPeakPlot, 'XData', Self.Frame, 'YData', Self.runPeak);
        end
       
        
        function updateThreshPlot(Self)
            % set new Y data
            set(Self.hThreshPlot, 'XData', Self.Frame, 'YData', Self.runThresh);
        end
        %
        function xLim(Self, range)
            set(Self.hPlotAxes,'XLim', range);
        end
        %
        %function bAct=autoSetActive(Self)
        %    %
        %    frq=str2num(get(Self.hFreqBox, 'String'));
        %    frc=str2num(get(Self.hForceBox, 'String'));
        %
        %    bAct=false;
        %    if frc > 1 && frq > 0.3
        %        bAct=true;
        %    end
        %    set(Self.hActBox, 'Value',  bAct);
        %end
        
        function updateFreq(Self)
            %
            %
            if numel(Self.PeakPos) >=2
                %
                %RR interval in seconds
                %
                RR_int = (Self.PeakPos(end)-Self.PeakPos(end-1))/Self.hParent.framesPerSecond;
                % beats per minute
                bpm=60/RR_int;
                %
                nCol=length(Self.hParent.cmap);
                scaleF=Self.hParent.bpmColorScale;
                %
                % convert to BPM  [20 52]
                %
                %
                colorId=floor( max (min((bpm-scaleF(1))*(nCol/diff(scaleF)),nCol),1 ));
                %
                set(Self.hFreqBox, 'BackgroundColor', Self.hParent.cmap(colorId,:));
                set(Self.hFreqBox, 'String',  num2str(bpm,'%2.1f'));
            end
            
        end
        %
        function roi(Self, roiRows, roiCols)
            %
            Self.firstRow=Self.hParent.firstRoiRow+Self.iRow*Self.hParent.gridRows;
            Self.firstCol=Self.hParent.firstRoiCol+Self.iCol*Self.hParent.gridCols;
            %
            % re-position cutoff string
            %
            set(Self.hImgAxes, 'XLim', [0.5 roiCols+0.5]);
            set(Self.hImgAxes, 'YLim', [0.5 roiRows+0.5]);
            %
        end
        %
        function update(Self)
            %
            Self.mRoiL = single(Self.hParent.image(Self.RanL(1):Self.RanL(2), Self.RanL(3):Self.RanL(4)));
            %
            % filter so we only keep the darkest 80% of all pixel
            %
            Self.mRoiL(Self.mRoiL>Self.cutL) = Self.cutL;   %bleach other pixel
            Self.mRoiL=(Self.mRoiL-Self.minL) / (Self.cutL-Self.minL) ;  % scale to [0 255]
            %
            % do the same for the right side
            %
            Self.mRoiR = single(Self.hParent.image(Self.RanR(1):Self.RanR(2), Self.RanR(3):Self.RanR(4)));
            % filter so we only keep the darkest 80% of all pixel
            Self.mRoiR(Self.mRoiR>Self.cutR)=Self.cutR;
            Self.mRoiR=(Self.mRoiR-Self.minR) / (Self.cutR-Self.minR) ;
        end
        %
        %
        function resizeRoi(Self, roiRows, roiCols)
            Self.image=ones(roiRows, roiCols, 'uint8');
            set(Self.hImgAxes,'XLim',[0 roiCols+1]);
            set(Self.hImgAxes,'YLim',[0 roiRows+1]);
        end
        %
        function mask(Self)
            rel_size=Self.hParent.relMask;
            x  = Self.wellSize;
            cx = x/2;           %circle center -> center
            r  = x/2 * rel_size;  %radius
            [xx,yy] = ndgrid((1:x)-cx,(1:x)-cx);
            Self.Mask = (xx.^2 + yy.^2) < r^2;
        end
        %
        %
        %
        function time=analyzeHough(Self)
            %
            nCol=Self.roiCols/2;
            %
            minRad=8;
            maxRad=20;
            %
            pHough=struct('Method', 'TwoStage', 'ObjectPolarity','bright');
            %
            [centers, radii, metric] = imfindcircles(Self.imageScale(:,1:nCol),[minRad maxRad],pHough);
            %
            if numel(metric)
               Self.houghX(1)=centers(1,1);
               Self.houghY(1)=centers(1,2);
               Self.houghR(1)=radii(1);
            else
               Self.houghX(1)=10;
               Self.houghY(1)=10;
               Self.houghR(1)=5;
            end
            %
            [centers, radii, metric] = imfindcircles(Self.imageScale(:,nCol+1:nCol*2),[minRad maxRad], pHough);
            %
            if numel(metric)
              %important: add nCol to get reference to 0,0
              Self.houghX(2)=centers(1,1)+nCol;
              Self.houghY(2)=centers(1,2);
              Self.houghR(2)=radii(1);
            else
              Self.houghX(2)=10;
              Self.houghY(2)=10;
              Self.houghR(2)=5;
            end
            %
            Self.distHough(i)=diff(Self.houghX);
            %
            %
            time=toc;
            
        end
        
        
        function analyzeCHT(Self)
            %
            %
            bWeight=true;
            bWeightCM=true;
            %
            [a, Self.circCentL] = CH_accumArray(Self.mRoiL,Self.circRange,bWeight, bWeightCM);
            set(Self.hCrossL, 'XData', Self.circCentL(1), 'YData', Self.circCentL(2));
            %
            [a, Self.circCentR] = CH_accumArray(Self.mRoiR,Self.circRange,bWeight, bWeightCM);
            set(Self.hCrossR, 'XData', Self.circCentR(1), 'YData', Self.circCentR(2));
            %
            Self.curDist=Self.RoiL(3)- Self.circCentL(1) + Self.circCentR(1);
            %
            %sprintf('x Left %6.1f x Right %6.1f Dist %6.1f\n', Self.RoiL(3)- Self.circCentL(1), Self.circCentR(1), Self.curDist)
            %
        end
        
        function analyzeCircles(Self)
            %
            %
            % Compute the accumulator array
            objPolarity=Self.hParent.objPolarity;
            edgeThresh=Self.hParent.edgeThresh;
            sensitivity=Self.hParent.sensitivity;
            radiusRange=Self.hParent.radiusRange;
            %
            [accumMatrix, gradientImg] = chaccum(Self.mRoi, radiusRange,'ObjectPolarity', objPolarity,'EdgeThreshold',edgeThresh);
            %
            % Check if the accumulator array is all-zero
            %
            Self.nBlob=0;
            %
            if  any(accumMatrix(:))
                % Estimate the centers
                accumThresh = 1 - sensitivity;
                [centers, metric] = chcenters(accumMatrix, accumThresh);
                idx2Keep = find(metric >= accumThresh);
                %
                if any(idx2Keep)
                    % Retain circles with metric value greater than threshold corresponding to AccumulatorThreshold
                    centers = centers(idx2Keep,:);
                    metric = metric(idx2Keep,:);
                    % Estimate radii
                    phasecode=true;
                    %
                    if phasecode
                        r_estimated = chradiiphcode(centers, accumMatrix, radiusRange);
                    else
                        %two-stage
                        r_estimated = chradii(centers, gradientImg, radiusRange);
                    end
                    %
                    %
                    Self.nBlob=numel(r_estimated);
                    %
                end
            end
            %
            Self.curDist=nan;
            %
            switch Self.nBlob
                case 0
                    sprintf( 'analyzeStrecher: %s found %d Circles between %d and %d', Self.sWell, Self.nBlob, radiusRange(1), radiusRange(2))
                case 1
                    sprintf( 'analyzeStrecher: %s found %d Circles between %d and %d', Self.sWell, Self.nBlob, radiusRange(1), radiusRange(2))
                    Self.bbox(1,1:4)= [centers(1,:) - r_estimated(1) r_estimated(1) r_estimated(1)];
                case  2
                    Self.curDist = norm(centers(1,1:end) - centers(2,1:end));
                    %sprintf( 'analyzeCircles: %s found %d Circles with radii %f and %f', Self.sWell, Self.nBlob, r_estimated(1), r_estimated(2))
                    Self.bbox(1,1:4)=[centers(1,:) - r_estimated(1) 2*r_estimated(1) 2*r_estimated(1)];
                    Self.bbox(2,1:4)=[centers(2,:) - r_estimated(2) 2*r_estimated(2) 2*r_estimated(2)];
                otherwise
                    sprintf( 'analyzeStrecher: %s found %d Circles between %d and %d', Self.sWell, Self.nBlob, radiusRange(1), radiusRange(2))
                    Self.bbox(1,1:4)=[centers(1,:) - r_estimated(1) 2*r_estimated(1) 2*r_estimated(1)];
                    Self.bbox(2,1:4)=[centers(2,:) - r_estimated(2) 2*r_estimated(2) 2*r_estimated(2)];
                    Self.bbox(3,1:4)=[centers(3,:) - r_estimated(3) 2*r_estimated(3) 2*r_estimated(3)];
            end
            
            
        end
        
        function plotPeaks(Self)
            for n=1:Self.PeakList.n
                peak = Self.PeakList.get(n);
                peak.plot(Self.hPlotAxes);                 
            end
        end
        %
        function removePeaksPlot(Self)
             for i=1:Self.PeakList.n
                Self.PeakList.get(i).removePlot();                   
             end
        end
        
        function plotPointcare(Self)
             if (Self.hPcAxes==0)
                 fh = figure;
                 Self.hPcAxes=axes();
             end
             
             Self.analyzePeaks();
             
             if ~Self.bActive || Self.PeakList.n < 3
                 return 
             end
                 
             rr =Self.PeakList.getValues('RR');
             %plot(rr(2:end-1), rr(3:end), 'Parent', Self.hPcAxes, 'LineStyle','', 'MarkerStyle', 'O' );
             plot(rr(2:end-1), rr(3:end), 'Parent', Self.hPcAxes, 'LineStyle','none', 'Marker', '.', 'MarkerSize',25 );             
             % calc stats
             %function [mx my] = heart_rate_variability(Self, rr)
             [mx my] = Self.heart_rate_variability(rr);
             %plot ellipse
             tt=0:0.02:(2*pi);
             iyye=my(2)*sin(tt);
             ixxe=mx(2)*cos(tt)+mx(1);           
             % plot ellipse
             plot(ixx(1:numel(ixxe)),iyy(1:numel(ixxe)),'color',[0,0,0]); %elipse
             %plot SD lines
             plot(ixx(numel(ixxe)+[1,2]),iyy(numel(ixxe)+[1,2]),'color',[0,0,0]) %SD1
             plot(ixx(numel(ixxe)+[1,3]),iyy(numel(ixxe)+[1,3]),'color',[0,0,0]) %SD2
             %    
        end
        %
        %
        function RR=RR(Self)
            nPeak=Self.PeakList.n;
            %
            RR=zeros(nPeak-1,1);
            last_peak=Self.PeakList.get(1);
            for i=2:nPeak
                peak=Self.PeakList.get(1)
                RR(i)=peak.timepoint - last_peak.timepoint;
                last_peak=peak;
            end
        end
        
        function freq=frequency(Self)
            RR=Self.RR;
            %
            %  well    panel  gpu     video
            fps=Self.hParent.framesPerSecond;
            %
            if numel(RR)
                freq=1/mean(RR)*fps;
            else
                freq=0;
            end
        end
        %
        function plotPeakRange(Self,range)
            %Self.hPeakPlot= plot([nan],[nan],'v', 'Parent',Self.hPlotAxes);
            %set(ph.peaks,    'XData',    peakTime , 'YData', well.peakHeight);
            %
            % since PEaks are in mN but the axis System is in Pixel Deflection we
            % need to convert to get to same scale
            cmap=winter(16);
            R=[0.5 1];
            %
            nPeak=Self.PeakList.n;
            %
            if nPeak
                %
                pTime={};
                pForce={};
                RR={};
                %
                last_peak=Self.PeakList.get(1);
                for i=2:nPeak
                    peak=Self.PeakList.get(i);
                    if peak.Position.max > range(1) && peak.Position.max < range(2)
                        pTime{end+1} =peak.timepoint;
                        pForce{end+1}=peak.force;
                        RR{end+1}=peak.timepoint-last_peak.timepoint;                        
                    end
                    last_peak=peak;
                end
                %
                %disp('plot peaks')
                set(Self.hPeakPlot,'XData',cell2mat(pTime),'YData',Self.maxDistance-cell2mat(pForce)/Self.kHooke);
                %
                if numel(RR)
                    %disp('calc Freq')
                    freq=1/mean(cell2mat(RR))*Self.hParent.framesPerSecond;
                else
                    freq=0;
                end
                %
                set(Self.hFreqBox,'String',sprintf('%1.2f', freq));
                %
                if freq < R(1)
                    set(Self.hFreqBox,'BackgroundColor',cmap(1,:));
                elseif freq > R(2)
                    set(Self.hFreqBox,'BackgroundColor',cmap(end,:));
                else
                    i=ceil( (freq-R(1))/R(2)*16);
                    set(Self.hFreqBox,'BackgroundColor',cmap(i,:));
                end
            elseif Self.PeakList.n ~= numel(get(Self.hPeakPlot,'XData'))
                set(Self.hPeakPlot,'XData',[],'YData',[]);
                set(Self.hFreqBox,'String',sprintf('%1.2f', 0));
                set(Self.hFreqBox,'BackgroundColor',cmap(1,:));
            end
        end
        %
        function Xlim(Self, range)
            set(Self.hPlotAxes, 'XLim',range);
        end
        %
        function updateMeans(Self)            
            %
            frq    =0;
            frc    =0;
            frcStim=0;
            bse    =1;
            %                
            if Self.bActive && Self.bActPeak
                [frq frc bse]=Self.getPeakMeans();
            end
            %            
            nColor=length(Self.cmap);               
            %
            if frq > Self.minFreq && frq < Self.maxFreq
                frqColor=floor( max ( min((frq-Self.scaleFrq(1))*(nColor/diff(Self.scaleFrq)),nColor),1 ));
            else
                frqColor=1;
            end
            %
            set(Self.hFreqBox,'String',sprintf('%1.2f', frq));
            set(Self.hFreqBox, 'BackgroundColor', Self.cmap(frqColor,:));
            %
            if isobject(Self.hRelStimBox)
              set(Self.hRelStimBox,'String',sprintf('%1.2f', 0));
            end
            %
            
            if (~Self.bPeakAbs)
              % relative peak height, e.g. from myrPlate
              % convert Force to pct as in contraction
              foc=abs(frc/bse);
              set(Self.hForceBox,'String',sprintf('%2.1f%%', foc*100));
            else
              %absolute peaks e.g. from myoFarm
              foc=frc
              set(Self.hForceBox,    'String',sprintf('%3.2f%', abs(foc)));
              set(Self.hForceStimBox,'String',sprintf('%3.2f%', abs(foc)));            
            end            
            %
            if foc> 0
                focColor=floor( max (min((foc-Self.scaleFrc(1))*(nColor/diff(Self.scaleFrc)),nColor),1 ));
            else
                focColor=1;
            end
            %
            %
            set(Self.hForceBox, 'BackgroundColor', Self.cmap(focColor,:));
            %
        end
        
        
        %
        function openFigure(Self)
            %
            hFig = figure('Units','normalized', 'Position',[.05 0.5 0.8 .3]);
            %
            set(hFig, 'Toolbar', 'figure');
            set(hFig, 'name', sprintf('Distances %s (%d)', Self.name, Self.id),...
                'numbertitle','off','Menubar','none');
            %
            set(hFig, 'WindowScrollWheelFcn',  {@OOwell.mouseWheel_Callback, Self});
            set(hFig, 'WindowButtonMotionFcn', {@OOwell.mouseMove_Callback, Self});
            set(hFig, 'CloseRequestFcn',       {@OOwell.closeMain_Callback, Self});
            set(hFig, 'WindowButtonUpFcn',     {@OOwell.mouseUp_Callback, Self});       
            set(hFig, 'WindowButtonDownFcn',   {@OOwell.mouseDown_Callback, Self});       
            
            set(hFig, 'name', sprintf('Distances %s  %s', Self.tag, Self.fName));
            %
            Self.hPlotAxes.Parent=hFig;
            
            Self.scalePlot(1, 1, 0.01, 0.05);
            %hAxes= axes('Parent',hFig, 'Position',[0.02 0.05 0.87 0.94], 'ytick',[]);%
            Self.hPlotAxes.Visible='on';
            Self.hPlotAxes.XTickMode='auto';
            Self.hPlotAxes.XTickLabelMode='auto';
            Self.hPlotAxes.XLabel.Visible='on';
            Self.hPlotAxes.YTickMode='auto';
            Self.hPlotAxes.YTickLabelMode='auto';
            Self.hPlotAxes.YLabel.Visible='on';
            %
            %well=Self.clone(hAxes);
            %well.analyzeDistances();
            % make sure changes made in new Plot are copied back
            % into original
            %
            Self.hPlot.MarkerSize=12;
            
            Self.hPeakPlot.MarkerSize=12;
            Self.hPeakPlot.ButtonDownFcn = {@OOwell.removePeak_Callback, Self};
            %
            Self.hPeakStimPlot.MarkerSize=12;
            %
            % Add Symbols and Manual Peak Selection/Editing            
            Self.hRunAvgPlot.Marker='v';
            Self.hRunAvgPlot.MarkerSize=6;
            Self.hRunAvgPlot.MarkerEdgeColor='m';
            Self.hRunAvgPlot.MarkerFaceColor= 'm';
            Self.hRunAvgPlot.ButtonDownFcn = {@OOwell.addPeak_Callback, Self, Self.hPeakPlot};
            %
            Self.hRunAvgSPlot.Visible='On';
            %
            Self.updateAverageSPlot;
            % Interactive Controls
            S_txt=struct('style','text','FontSize',9,'Units','Normalized');
            S_edt=struct('style','edit','FontSize',12,'Units','Normalized');
            S_btn=struct('Style','pushbutton', 'Units','Normalized');
            %
            hFit =uicontrol(S_btn,'Position',[ 0.01 0.90 0.05 0.09],  'String','Fit Peaks');
            set(hFit,  'Callback', {@OOwell.analyzePeaks_Callback, Self});
            %waitfor(hFig);
            hSave =uicontrol(S_btn,'Position',[ 0.06 0.90 0.05 0.09],  'String','Save');
            set(hSave,  'Callback', {@OOwell.saveTraces_Callback, Self});
            
            hSup =uicontrol(S_btn,'Position',[ 0.01 0.80 0.05 0.09],  'String','Superpose');
            set(hSup,  'Callback', {@OOwell.superposePeaks_Callback, Self});
            
            hSupStim =uicontrol(S_btn,'Position',[ 0.06 0.80 0.05 0.09],  'String','SupStim');
            set(hSupStim,  'Callback', {@OOwell.superposeStim_Callback, Self});
            
            
            %set(hSup,  'Callback', {@OOwell.superposePeaks_Callback, well, well.hPlotAxes});
            %set(S.hFreq,   'Callback',   {@OOwell.freq_Callback,Self,S} );
            S.Noise =Self.addDialFf(hFig, 'Noise',  Self.noiseThresh, @OOwell.noise_Callback,  0.01, 0.70, 0.1 , 0.14);
            S.Height=Self.addDialFf(hFig, 'Height', Self.peakThresh,  @OOwell.height_Callback, 0.01, 0.55, 0.1 , 0.14);
            S.Freq  =Self.addDialFf(hFig, 'Freq',   Self.maxFreq,     @OOwell.freq_Callback,   0.01, 0.40, 0.1 , 0.14);
            S.Pixel =Self.addDialFf(hFig, 'Pixel',  Self.noisePx,     @OOwell.pix_Callback,    0.01, 0.25, 0.1 , 0.14);
            %
            uicontrol(S_txt,'String','Force', 'Position',[0.010, 0.08, 0.05,0.08]);
            uicontrol(S_txt,'String','Freq', 'Position', [0.065, 0.08, 0.05,0.08]);
            
            Self.hForce=uicontrol(S_edt,'String','nan', 'Position', [0.010, 0.03,0.05,0.08]);
            Self.hFreq =uicontrol(S_edt,'String','nan', 'Position', [0.065, 0.03,0.05,0.08]);
            
            
            
        end
        
        function setActPeak(Self, bActive)
            %
            Self.hActPeakBox.Value=bActive;
            Self.bActPeak=bActive;
            if Self.bActPeak
               Self.setActive(bActive);
               Self.findPeaks;
               Self.updatePeaksPlot;
            end
            %            
            Self.updateMeans();
            %
        end
        %
        function [x y]=getFittedPeaks(Self)
           x=zeros(Self.PeakList.n,1);
           y=zeros(Self.PeakList.n,1);
           
           for i=1:Self.PeakList.n
              peak=Self.PeakList.get(i);
              x(i)=peak.time;
              y(i)=peak.max;
           end
        end
        
        function setActive(Self, bActive)
            %
            Self.bActive=bActive;
            Self.hActBox.Value=bActive;
            %            
            if (Self.bActive && Self.bActPeak)
                   Self.findPeaks;
                   Self.updatePeaksPlot();
            else
                   Self.removePeaks();                  
            end
            %            
            Self.updateMeans();
        end
        
        function S=addDialFf(Self, hFig, title, val, cb, xPos, yPos, width, height)
            % Label can be on Top or next to dial
            bVert=1;
            %
            S=struct;            
            %
            if bVert
                txt_width=width;
                arr_width=width;
                txt_height=height*0.5;
                height=height/2;                
            else
                txt_height=height*1;
                txt_width =width*0.4;
                arr_width =width-txt_width;
            end
            
            S_txt=struct('style','text','FontSize',12,'Units','Normalized', 'Parent', hFig);
            S_btn=struct('Style','pushbutton', 'Units','Normalized', 'Parent', hFig);            
            S_edt=struct('style','edit','FontSize',12, 'Units','Normalized', 'Parent', hFig);
            %
            uicontrol(S_txt,'String',title,'Position',[xPos yPos txt_width txt_height]);                        
            %'verticalAlignment','bottom', 'horizontalAlignment','center'
            if bVert
                yPos=yPos-height;
            else
                xPos=xPos+txt_width;
            end
            %
            wStep=arr_width/12;
            S.frw=uicontrol(S_btn,'Position',[ xPos+ 0*wStep yPos 1.9*wStep txt_height], 'String','<<');
            S.rw =uicontrol(S_btn,'Position',[ xPos+ 2*wStep yPos 1.9*wStep txt_height], 'String','<');
            S.edt=uicontrol(S_edt,'Position',[ xPos+ 4*wStep yPos 3.9*wStep txt_height], 'String', sprintf('%4.2f', val));
            S.fw =uicontrol(S_btn,'Position',[ xPos+ 8*wStep yPos 1.9*wStep txt_height], 'String','>');
            S.ffw=uicontrol(S_btn,'Position',[ xPos+10*wStep yPos 1.9*wStep height], 'String','>>');
            %set(S.hFreq,   'Callback',   {@OOvideoAnalysisPanel.freq_Callback,Self,S} );
            set(S.frw, 'Callback', {cb, Self, S,-0.10} );
            set(S.rw,  'Callback', {cb, Self, S,-0.01} );
            set(S.edt, 'Callback', {cb, Self, S, 0.00} );
            set(S.fw,  'Callback', {cb, Self, S, 0.01} );
            set(S.ffw, 'Callback', {cb, Self, S, 0.10} );
        end
        
        function addWaypoint(Self, xPos)
           hAxes=Self.hPlotAxes;           
           YLim=get(hAxes, 'YLim');
           xMax=numel(Self.Time);
           trans=0.3;
           color = getColor(Self.cmap, xPos, 1, xMax);
           %
           hLine=line([xPos xPos], YLim, 'Parent',hAxes,'Linewidth',5, 'Color', [color, trans] );
           Self.waypoint(end+1)=xPos;
           Self.hWaypoint(end+1)=hLine;           
           hLine.ButtonDownFcn = {@OOwell.waypoint_Callback, Self, xPos};
           %
           Self.checkWaypoints;
           %
        end
        
        function checkWaypoints(Self)
            if ~(Self.hForce==0)
               if (numel(Self.waypoint)==2)
                    Self.calcRangeStats; 
               else
                    Self.hForce.String='nan';
                    Self.hFreq.String='nan';
               end
           end
        end
        
        function calcRangeStats(Self)
            % do average between waypoints
            start=min([Self.waypoint(1), Self.waypoint(2)]);
            stop =max([Self.waypoint(1), Self.waypoint(2)]);
            [pos foc bse] = Self.getPeaksRange(start,stop);
            if ~(Self.hForce==0)
                Self.hForce.String=sprintf('%4.2f', mean(foc));
                RR = diff(pos);
                frq=Self.framesPerSecond/mean(RR);                
                Self.hFreq.String =sprintf('%4.2f', mean(frq));
            end
            %copy forc of contraction to clipboard
            clipboard('copy', mean(foc));
        end
        
        function foc=getWaypointFoc(Self, xPos)
          foc=nan;
          if Self.bAnalyzeForces
             if xPos<Self.bufferSize
                foc=Self.runPeak(xPos)-Self.runBase(xPos);
             end
          else
             foc=Self.runMax(xPos)/Self.runMin(xPos)-1;
          end          
        end
        
        function removeWaypoint(Self, xPos)
            pos=find(Self.waypoint==xPos);
            delete(Self.hWaypoint(pos));
            Self.hWaypoint(pos)=[];
            Self.waypoint(pos)=[];
            %
            Self.checkWaypoints;            
           %
        end
        
        function axesPan(Self, xy)                       
            mv = xy-Self.mousePos;
            xlim=Self.hPlotAxes.XLim;
            ylim=Self.hPlotAxes.YLim;
            if (xy(1) > xlim(1) && xy(1) < xlim(2))                
                set(Self.hPlotAxes, 'XLim', xlim - [mv(1) mv(1)]);
                Self.mousePos(1)=xy(1);
            end
            if ( xy(2) > ylim(1) && xy(2) < ylim(2) )                
                set(Self.hPlotAxes, 'YLim', ylim - [mv(2) mv(2)]);
                Self.mousePos(2)=xy(2);
            end
            
        end
        
        
    end
    
    methods(Static)
        %        
        function savePeakOverlay_Callback(hFig, event, Self, hAxes)
            Self.savePlotData(hAxes);
        end
        
        function waypoint_Callback(hLine, eventdata, Self, xPos)            
            Self.hParent.removeWaypoint(xPos);           
        end
        
        function select_Callback(hRect, eventdata, Self)
            
            switch Self.bActive
                case true
                    hRect.FaceColor=[1 0 0];
                    Self.bActive=false;
                otherwise
                    hRect.FaceColor=[0 1 0]
                    Self.bActive=true;
            end
        end
        %
        function bActive_Callback(hBox, eventdata, Self)
            %
            bActive=hBox.Value;
            Self.setActive(bActive);
            if (~ bActive)
                bActPeak=hBox.Value;
                Self.setActPeak(bActPeak);
            end
        end
        
        function bActPeak_Callback(hBox, eventdata, Self)
            %
            bActPeak=hBox.Value;
            Self.setActPeak(bActPeak);
            
        end
        
        function mouseWheel_XZoom(hFig, eventdata, Self)
            hAxes=Self.hPlotAxes;
            move=eventdata.VerticalScrollCount*0.1;
            xpos=Self.hPlotAxes.CurrentPoint(1,1);
            XLim=get(hAxes, 'XLim');
            newL=XLim(1)+(XLim(1)-xpos)*move;
            newR=XLim(2)+(XLim(2)-xpos)*move;
            hAxes.XLim = [newL newR];            
        end
        
        function mouseUp_Callback(hFig, event, Self)
            %
            %sTyp=get(hFig.Parent,'selectiontype')
            %sMod=get(hAxes.Parent, 'CurrentModifier');
            %
            Self.bPan=false;            
        end
        
        function mouseDown_Callback(hFig, event, Self)         
          Self.mousePos = Self.hPlotAxes.CurrentPoint(1,1:2);
          Self.bPan     = true;          
        end
        
        function mouse_Callback(hAxes, eventdata, Self)
            %
            sTyp=get(hAxes.Parent,'selectiontype');
            sMod=get(hAxes.Parent, 'CurrentModifier');
            %
            switch sTyp
                case 'normal'
                    % LEFT CLICK                    
                case 'extend'
                    % SHIFT-CLICK LEFT (or L/R simultaneous)
                    Self.hParent.removeWaypoints();
                case 'alt'
                    % CTRL-CLICK LEFT (or RIGHT-CLICK)
                    %
                    % Add Analysis Point for all             %
                    xpos=round(Self.hPlotAxes.CurrentPoint(1,1) , 0);
                    %
                    Self.hParent.addWaypoint(xpos);
                    %
                case 'open'
                    % DOUBLE-CLICK
                    S=struct;
                    % open new figure with enlarged graph
                    Self.openFigure;
                    Self.checkWaypoints;                    
                otherwise 
                    disp('mouse action not known');
            end
        end
        %
        function mouseMove_Callback(hFig, event, Self)
            %ah=gca;
            %disp('moseMove')
            if Self.bPan
                Self.axesPan(Self.hPlotAxes.CurrentPoint(1,1:2));
            end
        end
        
        %
        function noise_Callback(hObj, eventdata, Self, S, factor)
            val =str2double(S.edt.String);
            val =val+val*factor;
            S.edt.String=sprintf('%3.2f', val);
            %
            Self.bChangesPending=true;
            %
            Self.noiseThresh(val);
            Self.findPeaks();
            Self.updateThreshPlot();
            Self.updatePeaksPlot();
        end
        
        function height_Callback(hObj, eventdata, Self, S, factor)
            val =str2double(S.edt.String);
            val =val+val*factor;
            S.edt.String=sprintf('%3.2f', val);
            %
            Self.bChangesPending=true;
            %
            Self.peakThresh(val);
            Self.findPeaks();
            Self.updateThreshPlot();
            Self.updatePeaksPlot();
        end
        
        function freq_Callback(hObj, eventdata, Self, S, factor)
            val =str2double(S.edt.String);
            val =val+val*factor;            
            S.edt.String=sprintf('%3.2f', val);            
            %
            Self.bChangesPending=true;
            %
            Self.maxFrequency(val);
            %Self.maxFreq=val;            
            %n=oddify(Self.framesPerSecond/val);
            %Self.setNeighborLength(n);
            Self.analyzeTraces();   %required to update neighBuffSize
            nPeak=Self.findPeaks();
            Self.updateThreshPlot();
            Self.updatePeaksPlot();
            Self.updateMaxPlot();
            Self.updateMinPlot();
        end
        
        function pix_Callback(hObj, eventdata, Self, S, factor)
            val =str2double(S.edt.String);
            val =val+val*factor;
            S.edt.String=sprintf('%3.2f', val);            
            %
            Self.bChangesPending=true;
            %
            Self.noisePx(val);
            nPeak=Self.findPeaks();
            Self.updateThreshPlot();
            Self.updatePeaksPlot();
        end
        
        %
        function analyzePeaks_Callback(hObj, eventdata, Self)
             Self.removePeaksPlot();
             Self.analyzePeaks();             
             Self.plotPeaks();
        end
        
        function saveTraces_Callback(hObj, eventdata, Self)
             Self.saveTraces();             
        end
        
        function superposeStim_Callback(hObj, eventdata, Self)
             %
             %
             if ~ numel(Self.PeakList)
                h=errordlg('No Peaks Found', 'No Peaks in Trace');
                uiwait(h)
                return
            end
            %
            Self.analyzePeaks();
            %
            hFig = figure('Units','normalized', 'Position',[.05 0.2 0.4 .6]);
            %
            set(hFig, 'name', sprintf('Peak Superposition %s (%d)', Self.sWell,Self.iWell),...
                'numbertitle','off','Menubar','none');
                %
             set(hFig, 'Toolbar', 'figure');
             %
             S=struct();
             S_btn=struct('Style','pushbutton', 'Units','Normalized');
             %             
             S.hPlotAxes=axes('Parent',hFig,'NextPlot','Add','Tag','Axes');
             % gen Save Button             
             S.hSave = uicontrol(S_btn,'Position',[ 0.01 0.90 0.05 0.09],  'String','Save');
             %
             set(S.hSave, 'Callback',         {@OOwell.savePeakOverlay_Callback, Self, S.hPlotAxes});
             set(hFig, 'WindowScrollWheelFcn',{@OOwell.mouseWheel_Callback, S});
             %
             fps=Self.framesPerSecond;
             %
             [frqData frcData bseData]= Self.getPeakStats();
             transp=0.4;
             fps=Self.framesPerSecond;
             %
             A=nan(Self.PeakList.n,1);
             %
             for i=1:Self.PeakList.n
                 %
                 peak=Self.PeakList.get(i);
                 A(i)=peak.superposeStim(Self.hPlot.YData, Self.DistanceStretch, Self.stimThresh);                 
                 %x=x/fps*1000; %convert frames to ms
                 color =Self.getColor(peak.height, frcData(4), frcData(3));                 
                 line(peak.Time*1000/fps, peak.Trace,    'Parent',S.hPlotAxes, 'linewidth',2, 'Color',[color, transp]);                 
                 line(peak.Time*1000/fps, peak.Distance, 'Parent',S.hPlotAxes);                 
             end
             %
             S.hPlotAxes.YTickLabel=sprintf('%3.2f\n', S.hPlotAxes.YTick);
             ylabel(S.hPlotAxes, 'Twitch Force [mN]');
             xlabel(S.hPlotAxes, 'Time [ms]');
        end
        %
        function superposePeaks_Callback(hObj, eventdata, Self,hAxes)
             %
             %
             if ~ numel(Self.PeakList)
                h=errordlg('No Peaks Found', 'No Peaks in Trace');
                uiwait(h)
                return
            end
            %             
            hFig = figure('Units','normalized', 'Position',[.05 0.2 0.2 .3]);
            %
            set(hFig, 'name', sprintf('Peak Superposition %s (%d)', Self.sWell,Self.iWell),...
                'numbertitle','off','Menubar','none',...
                'WindowScrollWheelFcn',@OOwell.mouseWheel_Callback);
                %
             set(hFig, 'Toolbar', 'figure');
             %
             hAxes=axes('Parent',hFig,'NextPlot','Add','Tag','Axes');
             fps=Self.framesPerSecond;
             %
             xData=Self.hPlot.XData;
             yData=Self.hPlot.YData;
             %
             %Self.hParent.fps=25;
             
             for i=1:Self.PeakList.n
                 %
                 peak=Self.PeakList.get(i);
                 %for n=1:numel(Self.PeakList)
                 %strt=Self.PeakList{n}.frame-(width-1)/2;
                 %stop=Self.PeakList{n}.frame+(width-1)/2;                     
                 strt=floor(peak.t1-7);
                 stop=ceil(peak.t4+7);
                 base=peak.base;
                 if strt>0 && stop < numel(yData)
                         y=yData(strt:stop)-base;
                         x=[strt:stop]-peak.frame;
                         x=x/fps*1000; %convert frames to ms
                         plot(x,y, 'Parent',hAxes);
                 end                 
             end             
             hAxes.YTickLabel=sprintf('%1.1f%%\n',hAxes.YTick);
             ylabel(hAxes, 'Twitch Force [mN]');
             ylabel(hAxes, 'time [ms]');
             
        end
        %
        function addPeak_Callback(hRunAvg, eventdata, Self, hPeak)
            %
            switch get(gcf,'selectiontype')
                case 'open'
                    % DOUBLE-CLICK
                    %pos =get(hRunAvg.Parent,'CurrentPoint');
                    xPos=round(Self.hPlotAxes.CurrentPoint(1,1));
                    xInd=find(hRunAvg.XData==xPos);
                    hPeak.YData(xInd)=hRunAvg.YData(xInd);
                    Self.Minimum(xInd)=Self.runAvg(xInd);
                    Self.Peaks(xInd)=Self.runAvg(xInd);
                    %hPeak.YData(xPos)=hRunAvg.YData(xPos);
                    Self.bChangesPending=true;
            end
            %
        end
        %
        function removePeak_Callback(hPeak, eventdata, Self)
            %
            switch get(gcf,'selectiontype')
                case 'open'
                    pos =get(hPeak.Parent,'CurrentPoint');
                    xPos=round(pos(1,1));
                    xInd=find(hPeak.XData==xPos);
                    hPeak.YData(xInd)=nan;
                    Self.Minimum(xInd)=nan;
                    Self.Peaks(xInd)=nan;
                    %hPeak.YData(xPos)=nan;
                    Self.bChangesPending=true;
            end
            %
        end
        %
        
        
        function mouseWheel_Callback(hFig, event, Self)
            %
            % if the mouse is currently over an axis object zoom into that axis
            %
            %hAxes=getChild(hFig, 'Axes');
            hAxes=Self.hPlotAxes;
            %
            move=event.VerticalScrollCount*0.1;  %move 10% per click
            %
            pos=Self.hPlotAxes.CurrentPoint;
            xpos=pos(1,1);
            ypos=pos(1,2);
            %
            XLim=get(hAxes, 'XLim');
            YLim=get(hAxes, 'YLim');
            %
            newL=XLim(1)+(XLim(1)-xpos)*move;
            newR=XLim(2)+(XLim(2)-xpos)*move;
            newT=YLim(1)+(YLim(1)-ypos)*move;
            newB=YLim(2)+(YLim(2)-ypos)*move;
            %
            switch get(hFig,'selectiontype')
                case 'normal'
                    hAxes.XLim = [newL newR];
                case 'alt'
                    hAxes.YLim = [newT newB];
                otherwise
                    hAxes.XLim = [newL newR];
                    hAxes.YLim = [newT newB];
            end
            %
        end
        %
        function closeMain_Callback(hObj, event, Self)
              %'Color','b', 'Tag','runAvg', 'Marker','none');
              Self.hRunAvgPlot.Marker='none';
              Self.hRunAvgPlot.ButtonDownFcn = [];                    
              % Move Plot to main Figure
              Self.hPlotAxes.Parent=Self.hPlotParameter.hFigure;
              %
              Self.hPeakPlot.MarkerSize=6;
              Self.hPeakPlot.ButtonDownFcn = [];           
              %Self.hPlotAxes.Visible='off';
              Self.hPeakStimPlot.MarkerSize=6;
              Self.hPeakStimPlot.ButtonDownFcn = [];           
              %
              if ~(Self.hForce==0)
                  delete(Self.hForce);
              end
              Self.hForce=0;
              Self.removePeaksPlot();
              Self.internal;
              Self.rescalePlot();
              delete(hObj)
        end
        
        
        
        %        
    end    
end