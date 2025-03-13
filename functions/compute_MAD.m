function mad = compute_MAD(inputVector)
%It computation is based on the
%following article: https://www.sciencedirect.com/science/article/pii/S0022103113000668
%This indice is to be better than the standard deviation because it is
%less sensible to outlier. The script assume that the data approximatively normaly distribute. 
%
% Input: a numerical vector
% Output: median absolute deviation (MAD)

%% compute MAD
k=1.4826; %assumption to have a normal distribution

inputVector=inputVector(:); %transform a multi dimensional matrix to a unidimentional vector

MedianData=median(inputVector);
sizedata=length(inputVector);

diffMed=zeros(sizedata,1);

for i=1:sizedata
    diffMed(i)=abs(inputVector(i)-MedianData);
end

mad=k*median(diffMed);
