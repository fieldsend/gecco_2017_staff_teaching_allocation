function quality = variation_from_previous_year_teach(X, X_old,increment_number)
% quality = variation_from_previous_year_teach(X, X_old,increment_number)
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
%
% 
% Jonathan Fieldsend, University of Exeter, 2017

quality = sum(sum(abs(X-X_old)));
end
