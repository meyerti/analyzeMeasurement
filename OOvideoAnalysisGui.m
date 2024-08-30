%classdef to create GUI objects for videoAnalysis
classdef OOvideoAnalysisGui < OOvideoAnalysis
    %classdef OOcontractionDbGui < handle
    %
    properties
        %
        %
        hWait
        hFigure;
        hnFile
        hiFile
        hRoi;
        hStop
        hFit
        
        hDist
        
        hLoop;
        hPixel;
        hPixTxt;
        %
        hSave;
        hAll=0;     % Pushbutton to plot All
        hHough=0
        %
        hF_All=0;   % Figure Handle for plot w. all ROI
        hA_All=[]
        hI_All=[]
        hP_All=[]
        hM_All=[]
        hC_All=[];    %handle for circle
        %
        circAng;    %Angles for Hough Circle
        %
        %OO
        analysisPanel=0; %OO
        
        hRatioRows=0
        hRatioCols=0
        %
        
        %for image series outlevel=-1, outpath one level above
        %inpath
        hNameIn
        hNameOut
        hPathIn
        hPathOut
        hRoiTxt
        hRoiXOff
        hRoiYOff
        hRoiWidth
        hRoiHeight
        
        hFrameRate
        %
        hA_preview
        hI_preview
        %
        hA_A1
        hA_A6
        hA_H1
        hA_H6
        %
        hI_A1
        hI_A6
        hI_H1
        hI_H6
        %
        hP_A1
        hP_A6
        hP_H1
        hP_H6
        %
        hM_A1
        hM_A6
        hM_H1
        hM_H6
        %
        %
        hA_plot
        hP_max
        hP_hough
        %
    end
    
    methods
        function Self = OOvideoAnalysisGui()
            %
            Self.stateVars={Self.stateVars{:}, 'fNameIn','fPathIn','fPathOut','fRoot'};
        end
        %
        %
        %
        function updateFilenames(Self)
            set(Self.hNameIn,  'string', Self.fNameIn);
            set(Self.hNameOut, 'string', Self.fDist);
            set(Self.hPathIn,  'string', Self.fPathIn);
            set(Self.hPathOut, 'string', Self.fPathOut);
            %
            set(Self.hnFile,'String',num2str(Self.fileSet.nFile));
            set(Self.hiFile,'String',num2str(1));
            
        end
        %
        function fitRoi_guiVideo(Self)
            %
            set(0,'defaultuicontrolunits','pixels') ;
            %
            Self.hFigure=figure('Units','pixels', 'Position', [100 100 900 800],...
                'Name','48 well video Analysis Tool', 'NumberTitle','Off');
            Self.hFigure.WindowScrollWheelFcn={@OOvideoAnalysisGui.WindowScrollWheelFcn,Self};
            %pAxes=struct('Units','pixels','YTickLabel', '{}','XTickLabel', '{}');
            pAxes=struct('Units','pixels','XTickLabel', '{}', 'YDir','Reverse');
            pAxes.YTickLabel={};
            %
            Self.hA_preview=axes(pAxes,'Position', [100 300 600 400], 'NextPlot', 'Add' );
            %
            Self.hA_A1     =axes(pAxes,'Position', [ 50 720 120  40],'NextPlot','Add', 'YDir','reverse');
            Self.hA_A6     =axes(pAxes,'Position', [650 720 120  40],'NextPlot','Add', 'YDir','reverse');
            Self.hA_H1     =axes(pAxes,'Position', [ 50 250 120  40],'NextPlot','Add', 'YDir','reverse');
            Self.hA_H6     =axes(pAxes,'Position', [650 250 120  40],'NextPlot','Add', 'YDir','reverse');
            %
            Self.hA_plot   =axes('Units','pixels', 'Position', [50 30 700 200], 'XLim', [0.1 48.9], 'NextPlot','Add');
            %
            % add control of Pixel Cutoff
            %
            Self.hPixel    = uicontrol('Style', 'slider','Value',Self.darkThresh,'Units','pixels','Position', [ 50 330 30 370], 'Min', 0.01);
            Self.hPixTxt   = uicontrol('Style', 'Text','Units',  'pixels','Position', [ 50 300 30  20],'String',sprintf('%4.2f',Self.darkThresh)) ;
            %TooltipString
            addlistener(Self.hPixel,'Value','PreSet',@(~,~)set(Self.hPixTxt,'String',sprintf('%4.2f',Self.hPixel.Value)));
            %
            sTxt=struct('Units','pixels','HorizontalAlignment','left');
            
            Self.hPathIn  = uicontrol(sTxt,'String',  Self.fPathIn, 'Position', [ 200 780 600 17]);
            Self.hPathOut = uicontrol(sTxt,'String',  Self.fPathOut,'Position', [ 200 762 600 17]);
            
            Self.hNameIn = uicontrol('Style', 'pushbutton','String', Self.fNameIn, 'Units','pixels','Position', [ 200 730 400 15]);
            Self.hNameOut = uicontrol('Style', 'edit','String',  Self.fDist, 'Units','pixels','Position',       [ 200 705 400 15]);
            %
            %
            uicontrol('Style', 'text','String', 'ROI', 'Units','pixels','Position',      [ 720 680  40 20]);
            Self.hRoiXOff   = uicontrol('Style', 'edit','String', '1',    'Units','pixels','Position',[ 760 680 30 20],'Tag','RoiXOff');
            Self.hRoiYOff   = uicontrol('Style', 'edit','String', '1',    'Units','pixels','Position',[ 792 680 30 20],'Tag','RoiYOff');
            Self.hRoiWidth  = uicontrol('Style', 'edit','String', '5120', 'Units','pixels','Position',[ 824 680 30 20],'Tag','RoiWidth');
            Self.hRoiHeight = uicontrol('Style', 'edit','String', '3840', 'Units','pixels','Position',[ 856 680 30 20],'Tag','RoiHeight');
            
            %Self.hRoiTxt  = uicontrol('Style', 'edit','String', '1 1 1 1', 'Units','pixels','Position',  [ 800 680 100 20]);
            %
            uicontrol('Style', 'text','String', 'Frame', 'Units','pixels','Position',  [ 720 650 40 20]);
            Self.hnFile  = uicontrol('Style', 'text','String',  num2str(Self.fileSet.nFile), 'Units','pixels','Position', [ 760 650 40 20]);
            Self.hiFile  = uicontrol('Style', 'edit','String',  num2str(Self.fileSet.iFile), 'Units','pixels','Position', [ 800 650 40 20],'Tag','iFile');
            %
            uicontrol('Style', 'text','String', 'FrameRate', 'Units','pixels', 'Position', [ 720 620  60 20]);
            Self.hFrameRate = uicontrol('Style', 'edit','String', num2str(Self.frameRate), 'Units','pixels','Position', [ 785 620  80 20]);
            %
            sDate=datestr(datetime(Self.recordingTimestamp, 'ConvertFrom','posixtime'),'yyyy-mm-dd')
            sTime=datestr(datetime(Self.recordingTimestamp, 'ConvertFrom','posixtime'),'HH:MM:SS')
            uicontrol('Style', 'text','String', 'Recording', 'Units','pixels', 'Position', [ 720 580  60 20]);
            uicontrol('Style', 'text','String', 'Date','Units','pixels', 'Position',  [ 720 560  60 20]);
            uicontrol('Style', 'text','String', sDate, 'Units','pixels', 'Position',  [ 785 560  80 20]);
            uicontrol('Style', 'text','String', 'Time','Units','pixels', 'Position',  [ 720 540  60 20]);
            uicontrol('Style', 'text','String', sTime, 'Units','pixels', 'Position',  [ 785 540  80 20]);
            %
            uicontrol('Style', 'text','String', 'ratioRows', 'Units','pixels', 'Position', [ 720 520  60 20]);
            Self.hRatioRows = uicontrol('Style', 'edit','String',num2str(Self.ratioRows), 'Units','pixels','Position', [ 785 520  80 20]);
            
            uicontrol('Style', 'text','String', 'ratioCols', 'Units','pixels', 'Position', [ 720 500  60 20]);
            Self.hRatioCols = uicontrol('Style', 'edit','String',num2str(Self.ratioCols), 'Units','pixels','Position', [ 785 500  80 20]);
            
            %
            Self.hAll  = uicontrol('Style', 'CheckBox','String','Plot All','Value',0,'Units','pixels','Position', [ 720 460 80 19]);
            Self.hHough= uicontrol('Style', 'CheckBox','String','Hough','Value',0,'Units','pixels','Position',    [ 720 440 80 19]);
            Self.hDist = uicontrol('Style', 'CheckBox','String','Distances','Value',0,'Units','pixels','Position',[ 720 420 80 19]);
            %
            Self.hSave = uicontrol('Style', 'pushbutton','String','Save',    'Units','pixels','Position', [ 200 250 98 40]);
            Self.hLoop = uicontrol('Style', 'pushbutton','String','Loop',    'Units','pixels','Position', [ 300 250 98 40]);
            Self.hStop = uicontrol('Style', 'pushbutton','String','Stop',    'Units','pixels','Position', [ 400 250 98 40]);
            Self.hFit  = uicontrol('Style', 'pushbutton','String','Fit Roi', 'Units','pixels','Position', [ 500 250 98 40]);
            %
            %
            Self.hI_preview = image(Self.image, 'Parent',Self.hA_preview);
            %
            % calculate pixel sums
            %
            blurred = imfilter(Self.image,fspecial('average',400),'replicate');
            colSum=sum(Self.image-blurred);
            rowSum=sum(Self.image'-blurred');
            plot( colSum/max(colSum)*1500, 'Parent', Self.hA_preview);
            plot([rowSum/max(rowSum)*2000], [1:Self.imgRows], 'Parent', Self.hA_preview);
            
            Self.hI_A1      = image(155-Self.getRoiWell(1),  'Parent', Self.hA_A1);
            Self.hI_A6      = image(155-Self.getRoiWell(6),  'Parent', Self.hA_A6);
            Self.hI_H1      = image(155-Self.getRoiWell(43), 'Parent', Self.hA_H1);
            Self.hI_H6      = image(155-Self.getRoiWell(48), 'Parent', Self.hA_H6);
            %
            sA1=[Self.pixSum(:,1,1)' , Self.pixSum(:,2,1)' ];
            sA6=[Self.pixSum(:,1,6)' , Self.pixSum(:,2,6)' ];
            sH1=[Self.pixSum(:,1,43)', Self.pixSum(:,2,43)'];
            sH6=[Self.pixSum(:,1,48)', Self.pixSum(:,2,48)'];
            %
            yScale=Self.roiRows/2; %scale plot height to half max
            %
            Self.hP_A1      = plot(sA1/max(sA1)*yScale,  'Parent', Self.hA_A1);
            Self.hP_A6      = plot(sA6/max(sA6)*yScale,  'Parent', Self.hA_A6);
            Self.hP_H1      = plot(sH1/max(sH1)*yScale,  'Parent', Self.hA_H1);
            Self.hP_H6      = plot(sH6/max(sH6)*yScale,  'Parent', Self.hA_H6);
            %
            nCol=Self.roiCols/2;
            %
            lA1=Self.pixMax(1,1);
            rA1=Self.pixMax(2,1)+nCol;
            lA6=Self.pixMax(1,6);
            rA6=Self.pixMax(2,6)+nCol;
            lH1=Self.pixMax(1,43);
            rH1=Self.pixMax(2,43)+nCol;
            lH6=Self.pixMax(1,48);
            rH6=Self.pixMax(2,48)+nCol;
            %
            mx=Self.roiRows;
            Self.hM_A1 = plot([lA1 lA1 rA1 rA1],[mx 0 0 mx],'r','Parent', Self.hA_A1);
            Self.hM_A6 = plot([lA6 lA6 rA6 rA6],[mx 0 0 mx],'r','Parent', Self.hA_A6);
            Self.hM_H1 = plot([lH1 lH1 rH1 rH1],[mx 0 0 mx],'r','Parent', Self.hA_H1);
            Self.hM_H6 = plot([lH6 lH6 rH6 rH6],[mx 0 0 mx],'r','Parent', Self.hA_H6);
            %
            %
            Self.curFrame=1;
            Self.analyze;
            
            Self.hP_max    = stem(Self.curDistMax,':x','Parent',Self.hA_plot);
            Self.hP_hough  = plot(Self.curDistMax,'ro','Parent',Self.hA_plot);
            
            set(Self.hA_preview, pAxes);
            set(Self.hA_A1,  pAxes);
            set(Self.hA_A6,  pAxes);
            set(Self.hA_H1, pAxes);
            set(Self.hA_H6, pAxes);
            %
            colormap gray(256);
            %
            %roi=Self.roi;
            Self.hRoi=imrect(Self.hA_preview,Self.roi);
            %
            Self.hRoi.addNewPositionCallback(@(pos)OOvideoAnalysisGui.resizeROI(pos, Self));
            %
            constFcn=makeConstrainToRectFcn('imrect',[1 Self.imgCols],[1 Self.imgRows]);
            Self.hRoi.setPositionConstraintFcn(constFcn);
            %
            % define Callbacks at end to ensure Self (static) is complete
            set(Self.hPixel,  'Callback', {@OOvideoAnalysisGui.pixel_Callback,Self} );
            set(Self.hSave,   'Callback', {@OOvideoAnalysisGui.save_Callback,Self} );
            set(Self.hNameOut,'Callback', {@OOvideoAnalysisGui.out_Callback,Self} );
            set(Self.hAll,    'Callback', {@OOvideoAnalysisGui.all_Callback,Self} );
            set(Self.hHough,  'Callback', {@OOvideoAnalysisGui.hough_Callback,Self} );
            set(Self.hDist,   'Callback', {@OOvideoAnalysisGui.dist_Callback,Self} );
            set(Self.hNameIn, 'Callback', {@OOvideoAnalysisGui.in_Callback,Self} );
            set(Self.hLoop,   'Callback', {@OOvideoAnalysisGui.loop_Callback,Self} );
            Self.hStop.Callback={@OOvideoAnalysisGui.stop_Callback,Self};
            Self.hFit.Callback ={@OOvideoAnalysisGui.fit_Callback,Self};
            
            set(Self.hnFile,  'Callback', {@OOvideoAnalysisGui.nFile_Callback,Self} );
            
            set(Self.hiFile,  'Callback', {@OOvideoAnalysisGui.iFile_Callback,Self} );
            
            set(Self.hFrameRate, 'Callback', {@OOvideoAnalysisGui.frameRate_Callback,Self} );
            %
            set(Self.hFigure, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeMain_Callback,Self} );
            %
            set(Self.hRatioRows, 'Callback', {@OOvideoAnalysisGui.ratio_Callback,Self} );
            set(Self.hRatioCols, 'Callback', {@OOvideoAnalysisGui.ratio_Callback,Self} );
            
            Self.hRoiXOff.ButtonDownFcn ={@OOvideoAnalysisGui.mouse_Callback,Self};
            Self.hiFile.ButtonDownFcn   ={@OOvideoAnalysisGui.mouse_Callback,Self};
            
            
            Self.updateRoiTxt;
            %
            %
            
        end
        %
        
        %
        
        function updateRoiTxt(Self)
            roi=Self.hRoi.getPosition;
            %set(Self.hRoiTxt,'String', sprintf('%d %d %d %d', floor(roi)));
            Self.hRoiXOff.String  =num2str(floor(roi(1)));
            Self.hRoiYOff.String  =num2str(floor(roi(2)));
            Self.hRoiWidth.String =num2str(floor(roi(3)));
            Self.hRoiHeight.String=num2str(floor(roi(4)));
        end
        
        function plotAll(Self)
            %
            width=round(Self.roiCols*0.7);
            height=round(Self.roiRows*0.7);
            
            margin=1;
            %
            Position=[50 50 margin+(width+margin)*Self.nCol margin+(height+margin)*Self.nRow];
            %
            Self.hF_All=figure('Units','pixels', 'Position', Position,'Name','ROI Preview', 'NumberTitle','Off');
            %
            set(Self.hF_All, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeAll_Callback,Self} );            
            %
            Self.circAng=0:0.1:2*pi;
            %
            i=1;
            %
            for row=1:Self.nRow
                for col=1:Self.nCol
                    well=Self.well{i};
                    pos=[margin+(margin+width)*(col-1) margin+(margin+height)*(Self.nRow-row) width height];
                    well.image=Self.getRoiWell(i);
                    well.initializeRoiPlot(Self.hF_All,pos);
                    %
                    well.initializePixSumPlot;
                    well.initializeCenterLinePlot;
                    %
                    well.updateImage
                    %
                    i=i+1;
                end
            end
            %
            colormap gray(256);
            refresh(Self.hF_All);
        end
        
        function addWaypoint(Self, xPos)
            for i=1:Self.nWell
                Self.well(i).addWaypoint(xPos);
            end
            Self.waypoint(end+1)=xPos;            
        end
        
        function n = nWaypoint(Self)
           n=numel(Self.waypoint);
        end
        
        function removeWaypoints(Self, xPos)
            for i=flip(1:Self.nWaypoint)
                Self.removeWaypoint(Self.waypoint(i));
            end            
        end
        
        function removeWaypoint(Self, xPos)
            for i=1:Self.nWell
                Self.well(i).removeWaypoint(xPos);
            end
            pos=find(Self.waypoint==xPos);
            Self.waypoint(pos)=[];
        end
        
        
        function updateAll(Self)
            
            %yScale=Self.roiRows/2;
            binWidth=2;
            range=30;
            %
            for i=1:Self.nWell
                well=Self.well(i);
                well.image=Self.getRoiWell(i);
                well.scaleImage;
                well.updateImage;
                well.updatePixelSum;                    
            end
            
        end
        %
        function analyzeHough(Self)
            set(Self.hFigure, 'pointer', 'watch')
            analyzeHough@OOvideoAnalysis(Self);
            % your computation
            set(Self.hFigure, 'pointer', 'arrow')
        end
        %
        function updateHough(Self)
            %
            for i=1:numel(Self.hA_All)
                xC=Self.houghX(1,i)+Self.houghR(1,i)*cos(Self.circAng);
                yC=Self.houghY(1,i)+Self.houghR(1,i)*sin(Self.circAng);
                set(Self.hC_All(1,i), 'XData', xC, 'YData', yC);
                %
                xC=Self.houghX(2,i)+Self.houghR(2,i)*cos(Self.circAng);
                yC=Self.houghY(2,i)+Self.houghR(2,i)*sin(Self.circAng);
                set(Self.hC_All(2,i), 'XData', xC, 'YData', yC);
            end
            
        end
        %
        function fh=heatmap(Self)
            %
            %
            fh=findobj('Name','Heatmap');
            %
            if ~numel(fh)
                fh=figure('Name','Heatmap','numbertitle','off', 'Position', [500 200 500 500]);
                %
                
                S=struct('Units','Normalized','NextPlot','Add','XLim',[0.1 6.9],...
                    'YLim',[0.1 8.9],'YDir','reverse','Parent',fh,...
                    'YTickLabel',['A':'H']');
                %
                aFrq=axes(S, 'Position',[0.1 0.50 0.88 0.44], 'Tag','Freq', 'XTickLabel',[]);
                ylabel('Frequency [Hz]','FontSize',12,'FontWeight','bold'); % y-axis label
                aFrc=axes(S, 'Position',[0.1 0.05 0.88 0.44], 'Tag','Force');
                ylabel('Force [%]','FontSize',12,'FontWeight','bold'); % y-axis label
                %
                title(aFrq,Self.fRoot, 'interpreter','none');
                %title(aFrc,'Force');
            else
                aFrc=findobj(fh, 'Tag','Force');
                for i=numel(aFrc.Children):-1:1
                    aFrc.Children(i).delete;
                end
                %
                aFrq=findobj(fh, 'Tag','Freq');
                for i=numel(aFrq.Children):-1:1
                    aFrq.Children(i).delete;
                end
            end
            % collect data
            frc=nan(Self.nWell,1);
            rr =nan(Self.nWell,1);
            %   
            for i=1:Self.nWell
                well=Self.well(i);
                well.analyzePeaks();
                if well.bActive && well.PeakList.n > 3
                    frc(i,1)=nanmean(well.PeakList.getValues('force'));
                    rr(i,1) =nanmean(well.PeakList.getValues('RR'));
                end
            end
            
            Self.heatmap_plot(aFrq, Self.framesPerSecond ./ rr);
            Self.heatmap_plot(aFrc, frc.*100);
        end
        %
        function heatmap_plot(Self, hAxes, data);
            %
            box(hAxes,'on');
            %
            % map with 66 entries
            cmap=colormap('Jet');
            cmap(1,:)=[0 0 0];
            cnum=numel(cmap(:,1));
            % get Wells which do have signal
            %
            bActive=data>0;
            values=data(bActive);
            %
            avg=nanmean(values);
            dev=nanstd(values);
            %
            sig=3;
            %
            hRect={};
            hText={};
            %
            index=floor((data-avg)/dev/sig*cnum/2+cnum/2);
            index(~bActive)=1;
            index(index<1)=1;
            index(index>cnum)=cnum;
            iWell=1;
            %
            for row=1:Self.nRow
                for col=1:Self.nCol
                    %
                    hRect{iWell}=rectangle('Position',[ col-0.4 row-0.4 0.8 0.8],...
                        'Curvature', [.2 .2], 'FaceColor', cmap(index(iWell),:), 'Parent',hAxes);
                    %
                    hText{iWell}=text(col,row, sprintf('%4.2f', data(iWell)),'FontSize',8,'HorizontalAlignment','center', 'Parent',hAxes);
                    %
                    iWell=iWell+1;
                end
            end
            %
            %hBar=colorbar(hAxes,'Location','southoutside');
            hBar=colorbar(hAxes,'Location','eastoutside');
            xTick=get(hBar,'Ticks');
            % scale to -sig*dev - sig*dev
            scaled=(xTick-0.5)*2*dev*sig+avg;
            set(hBar,'TickLabels', arrayfun(@(scaled)(sprintf('%.2f', scaled)),scaled, 'UniformOutput',false));
            % default colorbar goes from 0 to 1
            
            
        end
        
        function fh=dataTable(Self)
            if (Self.nWaypoint>0)
                Self.showWaypointData();
            else
                Self.showWellData();
            end
        end
        
        function fh=showWellData(Self)
            fh=findobj('Name','WellData');
            
            if ~numel(fh)
                fh=figure('Name','WellData','numbertitle','off', 'Position', [100 100 80+10*90 Self.nWell*20+20]);
            end
            %
            clf(fh);
            %
            sdata={};
            sdata{1,2}='abs_time';
            sdata{1,3}='rel_time';
            sdata{1,4}='fStrech';
            sdata{1,5}='frcAvg';
            sdata{1,6}='frcDev';
            sdata{1,7}='frqAvg';
            sdata{1,8}='frqDev';
            %
            sdata{1,9}='tag';
            sdata{1,10}='fName';
            %
            %
            t0=Self.well(1).time;
            for i=1:Self.nWell             
               well=Self.well(i);
               sdata{i+1,1}=well.sWell;
               %absolute time 
               sdata{i+1,2}=num2str(posixtime(well.time));
               %time relative to start
               sdata{i+1,3}=num2str(hours(well.time-t0));
               %
               sdata(i+1,4)= num2cell(well.stretchFactor);
               %
               [frqData frcData bseData] = well.getPeakStats();
               %
               sdata(i+1,5)=num2cell(frcData(1)); %avg
               sdata(i+1,6)=num2cell(frcData(2)); %dev
               sdata(i+1,7)=num2cell(frqData(1)); %avg frq
               sdata(i+1,8)=num2cell(frqData(2)); %dev frq                           
               %
               sdata(i+1,9)={well.tag}; %dev frq                           
               sdata(i+1,10)={well.fName}; %dev frq                           
            end
            %
            %sdat(2:18, 2:6)=num2cell(data)            
            %[sWell' num2cell([sCol; data])];
            uit = uitable(fh,'Data',sdata);            
            uit.Units='Normalized';
            uit.Position=[0.01 0.01 0.98 0.98];
        end
        
        function fh=showWaypointData(Self)
            %
            if (Self.nWaypoint==0)
                error('no waypoints');
            end
            %
            fh=findobj('Name','Tetanic');
            %
            if ~numel(fh)
                fh=figure('Name','Tetanic','numbertitle','off', 'Position', [500 100 80+Self.nWaypoint*90 Self.nWell*20]);
            end
            %
            clf(fh);
            %
            data=zeros(Self.nWell, Self.nWaypoint);
            name={};            
            %
            sorted=sort(Self.waypoint);            
            %
            for i=1:Self.nWell
               well=Self.well(i);
               name{i+1}=well.sWell;               
               for j=1:Self.nWaypoint                   
                   data(i,j)=well.getWaypointFoc(sorted(j));
               end
            end                            
            %
            sdat=[name' num2cell([sorted; data])];
            uit = uitable(fh,'Data',[name' num2cell([sorted; data])]);            
            uit.Units='Normalized';
            uit.Position=[0.01 0.01 0.98 0.98];
        end
        
        function fh=pointcare(Self)
            %
            %
            fh=findobj('Name','Pointcare');
            %
            if ~numel(fh)
                fh=figure('Name','Pointcare','numbertitle','off', 'Position', [500 100 800 1000]);
                %                
                S=struct('Units','Normalized','NextPlot','Add','Parent',fh,...
                    'YTickLabel',[], 'XTickLabel',[]);
                %                
                width=0.15;
                hight=0.10;
                %
                for iWell=1:Self.nWell
                   well=Self.well(iWell);
                   %iCol=well.iCol
                   xpos = 0.02 + (well.iCol-1)*(width+0.01)
                   ypos = 0.98 - well.iRow*(hight+0.01)
                   str = sprintf('PC_%d',iWell);
                   well.hPcAxes = axes(S, 'Position',[xpos ypos width hight], 'Tag',str, 'XTickLabel',[]);
                end                
                %ylabel('RRn+1 [ms]','FontSize',12,'FontWeight','bold'); % y-axis label
                %
                %title(aFrc,'Force');
            else
                %
                for iWell=1:Self.nWell
                    well=Self.well(iWell);
                    if (well.hPcAxes ~= 0)
                        for j=numel(well.hPcAxes.Children):-1:1                    
                            well.hPcAxes.Children(j).delete;                                       
                        end
                    end
                end
            end
            % collect data
            %   
            for i=1:Self.nWell
                well=Self.well(i);
                well.plotPointcare();                
            end
            %
        end
        %
        
        
        function close(Self)
            %if Self.hAll
            %    set(Self.hAll, 'Value',0);
            %end
            %
            hFigure = findobj('Type','figure');
            %
            for i=1:numel(hFigure)
                hFigure(i).delete
            end
            %
            delete(Self);            
        end
        
        function fh=boxplot(Self)
            %           
            % fonvert force of contraction into % of base
            %            
            Xlim=[0 Self.n+1];
            %
            fh=findobj('Name','Boxplot');
            %
            if ~numel(fh)
                fh=figure('Name','Boxplot','numbertitle','off');
                S=struct('Units','Normalized','NextPlot','Add');
                aFrq=axes(S, 'Position',[0.07 0.53 0.9 0.44]);
                aFrc=axes(S, 'Position',[0.07 0.05 0.9 0.44]);
                set(aFrq, 'XLim',Xlim, 'XTick',{}, 'Tag','Freq');
                set(aFrc, 'XLim',Xlim, 'Tag','Force');
                %
                title(aFrq, 'Frequencies', 'Units','Normalized', 'Position',[.5 .9 0]);
                title(aFrc, 'Forces',      'Units','Normalized', 'Position',[.5 .9 0]);
                %
                aFrc.XTick     = [1 7 13 19 25 31 37 43];
                aFrc.XTickLabel = {'A1' 'B1' 'C1' 'D1' 'E1' 'F1' 'G1' 'H1'};
                
                hold on;
            else
                aFrc=findobj(fh, 'Tag','Force');
                for i=numel(aFrc.Children):-1:1
                    aFrc.Children(i).delete;
                end
                %
                aFrq=findobj(fh, 'Tag','Freq');
                for i=numel(aFrq.Children):-1:1
                    aFrq.Children(i).delete;
                end
            end
            %
            % [pos frc bse]=Self.getPeaks(range);
            %
            for i=1:Self.nWell
                well=Self.well(i);
                well.analyzePeaks();
                if well.bActive && well.PeakList.n > 3
                    frc=well.PeakList.getValues('force');
                    rr =well.PeakList.getValues('RR');
                    frq = Self.framesPerSecond./rr;
                    % convert force of contraction into % of base
                    Self.plotBox(aFrc, i, frc);
                    if numel(frq)
                        %takes handle, x-position, y-values
                        Self.plotBox(aFrq, i, frq);
                    end
                end
            end
            %
            % Convert y-axis values to percentage values by multiplication
            a=[cellstr(num2str(aFrc.YTick'*100))];
            % Create a vector of '%' signs
            pct = char(ones(size(a,1),1)*'%');
            % Append the '%' signs after the percentage values
            new_yticks = [char(a),pct];
            % 'Reflect the changes on the plot
            aFrc.YTickLabel=new_yticks;
        end
    end
    %
    methods(Static)
        %
        function resizeROI(pos, Self)
            %roi=pos
            Self.hRoi.setPosition(Self.roi);
            Self.resizeRoi(pos);
            Self.scalePixel;
            Self.updateRoi();
            %
            Self.updateRoiTxt;
            %
            Self.updateImage(Self);
            %
            set(Self.hA_A1, 'XLim', [1 Self.roiCols]);
            set(Self.hA_A1, 'YLim', [1 Self.roiRows]);
            set(Self.hA_A6, 'XLim', [1 Self.roiCols]);
            set(Self.hA_A6, 'YLim', [1 Self.roiRows]);
            %
            set(Self.hA_H1, 'XLim', [1 Self.roiCols]);
            set(Self.hA_H1, 'YLim', [1 Self.roiRows]);
            set(Self.hA_H6, 'XLim', [1 Self.roiCols]);
            set(Self.hA_H6, 'YLim', [1 Self.roiRows]);
            %
            %
            Self.hRoi.setPosition(Self.roi);
            Self.analyze;
            set(Self.hP_max, 'YData', Self.curDistMax);
            
            %
            if get(Self.hAll, 'Value')
                Self.updateAll;
            end
            %
            if get(Self.hHough, 'Value')
                Self.analyzeHough;
                Self.updateHough;
            end
            %
        end
        %
        
        
        %
        function updateImage(Self)
            set(Self.hI_A1, 'CData', Self.getRoiWell(1));
            set(Self.hI_A6, 'CData', Self.getRoiWell(6));
            set(Self.hI_H1, 'CData', Self.getRoiWell(43));
            set(Self.hI_H6, 'CData', Self.getRoiWell(48));
            %
            sA1=[Self.pixSum(:,1,1)' , Self.pixSum(:,2,1)' ];
            sA6=[Self.pixSum(:,1,6)' , Self.pixSum(:,2,6)' ];
            sH1=[Self.pixSum(:,1,43)', Self.pixSum(:,2,43)'];
            sH6=[Self.pixSum(:,1,48)', Self.pixSum(:,2,48)'];
            %
            
            set(Self.hP_A1, 'YData', sA1/max(sA1)*Self.roiRows/2);
            set(Self.hP_A6, 'YData', sA6/max(sA6)*Self.roiRows/2);
            set(Self.hP_H1, 'YData', sH1/max(sH1)*Self.roiRows/2);
            set(Self.hP_H6, 'YData', sH6/max(sH6)*Self.roiRows/2);
            %
            nCol=Self.roiCols/2;
            %
            lA1=Self.pixMax(1,1);
            rA1=Self.pixMax(2,1)+nCol;
            lA6=Self.pixMax(1,6);
            rA6=Self.pixMax(2,6)+nCol;
            lH1=Self.pixMax(1,43);
            rH1=Self.pixMax(2,43)+nCol;
            lH6=Self.pixMax(1,48);
            rH6=Self.pixMax(2,48)+nCol;
            %
            set(Self.hM_A1, 'XData', [lA1 lA1 rA1 rA1]);
            set(Self.hM_A6, 'XData', [lA6 lA6 rA6 rA6]);
            set(Self.hM_H1, 'XData', [lH1 lH1 rH1 rH1]);
            set(Self.hM_H6, 'XData', [lH6 lH6 rH6 rH6]);
            
            %plot( Self.pixelSum(:,1)/max(Self.pixelSum(:,1))*Self.roiRows, 'Parent', Self.hA_A1)
            
        end
        
        function ratio_Callback(hObj, event, Self)
            Self.ratioRows=str2num(get(Self.hRatioRows, 'String'));
            Self.ratioCols=str2num(get(Self.hRatioCols, 'String'));
            OOvideoAnalysisGui.resizeROI(Self.roi, Self);
            Self.updateAll;
        end
        
        function pixel_Callback(hObj, event, Self)
            val=get(hObj, 'Value');
            darkThresh=round(val,2);
            Self.darkThresh=darkThresh;
            Self.scalePixel;
            Self.updateImage(Self);
            Self.hPixTxt.String=sprintf('%4.2f',darkThresh);
            %
            if get(Self.hAll, 'Value')
                Self.updateAll;
            end
            %
            Self.analyze;
            set(Self.hP_max, 'YData', Self.curDistMax);
            %
            if get(Self.hHough, 'Value')
                Self.analyzeHough;
                Self.updateHough;
                set(Self.hP_hough, 'YData', Self.curDistHough);
            end
            %
        end
        %
        function out_Callback(hObj, event,Self)
            Self.fDist=get(Self.hNameOut, 'String');
        end
        %
        function save_Callback(hObj, event,Self)
            %
            fRoot=Self.fRoot;
            Self.writeDistances(fullfile(Self.fPathOut, Self.fDistMax));
            Self.writeDistancesHough(fullfile(Self.fPathOut, Self.fDistHough));
            % save parameter
            S={Self.stateVars{:}, Self.paraVars{:}};
            P=getParameter(Self, S);
            fName=fullfile(Self.fPathOut,Self.fPara);
            Self.saveXml(P, fName);
            Self.saveState;
            %
        end
        %
        function in_Callback(hObj, event,Self)
            %
            [name,path]=uigetfile({'*.bmp; *.tif; *.tiff; *.jpg','All Files'},'Select Image File', fullfile(Self.fPathIn, Self.fPathIn));
            Self.setFilenames(fullfile(name, path));
            Self.updateFilenames;
            %
            Self.image =imread(fullfile(Self.fPathIn, Self.fPathIn));
            [Self.imgRows Self.imgCols]=size(Self.image);
            %
            Self.analyze;
            set(Self.hP_max, 'YData', Self.curDistMax);
            %
            if get(Self.hHough,'Value')
                Self.analyzehough;
                set(Self.hP_hough, 'YData', Self.curDistHough);
            end
            %
            set(Self.hI_preview, 'CData', Self.image);
            Self.updateImage(Self);
            %
            if ishandle(Self.hF_All)
                Self.updateAll(Self);
            end
        end
        
        function iFile_Callback(hObj, event,Self)
            new=str2num(get(hObj, 'String'));
            %
            new=min([new, Self.fileSet.nFile]);
            new=max([new, 1]);
            %
            % now goto frame new
            OOvideoAnalysisGui.analyzeFrame(Self,new);
            
        end
        
        function frameRate_Callback(hObj, event,Self)
            val=str2num(get(hObj, 'String'));
            Self.frameRate=val;
            
        end
        
        function hough_Callback(hObj, event,Self)
            %
            if get(hObj,'Value')
                %
                Self.analyzeHough();
                set(Self.hP_hough, 'YData', Self.curDistHough);
                if ishandle(Self.hF_All)
                    Self.updateHough;
                end
            end
        end
        %
        %
        function all_Callback(hObj, event,Self)
            %
            if get(hObj, 'Value');
                Self.plotAll();
            else
                delete(Self.hF_All);
            end
            %
        end
        %
        function dist_Callback(hObj, event,Self)
            %
            if get(hObj, 'Value');
                Panel=OOvideoAnalysisPanel(Self);
                Panel.bRoi=true;     % do not plot Roi, only Graphs
                Panel.bRoiPlot=true;
                Panel.open_Gui,
                Self.analysisPanel=Panel;
            else
                Self.analysisPanel.delete;
                Self.analysisPanel=0
            end
            %
        end
        %
        function stop_Callback(hObj, event,Self)
            %
            set(Self.hStop,'Value',1);
            %
        end
        
        function fit_Callback(hObj, event,Self)
            %
            pos=Self.fitRoi();
            OOvideoAnalysisGui.resizeROI(pos, Self);
            %
        end
        
        function loop_Callback(hObj, event,Self)
            %
            set(Self.hFigure, 'pointer', 'watch')
            %
            set(Self.hStop,'Value',0);
            %
            refreshFreq=10;
            
            %
            Self.lastFrame=min([Self.fileSet.nFile, str2num(get(Self.hnFile,'String'))]);
            %
            Self.hWait=waitbar(0, sprintf('Analyzing %4d of %4d',0,Self.lastFrame));
            %
            %  set(Self.hFigure, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeMain_Callback,Self} );
            %
            %set(hWait, 'CloseRequestFcn',  {set(Self.hStop,'Value',0)} );
            %
            set(Self.hWait, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeWait_Callback,Self} );
            %
            for curFrame=1:Self.lastFrame
                %
                %
                waitbar(curFrame/Self.lastFrame, Self.hWait, sprintf('Analyzing %4d of %4d ',curFrame, Self.lastFrame));
                %
                OOvideoAnalysisGui.analyzeFrame(Self,curFrame);
                %
                if get(Self.hStop,'Value')
                    break
                end
                
                %
            end
            %
            delete(Self.hWait);
            %
            if get(Self.hDist, 'Value')
                Self.analysisPanel.updatePlots([1 curFrame])
            end
            %
            set(Self.hStop,'Value',0)
            %
            Self.save_Callback(hObj, event,Self);
            %
            set(Self.hFigure, 'pointer', 'arrow');
            %
        end
        %
        function analyzeFrame(Self, curFrame)
            Self.hiFile.String=num2str(curFrame);
            Self.fileSet.iFile=curFrame;
            Self.curFrame=curFrame;
            %
            Self.image =imread(Self.fileSet.fullfile(curFrame));
            Self.analyze;
            Self.hP_max.YData=Self.curDistMax;
            %
            if get(Self.hHough,'Value')
                Self.analyzeHough;
                Self.hP_hough.YData=Self.curDistHough;
            end
            %
            if get(Self.hAll, 'Value')
                Self.updateAll;
            end
            %
            refreshFreq=10;
            %
            if get(Self.hDist, 'Value') && mod(curFrame,refreshFreq) == 0
                Self.analysisPanel.updatePlots([1 curFrame])
            end
            %
        end
        
        function loopPar_Callback(hObj, event,Self)
            %
            set(Self.hFigure, 'pointer', 'watch')
            %
            set(Self.hStop,'Value',0);
            %
            refreshFreq=10;
            %
            Self.lastFrame=min([Self.fileSet.nFile, str2num(get(Self.hnFile,'String'))]);
            %
            Self.hWait=waitbar(0, sprintf('Analyzing %4d of %4d',0,Self.lastFrame));
            %
            %  set(Self.hFigure, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeMain_Callback,Self} );
            %
            %set(hWait, 'CloseRequestFcn',  {set(Self.hStop,'Value',0)} );
            %
            set(Self.hWait, 'CloseRequestFcn',  {@OOvideoAnalysisGui.closeWait_Callback,Self} );
            %
            %POOL = parpool('local',4);
            dist=zeros(1,Self.lastFrame);
            for curFrame=1:Self.lastFrame
                %
                Self.image =imread(Self.fileSet.fullfile(curFrame));
                Self.analyze;
                %
                dist(curFrame)=Self.curDistMax;
                %
                if get(Self.hHough,'Value')
                    Self.analyzeHough;
                    dist(curFrame)=Self.curDistHough;
                end
                %
                
                %
            end
            %
            delete(Self.hWait);
            %
            if get(Self.hDist, 'Value')
                Self.analysisPanel.updatePlots([1 curFrame])
            end
            %
            set(Self.hStop,'Value',0)
            %
            Self.save_Callback(hObj, event,Self);
            %
            set(Self.hFigure, 'pointer', 'arrow');
            %
        end
        %
        function plotNoisePerWell(Self)
            
            Avg=mean(Self.runNoise);
            Min=min(Self.runNoise);
            Max=max(Self.runNoise);
            %
        end
        
        
        function plotBox(aH, y, X)
            %            
            %
            barWidth = .8;
            barFactor=1; %
            linewidth=1;
            
            boxColor = [0.0005    0.3593    0.7380];
            wisColor = [0 0 0]+.3;
            meanColor = [0.9684    0.2799    0.0723];
            medianX=nanmedian(X);
            meanX=nanmean(X);
            stdX = nanstd(X);
            %
            n = length(X);
            x = sort(X);
            Y = 100*(.5 :1:n-.5)/n;
            x=[min(x); x; max(x)];
            % calc 25% and 75%
            if numel(x)>2
                boxEdge = interp1([0 Y 100],x,[25 75]);
            else
                boxEdge=[x(1) x(1)];
            end
            %
            %boxEdge = calcPercentile(X,[25 75]);
            IQR=max(diff(boxEdge),eps);
            
            wisEdge = [meanX-stdX meanX+stdX];
            %
            S=struct('LineWidth',linewidth , 'Parent',aH);
            rectangle('Position',[y-barWidth/2,boxEdge(1),barWidth,IQR],'EdgeColor',boxColor,'facecolor',[1 1 1], S);
            plot([y-barWidth/2 y+barWidth/2],[medianX medianX],'color',meanColor, S);
            plot(y,meanX,'+','color',meanColor,'markersize',10, S);
            plot([y-barWidth/2 y-barWidth/2],[boxEdge(1) boxEdge(2)],'color',boxColor, S);
            plot([y y],[wisEdge(1) boxEdge(1)],'--','color',wisColor,S);
            plot([y y],[boxEdge(2) wisEdge(2)],'--','color',wisColor,S);
            plot([y-barWidth/3 y+barWidth/3],[wisEdge(1) wisEdge(1)],'-','color',wisColor,S);
            plot([y-barWidth/3 y+barWidth/3],[wisEdge(2) wisEdge(2)],'-','color',wisColor,S);
            %plot raw data
            %
            plot(y*ones(numel(X),1),X,'.','color',wisColor,S);
        end
        %
        function closeMain_Callback(hObj, event,Self)
            %
            hFigure = findobj('Type','figure');
            %
            for i=1:numel(hFigure)
                hFigure(i).delete
            end
            %
        end
        %
        function closeWait_Callback(hObj, event,Self)
            %
            set(Self.hStop, 'Value',1);
            %
            delete(hObj);
            %
        end
        %
        function mouse_Callback(hObject, eventdata,h)
            % Manually assign the focus to the edit1 uicontrol
            uicontrol(h)
        end
        %
        function closeAll_Callback(hObj, event,Self)
            %
            if isvalid(Self.hAll)
                set(Self.hAll, 'Value',0);
            end
            %
            delete(hObj);
            %
        end
    end
    
    methods(Static)
        %
        function WindowScrollWheelFcn(hFig, eventdata, Self)
            %
            h = gco;
            if isprop(h,'Tag')
                switch h.Tag
                    case 'RoiXOff'
                        roi=floor(Self.hRoi.getPosition);
                        move=eventdata.VerticalScrollCount;
                        new=roi(1) + move;
                        new=min([new, Self.imgCols-roi(3)]);
                        new=max([new, 1]);
                        roi(1)=new;
                        OOvideoAnalysisGui.resizeROI(roi,Self);
                        
                    case 'RoiYOff'
                        roi=floor(Self.hRoi.getPosition);
                        move=eventdata.VerticalScrollCount;
                        new=roi(2) + move;
                        new=min([new, Self.imgRows-roi(4)]);
                        new=max([new, 1]);
                        roi(2)=new;
                        OOvideoAnalysisGui.resizeROI(roi,Self);
                    case 'RoiWidth'
                        roi=floor(Self.hRoi.getPosition);
                        move=eventdata.VerticalScrollCount;
                        new=roi(3) + move;
                        new=min([new, Self.imgCols-roi(1)+1]);
                        new=max([new, 200]);
                        roi(3)=new;
                        OOvideoAnalysisGui.resizeROI(roi,Self);
                    case 'RoiHeight'
                        roi=floor(Self.hRoi.getPosition);
                        move=eventdata.VerticalScrollCount;
                        new=roi(4) + move;
                        new=min([new, Self.imgRows-roi(2)]);
                        new=max([new, 200]);
                        roi(4)=new;
                        OOvideoAnalysisGui.resizeROI(roi,Self);
                    case 'iFile'
                        move=eventdata.VerticalScrollCount
                        new=Self.fileSet.iFile+move;
                        new=min([new, Self.fileSet.nFile]);
                        new=max([new, 1])
                        %
                        % now goto frame new
                        OOvideoAnalysisGui.analyzeFrame(Self,new);
                    otherwise
                        disp('unknown tag');
                end
            elseif (h==0)
                hAxes=getChild(hFig, 'Axes');
                %
                %
                move=eventdata.VerticalScrollCount*0.1;  %move 10% per click
                %
                pos=get(hAxes,'CurrentPoint');
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
            end
        end
    end
end