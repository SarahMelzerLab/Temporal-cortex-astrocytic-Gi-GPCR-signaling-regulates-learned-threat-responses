close all
samplerate=2052; % Hz
spectWindow=200;%window size for frequency calculation in spectrogram (number of samples)
spectOverlap=180;%overlap between windows in spectrogram; new calculation every 20 samples.data points thus downsampled to 100Hz.
params.freqRange1 = [163.5:5:178.5]; % frequencies for channel 1 spectrogram (target 171 Hz)
params.freqRange2 = [220.5:5:235.5]; % frequencies for channel 2 spectrogram (target 228 Hz)
useFreqRange=[0:5:500];%frequencies for all spectrograms in figure;

folder = uigetdir('','Choose folder to save photometry data');
cd(folder); 

D=dir('Raw_*.mat');
[~,idx] = sort([D.datenum]);
D = D(idx);
filename={D.name};
load(filename{1});
numChannels=length(temp)/samplerate;
newfileIdx = length(D);
dataArray=zeros(1,(newfileIdx*length(temp)));
for i=1:newfileIdx
    load(filename{i});
    dataArray(((i-1)*length(temp)+1):(i*length(temp)))=temp;
end

output=dataArray;
totalLen = length(dataArray);

% In the order of scanning
Ch1=find(mod(1:totalLen,numChannels)==1);   % photodetector #1 -green
Ch2=find(mod(1:totalLen,numChannels)==2);   % photodetector #2 -red
Ch3=find(mod(1:totalLen,numChannels)==3);  %copy of 488 modulation
Ch4=find(mod(1:totalLen,numChannels)==4);   %copy of 560 modulation
Ch5=find(mod(1:totalLen,numChannels)==5);   %shock
Ch6=find(mod(1:totalLen,numChannels)==6);   %paired
Ch7=find(mod(1:totalLen,numChannels)==7);   %unpaired
Ch8=find(mod(1:totalLen,numChannels)==8);   %light
Ch9=find(mod(1:totalLen,numChannels)==0);   %camera

% Make green and red arrays and demodulate photodiode signals  

green= output(Ch1);
red= output(Ch2);
modgreen=output(Ch3);
modred=output(Ch4);
shock=output(Ch5);
paired=output(Ch6);
unpaired=output(Ch7);
light=output(Ch8);
camera=output(Ch9);

figure;hold on
subplot(10,1,1); plot(green);title('green raw');axis tight
subplot(10,1,2);plot(green(1:12:end));title('green no mod');axis tight
subplot(10,1,3); plot(red);title('red raw');axis tight
subplot(10,1,4);plot(red(1:9:end));title('red no mod');axis tight
subplot(10,1,5); plot(modgreen);title('green modulation');axis tight
subplot(10,1,6); plot(modred);title('red modulation');axis tight
subplot(10,1,7); plot(shock);title('shock');axis tight
subplot(10,1,8); plot(paired);title('paired');axis tight
subplot(10,1,9); plot(unpaired);title('unpaired');axis tight
subplot(10,1,10); plot(light);title('light');axis tight

% params.spectSample = 0.01; % Step size for spectrogram (sec)
params.filtCut = 100/(spectWindow-spectOverlap); % Cut off frequency of 5Hz for low pass filter of processed data
params.dsRate = 0.05; % Time steps for down-sampling (seconds) (average of every 100 samples)


% Convert spectrogram window size and overlap from time to samples
% spectWindow = 2.^nextpow2(samplerate .* params.winSize);
% spectOverlap = ceil(spectWindow - (spectWindow .* (params.spectSample ./ params.winSize)));
disp(['Spectrum window ', num2str(spectWindow ./ samplerate), ' sec; ',...
    num2str(spectWindow), ' samples at ', num2str(samplerate), ' Hz with ',num2str(spectOverlap),' samples overlap'])
% Create low pass filter for final data
lpFilt = designfilt('lowpassiir','FilterOrder',8, 'PassbandFrequency',params.filtCut,...
    'PassbandRipple',0.01, 'SampleRate',samplerate/(spectWindow-spectOverlap));

% Calculate spectrogram channel 1
[spectVals1,spectFreqs1,filtTimes]=spectrogram(green,spectWindow,spectOverlap,params.freqRange1,samplerate);
figure;subplot(2,3,1);hold on; title('green');spectrogram(green,spectWindow,spectOverlap,useFreqRange,samplerate);
rawSig1 = mean(abs(spectVals1),1);
filtSig1 = filtfilt(lpFilt,double(rawSig1));% Low pass filter the signals
1

% Calculate spectrogram channel 2 modulated by green LED
[spectVals2,spectFreqs2,filtTimes]=spectrogram(red,spectWindow,spectOverlap,params.freqRange2,samplerate);
subplot(2,3,2);hold on; title('red');spectrogram(red,spectWindow,spectOverlap,useFreqRange,samplerate);
rawSig2 = mean(abs(spectVals2),1);
filtSig2 = filtfilt(lpFilt,double(rawSig2));% Low pass filter the signals
2
% Calculate spectrogram channel 2 modulated by blue LED
[spectVals3,spectFreqs3,filtTimes]=spectrogram(red,spectWindow,spectOverlap,params.freqRange1,samplerate);
subplot(2,3,3);hold on; title('red');spectrogram(red,spectWindow,spectOverlap,useFreqRange,samplerate);
rawSig3 = mean(abs(spectVals3),1);
filtSig3 = filtfilt(lpFilt,double(rawSig3));% Low pass filter the signals
3
% Calculate spectrogram channel 3
[spectVals4,spectFreqs4,filtTimes]=spectrogram(modgreen,spectWindow,spectOverlap,params.freqRange1,samplerate);
subplot(2,2,3);hold on; title('modgreen');spectrogram(modgreen,spectWindow,spectOverlap,useFreqRange,samplerate);
rawSig4 = mean(abs(spectVals4),1);
4

% Calculate spectrogram channel 4
[spectVals5,spectFreqs5,filtTimes]=spectrogram(modred,spectWindow,spectOverlap,params.freqRange2,samplerate);
subplot(2,2,4);hold on; title('modred');spectrogram(modred,spectWindow,spectOverlap,useFreqRange,samplerate);
rawSig5 = mean(abs(spectVals5),1);
5

% Determine time points in output data set
dsTimes = filtTimes(1):params.dsRate:filtTimes(end); 

% Fit each channel to exponential decay for photobleaching correction
pbFit1 = fit(filtTimes',filtSig1','exp1'); 
pbFit2 = fit(filtTimes',filtSig2','exp1');
pbFit3 = fit(filtTimes',filtSig3','exp1');

% Divide filtered signal by exponential decay to correct for photobleaching
pbVals1 = (filtSig1' ./ double(pbFit1(filtTimes)))';
pbVals2 = (filtSig2' ./ double(pbFit2(filtTimes)))';
pbVals3 = (filtSig3' ./ double(pbFit3(filtTimes)))';

% Downsample photobleaching-corrected data
dsVals1 = interp1(filtTimes,pbVals1,dsTimes,'spline');
dsVals2 = interp1(filtTimes,pbVals2,dsTimes,'spline');
dsVals3 = interp1(filtTimes,pbVals3,dsTimes,'spline');

% Downsample raw (uncorrected) data
rawVals1 = interp1(filtTimes,filtSig1',dsTimes,'spline');
rawVals2 = interp1(filtTimes,filtSig2',dsTimes,'spline');
rawVals3 = interp1(filtTimes,filtSig3',dsTimes,'spline');

% Fs=20;
% g_0 = running_percentile(dsVals1, floor(Fs*60), 10);
% g_dff = dsVals1'./g_0 - 1;
% g_dff = g_dff';


figure;
subplot(3,1,1); hold on
plot(filtTimes,rawSig1,'g'); title('spec power');
subplot(3,1,2); hold on
plot(filtTimes,rawSig2,'r');
subplot(3,1,3); hold on
plot(filtTimes,rawSig3,'r');
figure
subplot(3,1,1); hold on
plot(filtTimes,filtSig1,'g'); title('low pass filtered spec power');
subplot(3,1,2); hold on
plot(filtTimes,filtSig2,'r');
subplot(3,1,3); hold on
plot(filtTimes,filtSig3,'r');
figure
subplot(3,1,1); hold on
plot(rawVals1,'g'); title('low pass filtered spec power downsampled');
subplot(3,1,2); hold on
plot(rawVals2,'r');
subplot(3,1,3); hold on
plot(rawVals3,'r');
% subplot(4,1,4);hold on
% plot(filtTimes,rawSig3,'g'); title('spec power of excitation light');
% plot(filtTimes,rawSig4,'r');

% Calculate spectrogram channel 9
[spectVals9,spectFreqs9,filtTimes]=spectrogram(camera,2052,0,[29:0.1:31],samplerate);
figure;
subplot(2,2,1);hold on; title('camera');spectrogram(camera,2052,0,[29:0.1:31],samplerate);
rawSig9 = mean(abs(spectVals9),1);
6
save('allData.mat','green','red','rawSig1','rawSig2','rawSig3','rawSig2','filtSig1','filtSig2','filtSig3','rawVals1','rawVals2','rawVals3','pbVals1','pbVals2','pbVals3','shock','paired','unpaired','light');