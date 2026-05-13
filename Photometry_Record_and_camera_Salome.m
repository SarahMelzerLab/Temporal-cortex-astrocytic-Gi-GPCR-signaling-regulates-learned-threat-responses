% make sure to download and install LJM library before running this code
% find LJM library at https://labjack.com/support/software/installers/ljm


% Setting up stream-in and stream-out together, then reading
% stream-in values using .NET.
% for info on LabJ2ack methods for Matlab run >> methodsview(LabJack.LJM)


% Creates two sine waves on DAC0 and DAC1 for LED modulation.  DAC0 = 470nm (167Hz) (0.5 offset = about 70uW, used 
% amplitude = 0.275), DAC1 = 565nm (224Hz)
% modify frequency and amplitude individually using local variables amplitude, offset and frequency 
% negative peak of sine wave should not go below 0.15V as LED begins to turn off/labjack bottoms out

%% close current labjack session
try
    LabJack.LJM.CloseAll();
    pause(2);
end

%% continue with normal protocol

clc  % Clear the MATLAB command window
clear all % Clear the MATLAB variables
close all % close all figures

%set variables
maxRequests = 15000;%after how many seconds should this script stop automatically? (currently 15000sec=4 hrs and 10min)
%press Ctrl+c if you want to terminate before.
samplerate=2052; % Hz
scansPerRead = samplerate;  % Scans returned by eStreamRead call, here every second
spectWindow=200;%window size for frequency calculation in spectrogram (number of samples)
spectOverlap=180;%overlap between windows in spectrogram; new calculation every 20 samples.data points thus downsampled to 100Hz.
freqRange = [163.5:5:178.5;220.5:5:235.5]; % frequencies for channel 1 spectrogram (target 171, 228 Hz)
%LEDpowerblue=input('Choose fold increase of blue LED power')
%LEDpowergreen=input('Choose fold increase of green LED power')
LEDpowerblue=1;
LEDpowergreen=1.8;
colorarray=[0 1 0;1 0 0];%for display
looplength=[12,9];%sample rate divided by amplitude modulation frequency is looplength

% Choose folder to save data
folder = uigetdir('','Choose folder to save photometry data');
cd(folder);

save('info.mat','samplerate','looplength','LEDpowerblue','LEDpowergreen','scansPerRead');

% Make the LJM .NET assembly visible in MATLAB
ljmAsm = NET.addAssembly('LabJack.LJM');

% Creating an object to nested class LabJack.LJM.CONSTANTS
t = ljmAsm.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
LJM_CONSTANTS = System.Activator.CreateInstance(t);

handle = 0;


try
    % Open first found LabJack

    % Any device, Any connection, Any identifier
    [ljmError, handle] = LabJack.LJM.OpenS('ANY', 'ANY', 'ANY', handle);

    %show device info (same as function with same name)
    [~, devType, connType, serNum, ipAddr, port, maxBytesMB] = ...
        LabJack.LJM.GetHandleInfo(handle, 0, 0, 0, 0, 0, 0);
    ipAddrStr = '';
    [~, ipAddrStr] = LabJack.LJM.NumberToIP(ipAddr, ipAddrStr);
    disp(['Opened a LabJack with Device type: ' num2str(devType) ', ' ...
          'Connection type: ' num2str(connType) ','])
    disp(['Serial number: ' num2str(serNum) ', IP address: ' ...
          char(ipAddrStr) ', Port: ' num2str(port) ','])
    disp(['Max bytes per MB: ' num2str(maxBytesMB)])

    % Setup stream-out
    numAddressesOut = 2; 
    aNamesOut = NET.createArray('System.String', numAddressesOut);
    aNamesOut(1) = 'DAC0';  %address for 167Hz sine wave
    aNamesOut(2) = 'DAC1';  %address for 223Hz sine wave
    aAddressesOut = NET.createArray('System.Int32', numAddressesOut);
    aTypesOut = NET.createArray('System.Int32', numAddressesOut);  % Dummy
    LabJack.LJM.NamesToAddresses(numAddressesOut, aNamesOut, ...
        aAddressesOut, aTypesOut);

    % Allocate memory for the stream-out buffer DAC0 (OUT0)
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_TARGET', aAddressesOut(1));
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_SIZE', 512);
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_ENABLE', 1);
    
    % Allocate memory for the stream-out buffer DAC1 (OUT1)
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_TARGET', aAddressesOut(2));
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_SIZE', 512);
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_ENABLE', 1);
    
   
    %Write values to the stream-out buffer OUT0 = 470nm @ 167 Hz
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_LOOP_SIZE', 12);
    
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.6191*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.5687*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.5*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.4313*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.3809*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.3625*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.3809*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.4312*0.5*LEDpowerblue); 
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.5000*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.5687*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.6191*0.5*LEDpowerblue);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_BUFFER_F32', 0.6375*0.5*LEDpowerblue); 

    %   OUT1 = 565nm @ 223 Hz
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_LOOP_SIZE', 9);
    
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.6053*LEDpowergreen); 
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.5239*LEDpowergreen); 
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.4313*LEDpowergreen);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.3708*LEDpowergreen);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.3708*LEDpowergreen);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.4312*LEDpowergreen); 
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.5239*LEDpowergreen);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.6053*LEDpowergreen);  
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 0.6375*LEDpowergreen);  
%     
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen); 
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen); 
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen); 
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  
%     LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_BUFFER_F32', 1*LEDpowergreen);  

    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_SET_LOOP', 1);
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_SET_LOOP', 1);
    
     
end

% Stream-in  configuration
% Scan list names to stream-in
numAddressesIn = 9;
aScanListNames = NET.createArray('System.String', numAddressesIn);
aScanListNames(1) = 'AIN0'; % photodiode green channel
aScanListNames(2) = 'AIN1'; % photodiode red channel
aScanListNames(3) = 'AIN2'; % copy of DAC0 out to 488 LED
aScanListNames(4) = 'AIN3'; % copy of DAC1 out to 565 LED
aScanListNames(5) = 'DIO0'; % shock
aScanListNames(6) = 'DIO2'; % paired
aScanListNames(7) = 'DIO3'; % unpaired
aScanListNames(8) = 'DIO1'; % start and stop of ligth and script
aScanListNames(9) = 'FIO7'; % camera

% Scan list addresses to stream
aScanList = NET.createArray('System.Int32', ...
    (numAddressesIn + numAddressesOut));

% Get stream-in addresses
aTypes = NET.createArray('System.Int32', numAddressesIn); % Dummy
LabJack.LJM.NamesToAddresses(numAddressesIn, aScanListNames, ...
    aScanList, aTypes);

% Add the scan list outputs to the end of the scan list.
% STREAM_OUT0 = 4800, STREAM_OUT1 = 4801, ...
aScanList(numAddressesIn+1) = 4800;  % STREAM_OUT0
aScanList(numAddressesIn+2) = 4801;  % STREAM_OUT1


%scanRate = double(samplerate);  % Scans per second

% Stream reads will be stored in aData. Needs to be at least
% numAddresses*scansPerRead in size.
aData = NET.createArray('System.Double', numAddressesIn*scansPerRead);

% Ensure triggered stream is disabled.
LabJack.LJM.eWriteName(handle, 'STREAM_TRIGGER_INDEX', 0);

% Enabling internally-clocked stream.
LabJack.LJM.eWriteName(handle, 'STREAM_CLOCK_SOURCE', 0);

% All negative channels are single-ended, AIN0 and AIN1 ranges are
% +/-10 V, stream settling is 0 (default) and stream resolution index
% is 0 (default).
numFrames = 7;
aNames = NET.createArray('System.String', numFrames);
aNames(1) = 'AIN_ALL_NEGATIVE_CH';
aNames(2) = 'AIN0_RANGE';
aNames(3) = 'AIN1_RANGE';
aNames(4) = 'AIN2_RANGE';
aNames(5) = 'AIN3_RANGE';
aNames(6) = 'STREAM_SETTLING_US';
aNames(7) = 'STREAM_RESOLUTION_INDEX';
%             aNames(8) = 'STREAM_RESOLUTION_INDEX';
aValues = NET.createArray('System.Double', numFrames);
aValues(1) = LJM_CONSTANTS.GND;
aValues(2) = 10.0;
aValues(3) = 10.0;
aValues(4) = 10.0;
aValues(5) = 10.0;
aValues(6) = 0;
aValues(7) = 0;
%aValues(8) = 0;

% Write the analog inputs' negative channels (when applicable), ranges
% stream settling time and stream resolution configuration.
LabJack.LJM.eWriteNames(handle, numFrames, aNames, aValues, -1);

% Configure and start stream
scanRate=samplerate;
numAddresses = aScanList.Length;
[~, scanRate] = LabJack.LJM.eStreamStart(handle, scansPerRead, ...
    numAddresses, aScanList, scanRate);

disp(['Stream started with a scan rate of ' num2str(scanRate) ...
      ' Hz.'])


tic
curSkippedSamples = 0;
totalSkippedSamples = 0;

figure('Position',[0 40 600 900]); 
        subplot(8,1,1);hold on; title('blue ex - green em')
        subplot(8,1,2);hold on; title('green ex - red em')
        subplot(8,1,3);hold on; title('blue ex - red em')
        subplot(8,1,4);hold on; title('light')
        subplot(8,1,5);hold on; title('shock')
        subplot(8,1,6);hold on; title('sound 1')
        subplot(8,1,7);hold on; title('sound 2')
        subplot(8,1,8);hold on; title('raw green em')
        drawnow
speclength=floor((samplerate-spectOverlap)/(spectWindow-spectOverlap));
rawSig=zeros(2,speclength);
        
for i = 1:maxRequests
            [~, devScanBL, ljmScanBL] = LabJack.LJM.eStreamRead( ...
                handle, aData, 0, 0);

    temp = aData.double;
    
  if i>2   
    save(sprintf('Raw_%d.mat',i+1000),'temp')
   
        for j=1:2
            rawSig(j,:)=mean(abs(spectrogram(temp(j:numAddressesIn:end),spectWindow,spectOverlap,freqRange(j,:),samplerate)),1);
            subplot(8,1,j);hold on;plot(i*speclength-speclength+1:i*speclength,rawSig(j,:),'Color',colorarray(j,:));axis tight
            subplot(8,1,j+5);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(j+5:numAddressesIn:end),'Color','b');axis tight
            drawnow  
        end
         %rawSig(3,:)=mean(abs(spectrogram(temp(2:numAddressesIn:end),spectWindow,spectOverlap,freqRange(1,:),samplerate)),1);
         %subplot(8,1,3);hold on;plot(i*speclength-speclength+1:i*speclength,rawSig(3,:),'Color',colorarray(2,:));axis tight
         subplot(8,1,4);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(8:numAddressesIn:end),'Color','b');axis tight
         subplot(8,1,5);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(5:numAddressesIn:end),'Color','b');axis tight
         %subplot(8,1,8);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(1:numAddressesIn:end),'Color',colorarray(1,:));axis tight            
        
    end
    if mod(i,600)==0;
        close all
        figure('Position',[0 40 600 900]); 
        subplot(8,1,1);hold on; title('demodulated')
        %subplot(8,1,3);hold on; title('demodulated mBeRFP blue excitation')
        subplot(8,1,4);hold on; title('light')
        subplot(8,1,5);hold on; title('shock')
        subplot(8,1,6);hold on; title('sound 1')
        subplot(8,1,7);hold on; title('sound 2')
        %subplot(8,1,8);hold on; title('raw green em')
        drawnow
    end
    % Count the skipped samples which are indicated by -9999
    % values. Skipped samples occur after a device's stream buffer
    % overflows and are reported after auto-recover mode ends2.
    % When streaming at faster scan rates in MATLAB, try counting
    % the skipped packets outside your eStreamRead loop if you are
    % getting skipped samples/scan.
    curSkippedSamples = sum(double(aData) == -9999.0);
    totalSkippedSamples = totalSkippedSamples + curSkippedSamples;
i
end
toc


disp('Stop Stream')
LabJack.LJM.eStreamStop(handle);

% Close handle
LabJack.LJM.Close(handle);

