classdef OOList < OOclass
    %PropertyReference Reference to a property in another object
    properties
        %
        type='';
        list={};        
        i=0;
    end
    
    methods
        function Self = OOList()
            Self.i=0;
            %            
        end
        %
        % read Frame is to match the corresponding videoReader function. It
        % loads the next frame
        %
        function i=n(Self)
            i=numel(Self.list);
        end
        
        function ele=add(Self, ele)
           % check type, set if new list
           if Self.n==0
               Self.type=class(ele);
           elseif ~strcmp(Self.type, class(ele))                
              error('OOList::add: types of list and new element dont match') 
           end
           %
           Self.list{end+1}=ele;           
        end
        
        function ele=remove(Self, i)
           % check type, set if new list
           ele=0;
           if i <= Self.n
               ele=Self.get(i);
               Self.list(i)=[];               
           else         
              error(sprintf('OOList::remove: index %d larger than list %d', i, Self.n)); 
           end
           %
        end
        
        function arr=activeList(Self)
           arr=Self.getValues('bActive');           
        end
        
        function arr=getValues(Self, val)
            arr=nan(Self.n,1);
            if Self.n>0 && ~isprop(Self.get(1), val)
                [self.type val]
                Self.get(1)
                error('OOList::getValues: field not in element');
            end
            for j=1:Self.n
                arr(j,1)=Self.get(j).(val);
            end
           
        end
        
        function set(Self,par,val)
            %
            Self.set@OOclass(par,val);
            for i=1:Self.n
                Self.get(i).set(par, val);                
            end            
        end
        
        function ele=empty(Self)
            %
            for i=1:Self.n
                Self.get(i).empty();                
            end
            Self.list={};            
        end
        
        function bEm=bEmpty(Self)
            %
            bEm = false;
            if (Self.n==0)
                bEm=true;
            else
                bEm=false;
            end
        end
        
        function ele=last(Self)
           ele=Self.list{Self.n};         
        end
        
        function ele=rewind(Self)
           Self.i=0;
        end
        
        function ele=get(Self, i)
           ele=0;
           if (i <= Self.n)
               ele=Self.list{i};
           else
                error('no Element %d in list of %d', i, Self.n);
           end
        end
        
        function was=put(Self, i, ele)
          was=0;
          if (i <= Self.n)
              was=Self.list{i};
              Self.list{i}=ele;
          end        
        end
        
        function ele=getNext(Self)
           ele=0;
           if (Self.i<Self.n)
               Self.i=Self.i+1;
               ele=Self.list{Self.i};
           end
        end
        
    end
end

            
