function [Rank]=SI_Rank(IN)

for kk=1:size(IN,2)
    V=IN(:,kk); 
    u=tiedrank(-V); % so we descend
    Rank(kk)=u(kk);      
end   
