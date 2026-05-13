%%select folder and load data
close all
clear
disp('select folder with the two subfolders ctrl and test')
directorynew=uigetdir;%select the folder that has the two subfolders 'test' and 'ctrl'
cd(directorynew);
close all


%% set variables
durationctrl=[];% length of phase 4 with 2 sounds in days
durationtest=[];% length of phase 4 with 2 sounds in days
samplerate=2052; %sample rate of the LabJack
rewardduration=5; %in seconds
sumRewardR=[];
sumFalsePositiveR=[];
latencyR=[];
latencyFalsePositiveR=[];
TASound1R=[];
TASound2R=[];
rewardedR=[];
sound_pairedR=[];
falsePokesR=[];
sound_unpairedR=[];
magazineentryR=[];

%% Make data matrices and figure for each group separately, start with ctrl
cd(strcat(directorynew,'/ctrl'));
filelist1=dir('1_*');% file list for only the first day of discrimination learning
for i=2:28
    if length(dir(strcat(string(i),'_*')))<length(filelist1)
        break
    else
        durationctrl=i;
    end
end

cd(strcat(directorynew,'/test'));
filelist1=dir('1_*');% file list for only the first day of discrimination learning
for i=2:28
    if length(dir(strcat(string(i),'_*')))<length(filelist1)
        break
    else durationtest=i;
    end
end
duration=min(durationctrl,durationtest);

for group=1:2
    if group==1
        colorcode=[0.5 0.5 0.5];
        cd(strcat(directorynew,'/ctrl'));
    elseif group==2
        durationctrl=duration;
        colorcode=[0.0 0.7 0.8];
        cd(strcat(directorynew,'/test'));
    end
filelist1=dir('1_*');% file list for only the first day of discrimination learning
filelist=dir('*.mat');% all files

% Create data matrices for all mice from one group
hitrateAll=zeros(length(filelist1),duration);
FArateAll=zeros(length(filelist1),duration);
discriminationIndex=zeros(length(filelist1),duration);
discriminationIndex15=zeros(length(filelist1),15);
discriminability=zeros(length(filelist1),duration);
discriminability15=zeros(length(filelist1),15);
latencyHit=zeros(length(filelist1),duration);
latencyFA=zeros(length(filelist1),duration);
magazineBL=zeros(length(filelist1),duration);
magazineBLafter5=zeros(length(filelist1),duration);
PokeHistEarlyCS=zeros(length(filelist1),123120);
PokeHistEarlyS=zeros(length(filelist1),123120);
PokeHistMidCS=zeros(length(filelist1),123120);
PokeHistMidS=zeros(length(filelist1),123120);
PokeHistLateCS=zeros(length(filelist1),123120);
PokeHistLateS=zeros(length(filelist1),123120);
HitrateExpert=zeros(length(filelist1),4);
FArateExpert=zeros(length(filelist1),4);
%ExpertPokes=zeros(length(filelist1),1904122);
ExpertPokes=[];
Hitrate6=zeros(length(filelist1),4);
Hitrate12=zeros(length(filelist1),4);
Hitrate18=zeros(length(filelist1),4);
FArate6=zeros(length(filelist1),4);
FArate12=zeros(length(filelist1),4);
FArate18=zeros(length(filelist1),4);

 exclude=[];
for i=1:duration% length(filelist1) equal number of mice
    disp('day ')
    i
    group
    filelist_temp=dir(strcat(string(i),'_*'));% find all mice for day 1 etc
         if length(filelist_temp)==length(filelist1)
         else
             disp('warning: day',string(i),'does not have the correct number of mice!!!')
         end
    for j=1:length(filelist_temp)

        load(filelist_temp(j).name)
        if isempty(sumRewardR)
        else
        sumReward=sumRewardR;
        sumFalsePositive=sumFalsePositiveR;
        latency=latencyR;
        latencyFalsePositive=latencyFalsePositiveR;
        TASound1=TASound1R;
        TASound2=TASound2R;
        rewarded=rewardedR;
        sound_paired=sound_pairedR;
        falsePokes=falsePokesR;
        sound_unpaired=sound_unpairedR;
        magazineentry=magazineentryR;
        light=lightR;
        sumRewardR=[];
        sumFalsePositiveR=[];
        latencyR=[];
        latencyFalsePositiveR=[];
        TASound1R=[];
        TASound2R=[];
        rewardedR=[];
        sound_pairedR=[];
        falsePokesR=[];
        sound_unpairedR=[];
        magazineentryR=[];
        lightR=[];
        end

        hitrate1=sumReward/length(sound_paired);        
        FArate1=sumFalsePositive/length(sound_unpaired);
        hitrateAll(j,i)=hitrate1; %each column (i) is one day, each row (j) is one mouse
        FArateAll(j,i)=FArate1;
        discriminationIndex(j,i)=((hitrate1-FArate1)/(hitrate1+FArate1));
        %calculate discrimination index for 15 rewarded sounds only
        if length(rewarded)<=15
            hitrate15=hitrate1;
            FArate15=FArate1;
        else
            hitrate15=15/((length(find(sound_paired<rewarded(15)))+1)/2);
            FArate15=length(find(falsePokes<rewarded(15)))/((length(find(sound_unpaired<rewarded(15))))/2);
        end
        discriminationIndex15(j,i)=((hitrate15-FArate15)/(hitrate15+FArate15));
        %calculate discrimination index for first 5 sounds only
        hitrate5=(length(find(rewarded>sound_paired(1) & rewarded<sound_paired(10))))/5;
        FArate5=(length(find(falsePokes>sound_unpaired(1) & falsePokes<sound_unpaired(10))))/5;
        discriminationIndex15(j,i)=((hitrate15-FArate15)/(hitrate15+FArate15));
        discriminationIndex5(j,i)=((hitrate5-FArate5)/(hitrate5+FArate5));
        %calculate discrimination index for sounds 11-15 only
        discriminationIndex15(j,i)=((hitrate15-FArate15)/(hitrate15+FArate15));
 
        if size(sound_paired,2)>14 % include only mice that poke at least 15 times for reward
         hitrate11to15=(length(find(rewarded>sound_paired(20) & rewarded<sound_paired(30))))/5;
        FArate11to15=(length(find(falsePokes>sound_unpaired(20) & falsePokes<sound_unpaired(30))))/5;
        discriminationIndex5(j,i)=((hitrate5-FArate5)/(hitrate5+FArate5));
        discriminationIndex11to15(j,i)=((hitrate11to15-FArate11to15)/(hitrate11to15+FArate11to15));
        else
            discriminationIndex5(j,i)=NaN;
            discriminationIndex11to15(j,i)=NaN;
            exclude=[exclude;[j,i]];
        end
        %calculate discriminability for all rewards
        if hitrate1>0.99
            hitrate2=0.99;
        elseif hitrate1<0.01
            hitrate2=0.01;
        else 
            hitrate2=hitrate1;
        end
        if FArate1<0.01
            FArate2=0.01;
        elseif FArate1>0.99
            FArate2=0.99;
        else
            FArate2=FArate1;
        end

        discriminability(j,i)=norminv(hitrate2)-norminv(FArate2);
        %calculate discriminability for up to 15 rewards
        if length(rewarded)<=15
            discriminability15(j,i)=discriminability(j,i);
        else
            if hitrate15>0.99
                hitrate15b=0.99;
            elseif hitrate15<0.01
                hitrate15b=0.01;
            else 
                hitrate15b=hitrate15;
            end
            if FArate15<0.01
                FArate15b=0.01;
            elseif FArate15>0.99
                FArate15b=0.99;
            else
                FArate15b=FArate15;
            end
            discriminability15(j,i)=norminv(hitrate15b)-norminv(FArate15b);
        end
        %calculate latency for all hits and false positives
        latencyHit(j,i)=mean(latency);
        latencyFA(j,i)=mean(latencyFalsePositive);
        startLight=find(light==0);startLight=startLight(1);
        magazineBL(j,i)=((length(magazineentry(magazineentry>startLight))-length(magazineentry(magazineentry>(startLight+(20*2052)))))/20)*5*100;
        %magazineBLafter5(j,i)=min(1,((length(magazineentry(magazineentry>sound_unpaired(10)+(5*2052)))-length(magazineentry(magazineentry>(sound_unpaired(10)+(10*2052)))))))*100;
        %calculate baseline magazine entries based on the no sound period
        %after unpaired sound: this is from sec 5-10 after each
        %unpaired sound.
        for l=2:2:length(sound_unpaired)*2
            magazineBLafter5(j,i)=magazineBLafter5(j,i)+(min(1,((length(magazineentry(magazineentry>sound_unpaired(l)+(5*2052)))-length(magazineentry(magazineentry>(sound_unpaired(l)+(10*2052)))))))*100);
        end
        magazineBLafter5(j,i)=magazineBLafter5(j,i)/length(sound_unpaired);
        if i==1
            PokeHistEarlyCS(j,:)=mean(TASound1);
            PokeHistEarlyS(j,:)=mean(TASound2);
        elseif i==6
            PokeHistMidCS(j,:)=mean(TASound1);
            PokeHistMidS(j,:)=mean(TASound2);
            Hitrate6(j,1)=[length(find(rewarded>sound_paired(1) & rewarded<sound_paired(8)))];
            Hitrate6(j,2)=[length(find(rewarded>sound_paired(9) & rewarded<sound_paired(16)))];
            Hitrate6(j,3)=[length(find(rewarded>sound_paired(17) & rewarded<sound_paired(24)))];
            Hitrate6(j,4)=[length(find(rewarded>sound_paired(25) & rewarded<sound_paired(32)))];
            FArate6(j,1)=[length(find(falsePokes>sound_unpaired(1) & falsePokes<sound_unpaired(8)))];
            FArate6(j,2)=[length(find(falsePokes>sound_unpaired(9) & falsePokes<sound_unpaired(16)))];
            FArate6(j,3)=[length(find(falsePokes>sound_unpaired(17) & falsePokes<sound_unpaired(24)))];
            FArate6(j,4)=[length(find(falsePokes>sound_unpaired(25) & falsePokes<sound_unpaired(32)))];
            ExpertPokes=[ExpertPokes,magazineentry];
        elseif i==12
            Hitrate12(j,1)=[length(find(rewarded>sound_paired(1) & rewarded<sound_paired(8)))];
            Hitrate12(j,2)=[length(find(rewarded>sound_paired(9) & rewarded<sound_paired(16)))];
            Hitrate12(j,3)=[length(find(rewarded>sound_paired(17) & rewarded<sound_paired(24)))];
            Hitrate12(j,4)=[length(find(rewarded>sound_paired(25) & rewarded<sound_paired(32)))];
            FArate12(j,1)=[length(find(falsePokes>sound_unpaired(1) & falsePokes<sound_unpaired(8)))];
            FArate12(j,2)=[length(find(falsePokes>sound_unpaired(9) & falsePokes<sound_unpaired(16)))];
            FArate12(j,3)=[length(find(falsePokes>sound_unpaired(17) & falsePokes<sound_unpaired(24)))];
            FArate12(j,4)=[length(find(falsePokes>sound_unpaired(25) & falsePokes<sound_unpaired(32)))];
         elseif i==18
            Hitrate18(j,1)=[length(find(rewarded>sound_paired(1) & rewarded<sound_paired(8)))];
            Hitrate18(j,2)=[length(find(rewarded>sound_paired(9) & rewarded<sound_paired(16)))];
            Hitrate18(j,3)=[length(find(rewarded>sound_paired(17) & rewarded<sound_paired(24)))];
            Hitrate18(j,4)=[length(find(rewarded>sound_paired(25) & rewarded<sound_paired(32)))];
            FArate18(j,1)=[length(find(falsePokes>sound_unpaired(1) & falsePokes<sound_unpaired(8)))];
            FArate18(j,2)=[length(find(falsePokes>sound_unpaired(9) & falsePokes<sound_unpaired(16)))];
            FArate18(j,3)=[length(find(falsePokes>sound_unpaired(17) & falsePokes<sound_unpaired(24)))];
            FArate18(j,4)=[length(find(falsePokes>sound_unpaired(25) & falsePokes<sound_unpaired(32)))];
        elseif i==21
            PokeHistLateCS(j,:)=mean(TASound1);
            PokeHistLateS(j,:)=mean(TASound2);
        end
    end
end

if group==1

%make figure for everything    
figure('Position',[100 10 1100 1350],'Color',[1 1 1]); hold on
% draw schematic
end

% hit rate across learning; false alarm rate across learning
subplot(5,4,2); hold on
if size(hitrateAll*100,1)>1
stdX=std(hitrateAll*100)/sqrt(size(hitrateAll*100,1));
    for k=1:duration-1
        errBoxY = [mean(hitrateAll(:,k)*100)-stdX(k),mean(hitrateAll(:,k)*100)+stdX(k), mean(hitrateAll(:,k+1)*100)+stdX(k+1),mean(hitrateAll(:,k+1)*100)-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
stdX=std(FArateAll*100)/sqrt(size(FArateAll*100,1));
    for k=1:duration-1
        errBoxY = [mean(FArateAll(:,k)*100)-stdX(k),mean(FArateAll(:,k)*100)+stdX(k), mean(FArateAll(:,k+1)*100)+stdX(k+1),mean(FArateAll(:,k+1)*100)-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
end
plot(mean(hitrateAll)*100,'-','Color',colorcode,'LineWidth',1.5);
plot(mean(FArateAll)*100,':','Color',colorcode,'LineWidth',1.5)
title('Hit rate, FA rate')
xlabel('Session')
ylabel('Probability [%]')
if group==2
    text(1,29,'-  Hit rate ctrl','FontSize',8,'Color',[0.7,0.7,0.7]); % add text
    text(1,21,'-  Hit rate test','FontSize',8,'Color',colorcode); % add text
    text(1,13,'.. FA rate ctrl','FontSize',8,'Color',[0.7,0.7,0.7]); % add text
    text(1,5,'.. FA rate test','FontSize',8,'Color',colorcode); % add text
end
axis([0 duration 0 100])

% discrimination index across learning
subplot(5,4,3); hold on
if size(hitrateAll*100,1)>1
stdX=std(discriminationIndex)/sqrt(size(discriminationIndex,1));
    for k=1:duration-1
        errBoxY = [mean(discriminationIndex(:,k))-stdX(k),mean(discriminationIndex(:,k))+stdX(k), mean(discriminationIndex(:,k+1))+stdX(k+1),mean(discriminationIndex(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
end
    plot(mean(discriminationIndex),'-','Color',colorcode,'LineWidth',1.5);
title('Discrimination')
xlabel('Session')
ylabel('Discrimination Index')
axis([0 duration -0.1 0.8])
if group==2
    text(1,0.8,'ctrl','FontSize',10,'Color',[0.7,0.7,0.7]); % add text
    text(1,0.7,'test','FontSize',10,'Color',colorcode); % add text
end

% performance (d') across learning
subplot(5,4,4); hold on
if size(hitrateAll*100,1)>1
    stdX=std(discriminability)/sqrt(size(discriminability,1));
    for k=1:duration-1
        errBoxY = [mean(discriminability(:,k))-stdX(k),mean(discriminability(:,k))+stdX(k), mean(discriminability(:,k+1))+stdX(k+1),mean(discriminability(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
end
plot(mean(discriminability),'-','Color',colorcode,'LineWidth',1.5);
title('Discriminability')
xlabel('Session')
ylabel('Performance (d)')
axis([0 duration -0.5 3])

% latency hit across learning, latency FA across learning
subplot(5,4,5); hold on
if size(hitrateAll*100,1)>1
    stdX=std(latencyHit/samplerate)/sqrt(size(latencyHit/samplerate,1));
    for k=1:duration-1
        errBoxY = [mean(latencyHit(:,k)/samplerate)-stdX(k),mean(latencyHit(:,k)/samplerate)+stdX(k), mean(latencyHit(:,k+1)/samplerate)+stdX(k+1),mean(latencyHit(:,k+1)/samplerate)-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
end
plot(mean(latencyHit/samplerate),'-','Color',colorcode,'LineWidth',1.5);
title('Latency hits')
ylabel('[sec]');
xlabel('Session')
axis([0 duration 0 3])


subplot(5,4,6); hold on
if size(hitrateAll*100,1)>1
    stdX=std(latencyFA/samplerate)/sqrt(size(latencyFA/samplerate,1));
    for k=1:duration-1
        errBoxY = [mean(latencyFA(:,k)/samplerate)-stdX(k),mean(latencyFA(:,k)/samplerate)+stdX(k), mean(latencyFA(:,k+1)/samplerate)+stdX(k+1),mean(latencyFA(:,k+1)/samplerate)-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
end
plot(mean(latencyFA/samplerate),':','Color',colorcode,'LineWidth',1.5)
title('Latency FA')
ylabel('[sec]');
xlabel('Session')
axis([0 duration 0 3])

% baseline magazine entry; needs to be subtracted from hitrate if different
subplot(5,4,12); hold on
stdX=std(magazineBL)/sqrt(size(magazineBL,1));
    for k=1:duration-1
        errBoxY = [mean(magazineBL(:,k))-stdX(k),mean(magazineBL(:,k))+stdX(k), mean(magazineBL(:,k+1))+stdX(k+1),mean(magazineBL(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(magazineBL),'-','Color',colorcode,'LineWidth',1.5);
title({'Magazine entries baseline','(per 5 sec)'})
ylabel('Probability [%]');
xlabel('Session')
axis([0 duration 0 200])

% baseline magazine entry; needs to be subtracted from hitrate if different
subplot(5,4,8); hold on
stdX=std(magazineBLafter5)/sqrt(size(magazineBLafter5,1));
    for k=1:duration-1
        errBoxY = [mean(magazineBLafter5(:,k))-stdX(k),mean(magazineBLafter5(:,k))+stdX(k), mean(magazineBLafter5(:,k+1))+stdX(k+1),mean(magazineBLafter5(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(magazineBLafter5),'-','Color',colorcode,'LineWidth',1.5);
title({'Magazine entries','after unpaired sounds','(per 5 sec)'})%probability to enter during 5 sec period; max is 100%; if mouse pokes twice within 5 sec, it is still 100%, to match calculation during sounds
ylabel('Probability [%]');
xlabel('Session')
axis([0 duration 0 40])




% poke histogram rewarded and unrewarded sound early
subplot(5,4,9,'XTick',1:(5*samplerate):(60*samplerate),'XTickLabel',-30:5:30); hold on
fill([(30*samplerate)+1 (30*samplerate)+1 (30*samplerate)+(rewardduration*samplerate),(30*samplerate)+(rewardduration*samplerate)],[0,100,100,0],[0,0.8,0.2],'EdgeColor','None','FaceAlpha',0.3)
plot(mean(PokeHistEarlyCS)*100,'-','Color',colorcode,'LineWidth',1);
plot(mean(PokeHistEarlyS)*100,':','Color',colorcode,'LineWidth',1);
title('Magazine entries Day 1')
xlabel('[sec]')
ylabel('Probability [%]')
axis([(21*2052)+2 2052*45 0 80])
if group==2
    text((2052*37),95,'-  Hit rate ctrl','FontSize',8,'Color',[0.7,0.7,0.7]); % add text
    text((2052*37),88,'-  Hit rate test','FontSize',8,'Color',colorcode); % add text
    text((2052*37),81,'.. FA rate ctrl','FontSize',8,'Color',[0.7,0.7,0.7]); % add text
    text((2052*37),74,'.. FA rate test','FontSize',8,'Color',colorcode); % add text
end

% poke histogram rewarded and unrewarded sound mid
subplot(5,4,10,'XTick',1:(5*samplerate):(60*samplerate),'XTickLabel',-30:5:30); hold on
fill([(30*samplerate)+1 (30*samplerate)+1 (30*samplerate)+(rewardduration*samplerate),(30*samplerate)+(rewardduration*samplerate)],[0,100,100,0],[0,0.8,0.2],'EdgeColor','None','FaceAlpha',0.3)
plot(mean(PokeHistMidCS)*100,'-','Color',colorcode,'LineWidth',1);
plot(mean(PokeHistMidS)*100,':','Color',colorcode,'LineWidth',1);
xlabel('[sec]')
ylabel('Probability [%]')
title('Magazine entries Day 6')
axis([(21*2052)+2 2052*45 0 80])
% 
% poke histogram rewarded and unrewarded sound late
subplot(5,4,11,'XTick',1:(5*samplerate):(60*samplerate),'XTickLabel',-30:5:30); hold on
fill([(30*samplerate)+1 (30*samplerate)+1 (30*samplerate)+(rewardduration*samplerate),(30*samplerate)+(rewardduration*samplerate)],[0,100,100,0],[0,0.8,0.2],'EdgeColor','None','FaceAlpha',0.3)
plot(mean(PokeHistLateCS)*100,'-','Color',colorcode,'LineWidth',1);
plot(mean(PokeHistLateS)*100,':','Color',colorcode,'LineWidth',1);
xlabel('[sec]')
ylabel('Probability [%]')
title('Magazine Entries Day ' + string(duration))
axis([(21*2052)+2 2052*45 0 80])

% % last day hit vs falsealarm plot and response rate for early, mid, late according to https://www.nature.com/articles/srep27389
% subplot(5,4,9); hold on
% for k=1:length(hitrateAll(:,1))
%     plot(hitrateAll(k,6),FArateAll(k,6),'.','Color',colorcode,'LineWidth',1.5);
% end
% title(strcat('Hit and FA rate Day 6'))
% ylabel('FA rate')
% xlabel('Hit rate')

% subplot(5,4,13,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
% plot(mean(Hitrate6)/4,'-','Color',colorcode,'LineWidth',1.5);
% title(strcat('hit and FA rate Day 6'))
% plot(mean(FArate6)/4,':','Color',colorcode,'LineWidth',1.5);
% %title(strcat('FArate Day',' ',string(duration)))
% axis([1 4 0 1])
% xlabel('sounds')
% ylabel('Probability [%]')

subplot(5,4,13,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
discrimination6=(Hitrate6-FArate6)./(Hitrate6+FArate6);
stdX=std(discrimination6)/sqrt(size(discrimination6,1));
    for k=1:3
        errBoxY = [mean(discrimination6(:,k))-stdX(k),mean(discrimination6(:,k))+stdX(k), mean(discrimination6(:,k+1))+stdX(k+1),mean(discrimination6(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discrimination6),'-','Color',colorcode,'LineWidth',1.5);  
title(strcat('Discrimination Index Day 6'))
axis([1 4 0 1])
xlabel('sounds')
ylabel('Discrimination Index')

% subplot(5,4,14,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
% Hitrate6(Hitrate6==4)=3.96;
% Hitrate6(Hitrate6==0)=0.04;
% FArate6(FArate6==4)=3.96;
% FArate6(FArate6==0)=0.04;
% discriminability6=norminv(Hitrate6/4)-norminv(FArate6/4);
% stdX=std(discriminability6)/sqrt(size(discriminability6,1));
%     for k=1:3
%         errBoxY = [mean(discriminability6(:,k))-stdX(k),mean(discriminability6(:,k))+stdX(k), mean(discriminability6(:,k+1))+stdX(k+1),mean(discriminability6(:,k+1))-stdX(k+1)];
%         errBoxX=[k,k,k+1,k+1];
%         fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
%     end
% plot(mean(discriminability6),'-','Color',colorcode,'LineWidth',1.5);
% title(strcat('Discriminability Day 6'))
% axis([1 4 0 4])
% xlabel('sounds')
% ylabel('Discriminability')

% plot hitrate on day 12
subplot(5,4,14,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
discrimination12=(Hitrate12-FArate12)./(Hitrate12+FArate12);
stdX=std(discrimination12)/sqrt(size(discrimination12,1));
    for k=1:3
        errBoxY = [mean(discrimination12(:,k))-stdX(k),mean(discrimination12(:,k))+stdX(k), mean(discrimination12(:,k+1))+stdX(k+1),mean(discrimination12(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discrimination12),'-','Color',colorcode,'LineWidth',1.5);  
title(strcat('Discrimination Index Day 12'))
axis([1 4 0 1])
xlabel('sounds')
ylabel('Discrimination Index')

% subplot(5,4,15,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
% Hitrate12(Hitrate12==4)=3.96;
% Hitrate12(Hitrate12==0)=0.04;
% FArate12(FArate12==4)=3.96;
% FArate12(FArate12==0)=0.04;
% discriminability12=norminv(Hitrate12/4)-norminv(FArate12/4);
% stdX=std(discriminability12)/sqrt(size(discriminability12,1));
%     for k=1:3
%         errBoxY = [mean(discriminability12(:,k))-stdX(k),mean(discriminability12(:,k))+stdX(k), mean(discriminability12(:,k+1))+stdX(k+1),mean(discriminability12(:,k+1))-stdX(k+1)];
%         errBoxX=[k,k,k+1,k+1];
%         fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
%     end
% plot(mean(discriminability12),'-','Color',colorcode,'LineWidth',1.5);
% title(strcat('Discriminability Day 12'))
% axis([1 4 0 4])
% xlabel('sounds')
% ylabel('Discriminability')

subplot(5,4,15,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
discrimination18=(Hitrate18-FArate18)./(Hitrate18+FArate18);
stdX=std(discrimination18)/sqrt(size(discrimination18,1));
    for k=1:3
        errBoxY = [mean(discrimination18(:,k))-stdX(k),mean(discrimination18(:,k))+stdX(k), mean(discrimination18(:,k+1))+stdX(k+1),mean(discrimination18(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discrimination18),'-','Color',colorcode,'LineWidth',1.5);  
title(strcat('Discrimination Index Day 18'))
axis([1 4 0 1])
xlabel('sounds')
ylabel('Discrimination Index')

% subplot(5,4,16,'XTick',1:4,'XTickLabel',{'1-4','5-8','9-12','13-16'}); hold on
% Hitrate18(Hitrate18==4)=3.96;
% Hitrate18(Hitrate18==0)=0.04;
% FArate18(FArate18==4)=3.96;
% FArate18(FArate18==0)=0.04;
% discriminability18=norminv(Hitrate18/4)-norminv(FArate18/4);
% stdX=std(discriminability18)/sqrt(size(discriminability18,1));
%     for k=1:3
%         errBoxY = [mean(discriminability18(:,k))-stdX(k),mean(discriminability18(:,k))+stdX(k), mean(discriminability18(:,k+1))+stdX(k+1),mean(discriminability18(:,k+1))-stdX(k+1)];
%         errBoxX=[k,k,k+1,k+1];
%         fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
%     end
% plot(mean(discriminability18),'-','Color',colorcode,'LineWidth',1.5);
% title(strcat('Discriminability Day 18'))
% axis([1 4 0 4])
% xlabel('sounds')
% ylabel('Discriminability')

% % last day poke rate across whole session; make dot plot and histogram
% subplot(5,4,13); hold on
% ExpertPokesHist=[];
% for k=1:2052*60:1904122-(2052*60);
%     ExpertPokesHist=[ExpertPokesHist,length(find(ExpertPokes>k-1 & ExpertPokes<k+(2052*60)))/60/length(filelist1)];%calculates average poke rate per second per mouse
% end
% plot(ExpertPokesHist,'-','Color',colorcode,'LineWidth',1.5);
% title(strcat('Magazine Entries Day 6'))
% axis([0 1904122/(2052*60) 0 1])
% xlabel('time [min]')
% ylabel('Probability [%]')


% discrimination index across learning
subplot(5,4,17); hold on
stdX=std(discriminationIndex15)/sqrt(size(discriminationIndex15,1));
    for k=1:duration-1
        errBoxY = [mean(discriminationIndex15(:,k))-stdX(k),mean(discriminationIndex15(:,k))+stdX(k), mean(discriminationIndex15(:,k+1))+stdX(k+1),mean(discriminationIndex15(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discriminationIndex15),'-','Color',colorcode,'LineWidth',1.5);
title('Discrimination Index 15')
xlabel('Session')
ylabel('Discrimination Index')
axis([0 duration -0.1 0.8])
if group==2
    text(1,0.8,'ctrl','FontSize',10,'Color',[0.7,0.7,0.7]); % add text
    text(1,0.7,'test','FontSize',10,'Color',colorcode); % add text
end

% performance (d') across learning
subplot(5,4,18); hold on
stdX=std(discriminability15)/sqrt(size(discriminability15,1));
    for k=1:duration-1
        errBoxY = [mean(discriminability15(:,k))-stdX(k),mean(discriminability15(:,k))+stdX(k), mean(discriminability15(:,k+1))+stdX(k+1),mean(discriminability15(:,k+1))-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discriminability15),'-','Color',colorcode,'LineWidth',1.5);
title('Discriminability 15')
xlabel('Session')
ylabel('Performance (d)')
axis([0 duration -0.5 3])

% discrimination index across learning
subplot(5,4,19); hold on
stdX=std(discriminationIndex5,'omitnan')/sqrt((size(discriminationIndex5,1))-sum(isnan(discriminationIndex5(:,1))));
    for k=1:duration-1
        errBoxY = [mean(discriminationIndex5(:,k),'omitnan')-stdX(k),mean(discriminationIndex5(:,k),'omitnan')+stdX(k), mean(discriminationIndex5(:,k+1),'omitnan')+stdX(k+1),mean(discriminationIndex5(:,k+1),'omitnan')-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discriminationIndex5,'omitnan'),'-','Color',colorcode,'LineWidth',1.5);
title('Discrimination Index 1-5')
xlabel('Session')
ylabel('Discrimination Index')
axis([0 duration -0.3 1])

% discrimination index across learning
subplot(5,4,20); hold on
stdX=std(discriminationIndex11to15,'omitnan')/sqrt(size(discriminationIndex11to15,1)-sum(isnan(discriminationIndex11to15(:,1))));
    for k=1:duration-1
        errBoxY = [mean(discriminationIndex11to15(:,k),'omitnan')-stdX(k),mean(discriminationIndex11to15(:,k),'omitnan')+stdX(k), mean(discriminationIndex11to15(:,k+1),'omitnan')+stdX(k+1),mean(discriminationIndex11to15(:,k+1),'omitnan')-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(discriminationIndex11to15,'omitnan'),'-','Color',colorcode,'LineWidth',1.5);
title('Discrimination Index 11-15')
xlabel('Session')
ylabel('Discrimination Index')
axis([0 duration -0.3 1])

% discrimination index difference across learning
subplot(5,4,7); hold on
DiscriminationDiff=discriminationIndex11to15-discriminationIndex5;
stdX=std(DiscriminationDiff,'omitnan')/sqrt(size(DiscriminationDiff,1)-sum(isnan(DiscriminationDiff(:,1))));
    for k=1:duration-1
        errBoxY = [mean(DiscriminationDiff(:,k),'omitnan')-stdX(k),mean(DiscriminationDiff(:,k),'omitnan')+stdX(k), mean(DiscriminationDiff(:,k+1),'omitnan')+stdX(k+1),mean(DiscriminationDiff(:,k+1),'omitnan')-stdX(k+1)];
        errBoxX=[k,k,k+1,k+1];
        fill(errBoxX',errBoxY',colorcode,'FaceAlpha',0.3,'EdgeAlpha',0)
    end
plot(mean(DiscriminationDiff,'omitnan'),'-','Color',colorcode,'LineWidth',1.5);
title({'Within session learning','Discrimination','1-5 vs 11-15'})
xlabel('Session')
ylabel('Discrimination Index Diff')
axis([0 duration -0.5 1])


if group==1
    discriminationIndexCtrl=discriminationIndex;
    discriminabilityCtrl=discriminability;
    latencyHitCtrl=latencyHit;
    latencyFACtrl=latencyFA;
end
end

%plot schematic in first panel
panel1 = imread('S:\MelzerLab\Lab\MatlabScripts\Schematic for reinforcement\Schematic_smalldocument.tiff');
subplot('Position',[0.1 0.77 0.2 0.16],'XTickLabel',[],'XTick',[],'YTickLabel',[],'YTick',[],'YDir','reverse'); hold on
image(panel1)
axis off

%% statistics - now compares day 2-6!!

%% statistics (now based on days 2–6)

%% --- Discrimination index: Ctrl vs Test (days 2–6) ---
vecCtrl_DI = sum(discriminationIndexCtrl(:,2:6),2);
vecKO_DI   = sum(discriminationIndex(:,2:6),2);

pShapiroWilk_Ctrl = swtestSarah(vecCtrl_DI,0.05); % normality ctrl
pShapiroWilk_KO   = swtestSarah(vecKO_DI,0.05);   % normality test
[~,pEqualVariance] = vartest2(vecCtrl_DI,vecKO_DI); % variance equality

disc_testName   = '';
disc_statName   = '';
disc_df         = NaN;
pDiscriminationIndex_raw = NaN;

if min([pShapiroWilk_Ctrl,pShapiroWilk_KO])<=0.05  % non-normal in at least one group
    [pDiscriminationIndex_raw,tDiscriminationIndex,meanrank1,meanrank2] = mwwtestSarah(vecCtrl_DI,vecKO_DI); % Mann–Whitney U
    disc_testName = 'Mann-Whitney U';
    disc_statName = 'U';
    disp(strcat('Discrimination index (Mann-Whitney U test, days 2–6): U=',string(tDiscriminationIndex),' p=',string(pDiscriminationIndex_raw)))
    if pEqualVariance<0.05
        disp('Variance is unequal and data are non-parametric! Consider reporting this in text.')
    end
elseif pEqualVariance>0.05  % equal variance, normal
    [~,pDiscriminationIndex_raw,~,stats] = ttest2(vecCtrl_DI,vecKO_DI); % unpaired t-test
    tDiscriminationIndex = stats.tstat;
    dfDiscriminationIndex = stats.df;
    disc_testName = 'unpaired t-test (equal var)';
    disc_statName = 't';
    disc_df       = dfDiscriminationIndex;
    disp(strcat('Discrimination index (unpaired t-test, days 2–6): t=',string(tDiscriminationIndex),'(',string(dfDiscriminationIndex),'), p=',string(pDiscriminationIndex_raw)))
else % unequal variance, normal
    [~,pDiscriminationIndex_raw,~,stats] = ttest2(vecCtrl_DI,vecKO_DI,'Vartype','unequal'); % Welch t-test
    tDiscriminationIndex = stats.tstat;
    dfDiscriminationIndex = stats.df;
    disc_testName = 'Welch t-test (unequal var)';
    disc_statName = 't';
    disc_df       = dfDiscriminationIndex;
    disp(strcat('Discrimination index (Welch t-test, days 2–6): t=',string(tDiscriminationIndex),'(',string(dfDiscriminationIndex),') p=',string(pDiscriminationIndex_raw)))
end


%% --- Discriminability (d′): Ctrl vs Test (days 2–6) ---
vecCtrl_d = sum(discriminabilityCtrl(:,2:6),2);
vecKO_d   = sum(discriminability(:,2:6),2);

pShapiroWilk_Ctrl = swtestSarah(vecCtrl_d,0.05);
pShapiroWilk_KO   = swtestSarah(vecKO_d,0.05);
[~,pEqualVariance] = vartest2(vecCtrl_d,vecKO_d);

discrim_testName   = '';
discrim_statName   = '';
discrim_df         = NaN;
pdiscriminability_raw = NaN;

if min([pShapiroWilk_Ctrl,pShapiroWilk_KO])<=0.05  % non-normal
    [pdiscriminability_raw,tdiscriminability,meanrank1,meanrank2] = mwwtestSarah(vecCtrl_d,vecKO_d); % Mann–Whitney U
    discrim_testName = 'Mann-Whitney U';
    discrim_statName = 'U';
    disp(strcat('Discriminability (Mann-Whitney U test, days 2–6): U=',string(tdiscriminability),' p=',string(pdiscriminability_raw)))
    if pEqualVariance<0.05
        disp('Variance is unequal and data are non-parametric! Consider reporting this in text.')
    end
elseif pEqualVariance>0.05  % equal variance, normal
    [~,pdiscriminability_raw,~,stats] = ttest2(vecCtrl_d,vecKO_d); % unpaired t-test
    tdiscriminability = stats.tstat;
    dfdiscriminability = stats.df;
    discrim_testName = 'unpaired t-test (equal var)';
    discrim_statName = 't';
    discrim_df       = dfdiscriminability;
    disp(strcat('Discriminability (unpaired t-test, days 2–6): t=',string(tdiscriminability),'(',string(dfdiscriminability),'), p=',string(pdiscriminability_raw)))
else % unequal variance, normal
    [~,pdiscriminability_raw,~,stats] = ttest2(vecCtrl_d,vecKO_d,'Vartype','unequal'); % Welch t-test
    tdiscriminability = stats.tstat;
    dfdiscriminability = stats.df;
    discrim_testName = 'Welch t-test (unequal var)';
    discrim_statName = 't';
    discrim_df       = dfdiscriminability;
    disp(strcat('Discriminability (Welch t-test, days 2–6): t=',string(tdiscriminability),'(',string(dfdiscriminability),') p=',string(pdiscriminability_raw)))
end


%% --- Hit latency: Ctrl vs Test (days 2–6) ---
vecCtrl_lat = sum(latencyHitCtrl(:,2:6),2);
vecKO_lat   = sum(latencyHit(:,2:6),2);

pShapiroWilk_Ctrl = swtestSarah(vecCtrl_lat,0.05);
pShapiroWilk_KO   = swtestSarah(vecKO_lat,0.05);
[~,pEqualVariance] = vartest2(vecCtrl_lat,vecKO_lat);

lat_testName   = '';
lat_statName   = '';
lat_df         = NaN;
platencyHit    = NaN;

if min([pShapiroWilk_Ctrl,pShapiroWilk_KO])<=0.05 % non-normal
    [platencyHit,tlatencyHit,meanrank1,meanrank2] = mwwtestSarah(vecCtrl_lat,vecKO_lat); % Mann–Whitney U
    lat_testName = 'Mann-Whitney U';
    lat_statName = 'U';
    disp(strcat('latencyHit (Mann-Whitney U test, days 2–6): U=',string(tlatencyHit),' p=',string(platencyHit)))
    if pEqualVariance<0.05
        disp('Variance is unequal and data are non-parametric! Consider reporting this in text.')
    end
elseif pEqualVariance>0.05 % equal variance, normal
    [~,platencyHit,~,stats] = ttest2(vecCtrl_lat,vecKO_lat); % unpaired t-test
    tlatencyHit = stats.tstat;
    dflatencyHit = stats.df;
    lat_testName = 'unpaired t-test (equal var)';
    lat_statName = 't';
    lat_df       = dflatencyHit;
    disp(strcat('latencyHit (unpaired t-test, days 2–6): t=',string(tlatencyHit),'(',string(dflatencyHit),'), p=',string(platencyHit)))
else % unequal variance, normal
    [~,platencyHit,~,stats] = ttest2(vecCtrl_lat,vecKO_lat,'Vartype','unequal'); % Welch t-test
    tlatencyHit = stats.tstat;
    dflatencyHit = stats.df;
    lat_testName = 'Welch t-test (unequal var)';
    lat_statName = 't';
    lat_df       = dflatencyHit;
    disp(strcat('latencyHit (Welch t-test, days 2–6): t=',string(tlatencyHit),'(',string(dflatencyHit),') p=',string(platencyHit)))
end


%% --- Holm–Bonferroni correction for DI & d′ (familywise error) ---
raw_p_vec = [pdiscriminability_raw, pDiscriminationIndex_raw];  % [d', DI]
s = size(raw_p_vec);
if isvector(raw_p_vec)
    if size(raw_p_vec,1)>1
        raw_p_vec = raw_p_vec';
    end
    [sorted_p, sort_ids] = sort(raw_p_vec);
end
[~, unsort_ids] = sort(sort_ids);
m = length(sorted_p);
mult_fac = m:-1:1;
cor_p_sorted = sorted_p .* mult_fac;
for i = 2:m
    cor_p_sorted(i) = max(cor_p_sorted(i-1:i)); % Holm step-up
end
corrected_p = cor_p_sorted(unsort_ids);
for i = 1:length(corrected_p)
    if corrected_p(i)>1
        corrected_p(i)=1;
    end
end

% Assign back (order: d', DI)
pdiscriminability = corrected_p(1);
pDiscriminationIndex = corrected_p(2);

disp(strcat('Discrimination index: Bonferroni-Holm corrected p=',string(pDiscriminationIndex)))
disp(strcat('Discriminability: Bonferroni-Holm corrected p=',string(pdiscriminability)))
disp('statistics for discrimination index and discriminability based on sum of values from day 2 to day 6 (all days that would be affected by learning and memory impairment due to CNO); Bonferroni-Holm correction applied for 2 tests')
disp('saved matlab file has discrimination index, discriminability, latencyHit and latencyFA each for control and test')

%% --- Build statsSummary struct for reporting ---
statsSummary = struct();

statsSummary.discriminationIndex.testName    = disc_testName;
statsSummary.discriminationIndex.statName    = disc_statName;
statsSummary.discriminationIndex.statValue   = tDiscriminationIndex;
statsSummary.discriminationIndex.df          = disc_df;
statsSummary.discriminationIndex.p_raw       = pDiscriminationIndex_raw;
statsSummary.discriminationIndex.p_corrected = pDiscriminationIndex;

statsSummary.discriminability.testName    = discrim_testName;
statsSummary.discriminability.statName    = discrim_statName;
statsSummary.discriminability.statValue   = tdiscriminability;
statsSummary.discriminability.df          = discrim_df;
statsSummary.discriminability.p_raw       = pdiscriminability_raw;
statsSummary.discriminability.p_corrected = pdiscriminability;

statsSummary.latencyHit.testName    = lat_testName;
statsSummary.latencyHit.statName    = lat_statName;
statsSummary.latencyHit.statValue   = tlatencyHit;
statsSummary.latencyHit.df          = lat_df;
statsSummary.latencyHit.p_raw       = platencyHit;
statsSummary.latencyHit.p_corrected = platencyHit; % no multiple-comparisons correction here

% %% --- Create and save a figure summarizing the statistics ---
% 
% figStats = figure('Color','w','Position',[200 200 800 300]);
% axis off; hold on;
% 
% y = 0.9; dy = 0.15;
% txt = {
%     sprintf('Discrimination index (sessions 2–6): %s, %s = %.3g, df = %s, p_{raw} = %.3g, p_{corr} = %.3g', ...
%         statsSummary.discriminationIndex.testName, ...
%         statsSummary.discriminationIndex.statName, ...
%         statsSummary.discriminationIndex.statValue, ...
%         ternary(isnan(statsSummary.discriminationIndex.df),'n/a',num2str(statsSummary.discriminationIndex.df)), ...
%         statsSummary.discriminationIndex.p_raw, ...
%         statsSummary.discriminationIndex.p_corrected) ...
%     sprintf('Discriminability d'' (sessions 2–6): %s, %s = %.3g, df = %s, p_{raw} = %.3g, p_{corr} = %.3g', ...
%         statsSummary.discriminability.testName, ...
%         statsSummary.discriminability.statName, ...
%         statsSummary.discriminability.statValue, ...
%         ternary(isnan(statsSummary.discriminability.df),'n/a',num2str(statsSummary.discriminability.df)), ...
%         statsSummary.discriminability.p_raw, ...
%         statsSummary.discriminability.p_corrected) ...
%     sprintf('Hit latency (sessions 2–6): %s, %s = %.3g, df = %s, p = %.3g (no multiple-comparisons correction)', ...
%         statsSummary.latencyHit.testName, ...
%         statsSummary.latencyHit.statName, ...
%         statsSummary.latencyHit.statValue, ...
%         ternary(isnan(statsSummary.latencyHit.df),'n/a',num2str(statsSummary.latencyHit.df)), ...
%         statsSummary.latencyHit.p_raw) ...
%     };
% 
% for iLine = 1:numel(txt)
%     text(0.05, y - (iLine-1)*dy, txt{iLine}, 'Units','normalized', ...
%         'FontSize',10, 'Interpreter','none');
% end
% 
% title({'Go/No-Go statistics summary','(Ctrl vs Test, sessions 2–6)'}, 'FontSize',12);
% 
% % save stats figure in the main folder
% cd(directorynew);
% % saveas(figStats,'Gonogo_stats_summary','png');
% print(figStats,'-depsc','-painters','Gonogo_stats_summary');

%% warnings
if min(latencyHit)==0
    disp('warning: one of the days has to many mice, KO or CNO group')
end
if min(latencyHitCtrl)==0
    disp('warning: one of the days has to many mice, ctrl group')
end

%% save figure
cd(directorynew);
save('Gonogo_analysis','discriminationIndexCtrl','discriminationIndex','discriminabilityCtrl','discriminability','latencyHitCtrl','latencyHit','latencyFACtrl','latencyFA','samplerate')
saveas(gcf,'Gonogo_analysis_summary','png')
print('-depsc','-painters','Gonogo_analysis_summary');
disp('these mice/days were excluded from the within session analysis: first column is mouse number, second column is day')
exclude

%% Shapiro Wilk test
function [pValue,H,W] = swtestSarah(x, alpha)
%SWTEST Shapiro-Wilk parametric hypothesis test of composite normality.
%   [H, pValue, SWstatistic] = SWTEST(X, ALPHA) performs the
%   Shapiro-Wilk test to determine if the null hypothesis of
%   composite normality is a reasonable assumption regarding the
%   population distribution of a random sample X. The desired significance 
%   level, ALPHA, is an optional scalar input (default = 0.05).
%
%   The Shapiro-Wilk and Shapiro-Francia null hypothesis is: 
%   "X is normal with unspecified mean and variance."
%
%   This is an omnibus test, and is generally considered relatively
%   powerful against a variety of alternatives.
%   Shapiro-Wilk test is better than the Shapiro-Francia test for
%   Platykurtic sample. Conversely, Shapiro-Francia test is better than the
%   Shapiro-Wilk test for Leptokurtic samples.
%
%   When the series 'X' is Leptokurtic, SWTEST performs the Shapiro-Francia
%   test, else (series 'X' is Platykurtic) SWTEST performs the
%   Shapiro-Wilk test.
% 
%    [H, pValue, SWstatistic] = SWTEST(X, ALPHA)
%
% Inputs:
%   X - a vector of deviates from an unknown distribution. The observation
%     number must exceed 3 and less than 5000.
%
% Optional inputs:
%   ALPHA - The significance level for the test (default = 0.05).
%  
% Outputs:
%  SWstatistic - The test statistic (non normalized).
%
%   pValue - is the p-value, or the probability of observing the given
%     result by chance given that the null hypothesis is true. Small values
%     of pValue cast doubt on the validity of the null hypothesis.
%
%     H = 0 => Do not reject the null hypothesis at significance level ALPHA.
%     H = 1 => Reject the null hypothesis at significance level ALPHA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                Copyright (c) 17 March 2009 by Ahmed Ben Sada          %
%                 Department of Finance, IHEC Sousse - Tunisia           %
%                       Email: ahmedbensaida@yahoo.com                   %
%                    $ Revision 3.0 $ Date: 18 Juin 2014 $               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%
% References:
%
% - Royston P. "Remark AS R94", Applied Statistics (1995), Vol. 44,
%   No. 4, pp. 547-551.
%   AS R94 -- calculates Shapiro-Wilk normality test and P-value
%   for sample sizes 3 <= n <= 5000. Handles censored or uncensored data.
%   Corrects AS 181, which was found to be inaccurate for n > 50.
%   Subroutine can be found at: http://lib.stat.cmu.edu/apstat/R94
%
% - Royston P. "A pocket-calculator algorithm for the Shapiro-Francia test
%   for non-normality: An application to medicine", Statistics in Medecine
%   (1993a), Vol. 12, pp. 181-184.
%
% - Royston P. "A Toolkit for Testing Non-Normality in Complete and
%   Censored Samples", Journal of the Royal Statistical Society Series D
%   (1993b), Vol. 42, No. 1, pp. 37-43.
%
% - Royston P. "Approximating the Shapiro-Wilk W-test for non-normality",
%   Statistics and Computing (1992), Vol. 2, pp. 117-119.
%
% - Royston P. "An Extension of Shapiro and Wilk's W Test for Normality
%   to Large Samples", Journal of the Royal Statistical Society Series C
%   (1982a), Vol. 31, No. 2, pp. 115-124.
%

%
% Ensure the sample data is a VECTOR.
%

if numel(x) == length(x)
    x  =  x(:);               % Ensure a column vector.
else
    error(' Input sample ''X'' must be a vector.');
end

%
% Remove missing observations indicated by NaN's and check sample size.
%

x  =  x(~isnan(x));

if length(x) < 3
   error(' Sample vector ''X'' must have at least 3 valid observations.');
end

if length(x) > 5000
    warning('Shapiro-Wilk test might be inaccurate due to large sample size ( > 5000).');
end

%
% Ensure the significance level, ALPHA, is a 
% scalar, and set default if necessary.
%

if (nargin >= 2) && ~isempty(alpha)
   if ~isscalar(alpha)
      error(' Significance level ''Alpha'' must be a scalar.');
   end
   if (alpha <= 0 || alpha >= 1)
      error(' Significance level ''Alpha'' must be between 0 and 1.'); 
   end
else
   alpha  =  0.05;
end

% First, calculate the a's for weights as a function of the m's
% See Royston (1992, p. 117) and Royston (1993b, p. 38) for details
% in the approximation.

x       =   sort(x); % Sort the vector X in ascending order.
n       =   length(x);
mtilde  =   norminv(((1:n)' - 3/8) / (n + 1/4));
weights =   zeros(n,1); % Preallocate the weights.

if kurtosis(x) > 3
    
    % The Shapiro-Francia test is better for leptokurtic samples.
    
    weights =   1/sqrt(mtilde'*mtilde) * mtilde;

    %
    % The Shapiro-Francia statistic W' is calculated to avoid excessive
    % rounding errors for W' close to 1 (a potential problem in very
    % large samples).
    %

    W   =   (weights' * x)^2 / ((x - mean(x))' * (x - mean(x)));

    % Royston (1993a, p. 183):
    nu      =   log(n);
    u1      =   log(nu) - nu;
    u2      =   log(nu) + 2/nu;
    mu      =   -1.2725 + (1.0521 * u1);
    sigma   =   1.0308 - (0.26758 * u2);

    newSFstatistic  =   log(1 - W);

    %
    % Compute the normalized Shapiro-Francia statistic and its p-value.
    %

    NormalSFstatistic =   (newSFstatistic - mu) / sigma;
    
    % Computes the p-value, Royston (1993a, p. 183).
    pValue   =   1 - normcdf(NormalSFstatistic, 0, 1);
    
else
    
    % The Shapiro-Wilk test is better for platykurtic samples.

    c    =   1/sqrt(mtilde'*mtilde) * mtilde;
    u    =   1/sqrt(n);

    % Royston (1992, p. 117) and Royston (1993b, p. 38):
    PolyCoef_1   =   [-2.706056 , 4.434685 , -2.071190 , -0.147981 , 0.221157 , c(n)];
    PolyCoef_2   =   [-3.582633 , 5.682633 , -1.752461 , -0.293762 , 0.042981 , c(n-1)];

    % Royston (1992, p. 118) and Royston (1993b, p. 40, Table 1)
    PolyCoef_3   =   [-0.0006714 , 0.0250540 , -0.39978 , 0.54400];
    PolyCoef_4   =   [-0.0020322 , 0.0627670 , -0.77857 , 1.38220];
    PolyCoef_5   =   [0.00389150 , -0.083751 , -0.31082 , -1.5861];
    PolyCoef_6   =   [0.00303020 , -0.082676 , -0.48030];

    PolyCoef_7   =   [0.459 , -2.273];

    weights(n)   =   polyval(PolyCoef_1 , u);
    weights(1)   =   -weights(n);
    
    if n > 5
        weights(n-1) =   polyval(PolyCoef_2 , u);
        weights(2)   =   -weights(n-1);
    
        count  =   3;
        phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2 - 2 * mtilde(n-1)^2) / ...
                (1 - 2 * weights(n)^2 - 2 * weights(n-1)^2);
    else
        count  =   2;
        phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2) / ...
                (1 - 2 * weights(n)^2);
    end
        
    % Special attention when n = 3 (this is a special case).
    if n == 3
        % Royston (1992, p. 117)
        weights(1)  =   1/sqrt(2);
        weights(n)  =   -weights(1);
        phi = 1;
    end

    %
    % The vector 'WEIGHTS' obtained next corresponds to the same coefficients
    % listed by Shapiro-Wilk in their original test for small samples.
    %

    weights(count : n-count+1)  =  mtilde(count : n-count+1) / sqrt(phi);

    %
    % The Shapiro-Wilk statistic W is calculated to avoid excessive rounding
    % errors for W close to 1 (a potential problem in very large samples).
    %

    W   =   (weights' * x) ^2 / ((x - mean(x))' * (x - mean(x)));

    %
    % Calculate the normalized W and its significance level (exact for
    % n = 3). Royston (1992, p. 118) and Royston (1993b, p. 40, Table 1).
    %

    newn    =   log(n);

    if (n >= 4) && (n <= 11)
    
        mu      =   polyval(PolyCoef_3 , n);
        sigma   =   exp(polyval(PolyCoef_4 , n));    
        gam     =   polyval(PolyCoef_7 , n);
    
        newSWstatistic  =   -log(gam-log(1-W));
    
    elseif n > 11
    
        mu      =   polyval(PolyCoef_5 , newn);
        sigma   =   exp(polyval(PolyCoef_6 , newn));
    
        newSWstatistic  =   log(1 - W);
    
    elseif n == 3
        mu      =   0;
        sigma   =   1;
        newSWstatistic  =   0;
    end

    %
    % Compute the normalized Shapiro-Wilk statistic and its p-value.
    %

    NormalSWstatistic   =   (newSWstatistic - mu) / sigma;
    
    % NormalSWstatistic is referred to the upper tail of N(0,1),
    % Royston (1992, p. 119).
    pValue       =   1 - normcdf(NormalSWstatistic, 0, 1);
    
    % Special attention when n = 3 (this is a special case).
    if n == 3
        pValue  =   6/pi * (asin(sqrt(W)) - asin(sqrt(3/4)));
        % Royston (1982a, p. 121)
    end
    
end

%
% To maintain consistency with existing Statistics Toolbox hypothesis
% tests, returning 'H = 0' implies that we 'Do not reject the null 
% hypothesis at the significance level of alpha' and 'H = 1' implies 
% that we 'Reject the null hypothesis at significance level of alpha.'
%

H  = (alpha >= pValue);
end

function [p2,U,mr1,mr2]=mwwtestSarah(x1,x2)
%modified by Sarah to only output p-value for a two-tailed test (if
%difference, it can go in either direction, not possible to predict which
%group is larger), U-statistic (if sample sizes are different, this U-value
%represents the smaller of them), mean rank sum for both samples (mr1, mr2).
%Mann-Whitney-Wilcoxon non parametric test for two unpaired groups.
%This file execute the non parametric Mann-Whitney-Wilcoxon test to evaluate the
%difference between unpaired samples. If the number of combinations is less than
%20000, the algorithm calculates the exact ranks distribution; else it 
%uses a normal distribution approximation. The result is not different from
%RANKSUM MatLab function, but there are more output informations.
%There is an alternative formulation of this test that yields a statistic
%commonly denoted by U. Also the U statistic is computed.
%
% Syntax: 	STATS=MWWTEST(X1,X2)
%      
%     Inputs:
%           X1 and X2 - data vectors. 
%     Outputs:
%           - T and U values and p-value when exact ranks distribution is used.
%           - T and U values, mean, standard deviation, Z value, and p-value when
%           normal distribution is used.
%        If STATS nargout was specified the results will be stored in the STATS
%        struct.
%
%      Example: 
%
%         X1=[181 183 170 173 174 179 172 175 178 176 158 179 180 172 177];
% 
%         X2=[168 165 163 175 176 166 163 174 175 173 179 180 176 167 176];
%
%           Calling on Matlab the function: mwwtest(X1,X2)
%
%           Answer is:
%
% MANN-WHITNEY-WILCOXON TEST
% ---------------------------------------------------------------------------
%                                   Group 1         Group 2
% numerosity                		15              15
% Sum of Ranks (W)                  270.0           195.0
% Mean rank                         18.0            13.0
% Test variable (U)                 75.0            150.0
% ---------------------------------------------------------------------------
% Sample size is large enough to use the normal distribution approximation
% Mean                                      112.5
% Standard deviation corrected for ties     24.0474
% Z corrected for continuity        1.5386          1.5386
% p-value (1-tailed)                        0.06195
% p-value (2-tailed)                        0.12389
% ---------------------------------------------------------------------------
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
%
% To cite this file, this would be an appropriate format:
% Cardillo G. (2009). MWWTEST: Mann-Whitney-Wilcoxon non parametric test for two unpaired samples.
% http://www.mathworks.com/matlabcentral/fileexchange/25830

%Input Error handling
if ~isvector(x1) || ~isvector(x2)
   error('MWWTEST requires vector rather than matrix data.');
end 
if ~all(isfinite(x1)) || ~all(isnumeric(x1)) || ~all(isfinite(x2)) || ~all(isnumeric(x2))
    error('Warning: all X1 and X2 values must be numeric and finite')
end

%set the basic parameter
n1=length(x1); n2=length(x2); NP=n1*n2; N=n1+n2; N1=N+1; k=min([n1 n2]);

[A,B]=tiedrank([x1(:); x2(:)]); %compute the ranks and the ties
R1=A(1:n1); R2=A(n1+1:end); 
T1=sum(R1); T2=sum(R2);
U1=NP+(n1*(n1+1))/2-T1; U2=NP-U1;
tr=repmat('-',1,75); %set the divisor
% disp('MANN-WHITNEY-WILCOXON TEST')
% disp(tr)
% fprintf('\t\t\t\tGroup 1\t\tGroup 2\n')
% fprintf('numerosity\t\t\t%i\t\t%i\n',n1,n2)
% fprintf('Sum of Ranks (W)\t\t%0.1f\t\t%0.1f\n',T1,T2)
% fprintf('Mean rank\t\t\t%0.1f\t\t%0.1f\n',T1/n1,T2/n2)
% fprintf('Test variable (U)\t\t%0.1f\t\t%0.1f\n',U1,U2)
% disp(tr)
% if nargout
%     STATS.n=[n1 n2];
%     STATS.W=[T1 T2];
%     STATS.mr=[T1/n1 T2/n2];
%     STATS.U=[U1 U2];
% end    
mr1=T1/n1;
mr2=T2/n2;
U=min([U1,U2]);
if round(exp(gammaln(N1)-gammaln(k+1)-gammaln(N1-k))) > 20000
    mU=NP/2;
    if B==0
        sU=realsqrt(NP*N1/12);
    else
        sU=realsqrt((NP/(N^2-N))*((N^3-N-2*B)/12));
    end
    Z1=(abs(U1-mU)-0.5)/sU; Z2=(abs(U2-mU)-0.5)/sU; 
    p=1-normcdf(Z1); %p-value
%     disp('Sample size is large enough to use the normal distribution approximation')
%     fprintf('Mean\t\t\t\t\t%0.1f\n',mU)
%     if B==0
%         fprintf('Standard deviation\t\t\t%0.4f\n',sU)
%     else
%         fprintf('Standard deviation corrected for ties\t%0.4f\n',sU)
%     end
%     fprintf('Z corrected for continuity\t%0.4f\t\t%0.4f\n',Z1,Z2)
%     fprintf('p-value (1-tailed)\t\t\t%0.5f\n',p)
%     fprintf('p-value (2-tailed)\t\t\t%0.5f\n',2*p)
%     if nargout
%         STATS.method='Normal approximation';
%         STATS.mU=mU;
%         STATS.sU=sU;
%         STATS.Z=Z1;
%         STATS.p=[p 2*p];
%     end
else
%     disp('Sample size is small enough to use the exact Mann-Whitney-Wilcoxon distribution')
    if n1<=n2
        w=T1;
    else
        w=T2;
    end
    pdf=sum(nchoosek(A,k),2);
    P = [sum(pdf<=w) sum(pdf>=w)]./length(pdf);
    p = min(P);
%     fprintf('Test variable (W)\t\t\t%0.1f\n',w)
%     fprintf('p-value (1-tailed)\t\t\t%0.5f\n',p)
%     fprintf('p-value (2-tailed)\t\t\t%0.5f\n',2*p)
%     if nargout
%         STATS.method='Exact distribution';
%         STATS.T=w;
%         STATS.p=[p 2*p];
%     end
end
p2=2*p;
end

function out = ternary(cond, a, b)
% Simple inline ternary helper: out = a if cond is true, else b
if cond
    out = a;
else
    out = b;
end
end
