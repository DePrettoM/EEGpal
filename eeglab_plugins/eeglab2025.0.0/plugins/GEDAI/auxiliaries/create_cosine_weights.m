function [weights] = create_cosine_weights(channels, srate, epoch_size, fullshift)

%cosine weights to avoid overlaps for seamless re-contruction 
%%   Creative Commons License
%
%   Credits:  Abele Michela & Tomas Ros 
%             NeuroTuning Lab [ https://github.com/neurotuning ]
%             Center for Biomedical Imaging
%             University of Geneva
%             Switzerland
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.
cosine_weights=zeros(channels,srate*epoch_size);

    %creating the weights (depending on odd or even)
    if(fullshift) %even
        for e=1:channels %for each electrode
            for u=1:srate*epoch_size %for each sample in the epoch
                cosine_weights(e,u) = 0.5-0.5*cos(2*u*pi/(srate*epoch_size));
            end
        end
    else %odd
        for e=1:channels
            for u=1:srate*epoch_size-1
                cosine_weights(e,u) = 0.5-0.5*cos(2*u*pi/(srate*epoch_size-1));
            end
        end
    end
    weights = cosine_weights;
end