%=========================================================================%
%% Inputs
%=========================================================================%
%------------------------------%
% MVPA subject settings
%------------------------------%
% SI.subject{X}.vox.dat.[Y](voxels X trials)
%   -> this variable has each subjects (X) brain data [feature X trial]
%   where feature most likely refers to voxels. Trial is based upon
%   stimulus, not trial temporal order. The algorithm assumes that all 
%   subjects have had the trial dimension sorted such that the trials align 
%   across subjects, e.g., trial one for all subjects should be a picture 
%   of cardinal
%   -> [Y] is an additional field name that permits a single-subject to
%   have multiple datasets loaded. This was used for cross-modal decoding
%   (i.e. training on pictures testing on words). When setting up the
%   classifier you have the option to choose modl (triaing) and data
%   (testing). The inputs into this are Y. For example, if you wanted to
%   train on pictures and test on words then...
%       SI.subject{X}.vox.picture(voxels X trials)
%       SI.subject{X}.vox.word(voxels X trials)
%       SI.DR.modl='picture';  % trian on pictures
%       SI.DR.data='word';     % test on words
%------------------------------%
% MVPA model settings
%------------------------------%
% SI.MVPA.save(str)              Where to save data output
% SI.MVPA.lambda(double)         Lambda hyperparameter for logistic regression
% SI.MVPA.model(str)             'LogOVA' -> logisitc regression (one vs all)
%   -> this is the only option available at the moment
% SI.MVPA.debias.train(logical)   handle to debias training data
% SI.MVPA.debias.test(logical)    handle to debias testing data
% SI.MVPA.save(str)               output directory to svae data
%=========================================================================%
%% Outputs (saved to SI.MVPA.save)
%=========================================================================%
% R(subject X posterior probability X to-be-decoded stimulus)
%   If we examine a single subject (posterior probability X stimulus) then
%   -> the rows pertain to liklihood whereas as the columns refer to the
%   to-be-decoded stimulus. As such cell (4,8) refers to the probability
%   that to-be-decoded stimulus 8 is stimulus 4. The posterior probability
%   must sum to 1, because of this, the sum of each column is 1.
%   -> this is the confusion matrix for each subject and serves as input
%   into SI_analysis_MVPA_v3
% (N-1)=X logistic regression results
%   -> temp_sav_str=[mdl_sav_str(1:end-4) '_N' num2str(X) '.mat'];

function SI_MVPA_v3()
global SI;
%-------------------------------------------------------------------------%
%% Impliment default values
%-------------------------------------------------------------------------%
% If values are not a priori defined, some of these are auto-set
if ~isfield(SI.MVPA,'lambda'), SI.MVPA.lambda=100; end
if ~isfield(SI.MVPA,'model'),  SI.MVPA.model='LogOVA'; end
if ~isfield(SI.MVPA,'debias'), SI.MVPA.debias.train=true; SI.MVPA.debias.test=true; end
% Setup save strings based upon MVPA model parameters
lambda_str=['_lambda' num2str(SI.MVPA.lambda*100)];
train_str=['_debiasTrain' num2str(SI.MVPA.debias.train)];
test_str=['_debiasTest' num2str(SI.MVPA.debias.test)];

sav_str=fullfile(SI.MVPA.save,[SI.DR.modl 'to' SI.DR.data '_' SI.MVPA.model,...
    lambda_str train_str test_str '.mat']);
% Testing doesn't matter for the mdl, as the mdl is based purely on
% training data. This accelerates cross-modal training, as we can use the
% same trained model regardless of what the testing set is
mdl_sav_str=fullfile(SI.MVPA.save,[SI.DR.modl 'to' SI.DR.data '_' SI.MVPA.model,...
    lambda_str train_str '.mat']);

disp([SI.DR.modl 'to' SI.DR.data '_' SI.MVPA.model,...
    lambda_str train_str test_str]);
clear lambda_str train_str test_str;
%-------------------------------------------------------------------------%
%% Analysis
%-------------------------------------------------------------------------%
% Execute code if an existing save file doesn't exist
RUN=false; % if set to true, will overwrite existing data
if (~exist(sav_str,'file') || RUN)
    
N=size(SI.subject{1}.vox.dat.(SI.DR.modl),2);   % Number of train items
N2=size(SI.subject{1}.vox.dat.(SI.DR.data),2);  % Number of test items

% Initialize data matrices
VOXTrain=[]; VOXTest=[]; S=[]; S2=[];
% Setup response vector, assume data is properly aligned. Stimuli are
% numbered based upon matrix position
Y=repmat(1:N,[1 length(SI.subject)]);    % Training labels
Y2=repmat(1:N2,[1 length(SI.subject)]);  % Testing labels

% Load in subject data, this is redundant if training and testing on the
% same set, but the code calls for less exceptions, so heres to hoping you
% have lots of RAM
for ii=1:length(SI.subject)
    VOXTrain=[VOXTrain, SI.subject{ii}.vox.dat.(SI.DR.modl)(:,1:N)];
    VOXTest=[VOXTest, SI.subject{ii}.vox.dat.(SI.DR.data)(:,1:N2)];
    % Subject variable
    S=[S ones(1,N)*ii];
    S2=[S2 ones(1,N2)*ii];
end
VOXTrain=VOXTrain'; VOXTest=VOXTest';

% Quick detection for missing (NaN) volumes
Miss.Train=isnan(nanmean(VOXTrain,2));
if sum(Miss.Train)>0
    disp('Warning items removed from training set');
    VOXTrain(Miss.Train,:)=[];
    S(Miss.Train)=[];
    Y(Miss.Train)=[];
end
Miss.Test=isnan(nanmean(VOXTest,2));
if sum(Miss.Test)>0
    disp('Warning items removed from testing set');
    VOXTest(Miss.Test,:)=[];
    S2(Miss.Test)=[];
    Y2(Miss.Test)=[];
end

% Remove NaN voxels
kill=(isnan(mean(VOXTrain)) | isnan(mean(VOXTest))); I=~kill;
% Save an index of removed voxels -> this allows for the option of
% translating model-weights back to voxel indices
save(fullfile(SI.MVPA.save,['GoodVoxels_' SI.DR.modl SI.DR.data '.mat']),'I'); clear I;

VOXTrain(:,kill)=[]; % Clear NaNs
VOXTest(:,kill)=[]; % Clear NaNs
%-------------------------------------------------------------------------%
% VOX (observations X features)
% Y   (1 X observations)
% S   (1 X subject)
% -> Y2 and S2 are just the test set
% -> VOX is divided into Train and Test
%-------------------------------------------------------------------------%
% Apply debiasing if needed
VOXTrain_de=[];
VOXTest_de=[];
for ii=1:length(SI.subject)
    if SI.MVPA.debias.train
        debias=SI_debias(double(VOXTrain(S==ii,:)));
        VOXTrain_de=[VOXTrain_de, debias']; clear debias;
    end
    if SI.MVPA.debias.test
        debias=SI_debias(double(VOXTest(S2==ii,:)));  
        VOXTest_de=[VOXTest_de, debias']; clear debias;
    end
end
% Apply debiasing if needed
if SI.MVPA.debias.test, VOXTest=VOXTest-VOXTest_de'; clear VOXTest_de; end
if SI.MVPA.debias.train, VOXTrain=VOXTrain-VOXTrain_de'; clear VOXTrain_de; end
%=========================================================================%
%% MVPA analysis
%=========================================================================%
% Leave-one-person-out (LOPO) analysis
for ii=1:length(SI.subject)
    disp([' Subject #' num2str(ii) ': Logistic OVA']);
    
    % Model parameters for left out subject
    temp_sav_str=[mdl_sav_str(1:end-4) '_N' num2str(ii) '.mat'];

    % Setup input variables for left out subject
    TRAIN=double(VOXTrain(S~=ii,:));
    TEST=double(VOXTest(S2==ii,:));    
    LABEL=Y(S~=ii);

    % Predefine output indices as well
    TRAIN_Label=unique(LABEL);  
    TEST_Label=Y2(S2==ii);     
    % And posteriors
    outPosterior=NaN(N2,N);
    
    %---------------------------------------------------------------------%
    % Logistic (onevsall)
    %---------------------------------------------------------------------%
    tic
    
    % Run model if it hasn't already been done
    if ~exist(temp_sav_str,'file')
        t=templateLinear('Learner','logistic','Lambda',SI.MVPA.lambda,'Regularization','ridge'); % ?
        Mdl=fitcecoc(TRAIN,LABEL,'FitPosterior',1,'Learner',t,'Coding','onevsall'); % This is slow
        save(temp_sav_str,'Mdl'); % Save the model to make pretty pictures
    else
        load(temp_sav_str,'Mdl');
    end
    % Get the posteriors for the test data
    [~,~,~,Posterior]=predict(Mdl,TEST); % This is slower than I'd expect

    % Save into existing NaN matrix (accounts for missing trials*)
    outPosterior(TEST_Label,TRAIN_Label)=Posterior;
    clear Mdl label Posterior;
    
    toc % Keep time stamps for user

    % Posterior (Trial X (liklihood class A)) -> sum(P,2)=1;
    % So we transpose this so rows are liklihood of classes
    R(ii,:,:)=outPosterior';
end

save(sav_str,'R');

else
    disp('Complete');
end














