% MODIFIED VERSION OF pop_cleanline() FOR USE WITH EEGpalCS APP
% Grouped with arg_guidialog() into one function.
% Opens the original option gui and provides a structure with the selected
% options as an output, instead of running the plugin
%
% Only for cleanLineNoise.m
%
% Update 02.2021, Michael.DePretto@unifr.ch
% =========================================================================


% ORIGINAL DESCRIPTION:
% Mandatory             Information
% --------------------------------------------------------------------------------------------------
% EEG                   EEGLAB data structure
% --------------------------------------------------------------------------------------------------
%
% Optional              Information
% --------------------------------------------------------------------------------------------------
% Type 'doc cleanline' for additional arguments
%
% See Also: cleanline()

% Author: Tim Mullen, SCCN/INC/UCSD Copyright (C) 2011
% Date:   Nov 20, 2011
%
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function CL_options = EEGpalCS_pop_cleanline(CL_options)

% UI list...
uilist =    {...
    {'style' 'text' 'string' 'Line noise frequencies to remove' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' num2str(CL_options.lineFrequencies(1)) 'tag' 'linefreqs' } ...
    ...
    {'style' 'text' 'string' 'Bandwidth (Hz)' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' num2str(CL_options.fScanBandWidth) 'tag' 'bandwidth' 'tooltipstring' wordwrap('This is the width of a spectral peak for a sinusoid at fixed frequency. As such, this defines the multi-taper frequency resolution.',80) } ...
    ...
    {'style' 'text' 'string' 'Indices of Channels to clean' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' CL_options.lineNoiseChannels 'tag' 'chanlist' } ...
    ...
    {'style' 'text' 'string' 'p-value for detection of significant sinusoid' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '0.01' 'tag' 'p' } ...
    ...
    {'style' 'text' 'string' 'Taper bandwidth' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '2' 'tag' 'taperbandwidth' } ...
    ...
    {'style' 'text' 'string' 'Sliding window length (sec)' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '0' 'tag' 'winsize' 'tooltipstring' wordwrap('Default for epoched data is the epoch length. Default for continuous data is 4 seconds.',80) } ...
    ...
    {'style' 'text' 'string' 'Sliding window step size (sec)' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '0' 'tag' 'winstep' 'tooltipstring' wordwrap('This determines the amount of overlap between sliding windows.Default for epoched data is window length (no overlap). Default for continuous data is 1 second.',80) } ...
    ...
    {'style' 'text' 'string' 'Window overlap smoothing factor' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '100' 'tag' 'tau' 'tooltipstring' wordwrap('A value of 1 means (nearly) linear smoothing between adjacent sliding windows.A value of Inf means no smoothing. Intermediate values produce sigmoidal smoothing between adjacent windows.',80) } ...
    ...
    {'style' 'text' 'string' 'FFT padding factor' 'fontweight' 'bold' } ...
    {'style' 'edit' 'string' '2' 'tag' 'pad' 'tooltipstring' wordwrap('Signal will be zero-padded to the desired power of two greater than the sliding window length. The formula is NFFT = 2^nextpow2(SlidingWinLen*(PadFactor+1)). e.g., For N = 500, if PadFactor = -1, we do not pad; if PadFactor = 0, we pad the FFT to 512 points, if PadFactor=1, we pad to 1024 points etc.',80) } ...
    };

% create an inputgui() dialog...
buttons = [];
geometry = repmat({[0.6 0.35]},1,length(uilist)/2+length(buttons)/2);
geomvert = ones(1,length(uilist)/2+length(buttons)/2);

[~,~,okpressed,outs] = inputgui('geometry',geometry, 'uilist',uilist,...
    'title','CleanLine Options','geomvert',geomvert);

% Prepare for CleanLineNoise
if ~isempty(okpressed)
    CL_options.lineFrequencies      = str2double(outs.linefreqs);
    CL_options.fScanBandWidth       = str2double(outs.bandwidth);
    CL_options.lineNoiseChannels    = outs.chanlist;
    CL_options.p                    = str2double(outs.p);
    CL_options.pad                  = str2double(outs.pad);
    CL_options.taperBandWidth       = str2double(outs.taperbandwidth);
    CL_options.taperWindowSize      = str2double(outs.winsize);
    CL_options.taperWindowStep      = str2double(outs.winstep);
    CL_options.tau                  = str2double(outs.tau);


    % Set default values if field not already set
    if length(CL_options.lineFrequencies) == 1
        lf = CL_options.lineFrequencies;
        CL_options.lineFrequencies = [ lf 2*lf 3*lf 4*lf ];
    end
    rmFreq = CL_options.lineFrequencies > CL_options.Fs/2;
    CL_options.lineFrequencies(rmFreq) = [];
else
    return
end


% 06/22/2018 Makoto. Disabled.
%
% if ~isempty(Sorig)
%     
%     % plot the original and cleaned spectra
%     eegplot(Sorig,'data2',Sclean, ...
%         'title',sprintf('Original and Cleaned %s spectra for selected %s',fastif(g.normSpectrum,'normalized',''),g.sigtype),'srate',length(f)/f(end), ...
%         'winlength',f(end),'submean','on'); %,'trialstag',1/length(f));
%     
%     ax = findobj(gcf,'tag','eegaxis');
%     xlabel(ax,'Frequency (Hz)');
%     title(ax,sprintf('Original and Cleaned %s spectra for selected %s',fastif(g.normSpectrum,'normalized',''),g.sigtype));
%     set(ax,'Yticklabel',[{''}; cellstr(num2str(g.chanlist(end:-1:1)'))]);
%     %     set(ax,'Xtick',1:10:length(f));
%     %     set(ax,'Xticklabel',f(1:10:end));
%     plts = get(ax,'children');
%     legend([plts(end) plts(1)],'original','cleaned');
%     
% end



% From pop_clean_rawdata()
function outtext = wordwrap(intext,nChars)
outtext = '';    
while ~isempty(intext)
    if length(intext) > nChars
        cutoff = nChars+find([intext(nChars:end) ' ']==' ',1)-1;
        outtext = [outtext intext(1:cutoff-1) '\n']; %#ok<*AGROW>
        intext = intext(cutoff+1:end);
    else 
        outtext = [outtext intext];
        intext = '';
    end
end
outtext = sprintf(outtext);