function Script_CLM_params_train_dyn_out()

% Change to your downloaded location
addpath('C:\liblinear\matlab')

num_test_folds = 27;

correlations = zeros(num_test_folds, 1);
RMS = zeros(num_test_folds, 1);

predictions = cell(num_test_folds, 1);

gt = cell(num_test_folds, 1);

%% load shared definitions and AU data
shared_defs_dyn;

% Set up the hyperparameters to be validated
hyperparams.c = 10.^(-6:1:3);
hyperparams.p = 2.^(-7:1:-1);

hyperparams.validate_params = {'c', 'p'};

% Set the training function
svr_train = @svm_train_linear;
    
% Set the test function (the first output will be used for validation)
svr_test = @svm_test_linear;

%%
for a=1:numel(aus)
    
    au = aus(a);
            
        %% use all but test_fold
        train_users = 1:num_test_folds;

        rest_aus = setdiff(all_aus, au);        
        
        % load the training and testing data for the current fold
        [train_samples, train_labels, valid_samples, valid_labels, raw_valid, means, scaling] = Prepare_CLM_AU_data(users(train_users), au, rest_aus, clm_data_dir);
        
        train_samples = sparse(train_samples);
        valid_samples = sparse(valid_samples);
        
        %% Cross-validate here                
        [ best_params, ~ ] = validate_grid_search(svr_train, svr_test, false, train_samples, train_labels, valid_samples, valid_labels, hyperparams);
                        
        model = svr_train(train_labels, train_samples, best_params);        

        [~, prediction] = svr_test(valid_labels, valid_samples, model);
    
        % Go from raw data to the prediction
        data_norm = bsxfun(@times, bsxfun(@plus, raw_valid, -means), 1./scaling);
        data_norm(data_norm < -3) = -3;
        data_norm(data_norm > 3) = 3;
        
        w = model.w(1:end-1)';
        b = model.w(end);
    
        svs = w;
        
        % Attempt own prediction
        preds_mine = data_norm * svs + b;
        preds_mine(preds_mine <0) = 0;
        preds_mine(preds_mine >5) = 5;
        
        assert(norm(preds_mine - prediction) < 1e-8);
                
        name = sprintf('trained_10_28/AU_%d_geom.dat', au);
        
        write_geom_lin_dyn_svr(name, means, scaling, svs, b);
        
        name = sprintf('trained_10_28/AU_%d_geom.mat', au);
        
        [ accuracies, F1s, corrs, rms, classes ] = evaluate_classification_results( prediction, valid_labels );    
        
        save(name, 'accuracies', 'F1s', 'corrs', 'rms');        

end

end

function [model] = svm_train_linear(train_labels, train_samples, hyper)
    comm = sprintf('-s 11 -B 1 -p %f -c %f -q', hyper.p, hyper.c);
    model = train(train_labels, train_samples, comm);
end

function [result, prediction] = svm_test_linear(test_labels, test_samples, model)

    prediction = predict(test_labels, test_samples, model);
    prediction(prediction<0)=0;
    prediction(prediction>5)=5;
    % using the average of RMS errors
%     result = mean(sqrt(mean((prediction - test_labels).^2)));  
    result = corr(test_labels, prediction);
    
    if(isnan(result))
        result = 0;
    end
    
end
