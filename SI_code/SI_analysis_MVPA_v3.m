%-------------------------------------------------------------------------%
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

function [FRAME,SIMPLE,TRIAL,CEXL]=SI_analysis_MVPA_v3(R,RSA,PLOT,trialON,CAT)
% -> zID values
% -> ACC 1 values
% -> ACC 1/2 values
% -> RSA fit values 
% --> values are mean, std, t, p
%=========================================================================%
% Initialize higher level variables
%=========================================================================%
% Initialize outputs
TRIAL=[]; CEXL=[]; 
FRAME=[]; SIMPLE=[];

if ~isempty(CAT)
    CIND=CAT.CIND;
else 
    CIND=[];
end

Nsubj=size(R,1);  % number subjects
Ntrial=size(R,2); % number of trials
EYE=logical(eye(Ntrial,Ntrial));
if ~isempty(CIND)
    cEYE=NaN(Ntrial,Ntrial);
    for ii=1:length(unique(CIND))
        cEYE(CIND==ii,CIND==ii)=1;
    end
    countCIND=zeros(1,length(CIND));
    for ii=1:length(unique(CIND))
        countCIND(CIND==ii)=sum(CIND==ii);
    end
end
% EYE  (diagonal)
% cEYE (blocky diagonal for category)
% countCIND (number of items per category)
RSAmask=true(Ntrial,Ntrial);
% Include all values for RSA
%=========================================================================%
%% Pull some highlevel variables and gently process
%=========================================================================%
SubjR=R;
for ii=1:Nsubj
    %----------------------------%
    % Get Rank and Z
    %----------------------------%
    % if CIND exists, also get cRank and cZ for category
    Rank(ii,:)=SI_Rank(squeeze(R(ii,:,:)));
    pRank(ii,:)=Rank(ii,:)./Ntrial; % Propotional rank
    
    MESv=squeeze(R(ii,:,:)); % Subject specific confusion matrix
    
    Z(ii,:)=MESv(EYE)-1/Ntrial; % above chance
    Zoff(ii)=mean(MESv(~EYE));  % for plotting
    %----------------------------%
    % Get Rank and Z for category
    %----------------------------%
    if ~isempty(CIND)
        % Turn off category into NaN
        MESv=MESv.*cEYE; % Overwrite MESv, we clear it next anyways

        a1=MESv; a1(EYE)=NaN;
        for jj=1:Ntrial
            a2(jj)=nanmean(a1(:,jj));
        end
        % cZ: post-prob of match > than mismatch in the same category (a2)
        cZ(ii,:)=MESv(EYE)-a2'; clear a1 a2;
        % cZr: raw post-prob value
        cZr(ii,:)=MESv(EYE);
        
        E=cEYE; E(EYE)=0; E(isnan(E))=0;
        
        cZoff(ii)=mean(MESv(E==1));
        clear E;
        
        cSubjR(ii,:,:)=MESv; % save updated 
        
        % Category specific rank
        tRank=[]; tpRank=[]; cNEL=[];
        for cc=1:length(unique(CIND))
            [temp]=SI_Rank(MESv(CIND==cc,CIND==cc));    
            tRank=[tRank,temp];
            tpRank=[tpRank,temp./sum(CIND==cc)];
        end
        cRank(ii,:)=tRank;   % raw Rank
        cpRank(ii,:)=tpRank; % Category proportion rank  
        clear tRank tpRank;
    end
    clear MESv;
    %----------------------------%
    % Now check into RSA
    %----------------------------%
    if ~isempty(RSA)
        for aa=1:length(RSA)
            A=squeeze(SubjR(ii,:,:));  A=A(RSAmask);
            B=RSA{aa}.model;           B=B(RSAmask);
            kill=isnan(A) | isnan(B);
            RSA{aa}.val(ii)=corr(A(~kill),B(~kill),'type','Spearman');
            clear A B kill; 
            % Get trial wise values
            if trialON==1
                A=squeeze(SubjR(ii,:,:)); 
                B=RSA{aa}.model; 
                for bb=1:Ntrial
                    tA=A(:,bb);
                    tB=B(:,bb);
                    kill=isnan(tA) | isnan(tB);
                    RSA{aa}.tval(ii,bb)=corr(tA(~kill),tB(~kill),'type','Spearman');
                    clear tA tB kill;
                end
            end
            
            if RSA{aa}.CIND==1
                for bb=1:length(unique(CIND))
                    A=squeeze(cSubjR(ii,:,:)); A=A(CIND==bb,CIND==bb); A=A(RSAmask(CIND==bb,CIND==bb));
                    B=RSA{aa}.model(CIND==bb,CIND==bb);           B=B(RSAmask(CIND==bb,CIND==bb));
                    kill=isnan(A) | isnan(B);
                    RSA{aa}.cval(bb,ii)=corr(A(~kill),B(~kill),'type','Spearman');
                end
            elseif RSA{aa}.CIND==2
                for bb=1:length(unique(CIND))
                    % SubjR is correct, we wanna see the within class
                    % coherence here
                    A=squeeze(SubjR(ii,:,:)); A=A(CIND==bb,CIND==bb); A=A(RSAmask(CIND==bb,CIND==bb));
                    RSA{aa}.cval(bb,ii)=nanmean(nanmean(A));
                end
            end
        end
    end
end
%=========================================================================%
%% PlotFigures
%=========================================================================%
if PLOT.on
RIN=squeeze(mean(SubjR));
for ii=unique(CIND)'
    for jj=unique(CIND)'
        RIN2(ii,jj)=mean(mean(RIN(CIND==ii,CIND==jj)));
    end
end

figure(1); set(gcf,'color','w');
h=imagesc(RIN2); %,[(1/Ntrial),(1/Ntrial)*2]);
colormap('jet'); colorbar;
h.Parent.XTick=unique(CIND);
h.Parent.YTick=unique(CIND);
h.Parent.TickDir='out';
h.Parent.XTickLabel=CAT.name;
h.Parent.YTickLabel=CAT.name;
h.Parent.XTickLabelRotation=45;
h.Parent.XTick
set(gca,'fontsize',16); set(gca,'FontWeight','bold'); axis square;
%---------------------%
% Bar Plots
%---------------------%
Z1=nanmean(Z')+1/Ntrial;
Z2=Zoff;

Z1c=nanmean(cZr');
Z2c=cZoff;

bV=[mean(Z1),mean(Z2) mean(Z1c),mean(Z2c)];
blow=[std(Z1)/sqrt(Nsubj) std(Z2)/sqrt(Nsubj) std(Z1c)/sqrt(Nsubj) std(Z2c)/sqrt(Nsubj)];
bhigh=blow;
POS=[1 1.3 1.7 2.0];

figure(2); set(gcf,'color','w');
h=bar(POS,bV,...
    'EdgeColor',[0 0 0],...
    'LineWidth',1); hold on; ylabel('Class. Evid.');
h.FaceColor='flat';
h.Parent.TickDir='out';

er=errorbar(POS,bV,blow,bhigh);
er.Color=[0 0 0]; 
er.LineStyle='none';
er.LineWidth=2;
D=max(bV)-min(bV); AX=[min(bV)-min(blow) max(bV)+max(blow)*2];
set(gca,'YLim',[AX(1)-diff(AX)/2 AX(2)]);
set(gca,'fontsize',16); set(gca,'FontWeight','bold'); 
h.Parent.XTick=[];
h.Parent.XLim=[0.8 2.2];

clear D AX;
%---------------------%
% Accuracy Plots
%---------------------%
c=1; Lr=0.05:0.025:0.5;
for L=Lr
    RANK2c=(cpRank<=L); 
    RANK2a=(pRank<=L);
    Vc(c)=mean(mean(RANK2c')); 
    Va(c)=mean(mean(RANK2a')); 
    
    Ec(c)=std(mean(RANK2c'))/sqrt(Nsubj);
    Ea(c)=std(mean(RANK2a'))/sqrt(Nsubj);

    Chance(c)=L;
    
    clear RANK2* t;
    c=c+1;
end

figure(3); set(gcf,'color','w');
errorbar(Lr,Va,Ea,'bo-','color',[.9 .9 .9]); hold on;
errorbar(Lr,Vc,Ec,'bo-','color',[.8 .8 .8]); hold on;
plot(Lr,Chance,'color',[.7 .7 .7],'linewidth',3,'linestyle','--');
xlabel('Chance'); ylabel('Accuracy'); hold on;
set(gca,'XLim',[Lr(1) Lr(end)]);
set(gca,'fontsize',16); set(gca,'FontWeight','bold'); 
legend({'All Items','w/in Category'},'Location','SouthEast');
grid; grid;
   
return;

end
%=========================================================================%
%% Pull trialwise estimates
%=========================================================================%
if trialON
    % Need to initialize structure a tad
    TC=1; c=1;
    if ~isempty(CIND)
        TRIAL.header{TC}='Subject';
        TRIAL.header{TC+1}='Trial';
        TRIAL.header{TC+2}='Category';
        TRIAL.header{TC+3}='zID';
        TRIAL.header{TC+4}='zIDwCat';
        TRIAL.header{TC+5}='Y50';
        TRIAL.header{TC+6}='cY50';
        for ii=1:length(RSA)
            TRIAL.header{TC+6+ii}=RSA{ii}.name;
        end
    else
        TRIAL.header{TC}='Subject';
        TRIAL.header{TC+1}='Trial';
        TRIAL.header{TC+2}='zID'; 
        TRIAL.header{TC+3}='Y50';
         for ii=1:length(RSA)
            TRIAL.header{TC+3+ii}=RSA{ii}.name;
        end
    end
    
    for ii=1:Nsubj
        for jj=1:Ntrial
            if ~isempty(CIND)
                TRIAL.data(c,TC)=ii;
                TRIAL.data(c,TC+1)=jj;
                TRIAL.data(c,TC+2)=CIND(jj);
                TRIAL.data(c,TC+3)=Z(ii,jj);
                TRIAL.data(c,TC+4)=cZ(ii,jj);
                TRIAL.data(c,TC+5)=pRank(ii,jj);
                TRIAL.data(c,TC+6)=cpRank(ii,jj);
                for aa=1:length(RSA)
                    TRIAL.data(c,TC+6+aa)=RSA{aa}.tval(ii,jj);
                end
                c=c+1;
            else
                TRIAL.data(c,TC)=ii;
                TRIAL.data(c,TC+1)=jj;
                TRIAL.data(c,TC+2)=Z(ii,jj);
                TRIAL.data(c,TC+3)=pRank(ii,jj);
                for aa=1:length(RSA)
                    TRIAL.data(c,TC+3+aa)=RSA{aa}.tval(ii,jj);
                end
                c=c+1;
            end
        end
    end   
end
%=========================================================================%
%% Now we can proceed to figuring out more stuff
%=========================================================================%
% IMPORTANT NOTE
% -> all zvalues (which are now post. prob.) are corrected for the number
% of trials s.t. post. prob. > 0 are above chance
%
% Key variables here
% (c)Rank  (subject X trial)
% (c)Z     (subject X trial)
% (c)SubjR (subject X trial X trial)
%
% For the MVPA paper we need to know
% -> zID values
% -> ACC 1 values
% -> ACC 1/2 values
% -> RSA fit values 
% --> values are mean, std, t, p
% FRAME.CIND, FRAME.ALL, SIMPLE
IX=0; % Counter for SIMPLE
FA=1; % Counter for FRAME.ALL
FC=1; % Counter for FRAME.CIND
FX=0; % Counter for CEXL
% each of these has fields for data and header
%-------------------------------------------------------------------------%
% zID values
%-------------------------------------------------------------------------%
[~,p,~,stat]=ttest(nanmean(Z'));
display([' zID = ' num2str(mean(nanmean(Z'))) ' : p = ' num2str(p) ' / T = ' num2str(stat.tstat)]);

fn='zID_';
SIMPLE.data(IX+1)=nanmean(nanmean(Z')); SIMPLE.header{IX+1}=[fn 'u'];
SIMPLE.data(IX+2)=nanstd(nanmean(Z'));  SIMPLE.header{IX+2}=[fn 'std'];
SIMPLE.data(IX+3)=stat.tstat;           SIMPLE.header{IX+3}=[fn 'T'];
SIMPLE.data(IX+4)=p;                    SIMPLE.header{IX+4}=[fn 'p'];
IX=IX+4;

if ~isempty(CIND)
    fn='czID_';
    [~,p,~,stat]=ttest(nanmean(cZ'));      CEXL.header{FX+1}=[fn 'u'];
    CEXL.data(FX+1)=nanmean(nanmean(cZ')); CEXL.header{FX+2}=[fn 'std'];
    CEXL.data(FX+2)=nanstd(nanmean(cZ'));  CEXL.header{FX+3}=[fn 'T'];
    CEXL.data(FX+3)=stat.tstat;            CEXL.header{FX+4}=[fn 'p'];
    CEXL.data(FX+4)=p; 
    FX=FX+4;
    clear p stat;
end
% If CIND exist, ALL header will be labeled as czID instead of zID    
FRAME.ALL.data(:,FA)=nanmean(Z');  FRAME.ALL.header{FA}=fn(1:end-1); FA=FA+1;

if ~isempty(CIND)
    FC2=1;
    FRAME.CIND.header{FC}=fn;
    for aa=1:Nsubj
        for bb=1:length(unique(CIND))
            FRAME.CIND.data(FC2,FC)=nanmean(cZ(aa,CIND==bb)');
            FC2=FC2+1;
        end
    end
    FC=FC+1;
end
%-------------------------------------------------------------------------%
% ACC values
%-------------------------------------------------------------------------%  
%--------------%
% All trials
%--------------%
for L=1:Ntrial/2
    RANK2=(Rank<=L); 
    V(L)=mean(mean(RANK2')); BX(L)=(L/(Ntrial));
    S(L,:)=mean(RANK2');
    E(L)=std(mean(RANK2'))/sqrt(Nsubj);
    [~,p(L),~,t]=ttest(mean(RANK2')-L/(Ntrial));
    T(L)=t.tstat;
    clear RANK2 t;
end

display([' ACC50 = ' num2str(V(end)) ' : p = ' num2str(p(end))]);
display([' ACC1 = ' num2str(V(1)) ' : p = ' num2str(p(1))]);

fn='ACC50_';
SIMPLE.data(IX+1)=V(end); SIMPLE.header{IX+1}=[fn 'u'];   
SIMPLE.data(IX+2)=E(end); SIMPLE.header{IX+2}=[fn 'std'];   
SIMPLE.data(IX+3)=T(end); SIMPLE.header{IX+3}=[fn 'T'];
SIMPLE.data(IX+4)=p(end); SIMPLE.header{IX+4}=[fn 'p'];   
IX=IX+4;

FRAME.ALL.data(:,FA)=S(end,:); FRAME.ALL.header{FA}=fn(1:end-1);
FA=FA+1;

fn='ACC1_';
SIMPLE.data(IX+1)=V(1);  SIMPLE.header{IX+1}=[fn 'u'];   
SIMPLE.data(IX+2)=E(1);  SIMPLE.header{IX+2}=[fn 'std'];    
SIMPLE.data(IX+3)=T(1);  SIMPLE.header{IX+3}=[fn 'T'];   
SIMPLE.data(IX+4)=p(1);  SIMPLE.header{IX+4}=[fn 'p'];   
IX=IX+4;

FRAME.ALL.data(:,FA)=S(1,:); FRAME.ALL.header{FA}=fn(1:end-1);
FA=FA+1;
%--------------%
% CIND
%--------------%
if ~isempty(CIND)
    FRAME.CIND.header{FC}='ACC50';
    FRAME.CIND.header{FC+1}='ACC1';
    FC2=1;    
    for ii=1:Nsubj
        for aa=1:length(unique(CIND))
            tI=(CIND==aa);
            tR=cRank(ii,tI); 
            % Likelihood =>
            % (sum(Rank < X) / # items) / expectation of Rank < X
            t1(aa)=sum(tR==1)/length(tR)-(1/length(tR));
            t50(aa)=sum(tR<=(length(tR)/2))/length(tR)-0.5;
            % Sloppy, but works fine
            FRAME.CIND.data(FC2,FC)=t50(aa);
            FRAME.CIND.data(FC2,FC+1)=t1(aa);
            FC2=FC2+1;
            clear tI tR
        end
        ct1(ii)=mean(t1);
        ct50(ii)=mean(t50);
        clear t1 t50;
    end
    fn='cACC50';
    [~,p,~,stat]=ttest(ct50);      CEXL.header{FX+1}=[fn 'u'];
    CEXL.data(FX+1)=nanmean(ct50); CEXL.header{FX+2}=[fn 'std'];
    CEXL.data(FX+2)=nanstd(ct50);  CEXL.header{FX+3}=[fn 'T'];
    CEXL.data(FX+3)=stat.tstat;            CEXL.header{FX+4}=[fn 'p'];
    CEXL.data(FX+4)=p; 
    FX=FX+4;
    clear p stat ct50;
    
    fn='cACC1';
    [~,p,~,stat]=ttest(ct1);      CEXL.header{FX+1}=[fn 'u'];
    CEXL.data(FX+1)=nanmean(ct1); CEXL.header{FX+2}=[fn 'std'];
    CEXL.data(FX+2)=nanstd(ct1);  CEXL.header{FX+3}=[fn 'T'];
    CEXL.data(FX+3)=stat.tstat;            CEXL.header{FX+4}=[fn 'p'];
    CEXL.data(FX+4)=p; 
    FX=FX+4;
    clear p stat ct50;
    
    FC=FC+2;
end
%-------------------------------------------------------------------------%
% RSA
%-------------------------------------------------------------------------%  
if ~isempty(RSA)
     for aa=1:length(RSA)
        [~,p,~,stat]=ttest(atanh(RSA{aa}.val));
        display([' ' RSA{aa}.name ' ' num2str(nanmean(RSA{aa}.val)) ' : p = ' num2str(p)]);
        
        FRAME.ALL.data(:,FA)=atanh(RSA{aa}.val); 
        FRAME.ALL.header{FA}=RSA{aa}.name;
        FA=FA+1;
        
        SIMPLE.data(IX+1)=mean(atanh(RSA{aa}.val)); SIMPLE.header{IX+1}=[RSA{aa}.name '_u'];   
        SIMPLE.data(IX+2)=std(atanh(RSA{aa}.val));  SIMPLE.header{IX+2}=[RSA{aa}.name '_std'];   
        SIMPLE.data(IX+3)=stat.tstat;               SIMPLE.header{IX+3}=[RSA{aa}.name '_T'];   
        SIMPLE.data(IX+4)=p;                        SIMPLE.header{IX+4}=[RSA{aa}.name '_p'];   
        IX=IX+4;
        
        if RSA{aa}.CIND
            FC2=1;
            FRAME.CIND.header{FC}=[RSA{aa}.name];   
            for ii=1:Nsubj
                for bb=1:length(unique(CIND))
                    FRAME.CIND.data(FC2,FC)=RSA{aa}.cval(bb,ii);
                    FC2=FC2+1;
                end
            end
            FC=FC+1;
        end
    end
end  
