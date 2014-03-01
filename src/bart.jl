type BartLeaf <: DecisionLeaf
    value::Float64
    train_data_indices::Vector{Int}
end

type BartTreeTransformationProbabilies
    node_birth_death::Float64
    change_decision_rule::Float64
    swap_decision_rule::Float64

    function BartTreeTransformationProbabilies(n, c, s)
        assert(n+c+s==1.0)
        new(n, c, s)
    end
end
BartTreeTransformationProbabilies() = BartTreeTransformationProbabilies(0.5, 0.4, 0.1)

type BartOptions <: RegressionModelOptions
    num_trees::Int
    burn_in::Int
    num_draws::Int
    alpha::Float64
    beta::Float64
    k::Float64
    transform_probabilities::BartTreeTransformationProbabilies
end
BartOptions() = BartOptions(10, 200, 1000, 0.95, 2.0, BartTreeTransformationProbabilies())

function bart_options(;num_trees::Int=10,
                      burn_in::Int=200,
                      num_draws::Int=1000,
                      alpha::Float64=0.95,
                      beta::Float64=2.0,
                      k::Float64=2.0,
                      transform_probabilities::BartTreeTransformationProbabilies=BartTreeTransformationProbabilies())
    BartOptions(num_trees, burn_in, num_draws, alpha, beta, k, transform_probabilities)
end

type BartTree <: AbstractRegressionTree
    root::DecisionNode
end

# This is really a single iteration / state.
type Bart <: RegressionModel
    trees::Vector{BartTree}
    sigma::Float64
    sigma_hat::Float64
    options::BartOptions
end

function nonterminal_node_prior(alpha::Float64, beta::Float64, depth::Int)
    # using the convention that the root node has depth=1
    # BART paper implies that root node has depth=0
    alpha * depth^(-beta)
end

function nonterminal_node_prior(opts::BartOptions, depth::Int)
    nonterminal_node_prior(opts.alpha, opts.beta, depth)
end

function sigma_prior(x::Matrix{Float64}, y::Vector{Float64})
    linear_model = x\y
    sigma_hat = std(x*linear_model-y)
end

function initialize_bart(x::Matrix{Float64}, y::Vector{Float64}, opts::BartOptions)
    trees = Array(BartTree, 0)
    y_bar = mean(y)
    for i=1:opts.num_trees
        push!(trees, BartTree(BartLeaf(y_bar, [1:size(x,1)])))
    end
    sigma_hat = sigma_prior(x, y)
    Bart(trees, 1.0, sigma_hat, opts)
end

function draw_sigma(bart::Bart)
    # Default setting for sigma prior. Eventually move these settings to BartOptions
    v = 3.0
    q = 0.90
    inverse_gamma = InverseGamma(v/2.0, 1/2.0)
    lambda = bart.sigma_hat^2.0/quantile(inverse_gamma, q)/v
    sigma = sqrt(v*lambda*rand(inverse_gamma))
    sigma
end

function draw_sigma!(bart::Bart)
    sigma = draw_sigma(bart)
    bart.sigma = sigma
end

function update_tree!(tree::BartTree, opts::BartOptions, x::Matrix{Float64}, r::Vector{Float64})
    select_action = rand()
    if select_action < opts.transform_probabilities.node_birth_death
        alpha = node_birth_death!(tree, x, r, opts)
    elseif select_action < opts.transform_probabilities.node_birth_death + opts.transform_probabilities.change_decision_rule
        alpha = change_decision_rule!(tree, x, r)
    else
        alpha = swap_decision_rule!(tree, x, r)
    end
    alpha
end

function probability_node_birth(tree::BartTree)
    if typeof(tree.root) == BartLeaf
        probability_birth = 1.0
        birth_node = tree.root
    else
        probability_birth = 0.5
        leaf_nodes = all_leaf_nodes(tree)
        i = rand(1:length(leaf_nodes))
        birth_node = leaf_nodes[i]
    end

    probability_birth, birth_node
end

function all_leaf_nodes(tree::BartTree)
    leaf_nodes = Array(BartLeaf, 0)
    all_leaf_nodes!(tree.root, leaf_nodes)
    leaf_nodes
end

function all_leaf_nodes!(branch::DecisionBranch, leaf_nodes::Vector{BartLeaf})
    all_leaf_nodes!(branch.left,  leaf_nodes)
    all_leaf_nodes!(branch.right, leaf_nodes)
end

function all_leaf_nodes!(leaf::BartLeaf, leaf_nodes::Vector{BartLeaf})
    push!(leaf_nodes, leaf)
end

function depth(tree::BartTree, leaf::BartLeaf)
    depth(tree.root, leaf)
end

function depth(branch::DecisionBranch, leaf::BartLeaf)
    left_depth  = depth(branch.left)
    right_depth = depth(branch.right)
    left_depth  = left_depth > 0  ? left_depth  + 1 : 0
    right_depth = right_depth > 0 ? right_depth + 1 : 0
    max(left_depth, right_depth)
end

function depth(leaf2::BartLeaf, leaf::BartLeaf)
    leaf==leaf2 ? 1 : 0
end

function parent(tree::BartTree, leaf::BartLeaf)
    parent(tree.root, leaf)
end

function parent(branch::DecisionBranch, leaf::BartLeaf)
    if branch.left==leaf || branch.right==leaf
        this_parent = branch
    else
        error("Not implemented yet")
    end
end

function growth_prior(tree::BartTree, leaf::BartLeaf, opts::BartOptions)
    leaf_depth = depth(tree, leaf)
    branch_prior = nonterminal_node_prior(opts, leaf_depth)
    length(leaf.train_data_indices) >= 5 ? branch_prior : 0.001*branch_prior
end

function node_birth!(tree::BartTree, leaf::BartLeaf, x::Matrix{Float64}, r::Vector{Float64}, opts::BartOptions)
    branch_prior = growth_prior(tree, leaf, opts)
    error("Not implemented yet")
end

function node_death!(tree::BartTree, x::Matrix{Float64}, r::Vector{Float64})
    error("Not implemented yet")
end

function node_birth_death!(tree::BartTree, x::Matrix{Float64}, r::Vector{Float64}, opts::BartOptions)
    probability_birth, birth_node = probability_node_birth(tree)
    if rand() < probability_birth
        node_birth!(tree, birth_node, x, r, opts)
    else
        node_death!(tree, x, r)
    end
end

function change_decision_rule!(tree::BartTree, x::Matrix{Float64}, r::Vector{Float64})
    error("Not implemented yet")
end

function swap_decision_rule!(tree::BartTree, x::Matrix{Float64}, r::Vector{Float64})
    error("Not implemented yet")
end

function posterior_mu_sigma(prior_mu, a, sigma_hat, y_bar, num_observations)
    b = num_observations / sigma_hat^2
    posterior_mu = b*y_bar/(a+b)
    posterior_sigma = 1 / sqrt(a+b)
    posterior_mu, posterior_sigma
end

function fit_predict(x_train::Matrix{Float64}, y_train::Vector{Float64}, opts::BartOptions, x_test::Matrix{Float64})
    bart = initialize_bart(x_train, y_train, opts)
    for i=1:opts.num_draws
        draw_sigma!(bart)
        y_hat = predict(bart, x_train)
        for i=1:opts.num_trees
            residuals = y_train-y_hat+predict(bart.trees[i], x_train)
            update_tree!(bart.trees[i], bart.options, x_train, residuals)
        end
        if i>opts.burn_in
            # store predictions
        end
    end
end

function StatsBase.predict(bart::Bart, sample::Vector{Float64})
    sum([predict(tree, sample) for tree=bart.trees])
end