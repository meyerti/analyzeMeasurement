classdef OOvideoAnalysis < OOwellSet
    % OOVIDEOANALYSISGPU Summary of this class goes here
    % Setailed explanation goes here
    properties
        %
        bUseGpu=false;
        bUseMean=false;  %use either mean or max of pixSum to calc Dist
        bInvert=0;
        bBinarize=1;
        %
        bRelative=1;  %calculate relative forces
        %
        bTetanic=false;
        bRegular=true;
        
        timer;
        cycleTime;
        hVideo=0;
        roi=[0 0 0 0];
        %
        fileSet=0;
        %
        houghX=[];
        houghY=[];
        houghR=[];
        
        imgRows;
        imgCols;
        %
        gridWidthMm=18;       % to calculat the pixel_to_mm
        strecherDistance=5;   % to calculate target ROI
        strecherDiameter=1.1; %
        %
        %
        gridRows=50
        gridCols=100
        ratioGrid=2/1; % grid has twice as many cols as rows
        %
        ratioRows=0.3;
        ratioCols=0.3;
        %
        roiRows=20
        roiCols=50
        %ratioRows=1/3; % take middle-third of Rows as roi
        %ratioRows=1/2; % take middle-third of Rows as roi
        %ratioCols=1/2; % take center half of Cols as roi
        imgRowList
        imgColList
        roiRowList
        roiColList
        %
        % image data in RAM
        %
        image=[]
        %
        pixSum=[];  %2D Array
        pixMean=[]
        pixMax=[]        
        %
        imgRange=[];
        roiRange=[];             % nWell x 4 matrix with [x y w h] for each roi
        imgMin  =[];             % same size as image, for scaling to min/max
        imgMax  =[];             % same size as image, for scaling to min/max
        imgScale=[];             %scale factor = (image-imgMin)*255/(imgMax-imgMin)
        imgRoi
        imgRoi16;
        roiCpu;         %3D Array with rois roiRows x roiCols x nRow*nCol
        %
        linRoi;
        linCut;
        % POSIX time
        recordingTimestamp
        analysisTimestamp
        %
        %peakAnalFrame=0
        %
        bFlipImage=false;
        rotateImageDeg=0;
        %
        darkThresh=0.05  %keep only 5% of darkest pixel
        %
        % Distance, Frame, and Time are circular Buffers!
        % this is required for continuous analysis of video Data
        runThresh=[]
        Minimum=[]
        Maximum=[]
        %
        % some distances might no have been recorded because of missing
        % strechers, ROI issues etc.
        %
        activeCols=[]
        %
        %
        
        Distance=[]
        DistanceRaw=[]
        DistanceMax=[]
        DistanceHough=[]
        %
        %
        curDistAvg=[]
        curDistMax=[]
        curDistHough=[]
        %
        runAvg=[];    %running average window 5
        runAvgBuffer=[];
        %
        runAvgS=[];    % slow running average window 51
        runAvgSBuffer=[];
        %
        runNei=[];
        runNeiBuffer=[]
        %
        runMin=[];
        runMinBuffer=[]
        %
        runMax=[];
        runMaxBuffer=[]
        %
        runNoi=[];        % Determines local noise level
        runNoiBuffer=[]
        %
        lastMin=[];
        lastFrc=[];
        lastRR=[];
        % This buffer assures the minimum peak distance
        %
        %
        tgtRowSum=[];
        tgtColSum=[];
        %
        %
        %
        minThresh=10;   %img filter
        maxThresh=240;
        %
        analysisTime=0;
        %
        %
        %
        bDone=false;
        % Define local Filesnames
        fDist;
        fDistMax;
        fDistHough;
        fPara;
        fStats;
        fPeaks;
        fPdf;
        %
        ExperimentName
        MeasurementName
        dbCred='DB_credentials.json';
    end
    
    methods
        function Self=OOvideoAnalysis
            %
            Self.bRawFilter=true;
            Self.nRow=8;
            Self.nCol=6;
            
            bufferSize=25000;            
            %            
            Self.fileSet=OOfileSet();
            %
            Self.timer=tic;
            Self.cycleTime=toc(Self.timer);
            %
            Self.imgCols=5120;
            Self.imgRows=3600;
            %
            Self.curFrame=1;
            Self.image=rand(Self.imgRows,Self.imgCols)*150;
            %
            Self.stateVars=unique({Self.stateVars{:}  ...
                'analysisTimestamp'  ...
                'bStimulate' 'compressVideo' ...
                'Date' 'darkThresh' 'duration' ...
                'ExperimentName' 'exposureTime' ...
                'fastBufferSize' 'fNameIn'  'fPathOut' 'fRoot' 'frameRate' ...
                'gain' ...
                'imgWidth' 'imgHeight' 'MeasurementName' ...
                'nCol' 'nRow' 'noiseThresh' ...
                'peakThresh' 'pixThresh' 'pixel_per_mm' 'pixUse' ...
                'ratioCols' 'ratioRows'...
                'reverseX' 'reverseY' 'recordingTimestamp' 'roi' ...
                'runAvgLen' 'runAvgSLen' ...
                'runMinLen' 'runMaxLen' 'runNeiLen' 'runNoiLen' ...
                'slowBufferSize'  ...
                });
            %
            %
            % Set Default Values for Peak Finding
            %
            Self.runAvgLen(3);
            Self.maxFrequency(1.5);
        end
        %
        function setMode(Self, mode)
            switch lower(mode)
                case 'tetanic'
                    Self.bTetanic=true;
                    Self.bRegular=false;                    
                    Self.analyzeTetanic;
                    % assume we have only 1 peak within the trace
                case 'regular'
                    Self.setNeighborLength(21);
                    initializeAnalysis(Self)
                    Self.bTetanic=false;
                    Self.bRegular=true;                
                    Self.runAvgLen(3);
                otherwise
                    disp('mode not known');
            end
        end
        
        function nPeak=analyzeTetanic_Mina(Self)
            
            Self.runMinLen=5;
            Self.runMaxLen=5;
            Self.runNeiLen=151;
            Self.runNoiLen=11;            
            Self.runAvgLen(51);
            Self.runAvgSLen(9);
            Self.fNoisePx     = 1;       % noise in Pixel Deviation        
            Self.fNoiseThresh = 5;         % Factor of how many times the peak must superate the noise level
            Self.initializeAnalysis();
            Self.loopDistances();                   
                        
            fh=figure;
            nPeak=0;
            for i=1:Self.nWell
                %
                Self.Minimum(:,i)=nan(Self.bufferSize,1);
                
                hist=histogram(Self.runAvg(:,i),10);
                
                [pks, pos] = findpeaks([0 hist.Values 0]);
                %
                %                    
                if numel(pks)==2
                    peak = hist.BinEdges(min(pos));
                    base = hist.BinEdges(max(pos));
                    half=peak+base/2;
                    
                    Self.well(i).bActive=true;
                    sprintf('Well %i min %4.1f max %4.1f peakHeight %4.2f', i, base, peak, peak-base)
                    nPeak=nPeak+1;
                    [mval mpos]=min(Self.runAvg(:,i));
                    Self.Minimum(mpos,i)=mval;
                    Self.runMax(:,i)=base*ones(Self.bufferSize,1);                    
                else
                    disp(sprintf('Well %i has %i peaks', i, numel(pks)));
                    Self.well(i).bActive=false;
                end                
            end           
           delete(fh); 
        end
        
        
        function nPeak=analyzeTetanic(Self)
            
            Self.runMinLen=301;
            Self.runMaxLen=301;
            Self.runNeiLen=301;
            Self.runNoiLen=11;            
            Self.runAvgLen(5);
            Self.runAvgSLen(5);
            Self.fNoisePx    = .3;       % noise in Pixel Deviation        
            Self.fNoiseThresh = 3;         % 
            Self.initializeAnalysis();
            Self.loopDistances();                   
                        
            nPeak=0;
            for i=1:Self.nWell
                %               
                well=Self.well(i);
                Self.copyParameter(well);                
                well.analyzeDistances;
                well.findPeaks;
                well.analyzePeaks;
                well.updatePlots;
           end           
        end
        
        function S=setFilenames(Self,fName)
            %
            S=Self.getFilenames(fName);
            %
            for field=fieldnames(S)'
                Self.(field{1}) = S.(field{1});
            end
            %
        end
        
        function S=getFilenames(Self,fName)
            %
            S=struct;
            %
            [fPath name ext]=fileparts(fName);
            %
            dirs=regexp(fPath,'\','split');
            %
            S.fPathIn=fPath;
            S.fNameIn=[name ext];
            %
            if Self.outLevel==0
                S.fPathOut = fPath;
                S.fRoot = name;
            elseif Self.outLevel==-1
                S.fPathOut   = strjoin(dirs(1:end-1),'\');
                S.fRoot      = dirs{end};
            else
                error(sprintf('outLevel %d nOK', Self.outLevel));
            end
            %
            S.fDist      = [S.fRoot '.csv'];
            S.fDistMax   = [S.fRoot '.max.csv'];
            S.fDistHough = [S.fRoot '.hough.csv'];
            S.fStats     = [S.fRoot '.stats.xml'];
            S.fPara      = [S.fRoot '.xml'];
            %
            strRange=[num2str(Self.firstFrame()) '_' num2str(Self.lastFrame())];
            S.fPeaks= [S.fRoot '.peaks.' strRange '.xml' ];
            S.fPdf  = [S.fRoot '.pdf.'   strRange '.pdf' ];
            %
        end
        %
        function initialize(Self)
            %
            %Self.scale(Self.nRow, Self.nCol);
            Self.roi = maxRoiSize(Self);
            Self.resizeRoi(Self.roi);
        end
        %
        
        
        function A=force_per_pixel(Self)
            %
            % calculate force constant according to beam bending equation
            %
            % F(d) =           A        *       d
            %
            %         3*pi* E [N/mm2]*r^4      1      l
            % F(d) = ------------------     ------  ---   d
            %          4*l^3                 px2mm   lp
            %
            % d  = deflection in pixels
            % l = distance of EHM from bottom (8mm)
            % d = deflection at tip
            % lp = total length of pole (14)
            %
            E = 5.0; % [MPa] = [M N/m^2] = [N/mm^2]
            %        E-Modulus for TangoBlack
            %
            r = Self.strecherDiameter/2;    % mm
            l =  8   ;    % mm
            lp = 14  ;    % mm
            %
            % the measuresd pixel movement is the sum of both poles, so
            % each pole is moving only half of the measured distance,
            % Therefor insert factor 1/2
            %
            % and convert to mN/pixel
            %
            A=0.5*3*pi*E*r^4/(4*l^3) * 1/Self.pixel_per_mm * l/lp*1000;
        end
        
        function initializeAnalysis(Self)
            Self.initializeDistanceAnalysis;
            Self.initializePeakAnalysis;
        end
        
        function initializeDistanceAnalysis(Self)
            % initialize principle buffers, all same length !
            % do not use Self.nWell since this counts wells in list
            % and might, at this point, not be up-to-date
            nWell=Self.nRow*Self.nCol;
            Self.runAvg  = nan(Self.bufferSize, nWell);
            Self.runAvgS = nan(Self.bufferSize, nWell);
            Self.runMin  = nan(Self.bufferSize, nWell);
            Self.runMax  = nan(Self.bufferSize, nWell);
            Self.runNoi  = nan(Self.bufferSize, nWell);
            Self.runNei  = nan(Self.bufferSize, nWell);
            % buffer for averaging, length = window length
            Self.runAvgBuffer  = nan(Self.runAvgLen, nWell);
            Self.runAvgSBuffer = nan(Self.runAvgSLen,nWell);
            Self.runMinBuffer  = nan(Self.runMinLen, nWell);
            Self.runMaxBuffer  = nan(Self.runMaxLen, nWell);
            Self.runNeiBuffer  = nan(Self.runNeiLen, nWell);
            Self.runNoiBuffer  = nan(Self.runNoiLen, nWell);
            %
            Self.Frame        = nan(Self.bufferSize,1);
            %Self.Time         = nan(Self.bufferSize,1);
            Self.curFrame     = 0;
            Self.bDone        = false;
            %
        end
        
        function initializePeakAnalysis(Self)
            %
            nWell=Self.nRow*Self.nCol;
            %
            Self.runThresh = nan(Self.bufferSize, nWell);
            Self.Minimum   = nan(Self.bufferSize, nWell);
            %
            Self.lastMin   = zeros(1, nWell);
            Self.lastFrc   =   nan(1, nWell);
            Self.lastRR    =   nan(1, nWell);
        end
        
        function initializeDistances(Self)
            nWell=Self.nRow*Self.nCol;
            %
            Self.Distance      = nan(Self.bufferSize, nWell);
            Self.DistanceMax   = nan(Self.bufferSize, nWell);
            Self.DistanceHough = nan(Self.bufferSize, nWell);
        end
        
    
        
        %returns the time resulution in miliseconds
        function res=timeResolution(Self)
            res=1000/Self.framesPerSecond
        end
        
        % returns the pixel size in micrometer
        function res=spatialResolution(Self)
            res=1000/Self.pixel_per_mm;
        end
        
        function setFrameRate(Self, frameRate)
            %
            Self.frameRate=frameRate;
            %
            Self.loopPeaks;
            %
            %
            if Self.hVideo ~=0 && isvalid(Self.hVideo)
                hSource=Self.hVideo.Source;
                %hSource.AcquisitionFrameRateAbs=frameRate;
                hSource.frameRate=frameRate;
            end
            %
        end
        
       function setMaxFreq(Self, frq)
            % This changes the Size of the Neighborhood Buffer
            % To fill the Neighborhood Distance Analysis must be repeated
            error('old function, dont use');
            Self.maxFreq=frq;
            Self.loopDistances;   %required to update neighBuffSize
            Self.loopPeaks;
       end
        
       
       
        function roi = maxRoiSize(Self)
            %
            % shape of Roi must change too
            %
            h= Self.nRow -1 + Self.ratioRows;
            b= Self.nCol -1 + Self.ratioCols;
            %
            aspectRatio=Self.ratioGrid*b/h;
            %
            if Self.imgCols / Self.imgRows > aspectRatio
                roi = round([1 1 Self.imgRows * aspectRatio Self.imgRows]);
            else
                roi = round([1 1 Self.imgCols Self.imgCols/aspectRatio]);
            end
            %
        end
        
        function roi=scale(Self, nRow, nCol)
            %
            error('this place should not be reached')
            scale@OOwellSet(Self,nRow, nCol)
            %Self.nRow = nRow;
            %Self.nCol = nCol;
            %
            Self.initializeDistances;
            Self.initializeAnalysis;
            %
            Self.maximizeRoi;
            %Self.analyze;
        end
        
        function roi=fitRoi(Self)
            roi=[0 0 0 0];
            %blurred = imfilter(Self.image,fspecial('average',400),'replicate');
            %colSum=sum(Self.image-blurred);
            %plot( colSum/max(colSum)*1500, 'Parent', Self.hA_preview);
            img=im2bw(imfilter(Self.image,fspecial('average',4),'replicate'),0.1);            
            %
            rowSum=sum(img');
            x=rowSum-mean(rowSum);
            %
            %do some zero padding
            x(Self.imgRows+1:2*Self.imgRows)=0;
            %do FFT ind inverseFFT to get ACF
            X = fft(x);
            c = ifft(abs(X).^2);
            %
            % find the max within the estimated grid Range
            %
            gridMax=floor(Self.imgRows/Self.nRow*1.1);
            gridMin=floor(Self.imgRows/Self.nRow*0.7);
            %
            [val pos]=max(c(gridMin:gridMax));
            %
            Self.gridRows=pos+gridMin-1;            
            %
            % fold the signal to determine the offset
            %
            dd=sum(reshape(x(1:Self.gridRows*Self.nRow), [Self.gridRows,Self.nRow])');
            [pk yOff] = max(dd);
            %
            % calculate the Rows per well-ROI            
            Self.roiRows  = floor(Self.gridRows*Self.ratioRows);
            % define the first row and width of entire ROI
            roi(2)=floor(yOff-Self.roiRows/2);
            roi(4)=Self.gridRows*(Self.nRow-1)+Self.roiRows;
            % make a list with all nRow first rows
            rows=roi(2): Self.gridRows: roi(2)+roi(4);            
            Self.imgRowList=zeros(Self.roiRows, Self.nRow, 'uint16');
            %
            for i=1:Self.nRow
                Self.imgRowList(:,i) = rows(i):rows(i)+Self.roiRows-1;
            end
            %
            % Filter the relevant Rows, only the information of these Rows
            % will be used to determine the columns. This is to filter
            % noise from e.g. reflections.
            % Since we have 2 motivs, 18mm and 3.9mm, the fft will show
            % triplets, which are harder to analyze
            
            imgCut=img(Self.imgRowList(:),:);
            %same procedure as for rows            
            rowSum=sum(imgCut);
            x=rowSum-mean(rowSum);
            %do some zero padding
            x(Self.imgCols+1:2*Self.imgCols)=0;
            %do FFT ind inverseFFT to get ACF
            X = fft(x);
            c = ifft(abs(X).^2);
            % Since Wells have 9:18mm shape we expect to have twice as many
            % Cols as Rows
            gridMax=floor(Self.gridRows*2*1.2);
            gridMin=floor(Self.gridRows*2*0.8);
            %
            [val pos]=max(c(gridMin:gridMax));
            Self.gridCols=pos+gridMin-1;
            %roiCols should be even
            Self.roiCols  = floor((Self.gridCols*Self.ratioCols)/2)*2;
            % Fold signal to find Offset
            dd=sum(reshape(x(1:Self.gridCols*Self.nCol), [Self.gridCols,Self.nCol])');
            dd=dd-min(dd);
            %
            cog=[0,0];
            for i=1:Self.gridCols
                cog(1)=cog(1)+dd(i)*i;                
                cog(2)=cog(2)+dd(i);
            end        
            %[val xOff] = max(dd);
            xOff=cog(1)/cog(2);
            %            
            % define the first col and width of entire ROI
            roi(1)=floor(xOff-Self.roiCols/2);
            roi(3)=Self.gridCols*(Self.nCol-1)+Self.roiCols;
            roi
        end
        
        function roi=fitRoiFft(Self)
            %
            % starting Guess
            %
            yGrid=floor(Self.imgRows/Self.nRow);
            %
            gridMax=floor(yGrid*1.2);
            gridMin=floor(yGrid*0.8);
            %
            rowSum=(255-sum(single(Self.image')))/Self.imgCols;
            colSum=(255-sum(single(Self.image)))/Self.imgRows;
            % shift and smoothen data
            x=runningAverage(rowSum-mean(rowSum),45);
            %do some zero padding
            x(Self.imgRows+1:2*Self.imgRows)=0;
            %do FFT ind inverseFFT to get ACF
            X = fft(x);
            c = ifft(abs(X).^2);
            % find the max within the estimated grid Range
            [mV mP]=max(c(gridMin:gridMax));
            yGrid=mP+gridMin-1;
            % fold the signal to determine the offset
            dd=sum(reshape(x(1:yGrid*Self.nRow), [yGrid,Self.nRow])');
            % to filter for left border (dark) set
            % 'MinPeakProminence',10
            [pks locs] = findpeaks(double(dd),'SortStr','descend', 'NPeaks',1, 'MinPeakProminence',10);
            yOff=locs(1)-yGrid/6;
            %figure;
            %plot(dd)
            %
            
            
            x=runningAverage(colSum-mean(colSum),45);
            %do some zero padding
            x(Self.imgCols+1:2*Self.imgCols)=0;
            %
            %X = fft(x);
            %c = ifft(abs(X).^2);
            %r=fft(x);
            %acf=ifft(r.*r);
            fitXGrid=false
            %
            if fitXGrid
                gridMin=2*gridMin;
                gridMax=2*gridMax;
                %
                [mV mP]=max(c(gridMin:gridMax));
                xGrid=mP+gridMin-1;
            else
                xGrid=round(yGrid*Self.ratioGrid)
            end
            %pShift =angle(X(xGrid))
            %xOff=(pShift+pi/2)*xGrid
            %
            %figure;
            %plot([gridMin:gridMax], c(gridMin:gridMax));
            dd=sum(reshape(x(1:xGrid*Self.nCol), [xGrid,Self.nCol])');
            [pks locs] = findpeaks(double(dd),'SortStr','descend', 'NPeaks',2, 'MinPeakProminence',10);
            xOff=mean(locs)-xGrid/4;
            %
            roiWidth =xGrid*(Self.nCol-1)+Self.ratioCols
            roiHeight=yGrid*(Self.nRow-1)+Self.ratioRows
            %
            roi=round([xOff yOff roiWidth roiHeight])
            %
            h= Self.nRow -1 + Self.ratioRows;
            b= Self.nCol -1 + Self.ratioCols;
            %
            aspectRatio=Self.ratioGrid*b/h;
            %
            sprintf('After Fft have Ar %4.3f tgt %4.3f', roi(3)/roi(4), aspectRatio)
            Self.resizeRoi(roi);
            %
        end
        %
        function [x1, x2]=findImageBorders(Self, data)
            y=data-mean(data);
            %
            signum = sign(y); % get sign of data
            signum(y==0) = 1; % set sign of exact data zeros to positiv
            zeroCross=find(diff(signum));
            %
            if signum(1)== 1
                x1=1;
            else
                x1=zeroCross(1);
            end
            %
            if signum(end)==1
                x2=numel(y);
            else
                x2=zeroCross(end);
            end
            
            if (0)
                figure(2);
                plot(y)
                hold on;
                stem([x1, x2], [max(y) , max(y)]);
            end
        end
        %
        
        
        function yGrid=findFrequencyMax(Self, data)
            %do some zero padding
            x=data-mean(data);
            %
            Fs=numel(data);
            
            nfft=2^nextpow2(Fs*2);
            %
            X = fft(x,nfft); % Fast Fourier Transform
            X = X(1:1+nfft/2); % half-spectrum
            % analyse real part
            R = abs(X.^2); % raw power spectrum density
            A = angle(X);
            [v,k] = max(R); % find maximum
            %
            f_scale = (0:nfft/2)* Fs/nfft; % frequency scale
            omegaOut  = f_scale(k); % dominant frequency estimate
            lambdaOut = Fs/omegaOut;
            %
            if A(k) < 0
                pShift = A(k)/(2*pi);
            else
                pShift = A(k)/(2*pi) -1;
            end
            %
            dLambdaOut=-pShift*lambdaOut;
            %
            
            %
            if (0)
                figure(1);
                subplot(3,1,1)
                plot(x), axis('tight'), grid('on'), title('Time series')
                subplot(3,1,2)
                stem(R(1:30)),axis('tight'),grid('on'),title('Dominant Frequency')
                subplot(3,1,3)
                stem(A(1:30)),axis('tight'),grid('on'),title('Angles')
                %
                %
                fprintf('Freq. %d: %.1f Hz %.1f px, shift %.1f px\n',k, omegaOut, lambdaOut, dLambdaOut)
            end
            
        end
        %
        function grid=findAcfMax(Self, data)
            %
            %
            x=double(data-mean(data));
            Fs=numel(x);
            x(Fs+1:2*Fs)=0;
            %
            nfft=2^nextpow2(Fs*2);
            %X = fft(x, nfft);
            X = fft(x);
            c = ifft(abs(X).^2);
            % find the max within the estimated grid Range
            [mV mP]=max(c);
            figure;
            subplot(2,1,1)
            plot(x(1:Fs)), axis tight;
            subplot(2,1,2)
            plot(c(1:Fs)), axis tight;
            [pks locs] = findpeaks(c(1:Fs),'SortStr','descend', 'NPeaks',3, 'MinPeakProminence',10);
            hold on;
            plot(locs, pks, 'd');
            grid=diff(locs)
            
        end
        %
        function roi=fitRoiTwoStage(Self)
            %
            % stage One: Find surrounding Frame
            %
            % filter image in 2D
            min2D = runningExtreme(Self.image,101,'min');
            %
            rowMax=single(max(min2D'));
            colMax=single(max(min2D));
            [y1, y2] = Self.findImageBorders(rowMax);
            [x1, x2] = Self.findImageBorders(colMax);
            %
            %rowAvg=mean(Self.image');
            %
            yGrid=Self.findAcfMax(rowMax(y1:y2));
            xGrid=Self.findAcfMax(colMax(x1:x2));
            %
            
            %
            roiWidth =xGrid*(Self.nCol-1+Self.ratioCols)
            roiHeight=yGrid*(Self.nRow-1+Self.ratioRows)
            %
            roi=round([xOff yOff roiWidth roiHeight])
            %
            h= Self.nRow -1 + Self.ratioRows;
            w= Self.nCol -1 + Self.ratioCols;
            %
            aspectRatio=Self.ratioGrid*b/h
            %
            sprintf('After Fft have Ar %4.3f tgt %4.3f', roi(3)/roi(4), aspectRatio)
            Self.resizeRoi(roi);
            %
        end
        %
        function genTgtRoi(Self,grid)
            %
            % create
            %    _     _             _
            % __| |___| |__ and ___ | |___
            %
            % discrete pattern for findROI
            h= (Self.nRow -1 + Self.ratioRows)*grid;
            w= (Self.nCol -1 + Self.ratioCols)*grid*Self.ratioGrid;
            %
            tgtRowSum=zeros(h,1);
            %
            dy=grid;
            y1=floor(grid*Self.ratioRows/2)
            %
            mm2pix=grid/9;
            %
            tgtRowSum(y1:dy:y1+7*dy)=1;
            %
            %
            Self.tgtColSum=zeros(Self.roiRows,1);
            dx=2*grid;
            x1=floor(dx*Self.ratioCols/2 - (3.7/2*mm2pix));
            x2=y1+3.7*mm2pix;
            %
            tgtColSum(x1:dx:x1+5*dx)=1;
            tgtColSum(x2:dx:x2+5*dx)=1;
            %
            tgtColSum=runningAverage(tgtColSum,25);
            tgtRowSum=runningAverage(tgtRowSum,25);
            figure;
            subplot(2,1,1)
            plot(tgtRowSum), axis tight;
            subplot(2,1,2)
            plot(tgtColSum), axis tight;
        end
        
        %
        function updateImg(Self)
            
        end
        %
        function setImage(Self, img)
            %
            [Self.imgRows Self.imgCols]=size(img);
            Self.image =img;
            
            %Self.scale(8,6);
            Self.initializeDistances;
            Self.initializeAnalysis;
            %
            Self.maximizeRoi;
            
            Self.maximizeRoi;
            Self.scalePixel;
            Self.updateRoi;
            
        end
        
        
        
        
        function genTgtSums(Self)
            %
            % create
            %    _     _             _
            % __| |___| |__ and ___ | |___
            %
            % discrete pattern for findROI
            Self.tgtRowSum=zeros(Self.roiCols,1);
            col2mm=ceil(Self.roiCols/9/2)*2;
            
            Self.tgtRowSum(2.0*col2mm:3.5*col2mm)=1;
            Self.tgtRowSum(5.5*col2mm:7.0*col2mm)=1;
            %
            Self.tgtColSum=zeros(Self.roiRows,1);
            Self.tgtColSum(1.0*col2mm:2.0*col2mm)=1;
            %
        end
        
        function resizeImg(Self)
            %dummy function, only required in GPU Version
        end
        
        function resizeRoi(Self, roi)
            %
            Self.roi=round(roi);
            %
            %
            % roiCols must be even because analysis requires separation of
            % left and right half
            Self.gridRows = floor(roi(4) / (Self.nRow-1+Self.ratioRows));
            Self.gridCols = floor(roi(3) / (Self.nCol-1+Self.ratioCols));
            %
            Self.roiRows  = floor(Self.gridRows*Self.ratioRows);
            Self.roiCols  = floor(Self.gridCols*Self.ratioCols/2)*2;
            %
            roiSize=[Self.gridRows Self.gridCols]
            %
            %
            Self.pixel_per_mm=Self.gridCols/Self.gridWidthMm;
            %
            Self.imgRoi  = ones(Self.roiRows*Self.nRow, Self.roiCols*Self.nCol, 'uint8');
            Self.linRoi  = ones(Self.roiRows, Self.roiCols*Self.nCol*Self.nRow, 'uint8');
            
            Self.imgScale= Self.imgRoi;
            Self.imgMin  = Self.imgScale*0;
            Self.imgMax  = Self.imgScale*255;
            %
            %
            dims=[Self.roiRows Self.roiCols Self.nWell];
            %
            % ROI Positions in image
            %
            rows=Self.roi(2):Self.gridRows:Self.roi(2)+Self.roi(4);
            cols=Self.roi(1):Self.gridCols:Self.roi(1)+Self.roi(3);
            %
            Self.imgRange=zeros(Self.nWell,4);
            Self.imgRange(:,1)=reshape(repmat(rows,Self.nCol,1),1,Self.nRow*Self.nCol);
            Self.imgRange(:,2)=repmat(cols,1,Self.nRow);
            Self.imgRange(:,3)=Self.imgRange(:,1)+Self.roiRows-1;
            Self.imgRange(:,4)=Self.imgRange(:,2)+Self.roiCols-1;
            %
            Self.imgRowList=zeros(Self.roiRows, Self.nRow, 'uint16');
            Self.imgColList=zeros(Self.roiCols, Self.nCol, 'uint16');
            %
            for i=1:Self.nRow
                Self.imgRowList(:,i) = rows(i):rows(i)+Self.roiRows-1;
            end
            %
            for i=1:Self.nCol
                Self.imgColList(:,i) = cols(i):cols(i)+Self.roiCols-1;
            end
            %
            %
            Self.imgColList(Self.imgColList>Self.imgCols)=Self.imgCols;
            Self.imgRowList(Self.imgRowList>Self.imgRows)=Self.imgRows;
            %
            % Now the ROI Positions in the imgRoi
            %
            rows=1:Self.roiRows:Self.roiRows*Self.nRow;
            cols=1:Self.roiCols:Self.roiCols*Self.nCol;
            %
            Self.roiRange=zeros(Self.nWell,4);
            Self.roiRange(:,1)=reshape(repmat(rows,Self.nCol,1),1,Self.nRow*Self.nCol);
            Self.roiRange(:,2)=repmat(cols,1,Self.nRow);
            Self.roiRange(:,3)=Self.roiRange(:,1)+Self.roiRows-1;
            Self.roiRange(:,4)=Self.roiRange(:,2)+Self.roiCols-1;
            %
            Self.roiRowList=zeros(Self.roiRows, Self.nRow, 'uint16');
            Self.roiColList=zeros(Self.roiCols, Self.nCol, 'uint16');
            %
            for i=1:Self.nRow
                Self.roiRowList(:,i) = rows(i):rows(i)+Self.roiRows-1;
            end
            %
            for i=1:Self.nCol
                Self.roiColList(:,i) = cols(i):cols(i)+Self.roiCols-1;
            end
            %
            
        end
        %
        
        
        %
        function scalePixel(Self)
            %
            %if Self.bInvert
            nTot=Self.roiRows*Self.roiCols/2;            
            nKeep=ceil(nTot*Self.darkThresh);
            %
            %
            roiPos=Self.roiRange;
            %
            for row=1:Self.nRow
                imgRows=Self.imgRowList(:, row);
                roiRows=Self.roiRowList(:, row);
                %
                for col=1:Self.nCol
                    %
                    imgCols=Self.imgColList(1:Self.roiCols/2, col);
                    roiCols=Self.roiColList(1:Self.roiCols/2, col);
                    %
                    img = uint16(Self.image(imgRows, imgCols));
                    tmpArr=sort(img(:));
                    %
                    % filter so we only keep the lightest n% of all pixel
                    %
                    imgMin  = tmpArr(nTot-nKeep);
                    imgMax  = tmpArr(nTot);
                    imgRange= max([imgMax-imgMin 1]);
                    %[row col imgMin imgMax]
                    %
                    Self.imgMin(roiRows,roiCols)   = imgMin;
                    Self.imgMax(roiRows,roiCols)   = imgMax;
                    Self.imgScale(roiRows,roiCols) = uint8(imgRange);
                    %
                    % do the same for the right side
                    % Shift Columns 1/2 roi
                    %
                    imgCols=Self.imgColList(Self.roiCols/2+1:end, col);
                    roiCols=Self.roiColList(Self.roiCols/2+1:end, col);
                    %
                    img = uint16(Self.image(imgRows, imgCols));
                    %
                    tmpArr=sort(img(:));
                    % filter so we only keep the darkest n% of all pixel
                    imgMin  = tmpArr(nTot-nKeep);
                    imgMax  = tmpArr(nTot);
                    imgRange= max([imgMax-imgMin 1]);
                    %[row col imgMin imgRange  imgMin+imgRange max(img(:))]
                    %
                    Self.imgMin(roiRows,roiCols)   = imgMin;
                    Self.imgMax(roiRows,roiCols)   = imgMax;
                    Self.imgScale(roiRows,roiCols) = uint8(imgRange);
                    %                    
                end
            end
            Self.imgMin  =uint8(Self.imgMin);
            Self.imgMax  =uint8(Self.imgMax);            
            
        end
        
        
        
        function video(Self,hVideo)
            %
            Self.hVideo=hVideo;
            %
            sz=hVideo.VideoResolution;
            Self.imgCols=sz(1);
            Self.imgRows=sz(2);
            %
            if isrunning(hVideo)
                Self.image=hVideo.getdata(1);
            else
                Self.image=uint8(rand(Self.imgRows,Self.imgCols)*255);
            end
            %
            switch class(hVideo)
                case 'OOvideoSource'
                    Self.lastFrame=hVideo.NumberOfFrames;
                    Self.bufferSize=Self.lastFrame;
                case 'videoinput'
                    Self.lastFrame=1;
                otherwise
                    error('videotype nOK')
            end
            %
            Self.Distance=nan(Self.bufferSize,Self.nWell);
            %
            Self.resizeImg();
            Self.updateImg();
            %
            % also does resize Roi, aspect remains constant
            %
            Self.maximizeRoi;
            %
        end
        
        function roi=maximizeRoi(Self)
            %
            roi = Self.maxRoiSize;
            %
            Self.resizeRoi(roi);
            
        end
        
        %
        function range=framesInBuffer(Self)
            firstFrame=max([1, Self.curFrame-Self.bufferSize+1]);
            range=[firstFrame, Self.curFrame];
        end
        
        %
        function ind=range2ind(Self,range)
            %
            if range(2) - range(1)+1 > Self.bufferSize
                errTxt=sprintf('range %d - %d larger than buffer size %d', range(1), range(2), Self.bufferSize);
                error(errTxt);
            end
            % Distance is a circular buffer of size lastFrame.
            % if the requested range
            ind(1)=mod(range(1)-1, Self.bufferSize)+1;
            ind(2)=mod(range(2)-1, Self.bufferSize)+1;
        end
        %
        function A=getDistances(Self,range, iWell)
            %
            if exist ('iWell','var')
                wells=iWell;
            else
                wells=1:numel(Self.Distance(1,:));
            end
            %
            ind=Self.range2ind(range);
            %
            if ind(1) > ind(2)
                A = Self.Distance([ind(1):Self.bufferSize 1:ind(2)],wells);
            else
                A=Self.Distance(ind(1):ind(2),wells);
            end
        end
        %
        function A=getRunMax(Self,range, iWell)
            %
            if exist ('iWell','var')
                wells=iWell;
            else
                wells=1:Self.nWell;
            end
            %
            ind=Self.range2ind(range);
            %
            if ind(1) > ind(2)
                A = Self.runMax([ind(1):Self.bufferSize 1:ind(2)],wells);
            else
                A=Self.runMax(ind(1):ind(2),wells);
            end
        end
        %
        function A=getRunAvg(Self,range,iWell)
            %
            if exist ('iWell','var')
                wells=iWell;
            else
                wells=1:Self.nWell;
            end
            %
            ind=Self.range2ind(range);
            if ind(1) > ind(2)
                A = Self.runAvg([ind(1):Self.bufferSize 1:ind(2)],wells);
            else
                A = Self.runAvg(ind(1):ind(2),wells);
            end
        end
        %
        function A=getRunAvgS(Self, range, iWell)
            %
            if exist ('iWell','var')
                wells=iWell;
            else
                wells=1:Self.nWell;
            end
            %
            ind=Self.range2ind(range);
            if ind(1) > ind(2)
                A = Self.runAvgS([ind(1):Self.bufferSize 1:ind(2)],wells);
            else
                A = Self.runAvgS(ind(1):ind(2),wells);
            end
        end
        %
        function A=getRunMin(Self,range)
            %
            ind=Self.range2ind(range);
            %
            if ind(1) > ind(2)
                A = Self.runMin([ind(1):Self.bufferSize 1:ind(2)],:);
            else
                A=Self.runMin(ind(1):ind(2),:);
            end
        end
        
        
        
        function A=getRunThresh(Self,range)
            ind=Self.range2ind(range);
            if ind(1) > ind(2)
                A = Self.runThresh([ind(1):Self.bufferSize 1:ind(2)],:);
            else
                A=Self.runThresh(ind(1):ind(2),:);
            end
        end
        %
        function A=getRunNoise(Self,range)
            ind=Self.range2ind(range);
            if ind(1) > ind(2)
                A = Self.runNoi([ind(1):Self.bufferSize 1:ind(2)],:);
            else
                A=Self.runNoi(ind(1):ind(2),:);
            end
         end
        
        function A=getMinima(Self,range)
            %
            ind=Self.range2ind(range);
            %
            if ind(1) > ind(2)
                A=Self.Minimum([ind(1):Self.bufferSize 1:ind(2)],:);
            else
                A=Self.Minimum(ind(1):ind(2),:);
            end
        end
        
        function frame(Self, curFrame)
            %
            if curFrame~=Self.curFrame
                sprintf('OOvideoAnalysisGpu:frame: load frame %d', curFrame);
                Self.image=Self.hVideo.read(curFrame);
                Self.curFrame=curFrame;
            end
            Self.updateImg;
            Self.updateRoi;
            
        end
        
        function rotateImage(Self, angle)
            %
            if isa(Self.hVideo, 'videoinput')
                error('not done yet')
            elseif isa(Self.hVideo, 'OOvideoSource')
                Self.hVideo.rotateImageDeg=angle;
            end
            %
            if angle==90 || angle==270
                rows=Self.imgRows;
                Self.imgRows=Self.imgCols;
                Self.imgCols=rows;
                resizeImg(Self)
            end
            %
            curFrame=Self.curFrame
            %
            Self.image=Self.hVideo.read(Self.curFrame);
            Self.updateImg;
            Self.updateRoi;
        end
        
        function flipImage(Self, bFlipImage)
            %
            %
            if isa(Self.hVideo, 'videoinput')
                hSource=get(Self.hVideo, 'Source');
                if bFlipImage
                    set(hSource,'ReverseX','True');
                    set(hSource,'ReverseY','True');
                else
                    set(hSource,'ReverseX','False');
                    set(hSource,'ReverseY','False');
                end
            elseif isa(Self.hVideo, 'OOvideoSource')
                Self.hVideo.bFlipImage=bFlipImage;
            end
            %
            if Self.bFlipImage~=bFlipImage
                Self.bFlipImage=bFlipImage;
            end
            Self.updateImg;
            Self.updateRoi;
            
            
        end
        
        
        function updateRoi(Self)
            %
            Self.imgRoi(:,:) = Self.image(Self.imgRowList(:,:), Self.imgColList(:,:));
            %
            %
            if Self.bBinarize
                Self.imgRoi=(Self.imgRoi>Self.imgMin)*255;
            else
                Self.imgRoi(:,:) = (Self.imgRoi-Self.imgMin)/Self.imgScale;
            end
            %
            if Self.bInvert
                %Self.imgRoi(:,:) = 255-(Self.imgRoi-Self.imgMin)*255./Self.imgScale;
                Self.imgRoi(:,:) = 255-Self.imgRoi(:,:);
            end
            %
        end
        %
        function img=getRoiWell(Self, i)
            col=mod(i-1,Self.nCol)+1;
            row=(i-col)/Self.nCol+1;
            rowList=Self.roiRowList(:,row);
            colList=Self.roiColList(:,col);
            %[i,row,col, min(rowList),max(rowList), min(colList), max(colList)]
            img=Self.imgRoi(Self.roiRowList(:,row), Self.roiColList(:,col));
        end
        
        function time=analyzeHough(Self)
            tic;
            Self.updateRoi;
            %
            nWell=Self.nWell;
            nPole=nWell*2;
            nCol=Self.roiCols/2;
            %
            Self.houghX=ones(2,Self.nWell)*10;
            Self.houghY=ones(2,Self.nWell)*10;
            Self.houghR=ones(2,Self.nWell)*5;
            %
            minRad=8;
            maxRad=20;
            %
            pHough=struct('Method', 'TwoStage', 'ObjectPolarity','bright');
            
            for i=1:Self.nWell
                img=Self.getRoiWell(i);
                [centers, radii, metric] = imfindcircles(img(:,1:nCol),[minRad maxRad],pHough);
                if numel(metric)
                    Self.houghX(1,i)=centers(1,1);
                    Self.houghY(1,i)=centers(1,2);
                    Self.houghR(1,i)=radii(1);
                else
                    Self.houghX(1,i)=10;
                    Self.houghY(1,i)=10;
                    Self.houghR(1,i)=5;
                end
                %
                [centers, radii, metric] = imfindcircles(img(:,nCol+1:nCol*2),[minRad maxRad], pHough);
                if numel(metric)
                    %important: add nCol to get reference to 0,0
                    Self.houghX(2,i)=centers(1,1)+nCol;
                    Self.houghY(2,i)=centers(1,2);
                    Self.houghR(2,i)=radii(1);
                else
                    Self.houghX(2,i)=10;
                    Self.houghY(2,i)=10;
                    Self.houghR(2,i)=5;
                end
                %
                Self.curDistHough(i)=Self.houghX(2,i)-Self.houghX(1,i);
            end
            %
            ind0=mod(Self.curFrame-1, Self.bufferSize)+1;
            Self.DistanceHough(ind0,:)=Self.curDistHough;
            %
            time=toc;
            
        end
        
        function time=analyze(Self)
            %
            % image 2 roi
            %
            tic;
            Self.updateRoi;
            %
            %build column sums
            %
            nWell=Self.nWell;
            nPole=nWell*2;
            nCol=Self.roiCols/2;    %cols per half/well (per pole)
            %
            colSum=[];
            %
            % Build column Sums for A1:A6,B1:B6,..,H1:H6
            %
            for i=1:Self.nRow
                colSum = [colSum sum(Self.imgRoi(Self.roiRowList(:,i),:))];
            end
            %
            posIndex=repmat([1:nCol],1,nPole);
            %
            % posIndex=repmat([1:nCol],1,nPole);
            % calculate the weights per column
            %
            colSum2=colSum.*posIndex;
            %
            sumSmooth=reshape(runningAverage(colSum,5), nCol, nPole);
            [vMax pMax]=max(sumSmooth);
            %
            A=reshape(colSum,  nCol, nPole);
            B=reshape(colSum2, nCol, nPole);
            %
            Self.pixMax  = reshape(pMax,2,nWell);
            Self.pixMean = reshape(sum(B)./sum(A),2,nWell);  %Pixel Mean
            Self.pixSum  = reshape(A,nCol,2,nWell);
            %
            Self.curDistAvg=Self.pixMean(2,:)-Self.pixMean(1,:)+nCol;
            Self.curDistMax=Self.pixMax(2,:)-Self.pixMax(1,:)+nCol;
            %
            % store in circular Buffer!!!
            %
            idx=mod(Self.curFrame-1, Self.bufferSize)+1;
            %
            Self.Distance(idx,:)=Self.curDistAvg;
            %
            Self.DistanceMax(idx,:)=Self.curDistMax;
            %
            Self.Frame(idx)      = Self.curFrame;
            Self.Time(idx)       = Self.curTime;
            %
            time=toc;
        end
        %
        %
        function simulateAnalysis(Self)
            %firstRoiRow
            %
            
            y=(sin(Self.curFrame/50)/2+0.5).^20;
            %
            %sprintf('%d %f\n', Self.curFrame,y)
            % circular Buffer!!!
            %
            ind0=mod(Self.curFrame-1, Self.bufferSize)+1;
            %
            Self.Distance(ind0,:) = (ones(Self.nWell,1)-y)*10+rand(Self.nWell,1);
            Self.Frame(ind0)      = Self.curFrame;
            Self.Time(ind0)       = Self.curTime;
            %
            % now calculate the running averages
            % Any symmetric filter of length N will have a delay of (N-1)/2 samples.
            % We can account for this delay manually.if Self.curFrame>2
            %
        end
        %
        function nPeak=loopPeaks(Self)
            %
            if Self.bTetanic
                nPeak=Self.analyzeTetanic();
            else
                firstFrame=max([Self.firstFrame Self.curFrame-Self.bufferSize]);
                lastFrame =min([Self.lastFrame Self.bufferSize]);
                %
                Self.initializePeakAnalysis;
                %
                nPeak=0;
                %
                %loop through frames
                for i=firstFrame:lastFrame
                  Self.curFrame=i;
                  nPeak=nPeak + Self.findPeaks(i);
                end
            end
        end
        %
        function loopDistances(Self)
            %
            %firstFrame=max([Self.firstFrame Self.curFrame-Self.bufferSize]);
            %lastFrame =min([Self.lastFrame Self.bufferSize]);
            %
            Self.initializeAnalysis;
            %
            %
            for i=Self.firstFrame:Self.lastFrame
                Self.curFrame=i;
                Self.analyzeDistancesParallel;
            end
            %
        end
        %
        %
        % We have 2 Circular Buffers, a large one to store the
        % actual data and the small running buffer for averaging and
        % finding extrema
        %
        function analyzeDistancesParallel(Self)
            %
            i=Self.curFrame;
            %
            frameAvgF = i-(Self.runAvgLen-1)/2;
            frameAvgS = i-(Self.runAvgSLen-1)/2;
            %
            % use the slow filter for maxima and the fast filter for Minima
            % and everything else
            frameMax  = frameAvgS -(Self.runMaxLen-1)/2;
            frameMin  = frameAvgF -(Self.runMinLen-1)/2;
            frameNei  = frameAvgF -(Self.runNeiLen-1)/2;
            frameNoi  = frameAvgF -(Self.runNoiLen-1)/2;
            %
            %Self.peakAnalFrame=min([frameMax, frameMin, frameNei, frameNoi]);
            % calculate indices in circular buffers
            %
            ind      = mod(i-1, Self.bufferSize)+1;
            indAvgL  = mod(frameAvgF-2, Self.bufferSize)+1;
            indAvgF  = mod(frameAvgF-1, Self.bufferSize)+1;
            indAvgS  = mod(frameAvgS-1, Self.bufferSize)+1;
            %
            indMax   = mod(frameMax-1, Self.bufferSize)+1;
            indMin   = mod(frameMin-1, Self.bufferSize)+1;
            indNei   = mod(frameNei-1, Self.bufferSize)+1;
            indNoi   = mod(frameNoi-1, Self.bufferSize)+1;
            %
            % now calc the indices for the running buffers for averaging
            %
            indRunAvgF = mod(frameAvgF-1, Self.runAvgLen)+1;
            indRunAvgS = mod(frameAvgS-1, Self.runAvgSLen)+1;
            %
            indRunMax = mod(frameMax-1, Self.runMaxLen)+1;
            indRunMin = mod(frameMin-1, Self.runMinLen)+1;
            indRunNei = mod(frameNei-1, Self.runNeiLen)+1;
            indRunNoi = mod(frameNoi-1, Self.runNoiLen)+1;
            %
            % first filter for fitting jumps
            %Self.bRawFilter=true;
            %
            if Self.bRawFilter & i > 1 & i < Self.bufferSize
                %
                vel1=Self.Distance(ind,:)-Self.Distance(ind-1,:);
                vel2=Self.Distance(ind+1,:)-Self.Distance(ind,:);
                %
                map= abs(vel1)      < Self.maxVel & ...
                     abs(vel1-vel2) < Self.maxAcc & ...
                     Self.Distance(ind,:) > Self.minDist & ...
                     Self.Distance(ind,:) < Self.maxDist ;
                %
                Self.runAvgBuffer(indRunAvgF,map)  = Self.Distance(ind,map);
                Self.runAvgSBuffer(indRunAvgS,map) = Self.Distance(ind,map);
                %
                %if sum(map) >1
                %    vel1;
                %    vel2;
                %    map;
                %end
            else
                %
                % First fill the running Average Circular buffer for signal
                % smoothing. Use fast smoothing to detect peaks and slow
                % smoothing to define baseline
                %
                Self.runAvgBuffer(indRunAvgF,:)  = Self.Distance(ind,:);
                Self.runAvgSBuffer(indRunAvgS,:) = Self.Distance(ind,:);
            end
            %
            % the calculate the running Average for the last N frames
            %
            Self.runAvg(indAvgF,:)    = nanmean(Self.runAvgBuffer);
            Self.runAvgS(indAvgS,:)   = nanmean(Self.runAvgSBuffer);
            %
            % Now fill the other buffers with the current Values
            %
            Self.runNeiBuffer(indRunNei,:) = Self.runAvg(indAvgF,:);            
            Self.runMaxBuffer(indRunMax,:) = Self.runAvg(indAvgF,:);
            Self.runMinBuffer(indRunMin,:) = Self.runAvgS(indAvgS,:);
            %
            % important, do not use the current distance but the distance
            % corresponding to timepoint of running Average
            %
            % do not include PEaks in noise calculation, therefor only
            % values above avg (poles further away than avg) are considered,
            % since noise is per definition positive be take abs.
            dev=Self.runAvgS(indAvgS,:)-Self.Distance(indAvgS,:);
            dev(dev>0)=nan;
            Self.runNoiBuffer(indRunNoi,:) = abs(dev);
            %
            if i>Self.runMaxLen
                %Self.runMax(indMax,:) = max(Self.runMaxBuffer);
                Self.runMax(indMax,:) = max(Self.runMaxBuffer);
            end
            %
            if i>Self.runMinLen
                %Self.runMin(indMin,:) = min(Self.runMinBuffer);
                Self.runMin(indMin,:) = min(Self.runMinBuffer);
            end
            %
            if i>Self.runNeiLen
                %Self.runNei(indNei,:) = min(Self.runNeiBuffer);
                Self.runNei(indNei,:) = min(Self.runNeiBuffer);
            end
            %
            if i>Self.runNoiLen
                Self.runNoi(indNoi,:) = nanmean(Self.runNoiBuffer);
            end
            %            
        end
        
            
        function nPeak=findPeaks(Self, i)
            %
            % the frame to be analyzed. since we work with running Buffers of
            % various length the lagtime is half ot the longest buffer
            %
            %bufLen=max([Self.runMinLen Self.runMaxLen Self.runNoiLen Self.runNeiLen]);
            %
            nPeak=0;
            iActive=Self.activeCols;
            %
            %i=Self.curFrame;
            % make sure buffers are filled
            %
            if ~ any(isnan([Self.runNoi(i,iActive) Self.runNei(i,iActive) Self.runMax(i,iActive)]))
                %
                indAna  = mod(i-1, Self.bufferSize)+1;
                %
                % the first criterion is that a Peak musT be at least xx% of the
                % max peak hight (runMax-runMin) over n Frames
                dT=(Self.runMax(indAna,:) - Self.runMin(indAna,:)) * Self.peakThresh();
                % the second criterion is that the peak must eb at least N
                % times above the noise level
                dN=Self.runNoi(indAna,:) * Self.noiseThresh;
                dF=ones(1, numel(dT))*Self.noisePx;
                %dR=(Self.runMax(indAna,:)-Self.runMin(indAna,:))*Self.noiseRel;
                %
                dCut=max([dT' dN' dF']');
                %
                %
                Self.runThresh(indAna,:) = Self.runMax(indAna,:) - dCut;
                %
                map=Self.runThresh(indAna,:) < Self.runMin(indAna,:);
                % for the rare case where there are two exact. equal minima put
                % Self.lastMin < frmAna-5
                %
                bMin=double(Self.runAvg(indAna,:) == Self.runNei(indAna,:) &...     %% true if local maximum
                    Self.runAvg(indAna,:) <  Self.runThresh(indAna,:) &...            %% true if it is over Thresh
                    Self.lastMin          <  i-Self.runNeiLen  );
                %
                %[Self.runNeiLen i Self.lastMin Self.curFrame-Self.runNeiLen]
                %
                %bMin=double(  Self.runAvg(indAna,:) == Self.runNei(indAna,:) &...     %% true if local maximum
                %              Self.runAvg(indAna,:) <  Self.runThresh(indAna,:))
                %
                for n=find(bMin)
                    if Self.lastMin(n)
                        Self.lastRR(n)     = i-Self.lastMin(n);
                    end
                    %Self.lastMin(n)       = Self.curFrame;
                    Self.lastMin(n)        = i;
                    Self.lastFrc(n)        = Self.runAvg(indAna,n);
                    Self.Minimum(indAna,n) = Self.runAvg(indAna,n);
                end
                nPeak=sum(bMin);
            else
                %disp(sprintf('findPeaks: not all buffers are filled at %d (of %d)', i, Self.curFrame));
                %[Self.runNoi(i,:) Self.runNei(i,:) Self.runMin(i,:) Self.runMax(i,:)]
            end
        end
        
        function nPeak=findCurPeak(Self)
            Self.analyzeDistances;
            nPeak=Self.findPeaks;
        end        
        %
        %
        %
        function f=getTime(Self,n)
            if (numel(n)==1)
                bufferSize=numel(Self.Time);
                ind=mod(n-1, bufferSize)+1;
                f=Self.Time(ind);
            else
                ind=Self.range2ind(n);
                %
                if ind(1) > ind(2)
                    f = Self.Time([ind(1):Self.bufferSize 1:ind(2)],:);
                else
                    f = Self.Time(ind(1):ind(2));
                end
            end
        end
        %        
        function writeDistances(Self,fName)
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.curFrame
                fprintf(fh, '%8.3f,', Self.Distance(i,1:end-1));
                fprintf(fh, '%8.3f\n', Self.Distance(i,end));
            end
            %
            fclose(fh);
            %
        end
        %
        function writeDistancesHough(Self,fName)
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.curFrame
                fprintf(fh, '%8.3f,', Self.DistanceHough(i,1:end-1));
                fprintf(fh, '%8.3f\n', Self.DistanceHough(i,end));
            end
            %
            fclose(fh);
            %
        end
        %
        function writeDistancesFrame(Self,fName, iFrame)
            %
            fh=fopen(fName,'w');
            %
            fprintf(fh, '%8.3f\n', Self.Distance(iFrame,:));
            %
            fclose(fh);
            %
        end
        
        %
        % returns a cell-array of arrays
        % A1: pks{1}=[12 22 32 34 44]
        % A2: pks{2}=[2 12 32]
        % A3: pks{3}=[]
        %
        function [pos foc bse]=getPeaks(Self, range)
            %
            peak=Self.getMinima(range);
            base=Self.getRunMax(range);
            %
            pos={};
            bse={};
            foc={};
            %
            %
            for i=1:Self.nWell
                pos{i}=find(~isnan(peak(:,i)));                
                bse{i}=base(pos{i},i);
                foc{i}=base(pos{i},i)-peak(pos{i},i);
            end
        end
        %
        
        function [frqData frcData bseData]=getPeakStats(Self, range)
            %
            frcData=zeros(5,Self.nWell);
            frqData=zeros(5,Self.nWell);
            bseData=zeros(5,Self.nWell);
            fps=Self.framesPerSecond;
            %
            bHarmonic=0;
            %
            [pos foc bse]=Self.getPeaks(range);
            %
            for i=1:Self.nWell
                if numel(pos{i}) > 0 && Self.well(i).bActive
                    frcData(:,i)   = [mean(foc{i}) std(foc{i}) min(foc{i}) max(foc{i}) numel(foc{i})];
                    bseData(:,i)   = [mean(bse{i}) std(bse{i}) min(bse{i}) max(bse{i}) numel(bse{i})];
                    %
                    if numel(pos{i}) > 1
                       RR = diff(pos{i});                    
                       %
                       % Carefull, means of Frequencies are not calculated by
                       % the arithmetic mean but, since they are reciprocal,
                       % by the harmonic mean!
                       if bHarmonic
                           frq=fps./RR;
                       else
                       % 20200204:
                       % to avoid confusion we show arithmetic mean
                       %
                            frq=fps/mean(RR);
                       end
                       %
                       frqData(:,i)   = [mean(frq)   std(frq)    min(frq)    max(frq) numel(frq)];
                    end
                end
            end
        end
        
        function [frq foc bse]=getFrequencies(Self, range)
            [frq foc bse]=Self.getPeakStats(range);
        end
        
        
        
        function bOk=getQC(Self, range)
            [frqData frcData]=getPeakStats(Self, range);            
            if Self.bTetanic
                bOk = (frcData(1,:) > Self.minForce);
            else
                bOk = (frcData(1,:) > Self.minForce) .* (frqData(1,:) > Self.minFreq) .* (frcData(5,:) >= Self.minPeaks);
            end
            
        end
        
        
        
        function writeFrequencies(Self,fName, range)
            %
            [frq foc bse]=Self.getPeakStats(range);
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.nWell
                fprintf(fh, '%12.4f,',  frq(1:4,i)); % mean stdev min max
                fprintf(fh, '%5d,',    frq(  5,i)); % n
                fprintf(fh, '%5d,%5d\n',    range);
            end
            %
            fclose(fh);
            %
        end
        
        function writeForces(Self,fName, range)
            %
            [frq foc bse]=Self.getPeakStats(range);
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.nWell
                fprintf(fh, '%12.4f,',  foc(1:4,i)); % mean stdev min max
                fprintf(fh, '%5d,',    foc(  5,i)); % n
                fprintf(fh, '%5d,%5d\n',    range);
            end
            %
            fclose(fh);
            %
        end
        %
        function writeBase(Self,fName, range)
            %
            [frq foc bse]=Self.getPeakStats(range);
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.nWell
                fprintf(fh, '%12.4f,',  bse(1:4,i)); % mean stdev min max
                fprintf(fh, '%5d,',    bse(  5,i)); % n
                fprintf(fh, '%5d,%5d\n',    range);
            end
            %
            fclose(fh);
            %
        end
        %
        %
        function writePeakPositions(Self, fName, range)
            %
            %[pos frc] = Self.getPeaks(range);
            %
            fh=fopen(fName,'w');
            %
            if fh < 1
                errordlg(sprintf('Can not open %s for writing', fName), 'Write Error');
            else
                for i=1:Self.nWell
                    peaks=Self.well(i).getPeaks;
                    %
                    for i=1:peaks.n
                        fprintf(fh, '%5d\n', peaks.get(i).frame);
                        if (i<peak.n)
                            fprintf(fh, ',');
                        end
                    end
                    if peaks.n==0
                        fprintf(fh, '0');
                    end
                    fprintf(fh, '\n');
                end
                fclose(fh);
            end
        end
        %
        function writePeakForces(Self, fName, range)
            %
            [pos frc bse] = Self.getPeaks(range);
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.nWell
                if numel(frc{i})==1
                    fprintf(fh, '%8.5f\n',frc{i}(  end  ));
                elseif numel(frc{i})
                    fprintf(fh, '%8.5f,', frc{i}(1:end-1));
                    fprintf(fh, '%8.5f\n',frc{i}(  end  ));
                else
                    fprintf(fh, '0\n');
                end
            end
            fclose(fh);
        end
        
     
        
        function writeBaseForces(Self, fName, range)
            %
            [pos frc bse] = Self.getPeaks(range);
            %
            fh=fopen(fName,'w');
            %
            for i=1:Self.nWell
                if numel(frc{i})==1
                    fprintf(fh, '%8.5f\n',bse{i}(  end  ));
                elseif numel(frc{i})
                    fprintf(fh, '%8.5f,', bse{i}(1:end-1));
                    fprintf(fh, '%8.5f\n',bse{i}(  end  ));
                else
                    fprintf(fh, '0\n');
                end
            end
            fclose(fh);
        end
        
        
        function filterDistances(Self)
            %
            % check distances to be within range
            %
            error('no longer used')
            dis=Self.DistanceRaw;
            avg=mean(dis);
            dev=std(dis);
            % for each well find those frames that are within 3 std from
            % Mean
            %
            vel=vertcat(diff(dis),zeros(1,48));
            acc=vertcat(diff(vel),zeros(1,48));
            %
            
            rMap=(dis < Self.minDist | dis > Self.maxDist );
            vMap=abs(vel)>Self.maxVel;
            aMap=abs(acc)>Self.maxAcc;
            
            %
            disp(sprintf('Found %d Distances found %d outside the range %d-%d, and %d move faster %d, will be set NaN', ...
                numel(dis), sum(rMap(:)), Self.minDist, Self.maxDist, sum(vMap(:)), Self.maxVel ));
            %
            dis(rMap)=NaN;
            dis(vMap)=NaN;
            dis(aMap)=NaN;
            Self.Distance=dis;
            
        end
        
        function nData=readStats(Self, fName)            
            fprintf('readStats: reading %s\n', fName);
            stats=Self.readXml(fName);
            sWells=fieldnames(stats);
            for iWell=1:length(sWells)
                sWell=sWells{iWell};
                sKeys=fieldnames(stats.(sWell));
                for i = 1:length(sKeys);
                  sKey = sKeys{i};
                  fVal=str2double(stats.(sWell).(sKey));
                  fprintf('well %d %s field %s val %f\n', iWell, sWell, sKey, fVal);                  
                end
            end            
        end
        %
        
        
        function nData=readDistances(Self, fName)
            %
            data=csvread(fName);
            nData=Self.importDistances(data);
            FileInfo = dir(fName);
            try
                Self.recordingTimestamp=posixtime(datetime(FileInfo.datenum, 'ConvertFrom', 'dateNum'));
            catch 
                Self.recordingTimestamp=0000000;
            end
        end
                       
        function nData=importDistances(Self, data)    
            %FileInfo = dir('YourFileWithExtention');            
            %
            [nData nCols]=size(data);
            %
            %            
            if nCols == 8*6
                Self.nRow=8;
                Self.nCol=6;
                Self.DistanceRaw=data;
                Self.Distance   =data;  %unfiltered
                Self.Time       =1:numel(data(:,1));
            elseif nCols == 8*6+1
                Self.nRow=8;
                Self.nCol=6;
                Self.DistanceRaw=data(:,2:49);
                Self.Distance   =data(:,2:49);  %unfiltered
                Self.Time=data(:,1);
                fps=round(nData / (Self.Time(end)-Self.Time(1)),2)
                Self.framesPerSecond(fps);
            else
                %error(sprintf('have %d cols, expect %d\n', nCols, 48))
            end
            %
            if Self.bRawFilter
                Self.Distance(Self.Distance>Self.maxDist)=nan;
                Self.Distance(Self.Distance<Self.minDist)=nan;
            end
            %            
            %
            iCol=1:nCols;
            %
            bOk=max(~isnan(Self.Distance));            
            %
            if (sum(bOk)< 6*8)
                sprintf('only %d if %d cols are OK\n', sum(bOk), nCols)
            end
            %
            %
            %Self.Distance   =data;  %unfiltered
            %            
            Self.curFrame   =nData;
            Self.bufferSize =nData;
            Self.firstFrame(1);
            Self.lastFrame(nData);
            %
            Self.initializeAnalysis();
            %Self.recordingTimestamp=posixtime(datetime(FileInfo.date));            
            %
        end
    end    
end

