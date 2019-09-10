%=========================================================================%
% Requisite Scripts
%=========================================================================%
% 1) add SI_toolbox
cod_dir='F:\Data2\Geib\SI_github\SI_toolbox'; addpath(cod_dir);
% 2) declare global variable SI
global SI; 
%=========================================================================%
%% SI_shell
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
SI.subject{1}.vox.dat.picture=[];
SI.subject{1}.vox.dat.word=[];
SI.DR.modl='picture'; SI.DR.data='word'; 
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
SI.MVPA.save=fullfile(wrk_dir,'SID_analysis','MVPA_local','vX');
SI.MVPA.lambda=0.05;          
SI.MVPA.model='LogOVA';
SI.MVPA.debias.train=true;
SI.MVPA.debias.test=true;
SI.MVPA.save=fullfile(wrk_dir,'SID_analysis','MVPA_local','vX');

SI_MVPA_v3();



