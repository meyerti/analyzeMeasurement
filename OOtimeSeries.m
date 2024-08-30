classdef OOtimeSeries < OOtimeSeriesPar
    %
    properties
        %
        id=1;
        %
        hParent;
        PeakList=OOList;
        %
        Distance=[]
        Minimum =[]
        
        Force   =[]
        Peaks   =[]
        % By labelling parts of the trace as stimulated it is possible
        % to separate between stimulated and unstimulated peaks
        bStim   =[]        
        bStimOn =[]        
        stimThresh=0.1;
        %
        bPeakAbs=false;
        %
        %as default analyze Distances        
        %
        bAnalyzeForces=false;
        %        
        runAvg=[];    %running average window 5
        runAvgBuffer=[];
        %firstFrame=1;
        %lastFrame=2500;
        %
        runAvgS=[];    % slow running average window 51
        runAvgSBuffer=[];
        %
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
        runBase=[];
        runBaseBuffer=[]        
        %
        runPeak=[];
        runPeakBuffer=[]
        %      
        %
        runNoi=[];        % Determines local noise level
        runNoiBuffer=[]        
        %
        lastMin;
        lastFrc;
        lastRR;        
        %
        runThresh=[]
        runForce=[]
        %Peak=[]
        %PeakPos=[]
        bDone=false;
        
    end
    
    methods
        %
        function Self = OOtimeSeries(hParent)
            % hParent should be a OOvideoAnalysis Object
            Self.name='A1';
            %Self.hParent.bufferSize=bufferSize;
            %            
        end
        %        
        function initialize(Self,bufferSize)
            Self.bufferSize=bufferSize;
            Self.initializeAnalysis();
        end
        %
        function initializeAnalysis(Self)
            Self.initializeDistanceAnalysis;
            Self.initializePeakAnalysis;
        end
        
         
        function initializeDistanceAnalysis(Self)
            % initialize principle buffers, all same length !
            Self.runAvg  = nan(Self.bufferSize, 1);
            Self.runAvgS = nan(Self.bufferSize, 1);
            %
            Self.runMin  = nan(Self.bufferSize, 1);
            Self.runMax  = nan(Self.bufferSize, 1);
            % Base and Peak will replace Min and Max as
            %it is a question of definition, in distances peaks
            %are minima, in forces they are maxima
            Self.runBase  = nan(Self.bufferSize, 1);
            Self.runPeak  = nan(Self.bufferSize, 1);
            %
            Self.runNoi  = nan(Self.bufferSize, 1);
            Self.runNei  = nan(Self.bufferSize, 1);
            % buffer for averaging, length = window length
            Self.runAvgBuffer  = nan(Self.runAvgLen,1);
            Self.runAvgSBuffer = nan(Self.runAvgSLen,1);
            %
            Self.runMinBuffer  = nan(Self.runMinLen,1);            
            Self.runMaxBuffer  = nan(Self.runMaxLen,1);
            Self.runBaseBuffer = nan(Self.runBaseLen,1);            
            Self.runPeakBuffer = nan(Self.runPeakLen,1);
            %
            Self.runNeiBuffer  = nan(Self.runNeiLen,1);
            Self.runNoiBuffer  = nan(Self.runNoiLen,1);
            %
            Self.curFrame     = 0;
            Self.bDone        = false;
            %
        end
        
        function initializePeakAnalysis(Self)
            %
            %Self.Peak      = nan(Self.bufferSize, 1);
            %Self.PeakPos   = nan(Self.bufferSize, 1);
            Self.runThresh = nan(Self.bufferSize,1);
            Self.Minimum   = nan(Self.bufferSize,1);
            Self.Peaks     = nan(Self.bufferSize,1);
            %
            Self.lastMin      = 0;
            Self.lastFrc      = nan;
            Self.lastRR       = nan;
        end
        %
         function val=setMaxFrequency(Self, val)
            % This changes the Size of the Neighborhood Buffer
            % To fill the Neighborhood Distance Analysis must be repeated
            val=setMaxFrequency@OOtimeSeriesPar(Self, val);
            %
            %Self.maxFreq=frq;            
            %n=floor(Self.framesPerSecond/frq/2)*2+1;
            %setNeighborLength(Self, n)            
            
            Self.analyzeTraces;   %required to update neighBuffSize
            Self.findPeaks;
            %Self.analyzePeaks;
         end
        
        function f=maxDistance(Self, range)
            if exist('range','var')                
              f=max(Self.Distance(range(1):range(2)));
            else
                f=max(Self.Distance);
            end
        end
        %
        function n=nPeak(Self)
            n=Self.PeakList.n;
        end
        %
        function n=lastMinimum(Self)
            %
            if Self.nPeak
                n=Self.PeakList.last.Position.minR;
            else
                n=1;
            end
        end
        %
        function n=lastPeak(Self)
            %
            if Self.nPeak
                n=Self.PeakList.last.Position.minR;
            else
                n=1;
            end
        end
        %
        function [pTime, pForce, pBase]=peakData(Self,range)
            nPeak=Self.nPeak;
            %
            pTime={};
            pForce={};
            pBase={};
            %
            fps=Self.framesPerSecond;
           %
           for i=1:nPeak
              peak=Self.PeakList.get(i);
              if peak.Position.max > range(1) && peak.Position.max < range(2)
                  pTime{end+1} = peak.Position.max/fps;     
                  pForce{end+1}= peak.Value.max;
                  pBase{end+1} = peak.base;
              end
           end
           %           
        end
        %
        %
        function [pTime, pForce, pBase]=peakFitData(Self,range)
            nPeak=Self.nPeak;
            %
            pTime={};
            pForce={};
            pBase={};
           %
           for i=1:nPeak
              peak=Self.PeakList.get(i);
              if peak.Position.max > range(1) && peak.Position.max < range(2)
                  pTime{end+1} =peak.timepoint;                     
                  pForce{end+1}=peak.force;
                  pBase{end+1} =peak.base;
              end
           end
        end
        %
        %
        function n=hasNan(Self)
            n=sum(isnan(Self.Distance));
        end
        
        function analyzeTraces(Self)
            if (Self.bAnalyzeForces)
                Self.analyzeForces();
            else
                Self.analyzeDistances();
            end
                
        end
        
        function analyzeDistances(Self)
            % in distances peaks are minima!
            %
            Self.initializeAnalysis;
            %
            Self.runAvg =runningAvg(Self.Distance, Self.runAvgLen);
            Self.runAvgS=runningAvg(Self.Distance, Self.runAvgSLen);
            %Peaks (are actually minima)
            Self.runMin  =runningMin(Self.runAvg, Self.runMinLen);
            Self.runPeak =runningMin(Self.runAvg, Self.runPeakLen);
            % baseline
            Self.runMax  =runningMax(Self.runAvgS, Self.runMaxLen);
            Self.runBase =runningMax(Self.runAvgS, Self.runBaseLen);
            %
            Self.runNei =runningMin(Self.runAvg, Self.runNeiLen);
            % 
            %remove peaks from data
            dif=Self.Distance-Self.runAvgS;
            dif(dif<0)=nan;   %
            Self.runNoi=runningAvg(dif, Self.runNoiLen);            
        end
        
        function analyzeForces(Self)
            % in Forces peaks are maxima !
            %
            Self.initializeAnalysis;
            %
            Self.runAvg =runningAvg(Self.Force, Self.runAvgLen);
            Self.runAvgS=runningAvg(Self.Force, Self.runAvgSLen);
            %Peaks
            Self.runPeak =runningMax(Self.runAvgS, Self.runPeakLen);
            Self.runBase =runningMin(Self.runAvg,  Self.runBaseLen);
            %
            Self.runNei =runningMax(Self.runAvg, Self.runNeiLen);
            % 
            %remove datapoints below slow running avg to exclude
            %peaks from data to calculate noise from deviation to
            %baseline
            dif=Self.runAvgS-Self.Force;
            dif(dif<0)=nan;   %
            Self.runNoi=runningAvg(dif, Self.runNoiLen);            
        end
        
        function nPeak=findPeaks(Self)
            %
            nPeak=0;
            if (Self.bAnalyzeForces)
                nPeak=Self.findPeaksForce();
            else
                nPeak=Self.findPeaksDistance();
            end
        end
        
        function nPeak=findPeaksDistance(Self)
            %
            Self.runThresh = nan(Self.bufferSize,1);
            %
            dT=(Self.runMax - Self.runMin) .* Self.peakThreshCutOff;
            dN=Self.runNoi * Self.noiseThresh;
            dF= ones(Self.bufferSize,1).* Self.noisePx;
            %
            dCut=max([dT dN dF],[],2);
            Self.runThresh = Self.runMax - dCut;
            %
            bMin = (Self.runAvg == Self.runNei) .* (Self.runAvg < Self.runThresh);
            bMin(1:Self.firstFrame-1)=0;
            bMin(Self.lastFrame+1:end)=0;
            %
            pPos=find(bMin);
            % only consider Peaks in Range
            pPos(pPos < Self.firstFrame)=nan;
            pPos(pPos > Self.lastFrame) =nan;
            %
            dPos=diff(pPos);
            minDist=min(dPos);
            while minDist<Self.runNeiLen
                minPos=find(dPos==minDist,1);
                %[minDist minPos Self.runNeiLen pPos(minPos)]
                %if ( pPos(minPos) > 700 && pPos(minPos) < 750)
                %    [minDist minPos Self.runNeiLen pPos(minPos) pPos(minPos+1)]
                %end
                %
                if (Self.runAvg(pPos(minPos)) > Self.runAvg(pPos(minPos+1)))
                    pPos(minPos)=[];
                else
                    pPos(minPos+1)=[];
                end
                %
                dPos=diff(pPos);
                minDist=min(dPos);
            end
            nPeak=sum(bMin);
            % Now copy peak Heights for Representation. All other frames
            % should be nan, not 0, for Plotting
            Self.Minimum   = nan(Self.bufferSize,1);
            Self.Minimum(pPos) = Self.runAvg(pPos);
            Self.Peaks(pPos) = Self.runAvg(pPos);
        end
        
        function nPeak=findPeaksForce(Self)
            %
            Self.runThresh = nan(Self.bufferSize,1);
            %
            dT=(Self.runPeak - Self.runBase) .* Self.peakThreshCutOff;
            dN=Self.runNoi * Self.noiseThresh;
            dF= ones(Self.bufferSize,1).* Self.noisePx;
            %
            dCut=max([dT dN dF],[],2);
            Self.runThresh = Self.runBase + dCut;
            %
            bPeak = (Self.runAvg == Self.runNei) .* (Self.runAvg > Self.runThresh);
            bPeak(1:Self.firstFrame-1) =0;
            bPeak(Self.lastFrame+1:end)=0;
            %
            pPos=find(bPeak);
            % only consider Peaks in Range
            pPos(pPos < Self.firstFrame)=nan;
            pPos(pPos > Self.lastFrame) =nan;
            % get RR interval
            dPos   =diff(pPos);
            % get min RR interval
            minDist=min(dPos);
            %
            % filter peaks that are closer than runNeiLen.
            % this may only happen if 2 peaks have the same height
            while minDist<Self.runNeiLen
                minPos=find(dPos==minDist,1);
                %
                %
                if (Self.runAvg(pPos(minPos)) > Self.runAvg(pPos(minPos+1)))
                    pPos(minPos)=[];
                else
                    pPos(minPos+1)=[];
                end
                %
                dPos=diff(pPos);
                minDist=min(dPos);
            end
            nPeak=sum(bPeak);
            % Now copy peak Heights for Representation. All other frames
            % should be nan, not 0, for Plotting
            Self.Peaks       = nan(Self.bufferSize,1);
            Self.Peaks(pPos) = Self.runAvg(pPos);
        end
        
        function [mx my] = heart_rate_variability(Self, rr)
           %Calculate the Variance along and perpendicular o a 
           %dioganal of RRn vs. RRn+1 scatter
           %returns 2x2 array
           
           %rr =Self.PeakList.getValues('RR');
            
           xx=rr(2:(end-1));  % ISIi
           yy=rr(3: end); % ISIi+1
           %rotate 45deg

           iTH=45/180*pi;
           COS=cos(iTH);
           SIN=sin(iTH); 
           ixx= xx*COS+yy*SIN; 
           iyy=-xx*SIN+yy*COS;
           
           mx=[mean(ixx), std(ixx)]; % MEAN1 SD1
           my=[mean(iyy), std(iyy)]; % MEAN2 SD2           
           
           
        end
        
        
        
        function analyzeDistancesSeq(Self)
            %
            error('dont use');
            
            Self.initializeAnalysis();
            %
            for i=Self.firstFrame:Self.lastFrame
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
                %[i frameMax frameMin frameNei frameNoi]
                %
                %Self.peakAnalFrame=min([frameMax, frameMin, frameNei, frameNoi]);
                % calculate indices in circular buffers
                %
                ind      = mod(i-1,         Self.bufferSize)+1;
                indAvgF  = mod(frameAvgF-1, Self.bufferSize)+1;
                indAvgS  = mod(frameAvgS-1, Self.bufferSize)+1;
                %
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
                % First fill the running Average Circular buffer for signal
                % smoothing. Use fast smoothing to detect peaks and slow
                % smoothing to define baseline
                %
                Self.runAvgBuffer(indRunAvgF)  = Self.Distance(ind);
                Self.runAvgSBuffer(indRunAvgS) = Self.Distance(ind);
                %
                % the calculate the running Average for N frames
                %
                Self.runAvg(indAvgF)    = nanmean(Self.runAvgBuffer);
                Self.runAvgS(indAvgS)   = nanmean(Self.runAvgSBuffer);
                %
                % Now fill the other buffers with the current Values
                %
                Self.runNeiBuffer(indRunNei) = Self.runAvg(indAvgF);            
                Self.runMinBuffer(indRunMin) = Self.runAvg(indAvgF);
                Self.runMaxBuffer(indRunMax) = Self.runAvg(indAvgF);
                % do not include Peaks in noise calculation, therefor only
                % values above avg (poles closer than avg) are considered,
                % since noise is per definition positive be take abs.
                if (Self.runAvgS(indAvgS) > Self.Distance(indAvgS))
                    Self.runNoiBuffer(indRunNoi) = Self.runAvgS(indAvgS) - Self.Distance(indAvgS);
                else
                    Self.runNoiBuffer(indRunNoi) =nan;
                end
                %
                if i > Self.runMaxLen
                    Self.runMax(frameMax) = max(Self.runMaxBuffer);
                end
                %
                if i > Self.runMinLen
                    Self.runMin(frameMin) = min(Self.runMinBuffer);
                end
                %
                if i > Self.runNeiLen
                    Self.runNei(frameNei) = min(Self.runNeiBuffer);
                end
                %
                if i > Self.runNoiLen
                    Self.runNoi(frameNoi) = nanmean(Self.runNoiBuffer);
                end
            end
            %
        end
        
        
        function nPeak=findPeaksSeq(Self)
            %
            %
            Self.Minimum   = nan(Self.bufferSize,1);
            Self.runThresh = nan(Self.bufferSize,1);
            %
            nPeak=0;
            %
            Self.sWell
            tic
            for i=Self.firstFrame:Self.lastFrame
              %
              if any(isnan([Self.runNoi(i) Self.runNei(i) Self.runMax(i)]))                
                  continue;
              end
              % the first criterion is that a Peak musT be at least xx% of the
              % max peak hight (runMax-runMin) over n Frames
              dT=(Self.runMax(i) - Self.runMin(i)) * Self.peakThreshCutOff;
              % the second criterion is that the peak must be at least N
              % times above the noise level
              dN=Self.runNoi(i) * Self.noiseThresh;
              dF=Self.noisePx;
              %
              dCut=max([dT dN dF]);
              %
              %
              Self.runThresh(i) = Self.runMax(i) - dCut;
              %
              %map=Self.runThresh(i,:) < Self.runMin(i,:);
              % for the rare case where there are two exact. equal minima put
              % Self.lastMin < frmAna-5
              %
              %[Self.runAvg(i) Self.runNei(i) Self.runThresh(i) ]
              if (Self.runAvg(i) == Self.runNei(i) && Self.runAvg(i) <  Self.runThresh(i)    );
                 Self.Minimum(i) = Self.runAvg(i);
                 nPeak=nPeak+1;
              end
            end
            toc
        end
                
        function nPeak=findPeaksOld(Self)
            %
            error('old dont use');
            frameOffset=Self.Frame(1)-1;
            %
            nPeak=0;
            %
            if numel(Self.Force) < Self.filterLength
                return
            end
            %
            %
            if strcmp(Self.filterType, 'median')
                Self.runForce=medfilt1(Self.Force,Self.filterLength);
            else
                %
                flt=fspecial(Self.filterType,[Self.filterLength 1]);
                tmp=filter(flt,1,Self.Force);
                %
                %Any symmetric filter of length N will have a delay of (N-1)/2 samples.
                %We can account for this delay manually.
                fDelay= floor((Self.filterLength-1)/2);
                Self.runForce=vertcat(tmp(1+fDelay:end), Self.Force(end-fDelay+1:end));
            end
            %
            % make sure avgLen is odd
            avgLen = ceil(min([251, numel(Self.runForce)]/2))*2-1;
            %
            [Self.runMin,Self.runMax] = runningExtreme(Self.runForce,avgLen,'both');
            %
            % now find peaks in filtered data
            %
            Self.runThresh=(Self.runMax+Self.runMin)*Self.peakThresh;
            %
            %
            upCross=find(diff(Self.runForce>Self.runThresh)==1);
            dnCross=find(diff(Self.runForce>Self.runThresh)==-1);
            %
            if numel(upCross)==0 || numel(dnCross)==0
                return
            end
            %
            % filter those crossings where only one threshold was crossed
            %
            % search peaks between threshold crossings
            %
            if upCross(1)>dnCross(1)
                %
                % if we start descending remove first down
                %
                dnCross=dnCross(2:end);
            end
            %
            % now filter those where upCross->dnCross is at least 5 frames
            %
            for i=numel(dnCross):-1:1
              if dnCross(i)-upCross(i)<5
                dnCross(i)=[];
                upCross(i)=[];
              end            
            end
            %
            %            
            nCross=numel(dnCross);
            %
            % find first maximum
            %
            %Self.PeakPos =zeros(nCross,1);
            %
            tmpList={};
            %
            for i=1:nCross
                tmpList{i}=OOpeak(Self);
                tmpList{i}.index=i;
                %
                tmpList{i}.Position.crossL=frameOffset+upCross(i);
                tmpList{i}.Position.crossR=frameOffset+dnCross(i);
                %
                tmpList{i}.Force=Self.Force(upCross(i):dnCross(i));
                %
                tmpList{i}.findMax();
                %
            end
            %            
            for i=1:nCross-1
               tmpList{i}.next=tmpList{i+1};
               tmpList{i}.findMin();
            end
            %
            % only those peaks that have min to left and right qualify for peak
            % analysis, otherwise the base can not be calculated
            %
            for i=2:nCross-1
               %
               % analyze(Self, i, base, rAvg, dist, prev, next)
               %
               tmpList{i}.analyze;
               %
               % is the peaks are real transfer to PeakList
               %
               %dist=tmpList{i}.Position.max - tmpList{i-1}.Position.max;
               %
               if ~tmpList{i}.bNoise
                   if Self.lastMinimum > tmpList{i}.Position.minL 
                       %disp(sprintf('new minimum has minL at %d, last minR was %d', tmpList{i}.Position.minL, Self.lastMinimum))
                   else                      
                        Self.PeakList.add(tmpList{i});
                   end
               end               
            end    
            %
            nPeak=Self.PeakList.n;
        end
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
        %
        function data=peakForce(Self)
            nPeak = Self.PeakList.n;
            %
            data=zeros(nPeak,1);
            %
            for i=1:nPeak
               data(i)=Self.PeakListget(i).force; 
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
               data=vertcat(data, Self.PeakListget(i).fitTime); 
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
        function [pos foc bse] = getPeaks(Self)
            %
            pos=find(~isnan(Self.Peaks));
            peak=Self.runAvg(pos);
            %bse=Self.runMax(pos);
            bse=Self.runBase(pos);
            foc=abs(peak-bse);
        end
        
        function [pos foc bse] = getPeaksRange(Self,start,stop)
            peaks=Self.Peaks;
            peaks(1:start-1)=nan;
            peaks(stop+1:end)=nan;
            pos=find(~isnan(peaks));
            %
            peak=Self.runAvg(pos);
            %bse=Self.runMax(pos);
            bse=Self.runBase(pos);
            foc=abs(peak-bse);
        end
        
        function [pos foc bse] = getPeaksStimulated(Self)
            %
            peaks=Self.Peaks;
            peaks(~Self.bStim)=nan;            
            pos=find(~isnan(peaks));
            %
            peak=Self.runAvg(pos);
            bse=Self.runBase(pos);
            foc=(peak-bse);
        end
        
        function [pos foc bse] = getPeaksStimulationOn(Self)
            %
            peaks=Self.Peaks;
            peaks(~Self.bStimOn)=nan;            
            pos=find(~isnan(peaks));
            %
            peak=Self.runAvg(pos);
            bse=Self.runBase(pos);
            foc=(peak-bse);
        end
        
        
        
        function [pos foc bse] = getPeaksUnStimulated(Self)
            %
            peaks=Self.Peaks;
            peaks(Self.bStim)=nan;            
            pos  =find(~isnan(peaks));
            %
            peak=Self.runAvg(pos);
            bse =Self.runBase(pos);
            foc =(peak-bse);
        end
        
        function [frqData frcData bseData] = getPeakStats(Self)
            %
            [pos foc bse] = Self.getPeaks();
            
            RR = diff(pos);
            %
            bHarmonic=0;
            %
            if bHarmonic
                frq=Self.framesPerSecond./RR;
            else
                % 20200204:
                % to avoid confusion we show arithmetic mean
                frq=Self.framesPerSecond/mean(RR);
            end
            %
            frqData = [mean(frq) std(frq) min(frq) max(frq) numel(frq)];
            frcData = [mean(foc) std(foc) min(foc) max(foc) numel(foc)];
            bseData = [mean(bse) std(bse) min(bse) max(bse) numel(bse)];
            %
        end
        %
        function [frq frc bse] = getPeakMeans(Self)
            [frqData frcData bseData]= Self.getPeakStats();
            frq=frqData(1);
            frc=frcData(1);
            bse=bseData(1);
        end
        %
        %
        function f=curTime(Self)
            f=Self.time(Self.curFrame);
        end
        %
        function f=time(Self, nFrame)
            ind=mod(nFrame-1, Self.hParent.bufferSize)+1;
            f=Self.Time(ind);
        end
        
        function updatePeaks(Self,data)
            Self.Minimum=data;
        end
              
        function updateTime(Self,data)
            Self.Time=data;
        end
        
        function updateFrame(Self,data)
            Self.Frame=data;
        end
        
        function updateDistance(Self,data)
            Self.Distance=data;            
        end
        
        
        function updateAvgFast(Self,data)
            Self.runAvg=data;
        end
        
        function updateAvgSlow(Self,data)
            Self.runAvgS=data;
        end
        
        
        function updateRunMin(Self,data)
            Self.runMin=data;
        end
        
        function updateRunNoi(Self,data)
            Self.runNoi=data;
        end
        
        function updateRunNei(Self,data)
            Self.runNei=data;
        end
        
        function updateRunMax(Self,data)
            Self.runMax=data;
        end
        
        function updateRunThresh(Self,data)
            Self.runThresh=data;
        end
        
        function fName=writeDistances(Self, fileRoot);
            %
            fName = [fileRoot '.' Self.name];
            fh=fopen(fName, 'w');            
            fps=Self.hParent.framesPerSecond;
            %fprintf('write frames %d to %d, have %d\n', 1, Self.curFrame, numel(Self.Distance) )
            for i=1:Self.curFrame
                fprintf(fh, '%6.2f %6.2f\r\n', i/fps, Self.Distance(i));
            end
            fclose(fh);
            Self.distFile=fName;
        end
        %       
        
        %
        function fName=writePeaks(Self, fileRoot);
            fName = [fileRoot '.peak.' Self.name];
            fh=fopen(fName, 'w');
            %
            fps=Self.hParent.framesPerSecond;
            %last peak
            peakL=Self.PeakList.get(1);
            for i=2:Self.PeakList.n                
                peak=Self.PeakList.get(i);
                pos  = peak.Position.max;
                time = peak.timepoint/fps;
                force= peak.force;
                RR   = (peak.timepoint-peakL.timepoint)/fps;
                fprintf(fh, '%8i %6.2f %6.2f %6.2f\r\n', pos, time, force, RR);
                peakL=peak;
            end
            fclose(fh);
            Self.peakFile=fName;
        end
        %
        function readPeaks(Self, inFile)
            Self.peakFile=inFile;
            S = dir(inFile);
            if S.bytes == 0
                sprintf('File %s has only %d bytes, skip\n', inFile, S.bytes)
                return
            end
            fid=fopen(inFile,'r');
            fprintf('Loading %s\n', inFile)
            %
            bBinary=max(fread(fid,100)) > 255;
            fseek(fid, 0,-1);
            %
            data = fscanf(fid,'%f',[4 inf]);
            Self.PeakPos=data(1,:);
            Self.Peak=data(3,:);
            %
            fclose(fid);
        end
        %
        function distance2force(Self)
            %            
           Self.Force = Self.kHooke * (Self.maxDistance([1:end])-Self.Distance);
        end
        %
        function f=minPeakHeight(Self)
            f=Self.hParent.minPeakHeight;            
        end
        %
        function distance2fas(Self)
            %
            %
            % make sure avgLen is odd
            avgLen = ceil(min([251, numel(Self.runForce)]/2))*2-1;
            %
            [Self.runMin,Self.runMax] = runningExtreme(Self.Distance,avgLen,'both');
            %Self.Force=(1-Self.Distance/Self.maxDistance([1 Self.curFrame]))*100;
            Self.Force=(1-Self.Distance./Self.runMax)*100;
            %            
        end
        
        %
        function readDistances(Self, distFile)
            %
            Self.distFile=distFile;
            fid=fopen(distFile,'r');
            %
            bBinary=max(fread(fid,100)) > 255;
            fseek(fid, 0,-1);
            %
            if bBinary
                %assume FMI Data
                data = fread(fid,inf,'uint16');
            else
                data = fscanf(fid,'%f',[2 inf]);
                Self.Time=data(1,:)';
                Self.Distance=data(2,:)';
                %
            end
            fclose(fid);
            Self.hParent.curFrame=numel(Self.Distance);
        end
        %
        %        
    end   
end

function Y=runningAvg(X,N)
   flt=ones(N,1);
   fDelay= floor((N-1)/2);
   %fixSize
   T=vertcat(X, nan(fDelay,1));
   % take index to distinguish between NaN and Zero
   I=~isnan(T);
   % turn NaN to 0, otherwise the filter command can not omit nan and
   % will return streches of NaN 
   T(isnan(T))=0;  
   runSum=filter(flt,1,T);
   runInd=filter(flt,1,I);   
   %
   Y=runSum(fDelay+1:end)./runInd(fDelay+1:end);
end


 
function Y=runningAvg_Old(X,N)
   flt=fspecial('average',[N 1]);
   tmp=filter(flt,1,X);            
   %
   %Any symmetric filter of length N will have a delay of (N-1)/2 samples.
   %We can account for this delay manually.
   fDelay= floor((N-1)/2);
   Y=vertcat(tmp(1+fDelay:end), X(end-fDelay+1:end));
end
        
function Y = runningMin(X,N)
    %
    % Correcting X size
    fixsize = 0;
    addel = 0;
    if mod(size(X,1),N) ~= 0
        fixsize = 1;
        addel = N-mod(size(X,1),N);
		f = [X; Inf*ones([addel size(X,2)])];
    else
        f = X;
    end    
    lf = size(f,1); % # of elements in adjusted matrix
    lx = size(X,1); % # of elements in original matrix
    clear X
    % Declaring aux. mat.
    g = f;
    h = g;
    % Filling g & h (aux. mat.)
    ig = (1:N:size(f,1)).'; % First element of each window
    ih = ig + N - 1;    % Last element of each window
    %
    for i = 2 : N
       igold = ig;
       ihold = ih;
       ig = ig + 1;
       ih = ih - 1;
       g(ig,:) = min(f(ig,:),g(igold,:));
       h(ih,:) = min(f(ih,:),h(ihold,:));
    end        
    clear f
    if fixsize % If we had to pad the data
       if addel > (N-1)/2 % If the padding is more than half a zone
                ig =  (N : 1 : lf - addel + floor((N-1)/2)).' ;
                ih = ( 1 : 1 : lf-N+1 - addel + floor((N-1)/2)).';
            	Y = [ g(1+ceil((N-1)/2):N-1,:);  min(g(ig,:), h(ih,:)) ];		
        else
                ig = ( N : 1 : lf ).';
                ih = ( 1 : 1 : lf-N+1 ).';
                Y = [ g(1+ceil((N-1)/2):N-1,:);  min(g(ig,:), h(ih,:));  h(lf-N+2:lf-N+1+floor((N-1)/2)-addel,:) ];
        end
    else % not fixsize (addel=0, lf=lx)
        ig = ( N : 1 : lx ).';
        ih = ( 1 : 1 : lx-N+1 ).';
        Y = [  g(N-ceil((N-1)/2):N-1,:); min( g(ig,:), h(ih,:) );  h(lx-N+2:lx-N+1+floor((N-1)/2),:) ];
    end
end
        
function Y = runningMax(X,N)
    %
    % Correcting X size
    fixsize = 0;
    addel = 0;
    if mod(size(X,1),N) ~= 0
        fixsize = 1;
        addel = N-mod(size(X,1),N);
		f = [X; -Inf*ones([addel size(X,2)])];
    else
        f = X;
    end    
    lf = size(f,1); % # of elements in adjusted matrix
    lx = size(X,1); % # of elements in original matrix
    clear X
    % Declaring aux. mat.
    g = f;
    h = g;
    % Filling g & h (aux. mat.)
    ig = (1:N:size(f,1)).'; % First element of each window
    ih = ig + N - 1;    % Last element of each window
    for i = 2 : N
       igold = ig;
       ihold = ih;
       ig = ig + 1;
       ih = ih - 1;
       g(ig,:) = max(f(ig,:),g(igold,:));
       h(ih,:) = max(f(ih,:),h(ihold,:));
    end
    clear f
    if fixsize % If we had to pad the data
       if addel > (N-1)/2 % If the padding is more than half a zone
                ig =  (N : 1 : lf - addel + floor((N-1)/2)).' ;
                ih = ( 1 : 1 : lf-N+1 - addel + floor((N-1)/2)).';
            	Y = [ g(1+ceil((N-1)/2):N-1,:);  max(g(ig,:), h(ih,:)) ];		
        else
                ig = ( N : 1 : lf ).';
                ih = ( 1 : 1 : lf-N+1 ).';
                Y = [ g(1+ceil((N-1)/2):N-1,:);  max(g(ig,:), h(ih,:));  h(lf-N+2:lf-N+1+floor((N-1)/2)-addel,:) ];
        end
    else % not fixsize (addel=0, lf=lx)
        ig = ( N : 1 : lx ).';
        ih = ( 1 : 1 : lx-N+1 ).';
        Y = [  g(N-ceil((N-1)/2):N-1,:); min( g(ig,:), h(ih,:) );  h(lx-N+2:lx-N+1+floor((N-1)/2),:) ];
    end    
end
        