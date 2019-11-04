
function w = get_combined_workload(X,C, w_star, c_matrix,d_matrix, p_matrix, alpha, T)

% w = get_combined_workload(X,C, w_star, c_matrix,d_matrix, p_matrix, alpha, T)
%
% Calculates the total workload for each staff member and puts in an array
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
%
% Jonathan Fieldsend, University of Exeter, 2017



temp = c_matrix.*C + (d_matrix + (1+alpha*T).*p_matrix).*X; % calculate matrix of teaching loads
w = (w_star+sum(temp)); % add loads to each staff member
end