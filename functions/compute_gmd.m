function [GMD] = compute_gmd(dataset1)
% computediss: computes dissimilarity for a dataset
%
% inputs: data as 2-D numeric arrays where dimension 1 contains the
% timeframes, dimension 2 contains the channels
%
% outputs: diss and sc as 1-D numeric arrays that contain the
% dissimilarity
%
% Cartool: https://urldefense.com/v3/__http://brainmapping.unige.ch/Cartool.htm__;!!Dc8iu7o!3iOE0JZp0B1fvpl8cfOGdFf0oTmEZGrOgkDbFxvMUJOrWECvX-lm_U57IrgTpma7A1TAN97H6NDKxrpj3G2DplKbUyFZXeFuCLM$ 
%
% author of this script: pierre.megevand@medecine.unige.ch

% Update: 09.2024
% =========================================================================
%
% Computes dissimilarity
%
%
% INPUTS
% - 'dataset' 2D or 3D numeric array with
%   - dimension one: timeframes (or frequencies)
%   - dimension two: channels
%
% OUTPUTS
% - 'GMD' 1D numeric array. As the map of each TF is compare to the
% previous, the first value of GMD will be always 0 (as in Cartool)
%%
%
% Original author of this script: pierre.megevand@medecine.unige.ch
% Adapted by Michael De Pretto (Michael.DePretto@unige.ch) and Michael
% Mouthon (michael.mouthon@unifr.ch)
%
% =========================================================================


nTF = size(dataset1,1);
nChan = size(dataset1,2);

% GMD

GMD = zeros(nTF,1);
for tf = 2:nTF
    d1GFPi  = sqrt(sum((dataset1(tf-1,:) - mean(dataset1(tf-1,:))) .^2) ./ nChan);
    d1normi = dataset1(tf-1,:) ./ d1GFPi;
    d2GFPi  = sqrt(sum((dataset1(tf,:) - mean(dataset1(tf,:))) .^2) ./ nChan);
    d2normi = dataset1(tf,:) ./ d2GFPi;
    GMD(tf) = sqrt(sum(((d1normi - mean(d1normi)) - (d2normi - mean(d2normi))) .^2) ./ nChan);
end
