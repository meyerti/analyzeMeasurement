classdef OOpeak < handle
    %
    properties
        
        % Position in Well Struct
        % if the OOwell is constructed for an area not starting with frame 1
        % then the Position and the Frame# will differ
        %
        Position =struct('max',nan,'minL',nan,'minR',nan,'start',nan,'stop',nan, 'crossL',nan,'crossR',nan);
        Frame    =struct('max',nan,'minL',nan,'minR',nan,'start',nan,'stop',nan, 'crossL',nan,'crossR',nan);
        Value    =struct('max',nan,'minL',nan,'minR',nan,'start',nan,'stop',nan, 'crossL',nan,'crossR',nan);
        %
        Asc      = struct('start',nan,'stop',nan,'slope',nan,'intersect',nan);
        Desc     = struct('start',nan,'stop',nan,'slope',nan,'intersect',nan);
        %
        % Handles for Plot Options
        hMax
        hFit
        hAsc
        hDesc
        %
        %
        frame
        max     =nan;
        base    =nan;
        height  =nan;
        width   = nan;
        maxWidth_ms=900;    % depends of framesPerSeconds, should be set
        fps = 30;
        thresh  = nan;
        RR=nan;
        %
        bNoise=0;
        bStim=0;
        bStimOn=0;
        %
        bInverted=0;
        strech=1;
        shift=0.0
        %
        hParent=0;
        index=0;
        next=0;
        
        %
        start   %index
        stop
        %
        tstart;
        t1;
        t2;
        time=0;
        t3;
        t4;
        tstop;
        
        force=0;
        %
        %Force=[];     %forces between crossL and crossR
        Time      =[];
        Dist  =[];  %all Dists in peak
        Trace     =[];
        Norm      =[];  %all distances in peak
        %
        fitTrace =[];  % fit data
        fitTime  =[];  % x-pos matching fit data
        fitWeight =[];
        %
        fitPara=[];   %contains [p S mu]=polyfit(xData, yData,n)
        fitParaAsc
        fitParaDesc
        %
        fitType='sine';
        %
        min_thresh=0.2;   %beginn des Peaks xx% von peak ueber baselina
        max_thresh=0.8;
        %
        threshMax;
        threshMin;
    end
    
    methods
        function Self = OOpeak(hParent)
            Self.hParent=hParent;
            %
        end
        
        function nFrame=maxWidth(Self)
            nFrame=oddify(Self.maxWidth_ms * Self.fps / 1000);
        end
        
        function destroy(Self)
            %
            if ~ (Self.hMax==0)
                delete(Self.hMax);
            end
            if ~ (Self.hFit==0)
                delete(Self.hFit);
            end
            if ~ (Self.hAsc==0)
                delete(Self.hAsc);
            end
            if ~ (Self.hDesc==0)
                delete(Self.hDesc);
            end
        end
        %
        function f=framesPerSecond(Self)
            f=Self.hParent.framesPerSecond;
        end
        %
        function f=minPeakHeight(Self)
            f=Self.hParent.runThresh(Self.Position.max);
        end
        
        % Fit Asc, peak, and Desc as continuous, piecewise function
        %
        
        function bOk = timepoints(Self, i, base, rAvg)
            %
            bOk=0;
            % check if close to start/end od race
            Self.time   = i;
            Self.max    = rAvg(i);
            Self.base   = base;
            %
            Self.frame        = i;
            %
            halfWidth=floor(Self.maxWidth()/2);
            %
            Self.start  = max(1, i-halfWidth);
            Self.stop   = min(numel(rAvg), i+halfWidth);
            %
            if min(diff([Self.start,i,Self.stop])) < 5
                fprintf('OOpeak.analyze: peak too close to edge at frame %d\n', i);
                return
            end
            %
            height    = rAvg(i)-base;
            %
            distL = flipud( rAvg(Self.start:i-1));
            distR =         rAvg(i+1 : Self.stop);
            %distL = flipud( norm(1:halfWidth));
            %distR =         norm(halfWidth+1:end);
            
            if (height < 0)
                Self.bInverted=1;
                distL  =  (base - distL) / abs(height);
                distR  =  (base - distR) / abs(height);
            else
                Self.bInverted=0;
                distL  =  (distL - base) /   height;
                distR  =  (distR - base) /   height;
            end
            %
            % first define 80% timepoints around peak
            %
            Self.t2 = i - intersect(distL, Self.max_thresh);
            Self.t3 = i + intersect(distR, Self.max_thresh);
            %
            %then find 20% timepoints around base...
            %migth be obfuscated b double-peaks or shoulders
            %
            [minL, posL] = min(distL);
            Self.start = i - posL;
            if ( minL > Self.min_thresh)
                %peak does not start from baseline, maybe double peak
                Self.t1 = Self.start;                
            else
                Self.t1    = i - intersect(distL, Self.min_thresh);                
            end
            %
            %
            [minR, posR] = min(distR);
            Self.stop = i + posR;
            if ( minR > Self.min_thresh)
                %peak does not return to baseline, maybe double peak
                Self.t4   = Self.stop;                
            else
                Self.t4   = i + intersect(distR, Self.min_thresh);                
            end
            
            %
            % Do some Tests
            %
            if ( Self.start < 1 )
                fprintf('OOpeak::timepoints peak start %d too close to trace\n', Self.start);
                Self.bNoise=1;
            elseif (Self.stop > numel(rAvg))
                fprintf('OOpeak::timepoints peak stop %d too close to trace end\n', Self.stop);
                Self.stop=numel(rAvg);
                Self.bNoise=1;
            elseif ( min(diff([Self.t1 Self.t2 Self.t3 Self.t4]))<2)
                fprintf('OOpeak::timepoints start stop %d %d (%d) %d %d too close\n', Self.t1, Self.t2, i, Self.t3, Self.t4);
                Self.bNoise=1;
            else
                bOk=1;
            end
            %
        end
        
        function bOk = analyze(Self, i, base, rAvg, trace)
            %
            bOk=0;
            %
            %
            if Self.timepoints(i, base, rAvg)==0
                fprintf('OOpeak.analyze: could not determine timepoints for peak at %d\n', i);
                return
            end
            %
            if ( (Self.start < 0) || (Self.stop > numel(rAvg)) || ((Self.stop - Self.start) < 10) )
                Self.bNoise   =1;
                printf('OOpeak.analyze: peak %d too small t1 %d -> t4 %d', i, Self.t1, Self.t4);
                return;
            end
            %
            Self.Trace = trace(Self.start:Self.stop);
            bOk=Self.fit(i, base, trace);
            
            
        end
        
        function bOk=fit(Self, i, base, trace)
            %
            bOk=0;
            %
            nPad=6;
            nGap=3;
            %
            start = Self.t1;
            stop  = Self.t4;
            %
            Y      = base-trace(start:stop);            
            nData  = numel(Y);
            %
            %normalize and add zero padding            
            Y     = padding(Y,nPad,0);
            ny    = numel(Y);
            % ignore area
            xx    =[ (-nPad:-1)-nGap 1:nData nData+nGap+(1:nPad)];
            %
            ww    = ones(ny,1);
            [yMax,n2]=max(Y);
            %       1    2     3     4     5     6       7
            %      t1  tmax   t4    max  base   v_asc  v_desc
            %
            A = [   1   n2   ny-1   yMax   0     2     2];
            F = [   4   1     3     4      0     0     0    %fit Type 0=noFit   
                    0   0     0     0      0     1     1    %lower limit
                  ny/2  ny    ny    yMax*2  yMax 8     8];  %upper limit
            % fit timepoints 
            [A chi nn]=Self.fitSine(xx,Y,ww,A,F');
            % fit slope
            F(1,:) = [   4   4   4  4      0     4     4];    %fit Type 0=noFit   
            F(2,1:3) = A(1:3)-0.5;
            F(3,1:3) = A(1:3)+0.5;              
            %
            [A chi nn] = Self.fitSine(xx,Y,ww,A,F');
            %
            Self.fitPara=A;
            Self.height= A(4);
            % define the middle point of Ascent
            % The inflection Point of the sine function gives slope
            Self.start   = start -1 + A(1);
            Self.time    = start -1 + A(2);   %x_Max
            Self.stop    = start -1 + A(3);
            % Analyze Contraction
            [t1 t4] = myHeart_Fit_inverse(A(4)*Self.min_thresh,  A);
            [t2 t3] = myHeart_Fit_inverse(A(4)*Self.max_thresh,  A);
            dy=A(4) * (Self.max_thresh - Self.min_thresh);
            % Analyze Contraction
            
            Self.Asc.slope =  dy / (t2-t1) ;
            Self.Asc.exp   = A(6);
            Self.t1        = start + t1 -1 ;
            Self.t2        = start + t2 -1 ;
            % Analyze Relaxation
            Self.Desc.slope =  dy / (t4-t3) ;
            Self.Desc.exp   = A(7);
            Self.t3         = start -1 + t3 ;
            Self.t4         = start -1 + t4;
            % line
            xx2=linspace(xx(1), xx(end), 200);
            %fitTime        = linspace(1, numel(Y), 200);
            Self.fitTime   =  start + xx2-1;
            Self.fitTrace  =  base - myHeart_fit_cal(xx2, A);
            Self.max       =  base - Self.height;                    %y_Max
            Self.threshMin =  base - Self.height * Self.min_thresh;
            Self.threshMax =  base - Self.height * Self.max_thresh;            
            %
            Self.Time      = [Self.start:Self.stop+1]';
            %
            bOk=1;
        end
        
        function pos=superposeStim(Self, yData, sData, sThresh)
            %
            offset=20;  %offset from where plot starts
            %
            t1=floor(Self.t1);
            t4=ceil(Self.t4);
            %
            if (sData( floor(Self.t1) ) < sThresh)
                % low at onset
                %find if/when it increases
                pos = find( sData(t1:t4) >= sThresh,1) -1;
            else
                %high at onset
                %find when it started
                pos = find( flip(sData( min(1, t1-offset): t1) ) < sThresh,1);
                % reverse flip
                pos = -pos+1;
            end
            %
            if (pos & t1 + pos -offset > 0)
                %
                range         = t1 + pos -offset : t4 + 5;
                Self.Time     = (1:numel(range))-offset;
                Self.Trace    = yData(range) - Self.base;
                Self.Dist = sData(range);
            else
                pos=nan;
                Self.Time=[];
                Self.Trace   =[];
                Self.Dist=[];
            end
        end
        
        
        function [A chi nn] =fitSine(Self,xx,Y,ww,A,F)
            %
            Self.bNoise=0;
            %normalize fit weights
            E=zeros(numel(A),1); %error
            %
            try
                [chi,nn]=myHeart_fit_vfb3(xx,Y,A,F,E,ww);                
            catch errH
                fprintf(2, 'OOpeak::fitSine: Ain  time: t1 %d t2 %d t3 %d h %f \n', A(1), A(2),A(3),A(4) );                
                Self.bNoise=1;
                disp(errH)
            end            
            %            
            if isnan(chi)
                %[chi nn A]
                fprintf(2, 'OOpeak::fitSine: Failed to Fit: %f %f %f height %f exp %f %f\n', A(1), A(2) ,A(3), A(4), A(6), A(7) );
                Self.bNoise=1;
                figure; plot(xx,Y);hold on; plot(xx,myHeart_fit_cal(xx, A))
            else
                %fprintf('OOpeak::fitSine: chi2= %f after %d steps\n', chi,nn );
            end
            %
        end
        
        % fit sequentially, first Asc and Desc, then Tip
        
        function bOK=fitSeq(Self)
            bOK=1;
            % do linear fit for left and right shoulder
            % for numerical accuracy shift fit to x=0
            % make array wide for more numeric stability in noisy data
            %fprintf('OOpeak::fitSeq: fit for well %s at %d', Self.hParent.sWell, Self.start);
            %fitX =(Self.Asc.start:Self.Asc.stop)' - Self.start +1;
            %fitY = Self.Dist(fitX);
            
            Y=Self.Trace;
            X=Self.Time;
            % first fit Peak
            % Now fit Peak. for defined fitting of 2nd order we
            % need at least 5 Points
            %
            M = Self.Time >= Self.Asc.stop & Self.Time <= Self.Desc.start;
            [p S mu]=polyfit(1:sum(M), Self.Trace(M)',2);
            %
            %offset = max( [0, (5 - (Self.Desc.start - Self.Asc.stop) )/2 ] );
            %
            %fitX = (floor(Self.Asc.stop-offset) : ceil(Self.Desc.start+offset))' - Self.start +1;
            %fitY =  Self.Dist(fitX);
            %[p S mu] = polyfit(fitX, fitY,2);
            %
            % find zero-crossing of root. Since order is 2 there
            % is only one crossing
            % calc values at min/max/saddle points
            %
            tMax=roots(polyder(p))*mu(2)+mu(1);
            %
            Self.fitPara={p S mu};
            %
            Self.fitTime  = Self.Time(M);
            Self.fitTrace = polyval(p, ((1:sum(M))-mu(1))/mu(2));
            %
            fMax          = polyval(p, (tMax-mu(1))/mu(2));%
            % check if value is within range
            if (tMax > Self.Asc.stop && tMax < Self.Desc.start && Self.max*0.8 < fMax < Self.max*1.2 )
                Self.max=fMax;
                Self.height = Self.base-Self.max;
                Self.time   = tMax + Self.start-1;
            end
            %
            minSlope=Self.height/Self.width;
            %
            % FIT ASC
            M = Self.Time >= Self.Asc.start & Self.Time <= Self.Asc.stop;
            fitP=polyfit(1:sum(M), Self.Trace(M)',1);
            %
            %
            if ( fitP(1) > minSlope)
                Self.Asc.slope=fitP(1);
                Self.Asc.start = (Self.threshMin - fitP(2)) / fitP(1) + Self.Asc.start-1;
                Self.Asc.stop  = (Self.threshMax - fitP(2)) / fitP(1) + Self.Asc.start-1;
            else
                fprintf('OOpeak::fitSeq: fit Asc Failed for well %s at %d\n', Self.hParent.sWell, Self.start);
                fprintf('OOpeak::fitSeq: minSlope %f actual slope %f\n', minSlope, -fitP(1));
                Self.Asc.slope = minSlope;
            end
            % fit descent
            M = Self.Time >= Self.Desc.start & Self.Time <= Self.Desc.stop;
            fitP=polyfit(1:sum(M), Self.Trace(M)',1);
            %
            if ( fitP(1) < -minSlope)
                Self.Desc.slope = fitP(1);
                Self.Desc.start = (Self.threshMax - fitP(2))/fitP(1) + Self.Desc.start-1; %t4
                Self.Desc.stop  = (Self.threshMin - fitP(2))/fitP(1) + Self.Desc.start-1; %t3
            else
                fprintf('OOpeak::fitSeq: fit Desc Failed for well %s peak at %d\n', Self.hParent.sWell, Self.start);
                fprintf('OOpeak::fitSeq: minSlope %f actual slope %f\n', minSlope, fitP(1));
                %        slope =         dY           /         dX
                Self.Desc.slope= minSlope ;
            end
        end
        
        function bOK=fitPoly(Self)
            bOK=1;
            T=[Self.Frame.ascStart-5:Self.Frame.descStop+5]';
            Y=dist(T);
            X=[1:numel(T)]';
            breaks=[T(1) Self.Frame.ascStart (Self.Frame.ascStop+Self.Frame.ascStart)/2 Self.Frame.ascStop Self.Frame.descStart (Self.Frame.descStart+Self.Frame.descStop)/2 Self.Frame.descStop T(end)]
            
            ord =[1 3 2  3 2 3 1];
            wgt =[1 1 1 20 1 1 1];
            cprop=2;
            pp=ppfit(T, Y, breaks, ord, cprop,wgt,'v');
            r = abs(Y - ppval(pp, T));
            rr = r.^2;
            RMSE = sqrt(mean(rr));
            bPlot=0;
            if(bPlot)
                figure(); clf;
                xp = linspace(pp.breaks(1), pp.breaks(end), 400);   % x for plotting
                plot(T,Y,'b.', xp, ppval(pp, xp),'r-', pp.breaks,ppval(pp, pp.breaks),'ro');
            end
            Self.fitPara=pp;
            Self.Asc.slope = pp.coefs(3,2);
            Self.Desc.slope = pp.coefs(5,2);
            tMax = roots(polyder(pp.coefs(4,:)));
            Self.time=tMax+breaks(4);
            Self.max = polyval(pp.coefs(4,:), tMax);%
            xp=linspace(pp.breaks(1), pp.breaks(end), 200);
            Self.Time = xp;
            Self.fitTrace= ppval(pp, xp);
        end
        
        function plot(Self, hAxes)
            %
            axes(hAxes);
            Self.hMax  = plot(Self.time, Self.max, 'vb', 'MarkerFaceColor', 'b', 'Tag','PeakMax', 'MarkerSize',10);
            %
            Self.hFit  = plot(Self.fitTime, Self.fitTrace, 'Color','b','linewidth',2);            %
            % Asc and Desc are fitted separately
            Self.hAsc  = plot([Self.t1 Self.t2],  [Self.threshMin Self.threshMax],  'r','linewidth',2);
            Self.hDesc = plot([Self.t3 Self.t4],  [Self.threshMax Self.threshMin],  'r','linewidth',2);
            
        end
        
        function removePlot(Self)
            %
            if (Self.hMax~=0)
                delete(Self.hMax);
                Self.hMax=0;
            end
            if (Self.hFit~=0)
                delete(Self.hFit);
                Self.hFit=0;
            end
            %
            if  (Self.hAsc~=0)
                delete(Self.hAsc);
                Self.hAsc=0;
            end
            if (Self.hDesc ~= 0)
                delete(Self.hDesc);
                Self.hDesc=0;
            end
        end
    end
end


function pp = ppfit(varargin)
% ppfit            Fit a piecewise polynomal, i.e. ppform, to points (x,y)
%                  The points will be approximated by N polynomials, given in
% the pp-form (piecewise polynomial). ex: fnplt(pp); % to plot results
%
% pp = ppfit(x, y, breaks);
% pp = ppfit(x, y, breaks, ord, [], 'v');
% pp = ppfit(x, y, breaks, ord, cprop, fixval);
% pp = ppfit(x, y ,breaks, ord, cprop, fixval, 'p', 'v');
% pp = ppfit(x, y ,breaks, ord, cprop, fixval, 'p', 'v', weight);
%--------------------------------------------------------------------------
% arguments:
%   x        - the x values of which the function is given, size Lx1
%   y        - the function value for the corresponding x, size Lx1
%   breaks   - break sequence (knots), the start and end points for
%              the N polynomials as a vector of length (N+1).
%              Values of x should be within range of breaks:
%              min(breaks) <= x(i) <= max(breaks)
%              A scalar N may be given to set the number of polynomials.
%   ord      - order of each polynomial, a vector of length N or a scalar
%              1 (constant), 2 (linear), 3 (quadratic), 4 (cubic) (default)
%   cprop    - continuity properties, a vector of length (N-1) or N or a
%              scalar. Note that cprop(i) gives continuity at end of piece
%              i, at breaks(i+1).
%                0 - no continuity for breaks(i+1)
%                1 - continuity (default),
%                2 - also continuious first derivate,
%                3 - also continuious second derivate.
%  argument 6 and onward may be in any order, they may be:
%              fixval, numeric and size Kx3, gives fixed values for pp
%                fixval(k,1) is the x-value, must be within range of breaks.
%                fixval(k,2) the y-value (or the value of the derivate), and
%                fixval(k,3) is the type or derivate degree, i.e. 0 for value
%                1 for first derivate, 2 for second derivate.
%                if this variable is omitted no fixed values is assumed
%              weight, numeric and size Lx1
%                If this is given what is minimized is the weighted SSE;
%                i.e.    SSEw = sum( (weight.*error).^2 );
%                where   error = y - ppval(pp, x);
%              'p' for periodic, need cprop(N) > 0 to have any effect
%              'v' for verbose, default display only errors/warnings
%                  include fields 'input' and 'fitProp' in output struct
%--------------------------------------------------------------------------
% ex:  res = ppfit('test');   % special test (demo) examples

%--------------------------------------------------------------------------
% Copyright (c) 2002-2015.  Karl Skretting.  All rights reserved.
% University of Stavanger, TekNat, IDE
% Mail:  karl.skretting@uis.no   Homepage:  http://www.uis.no/~karlsk/
%
% HISTORY:  dd.mm.yyyy
% Ver. 1.0  15.01.2002  KS: function made as poly_inter_pol
% Ver. 1.1  09.05.2008  KS: function still works, some modifications
% Ver. 1.2  01.09.2014  KS: function still works, add a try statement
% Ver. 2.0  27.04.2015  KS: changed name to ppfit, and rewritten parts
% Ver. 2.1  13.05.2015  KS: function works (partly)
% Ver. 2.2  07.09.2015  KS: made function simpler
% Ver. 2.3  21.01.2016  KS: minor updates
% Ver. 2.4  30.08.2016  KS: thisFirstge local function included
% Ver. 2.5  06.12.2016  KS: a minor error corrected
%--------------------------------------------------------------------------


if (nargin == 1) && ischar(varargin{1}) && strcmpi(varargin{1}, 'test')
    pp = thisTest();
    return;
end

if nargin < 3
    error([mfilename,': should at least have three input arguments, see help.']);
end

arg = thisArg(varargin{:});   % check and verify input arguments

if arg.verbose >= 1
    disp([mfilename,': ',int2str(arg.L),' points (x,y) should be approximated by ',...
        int2str(arg.N),' polynomials.']);
    disp(['   order is in range ',int2str(min(arg.ord)),' to ',int2str(max(arg.ord)),'.']);
    t = ['   continuity properties is in range ',int2str(min(arg.cprop(1:(arg.N-1)))),...
        ' to ',int2str(max(arg.cprop(1:(arg.N-1)))),'.'];
    if arg.periodic
        t = [t,' Periodic continuity = ',int2str(arg.cprop(arg.N))];
    end
    disp(t);
    if (size(arg.fixval,1) > 0)
        disp(['   There are ',int2str(size(arg.fixval,1)), ' additional conditions.']);
    end
end

A = thisBuildA(arg.x, arg.breaks, arg.ord);

[B,c] = thisBuildBc(arg.breaks, arg.ord, arg.cprop, arg.fixval, arg.periodic);

if arg.verbose >= 2    % DEBUG
    disp([mfilename,': have made matrices: ']);
    disp(['   A (',int2str(size(A,1)),'x',int2str(size(A,2)),')', ...
        '   B (',int2str(size(B,1)),'x',int2str(size(B,2)),')', ...
        '   c (',int2str(size(c,1)),'x',int2str(size(c,2)),').']);
end

if (numel(arg.weight) == arg.L)
    u = thisLsq(repmat(arg.weight,1,size(A,2)).*A, arg.weight.*arg.y, B, c);
else
    u = thisLsq(A, arg.y, B, c);
end

% now use u to build the pp form
p = max(arg.ord);
N = arg.N;
ci = false(N, p);
for piece = 1:N
    ci(piece,(p - arg.ord(piece) + 1):p) = true;   % used variables
end
coefs = zeros(p,N);   % transposed
coefs(ci') = u;

% pp = ppmak(arg.breaks, coefs', 1);   % curvefit toolbox
pp = mkpp(arg.breaks, coefs', 1);      % polyfun 'toolbox'

if arg.verbose >= 1
    disp(['   Number of parameters in polynomals is ',int2str(size(A,2))]);
    disp(['   Total number of conditions is ',int2str(size(B,1)), ...
        ' giving ',int2str(size(A,2)-size(B,1)),' free variables.']);
    pp.input = arg;
    pp.fitProp = thisPpFitProp(pp);
    disp([mfilename,': Used ',int2str(pp.pieces),' pieces,  final RMSE is ',num2str(pp.fitProp.rmse)]);
end

if (arg.verbose >= 2)   % DEBUG
    pp.A = A;
    pp.B = B;
    pp.c = c;
    pp.ci = ci;
    pp.u = u;
    % may check by
    % uM = lsqlin(pp.A,pp.input.y,[],[],pp.B,pp.c);
end

end

% ----------------------- subfunctions ----------------------
function arg = thisArg(varargin)
% returns struct 'arg' with verified input arguments
% pp = ppfit(x,y,breaks,ord,cprop,fixval);

arg = struct( 'x', [], ... % data x-locations (Lx1)
    'y', [], ... % data y-values (Lx1)
    'L', 0, ...  % number of data points
    'N', 0, ... % number of pieces, polynoms
    'breaks', [], ... %      Breaks (N+1)x1
    'ord', [], ... % Polynomial order, Nx1
    'cprop', [], ... %  Continuity properties, Nx1, last is 0 if not periodic
    'fixval', [], ... % Fixed values, Kx3
    'weight', [], ... % weight, empty or size Lx1
    'periodic', false, ... %    true or false
    'verbose', 0 );  %  verbose level 0, 1 or 2

% Reshape x-data
x = varargin{1};
x = reshape(x,numel(x),1);
% Reshape y-data
y = varargin{2};
y = reshape(y,numel(y),1);

% Check data size
if numel(x) ~= numel(y)
    error([mfilename,': number of elements in x and y is not the same.']);
end

% Treat NaNs in x-data
xnan = find(isnan(x));
if ~isempty(xnan)
    x(xnan) = [];
    y(xnan) = [];
    warning([mfilename,': ignore NaN in x.']);
end

% Treat NaNs in y-data
ynan = find(isnan(y));
if ~isempty(ynan)
    x(ynan) = [];
    y(ynan) = [];
    warning([mfilename,': ignore NaN in y.']);
end

% Check number of data points
L = numel(x);
if L == 0
    error([mfilename,': no elements in x.']);
end

% Sort data
if any(diff(x) < 0)
    [x,isort] = sort(x);
    y = y(isort);
end

% Breaks
if isscalar(varargin{3})
    % Number of pieces
    N = varargin{3};
    if ~isreal(N) || ~isfinite(N) || (N < 1) || (fix(N) < N)
        error([mfilename,': breaks must be a vector or a positive integer.']);
    end
    %  we want (N+1) break points between x(1) and x(end), x is sorted
    %  distribute break points both uniform and random
    % ex: x = (1:0.1:10)'.^2; N = 10;
    L = numel(x);
    idxu = linspace(1, L, N+1);     % uniform indexes
    idxr = rand(1,N+1);             % some random numbers
    idxr = 1+(sort(idxr)-min(idxr))*((L-1)/(max(idxr)-min(idxr)));    % range 1  to L
    % idx = 0.5*idxu + 0.5*idxr;      % a mix between uniform and random
    idx = 0.9*idxu + 0.1*idxr;      % uniform plus a little bit random
    idx_int = floor(idx);           % N+1 elements
    idx_rem = (idx(1:N) - idx_int(1:N));   % the N first, not last element, first is zero
    breaks = [(1-idx_rem).*x(idx_int(1:N))' + idx_rem.*x(idx_int(2:(N+1)))', x(L)];
else
    % Vector of breaks
    breaks = varargin{3};
    N = numel(breaks) - 1;
    breaks = reshape(breaks,N+1,1);
end
% Sort breaks
if any(diff(breaks) < 0)
    breaks = sort(breaks);
end
% Unique breaks
if any(diff(breaks) <= 0)
    breaks = unique(breaks);
    N = numel(breaks)-1;
    disp([mfilename,': ignore duplicate breaks, use ',int2str(N+1),' breaks.']);
end
if isempty(breaks) || (min(breaks) == max(breaks))
    error([mfilename,': At least two unique breaks are required.']);
end

% ord of the polynomials
if (nargin < 4) || isempty(varargin{4})
    ord = 4*ones(N,1);
else
    if numel(varargin{4}) == N
        ord = reshape(floor(varargin{4}),N,1);
    else
        if numel(varargin{4}) > 1
            warning([mfilename,': use only first element of ord (argument 4)']);
        end
        ord = floor(varargin{4}(1))*ones(N,1);
    end
    if any(ord < 1)
        warning([mfilename,': set ord of ',int2str(nnz(ord < 1)),' polynomals to minimal value 1.']);
        ord(ord < 1) = 1;
    end
    if any(ord > 8)
        warning([mfilename,': set ord of ',int2str(nnz(ord > 8)),' polynomals to maximal value 8.']);
        ord(ord > 8) = 8;
    end
end
arg.ord = ord;

% continuity properties at breaks (except first, and perhaps last)
if (nargin < 5) || isempty(varargin{5})
    cprop = ones(N-1,1);
else
    if numel(varargin{5}) == N
        cprop = reshape(floor(varargin{5}),N,1);
    elseif numel(varargin{5}) == (N-1)
        cprop = [reshape(floor(varargin{5}),N-1,1); varargin{5}(end)];
    else
        if numel(varargin{5}) > 1
            warning([mfilename,': use only first element of cprop (argument 5)']);
        end
        cprop = floor(varargin{5}(1))*ones(N,1);
    end
    if any(cprop < 0)
        warning([mfilename,': set ',int2str(nnz(cprop < 0)),' neagtive ''cprop''-values to 0.']);
        cprop(cprop < 0) = 0;
    end
end
arg.cprop = cprop;

% Loop over optional arguments
for k = 6:nargin
    a = varargin{k};
    if ischar(a) && isscalar(a) && lower(a) == 'p'
        % Periodic conditions
        arg.periodic = true;
        if numel(cprop) == (N-1)
            arg.cprop = [cprop; cprop(end)];
        end
    elseif ischar(a) && strcmpi(a, 'v0')   % default
        arg.verbose = 0;
    elseif ischar(a) && (strcmpi(a, 'v') || strcmpi(a, 'v1'))
        arg.verbose = 1;
    elseif ischar(a) && strcmpi(a, 'v2')  % only for DEBUG
        arg.verbose = 2;
    elseif isreal(a) && (size(a,2) == 3)
        % fixval array,
        arg.fixval = a;
    elseif isreal(a) && (size(a,2) == 1) && ((size(a,1) == L) || (size(a,1) == numel(varargin{1})))
        % weight vector,
        if (size(a,1) ~= L)
            if ~isempty(xnan)
                a(xnan) = [];
            end
            if ~isempty(ynan)
                a(ynan) = [];
            end
        end
        if (size(a,1) == L)
            if exist('isort','var')
                arg.weight = a(isort);
                % warning([mfilename,': x and y and weights were sorted the same way to order x increasingly.']);
            else
                arg.weight = a;
            end
        else
            warning([mfilename,': ignore (weight?) argument ',int2str(k),'.']);
        end
    else
        warning([mfilename,': ignore argument ',int2str(k),'.']);
    end
end

% chech fixval
if ~isempty(arg.fixval)
    F = arg.fixval;
    F(:,3) = max( floor(F(:,3)), 0);
    F = sortrows(F(:,[1,3,2]));
    if (F(1,1) < breaks(1)) || (F(end,1) > breaks(end))
        disp([mfilename,': ignore fixval-properties outside breaks range.']);
        F = F( (F(:,1) >= breaks(1)) & (F(:,1) <= breaks(end)), :);
    end
    if (size(F,1) >= 2)  % check for duplicates
        for i = 2:size(F,1)
            if (nnz(F(i,1:2) == F(i-1,1:2)) == 2)
                disp([mfilename,': ignore duplicate fixval-properties.']);
                F(i,:) = [];
            end
        end
    end
    arg.fixval = F(:,[1,3,2]);
end

if ~arg.periodic
    arg.cprop(N) = 0;
end

% Check if data are in expected range
h = diff(breaks);
xlim1 = breaks(1) - 0.01*h(1);
xlim2 = breaks(end) + 0.01*h(end);
if x(1) < xlim1 || x(end) > xlim2
    if arg.periodic
        % Move data inside domain
        P = breaks(end) - breaks(1);
        x = mod(x-breaks(1),P) + breaks(1);
        % Sort
        [x,isort] = sort(x);
        y = y(isort);
        if (size(arg.weight,1) == L)
            arg.weight = arg.weight(isort);
        end
    else
        warning([mfilename,': Some data points are outside the domain given by breaks.']);
    end
end

arg.x = x;
arg.y = y;
arg.L = numel(x);
arg.breaks = breaks;
arg.N = N;

end


function u = thisLsq(A,x,B,c)
% Solve   min ||Au - x||_2^2     s.t.  Bu = c
%
% using lsqlin is not quite as robust as wanted (and slower):
% tic; uM = lsqlin(A,x,[],[],B,c); toc
% disp(['Difference between two methods, ||uM - u|| = ',num2str(norm(uM-u))]);

% we supress:  'Warning: Rank deficient, rank =    '
warning('off', 'all');
if numel(B)
    %     if issparse(B)
    %         tol = 1000*eps;
    %         [Q,R] = qr(B');
    %         R = abs(R);
    %         jj = all(R < R(1)*tol, 2);
    %         Z = Q(:,jj);
    %     else
    %         Z = null(B);   % B*Z = 0
    %     end
    Z = null(full(B));   % B*Z = 0
    
    % solve LS system
    if nnz(c)
        u0 = B\c;      % underdetermined system
        % rank test takes time (but avoid warnings)
        % Az = A*Z;
        % if rank(Az) < (size(A,2) - size(B,1))
        %     u = u0;        else
        v = (A*Z)\(x-A*u0);  % overdetermined system
        u = u0 + Z*v;
    else
        u = Z*((A*Z)\x);
    end
else % B is empty;    Solve   min ||Au - x||_2^2
    u = A\x;
end

warning('on', 'all');

end


function A = thisBuildA(x, breaks, ord)
% make matrix A to be used in LS, i.e. A in  min ||Au - y||_2^2
% where u are a vector of the (non-zero) elements in the coefs in pp-form

L = length(x);
N = numel(breaks)-1;    % number of pieces (polynoms)
p = max(ord);

if (N < 4)
    % make full matrix A
    A = zeros(L, N*p);
    for i=1:N
        idx = ((x >= breaks(i)) & (x < breaks(i+1)));
        if (i == N) && (x(L) >= breaks(N+1))
            idx = (idx | (x == breaks(N+1)));
        end
        if nnz(idx)
            t = x(idx) - breaks(i);
            col = ((i-1)*p+1):(i*p);
            A(idx,col(end)) = ones(numel(t),1);
            for cc = fliplr(col(1:(end-1)))
                % try
                A(idx,cc) = A(idx,cc+1).*t;
                % catch ME
                %     disp(ME.message);
                %     disp([i,size(x),size(breaks),-1,size(A),size(idx),cc,cc+1,size(t)]);
                %     disp(' ');
                % end
            end
        end
    end
else
    % make sparse matrix A
    I = thisFirstge(x, breaks);   % (N+1) breaks
    if (I(end) <= L) && (x(I(end)) == breaks(end))
        % include this element in last polynom even if it strictly
        % belongs to next polynom
        I(end) = I(end)+1;
    end
    % build A matrix, as used in    min || A*u - y ||_2^2
    % where  u = reshape(coefs', M, 1);
    Ai = zeros(L*p,1);
    Aj = zeros(L*p,1);
    As = zeros(L*p,1);
    for i=1:N
        idx = I(i):(I(i+1)-1);  % indexes in x for this polynom, or rows in A
        ni = numel(idx);
        if ni
            % if (ni < ord(i))
            %     disp([mfilename,' (521) Warning: ',...
            %         'Only ',int2str(ni),' points for polynom ',int2str(i),...
            %         ' of order ',int2str(ord(i)),' may cause problems.']);
            % end
            t = x(idx) - breaks(i);
            col = ((i-1)*p+1):(i*p);
            ii = (p*(I(i)-1)+1):(p*(I(i+1)-1));
            Ai(ii) = repmat(idx',p,1);
            Aj(ii) = reshape(repmat(col,ni,1),p*ni,1);
            tt = ones(ni,1);
            ii = (p*(I(i+1)-1)+1) - (ni:(-1):1);
            As(ii) = tt;
            for j=2:p
                tt = tt.*t;
                ii = ii - ni;
                As(ii) = tt;
            end
        end
    end
    A = sparse(Ai,Aj,As);
end

if (sum(ord) < N*p)     % some of the columns of A are not used
    ci = false(N, p);   % coefficient indicies
    for i = 1:N
        ci(i,(p-ord(i)+1):p) = true;   % used variables
    end
    A = A(:,reshape(ci',1,N*p));
end

end    % thisBuildA


function [B,c] = thisBuildBc(breaks, ord, cprop, fixval, periodic)
% make matrix B and vector c to be used as conditions in LS, i.e. Bu = c.
% where u are a vector of the (non-zero) elements in the coefs in pp-form

K = sum(cprop) + size(fixval,1);  % Number of continuity and fixval restrictions
if K
    N = numel(breaks)-1;    % number of pieces (polynoms)
    p = max(ord);
    pDesc = (p-1):(-1):0;
    facTab = [1 1 2 6 24 120 720 5040 40320 362880 3628800];
    if N < 4
        % make full matrix B
        B = zeros(K, p*N);
    else
        % make sparse matrix B
        B = sparse([],[],[], K, p*N, K*2*p);
    end
    c = zeros(K,1);
    
    k = 0;
    col = 1:(2*p);
    for i = 1:(N-1)
        % continuity at the end of polynom i,    breaks(i+1)
        t = breaks(i+1) - breaks(i);
        ft = (t*ones(1,p)).^pDesc;
        for count = 1:cprop(i)
            k = k+1;
            coeff = [ft, zeros(1,p)];
            coeff(2*p+1-count) = -facTab(count);
            B(k,col) = coeff;
            ft = [ft(2:end),0].*pDesc;
        end
        col = col + p;
    end
    if periodic
        col((p+1):(p+p)) = 1:p;
        t = breaks(N+1) - breaks(N);
        ft = (t*ones(1,p)).^pDesc;
        for count = 1:cprop(N)
            k = k+1;
            coeff = [ft, zeros(1,p)];
            coeff(2*p+1-count) = -facTab(count);
            B(k,col) = coeff;
            ft = [ft(2:end),0].*pDesc;
        end
    end
    
    % and now fixval
    for i = 1:size(fixval,1)
        k = k + 1;
        c(k) = fixval(i,2);
        n = find(breaks > fixval(i,1), 1); % should give: n >= 2
        if isempty(n) % may happen if fixval(i,1) == breaks(end)
            n = N;
        else
            n = n-1;   % n is number for the polynom
        end
        col = ((n-1)*p + 1):(n*p);
        t = fixval(i,1) - breaks(n);
        ft = (t*ones(1,p)).^pDesc;
        for count = 1:fixval(i,3)
            ft = [ft(2:end),0].*pDesc;
        end
        B(k,col) = ft;
    end
    
    if (sum(ord) < N*p)
        % some of the columns of B are not used
        coefs = false(N, p);
        for i = 1:N
            coefs(i,(p-ord(i)+1):p) = true;   % used variables
        end
        B = B(:,reshape(coefs',1,N*p));
    end
else
    B = []; c = [];
end

end    % thisBuildBc


function s = thisPpFitProp(pp)
% makes a struct telling how well this pp fits points in x and y
N = pp.pieces;
x = pp.input.x;
yhat = ppval(pp, x);
sqErr = (pp.input.y - yhat).^2;
nP = zeros(N, 1);     % number of points approximated by each polynom
sseP = zeros(N, 1);   % sum squared error for each polynom
n = 1;
for i = 1:numel(x);
    while (n < N) && (x(i) >= pp.breaks(n+1))
        n = n + 1;
    end
    nP(n) = nP(n) + 1;
    sseP(n) = sseP(n) + sqErr(i);
end
s = struct('n',nP, 'sse',sseP, 'rmse',sqrt(sum(sseP)/sum(nP)));
end

function I = thisFirstge(x,b)
% thisFirstge   Find first in x >= b(i) for each element of b
%               Both x and b should be sorted!
% It is like: I(j) = find(x >= b(j),1);  and if empty I(j) = numel(x)+1
%
% ex:  I = thisFirstge(x,b);
%      x = sort(rand(1000,1)); b = [0; sort(rand(5,1)); 1];
%      tic; I = thisFirstge(x,b); toc;

% in ..\srp\  this function is in its own m-file

I = zeros(size(b));
if (numel(b) < 20)
    for j = 1:numel(b)
        i = find(x >= b(j),1);
        if isempty(i);
            I(j) = numel(x)+1;
        else
            I(j) = i;
        end
    end
else
    i = 1; j = 1;
    while true
        if (x(i) >= b(j))
            I(j) = i;
            j = j + 1;
            if (j > numel(b)); break; end;
        else
            i = i + 1;
            if (i > numel(x)); break; end;
        end
    end
    if (j <= numel(b))
        I(j:end) = i;
    end
end
end











function xx=myHeart_fit_cal(tt,A)
    % using:
    %  yy = myHeart_fit_cal(tt, A);
    %  A=[t0, t1, t2, Amp, Offset];
    % t1 is on set time
    % t2 is offset time

    for ii=1:numel(tt)
        if tt(ii)<A(1)
            xx(ii)=A(5);
        elseif tt(ii)<A(2)
            dt=A(2)-A(1);
            %xx(ii)=A(4)* abs(sin(pi*(A(1)-tt(ii))/2/A(2))).^A(6) +A(5);    %xx(ii)=A(4)*sin((tt(ii)-A(1))/A(2)*pi-pi/2)/2+A(4)/2;
            xx(ii)=A(4)* sin(pi*(tt(ii)-A(1))/2/dt).^A(6) + A(5);    %xx(ii)=A(4)*sin((tt(ii)-A(1))/A(2)*pi-pi/2)/2+A(4)/2;
        elseif tt(ii)<A(3)
            dt=A(3)-A(2);
            xx(ii)=A(4)* cos(pi*(tt(ii)-A(2))/2/dt).^A(7) +A(5); %xx(ii)=A(4)*sin((tt(ii)-A(1)-A(2))/A(3)*pi+pi/2)/2+A(4)/2;
        else
            xx(ii)=A(5);
        end
    end
end

function [t1 t2]=myHeart_Fit_inverse(y,A)
    t1=0;
    t2=0;
    if (y < A(5)) || (y > A(4) + A(5))
        return;
    end
    dt  = A(2)-A(1);
    pt1 = asin(exp(log(y/A(4))/A(6)));

    t1 = A(1)+ (pt1 *dt *2 / pi);

    dt  = A(3)-A(2);
    pt2 = acos(exp(log(y/A(4))/A(7)));

    t2 = A(2)+ (pt2 *dt *2 / pi);
end

function xx=myHeart_fit_cal_dydx(tt,A)
% using:
% calculates the first derivative
%  yy = myHeart_fit_cal(tt, A);
%  A=[t0, t1, t2, Amp, Offset];
% t1 is on set time
% t2 is offset time
%
for ii=1:numel(tt)
    if tt(ii)<A(1)
        xx(ii)=0;
    elseif tt(ii)<A(2)
        dt=A(2)-A(1);
        xx(ii)= A(6)* A(4) * pi /2 / A(2) * sin( pi*( tt(ii) - A(1) ) /2/dt).^(A(6)-1).* cos(pi*(A(1)-tt(ii))/2/dt);
        %xx(ii)= A(6)* A(4) * pi /2 / A(2) * sin( pi*( tt(ii) - A(1) ) /2/A(2)).^(A(6)-1).* cos(pi*(A(1)-tt(ii))/2/A(2));
    elseif tt(ii)<A(3)
        dt=A(3)-A(2);
        %xx(ii)= - A(7)* A(4) * pi / 2 / A(3) * cos(pi*(A(1)+A(2)-tt(ii))/2/A(3)) .* sin(pi*(tt(ii)-A(1)-A(2))/2/A(3)).^(A(7)-1);
        xx(ii)= - A(7)* A(4) * pi / 2 / dt * cos(pi*(A(2)-tt(ii))/2/dt) .* sin(pi*(tt(ii)-A(2))/2/dt).^(A(7)-1);
    else
        xx(ii)=0;
    end
end
end
