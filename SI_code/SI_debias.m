function debias=SI_debias(data)

debias=ones(size(data));
a1=nanmean(data,1); a3=(a1-nanmean(a1))./nanstd(a1)'; a4=a1+a3.*nanstd(a1); 
b1=nanmean(data,2); b3=(b1-nanmean(b1))./nanstd(b1)'; b4=b1+b3.*nanstd(b1);
debias=(debias.*repmat(a4,[size(data,1),1]).*0.5)+...
    (debias.*repmat(b4,[1,size(data,2)]).*0.5);
