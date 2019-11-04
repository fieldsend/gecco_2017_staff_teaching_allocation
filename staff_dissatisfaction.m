function quality = staff_dissatisfaction(X,P,level,increment_number)

% quality = staff_dissatisfaction(X,P,level,increment_number)
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
%
% 
% Jonathan Fieldsend, University of Exeter, 2017
quality = max(sum((X./repmat(increment_number,1,size(X,2))).*(P>=level)));
end

