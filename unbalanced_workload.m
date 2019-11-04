function quality = unbalanced_workload(w,h)

% quality = unbalanced_workload(w,h)
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
% 
% Jonathan Fieldsend, University of Exeter, 2017

quality = max(w./h)- min(w./h);
end