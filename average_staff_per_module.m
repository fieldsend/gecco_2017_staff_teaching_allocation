function quality = average_staff_per_module(X)

% quality = average_staff_per_module(X)
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
%
% 
% Jonathan Fieldsend, University of Exeter, 2017

quality = sum(sum(X~=0))/size(X,1);
end
