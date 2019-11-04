function P = swap_mutation(P,data)

% P = swap_mutation(P,data)
%
% performs swap mutation on the population P
%
% INPUTS
% 
% P = parent population (structure, where P(i).s is the ith solution
%     in the parent population. s is a structure with matrices X and C
%     representing the staff allocation matrices
% data = data used in allocation, in struture. data.m should hold the
%     number of modules. data.module_mask is an array of integers holding 
%     the maximum number of staff to be involved in the dlivery of the 
%     corresponding module 
%
% OUTPUTS
%
% P = child population
%
% Jonathan Fieldsend, University of Exeter, 2017

max_to_vary = 1; % just switches on one element -- may want to increase this 

for i=1:length(P)
    for k=1:max_to_vary
        child = P(i).s;
        rm = randperm(data.m); % get a module at random
        rm = rm(1);
        if (data.module_mask(rm)==1)
            r = randperm(data.n);
            child.C(rm,:) = 0;
            child.X(rm,:) = 0;
            child.C(rm,r(1)) = 1; % swap staff memebr involved
            child.X(rm,r(1)) = data.increment_number(rm)-data.external_allocation(rm);
        else
            I = find(child.X(rm,:)>0); % get indices where teaching is happening
            r = randperm(length(I));
            I = I(r); %randomly permute
            if (isempty(I)==0) %some delivery internally
                if rand()<0.5
                    child.X(rm(1),I(1)) = child.X(rm(1),I(1))-1;
                    if (length(r)<data.module_mask(rm)) % can add extra staff
                        rn = randperm(data.n); % allocate to a random other
                        child.X(rm(1),rn(1)) = child.X(rm(1),rn(1))+1;
                        % always assign coordination to staff teaching most of module
                        child.C(rm(1),:)=0;
                        [~,index] = max(child.X(rm(1),:));
                        child.C(rm(1),index)=1;
                    else % can only shift between staff
                        child.X(rm(1),I(2)) = child.X(rm(1),I(2))+1;
                        % always assign coordination to staff teaching most of module
                        child.C(rm(1),:)=0;
                        [~,index] = max(child.X(rm(1),:));
                        child.C(rm(1),index)=1;
                    end
                else %randomly remove teaching of module from one member of staff and give to another
                    rn = randperm(data.n); % allocate to a random other
                    if (rn(1)==I(1))
                        rn =rn(2);
                    else
                        rn = rn(1);
                    end
                    child.X(rm(1),rn) = child.X(rm(1),rn) + child.X(rm(1),I(1));
                    child.X(rm(1),I(1)) = 0;
                    child.C(rm(1),rn) = max(child.C(rm(1),I(1)),child.C(rm(1),rn));
                    child.C(rm(1),I(1)) = 0;
                end
            else %  where no teaching due to external delivery swap coordinator
                child.C(rm(1),:)=0;
                index = randperm(data.n);
                child.C(rm(1),index(1))=1;
            end
        end
        P(i).s = child;
    end
end

% enforce constraints
P = teaching_constraints(P,data);

end