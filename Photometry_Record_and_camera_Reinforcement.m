% make sure to download and install LJM library before running this code
% find LJM library at https://labjack.com/support/software/installers/ljm


% Setting up stream-in and stream-out together, then reading
% stream-in values using .NET.
% for info on LabJ2ack methods for Matlab run >> methodsview(LabJack.LJM)


% Creates two sine waves on DAC0 and DAC1 for LED modulation.  DAC0 = 470nm (167Hz) (0.5 offset = about 70uW, used 
% amplitude = 0.275), DAC1 = 565nm (224Hz)
% modify frequency and amplitude individually using local variables amplitude, offset and frequency 
% negative peak of sine wave should not go below 0.15V as LED begins to turn off/labjack bottoms out
% modified by Sarah on 3/28/19

%% close current labjack session
try
    LabJack.LJM.CloseAll();
    pause(2);
end

%% continue with normal protocol

clc  % Clear the MATLAB command window
clear all % Clear the MATLAB variables
close all% close all figures
% The number of eStreamRead calls to perform in the stream read
% loop 1 per second 2
script=1;% script for 1 box with photometry

maxRequests = 15000;%1 per sec
%press Ctrl+c if you want to terminate before.
samplerate=2052; % Hz
spectWindow=200;%window size for frequency calculation in spectrogram (number of samples)
spectOverlap=180;%overlap between windows in spectrogram; new calculation every 20 samples.data points thus downsampled to 100Hz.
freqRange = [163.5:5:178.5;220.5:5:235.5]; % frequencies for channel 1 spectrogram (target 171, 228 Hz)
% LEDpowerblue=input('Choose fold increase of blue LED power')
% LEDpowergreen=input('Choose fold increase of green LED power')
LEDpowerblue=1;
LEDpowergreen=1;
colorarray=[0 1 0;1 0 0];
looplength=[12,9];
% p=gcp;
% Choose folder to save data
folder = uigetdir('','Choose folder to save photometry data');
cd(folder);

save('info.mat','samplerate','looplength','LEDpowerblue','LEDpowergreen');

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

%     OUT1 = 565nm @ 223 Hz
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

    LabJack.LJM.eWriteName(handle, 'STREAM_OUT0_SET_LOOP', 1);
    LabJack.LJM.eWriteName(handle, 'STREAM_OUT1_SET_LOOP', 1);
    
%     [~, value] = LabJack.LJM.eReadName(handle, ...
%         'STREAM_OUT2_BUFFER_STATUS', 0);
%     disp(['STREAM_OUT2_BUFFER_STATUS = ' num2str(value)])
%     
end

    
    
    % Stream-in  configuration

    % Scan list names to stream-in
    numAddressesIn = 9;
    aScanListNames = NET.createArray('System.String', numAddressesIn);
    aScanListNames(1) = 'AIN0'; % photodiode green channel
    aScanListNames(2) = 'AIN1'; % photodiode red channel
    aScanListNames(3) = 'AIN2'; % copy of DAC0 out to 488 LED
    aScanListNames(4) = 'AIN3'; % copy of DAC1 out to 565 LED
    aScanListNames(5) = 'DIO0'; % magazine state
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
   

    scanRate = double(2052);  % Scans per second
    scansPerRead = 2052;  % Scans returned by eStreamRead call

    % Stream reads will be stored in aData. Needs to be at least
    % numAddresses*scansPerRead in size.
    aData = NET.createArray('System.Double', numAddressesIn*scansPerRead);

%     try
        % When streaming, negative channels and ranges can be configured for
        % individual analog inputs, but the stream has only one settling time
        % and resolution.

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
%             aValues(8) = 0;
       %end
        % Write the analog inputs' negative channels (when applicable), ranges
        % stream settling time and stream resolution configuration.
        LabJack.LJM.eWriteNames(handle, numFrames, aNames, aValues, -1);

        % Configure and start stream
        numAddresses = aScanList.Length;
        [~, scanRate] = LabJack.LJM.eStreamStart(handle, scansPerRead, ...
            numAddresses, aScanList, scanRate);

        disp(['Stream started with a scan rate of ' num2str(scanRate) ...
              ' Hz.'])

     

        % Make a cell array out of scan list names. Helps performance when
        % converting and displaying in the loop.
        aScanListNamesML = cell(aScanListNames);

        tic

        disp(['Performing ' num2str(maxRequests) ' stream reads.'])

%         totalScans = 0;
        curSkippedSamples = 0;
        totalSkippedSamples = 0;
        
%         DATAM = zeros(maxRequests,scanRate*numAddressesIn); % initialize data matrix numAddressesOut not recorded
        figure('Position',[0 100 600 800]); 
                subplot(7,1,1);hold on; title('demodulated Green')
                subplot(7,1,2);hold on; title('demodulated Red with green excitation')
                subplot(7,1,3);hold on; title('demodulated Red with blue excitation')
                subplot(7,1,4);hold on; title('light')
                subplot(7,1,5);hold on; title('magazine state')
                subplot(7,1,6);hold on; title('rewarded sound')
                subplot(7,1,7);hold on; title('toggle')
                drawnow
        speclength=floor((samplerate-spectOverlap)/(spectWindow-spectOverlap));
        rawSig=zeros(2,speclength);
                
        for i = 1:maxRequests
            [~, devScanBL, ljmScanBL] = LabJack.LJM.eStreamRead( ...
                handle, aData, 0, 0);

%             totalScans = totalScans + scansPerRead;
%             DATAM(i,:)=aData.double;
            temp = aData.double;
        if i>2
            save(sprintf('Raw_%d.mat',i+1000),'temp')
    
                for (j=1:2);
                    rawSig(j,:)=mean(abs(spectrogram(temp(j:numAddressesIn:end),spectWindow,spectOverlap,freqRange(j,:),samplerate)),1);
                    subplot(7,1,j);hold on;plot(i*speclength-speclength+1:i*speclength,rawSig(j,:),'Color',colorarray(j,:));axis tight
%                     subplot(8,1,j+2);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(j:numAddressesIn:end),'Color',colorarray(j,:));axis tight
                    subplot(7,1,j+5);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(j+5:numAddressesIn:end),'Color','b');axis tight
%                     hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(5:numAddressesIn:end),'Color','r');axis tight
%                     subplot(8,1,j+4);hold on;plot(i*(samplerate/looplength(j))-(samplerate/looplength(j))+1:i*(samplerate/looplength(j)),temp(j:numAddressesIn*looplength(j):end),'Color',colorarray(j,:));axis tight
%                     subplot(7,1,j+7);hold on;plot(i*(samplerate/looplength(j))-(samplerate/looplength(j))+1:i*(samplerate/looplength(j)),temp(j+2:numAddressesIn*looplength(j):end),'Color',colorarray(j,:));axis tight
                    drawnow  
                end
                 rawSig(3,:)=mean(abs(spectrogram(temp(2:numAddressesIn:end),spectWindow,spectOverlap,freqRange(1,:),samplerate)),1);
                 subplot(7,1,3);hold on;plot(i*speclength-speclength+1:i*speclength,rawSig(3,:),'Color',colorarray(2,:));axis tight
                 subplot(7,1,4);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(8:numAddressesIn:end),'Color','b');axis tight
                 subplot(7,1,5);hold on;plot(i*samplerate-samplerate+1:i*samplerate,temp(5:numAddressesIn:end),'Color','b');axis tight
%                            
                
            end
            if mod(i,600)==0;
                close all
                figure('Position',[0 100 600 800]); 
                subplot(7,1,1);hold on; title('demodulated Green')
                subplot(7,1,2);hold on; title('demodulated Red with green excitation')
                subplot(7,1,3);hold on; title('demodulated Red with blue excitation')
                subplot(7,1,4);hold on; title('light')
                subplot(7,1,5);hold on; title('magazine state')
                subplot(7,1,6);hold on; title('rewarded sound')
                subplot(7,1,7);hold on; title('toggle')
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
% catch e
%     showErrorMessage(e)
%     LabJack.LJM.CloseAll();
% end
