%% add path
addpath('S:\MelzerLab\Lab\MatlabScripts');

%% variables
close all
    clear all
Rstime=50000;
totalNumSweeps=1;
Experiment=1;
noise=2;
rise=0.000000000035;%set the rise limit;decrease if too many electrical artefacts from the pump or phone are detected!
PSCtype=1;%-1 for EPSCs, 1 for IPSCs


%% define folder
disp('select the mat file with DeltaFF')
    [filename,directory]=uigetfile('*_Analysis.mat');%select recording to be analyzed
cd(directory)
load(filename);
DeltaFFWholeSlice=DeltaFF;


%% find peaks for each ROI individually and create data matrices for each slice

PSPfreqAll=zeros(size(DeltaFFWholeSlice,2),size(DeltaFFWholeSlice,1)-29);
PSPAmpAll=zeros(size(DeltaFFWholeSlice,2),size(DeltaFFWholeSlice,1)-29);
PSPRiseAll=nan(size(DeltaFFWholeSlice,2),size(DeltaFFWholeSlice,1));
PSPDecayAll=nan(size(DeltaFFWholeSlice,2),size(DeltaFFWholeSlice,1));
PSPHalfWidthAll=nan(size(DeltaFFWholeSlice,2),size(DeltaFFWholeSlice,1));

for k=1:size(DeltaFFWholeSlice,2)

DeltaFF=DeltaFFWholeSlice(:,k)';


% determine noise

figure('Position',[100 100 600 600]); plot(DeltaFF);hold on; title('determine noise level')
pause(0.5)
PSCthreshold=0;

while PSCthreshold==0
noise=input('type how many pA noise is - default = 2')

% find PSCs
concatenated=zeros(1,length(DeltaFF));
concatenatedAmp=zeros(1,length(DeltaFF));
concatenatedoriginal=DeltaFF;
[value,time]=findpeaks(concatenatedoriginal(21:length(concatenatedoriginal)-11),'MinPeakDistance',70);
time=time+20;

for i=1:length(time);
        if time(i)>200 & time(i)<(length(concatenatedoriginal)-round(201/6))...
              & (concatenatedoriginal(time(i))-min(concatenatedoriginal((time(i)-200):time(i))))>(noise*1.7)...
               & (concatenatedoriginal(time(i))-min(concatenatedoriginal(time(i):(time(i)+round(200/6)))))>(noise*1.4)...
               & mean(concatenatedoriginal(time(i)-1:time(i)+1))-min([mean(concatenatedoriginal(time(i)+round(50/6):(time(i)+round(55/6)))),mean(concatenatedoriginal(time(i)+round(100/6):(time(i)+round(110/6))))])>(noise/2)...
            & concatenatedoriginal(time(i))-min(concatenatedoriginal((time(i)-1):time(i)))<noise*10
             concatenated(time(i))=1;
             if concatenated(time(i))==1;
              if sum(concatenated)==1;  
                 concatenatedAmp(time(i))=concatenatedoriginal(time(i))-min(concatenatedoriginal(time(i)-200:time(i)-1));
                 if concatenatedAmp(time(i))<noise
                 concatenatedAmp(time(i))=0;
                 concatenated(time(i))=0;
             end
            timeold=time(i);
             else
             concatenatedAmp(time(i))=concatenatedoriginal(time(i))-(max(min(concatenatedoriginal(time(i)-200:time(i)-1)),min(concatenatedoriginal(timeold:time(i)-1))));
             if concatenatedAmp(time(i))<noise
                 concatenatedAmp(time(i))=0;
                 concatenated(time(i))=0;
             end
             timeold=time(i);
             end
             end
             
        end

end
for i=1:(length(concatenated)-1);
    if concatenated(i+1)==1;
        concatenated(i)=0;
    end
end
concatenatedAmp=concatenatedAmp.*concatenated;

% plot the PSC peaks
close all
figure('Position',[100 100 600 600]);
PeakList=find(concatenated);
plot(concatenatedoriginal,'-k');hold on
plot(PeakList,concatenatedoriginal(PeakList),'*r')
for i=1:length(PeakList)
plot([PeakList(i),PeakList(i)],[concatenatedoriginal(PeakList(i)),concatenatedoriginal(PeakList(i))-concatenatedAmp(PeakList(i))],'-g')
end
pause(0.5)
PSCthreshold=input('type 1 if ok; 0 if need to adjust')
if PSCthreshold==0
    concatenatedoriginal=concatenatedoriginal*PSCtype;
end
end

% calculate frequencies
[PSPtime]=find(concatenated);

%PSPfreq (calculates PSP freq in 1 sec bins but with original temporal resolution)
PSPfreq=zeros(1,length(concatenated)-29);
for i=1:length(concatenated)-29
    PSPfreq(i)=sum(concatenated(i:(i+29)));
end

PSPfreqAll(k,:)=PSPfreq;


PSPAmp=zeros(1,length(concatenated)-29);
for i=1:length(concatenated)-29
    PSPAmp(i)=sum(concatenatedAmp(i:(i+29)))/sum(concatenated(i:(i+29)));
end

PSPAmpAll(k,:)=PSPAmp;


for l=1:length(PSPtime)
    %calculate half width
    [~,A]=find(DeltaFF<(DeltaFF(PSPtime(l))-(concatenatedAmp(PSPtime(l))/2)));
    PSPend=A(A>PSPtime(l));%end of the half width transient
    try
    PSPend=PSPend(1);
    end
    PSPstart=A(A<PSPtime(l));% start of the half width transient
    try
    PSPstart=PSPstart(end);
    end
   if length(PSPstart)==1 & length(PSPend)==1
            if l==1 || PSPstart>PSPtime(l-1)
                if l==length(PSPtime) || PSPend<PSPtime(l+1)
                PSPHalfWidthAll(k,PSPtime(l))=PSPend-PSPstart+1;
                plot([PSPstart,PSPend],[concatenatedoriginal(PSPstart),concatenatedoriginal(PSPend)],'-b')
                else
                    PSPHalfWidthAll(k,PSPtime(l))=NaN;
                end
            else
                PSPHalfWidthAll(k,PSPtime(l))=NaN;
            end
   else
       PSPHalfWidthAll(k,PSPtime(l))=NaN;
   end


    %calculate rise slope
    [~,A]=find(DeltaFF<(DeltaFF(PSPtime(l))-(concatenatedAmp(PSPtime(l))/2)));
    PSPend=A(A>PSPtime(l));
    try
        PSPend=PSPend(1);
    end
    PSPstart=A(A<PSPtime(l));
    try
    PSPstart=PSPstart(end);
    end
    if length(PSPstart)==1
        if l==1 || PSPstart>PSPtime(l-1) 
    Slope=fit([1:PSPtime(l)-PSPstart+1]',DeltaFF(PSPstart:PSPtime(l))','poly1');
    PSPRiseAll(k,PSPtime(l))=Slope.p1;%in percent per data point (4hz frame rate)
    if Slope.p1<0
        PSPRiseAll(k,PSPtime(l))=NaN;
        PSPHalfWidthAll(k,PSPtime(l))=NaN;
    else
        plot([PSPstart:PSPtime(l)]',Slope(1:PSPtime(l)-PSPstart+1),'-y')
    end
        end
    else
        PSPRiseAll(k,PSPtime(l))=NaN;
        PSPHalfWidthAll(k,PSPtime(l))=NaN;
    end

    %calculate decay slope
    if length(PSPend)==1
        if l==length(PSPtime) || PSPend<PSPtime(l+1) 
    Slope=fit([1:PSPend-PSPtime(l)+1]',DeltaFF(PSPtime(l):PSPend)','poly1');
    PSPDecayAll(k,PSPtime(l))=Slope.p1;
        if Slope.p1>0
        PSPDecayAll(k,PSPtime(l))=NaN;
        PSPHalfWidthAll(k,PSPtime(l))=NaN;
        else
            plot([PSPtime(l):PSPend]',Slope(1:PSPend-PSPtime(l)+1),'-c')
    end
        end
    else
        PSPDecayAll(k,PSPtime(l))=NaN;
        PSPHalfWidthAll(k,PSPtime(l))=NaN;
    end
end

end


%% plot and save image

    close all
figure('Position',[100 100 700 700],'Color',[1 1 1])

subplot(5,1,1,'XTickLabel',[0:2:60],'XTick',[1:4*60:4*60*30]);hold on;title('PSC amplitude')
plot(PSPAmpAll','k-');hold on
plot(nanmean(PSPAmpAll),'r-');
xlabel('min')
ylabel('Amp [DFF]')
axis([0 length(nanmean(PSPAmpAll)) 0 max(nanmean(PSPAmpAll))])


subplot(5,1,2,'XTickLabel',[0:2:60],'XTick',[1:4*60:4*60*30]);hold on;title('PSC freq')
%plot(PSPfreqAll','k-');hold on
plot(mean(PSPfreqAll),'r-');
xlabel('min')
ylabel('freq')
axis([0 length(mean(PSPfreqAll)) 0 max(mean(PSPfreqAll))])



subplot(5,1,3,'XTickLabel',[0:2:60],'XTick',[1:4*60:4*60*30]);hold on;title('PSC half width')
%plot(PSPHalfWidthAll','k-');hold on
plot(nanmean(PSPHalfWidthAll),'r-');
xlabel('min')
ylabel('HalfWidth [%DFF]')
axis([0 length(nanmean(PSPHalfWidthAll)) 0 max(nanmean(PSPHalfWidthAll))])


subplot(5,1,4,'XTickLabel',[0:2:60],'XTick',[1:4*60:4*60*30]);hold on;title('PSC rise slope')
%plot(PSPRiseAll','k-');hold on
plot(nanmean(PSPRiseAll),'r-');
xlabel('min')
ylabel('Rise [slope]')
axis([0 length(nanmean(PSPRiseAll)) 0 max(nanmean(PSPRiseAll))])

subplot(5,1,5,'XTickLabel',[0:2:60],'XTick',[1:4*60:4*60*30]);hold on;title('PSC decay slope')
%plot(PSPDecayAll','k-');hold on
plot(nanmean(PSPDecayAll),'r-');
xlabel('min')
ylabel('Decay [slope]')
axis([0 length(nanmean(PSPDecayAll)) min(nanmean(PSPDecayAll)) 0])


%% save variables and image

saveas(gcf,strcat(filename(1:length(filename)-12),'FindPeaks'),'png')
%print('-depsc','-painters',strcat(filename(1:length(filename)-22),'FindPeaks'));
save(strcat(filename(1:length(filename)-12),'FindPeaks'),'filename','directory','PSPfreq','PSPfreqAll','PSPAmp','PSPAmpAll','noise','PSPDecayAll','PSPRiseAll','PSPHalfWidthAll');

