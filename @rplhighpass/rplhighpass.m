function [obj, varargout] = rplhighpass(varargin)
%@rplhighpass Constructor function for rplhighpass class
%   OBJ = rplhighpass(varargin) extracts highpass signals from a RIPPLE recording
%
%   OBJ = rplhighpass('auto') attempts to create a rplhighpass object by ...
%   
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   % Instructions on rplhighpass %
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%example [as, Args] = rplhighpass('save','redo')
%
%dependencies: 

Args = struct('RedoLevels',0, 'SaveLevels',0, 'Auto',0, 'ArgsOnly',0, ...
				'Data',[], 'HighpassFreqs',[500 10000], 'HPFOrder',8);
Args.flags = {'Auto','ArgsOnly'};
% The arguments that are critical when loading saved data
Args.DataCheckArgs = {'HighpassFreqs'};                            

[Args,modvarargin] = getOptArgs(varargin,Args, ...
	'subtract',{'RedoLevels','SaveLevels'}, ...
	'shortcuts',{'redo',{'RedoLevels',1}; 'save',{'SaveLevels',1}}, ...
	'remove',{'Auto'});

% variable specific to this class. Store in Args so they can be easily
% passed to createObject and createEmptyObject
Args.classname = 'rplhighpass';
Args.matname = [Args.classname '.mat'];
Args.matvarname = 'rh';

% To decide the method to create or load the object
command = checkObjCreate('ArgsC',Args,'narginC',nargin,'firstVarargin',varargin);

if(strcmp(command,'createEmptyObjArgs'))
    varargout{1} = {'Args',Args};
    obj = createEmptyObject(Args);
elseif(strcmp(command,'createEmptyObj'))
    obj = createEmptyObject(Args);
elseif(strcmp(command,'passedObj'))
    obj = varargin{1};
elseif(strcmp(command,'loadObj'))
    l = load(Args.matname);
    obj = eval(['l.' Args.matvarname]);
elseif(strcmp(command,'createObj'))
    % IMPORTANT NOTICE!!! 
    % If there is additional requirements for creating the object, add
    % whatever needed here
    obj = createObject(Args,modvarargin{:});
end

function obj = createObject(Args,varargin)

if(~isempty(Args.Data))
	data = Args.Data;
	data.analogTime = (0:(data.analogInfo.NumberSamples-1))' ./ data.analogInfo.SampleRate;
	data.numSets = 1;
	% clear Data in Args so it is not saved
	Args.Data = [];
	Args.HighpassFreqs = [data.analogInfo.HighFreqCorner/1000 ...
		data.analogInfo.LowFreqCorner/1000];
		
	% create nptdata so we can inherit from it   
	data.Args = Args; 
	n = nptdata(data.numSets,0,pwd);
	d.data = data;
	obj = class(d,Args.classname,n);
	saveObject(obj,'ArgsC',Args);	
else
	rw = rplraw('auto',varargin{:});
	if(~isempty(rw))		
		hpdata = nptHighPassFilter(rw.data.analogData,rw.data.analogInfo.SampleRate, ...
					Args.HighpassFreqs(1),Args.HighpassFreqs(2));
		data.analogData = hpdata;
		data.analogInfo = rw.data.analogInfo;
		data.analogInfo.MinVal = min(hpdata);
		data.analogInfo.MaxVal = max(hpdata);
		data.analogInfo.HighFreqCorner = Args.HighpassFreqs(1)*1000;
		data.analogInfo.LowFreqCorner = Args.HighpassFreqs(2)*1000;
		data.analogInfo.NumberSamples = length(hpdata);
		data.analogInfo.HighFreqOrder = Args.HPFOrder;
		data.analogInfo.LowFreqOrder = Args.HPFOrder;
		data.analogInfo.ProbeInfo = strrep(data.analogInfo.ProbeInfo,'raw','hp');
		data.analogTime = (0:(data.analogInfo.NumberSamples-1))' ./ data.analogInfo.SampleRate;
		data.numSets = 1;
		
		% create nptdata so we can inherit from it    
		data.Args = Args; 
		n = nptdata(data.numSets,0,pwd);
		d.data = data;
		obj = class(d,Args.classname,n);
		saveObject(obj,'ArgsC',Args);			
	else
		% create empty object
		obj = createEmptyObject(Args);
	end
end

function obj = createEmptyObject(Args)

% useful fields for most objects
data.numSets = 0;
data.setNames = '';

% these are object specific fields
data.dlist = [];
data.setIndex = [];

% create nptdata so we can inherit from it
data.Args = Args;
n = nptdata(0,0);
d.data = data;
obj = class(d,Args.classname,n);
