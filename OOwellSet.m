classdef OOwellSet < OOtimeSeriesPar & OOList
    properties
      nRow=0
      nCol=0
      %
      hSelect=0;       %figure handle
      hAxesSelect=0;   %axis handle
      %      
    end
    
    methods
        %
        function Self = OOwellSet()
            Self.stateVars=unique({Self.stateVars{:},'nRow','nCol' });           
        end
        
        function updateNames(Self)
           if Self.nRow*Self.nCol > Self.nWell
               error('OOwellSet:updateNames: failed');
           end
           iWell=0;
           for iRow=1:Self.nRow
                sRow=num2abc(iRow);
                for iCol=1:Self.nCol
                    iWell=iWell+1;
                    well=Self.get(iWell);
                    well.sWell(strcat(sRow, num2str(iCol)));
                    well.id=iWell;
                    well.iRow=iRow;
                    well.iCol=iCol;
                    if isobject(well.hTextBox)
                        well.hTextBox.String=well.name;
                    end
                end
           end                     
        end
        
        
        
        function ele=add(Self, ele)
           % check type, set if new list
           ele=add@OOList(Self, ele);
           try 
            ele.set('pixel_per_mm', Self.pixel_per_mm);
            ele.set('bInteractive', Self.bInteractive);
            ele.set('bQuiet', Self.bQuiet);
            ele.set('peakFitType', Self.peakFitType);
           catch
               disp('OOwellSet::add: failed to copy pixel_per_mm');
           end
        end
        %
        function n=nWell(Self)
            n=Self.n();
        end
        %
        function w=well(Self,i)
            w=Self.get(i);
        end
                
        function wellSelectGui(Self, hAxes)
            %
            if hAxes==0
                hFigure=figure;
                hAxes=axes('Position',[0.1 0.1 0.8 0.8], 'Parent',hFigure);
            end
            %
            set(hAxes,'XLim',[0.5 Self.nCol+0.5]);
            set(hAxes,'YLim',[0.5 Self.nRow+0.5]);
            set(hAxes,'XAxisLocation','top');
            set(hAxes,'XTick',1:6);
            set(hAxes,'Ydir','reverse');
            set(hAxes,'YTick',1:8);
            set(hAxes,'Box','on');
            set(hAxes,'YTickLabel',{'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'});            
            %
            for i=1:Self.n
               Self.well(i).initializeWellSelector(hAxes);
            end
            
        end        
        %
        function val=maxFrequency(Self, val)
            if exist('val','var')
               val=maxFrequency@OOtimeSeriesPar(Self, val);            
               for i=1:Self.n
                   Self.well(i).maxFrequency(val);
               end            
            end            
            val=maxFrequency@OOtimeSeriesPar(Self);
        end
        
        
        function val=runAvgLen(Self, val)
            if exist('val','var')         
               val=runAvgLen@OOtimeSeriesPar(Self, val);            
               for i=1:Self.n
                   Self.well(i).runAvgLen(val);
               end            
            end            
            val=runAvgLen@OOtimeSeriesPar(Self);
        end
        
        function val=runAvgSLen(Self, val)
            if exist('val','var')         
               val=runAvgSLen@OOtimeSeriesPar(Self, val);            
               for i=1:Self.n
                   Self.well(i).runAvgSLen(val);
               end            
            end            
            val=runAvgSLen@OOtimeSeriesPar(Self);
        end
        
        function val=framesPerSecond(Self, val)
            if exist('val','var')            
               val=framesPerSecond@OOtimeSeriesPar(Self, val);            
               for i=1:Self.n
                   Self.well(i).framesPerSecond(val);
               end            
            end            
            val=framesPerSecond@OOtimeSeriesPar(Self);
        end
        
        function val=peakThresh(Self, val)
            if exist('val','var')            
               val=peakThresh@OOtimeSeriesPar(Self, val);            
               for i=1:Self.n
                   Self.well(i).peakThresh(val);
               end            
            end            
            val=peakThresh@OOtimeSeriesPar(Self);
        end        
        %
        function analyzeDistances(Self)
            for i=1:Self.nWell
                Self.well(i).analyzeDistances;
            end
        end
        %
        function nPeaks=findPeaks(Self)
            nPeaks=0;
            for i=1:Self.nWell
                nPeaks=nPeaks+Self.well(i).findPeaks;
            end
        end
        
        %
        function distance2force(Self)
            for i=1:Self.nWell
                Self.well(i).distance2force
            end
        end
        
        function val=lastFrame(Self, val)
            %
            if exist('val','var')
                val=lastFrame@OOtimeSeriesPar(Self, val);
                for i=1:Self.n
                    Self.get(i).lastFrame(val);
                end
            end
            val=lastFrame@OOtimeSeriesPar(Self);
        end
        
        function val=firstFrame(Self, val)
            %
            if exist('val','var')
                val=firstFrame@OOtimeSeriesPar(Self, val);
                for i=1:Self.n
                    Self.get(i).firstFrame(val);
                end
            end
            val=firstFrame@OOtimeSeriesPar(Self);
        end
        
        function val=noiseThresh(Self, val)
            %
            if exist('val','var')
                val=noiseThresh@OOtimeSeriesPar(Self, val);
                for i=1:Self.n
                    Self.get(i).noiseThresh(val);
                end
            end
            val=noiseThresh@OOtimeSeriesPar(Self);
        end
        
        
        function fillWellSet(Self, nRow, nCol)
            %
            %error('dont use')
            Self.nRow =nRow;
            Self.nCol =nCol;
            %
            iWell=0;
            %
            for iRow = 1:Self.nRow
                sRow=num2abc(iRow);
                for iCol = 1:Self.nCol
                    %
                    iWell=iWell+1;
                    sWell=strcat(sRow, num2str(iCol));
                    %
                    if (iWell > Self.nWell)
                        well=OOwell(Self, sWell);                        
                        Self.add(well);
                    end
                    %
                    well=Self.get(iWell);
                    %
                    well.iRow=iRow;
                    well.iCol=iCol;
                    well.id  =iWell;
                    well.name=sWell;
                end
            end
        end
        %
        %
     end
end