function x = swap_random(data)

% x = swap_random(data)
%
% generates a random legal solution x
%
% INPUTS
% 
% data = data used in allocation, in struture. 
%     data.n the number of staff
%     data.m should hold the number of modules. 
%     data.module_mask is an array of integers holding 
%     the maximum number of staff to be involved in the delivery of the 
%     corresponding module 
%     data.staff_limited is an array of Booleans, indicating if certain
%     staff should be excluded from teaching allocation (e.g. due to
%     fellowships)
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
% x = legal solution
%
% Jonathan Fieldsend, University of Exeter, 2017


exclude = find(data.staff_limited==true); %staff not to use
X = zeros(data.m,data.n);
C = zeros(data.m,data.n);
for i=1:data.m %for each module in turn
    rn = randperm(data.n);
    rn = setdiff(rn,exclude); % will reorder from shuffled
    k = randperm(length(rn));
    rn = rn(k);
    if (data.module_minimum(i)>1)
        X(i,:) = data.preallocated_X(i,:); % allocate minimum amounts required to allocated staff
        remaining = data.increment_number(i)-sum(X(i,:))-data.external_allocation(i);
        rn = setdiff(rn,find(data.preallocated_X(i,:)>1)); % remove already allocated
        k = randperm(length(rn));
        rn = rn(k);
        for k =1 :remaining
            j = randperm(length(rn));
            j = j(1);
            X(i,rn(j))=X(i,rn(j))+1;
        end
        %X(i,rn(1)) = data.increment_number(i)-(data.external_allocation(i)+sum(X(i,rn(1:data.module_minimum(i)))));
    else
        old_rn = rn;
        rn = rn(1);
        if (sum(data.preallocated_X(i,:))>0)
            rn = find(data.allocation_mask(i,:)>0);
        end
        if length(rn)>1
            inc = (data.increment_number(i)-data.external_allocation(i))/length(rn);
            X(i,rn) = inc;
        else
            while (sum(X(i,:))+data.external_allocation(i))<data.increment_number(i)
                k = randperm(length(old_rn));
                index = old_rn(k(1));
                X(i,index) = X(i,index) +1;
            end
        end
    end
    [~, index] = max(X(i,:));
    C(i,index) =1;
end
x.X = X;
x.C = C;
P(1).s = x;

x = P(1).s;
if sum(sum(x.X-floor(x.X)))~=0
    x.X
    error('partial');
end
if sum((sum(x.X,2)+data.external_allocation)~=data.increment_number)>0
    % print out if there is an issue
    x.X
    [sum(x.X,2), data.external_allocation, data.increment_number, data.module_minimum', sum(data.preallocated_X,2), sum(data.allocation_mask,2)]
    data.preallocated_X(end,:)
    error('not matching');
end

P(1).s = x;
P = teaching_constraints(P, data); % apply constraints
x = P(1).s;


end

