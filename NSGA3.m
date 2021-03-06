function [P,Y,Zsa,Pa,Ya,stats] = NSGA3(generations,...
    cost_function,crossover_function,mutation_function, ...
    random_solution_function,  initial_population, boundary_p, inside_p, M, ...
    data, passive_archive, extreme_switch,preset_bounds)

% [P,Y,Zsa,Pa,Ya,stats] = NSGA3(...
% generations,cost_function,crossover_function,mutation_function,...
% random_solution_function, initial_population, boundary_p, inside_p, M, ...
%    data, passive_archive, extreme_switch,preset_bounds)
%
% INPUTS
% 
% generations = number of generations to run optimiser for
% cost_function = handle of function to be optimised
% crossover_function = handle of crossover function
% mutation_function = handle of mutation function
% random_solution_function = handle of function which supplies
%    random legal solutions
% initial_population = holds initial solutions
%    for evaluation, pass an empty matrix, [], if no initial
%    solutions available
% boundary_p = number of projection points on simplex boundary
%    (scales up with dimenion)
% inside_p = number of projection points on indside boundary
%    (scales up with dimenion)
% M = Input dimension of problem
% data = structure holding bounds to be used if preset bounds 
%   argument is 1 (l_bound and u_bound vectors for problem dimension)
%   and any additional project specific data (e.g. staff/module data
%   for staff allocation optimisation)
% passive_archive = OPTIONAL ARGUMENT (set at 1 if not
%    provided). If equal to 1 a passive archive tracking best
%    solutions evaluated during run is maintained and returned
%    in stats structure
% extreme_switch = OPTIONAL ARGUMENT If set at 1 the solutions at 
%    the extremes (minimising each criterion) are always peserved
%    in the selection from one generation to the next. Default 1.
% preset_bounds = OPTIONAL ARGUMENT if preset_bounds is 1 then the
%    bounds in data argument are to be used in simplex projection, 
%    set at 0 if not provided
%
% OUTPUTS
%
% P = Final search population
% Y = Objective values of final serach population
% Zsa = Projection of P (refer to Deb and Jai's work)
% Pa = Non-dominated subset of P
% Ya = Non-dominated subset of Y
% stats = Structure of various recorded statistics 
%
% REQUIRES recursive_pareto_shell_with_duplicates function from the 
% emo_2013_viz repository, also on my public github page 
%
% Jonathan Fieldsend, University of Exeter, 2017, based upon
% description in Deb and Jain, 2014, IEEE TEVC, but with additional
% functionality to e.g. allow focus on extremes and preset bounds



hv_samp_number=10000;
structure_flag =1;
P=[];
stats=[];
start_point = 1;
if (exist('initial_population', 'var'))
    P = initial_population;
    start_point = length(P)+1;
end
if (exist('passive_archive', 'var')==0)
    passive_archive = 1;
end
if (exist('preset_bounds', 'var')==0)
    preset_bounds = 0;
end
if (exist('extreme_switch', 'var')==0)
    extreme_switch = 1;
end
% create structured points if aspiration points not passed in
Zsa = get_structure_points(M, boundary_p, inside_p);
pop_size = size(Zsa,1);

while rem(pop_size,4)>0
    pop_size = pop_size+1;
end
fprintf('Population size is: %d\n',pop_size);


for i=start_point:pop_size
    P(i).s = random_solution_function(data);
end
Y = [];
for i =1:length(P)
    Y(i,:) =  cost_function(P(i).s,data);
end
Pa=[];
Ya =[];
if passive_archive==1
    [P_ranks] = recursive_pareto_shell_with_duplicates(Y,0);
    Ya = Y(P_ranks==0,:);
    Pa = P(P_ranks==0);
    stats.prop_non_dom = zeros(generations,1);
    stats.mn = zeros(generations,M);
    stats.hv = zeros(generations,1);
    stats.gen_found = zeros(size(Ya,1)); % track which generation a Pareto solution was discovered
    hv_points = rand(hv_samp_number,M);
    hv_points = hv_points.*repmat(data.mxb-data.mnb,hv_samp_number,1);
    hv_points = hv_points+repmat(data.mnb,hv_samp_number,1);
    samps = 0;
end

for g=1:generations
    if rem(g,10)==0
        fprintf('generation %d, pop_size %d, passive archive size %d \n',g, pop_size, length(Ya));
        min(Y)
    end
    [P, Y, Pa, Ya,non_dom, S, Ry] = evolve(Zsa, P, Y, pop_size, cost_function, crossover_function,...
        mutation_function,structure_flag,data, Pa, Ya, passive_archive,extreme_switch,preset_bounds);
    if passive_archive
       stats.prop_non_dom(g) = proportion_nondominated(Y(non_dom,:),Ya);
       stats.mn(g,:) = min(Y);
       [stats.hv(g), hv_points, samps] = est_hv(data.mnb,data.mxb,Ya,hv_points,samps);
       stats.A(g).Y = Y;
       stats.A(g).Ya = Ya;
       
       
       if rem(g,10)==0
          fprintf('Prop dominated %f, MC samples %d, hypervolume %f\n',stats.prop_non_dom(g), samps+hv_samp_number, stats.hv(g));
       end
    end
end

end

%-----------------------
function [hv, hv_points, samps] = est_hv(mnb,mxb,Ya,hv_points,samps)

[hv_samp_number,m] =size(hv_points);

to_remove = [];
for i=1:size(hv_points,1)
    if sum(sum(Ya <= repmat(hv_points(i,:),size(Ya,1),1),2)==m)>0
       to_remove = [to_remove; i]; 
    end
end

hv_points(to_remove,:)=[];
removed = length(to_remove);

% estimate hypervolume
hv = (hv_samp_number-removed)/(samps+hv_samp_number);

% update number dominated
samps = samps + removed;

% refill random samps to 1000
new_points = rand(removed,m);
new_points = new_points.*repmat(mxb-mnb,removed,1);
new_points = new_points+repmat(mnb,removed,1);
hv_points = [hv_points; new_points];


end
%-----------------------
function p = proportion_nondominated(Y,Ya)

[n,m] = size(Y);
p=0;
for i=1:n
    ge = sum(sum(Ya <= repmat(Y(i,:),size(Ya,1),1),2)==m);
    if ge >0
       if sum(sum(Ya == repmat(Y(i,:),size(Ya,1),1),2)==m)<ge % at least one must dominate
           p = p+1;
       end
    end
end

p = (n-p)/n;

end
%-----------------------
function Zs = get_structure_points(M, boundary_p, inside_p)


Zs = get_simplex_samples(M,boundary_p);
Zs_inside = get_simplex_samples(M,inside_p);
Zs_inside = Zs_inside/2; % retract
Zs_inside = Zs_inside + 0.5/M;% project inside

Zs = [Zs; Zs_inside];
end

%-----------------------
function Zs = get_simplex_samples(M,p)

lambda = 0:p;
lambda = lambda/p;
Zs = [];

for i=1:p+1 % for lambda in turn 
    tmp = zeros(1,M); % initialise holder for reference point
    tmp = fill_sample(tmp,lambda,i,1,M);
    Zs = [Zs; tmp];
end

end 


%-----------------------
function tmp_processed = fill_sample(tmp,lambda,lambda_index,layer_processing,M)

tmp(layer_processing) = lambda(lambda_index);
if (layer_processing < M-1)
    already_used = sum(tmp(1:layer_processing));
    valid_indices = find(lambda <= 1-already_used+eps); % identify valid fillers that can be used
    tmp_processed = [];
    for j=1:length(valid_indices)
       tmp_new = tmp;
       recursive_matrix = fill_sample(tmp_new,lambda,j,layer_processing+1,M);
       tmp_processed = [tmp_processed; recursive_matrix]; 
    end
else % M-1th layer being processed so last element has to complete sum
    tmp_processed = tmp;
    tmp_processed(M) = 1-sum(tmp(1:M-1));
end

end

%-----------------------
function [F, raw] = nondominated_sort(Ry,extreme_switch)
    [N,M] = size(Ry);
    [P_ranks] = recursive_pareto_shell_with_duplicates(Ry,extreme_switch);
    raw = P_ranks;
    % identify and strip duplicates
    m_value = max(P_ranks)+1;
    % strip out individual minimises to protect'
    if extreme_switch
        I = find(P_ranks==1);
        [~,indices] = min(Ry(I,:),[],1);
        P_ranks(I(indices)) =0;
    end
    % now remove duplicates
    for i=1:N-1
       vec = repmat(Ry(i,:),N-i,1);
       eq_v = vec==Ry(i+1:end,:);
       ind = find(sum(eq_v,2)==M);
       P_ranks(ind+i)=m_value; % move duplicates to worst shell
    end
    
    for i=0:max(P_ranks)
        F(i+1).I = find(P_ranks==i);
    end
end
%-----------------------
function [Pa,Ya] = update_passive(Pa,Ya, Qy,Q)

for i=1:length(Q)
   if sum(sum(Ya <= repmat(Qy(i,:),size(Ya,1),1),2)==size(Ya,2))==0 % if not dominated
       indices = sum(Ya >= repmat(Qy(i,:),size(Ya,1),1),2)==size(Ya,2);
       Ya(indices,:)=[];
       Pa(indices)=[];
       Ya = [Ya; Qy(i,:)];
       Pa = [Pa Q(i)];
   end
end

end
%-----------------------
function [P, Y, Pa, Ya, nd, S, Ry] = evolve(Zsa, P, Y, N, cost_function, crossover_function,...
    mutation_function,structure_flag,data, Pa, Ya, passive_archive,extreme_switch,preset_bounds)

% Za Aspiration points
% Zr reference points
% P structure of parents
% Y objective evaluations of P, matrix |P| by M
S =[];
Q = crossover_function(P,data);
Q = mutation_function(Q,data);
% EVALUATE CHILDREN
Qy =[]; % could preallocate given number of objectives
for j=1:length(Q)
    Qy(j,:) = cost_function(Q(j).s,data);
end

if passive_archive
    [P_ranks] = recursive_pareto_shell_with_duplicates(Qy,0);
    to_compare = find(P_ranks==0);
    for i=1:size(to_compare,1)
       [Pa,Ya] = update_passive(Pa,Ya, Qy(to_compare,:),Q(to_compare));
    end
end

% MERGE POPULATIONS
R = [P Q];
Ry = [Y; Qy];
% TRUNCATE POPULATION TO GENERATE PARENTS FOR NEXT GENERATION
[F, raw] = nondominated_sort(Ry,extreme_switch); 
% each element of F contains the indices of R of the respective shell
nd = sum(raw==extreme_switch);
nd = 1:min(nd, size(Y,1));

i=1;
while length(S) < N
    S = [S; F(i).I];
    i = i+1;
end
P = [];
Yp = [];
if length(S) ~= N
    indices_used =[];
    for j=1:i-2
        indices_used = [indices_used; F(j).I];
        P = [P R(F(j).I)];
        Yp = [Yp; Ry(F(j).I,:)];
    end
    Fl = F(i-1).I; % elements of this last shell now need to be choosen
    K = N-length(P); % specifically K elements
    [Yn, Zr] = normalise(S,Ry,Zsa,structure_flag,preset_bounds,data);

    [index_of_closest,distance_to_closest] = associate(S,Yn,Zr);
    Zr_niche_count = get_niche_count(Zr,index_of_closest(S(1:length(P))));
    [P, Y, indices_used] = niching(K,Zr_niche_count,index_of_closest,distance_to_closest,...
        Fl,P,R,Yp,Ry,indices_used);
    
else
    P = R(S);
    Y = Ry(S,:);
end

end

%----------
function [Yn,Zr] = normalise(S,Y,Zsa,structure_flag,preset_bounds,data)

%
%
% OUTPUTS
% Yn = normalised objectives
%
if preset_bounds==1
    %'preset'
    ideal = data.l_bound;
    Yn = Y-repmat(ideal,size(Y,1),1);
    a = ones(size(data.u_bound))./((data.u_bound-data.l_bound)*(sum(data.u_bound)-sum(data.l_bound)));
else
    %'no preset'
    [~,M] = size(Y); % get number of objectives
    ideal = min(Y(S,:)); % initialise ideal point
    
    Yn = Y-repmat(ideal,size(Y,1),1);
    
    % FROM PAPER:
    %Thereafter, the extreme point (zi,max) in each (ith) objective
    %axis is identified by finding the solution (x ? St) that makes the
    %corresponding achievement scalarizing function (formed with
    %f_i (x) and a weight vector close to ith objective axis) minimum.
    nadir = zeros(1,M);
    scalarising_indices = zeros(1,M);
    for j=1:M
        scalariser = ones(length(S),M);
        scalariser(:,j) = 0;
        scalarised = sum(Yn(S,:).*scalariser,2);
        % ensure matrix isn't singular by excluding elements already selected
        for k=1:j-1
            vec = Yn(S(scalarising_indices(k)),:); % vector of objective values
            rep_vec = repmat(vec, length(S),1);
            res = Yn(S,:)==rep_vec;
            scalarised(sum(res,2)==M)=inf;
        end
        [~,i] = min(scalarised); % identify solution on the ith axis (i.e.
        %minimising the other objectives as much as possible)
        nadir(j) = Yn(i,j);
        scalarising_indices(j) = i;
    end
    
    X = Yn(S(scalarising_indices),:);
    
    a = linsolve(X, ones(M,1))'; % solve system of linear equations to get weights
    
end

Yn = Yn.*repmat(a,size(Yn,1),1); % rescale

if (structure_flag)
    Zr = Zsa;
else
    Zr = Zsa.*repmat(a,size(Zsa,1),1);    
end


end
%----------
function [index_of_closest,distance_to_closest] = associate(S,Yn,Zr)
% S = indices of members
% Yn = normalised objectives
% Zr = reference points

index_of_closest = zeros(max(S),1);
distance_to_closest = zeros(max(S),1);
D = zeros(size(Zr,1),1);
for i=1:length(S)
    for j=1:size(Zr,1)
        D(j) = norm(Yn(S(i),:)'-(Zr(j,:)*Yn(S(i),:)'*Zr(j,:)')/norm(Zr(j,:)',2)^2,2);
    end
    [distance_to_closest(S(i)),index_of_closest(S(i))] = min(D);
end

end

%------------
function [P, Yp, iu] = niching(K,Zr_niche_count,index_of_closest,distance_to_closest,...
    Fl,P,R,Yp,Y, iu)

% returns indices of final selected population
        
k = 1;

while k <=K
    [j_min] = min(Zr_niche_count);
    I = find(Zr_niche_count==j_min); % get indices of Zr elements which have smallest niche count
    j_bar = randperm(length(I));
    j_bar = I(j_bar(1)); % get random index of element of Zr which has lowest niche count
        
    Ij_bar = find(index_of_closest(Fl)==j_bar); % get members of Fl which have the j_bar element of Zr as their guide
    if(isempty(Ij_bar)==0) % is j_bar index in Fl?
        if (Zr_niche_count(j_bar)==0) % no associated P member with ref point
            [~,chosen_index] = min(distance_to_closest(Fl(Ij_bar))); % get index of closest matching member of Fl
        else
            indices = randperm(length(Ij_bar));
            chosen_index = indices(1);
        end
        P = [P R(Fl(Ij_bar(chosen_index)))]; % add to P
        Yp = [Yp; Y(Fl(Ij_bar(chosen_index)),:)];
        Zr_niche_count(j_bar)=Zr_niche_count(j_bar)+1;
        iu = [iu; Fl(Ij_bar(chosen_index))];
        Fl(Ij_bar(chosen_index))=[]; % remove from consideration next time
        k=k+1;
    else
        Zr_niche_count(j_bar) = inf; % put niche count to infinity so it will not be considered in the next loop, same as removing from Zr
    end
end

end




%----------
function [niche_count] = get_niche_count(Zr, indices)

% indices =
niche_count = zeros(length(Zr),1);
for i=1:length(niche_count)
    niche_count(i) = sum(indices==i);
end
end
