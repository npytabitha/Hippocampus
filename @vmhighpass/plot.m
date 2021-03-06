function [obj, varargout] = plot(obj,varargin)
%@vmhighpass/plot Plot function for vmhighpass object.
%   OBJ = plot(OBJ) creates a raster plot of the neuronal
%   response.

Args = struct('LabelsOff',0,'GroupPlots',1,'GroupPlotIndex',1,'Color','b', ...
			'PreTrial',500, 'NormalizeTrial',0, 'RewardMarker',3, ...
            'TimeOutMarker',4, 'PlotAllData',0, 'OldMarkerFormat2',0, ...
            'FreqPlot',0, 'RemoveLineNoise',[], 'LogPlot',0, ...
		    'FreqLims',[], 'TFfft',0, 'TFfftWindow',200, 'TFfftOverlap',150, ...
		    'TFfftPoints',256, ...
		    'TFWavelets',0,  ...
		    'ReturnVars',{''}, 'ArgsOnly',0);
Args.flags = {'LabelsOff','ArgsOnly','NormalizeTrial','FreqPlot','TFfft', ...
				'LogPlot','TFWavelet','PlotAllData','OldMarkerFormat2'};
[Args,varargin2] = getOptArgs(varargin,Args);

% if user select 'ArgsOnly', return only Args structure for an empty object
if Args.ArgsOnly
    Args = rmfield (Args, 'ArgsOnly');
    varargout{1} = {'Args',Args};
    return;
end

if(~isempty(Args.NumericArguments))
	% plot one data set at a time
	n = Args.NumericArguments{1};
	% find indices for n-th trial
	tIdx = obj.data.trialIndices(n,:);
	sRate = obj.data.analogInfo.SampleRate;
	if(Args.OldMarkerFormat2)
		idx = (tIdx(1)-(Args.PreTrial/1000*sRate)):tIdx(2);
	else
		idx = (tIdx(1)-(Args.PreTrial/1000*sRate)):tIdx(3);
	end
	if(Args.FreqPlot)
		if(Args.PlotAllData)
			data = obj.data.analogData;
		else
			data = obj.data.analogData(idx);
		end
		if(~isempty(Args.RemoveLineNoise))
			data = nptRemoveLineNoise(data,Args.RemoveLineNoise,sRate);
		end
		% remove the mean, i.e. DC component		
		datam = mean(data);			
		PlotFFT(data-datam,sRate);
		set(gca,'TickDir','out')
		if(Args.LogPlot)
			set(gca,'YScale','log')
		end
	elseif(Args.TFfft)
		if(Args.PlotAllData)
			% create memory to store overall mean
			if(Args.OldMarkerFormat2)
				dIdx = diff(obj.data.trialIndices,1,2);
			else
				dIdx = obj.data.trialIndices(:,3) - obj.data.trialIndices(:,1);
			end
			% find longest trial
			mIdx = max(dIdx);
			% find number of time bins in the spectrogram that corresponds to
			spTimeStep = Args.TFfftWindow - Args.TFfftOverlap;
			spTimeBins = floor(mIdx/spTimeStep) - Args.TFfftOverlap/spTimeStep;
			% create matrix
			nFreqs = (Args.TFfftPoints/2)+1;			
			ops = zeros(nFreqs,spTimeBins);
			opsCount = ops;
			for ti = 1:obj.data.numSets
				tftIdx = obj.data.trialIndices(ti,:);
				if(Args.OldMarkerFormat2)
					tfidx = tftIdx(1):tftIdx(2);
				else
					tfidx = tftIdx(1):tftIdx(3);
				end
				data = obj.data.analogData(tfidx);
				if(~isempty(Args.RemoveLineNoise))
					data = nptRemoveLineNoise(data,Args.RemoveLineNoise,sRate);
				end
				datam = mean(data);
				[s,w,t,ps] = spectrogram(data-datam,Args.TFfftWindow, ...
					Args.TFfftOverlap,Args.TFfftPoints,sRate);
				% add to overall mean
				% get columns of ps
				psIdx = 1:size(ps,2);
				ops(:,psIdx) = ops(:,psIdx) + ps;
				opsCount(:,psIdx) = opsCount(:,psIdx) + 1;
			end
			imagesc(0:(Args.TFfftWindow-Args.TFfftOverlap):mIdx,0:(sRate/Args.TFfftPoints):(sRate/2),ops./opsCount)
            set(gca,'Ydir','normal')
		else
			data = obj.data.analogData(idx);
			if(~isempty(Args.RemoveLineNoise))
				data = nptRemoveLineNoise(data,Args.RemoveLineNoise,sRate);
			end
			datam = mean(data);
			spectrogram(data-datam,Args.TFfftWindow,Args.TFfftOverlap,Args.TFfftPoints, ...
				sRate,'yaxis')
		end
	elseif(Args.TFWavelets)
		% not fully completed yet
    	cdata = nptRemoveLineNoise(obj.data.analogData',50,1000);
    	cdata1 = cdata(idx);
    	cdata1m = mean(cdata1);
    	PlotFFT(cdata1-cdata1m,1000);
    
        data.trial = num2cell(mdata,2);
        data.label = '1';
        data.fsample = 1000;
        data.time = num2cell(repmat((0:13087)/1000,51,1),2);

        cfg.channel = 'all';
        cfg.method = 'wavelet';
        cfg.width = 7;
        cfg.output = 'pow';
        cfg.foi = 1:100;
        cfg.toi = 0:5000;
        cfg.pad = 'nextpow2';
        
        TFRwave = ft_freqanalysis(cfg,data);
	else
		data = obj.data.analogData(idx);
		if(~isempty(Args.RemoveLineNoise))
			data = nptRemoveLineNoise(data,Args.RemoveLineNoise,sRate);
		end
		plot( (obj.data.analogTime(idx)-obj.data.analogTime(tIdx(1)) )*1000,data,'.-')
		% indicate trial start
		line([0 0],ylim,'Color','g')
		if(Args.OldMarkerFormat2)
			if(obj.data.markers(n,2)==Args.RewardMarker)
				% indicate correct trial
				line(repmat((obj.data.analogTime(idx(end))-obj.data.analogTime(tIdx(1)))*1000,2,1),ylim,'Color','b')
			else
				% indicate incorrect trial
				line(repmat((obj.data.analogTime(idx(end))-obj.data.analogTime(tIdx(1)))*1000,2,1),ylim,'Color','r')
			end
		else
			% indicate cue offset
			line(repmat((obj.data.analogTime(tIdx(2))-obj.data.analogTime(tIdx(1)))*1000,2,1),ylim,'Color','m')
			if(obj.data.markers(n,3)==Args.RewardMarker)
				% indicate correct trial
				line(repmat((obj.data.analogTime(idx(end))-obj.data.analogTime(tIdx(1)))*1000,2,1),ylim,'Color','b')
			else
				% indicate incorrect trial
				line(repmat((obj.data.analogTime(idx(end))-obj.data.analogTime(tIdx(1)))*1000,2,1),ylim,'Color','r')
			end
		end
	end
else
	% plot all data
	if(Args.FreqPlot)
		sRate = obj.data.analogInfo.SampleRate;
		data = obj.data.analogData;
		if(~isempty(Args.RemoveLineNoise))
			data = nptRemoveLineNoise(data,Args.RemoveLineNoise,sRate);
		end

		datam = mean(data);
		PlotFFT(data-datam,sRate)
		set(gca,'TickDir','out')
		if(Args.LogPlot)
			set(gca,'YScale','log')
		end
	else
		if(Args.OldMarkerFormat2)
			dIdx = diff(obj.data.trialIndices,1,2);
		else
			dIdx = obj.data.trialIndices(:,3) - obj.data.trialIndices(:,1);
		end
		% find longest trial
		mIdx = max(dIdx);
		% create matrix
		mdata = zeros(obj.data.numSets,mIdx);
		for i = 1:obj.data.numSets
			idx = obj.data.trialIndices(i,:);
			if(Args.NormalizeTrial)
				if(Args.OldMarkerFormat2)
					rdata = obj.data.analogData(idx(1):idx(2));
				else
					rdata = obj.data.analogData(idx(1):idx(3));
				end
				rdmin = min(rdata);
				rdmax = max(rdata);
				mdata(i,1:(dIdx(i)+1)) = (rdata-rdmin)/(rdmax-rdmin);
			else
				if(Args.OldMarkerFormat2)
					mdata(i,1:(dIdx(i)+1)) = obj.data.analogData(idx(1):idx(2));
				else
					mdata(i,1:(dIdx(i)+1)) = obj.data.analogData(idx(1):idx(3));
				end
			end
		end
		imagesc(mdata)
		colormap(jet)
	end
end

% add code for plot options here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% @vmhighpass/PLOT takes 'LabelsOff' as an example
if(~Args.LabelsOff)
	if(Args.FreqPlot)
		xlabel('Frequency (Hz)')
		ylabel('Magnitude')
	elseif(Args.TFfft)
		xlabel('Time (s)')
		ylabel('Frequency (Hz)')
	else
		xlabel('Time (ms)')
		ylabel('Voltage (uV)')
	end
end
[a,b] = fileparts(obj.nptdata.SessionDirs{:});
title(b)
if(~isempty(Args.FreqLims))
	if(Args.FreqPlot)
		xlim(Args.FreqLims)
	elseif(Args.TFfft)
		ylim(Args.FreqLims)
	end
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RR = eval('Args.ReturnVars');
for i=1:length(RR) RR1{i}=eval(RR{i}); end 
varargout = getReturnVal(Args.ReturnVars, RR1);
