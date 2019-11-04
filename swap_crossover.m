function P = swap_crossover(P,data)

% P = swap_crossover(P,data)
%
% performs swap crossover on the population P
%
% INPUTS
% 
% P = parent population (structure, where P(i).s is the ith solution
%     in the parent population. s is a structure with matrices X and C
%     representing the staff allocation matrices
% data = data used in allocation -- optional argument 
%
% OUTPUTS
%
% P = child population
%
% Jonathan Fieldsend, University of Exeter, 2017


k = length(P);
R_comb = randperm(k);
for i=1:2:k-1
    parent1 = P(R_comb(i)).s;
    parent2 = P(R_comb(i+1)).s;
    crossover_mask = rand(data.m,1)<0.5;
    child1 = parent1;
    child2 = parent2;
    if rand()<0.8 % 80% chance of crossover
        child1.X(crossover_mask,:) = parent2.X(crossover_mask,:);
        child1.C(crossover_mask,:) = parent2.C(crossover_mask,:);
        
        child2.X(crossover_mask,:) = parent1.X(crossover_mask,:);
        child2.C(crossover_mask,:) = parent1.C(crossover_mask,:);
    end
    P(R_comb(i)).s = child1;
    P(R_comb(i)).s = child2;
end

end