classdef OOexcel < OOfile
    %
    % Housekeeping functions, usefull for any app
    %
    
    properties
        %
        nOpenRow=0;
        nOpenTable=0;
        nOpenWorksheet=0;
        %
        version='<?xml version="1.0"?>';
        progId='<?mso-application progid="Excel.Sheet"?>';
        xmlns = {'xmlns="urn:schemas-microsoft-com:office:spreadsheet"' ...
                 'xmlns:o="urn:schemas-microsoft-com:office:office"' ...
                 'xmlns:x="urn:schemas-microsoft-com:office:excel"' ...
                 'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' ...
                 'xmlns:html="http://www.w3.org/TR/REC-html40"'};
        %        
    end
    
    methods
        function Self=OOexcel(fName)
            Self.startTime=tic;
            if exist('fName','var')
                Self.fNameOut=fName;
            else
                Self.fNameOut=[getenv('tmp') '\OOexcel_out.xls'];
            end
        end
        %
        function openWorkbook(Self)
           fh=Self.open('w');
             
           fprintf(fh, '%s\n',  Self.version);
           fprintf(fh, '%s\n',  Self.progId);
           fprintf(fh, '<Workbook ');
           for i=1:numel(Self.xmlns)
               fprintf(fh, '%s\n', Self.xmlns{i});
           end
           fprintf(fh, '>\n');
        end
        
        function closeWorkbook(Self)
            %
            if (Self.nOpenWorksheet~=0)
                error(sprintf('have openWorksheets: %d', Self.nOpenWorksheet));
            end
            %
            fprintf(Self.hFileOut, '</Workbook>\n');
            Self.close();
        end
        
        function addStyles(Self)
            fprintf(Self.hFileOut, '<Styles>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sStr">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="@"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sPct0">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0%%"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sPct1">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0.0%%"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sPct2">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0.00%%"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            %<Style ss:ID="s69"> <NumberFormat ss:Format="0.0"/> </Style>
            fprintf(Self.hFileOut, '<Style ss:ID="sDec0">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sDec1">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0.0"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            fprintf(Self.hFileOut, '<Style ss:ID="sDec2">\n');
            fprintf(Self.hFileOut, '<NumberFormat ss:Format="0.00"/>\n');
            fprintf(Self.hFileOut, '</Style>\n');
            
            fprintf(Self.hFileOut, '</Styles>\n');
        end
        
        function openWorksheet(Self, wsName)
            Self.nOpenWorksheet=Self.nOpenWorksheet+1;
            fprintf(Self.hFileOut, '<Worksheet ss:Name="%s">\n', wsName);
        end
        
        function closeWorksheet(Self)
            if (Self.nOpenTable~=0)
                error(sprintf('have openTables: %d', Self.nOpenTable));
            end
            Self.nOpenWorksheet=Self.nOpenWorksheet-1;
            fprintf(Self.hFileOut, '</Worksheet>\n');
        end
        
        function openTable(Self)
            Self.nOpenTable=Self.nOpenTable+1;
            fprintf(Self.hFileOut, '<Table>\n');
        end        
        function closeTable(Self)
            if (Self.nOpenRow~=0)
                error(sprintf('openRows %d', Self.nOpenRow));
            end
            Self.nOpenTable=Self.nOpenTable-1;
            fprintf(Self.hFileOut, '</Table>\n');
        end
        function openRow(Self, nRow)
            %disp(sprintf('<Row ss:Index=" %.0f ">\n', nRow))
            Self.nOpenRow=Self.nOpenRow+1;
            fprintf(Self.hFileOut, '<Row ss:Index="%.0f">\n', nRow);
        end
        function closeRow(Self)
            Self.nOpenRow=Self.nOpenRow-1;
            fprintf(Self.hFileOut, '</Row>\n');
        end
        function openCell(Self, nCol)
            fprintf(Self.hFileOut, '<Cell ss:Index="%.0f">\n', nCol);
        end
        function writeCellFormula(Self, nCol, str)
            %<Cell ss:Formula="=IF(RC2*R4C2&gt;0, R4C2, &quot; &quot;)"></Cell>
            %replace all double quotes 
            %disp(str)
            str=strrep(str, '"', '&quot;');
            fprintf(Self.hFileOut, '<Cell ss:Index="%.0f" ss:Formula="%s"></Cell>\n', nCol, str);
        end
        %<Cell ss:StyleID="sPct" ss:Formula="=A1!R3C6"><Data ss:Type="Number">0.13491744250042159</Data></Cell>
        function writeCellFormulaFmt(Self, nCol, str, fmt)
            %<Cell ss:Formula="=IF(RC2*R4C2&gt;0, R4C2, &quot; &quot;)"></Cell>
            %replace all double quotes 
            %disp(str)
            str=strrep(str, '"', '&quot;');
            fprintf(Self.hFileOut, '<Cell ss:StyleID="%s" ss:Index="%.0f" ss:Formula="%s"></Cell>\n', fmt, nCol, str);
        end
        
        
        function writeCellString(Self, nCol, str)
            fprintf(Self.hFileOut, '<Cell ss:Index="%.0f"><Data ss:Type="String">%s</Data></Cell>\n', nCol, str);
        end
        
        function writeCellDouble(Self, nCol, val)
            if (isnan(val))
                fprintf(Self.hFileOut, '<Cell ss:Index="%.0f"><Data ss:Type="Number"></Data></Cell>\n', nCol);
            else
                fprintf(Self.hFileOut, '<Cell ss:Index="%.0f"><Data ss:Type="Number">%f</Data></Cell>\n', nCol, val);
            end
        end
        
        function writeCellDoubleFmt(Self, nCol, val,fmt)
           %ss:StyleID="sPct" 
           if (isnan(val))
                fprintf(Self.hFileOut, '<Cell ss:StyleID="%s" ss:Index="%.0f"><Data ss:Type="Number"></Data></Cell>\n', fmt, nCol);
            else
                fprintf(Self.hFileOut, '<Cell ss:StyleID="%s" ss:Index="%.0f"><Data ss:Type="Number">%f</Data></Cell>\n', fmt, nCol, val);
            end
        end
        
        
        function writeCellData(Self, nCol, fmt, val)
            fprintf(Self.hFileOut, '<Cell ss:Index="%.0f"><Data ss:Type="%s">%f</Data></Cell>\n', nCol, fmt,val);
        end
        
        function writeTest(Self)
            Self.openWorkbook();
             %
             Self.openWorksheet('Summary');
               Self.openTable()
                 Self.openRow(1)
                   Self.writeCellData(1,'Number',1.4)
                   Self.writeCellData(2,'Number',1.8)
                   Self.writeCellFormula(3,'=A1!A1')
                 Self.closeRow()
                 Self.openRow(2)
                   Self.writeCellData(1,'Number',2.4)
                   Self.writeCellData(2,'Number',13.8)
                   Self.writeCellFormula(3,'=RC[-1]*RC[-2]')
                 Self.closeRow()                 
               Self.closeTable()
             Self.closeWorksheet();
             %
             Self.openWorksheet('A1');
               Self.openTable()
                 Self.openRow(1)
                   Self.writeCellData(1,'Number',1.4)
                   Self.writeCellData(2,'Number',1.8)
                   Self.writeCellFormula(3,'=RC[-1]+RC[-2]')
                 Self.closeRow()
                 Self.openRow(2)
                   Self.writeCellData(1,'Number',2.4)
                   Self.writeCellData(2,'Number',13.8)
                   Self.writeCellFormula(3,'=RC[-1]*RC[-2]')
                 Self.closeRow()                 
               Self.closeTable()
             Self.closeWorksheet();
             %
            Self.closeWorkbook();

        end
        
        
        
    end
end

        
        