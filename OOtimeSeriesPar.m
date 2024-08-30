classdef OOtimeSeriesPar < OOclass
    %
    properties
        %
        maxFreq           =  3;         %maxFreq in Hz
        peakThreshCutOff  = 0.6;
        fNoisePx          = 0.1;       % noise in Pixel Deviation        
        fNoiseThresh      = 3;         % Factor of how many times the peak must superate the noise level
        % set true to distinguished between stimulated and unstimulated
        % peaks
        bStimulated=false;
        %
        Time=[]
        Frame=[]        
        %
        waypoint=[];
        %
        bufferSize=90000;
        % Parameter for peak filtering !
        %noiseRel          = 0.01;      % noise as percentage of signal
        %
        iRunAvgLen=3;
        iRunAvgSLen=21;
        runNeiLen=0;
        runNoiLen=11;
        %
        % Filter Legth depends of whether Distances or Forcs are 
        % analyzed. In distances baseline = maximum, in forces
        % baseline=minimum
        runMinLen=0;
        runMaxLen=0;
        runBaseLen=0;    %length of baseline filter
        runPeakLen=0;    %length of Peak Filter.
        %
        %
        peakFitType='sine';
        %
        minPeaks=3;
        minForce=0.0015;     %min 0.2% Contraction ~ 1pix
        minFreq=0.1;         %
        peakBufferSize=21;   %determines maxFreq
        slowBufferSize=301;
        fastBufferSize=15;
        %
        %
        noise=0.1;
        minPeakHeight=0.06;
        %
        curFrameAnal=0;
        curFrame=1;
        curTime=0
        firstFrame_=1;
        lastFrame_=1;
        maxFrame_=1;
        %
        bRawFilter=true;
        minDist = 10;         %Distance Range, Raw Distance outside are ignored
        maxDist = 250;
        maxVel  =  30;        % maximum distance between two neighboring frames
        maxAcc  =  20;
        %
        kHooke=1;          %Hooke's spring constant
        %
        filterType='average';
        fitWindow=9;
        filterLength=3;
        %
        %frameRate=50.0;
        dFramesPerSecond=50.0;
        pixel_per_mm=1;
        mN_per_mm = 1.5;   %default value for TM5MED as measured
        equi_dist_mm=3.9;  %nominal pole equilibrium distance
        %
        %cmap=vertcat(colormap(autumn(32)), flipud(colormap(summer(32))));
        scaleFrq=[0.2 0.6]; %deflection in percent
        scaleFrc=[0.003 0.05];
        %
        
    end
    
    methods
        %
        function Self = OOtimeSeriesPar()
            Self.stateVars=unique({Self.stateVars{:},...
                'maxFreq', 'peakThreshCutOff', 'fNoisePx','fNoiseThresh'});
            
            
        end
        %
        function n = maxPeakWidth(Self)
            %return maximun peak width in frames
            n = Self.neighborLength();
            
        end
        
        function val = maxFrequency(Self, val)
           %
           if exist('val', 'var')
               Self.maxFreq=val;                    
            end
            n=oddify(Self.framesPerSecond/Self.maxFreq);
            Self.neighborLength(n);
            val=Self.maxFreq;            
        end       
        
        
        function val = frameRate(Self, val)
            if exist('val','var')
                Self.framesPerSecond(val);
            end
            val=Self.dFramesPerSecond;            
        end
        
        function val=framesPerSecond(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.dFramesPerSecond=val;
                else
                    error('Value to framesPerSecond must be numeric, not %s', class(val));
                end
            end
            val=Self.dFramesPerSecond;            
        end
        
        function val=runAvgLen(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.iRunAvgLen=val;
                else
                    error('Value to runAvgLen must be numeric, not %s', class(val));
                end
            end
            val=Self.iRunAvgLen;            
        end
        
        function val=runAvgSLen(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.iRunAvgSLen=val;
                else
                    error('Value to runAvgLen must be numeric, not %s', class(val));
                end
            end
            val=Self.iRunAvgSLen;            
        end
        
        function val=noiseThresh(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.fNoiseThresh=val;
                else
                    error('Value to noiseThresh must be numeric, not %s', class(val));
                end
            end
            val=Self.fNoiseThresh;            
        end
        
        function val=noisePx(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.fNoisePx=val;
                else
                    error('Value to noisePx must be numeric, not %s', class(val));
                end
            end
            val=Self.fNoisePx;            
        end
        
        function copyParameter(Self, tgt)
            %
            tgt.peakThresh( Self.peakThresh);
            tgt.noisePx(    Self.noisePx);  
            tgt.noiseThresh(Self.noiseThresh);    
            tgt.firstFrame( Self.firstFrame);    
            tgt.lastFrame(  Self.lastFrame);
            tgt.runAvgLen(  Self.runAvgLen);
            tgt.runNeiLen   = Self.runNeiLen;
            tgt.runNoiLen   = Self.runNoiLen;
            tgt.runMaxLen   = Self.runMaxLen;
            tgt.runMinLen   = Self.runMinLen;
            tgt.runBaseLen  = Self.runBaseLen;
            tgt.runPeakLen  = Self.runPeakLen;
            
        end
        
        
        function n = neighborLength(Self, n)
            %
            if exist('n', 'var')
               Self.runNeiLen =n;                    
            end
            %
            n=Self.runNeiLen;
            Self.runMaxLen =Self.odd( min(Self.bufferSize/2, n*7 ) );
            Self.runMinLen =Self.odd( min(Self.bufferSize/2, n*11) );
            Self.runBaseLen=Self.odd( min(Self.bufferSize/2, n*7 ) );
            Self.runPeakLen=Self.odd( min(Self.bufferSize/2, n*11) );            
            Self.runNoiLen =Self.odd( min(Self.bufferSize/2, n*5 ) );
            %            
        end
        
        function n=nData(Self)
            n=numel(Self.Time);
        end
        
        function f=peakThresh(Self, val)
            if exist('val','var')
                if isa(val,'numeric')                    
                    Self.peakThreshCutOff=val;
                else
                    error('Value to peakThresh must be numeric, not %s', class(val));
                end
            end
            f=Self.peakThreshCutOff;            
        end
        %        
        function val=firstFrame(Self, val)
            if exist('val','var')
                if (val > Self.lastFrame)
                  val=Self.lastFrame-21;
                end            
                if (val <1)
                  val=1;
                end
                Self.firstFrame_=val;
            else
                val=Self.firstFrame_;
            end
        end
        
        function val=lastFrame(Self, val)
            if exist('val','var')
                if (val > Self.bufferSize)
                    val = Self.bufferSize;
                end            
                if (val < Self.firstFrame)
                    val = Self.firstFrame+21;
                end
                Self.lastFrame_=val;
            else
                val=Self.lastFrame_;
            end
        end
                
        function arr=range(Self)
            arr=[Self.firstFrame_ Self.lastFrame_];
        end        
    end
end