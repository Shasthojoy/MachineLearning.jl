module MachineLearning
    using
        DataFrames,
        Devectorize,
        Distributions,
        Gadfly,
        Optim,
        RDatasets,
        StatsBase

    export
        # types
        AbstractRegressionTree,
        Bart,
        BartLeaf,
        BartLeafParameters,
        BartOptions,
        BartState,
        BartTreeTransformationProbabilies,
        Branch,
        ClassificationForest,
        ClassificationForestOptions,
        ClassificationModel,
        ClassificationModelOptions,
        ClassificationLeaf,
        ClassificationNet,
        ClassificationPipeline,
        ClassificationPipelineOptions,
        ClassificationTree,
        ClassificationTreeOptions,
        CrossValidationSplit,
        SupervisedDataFrame,
        DataFrameModel,
        DecisionBranch,
        DecisionNode,
        DecisionTree,
        HashVectorizer,
        HashVectorizerOptions,
        Leaf,
        SupervisedMatrix,
        NeuralNet,
        NeuralNetLayer,
        ClassificationNetOptions,
        Node,
        StopAfterIteration,
        RegressionForest,
        RegressionForestOptions,
        RegressionModel,
        RegressionModelOptions,
        RegressionNet,
        RegressionNetOptions,
        RegressionPipeline,
        RegressionPipelineOptions,
        StopAfterValidationErrorStopsImproving,
        SupervisedModel,
        SupervisedModelOptions,
        TrainTestSplit,
        Transformer,
        TransformerOptions,
        Tree,
        Zmuv,
        ZmuvOptions,

        # methods
        accuracy,
        auc,
        bart_options,
        branches,
        classification_forest_options,
        classification_split_location,
        classification_tree_options,
        compare,
        cost,
        cost_gradient!,
        cost_gradient_update_net!,
        data_frame_feature_columns,
        data_set_x,
        data_set_y,
        data_set_x_y,
        depth,
        evaluate,
        fit,
        fit_predict,
        float_dataframe,
        float_matrix,
        gini,
        grand_branches,
        hash_vectorizer_options,
        importances,
        initialize_bart_state,
        initialize_classification_net,
        initialize_regression_net,
        initialize_neural_net_temporary,
        inverse_sigmoid,
        leaves,
        log_likelihood,
        log_loss,
        mean_log_loss,
        mean_squared_error,
        net_to_weights,
        classification_net_options,
        nonterminal_node_prior,
        not_grand_branches,
        one_hot,
        parent,
        partials,
        plot,
        predict,
        predict_probs,
        regression_forest_options,
        regression_net_options,
        regression_split_location,
        regression_tree_options,
        sample,
        sigmoid,
        split_cross_valid,
        split_train_test,
        streaming_mse,
        test_set,
        test_set_x,
        test_set_x_y,
        test_set_y,
        train_set,
        train_set_x,
        train_set_x_y,
        train_set_y,
        transform,
        valid_tree,
        valid_node,
        weights_to_net!

    include("common.jl")
    include("tree.jl")
    include("decision_tree.jl")
    include("bart.jl")
    include("metrics.jl")
    include("neural_net.jl")
    include("partial.jl")
    include("pipeline.jl")
    include("random_forest.jl")
    include("split.jl")
    include("transform/zmuv.jl")
    include("transform/hash.jl")
    include("importance.jl")
    include("experiment.jl")
    include("test_helpers.jl")
end