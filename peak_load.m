function quality = peak_load(X, C,  h, c_matrix,d_matrix, p_matrix, t_matrix, alpha, T)
% quality = peak_load(X, C,  h, c_matrix,d_matrix, p_matrix, t_matrix, alpha, T)
%
% Please refer to the GECCO paper linked in the repository for details on
% the arguments
%
% 
% Jonathan Fieldsend, University of Exeter, 2017

temp = (c_matrix.*C + (d_matrix + (1+alpha*T).*p_matrix).*X);
quality = max(abs(sum(temp.*(t_matrix==1)- temp.*(t_matrix==2))./h));
end
