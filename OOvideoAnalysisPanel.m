classdef OOvideoAnalysisPanel < OOclass
    
    properties
        hParent=0;
        main
        %
        xLim=[1 500];         %plotRange
        outputOrder=[];
        %
        bChangesPending=false;
        bUseDb=false;
        %
        Db=0;
        bUploadTraces=true;
        bUploadPeaks=true;
        bWritePdf=true;
        %
        guiElement=struct;
        
        
        %
        flipImage=1;
        bPlot=true;
        bRoi=true;    %Plot Region of interest.
        %
        timer;
        cycleTime;
        previewTime;
        %
        %
        %firstFrame=1;
        lastFramePlotted=0;
        %
        hFigure;
        hPar;
        %handle to distance plots figure
        hFreq;        %handle to frequency plots figure
        hFreqTxt
        hThresh
        hThreshTxt
        hNoise
        hNoiseTxt
        hSave
        hDb
        hFps
        hAvg
        hFirst
        hLast
        %        
        parameterFile='parameter.xml'
        %
        dataFiles={}
        %
        % Analysis Parameter
        analysisWindow=200
        minPeakDist=100   %in milliseconds
        %minPeakHeight=0.07;
        %
        hDataBase
        %                              should sum to 1
        hPlotParameter=struct('xOff',0.01,'Id', 0.04, 'Frq',0.04','Frc',0.04,...
                               'Img',0.08,'Act',0.02, 'Plot',0.76, 'bRoiPlot',false,...
                               'nWell', 48, 'headSpace', 0.02, 'footSpace', 0.02, 'hFigure',0);
        %
        sTitle='Distances';
    end
    
    
    methods
        %
        function Self = OOvideoAnalysisPanel(analysis)
            % pos=[.2 .2 .6 .6];
            Self.hParent=analysis;
            %
            % parent should be OOvideoAnalysisGpu or OOvideoAnalysisCpu
            %
            saveParameter={'ratio','Roi','Rois','nWell',...
                'firstRow','firstCol','nRow','nCol','Roi',...
                'strecherDiameter','videoFile', 'firstFrame','lastFrame','curFrame',...
                'dataFiles','flipImage', 'pKeep','pixel_per_mm','gridRows','gridCols'};
            %
            Self.stateVars=unique({Self.stateVars{:} saveParameter{:}});
            
            %Set some defaults
            Self.hParent.minPeakHeight=0.07;
            %
            %
            Self.timer=tic;
            Self.cycleTime=toc(Self.timer);
            Self.previewTime=toc(Self.timer);
            %            
            %
            %Self.nRow=analysis.nRow;
            %Self.nCol=analysis.nCol;
            Self.xLim=[1 max([2 analysis.curFrame])];            
            %
        end
        %
        function open_Gui(Self)
            % open Panel
            Self.createFigure;
            Self.scale();
            %
            if Self.bRoi
                Self.resizeRoi(Self.hParent.roiRows, Self.hParent.roiCols);
                Self.updateImage;
            end
            %refreqh
            opengl software;
            set(Self.main, 'Renderer','OpenGL');
            colormap(Self.hFigure,gray(256));
            %
        end
        
        function open_GuiDb(Self)
            % open Panel
            Self.createFigure;
            Self.scale();
            %
            if Self.bRoi
                Self.resizeRoi(Self.hParent.roiRows, Self.hParent.roiCols);
                Self.updateImage;
            end
            %refreqh
            opengl software;
            set(Self.main, 'Renderer','OpenGL');
            colormap(Self.hFigure,gray(256));
            %
        end
        
        function createFigureDb(Self)
            % get numbe rand size of monitors
            mp = get(0, 'MonitorPositions');
            sz=size(mp);
            %  1921        -414        1200        1920
            %     1           1        1920        1200
            iScreen=1;
            %two or more screens, check if one monitor is portrait                
            for i=1:sz(1)
              if mp(i,4) > mp(i,3)
                  iScreen=i;
              end
            end
            %pos=[ mp(2,1) mp(2,2) mp(2,3) mp(2,4)]; %right (single) screen
            %
            pos=[ mp(iScreen,1) mp(iScreen,2)+50 mp(iScreen,3) mp(iScreen,4)-100]; %
            
            %
            Anal=Self.hParent;
            %
            hFig = figure('Position',pos,'Name','Distances', 'numbertitle','off');
            %set(hFigure, 'MenuBar', 'none');
            %set(hFigure, 'ToolBar', 'none');
            %
            Self.hFigure=hFig;
            %set(Self.hFigure, 'WindowButtonDownFcn', {@OOvideoAnalysisPanel.mouse_Callback, Self});
            %
            colormap(hFig,gray(256));
            %
            %
            w=Self.hPlotParameter;
            %
            h=w.headSpace;
            %
            yPos  = 1 - h*0.75;
            %
            yPos1= 1-h/2;
            yPos2= 1-h;            
            %
            Sui=struct('style','text','FontSize',12,'Units','Normal');
            %
            pos=[0.01, yPos, w.Id, h*0.75];
            uicontrol(Sui,'String','Id','Position',pos);
            %
            pos=[pos(1)+pos(3) pos(2) w.Frq pos(4)];
            uicontrol(Sui,'String','[Hz]','Position',pos);
            %Force
            pos=[pos(1)+pos(3) pos(2) w.Frc pos(4)];
            uicontrol(Sui,'String','px/mN', 'Position',pos, 'Tag','Force');
            %Force Stim
            pos=[pos(1)+pos(3) pos(2) w.Frc pos(4)];
            uicontrol(Sui,'String','px/mN', 'Position',pos, 'Tag','ForceStim');
            %
            S=struct;
            %
            % Now Push Buttons
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.06 h*.6];
            %
            if Self.bUseDb
                pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
                S.hDb  = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','To Db');
            end
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hBox = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Boxplot');
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hHeat = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Heatmap');
            
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hPoint = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','PointCare');
            
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hTetanic = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Tetanic');
            
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hPara = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Paramtr');
            
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hFps = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.framesPerSecond),'TooltipString', 'Frames Per Second of Recording');
            
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hAvg = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.runAvgLen), 'TooltipString', 'Length of noise filter');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hFirst = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Self.xLim(1,1)), 'TooltipString', 'First Frame to be Analyzed');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hLast = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Self.xLim(1,2)),'TooltipString', 'Last Frame to be Analyzed');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hRunAvgS = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.runAvgSLen),'TooltipString', 'Running Average Slow');            
            %            
            Self.hFirst=S.hFirst;
            Self.hLast=S.hLast;
            %
            set(S.hBox,  'Callback', {@OOvideoAnalysisPanel.boxplot_Callback,Self} );
            set(S.hHeat, 'Callback', {@OOvideoAnalysisPanel.heatmap_Callback,Self} );
            set(S.hPoint,'Callback', {@OOvideoAnalysisPanel.pointcare_Callback,Self} );
            set(S.hTetanic,'Callback', {@OOvideoAnalysisPanel.tetanic_Callback,Self} );
            set(S.hPara, 'Callback', {@OOvideoAnalysisPanel.paramtr_Callback,Self} );
            if Self.bUseDb
              set(S.hDb,   'Callback', {@OOvideoAnalysisPanel.toDb_Callback,   Self} );            
            end
            set(S.hFps,  'Callback', {@OOvideoAnalysisPanel.fps_Callback,    Self} );
            set(S.hAvg,  'Callback', {@OOvideoAnalysisPanel.avg_Callback,    Self} );
            set(S.hFirst, 'Callback', {@OOvideoAnalysisPanel.first_Callback, Self} );
            set(S.hLast,  'Callback', {@OOvideoAnalysisPanel.last_Callback,  Self} );
            set(S.hRunAvgS,  'Callback', {@OOvideoAnalysisPanel.runAvgSlow_Callback,  Self} );
            %
            colormap(Self.hFigure,gray(256));
            %
            set(hClose, 'CloseRequestFcn',   {@OOvideoAnalysisPanel.closeMain_Callback,Self} );
            set(hFig, 'WindowScrollWheelFcn',{@OOvideoAnalysisPanel.mouseWheel_Callback,Self} ); 
            %
            Self.guiElement=S;
        end
        
        
        function createFigure(Self)
            % get numbe rand size of monitors
            mp = get(0, 'MonitorPositions');
            sz=size(mp);
            %  1921        -414        1200        1920
            %     1           1        1920        1200
            iScreen=1;
            %two or more screens, check if one monitor is portrait                
            for i=1:sz(1)
              if mp(i,4) > mp(i,3)
                  iScreen=i;
              end
            end
            %pos=[ mp(2,1) mp(2,2) mp(2,3) mp(2,4)]; %right (single) screen
            %
            pos=[ mp(iScreen,1) mp(iScreen,2)+50 mp(iScreen,3) mp(iScreen,4)-100]; %
            
            %
            Anal=Self.hParent;
            %
            %hFig = figure('Position',pos, 'Name',Self.sTitle, 'numbertitle','off');
            hFig = figure('Position',pos, 'Name',Self.sTitle);
            %
            Self.hFigure=hFig;
            %set(Self.hFigure, 'WindowButtonDownFcn', {@OOvideoAnalysisPanel.mouse_Callback, Self});
            %
            colormap(hFig,gray(256));
            %
            %
            w=Self.hPlotParameter;
            %
            h=w.headSpace;
            %
            yPos  = 1 - h*0.75;
            %
            yPos1= 1-h/2;
            yPos2= 1-h;
            
            %
            Sui=struct('style','text','FontSize',12,'Units','Normal');
            %
            pos=[0.01, yPos, w.Id, h*0.75];
            uicontrol(Sui,'String','Id','Position',pos);
            %
            pos=[pos(1)+pos(3) pos(2) w.Frq pos(4)];
            uicontrol(Sui,'String','Frq','Position',pos);
            %
            pos=[pos(1)+pos(3) pos(2) w.Frc pos(4)];
            uicontrol(Sui,'String','Frc', 'Position',pos);
            %
            %pos=[pos(1)+pos(3) pos(2) w.Frc pos(4)];
            %uicontrol(Sui,'String','[pixel]', 'Position',pos);
            %
            %
            S=struct;
            %
            %
            % Now Push Buttons
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.06 h*.6];
            %
            S.hOpen=uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Open');
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hSave=uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Save');
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hDb  = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','To Db');
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hClose = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Close');
        
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hBox = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Boxplot');
            %
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hHeat = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Heatmap');
            
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hPoint = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','PointCare');
            
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hTetanic = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Tetanic');
                        
            pos=[pos(1)+pos(3)+.005 1-h*.7 0.05 h*.6];
            S.hPara = uicontrol('style','pushbutton',...
                'Units','Normal','Position',pos,'String','Paramtr');
            
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hFps = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.framesPerSecond),'TooltipString', 'Frames Per Second of Recording');
            
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hAvg = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.runAvgLen), 'TooltipString', 'Length of noise filter');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hFirst = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Self.xLim(1,1)), 'TooltipString', 'First Frame to be Analyzed');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hLast = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Self.xLim(1,2)),'TooltipString', 'Last Frame to be Analyzed');
            %
            pos=[pos(1)+pos(3)+.01 1-h*.7 0.05 h*.6];
            S.hRunAvgS = uicontrol('style','edit','Units','Normal',...
                'Position',pos,'String',num2str(Anal.runAvgSLen),'TooltipString', 'Running Average Slow');
            
            
            
            Self.hFirst=S.hFirst;
            Self.hLast=S.hLast;
            
            set(S.hOpen, 'Callback', {@OOvideoAnalysisPanel.open_Callback,   Self} );
            set(S.hSave, 'Callback', {@OOvideoAnalysisPanel.save_Callback,   Self} );
            set(S.hBox,  'Callback', {@OOvideoAnalysisPanel.boxplot_Callback,Self} );
            set(S.hHeat, 'Callback', {@OOvideoAnalysisPanel.heatmap_Callback,Self} );
            set(S.hPoint,'Callback', {@OOvideoAnalysisPanel.pointcare_Callback,Self} );
            set(S.hTetanic,'Callback', {@OOvideoAnalysisPanel.tetanic_Callback,Self} );
            set(S.hPara, 'Callback', {@OOvideoAnalysisPanel.paramtr_Callback,Self} );
            set(S.hDb,   'Callback', {@OOvideoAnalysisPanel.toDb_Callback,   Self} );            
            set(S.hClose,'Callback', {@OOvideoAnalysisPanel.closeMain_Callback,   Self} );            
            set(S.hFps,  'Callback', {@OOvideoAnalysisPanel.fps_Callback,    Self} );
            set(S.hAvg,  'Callback', {@OOvideoAnalysisPanel.avg_Callback,    Self} );
            set(S.hFirst, 'Callback', {@OOvideoAnalysisPanel.first_Callback, Self} );
            set(S.hLast,  'Callback', {@OOvideoAnalysisPanel.last_Callback,  Self} );
            set(S.hRunAvgS,  'Callback', {@OOvideoAnalysisPanel.runAvgSlow_Callback,  Self} );
            %
            colormap(Self.hFigure,gray(256));
            %
            set(hFig, 'CloseRequestFcn',     {@OOvideoAnalysisPanel.closeMain_Callback,Self} );
            set(hFig, 'WindowScrollWheelFcn',{@OOvideoAnalysisPanel.mouseWheel_Callback,Self} ); 
            %
            Self.guiElement=S;
        end
        % 
        
        function disableSave(Self)
            set(Self.guiElement.hSave, 'Enable','Off');
        end
        
        
        function openParameterFigure(Self)
            %
            mp = get(0, 'MonitorPositions');
            sz=size(mp);
            %  1921        -414        1200        1920
            %     1           1        1920        1200
            if sz(1)==1
                % single Monitor, use main screen
                pos=[ 200 200 400 400]; %left screen
            else
                %two or more screens, use second(ary), full
                pos=[ mp(2,1)+200 mp(2,2)+200 400 400]; %right (single) screen
            end
            %
            hFigure = figure('Position',pos, 'Name','Peak Fitting Parameter', 'numbertitle','off');
            %
            Self.hPar=hFigure;
            Anal=Self.hParent;
            %
            colormap(hFigure,gray(256));
            %
            %
            S_txt=struct('style','text','FontSize',12,'Units','Pixel');
            S_edt=struct('style','edit','FontSize',12,'Units','Pixel');
            %            
            %
            uicontrol(S_txt,'String','Noise Cutoff',     'Position',[50  50 100 20]);
            uicontrol(S_txt,'String','Height Cutoff',    'Position',[50 100 100 20]);
            uicontrol(S_txt,'String','Frequency',       'Position',[50 150 100 20]);
            uicontrol(S_txt,'String','Pixel',           'Position',[50 200 100 20]);
            uicontrol(S_txt,'String','Min/Max',         'Position',[50 250 100 20]);
            uicontrol(S_txt,'String','Mode',             'Position',[50 300 100 20]);
            %
            S=struct;
            %minThresh=10;   %img filter        
            S.hMinDist   =uicontrol(S_edt,'String',sprintf('%3.0f', Anal.minDist),          'Position', [160 250 50 20]);
            S.hMaxDist   =uicontrol(S_edt,'String',sprintf('%3.0f', Anal.maxDist),          'Position', [215 250 50 20]);
            S.hPixTxt    =uicontrol(S_edt,'String',sprintf('%4.2f', Anal.noisePx),          'Position', [160 200 50 20]);
            S.hFreqTxt   =uicontrol(S_edt,'String',sprintf('%4.2f', round(Anal.maxFreq,2)), 'Position', [160 150 50 20]);
            S.hThreshTxt =uicontrol(S_edt,'String',sprintf('%4.2f', Anal.peakThresh()),        'Position',[160 100 50 20]);
            S.hNoiseTxt  =uicontrol(S_edt,'String',sprintf('%4.2f', Anal.noiseThresh),      'Position', [160  50 50 20]);            %
            
            S.hNoise=uicontrol('style','slider','Parent', hFigure,...
                'Min',1,'Max',5, 'Value',Anal.noiseThresh, 'Units', 'Pixel',...
                'Position',[250 50 150 20], 'TooltipString', 'Any peaks lower than runMin+Noise*runNoise are ignored');
            
            S.hThresh=uicontrol('style','slider','Parent', hFigure,...
                'Min',0.01,'Max',1,'Value',Anal.peakThresh(),'Units','Pixel',...
                'Position',[250 100 150 20], 'TooltipString', 'Any peaks lower than runMin+(runMax-runMin)*Thresh are ignored');
            %
            S.hFreq=uicontrol('style','slider', 'Parent', hFigure,...
                'Min',0.1,'Max',5.0,'Value',Anal.maxFreq,'Units','Pixel',...
                'Position',[250 150 150 20], 'TooltipString', 'Any peaks closer are ignored');             
            %
            S.hPix=uicontrol('style','slider', 'Parent', hFigure,...
                'Min',0.01,'Max',2.0, 'Value', Anal.noisePx,'Units','Pixel',...
                'Position',[250 200 150 20], 'TooltipString', 'Any peaks lower dd pixel above base');             
            %
            S.bg  = uibuttongroup('Visible','on','Units','Pixel', 'Position',                          [150 300 250 30]);
            S.bg1 = uicontrol(S.bg,'Style','radiobutton','String','Regular','Units','Pixel','Position',[0 5 100 20], 'HandleVisibility','on');
            S.bg2 = uicontrol(S.bg,'Style','radiobutton','String','Tetanic','Position',                [130 5 100 20], 'HandleVisibility','on');  
            set(S.bg, 'SelectionChangedFcn',{@OOvideoAnalysisPanel.mode_Callback,Self,S} );
            
            
            set(S.hPix,    'Callback',   {@OOvideoAnalysisPanel.pix_Callback,Self,S} );
            set(S.hPixTxt, 'Callback',   {@OOvideoAnalysisPanel.pixTxt_Callback,Self,S} );
            set(S.hFreq,   'Callback',   {@OOvideoAnalysisPanel.freq_Callback,Self,S} );
            set(S.hFreqTxt,'Callback',   {@OOvideoAnalysisPanel.freqTxt_Callback,Self,S} );
            set(S.hNoise,  'Callback',   {@OOvideoAnalysisPanel.noise_Callback,Self,S} );
            set(S.hNoiseTxt, 'Callback', {@OOvideoAnalysisPanel.noiseTxt_Callback,Self,S} );
            set(S.hThresh,   'Callback', {@OOvideoAnalysisPanel.thresh_Callback,Self,S} );
            set(S.hThreshTxt,'Callback', {@OOvideoAnalysisPanel.threshTxt_Callback,Self,S} );
            set(S.hMinDist,'Callback',   {@OOvideoAnalysisPanel.minDist_Callback,Self,S} );
            set(S.hMaxDist,'Callback',   {@OOvideoAnalysisPanel.maxDist_Callback,Self,S} );
            %
            colormap(Self.hFigure,gray(256));
            %            
        end
        
        function delete(Self)
            delete(Self.hFigure);
        end
        
        
        
        function n=nRow(Self)
            n=Self.hParent.nRow;
        end
        
        function n=nCol(Self)
            n=Self.hParent.nCol;
        end
        
        function n=nWell(Self)
            n = Self.hParent.nRow*Self.hParent.nCol;
        end
        
        function frame(Self, curFrame)
            Self.hParent.frame;
        end
        %
        
        function byRow(Self)
            %
            i=0;
            %
            % the default row order is A1-A2-A3-...H4-H5-H6
            %
            Anal=Self.hParent;
            nRow=Anal.nRow;
            nCol=Anal.nCol;
            %
            for iRow=1:nRow
                for iCol=1:nCol
                    i=i+1;
                    %
                    Anal.well(i).iWell=(iRow-1)*nCol+iCol;
                    %{i Self.well(i).iWell Self.well(i).sWell}
                    Self.outputOrder(i)=Self.well(i).iWell;
                    Self.well(i).scale(nRow, nCol);
                end
            end
        end
        %
        function byCol(Self)
            %
            i=0;
            %
            % the default row order is A1-A2-A3-...An-B1-B2
            % byCol changes order to A1-B1-C1-D1-...A2-B2-C2-...
            Anal=Self.hParent;
            nRow=Anal.nRow;
            nCol=Anal.nCol;
            %
            for iRow=1:nRow
                for iCol=1:nCol
                    i=i+1;
                    %
                    Anal.well(i).iWell=(iCol-1)*nRow+iRow;
                    %{i Self.well(i).iWell Self.well(i).sWell}
                    %
                    Self.outputOrder(i)=Anal.well(i).iWell;
                    %
                    Self.well(i).scale(nRow, nCol);
                end
            end
        end
        %
        function scale(Self)
            %
            Anal=Self.hParent;
            %
            set(Self.hFigure, 'visible','off');
            %
            %make all inactive;
            for i=1:Anal.nWell
                Anal.well(i).inactive;
            end
            %
            iWell=0;
            nRow=Anal.nRow;
            nCol=Anal.nCol;
            %
            Self.hPlotParameter.nWell=nCol*nRow;
            Self.hPlotParameter.hFigure=Self.hFigure;
            %
            if (nRow*nCol > Anal.nWell)
              Dist=Anal.getDistances([Anal.firstFrame Anal.lastFrame]);
              Frame=[Anal.firstFrame:Anal.curFrame]';
              % the default row order is A1-A2-A3-...An-B1-B2              
            end
            %
            for iRow=1:nRow
                sRow=num2abc(iRow);
                for iCol=1:nCol
                    iWell=iWell+1;
                    %
                    if iWell > Anal.nWell
                       well=OOwell(Anal);
                       well.peakFitType=Anal.peakFitType;
                       %
                       well.initialize(Anal.bufferSize);                       
                       %well.analyzeDistances();
                       Anal.add(well);
                       well.initializePlot(Self.hPlotParameter);
                       well.initializeGraphs();
                       well.updateFrame(Frame);
                       %
                       well.updateDistance(Dist(:,iWell));
                       well.distance_to_force;
                       %
                       well.plotForce();  % plot converted forces, not distances
                    else
                        well = Anal.well(iWell);
                    end
                    %                    
                    %well.sWell(strcat(sRow, num2str(iCol)));
                    well.id=iWell;
                    well.iRow=iRow;
                    well.iCol=iCol;
                    well.active();
                    %Self.well(i).scale(Self.nRow, Self.nCol, Self.roiRows, Self.roiCols);
                    well.rescale();
                    well.xLim(Anal.range);
                    %
                    Self.outputOrder(iWell)=well.id;
                    %strcat(num2abc(Anal.firstRow+iRow-1), num2str(Anal.firstCol+iCol-1));                    
                end
            end
            %
            for i=1:Anal.nWell
                Anal.well(i).internal;
            end
            %
            if (Anal.nWell)
                well.last();
            end
            %
            set(Self.hFigure, 'visible','on');
            %close(hW);            
        end      
        %        
        function updateDistances(Self)
         Anal=Self.hParent;
         
         for i = 1 : Anal.n
             Anal.well(i).updateDistance(Anal.Distance(:,i));
         end
            
            
        end
        
        function updateTraces(Self)
            %
            hW = waitbar(0,sprintf('update Traces  ...'));
            Anal=Self.hParent;
            set(Self.hFigure, 'pointer', 'watch');
            %
            for i=1:Anal.n                                
                well=Anal.well(i);
                %
                hW = waitbar(i/Anal.n, hW,sprintf('update Traces of %s frame %d to %d...', well.sWell, well.firstFrame, well.lastFrame));
                %
                well.analyzeTraces();
                %
                if (well.hasNan())
                    disp('well contains NaN, nOK')
                else
                    well.findPeaks;
                    well.analyzePeaks;
                    %
                    well.setActive(true);
                    well.updatePlots();
                    well.updateMeans();
                end
            end
            set(Self.hFigure, 'pointer', 'arrow');
            close(hW);
            Self.bChangesPending=true;
        end
        
        function savePdf(Self, Outfile)
            %
            Anal=Self.hParent;
            %
            hW = waitbar(0, sprintf('Saving Pdf to: %s', Outfile.fullname()));
            %
            Self.hFigure.PaperOrientation='portrait';
            Self.hFigure.PaperUnits='normalized';
            Self.hFigure.PaperPosition=[0 0 1 1];   %100% Fill            
            disp(sprintf('writing to %s',Outfile.fullname()))
            if Outfile.delete()
               print(Self.hFigure, '-dpdf', Outfile.fullname());               
            else
                disp(sprintf('Could not remove existing File %s',Outfile.fullname()))
            end
            saveas(Self.hFigure,Outfile.fullname());
            close(hW);
            %
        end
        
        function save(Self, bInteractive)            
            %
            %set(Self.hFigure, 'pointer', 'watch');
            %            
            Anal=Self.hParent;
            %fRoot=fullfile(Anal.fPathOut, Anal.fRoot);            
            range=Anal.range;
            strRange=[num2str(range(1,1)) '_' num2str(range(1,2))];
            %
            %Self.hFigure.PaperPositionMode='auto';
            Outfile=OOfile('tmp.xml', 'w');
            Outfile.Path(Anal.fPathOut);
            Outfile.Root(Anal.fRoot);
            %individual
            Outfile.Ext([ strRange '.xml' ] );
            Anal.saveState(Outfile.fullname());
            Anal.saveState(Self.stateFile);
            %  
            Outfile.Ext(['peaks.' strRange '.xml' ] );
            if Outfile.delete()
               disp(sprintf('writing to %s',Outfile.fullname()));
               Self.save_Excel_Xml(Outfile.fullname(),range);
            else
                disp(sprintf('Could not remove existing File %s',Outfile.fullname() ))
            end
            
            if Self.bWritePdf
                Outfile.Ext(['traces.' strRange '.pdf' ] );            
                savePdf(Self, Outfile);
            end
            
            Self.bChangesPending=false;
            %
            %set(Self.hFigure, 'pointer', 'arrow');
            %
        end
        
        
        
        function batchProcess(Self)
            
            ranges=[
                 201  1000
                1201  2000
                2201  3000
                3201  4000
                4201  5000
                5201  6000
                6201  7000
                7201  8000
                8201  9000
                9001  9800
               10001 10800
                ];
            
            for i=1:length(ranges)
                %first
                first=ranges(i,1);
                last=ranges(i,2);
                Anal.firstFrame(first);
                Self.xLim(1,1)= first;
                %
                Anal.lastFrame(last);
                Self.xLim(1,2)= last;
                %
                Self.updateTraces();
                %
                Self.save();                
            end
        end
        
        %
        function writePeaksXls(Self, fName, range)
            %
            error('do not use')
            
            hW = waitbar(0,'Saving to Excel ...');
            %
            Excel = actxserver('Excel.Application');
            Excel.DecimalSeparator= '.';
            Excel.ThousandsSeparator=',';
            % open Excel
            %DecimalSeparator: ','
            %ThousandsSeparator: '.'
            if exist(fName,'file')
                %waitbar(0, hW, sprintf('Delete Existing %s', fName));
                waitbar(0, hW, sprintf('Delete Existing outfile'));
                
                 delete(fName);
                pause(1);
            end
            %
            %ewb=Excel.Workbooks.Open(fName,0,false);
            ewb= Excel.Workbooks.Add;
            %
            if ewb.ReadOnly ~= 0
                %This means the file is probably open in another process.
                err=strcat('MATLAB:LockedFile', 'The file %s is not writable. It may be locked by another process.', xlsFile)
                h = errordlg(err);
                waitfor(h);
            end
            
            ews = ewb.Worksheets;
            
            tab=1;
            ews.Item(tab).Activate
            %ews.Item(tab).Name = Self.hParent.fRoot;
            ews.Item(tab).Name = [Self.hParent.fRoot '_' num2str(range(1,1)) '_' num2str(range(1,2)) ];
            %
            %
            Anal=Self.hParent;
            %
            fps=Anal.framesPerSecond;            
            range=[Anal.firstFrame Anal.lastFrame];
            rDist=Anal.getDistances(range);
            rPeak = Anal.getMinima(range);
            rAvg  = Anal.getRunAvg(range);
            rMax  = Anal.getRunMax(range);
            rMin  = Anal.getRunMin(range);
            time  = Anal.getTime(range);
            
            
            titleRow    ='2';
            subTitRow   ='3';
            
            avgRow      ='3';
            devRow      ='4';
            firstDataRow='5';
            %
            % define columns
            %
            m=struct; 
            %         col  title       format bStats
            m.frame      ={'A' 'Frame'      '0.00'  0};
            m.tm         ={'B' 'Tmax'       '0.00'  0};
            m.force      ={'C' 'Force'      '0.00'  1};
            m.base       ={'D' 'Base'       '0.00'  1};
            m.twitch_abs ={'E' 'TwitchAbs'  '0.00'  1};
            m.twitch_rel ={'F' 'TwitchRel'  '0.00%' 1};
            %
            m.rr         ={'G' 'RR'         '0.00'  1};
            m.freq       ={'H' 'Freq'       '0.00'  1};
            m.t1         ={'I' 'T1'         '0.00'  0};
            m.t2         ={'J' 'T2'         '0.00'  0};
            m.t3         ={'K' 'T3'         '0.00'  0};
            m.t4         ={'L' 'T4'         '0.00'  0};
            m.t1_t2      ={'M' 'd(T1,T2)'   '0.00'  1};
            m.t3_t4      ={'N' 'd(T3,T4)'   '0.00'  1};
            m.t1_tm      ={'O' 'd(T1,Tmax)' '0.00'  1};
            m.t4_tm      ={'P' 'd(T4,Tmax)' '0.00'  1};
            m.t1_t4      ={'Q' 'd(T1,T4)'   '0.00'  1};
            m.r1_r2      ={'R' 'd(R1,R2)'   '0.00'  1};
            %
            s = struct;
            %              col    title1       title2      src_col     src_row    bStats
            s.well        ={'A'    'Well'         ''       'A'            '1'     };
            s.twitch_abs  ={'B'    'TwitchAbs'    'Avg'  m.twitch_abs{1} avgRow    };
            s.twitch_rel  ={'C'    'TwitchRel'    'Avg'  m.twitch_rel{1} avgRow    };
            s.twitch_dev  ={'D'    ''             'Dev'  m.twitch_rel{1} devRow    };
            s.rr          ={'E'    'RR'           'Avg'  m.rr{1}         avgRow    };
            s.rr_dev      ={'F'    ''             'Dev'  m.rr{1}         devRow    };
            s.freq        ={'G'    'Freq'         'Avg'  m.freq{1}       avgRow    };
            s.freq_dev    ={'H'    ''             'Dev'  m.freq{1}       devRow    };
            s.t1_t2       ={'I'    'd(T1,T2)'     ''     m.t1_t2{1}      avgRow    };
            s.t3_t4       ={'J'    'd(T3,T4)'     ''     m.t3_t4{1}      avgRow    };
            s.t1_tm       ={'K'    'd(T1,Tmax)'   ''     m.t1_tm{1}      avgRow    };
            s.t4_tm       ={'L'    'd(Tmax,T4)'   ''     m.t4_tm{1}      avgRow    };
            s.t1_t4       ={'M'    'd(T1,T4)'     ''     m.t1_t4{1}      avgRow    };
            s.r1_r2       ={'N'    'd(R1,R2)'     ''     m.r1_r2{1}      avgRow    };
            %
            m_tags=fieldnames(m);
            s_tags=fieldnames(s);
            %
            for i=1:Self.nWell
                %                
                %
                pFrame=find( ~isnan( rPeak(:,i) ) );
                nPeak=numel(pFrame);
                %
                well=Self.well(i);
                waitbar(i/Self.nWell, hW, sprintf('Saving %d peaks of well %s to file %s', nPeak, well.sWell, fName));
                %
                tab=i+1;
                %
                if (tab > ews.Count)
                    ews.Add([], ews.Item(ews.Count));
                end
                ews.Item(tab).Activate;
                %
                ews.Item(tab).Name = well.sWell;
                %
                Select(Range(Excel,'A1') );
                set(Excel.selection,'Value',  well.sWell);                    
                Select(Range(Excel,['A' avgRow]) );
                set(Excel.selection,'Value',  'Mean:');                    
                Select(Range(Excel,['A' devRow]) );
                set(Excel.selection,'Value',  'Stdev:');                    
                
                Select(Range(Excel, [ 'A' avgRow ':P' avgRow]) );
                set(Excel.selection.Font,'Bold', true);                   
                Select(Range(Excel, [ 'A' devRow ':P' devRow]) );
                Excel.selection.Font.ColorIndex=3;                   
                %set(Excel.selection.Interior, 'ColorIndex', 3);                   
                %                
                well.analyzePeaks(pFrame, rDist(:,i), rAvg(:,i), rMax(:,i), time);
                %
                if (well.PeakList.n >=2)
                    %
                    %Insert Peaks
                    %                    
                    %
                    well.analyzePeaks2(pFrame, rDist(:,i), rAvg(:,i), rMax(:,i), time);
                    
                    %
                    %fill cell array with data to speed insertion
                    %
                    A={};
                    %                    
                    for j=1:well.PeakList.n
                        %
                        peak=well.PeakList.get(j);
                        %
                        row=num2str(str2num(firstDataRow)+j-1);
                        lRow=num2str(str2num(firstDataRow)+j-2);
                        %
                        A{j,1} = peak.Position.max;              %frame
                        A{j,2} = peak.time/fps;                  %Tmax
                        A{j,3} = peak.max;                       %force
                        A{j,4} = peak.base;                      %base
                        A{j,5} = cell2mat(['='  m.base(1)       row '-' m.force(1) row]); %twitchAbs
                        A{j,6} = cell2mat(['='  m.twitch_abs(1) row '/' m.base(1)  row]); %twitchRel
                        A{j,7} = cell2mat(['=WENN(' m.tm(1) row '*' m.tm(1) lRow '>0,' m.tm(1) row '-' m.tm(1) lRow ',"")']);  %rr                        
                        A{j,8} = cell2mat(['=WENN(ISTZAHL(' m.rr(1) row '),1/' m.rr(1) row ',"")']);                           %freq
                        
                        %
                        %'tmin',nan
                        A{j,9}  = nan2blank(peak.Asc.tmin/fps);              %t1
                        A{j,10} = nan2blank(peak.Asc.tmax/fps);              %t1
                        A{j,11} = nan2blank(peak.Desc.tmin/fps);             %t1
                        A{j,12} = nan2blank(peak.Desc.tmax/fps);             %t1
                                                
                        A{j,13}= cell2mat(['=WENN(UND(ISTZAHL(' m.t2(1) row '), ISTZAHL(' m.t1(1) row ')),(' m.t2(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,t2)
                        A{j,14}= cell2mat(['=WENN(UND(ISTZAHL(' m.t4(1) row '), ISTZAHL(' m.t3(1) row ')),(' m.t4(1) row '-' m.t3(1) row ')*1000,"")']); %d(t3,t4)
                        A{j,15}= cell2mat(['=WENN(UND(ISTZAHL(' m.tm(1) row '), ISTZAHL(' m.t1(1) row ')),(' m.tm(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,tm)
                        A{j,16}= cell2mat(['=WENN(UND(ISTZAHL(' m.t4(1) row '), ISTZAHL(' m.tm(1) row ')),(' m.t4(1) row '-' m.tm(1) row ')*1000,"")']); %d(t4,tm)
                        A{j,17}= cell2mat(['=WENN(UND(ISTZAHL(' m.t4(1) row '), ISTZAHL(' m.t1(1) row ')),(' m.t4(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,t4)
                        
                        %A{j,13}= cell2mat(['=WENN(' m.t2(1) row '*' m.t1(1) row '>0,(' m.t2(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,t2)
                        %A{j,14}= cell2mat(['=WENN(' m.t4(1) row '*' m.t3(1) row '>0,(' m.t4(1) row '-' m.t3(1) row ')*1000,"")']); %d(t3,t4)
                        %A{j,15}= cell2mat(['=WENN(' m.tm(1) row '*' m.t1(1) row '>0,(' m.tm(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,tm)
                        %A{j,16}= cell2mat(['=WENN(' m.t4(1) row '*' m.tm(1) row '>0,(' m.t4(1) row '-' m.tm(1) row ')*1000,"")']); %d(t4,tm)
                        %A{j,17}= cell2mat(['=WENN(' m.t4(1) row '*' m.t1(1) row '>0,(' m.t4(1) row '-' m.t1(1) row ')*1000,"")']); %d(t1,t4)
                        %=WENN(ISTZAHL(F9*F8),ABS(F9-F8)*1000,"")
                        
                        A{j,18}= cell2mat(['=WENN(istzahl(' m.rr(1) row '*' m.rr(1) lRow '),abs(' m.rr(1) row '-' m.rr(1) lRow ')*1000,"")']); %d(t1,t4)
                        %
                        
                        if (1)
                        A{j, 7}=0;
                        A{j, 8}=0;
                        A{j,13}=0;
                        A{j,14}=0;
                        A{j,15}=0;
                        A{j,16}=0;
                        A{j,17}=0;
                        A{j,18}=0;
                        end
                        
                    end
                    %
                    lastDataRow=num2str( str2num(firstDataRow) + nPeak-1 );
                    %
                    %cell2mat([m.(m_tags{1})(1) firstDataRow ':' m.(m_tags{end})(1) lastDataRow])
                    Select(Range(Excel,cell2mat([m.(m_tags{1})(1) firstDataRow ':' m.(m_tags{end})(1) lastDataRow])) );
                    set(Excel.selection,'Value',A);
                    %
                    % Insert Averages and Formats
                    %
                    %
                    %               
                    for j=1:numel(m_tags)
                      %
                      col   =m.(m_tags{j})(1);
                      sTitle=m.(m_tags{j})(2);
                      sForm =m.(m_tags{j}){3};
                      bStats=m.(m_tags{j}){4};
                      % set Title
                      Select( Range(Excel,cell2mat([col titleRow]) ) );
                      set(Excel.selection,'Value', sTitle);
                      % do Stats
                      if (bStats==1)
                          Select(Range(Excel,cell2mat([col avgRow])) );
                          set(Excel.selection,'Value',cell2mat(['=MITTELWERT(' col firstDataRow ':' col lastDataRow ')']) );
                          Select(Range(Excel,cell2mat([col devRow])) );                    
                          set(Excel.selection,'Value',cell2mat(['=STABW(' col firstDataRow ':' col lastDataRow ')']) );                                      
                      end
                      % set Fromat
                      Select(Range(Excel,cell2mat([col avgRow ':' col lastDataRow])) );
                      %set(Excel.selection, 'NumberFormat' , cell2mat(sForm])); 
                      Excel.selection.NumberFormat=sForm;
                      Select(Range(Excel,'A1'));
                    end
                    %
                    % Insert refs to summary
                    %
                    ews.Item(1).Activate;
                    %
                    for j=1:numel(s_tags)
                        tgtRow=num2str(i+3);
                        tgtCol=s.(s_tags{j})(1);
                        srcCol=s.(s_tags{j})(4);
                        srcRow=s.(s_tags{j})(5);
                        %
                        Select(Range(Excel,cell2mat([ tgtCol tgtRow])) );                        
                        set(Excel.selection,'Value', cell2mat(['=' char(39) well.sWell char(39) '!' srcCol srcRow]));
                        %
                    end
                    %
                end
                
            end
            %
            % Add Summary Headers
            %
            ews.Item(1).Activate;
            %
            for j=1:numel(s_tags)               
               tgtCol=s.(s_tags{j})(1);
               title1=s.(s_tags{j})(2);
               title2=s.(s_tags{j})(3);
               Select(Range(Excel,cell2mat([tgtCol titleRow])) );
               set(Excel.selection,'Value',title1);
               Select(Range(Excel,cell2mat([tgtCol subTitRow])) );
               set(Excel.selection,'Value',title2);
            end
            %
            Select(Range(Excel,'A1') );
            close(hW);
            %
            Excel.DefaultSaveFormat='xlOpenXMLWorkbook';
            ewb.SaveAs(fName,1);
            %Excel.ActiveWorkbook.Save;
            Excel.Quit;
            Excel.delete;
            clear Excel;
        end
        %
        %
        %
        %
        %
        %
        function save_Excel_Xml(Self, fName, range)
            %
            hW = waitbar(0,'Saving to Excel ...');
            %ThousandsSeparator: '.'
            Anal  = Self.hParent;
            
            fps   = Anal.framesPerSecond;
            
            wellidRow   =1;
            titleRow     =2;
            subTitRow    =3;
            firstWellRow =4;
            
            avgRow       =3;
            devRow       =4;
            firstDataRow =5;
            sFirstDataRow=num2str(firstDataRow);
            %
            % define columns
            %
            m=struct; 
            %             col sCol  title       format  bStats
            m.frame      ={1   '1' 'Frame'      'sDec0'  0};
            m.tm         ={2   '2' 'Tmax'       'sDec2'  0};
            m.force      ={3   '3' 'Force'      'sDec1'  1};
            m.base       ={4   '4' 'Base'       'sDec1'  1};
            m.twitch_abs ={5   '5' 'TwitchAbs'  'sDec1'  1};
            m.twitch_rel ={6   '6' 'TwitchRel'  'sPct2' 1};
            m.rr         ={7   '7' 'RR'         'sDec2'  1};
            m.freq       ={8   '8' 'Freq'       'sDec2'  1};
            m.t1         ={9   '9' 'T1'         'sDec2'  0};
            m.t2         ={10 '10' 'T2'         'sDec2'  0};
            m.t3         ={11 '11' 'T3'         'sDec2'  0};
            m.t4         ={12 '12' 'T4'         'sDec2'  0};
            m.t1_t2      ={13 '13' 'd(T1,T2)'   'sDec1'  1};
            m.t3_t4      ={14 '14' 'd(T3,T4)'   'sDec1'  1};
            m.t1_tm      ={15 '15' 'd(T1,Tmax)' 'sDec1'  1};
            m.t4_tm      ={16 '16' 'd(T4,Tmax)' 'sDec1'  1};
            m.t1_t4      ={17 '17' 'd(T1,T4)'   'sDec1'  1};
            m.r1_r2      ={18 '18' 'd(R1,R2)'   'sDec1'  1};
            m.v_con      ={19 '19' 'v_con'      'sPct1'  1};
            m.v_rel      ={20 '20' 'v_rel'      'sPct1'  1};
            m.b_stim     ={21 '21' 'bStim'      'sDec2'  1};
            m.b_stimOn   ={22 '22' 'bStimOn'    'sDec2'  1};
            %
            s = struct;
            %              col    title1    title2      src_col   src_row      fmt
            s.well        ={1    'Well'         ''           1            1     'sStr'  };
            s.twitch_abs  ={2    'TwitchAbs'    'Avg'  m.twitch_abs{1} avgRow   'sDec1' };
            s.twitch_rel  ={3    'TwitchRel'    'Avg'  m.twitch_rel{1} avgRow   'sPct1' };
            s.twitch_dev  ={4    ''             'Dev'  m.twitch_rel{1} devRow   'sPct1' };
            s.rr          ={5    'RR'           'Avg'  m.rr{1}         avgRow   'sDec2' };
            s.rr_dev      ={6    ''             'Dev'  m.rr{1}         devRow   'sDec2' };
            s.freq        ={7    'Freq'         'Avg'  m.freq{1}       avgRow   'sDec2' };
            s.freq_dev    ={8    ''             'Dev'  m.freq{1}       devRow   'sDec2' };
            s.t1_t2       ={9    'd(T1,T2)'     ''     m.t1_t2{1}      avgRow   'sDec2' };
            s.t3_t4       ={10   'd(T3,T4)'     ''     m.t3_t4{1}      avgRow   'sDec2' };
            s.t1_tm       ={11   'd(T1,Tmax)'   ''     m.t1_tm{1}      avgRow   'sDec2' };
            s.t4_tm       ={12   'd(Tmax,T4)'   ''     m.t4_tm{1}      avgRow   'sDec2' };
            s.t1_t4       ={13   'd(T1,T4)'     ''     m.t1_t4{1}      avgRow   'sDec2' };
            s.r1_r2       ={14   'd(R1,R2)'     ''     m.r1_r2{1}      avgRow   'sDec2' };
            s.v_con       ={15   'v_con'        'Avg'  m.v_con{1}      avgRow   'sPct1' };
            s.v_rel       ={16   'v_rel'        'Avg'  m.v_rel{1}      avgRow   'sPct1' };
            s.base_abs    ={17   'BaseAbs'      'Avg'  m.base{1}       avgRow   'sPct1' };
            s.stim_rel    ={18   'StimRel'      'Avg'  m.b_stim{1}     avgRow   'sPct1' };
            s.stim_on     ={19   'StimOn'       'Avg'  m.b_stimOn{1}   avgRow   'sPct1' };
            
            %
            m_tags=fieldnames(m);
            s_tags=fieldnames(s);
            %
            if exist(fName,'file')
                %waitbar(0, hW, sprintf('Delete Existing %s', fName));
                waitbar(0, hW, sprintf('Delete Existing outfile'));
                
                delete(fName);
                pause(1);
            end            
            %
            %Open Excel Workbook
            xls=OOexcel(fName);            
            xls.openWorkbook();
            xls.addStyles();
            %
            %
            %            
            % open Excel Worksheet "Waypoints"
            %
            %
            %Write Waypoint Data
            %
            if Anal.nWaypoint>0
                xls.openWorksheet('waypoints');
                xls.openTable();
                %
                titleCol=1;
                titleTit='Well'
                %
                twitchCol = titleCol + 1;
                twitchTit = 'twitch';
                %
                maxCol   = twitchCol + 1 + Anal.nWaypoint;
                maxTit   = 'baseline';
                
                minCol   = maxCol    + 1 + Anal.nWaypoint;
                minTit   = 'running Maximum';
                
                xls.openRow(titleRow);
                
                xls.writeCellString(twitchCol, twitchTit);
                xls.writeCellString(maxCol, maxTit);
                xls.writeCellString(minCol, minTit);
                                
                xls.closeRow;
                
                sorted=sort(Anal.waypoint);   
                
                xls.openRow(subTitRow);
                for j=1:Anal.nWaypoint
                  xls.writeCellDoubleFmt(twitchCol -1  + j, sorted(j), 'sDec0');                  
                end;
                for j=1:Anal.nWaypoint
                  xls.writeCellDoubleFmt(   maxCol -1  + j, sorted(j), 'sDec0');                  
                end;
                for j=1:Anal.nWaypoint
                  xls.writeCellDoubleFmt(   minCol -1  + j, sorted(j), 'sDec0');
                end;
                xls.closeRow;                
                
                for iWell=1:Anal.nWell
                   well=Anal.well(iWell);
                   %Insert Refs to Summary                
                   tgtRow= firstWellRow + iWell - 1;
                   %
                   xls.openRow(tgtRow);
                   xls.writeCellString(1, well.sWell);
                   %xls.writeCellString(2, well.fName);
                   
                   % write twich
                   for j=1:Anal.nWaypoint
                      runMax = well.runMax(sorted(j));
                      runMin = well.runMin(sorted(j));                      
                      xls.writeCellDoubleFmt(twitchCol -1 +j, runMax-runMin, 'sDec2');
                   end
                   %
                   % write base
                   for j=1:Anal.nWaypoint
                      xls.writeCellDoubleFmt(   maxCol -1 +j, well.runMax(sorted(j)), 'sDec2');
                   end
                   %
                   % write max
                   for j=1:Anal.nWaypoint
                      xls.writeCellDoubleFmt(minCol -1 +j, well.runMin(sorted(j)), 'sDec2');
                   end
                   xls.closeRow();
                end                
                xls.closeTable();
                xls.closeWorksheet();                     
            end %end waypoints
            %
            %            
            % open Excel Worksheet "Summary"
            %
            %
            tabName=[Self.hParent.fRoot '_' num2str(range(1,1)) '_' num2str(range(1,2)) ];
            
            xls.openWorksheet( tabName(1:min(24, numel(tabName) )) );
            xls.openTable();
            %
            % Add Summary Headers
            %
            xls.openRow(wellidRow);
            xls.writeCellString(1,'Created');                           
            xls.writeCellString(2, Self.timestamp);
            xls.closeRow;
            %
            xls.openRow(titleRow);
            %
            %Add Titles
            for j=1:numel(s_tags)
               tgtCol=s.(s_tags{j}){1};
               title =s.(s_tags{j}){2};               
               xls.writeCellString(tgtCol,title);               
            end
            xls.closeRow()
            %
            %Add Sub-Titles
            xls.openRow(subTitRow);            
            for j=1:numel(s_tags)
                tgtCol=s.(s_tags{j}){1};
                title =s.(s_tags{j}){3};
                xls.writeCellString(tgtCol,title);
            end
            xls.closeRow();
            %
            % Add links to worksheets
            for iWell=1:Anal.nWell
                well=Anal.well(iWell);
                %
                waitbar(iWell/Self.nWell, hW, sprintf('Write Summary of well %s ', well.name));
                %
                %Insert Refs to Summary                
                tgtRow= firstWellRow + iWell - 1;
                %
                xls.openRow(tgtRow);
                %
                for j=1:numel(s_tags)
                   tgtCol =         s.(s_tags{j}){1};
                   srcCol = num2str(s.(s_tags{j}){4});
                   srcRow = num2str(s.(s_tags{j}){5});
                   fmt    = num2str(s.(s_tags{j}){6});
                   %<Cell ss:Formula="=A1!R[-3]C"><Data ss:Type="String">A1</Data></Cell>
                   %xls.writeCellFormula(tgtCol,['=' well.sWell '!R' srcRow 'C' srcCol]);
                   xls.writeCellFormulaFmt(tgtCol,['=' well.sWell '!R' srcRow 'C' srcCol], fmt);
                   %
                end
                xls.closeRow;
            end
            %
            xls.closeTable();
            xls.closeWorksheet();
            
            %
            % insert box-whiskars plot
            %
            xls.openWorksheet('box_whisker');
            xls.openTable();
            %
            xls.openRow(1);
            xls.writeCellString(1, 'iPeak');
            for iWell=1:Self.nWell
                well=Anal.well(iWell);                
                xls.writeCellString(1+iWell, well.name); %well name for legend               
            end
            xls.closeRow;
            for i=2:180 %loop through peaks
                waitbar(i/180, hW, sprintf('Write Box-Whisker %d ', i));
                xls.openRow(i);
                xls.writeCellDoubleFmt(1, i,'sDec0');  %write peak number
                for iWell=1:Self.nWell                    
                    well=Anal.well(iWell);            
                    tgtCol = num2str(iWell+1);
                    srcRow = num2str(firstDataRow+i-1);
                    srcCol = num2str(m.freq{1});                    
                    fmt    = m.freq{4};
                    %<Cell ss:Formula="=A1!R[-3]C"><Data ss:Type="String">A1</Data></Cell>
                    %xls.writeCellFormula(tgtCol,['=' well.sWell '!R' srcRow 'C' srcCol]);
                    src = sprintf('%s!R%dC%d', well.name, firstDataRow+i-1, m.freq{1});                    
                    fld = sprintf('IF(ISNUMBER(%s), %s, NA())', src,src);
                    xls.writeCellFormulaFmt(iWell+1,fld, fmt);                   
                end
                xls.closeRow();
            end
            %
            %
            %
            %                
            xls.closeTable();
            xls.closeWorksheet();
            
            %                 
            for iWell=1:Self.nWell
                well=Anal.well(iWell);
                well.bInteractive=Anal.bInteractive;
                %                
                %                
                xls.openWorksheet(well.name);
                xls.openTable();
                %
                %now enter Data
                %pFrame cotains all peaks detected, 
                %analyzePeaks will do a more thorough analysis
                %pFrame=find(~isnan(rPeak(:,i)));
                if (well.bActPeak)
                    well.analyzePeaks();
                    nPeak=well.PeakList.n;
                else
                    well.PeakList.empty;
                    nPeak=0;
                end
                %
                waitbar(iWell/Self.nWell, hW, sprintf('Saving %d peaks of well %s ', nPeak, well.name));
                %
                sLastDataRow= num2str(firstDataRow + nPeak-1);
                %                
                % Well Name in 1.1
                xls.openRow(wellidRow);
                xls.writeCellString(1, well.sWell);
                xls.writeCellString(2, well.fName);
                xls.closeRow;
                %
                % Insert Titles
                %
                xls.openRow(titleRow);                
                for j=1:numel(m_tags)
                  tgtCol= m.(m_tags{j}){1};
                  title = m.(m_tags{j}){3};
                  xls.writeCellString(tgtCol, title);
                end
                xls.closeRow;
                %                
                %have peaks
                if (nPeak >=2 && well.bActPeak)
                    %
                    % do Avg
                    xls.openRow(avgRow);
                    for j=1:numel(m_tags)
                        tgtCol     = m.(m_tags{j}){1};
                        bStats     = m.(m_tags{j}){5};
                        fmt        = m.(m_tags{j}){4};%
                        if (bStats==1)
                            xls.writeCellFormulaFmt(tgtCol, ['=AVERAGE(R' sFirstDataRow 'C:R' sLastDataRow 'C)'], fmt);
                        end
                    end
                    xls.closeRow;
                    %
                    % do StDev
                    xls.openRow(devRow);
                    for j=1:numel(m_tags)
                        tgtCol = m.(m_tags{j}){1};
                        bStats = m.(m_tags{j}){5};
                        fmt    = m.(m_tags{j}){4};
                        %
                        if (bStats==1)
                            xls.writeCellFormulaFmt(tgtCol, ['=STDEV(R' sFirstDataRow 'C:R' sLastDataRow 'C)'], fmt);
                        end
                    end
                    xls.closeRow;
                    %
                    %if (nPeak >=2)
                    well.PeakList.n
                    for j=1:nPeak
                        %
                        peak=well.PeakList.get(j);
                        %
                        xls.openRow(firstDataRow+j-1);
                        %
                        lRow=num2str(firstDataRow+j-2);
                        %
                        %fmt    = m.(m_tags{j}){4};
                        xls.writeCellDoubleFmt(m.frame{1}, peak.Position.max, m.frame{4});
                        xls.writeCellDoubleFmt(m.tm{1},    peak.time/fps,     m.tm{4}   );
                        xls.writeCellDoubleFmt(m.force{1}, peak.max,          m.force{4});
                        xls.writeCellDoubleFmt(m.base{1},  peak.base,         m.base{4} );
                        %
                        
                        xls.writeCellFormulaFmt(m.twitch_abs{1}, ['=ABS(RC'  m.base{2}       '-RC' m.force{2} ')' ], m.twitch_abs{4});     %twitchAbs
                        xls.writeCellFormulaFmt(m.twitch_rel{1}, ['=RC'  m.twitch_abs{2} '/RC' m.force{2}  ],m.twitch_rel{4});     %twitchRel
                        xls.writeCellFormulaFmt(m.rr{1},  ['=IF(RC' m.tm{2} '*R' lRow 'C' m.tm{2} '>0, RC' m.tm{2} '- R' lRow 'C' m.tm{2} ',"")'], m.rr{4});  %rr                        
                        xls.writeCellFormulaFmt(m.freq{1},['=IF(ISNUMBER(RC' m.rr{2} '), 1/RC' m.rr{2} ',"")' ], m.freq{4});
                        %
                        % check if fitting worked
                        if (0<peak.t1<peak.t2<peak.time<peak.t3<peak.t4)
                            xls.writeCellDoubleFmt(m.t1{1}, peak.t1/fps,  m.t1{4});
                            xls.writeCellDoubleFmt(m.t2{1}, peak.t2/fps,  m.t2{4});
                            xls.writeCellDoubleFmt(m.t3{1}, peak.t3/fps, m.t3{4});
                            xls.writeCellDoubleFmt(m.t4{1}, peak.t4/fps, m.t4{4});
                        end
                        %
                        xls.writeCellFormulaFmt(m.t1_t2{1},['=IF(AND(ISNUMBER(RC' m.t2{2} '), ISNUMBER(RC' m.t1{2} ')),(RC' m.t2{2} '-RC' m.t1{2} ')*1000,"")'], m.t1_t2{4}); %d(t1,t2)
                        xls.writeCellFormulaFmt(m.t3_t4{1},['=IF(AND(ISNUMBER(RC' m.t4{2} '), ISNUMBER(RC' m.t3{2} ')),(RC' m.t4{2} '-RC' m.t3{2} ')*1000,"")'], m.t3_t4{4}); %d(t3,t4)
                        xls.writeCellFormulaFmt(m.t1_tm{1},['=IF(AND(ISNUMBER(RC' m.tm{2} '), ISNUMBER(RC' m.t1{2} ')),(RC' m.tm{2} '-RC' m.t1{2} ')*1000,"")'], m.t1_tm{4}); %d(t1,tm)
                        xls.writeCellFormulaFmt(m.t4_tm{1},['=IF(AND(ISNUMBER(RC' m.t4{2} '), ISNUMBER(RC' m.tm{2} ')),(RC' m.t4{2} '-RC' m.tm{2} ')*1000,"")'], m.t4_tm{4}); %d(t4,tm)
                        xls.writeCellFormulaFmt(m.t1_t4{1},['=IF(AND(ISNUMBER(RC' m.t4{2} '), ISNUMBER(RC' m.t1{2} ')),(RC' m.t4{2} '-RC' m.t1{2} ')*1000,"")'], m.t1_t4{4}); %d(t1,t4)
                        xls.writeCellFormulaFmt(m.r1_r2{1},['=IF(ISNUMBER(RC' m.rr{2} '*R' lRow 'C' m.rr{2} '),abs(RC' m.rr{2} '-R' lRow 'C' m.rr{2} ')*1000,"")'], m.r1_r2{4}); %d(t1,t4)
                        
                        xls.writeCellFormulaFmt(m.v_con{1},['=IF(AND(ISNUMBER(RC' m.t1_t2{2} '), ISNUMBER(RC' m.twitch_rel{2} ')),(RC' m.twitch_rel{2} '/RC' m.t1_t2{2} ')*1000,"")'], m.v_con{4}); %v_con
                        xls.writeCellFormulaFmt(m.v_rel{1},['=IF(AND(ISNUMBER(RC' m.t3_t4{2} '), ISNUMBER(RC' m.twitch_rel{2} ')),(RC' m.twitch_rel{2} '/RC' m.t3_t4{2} ')*1000,"")'], m.v_rel{4}); %v_rel
                        
                        xls.writeCellDoubleFmt(m.b_stim{1},   peak.bStim,   m.b_stim{4}  ); %v_rel
                        xls.writeCellDoubleFmt(m.b_stimOn{1}, peak.bStimOn, m.b_stimOn{4}); %v_rel
                        
                        xls.closeRow();
                    end
                else
                    %no peaks found
                    rawBaseline=nanmean(Self.hParent.Distance(:,iWell));
                    rawBaseline=nanmean(well.Distance);
                    xls.openRow(avgRow);
                    xls.writeCellDoubleFmt(m.base{1}, rawBaseline, m.base{4});
                    xls.closeRow;
                end
                
                
                xls.closeTable();
                xls.closeWorksheet();                    
            end
            %
            xls.closeWorkbook();
            %
            close(hW);
            
        end
        
        function [Db, idExp, idMea]=open_toDb(Self, bInteractive)
            Anal=Self.hParent;
            fName=fullfile(Anal.fPathIn, Anal.fNameIn);
            %
            idExp=0;
            idMea=0;
            
            Db=OOcontractionDb2Gui(Anal.dbCred);
            Db.connect;
            %Db.autocommit('off')
            %
            Self.initializeMessageBox('db connection')
            Self.addMessage('Set Filenames');
            % Get Names from File Path
            [sExp, sMea] = Db.setFilenames(fName);
            %
            Self.addMessage(sprintf('get idExperiment for %s and %s', sExp, sMea));
            %
            idExp=Db.idExperiment(sExp)
            bInteractive=0;
            %
            if ~idExp
                Self.addMessage(sprintf('addExperiment for %s', sExp));
                if (bInteractive)
                    idExp=Db.idExperiment_Gui(sExp);
                end
                idExp=Db.addExperiment('myrplate_TM5', sExp);
            end
            %
            if ~idExp
                if (bInteractive)
                    h = msgbox('No Experiment was defined, abort','Cancel');
                    waitfor(h);
                end    
                error('Could not generat eidExperiment');
            
            end
            
            Self.addMessage(sprintf('idExperiment of %s is: %d', sExp, idExp));
            
            % Check if the Experiment plate has wells associated
            idPlate = Db.idPlate(idExp);
            
            Self.addMessage(sprintf('idPlate of %s is: %d', sExp, idPlate));
            
            if (~ Db.hasWells(idPlate))
                Db.addWells(idPlate);
            end
            Self.addMessage('Get idMeasurement');
            %
            %posixTime            
            idMea=Db.idMeasurement(idExp, sMea);
            %
            if (~ idMea)
                Self.addMessage(sprintf('No idMeasurement for %s, create', sMea));
                pTime=Anal.recordingTimestamp;                
                %                
                if (bInteractive)
                    idMea=Db.idMeasurement_Gui(idExp, sMea, Anal.curFrame, pTime, Anal.timeResolution, Anal.spatialResolution);
                else                    
                    %str=sprintf('%4d-%02d-%02d %2d:%02d:%02d',.
                    username=getenv('username');
                    idPerson=Db.username2idPerson(username);
                    idMea=Db.addMeasurement(idExp, sMea, idPerson, Anal.lastFrame, pTime, Anal.timeResolution, Anal.spatialResolution);
                end
            end            
            %
            if ~idMea
                h = msgbox('No Measurement was defined, abort','Cancel');
                waitfor(h)
            else
                Self.addMessage(sprintf('idMeasurement of %s is: %d', sMea, idMea));
            end
            %
            str=sprintf('open_toDb: idExp of %s is %d, idMea of %s is %d', sExp, idExp,sMea,idMea);
            disp(str);            
            Self.addMessage(str);
             %
            Db.commit();
            
        end
        
        function ret=save_toDb(Self, bInteractive)
            %
            ret=0;
            [Db, idExp, idMea]=open_toDb(Self, bInteractive);
            
            if (idMea)
                Db.updateRecordingTimestamp(idMea, Self.hParent.recordingTimestamp);
                if (Self.bUploadTraces)
                   Self.addTraces_toDb(Db, idExp, idMea);
                end
                if (Self.bUploadPeaks)
                    Self.addPeaks_toDb(Db, idExp, idMea);
                end
            else
                Self.addMessage(sprintf('save_toDb: no MeasurementId, abort'));
            end
            Db.commit;
            Db.close;
            Self.addMessage('done, close DB');
            Self.deleteMessageBox();
            ret=1;
        end
        
        function addTraces_toDb(Self, Db, idExp, idMea)
            %
            Anal=Self.hParent;
            nWell=Anal.nWell;           
            %
            hWait=waitbar(0, sprintf('Insert Traces of %2s %2.0f%%', 'A0',0));
            %
            Db.updateRawTime(idMea, Anal.Time-Anal.Time(1));
            %
            for i=1:nWell
                %
                well=Anal.well(i);
                %
                if ~ well.bActive
                    continue;
                end
                %
                waitbar(i/nWell, hWait, sprintf('Insert Traces of %2s %2.0f%%', well.sWell, i/nWell*100));
                %                
                idEhm=Db.idEhm(idExp, well.sWell);
                %
                if (~idEhm)
                    idEhm=Db.addEhm(idExp, well.sWell);
                end
                %
                idForces=Db.addForces(idEhm, idMea);
                %
                Db.updateRawDistance(idForces, well.Distance);
                Db.updateBaseLine(idForces, well.runMax);
                Db.updateTwitchDistance(idForces, well.runMax - well.Distance);                
            end
            delete(hWait);
        end
        
        function w=well(Self,i)
            w=Self.hParent.well(i);
            w.bInteractive=Self.bInteractive;
            w.bQuiet=Self.bQuiet;
        end
        
        
        function addPeaks_toDb(Self, Db, idExp, idMea)        
            %
            % for now use only default analysis settings
            %
            idPeakAnalysis=1;
            Anal=Self.hParent;
            nWell=Anal.nWell;
            %range=Self.xLim;
            %       
            bPeakAnal=1;
            %            
            hWait=waitbar(0, sprintf('Insert Peaks of %2s %2.0f%%', 'A0',0));
            %
      
            for i=1:nWell
                %
                well=Anal.well(i);
                well.bInteractive=Anal.bInteractive;
                %
                if ~ well.bActive
                    continue;
                end
                %
                waitbar(i/nWell, hWait, sprintf('Insert PEaks of well %2s %2.0f%%', well.sWell, i/nWell*100));
                %
                idEhm=Db.idEhm(idExp, well.sWell);
                %
                if ~idEhm
                    txt=sprintf('Ehm %s not in Database Experiment %d, skip',well.sWell, idExp);
                    h = msgbox(txt,'Skip');
                    waitfor(h);
                    continue
                end
                %
                %pFrame=find(~isnan(peak(:,i)));
                well.analyzePeaks;
                nPeak=well.PeakList.n;
                %
                idForces=Db.addForces(idEhm, idMea);
                %
                Db.emptyPeakList(idPeakAnalysis, idForces);
                %
                if well.bActPeak && nPeak>0                    
                    % now insert Peaks                    
                    %
                    well.analyzePeaks();
                    Db.insertPeakList(idPeakAnalysis, idForces, well.PeakList);                
                end
            end
            delete(hWait);
        end        
    end
    %
    methods(Static)
        %
        function mouse_Callback(hObject, eventdata, Self)
            hAxes=overobj('Axes')
            pos=get(hObject,'CurrentPoint')
        end
        
        function mode_Callback(hObj, event, Self,S)
            display(['Previous: ' event.OldValue.String]);
            display(['Current: ' event.NewValue.String]);
            Anal=Self.hParent;
            Anal.setMode(event.NewValue.String);
            %
            Self.updateTraces();
            %
        end
        %        
        function thresh_Callback(hObj, eventdata, Self,S)
            Anal=Self.hParent;
            val=round(get(hObj, 'Value'),2);
            set(S.hThreshTxt,'String',sprintf('%4.2f',val));
            %
            Anal.peakThresh(val);
            Self.updateTraces();
        end
        %
        function threshTxt_Callback(hObj, eventdata, Self, S)
            Anal=Self.hParent;
            val =round(str2double(hObj.String),2);
            S.hThresh.Value=val;
            Anal.peakThresh(val);
            Self.updateTraces();
        end
        %
        function first_Callback(hObj, eventdata, Self)
            Anal=Self.hParent;
            val=Anal.firstFrame(str2double(hObj.String));
            Self.updateTraces();
            hObj.String=num2str(val);
            %
        end
        
        function last_Callback(hObj, eventdata, Self)
            %
            Anal=Self.hParent;
            val=Anal.lastFrame(str2double(hObj.String));            
            Self.xLim(1,2)= val;
            Self.updateTraces();
            hObj.String=num2str(val);
        end
        
        function noise_Callback(hObj, eventdata, Self,S)
            Anal=Self.hParent;
            val  = round(S.hNoise.Value,1);
            S.hNoiseTxt.String=sprintf('%03.1f', val);
            S.hNoise.Value    = val;
            Anal.noiseThresh(val);
            Self.updateTraces();
        end
        %
        function noiseTxt_Callback(hObj, eventdata, Self, S)
            Anal=Self.hParent;
            val =str2num(hObj.String);            %
            S.hNoise.Value=val;
            S.hNoiseTxt.String= sprintf('%3.2f', val);
            %
            Anal.noiseThresh(val);
            %
            Self.updateTraces();            
        end
        %
        function maxDist_Callback(hObj, eventdata, Self, S)
            Self.hParent.maxDist=str2num(hObj.String);
            Self.updateTraces();            
        end
        
        function minDist_Callback(hObj, eventdata, Self, S)
            Self.hParent.minDist=str2num(hObj.String);
            Self.updateTraces();            
        end
        
        function freq_Callback(hObj, eventdata, Self, S)
            val =round(S.hFreq.Value,1);            %
            S.hFreqTxt.String=sprintf('%3.1f', val);
            Anal=Self.hParent;
            Anal.setMaxFrequency(val)
            Self.updateTraces();            
        end
        %
        function freqTxt_Callback(hObj, eventdata, Self, S)
            val =str2num(hObj.String);            %
            S.hFreq.Value=val;
            Anal=Self.hParent;
            Anal.setMaxFrequency(val);
            Self.updateTraces();            
        end
        %
        function pix_Callback(hObj, eventdata, Self, S)
            val =round(get(hObj,'Value'),2);
            S.hPixTxt.String=sprintf('%3.2f', val);
            Self.hParent.noisePx(val);
            Self.updateTraces();
        end
        %
        function pixTxt_Callback(hObj, eventdata, Self, S)
            val =round(str2num(hObj.String),2);
            S.hPix.Value=val;
            Self.hParent.noisePx(val);
            Self.updateTraces();
        end
        %
        function fps_Callback(hObj, eventdata, Self)
            val = str2double(get(hObj,'String'));
            Anal=Self.hParent;
            Anal.framesPerSecond=val;
            maxFreq=Anal.setMaxFrequency();
            Anal.setMaxFrequency(maxFreq);
            Self.updateTraces;            
        end
        
        function runAvgSlow_Callback(hObj, eventdata, Self)
            Anal=Self.hParent;
            val = Anal.odd( str2num(get(hObj,'String')));
            %must be odd value
            set(hObj,'String', num2str(val));
            Anal.runAvgSLen(val);
            %Anal.loopDistances();
            Self.updateTraces();
        end
        
        
        function avg_Callback(hObj, eventdata, Self)
            Anal=Self.hParent;
            val = str2num(get(hObj,'String'));
            Anal.runAvgLen(val);
            %Anal.loopDistances();
            Self.updateTraces();
        end
        
        function toDb_Callback(hObj, eventdata, Self)
            bInteractive=true;
            Self.save_toDb(bInteractive);
        end
        
         function boxplot_Callback(hObj, eventdata, Self)
            %range=[1 Self.hParent.curFrame];
            %bActive=Self.hParent.activeList;
            Self.hParent.boxplot();
        end
        
        function heatmap_Callback(~, eventdata, Self)
            Self.hParent.heatmap();
        end
        
        function pointcare_Callback(~, eventdata, Self)
            Self.hParent.pointcare();
        end
        
        function tetanic_Callback(~, eventdata, Self)
            Self.hParent.dataTable();
        end
        
        function paramtr_Callback(hObj, eventdata, Self)
            Self.openParameterFigure();
        end
        
        function open_Callback(hObj, eventdata, Self)
            %
            Anal=Self.hParent;
            %
            [name path]=uigetfile({'*.xml','All Files'},'Select Data File', Anal.fPathIn);
            fName=fullfile(path,name);
            %
            if ~ exist(fName, 'file')
                h=errordlg('File not found', 'File Error');
                uiwait(h)
                return
            end
            %
            %
            S=Anal.getFilenames(fName);
            % test if all files are there
            fPara=fullfile(S.fPathIn, S.fPara);
            %fDist=fullfile(S.fPathIn, S.fDistHough);
            fDist=fullfile(S.fPathIn, S.fDist);
            %
            if ~exist(fPara,'file')
                h=errordlg(sprintf('Parameter file %s not found',fPara),'File Error');
                uiwait(h)
                return
            end
            if ~exist(fDist,'file')
                h=errordlg(sprintf('Distance file %s not found', fDist), 'File Error');
                uiwait(h)
                return
            end
            %
            set(Self.hFigure, 'pointer', 'watch')
            % 
            % 
            Anal.empty;
            Anal.setFilenames(fName);
            %
            Anal.loadState(fPara);
            %
            Anal.readDistances(fDist);
            % Loading of Analysis State File fPara may have overwritten the actual
            %
            set(Self.hFigure, 'Name',fName);
            set(Self.hFps, 'String',num2str(Anal.framesPerSecond));
            %
            Anal.firstFrame(1);
            Self.updateDistances();
            Anal.analyzeDistances();            
            Self.updateTraces;          
            %
            set(Self.hFigure, 'pointer', 'arrow')            
        end
        
        function save_Callback(hObj, eventdata, Self)
            %
            Self.save();
        end
        %
        
        function mouseWheel_Callback(hFig, eventdata, Self)
            %
            % if the mouse is currently over an axis object zoom into that axis
            %
            hAxes=overobj('Axes');
            %
            if isempty(hAxes)==0
                %
                set(hFig, 'Pointer','watch')
                %
                move=eventdata.VerticalScrollCount*0.1;  %move 10% per click
                %
                pos=get(hAxes,'CurrentPoint');
                xpos=pos(1,1);
                %
                XLim=hAxes.XLim;
                %
                newL = int16(max(0,    int16(XLim(1)+(XLim(1)-xpos)*move)));
                newR = int16(XLim(2)+(XLim(2)-xpos)*move);
                %
                Anal=Self.hParent;
                for i=1:Self.hParent.nWell
                    Self.hParent.well(i).scaleXaxis([newL newR]);
                    Self.hParent.well(i).scaleYaxis();
                end
                %Self.scaleXaxes([newL newR]);
                %
                set(hFig, 'pointer','arrow')
            end
        end
        %
        function closeMain_Callback(hObj, event,Self)
            %
            %Self.saveState;
            %
            if Self.bInteractive && Self.bChangesPending
                choice = questdlg({'Do you want to keep changes?', ...
                    'Existing Files will be overwritten'}, ...
                    'Save Changes Pending', 'Yes', 'No','Cancel','Cancel');
                switch choice
                    case 'Yes'
                        %Self.hParent.saveState;
                        Self.save;
                        hFigure = findobj('Type','figure');
                        for i=1:numel(hFigure)
                            hFigure(i).delete
                        end
                    case 'No'
                        hFigure = findobj('Type','figure');
                        for i=1:numel(hFigure)
                            hFigure(i).delete
                        end
                    case 'Cancel'
                end
            else
                hFigure = findobj('Type','figure');
                for i=1:numel(hFigure)
                   hFigure(i).delete
                end                
            end
        end
    end
end