%=========================================================================%
% Requisite Scripts
%=========================================================================%
% 1) add SI_toolbox
cod_dir='F:\Data2\Geib\SI_github\SI_toolbox'; addpath(cod_dir);
%-----------------------------------------------------------------%
% Inputs
%-------------------------------------------------------------------------%
%   R(subject X posterior probability X to-be-decoded stimulus)
%   -> generated with SI_MVPA_v3()
%   RSA{matrix #}.
%       .model(stimuli X stimuli)    : similarity matrix
%       .name(str)                   : user defined name for the matrix
%       .CIND                        : see below
%           CIND == 0 : just output corr value
%           CIND == 1 : within category 2nd order corr
%           CIND == 2 : within category mean
%           -> none of these effect trial wise values
%       ***can also be left empty ([])
%   PLOT
%       .on                          : plot stuff
%           figure(1): Within category similarity                
%           figure(2): Posterior prob (on/off)
%               -> bars on {All On, All Off, w/in On, w/in Off}
%           figure(3): Accuracy > 50%
%       ***if plotting is turned on, output is not generated (i.e. FRAME)
%       ***if plotting is turned off, then the full statistical routine
%       runs and the following output is provided... 
%           zID   -> post-prob > chance
%           ACC50 -> Accuracy > 50
%           ACC1  -> Accuracy > (1/number stimuli)
%           RSA results
%           -> these results are also saved to output parameters
%   TrialOn(logical)
%       -> if on, then we output trialwise values as well
%   CAT
%       .CIND(Stimuli X 1)           : category index for stimuli
%       .name(cell str)              : name for the category index
%       -> for example
%           .CIND = [1 1 1 2 2 2];
%           .name = {Birds, Mammals};
%           -> indicates that we have 2 categories, 1=Birds, 2=Mammals
%       ***if don't care about category stuff, just leave this empty ([])
%-------------------------------------------------------------------------%
% Outputs
%-------------------------------------------------------------------------%
% FRAME.[ALL | CIND] : CIND refers to w/in category, whereas ALL refers to
% with respect to all items
%   .header {zID, ACC50, ACC1, RSA_values}
%   .data(subject X header)
%   -> this variable has all the single-subject data, if there are
%   categories, then zID = czID
%   -> CIND data is also wrt the individual categories, thus the rows in
%   .data are = # subjects X # categories where the results are grouped by
%   subject and then category
%
% SIMPLE : basic t-test results derived from SIMPLE data
%   .header is the same as FRAME but with suffixes for (u, std, T and
%   p-value) based upon subject-wise t-test (this is based upon 'all' data
%   -> see CEXL for category data
%   .data (1 x header)
%
% TRIAL : has category specific data
%   .header
%       .subject  -> subject number
%       .Trial    -> trial (stimulus) number
%       .Category -> category number
%       .zID      -> post-prob
%       .zIDwCat  -> post-prob w/in category
%       .Y50      -> Accuracy > 50
%       .cY50     -> Accuracy > 50 w/in category
%       .RSA      -> all RSA trial-wise values
%   .data(data X header)
%
% CEXL : is the same as SIMPLE but with category values
%
% If no category structure exists, then all the category results are just
% left out.

[FRAME,SIMPLE,TRIAL,CEXL]=SI_analysis_MVPA_v3(R,RSA.STAMP,PLOT,true,CAT); 

