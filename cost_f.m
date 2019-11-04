function [y,w] = cost_f(s,data)

% [y,w] = cost_f(s,data)
%
% Seven objective cost function for staff teaching allocation.
%
% INPUTS
%
% s = solution (structure with the elements X and C of allocations)
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
% y = objective vector (to minimise)
% w = combined workload for each staff member -- useful for visualising
%     solutions
%
% Jonathan Fieldsend, University of Exeter, 2017


X = s.X./repmat(data.increment_number,1,data.n);

y = zeros(1,7);
w = get_combined_workload(X,s.C, data.w_star, data.c_matrix,data.d_matrix, data.p_matrix, data.alpha, data.T);
y(1) = sum(w)/sum(data.h);
y(2) = unbalanced_workload(w,data.h);
y(3) = staff_total_dissatisfaction(X,data.P,1,data.increment_number);
y(4) = staff_dissatisfaction(X,data.P,2,data.increment_number);
y(5) = average_staff_per_module(X);
y(6) = peak_load(X, s.C, data.h, data.c_matrix, data.d_matrix, data.p_matrix, data.t_matrix, data.alpha,data.T);
y(7) = variation_from_previous_year_teach(X, data.R/100,data.increment_number);

% unused but potential criteria
%y(i) = stddev_workload(w, data.h);
%y(j) = max(w./data.h);


if (data.constraints_on==1)
    %'apply constraints'
    y = apply_soft_constraints(y,s,data);
end
end

function y = apply_soft_constraints(y,s,data)

for i=1:data.m
    if sum(s.X(i,:)>0) < data.module_minimum(i) % all staff on module should be given at least the minimum load
        %fprintf('mn ');
        %data.full_module_names{i}
        y(data.objective_mask) = y(data.objective_mask)+ data.mxb*(data.module_minimum(i)-sum(s.X(i,:)>0));
    end
    if sum(s.X(i,:)>data.module_maximum(i))>0 % all staff on module must not be given more than maximum of module
        %fprintf('mx ');
        %data.full_module_names{i}
        y(data.objective_mask) = y(data.objective_mask)+ data.mxb*(abs(data.module_maximum(i)-sum(s.X(i,:)>0)));
    end
end

for i=1:data.n
    %if (data.staff_limited(i)==1) && ((sum(s.X(:,i))-sum(s.X(data.project_indices,i)))>(sum(data.preallocated_X(:,i))) || (sum(s.C(:,i))>0 && sum(data.preallocated_X(:,i))==0))
    if sum(s.X(:,i)<data.preallocated_X(:,i))>0%|| (sum(s.C(:,i))>0 && sum(data.preallocated_X(:,i))==0))
        %data.staff_names{i}
        %fprintf(strcat('pv ',data.staff_names{i},' '));
        y(data.objective_mask) = y(data.objective_mask)+data.mxb;
    end
%     
%     if (data.staff_limited(i)==0) && (sum(s.X(:,i))-sum(s.X(data.project_indices,i)))<0.5
%         %data.staff_names{i}
%         y(data.objective_mask) = y(data.objective_mask)+data.mxb; % all staff to do some teaching
%     end
    
end
mx_p = 10;
for i=1:data.n
    if (sum(s.X(data.all_project_indices,i))>mx_p) %total projects
        
        y(data.objective_mask) = y(data.objective_mask)+(sum(s.X(data.all_project_indices,i))-mx_p)*data.mxb;
    end
end

% penalise more than 1 whole module extra in one term over another
v = peak_load_proportion_of_module(s.X,data.t_matrix,data.increment_number,data.n);
mx_im=2;
if (v>mx_im)
    %fprintf('pl ');
    y(data.objective_mask) = y(data.objective_mask)+ (v-mx_im)*data.mxb;
end
% penalise assignment to prevent marked mappings
temp = sum(sum(s.X(data.prevent==1)));
y(data.objective_mask) = y(data.objective_mask)+ temp*data.mxb;
%fprintf('\n');

end