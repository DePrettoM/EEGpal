function [spectrum,FreqAxis] = frequency_computation(method,thedata,SamplingRate,WinFct)

% Update: 01.2021
% =========================================================================
%
% Frequency
%
%
% INPUTS
% - 'method' is the type of frequency analysis to compute
%   - 'FFT', 'pwelch', or 'FFTA'
%   - pwelch calls on the Signal Processing Toolbox
% - 'data' 2D numeric array with
%   - dimension one represents time-frames
%   - dimension two represents the electrodes
% - 'SamplingRate' is what you think it is
% - (optional) 'WinFct' is for windowing the data (see MatLab help)
%   - 'hamming'
%   - 'hanning'
%   - 'hann'
%   - 'none' (default)
%
% OUTPUTS
% - 'spectrum' is the resulting power spectra as a 2D numeric array with
%   - dimension one represents the frequency bins
%   - dimension two represents the electrodes
% - 'FreqAxis' is a column vector with the frequency bins [Hz]
%
% EXTERNAL FUNCTION CALLED
% - ref_change.m
%
%
% Author: Michael De Pretto (Michael.DePretto@unifr.ch)
%
% =========================================================================


EpochSize = size(thedata,1);
FreqAxis = SamplingRate * (0:(EpochSize/2))' / EpochSize;


% Apply window function
if nargin > 3
    if strcmpi(WinFct,'hamming')
        taper = hamming(EpochSize);
    elseif strcmpi(WinFct,'hanning')
        taper = hanning(EpochSize);
    elseif strcmpi(WinFct,'hann')
        taper = hann(EpochSize);
    elseif strcmpi(WinFct,'none')
        taper = rectwin(EpochSize);
    else
        error(['Sorry, I don''t know this windowing function: ' WinFct]);
    end
else
    taper = rectwin(EpochSize);
end


%% FFT

if strcmpi(method,'FFT')
    
    thedata = ref_change(thedata,'avgref'); % apply average reference
    
    EPOCHfft = fft(taper .* thedata); % Compute the Fourier transform of each column (each electrode)
    RealImag = cat(3,real(EPOCHfft),imag(EPOCHfft)); % Decompose the real and imaginary parts
    N = vecnorm(RealImag(1:EpochSize/2+1,:,:),2,3); % Norm of the complex data (single-sided)
    
    spectrum = (N .^2) / EpochSize; % Power


%% Welch

elseif strcmpi(method,'pwelch')
    
    spectrum = pwelch(thedata,taper,[],EpochSize);


%% FFTA

elseif strcmpi(method,'FFTA')
    
    thedata = ref_change(thedata,'avgref'); % apply average reference
	
    EPOCHfft = fft(taper .* thedata); % Compute the Fourier transform of each column (each electrode)
    EPOCHfft = EPOCHfft(1:EpochSize/2+1,:); % single-sided spectrum
    
    RealPart = real(EPOCHfft); % Real part of the FFT
    ImagPart = imag(EPOCHfft); % Imaginary part of the FFT
	spectrum = zeros(size(EPOCHfft));
    
    for freq = 1:length(FreqAxis)
        
        X = [RealPart(freq,:)' ImagPart(freq,:)'];
        [~,score] = pca(X); % Projection of the real-imaginary scatterplot on the PCA components
        spectrum(freq,:) = score(:,1); % FFTA is the projection on the first component

    end
    spectrum = spectrum / sqrt(EpochSize); % Power
end