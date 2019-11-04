function P = teaching_constraints(P, data) 

% P = teaching_constraints(P,data)
%
% Function fixes any additional constraints that might be present in the
% data argument (e.g. specific partial/full allocations of modules to
% particular staff that the optimiser must enforce)
%
% INPUTS
% 
% P = population (structure, where P(i).s is the ith solution
%     in the parent population. s is a structure with matrices X and C
%     representing the staff allocation matrices
% data = data used in allocation, in struture. 
%     data.m should hold the number of modules. 
%     data.module_mask is an array of integers holding the maximum number 
%     of staff to be involved in the delivery of the corresponding module. 
%     data.preallocated_module_indices holds the indices of all modules 
%     with preallocations
%     data.preallocated_X and data.preallocated_C holds the corresponding 
%     allocations to staff that must be ensured. 
%     data.external_allocation holds the amount of a module which is 
%     delivered by staff *outside* of the set being allocated to (e.g. from 
%     other departments/external speakers). 
%     data.limited_module_indices holds indices of modules where staff are
%     limited on the proportion they should be allocated (e.g. on project
%     modules) 
%     data.limited_X holds these limits. 
%     data.increment_number holds the 'chunk' numbers that each module's 
%     teaching is broken down into equal size chunks of. 
%     data.duplicated_coord_module_indices{j} holds the jth set of modules 
%     which codeshare, and therefore should have the same coordinator and 
%     teaching staff assigned
%
% OUTPUTS
%
% P = healed population
%
% Jonathan Fieldsend, University of Exeter, 2017


for i=1:length(P)
   s = P(i).s;
   % ensure preallocations
   for j=data.preallocated_module_indices
       if (sum(data.preallocated_C(j,:))>0)
            if sum(abs(s.C(j,:)-data.preallocated_C(j,:)))~=0 % some coordinators not matched
                s.C(j,:) = data.preallocated_C(j,:);
            end
       end
       I = find((s.X(j,:)-data.preallocated_X(j,:)) < 0); % identify where less than minimum teaching load
       if isempty(I)==0 % some minium teaching not matched
           s.X(j,I) = data.preallocated_X(j,I);
           total_load = sum(s.X(j,:))+data.external_allocation(j);
           while (total_load>(data.increment_number(j)))
               live = find(s.X(j,:)>0);
               k = randperm(length(live));
               if s.X(j,live(k(1)))>data.preallocated_X(j,live(k(1)))
                   s.X(j,live(k(1))) = s.X(j,live(k(1)))-1;
               end
               total_load = sum(s.X(j,:))+data.external_allocation(j);
           end
       end
   end
   
   % ensure maximum isn't breached on projects
   for j=data.limited_module_indices
       I = find((s.X(j,:)-data.limited_X(j,:)) > 0); % identify where greater than maximum teaching load
       if isempty(I)==0 % some maximum teaching breached
           s.X(j,I) = data.limited_X(j,I);
           total_load = sum(s.X(j,:))+data.external_allocation(j);
           while (total_load<(data.increment_number(j)))
               live = find((s.X(j,:)>0) + (s.X(j,:) < data.limited_X(j,:))==2);
               if isempty(live)==1
                   live = find(s.X(j,:) < data.limited_X(j,:));
               end 
               k = randperm(length(live));
               s.X(j,live(k(1))) = s.X(j,live(k(1)))+1;
               total_load = sum(s.X(j,:))+data.external_allocation(j);
           end
       end
   end
   
   % ensure duplicated modules are co-taught
   for j=1:length(data.duplicated_module_indices)
        I = data.duplicated_module_indices{j};
        s.X(I(2),:) = data.increment_number(I(2))*s.X(I(1),:)/data.increment_number(I(1));
        s.C(I(2),:) = s.C(I(1),:);
   end
   
   for j=1:length(data.duplicated_coord_module_indices)
        I = data.duplicated_coord_module_indices{j};
        s.C(I(2),:) = s.C(I(1),:);
   end
   
   % ensure coordinator is a teacher
   for j=data.limited_module_indices
      I = find(s.X(j,:) > 0);
      if isempty(I)==0
        if sum(s.C(j,I)) == 0 % teacher isn't coordinator
            s.C(j,:) = 0;
            r = randperm(length(I));
            s.C(j,I(r(1)))=1;
        end
      end
   end
     
   P(i).s = s;
   %if (sum(sum(P(i).s.X<0)))>0; error('negative load'); end;
end


end