%move all *_behavior data into a summary folder with 2 subfolders: 'test' and 'ctrl'

%when the script opens the GUI to select a folder, select the summary
%folder that contains both subfolders.
addpath('S:\MelzerLab\Lab\MatlabScripts');
close all

%% choose folder with all data
directorynew=uigetdir;%select the folder that has the two subfolders 'test' and 'ctrl'
directoryctrl=strcat(directorynew,'/ctrl');
directoryKO=strcat(directorynew,'/test');
cd(directorynew);

filenamesave='Results_summary';%;
D=dir([directoryctrl,'\*.mat']);
samplesizectrl=length(D);
E=dir([directoryKO,'\*.mat']);
samplesizeKO=length(E);

%% create variables
instim=5;%number of sounds to analyze as early freezing
latestim=1;%1 if you want to plot freezing to all sounds; or choose any other number where freezing calculation should start;
width=10; %the denser scatter needs to be (because of many cells), the higher number
ColorKO=[203/255 141/255 255/255];
ColorKO_BG=[226/255 199/255 255/255];
ColorCtrl=[33/255 129/255 151/255];
ColorCtrl_BG=[198/255 234/255 242/255];
lines=1;%1 if dots in figure 2 should be connected, 0 if not.
step=5;
uppervalue=100;
groups=10;

close all
freezingbaselineoriginalctrl=zeros(1,samplesizectrl);
freezingsoundlistoriginalctrl=zeros(15,samplesizectrl);
freezingunpairedsoundlistoriginalctrl=zeros(15,samplesizectrl);
freezingaftershocklistoriginalctrl=zeros(15,samplesizectrl);
freezingafterunpairedsoundlistoriginalctrl=zeros(15,samplesizectrl);
CSfreezing=zeros(samplesizectrl,3500);
USfreezing=zeros(samplesizectrl,3500);
CSfreezinglate=zeros(samplesizectrl,3500);
USfreezinglate=zeros(samplesizectrl,3500);
boutnumberBLctrl=zeros(samplesizectrl,1);
boutnumberCSctrl=zeros(samplesizectrl,1);
boutnumberUSctrl=zeros(samplesizectrl,1);
boutlengthBLctrl=zeros(samplesizectrl,1);
boutlengthCSctrl=zeros(samplesizectrl,1);
boutlengthUSctrl=zeros(samplesizectrl,1);
TA_MotionIndexShockctrl=zeros(samplesizectrl,1801);
TAshocksspeedctrl=zeros(samplesizectrl,1801);
TA_MotionIndexShockctrl5=zeros(samplesizectrl,1801);
TA_MotionIndexShockctrl1=zeros(samplesizectrl,1801);
MotionIndexBaselinectrl=zeros(samplesizectrl,1);
MotionIndexSoundctrl=zeros(samplesizectrl,1);
MotionIndexSoundUPctrl=zeros(samplesizectrl,1);
MotionIndexShockctrl=zeros(samplesizectrl,1);
MotionIndex1sAfterShockctrl=zeros(samplesizectrl,1);
MotionIndex2sAfterShockctrl=zeros(samplesizectrl,1);
MotionIndex3sAfterShockctrl=zeros(samplesizectrl,1);
MotionIndex4sAfterShockctrl=zeros(samplesizectrl,1);
MotionIndex5sAfterShockctrl=zeros(samplesizectrl,1);

for i=1:samplesizectrl
    load([directoryctrl,'\',D(i).name]);
    freezingbaselineoriginalctrl(i)=freezingbaseline;%
    freezingsoundlistoriginalctrl(:,i)=freezingsoundlist';%
    freezingunpairedsoundlistoriginalctrl(:,i)=freezingunpairedsoundlist';
    freezingtrace=zeros(length(framediffthresholded),1);freezingtrace(freezing)=1;
    TACSfreezing=zeros(15,3500);TAUSfreezing=zeros(15,3500);
    for j=1:15
        TACSfreezing(j,:)=freezingtrace(sound_paired(1,j)-900:sound_paired(1,j)+2599);
        TAUSfreezing(j,:)=freezingtrace(sound_unpaired(1,j)-900:sound_unpaired(1,j)+2599);
    end
    boutnumberBLctrl(i)=length(find((freezingtrace(2:3590)-freezingtrace(1:3589))==1))+freezingtrace(1);
    boutnumberCSctrl(i)=length(find((TACSfreezing(:,902:1800)-TACSfreezing(:,901:1799))==1))+length(find(TACSfreezing(:,901)==1));
    boutnumberUSctrl(i)=length(find((TAUSfreezing(:,902:1800)-TAUSfreezing(:,901:1799))==1))+length(find(TAUSfreezing(:,901)==1));
    boutlengthBLctrl(i)=sum(freezingtrace(1:3590))/boutnumberBLctrl(i);
    boutlengthCSctrl(i)=sum(sum(TACSfreezing(:,901:1800)))/boutnumberCSctrl(i);
    boutlengthUSctrl(i)=sum(sum(TAUSfreezing(:,901:1800)))/boutnumberUSctrl(i);
    if instim>1
        CSfreezing(i,:)=mean(TACSfreezing(1:instim,:));
        USfreezing(i,:)=mean(TAUSfreezing(1:instim,:));
    else
        CSfreezing(i,:)=(TACSfreezing(1,:));
        USfreezing(i,:)=(TAUSfreezing(1,:));
    end
    CSfreezinglate(i,:)=mean(TACSfreezing(latestim:15,:));
    USfreezinglate(i,:)=mean(TAUSfreezing(latestim:15,:));
    TA_MotionIndexShock=zeros(15,1801);
    for j=1:15
        TA_MotionIndexShock(j,:)=framediff(round(shocks(1,j)-900):round(shocks(1,j)+900));
    end
    TA_MotionIndexShockctrl(i,:)=mean(TA_MotionIndexShock);
    TAshocksspeed=zeros(15,1801);
    for j=1:length(shocks)
        TAshocksspeed(j,:)=speed(round(shocks(1,j)-900):round(shocks(1,j)+900))';
    end
    TAshocksspeedctrl(i,:)=mean(TAshocksspeed);
    TA_MotionIndexShockctrl5(i,:)=mean(TA_MotionIndexShock(1:instim,:));
    TA_MotionIndexShockctrl1(i,:)=TA_MotionIndexShock(1,:);
    MotionIndexBaselinectrl(i)=MotionIndexBaseline;
    MotionIndexSoundctrl(i)=MotionIndexSound(1);
    MotionIndexSoundUPctrl(i)=MotionIndexSoundUP(1);
    MotionIndexShockctrl(i)=MotionIndexShock(1);
    MotionIndex1sAfterShockctrl(i)=(MotionIndex1sAfterShock(1));
    MotionIndex2sAfterShockctrl(i)=(MotionIndex2sAfterShock(1));
    MotionIndex3sAfterShockctrl(i)=(MotionIndex3sAfterShock(1));
    MotionIndex4sAfterShockctrl(i)=(MotionIndex4sAfterShock(1));
    MotionIndex5sAfterShockctrl(i)=(MotionIndex5sAfterShock(1));

end


freezingbaselineoriginalKO=zeros(1,samplesizeKO);
freezingsoundlistoriginalKO=zeros(15,samplesizeKO);
freezingunpairedsoundlistoriginalKO=zeros(15,samplesizeKO);
CSfreezingKO=zeros(samplesizeKO,3500);
USfreezingKO=zeros(samplesizeKO,3500);
CSfreezingKOlate=zeros(samplesizeKO,3500);
USfreezingKOlate=zeros(samplesizeKO,3500);
boutnumberBLKO=zeros(samplesizeKO,1);
boutnumberCSKO=zeros(samplesizeKO,1);
boutnumberUSKO=zeros(samplesizeKO,1);
boutlengthBLKO=zeros(samplesizeKO,1);
boutlengthCSKO=zeros(samplesizeKO,1);
boutlengthUSKO=zeros(samplesizeKO,1);
TA_MotionIndexShockKO=zeros(samplesizeKO,1801);
TAshocksspeedKO=zeros(samplesizectrl,1801);
TA_MotionIndexShockKO5=zeros(samplesizeKO,1801);
TA_MotionIndexShockKO1=zeros(samplesizeKO,1801);
MotionIndexBaselineKO=zeros(samplesizeKO,1);
MotionIndexSoundKO=zeros(samplesizeKO,1);
MotionIndexSoundUPKO=zeros(samplesizeKO,1);
MotionIndexShockKO=zeros(samplesizeKO,1);
MotionIndex1sAfterShockKO=zeros(samplesizeKO,1);
MotionIndex2sAfterShockKO=zeros(samplesizeKO,1);
MotionIndex3sAfterShockKO=zeros(samplesizeKO,1);
MotionIndex4sAfterShockKO=zeros(samplesizeKO,1);
MotionIndex5sAfterShockKO=zeros(samplesizeKO,1);
for i=1:samplesizeKO
    load([directoryKO,'\',E(i).name]);
    freezingbaselineoriginalKO(i)=freezingbaseline;%
    freezingsoundlistoriginalKO(:,i)=freezingsoundlist';%
    freezingunpairedsoundlistoriginalKO(:,i)=freezingunpairedsoundlist';
    freezingtrace=zeros(length(framediffthresholded),1);freezingtrace(freezing)=1;
    TACSfreezingKO=zeros(15,3500);TAUSfreezingKO=zeros(15,3500);
    for j=1:15
        TACSfreezingKO(j,:)=freezingtrace(sound_paired(1,j)-900:sound_paired(1,j)+2599);
        TAUSfreezingKO(j,:)=freezingtrace(sound_unpaired(1,j)-900:sound_unpaired(1,j)+2599);
    end
    boutnumberBLKO(i)=length(find((freezingtrace(2:3590)-freezingtrace(1:3589))==1))+freezingtrace(1);
    boutnumberCSKO(i)=length(find((TACSfreezingKO(:,902:1800)-TACSfreezingKO(:,901:1799))==1))+length(find(TACSfreezingKO(:,901)==1));
    boutnumberUSKO(i)=length(find((TAUSfreezingKO(:,902:1800)-TAUSfreezingKO(:,901:1799))==1))+length(find(TAUSfreezingKO(:,901)==1));
    boutlengthBLKO(i)=sum(freezingtrace(1:3590))/boutnumberBLKO(i);
    boutlengthCSKO(i)=sum(sum(TACSfreezingKO(:,901:1800)))/boutnumberCSKO(i);
    boutlengthUSKO(i)=sum(sum(TAUSfreezingKO(:,901:1800)))/boutnumberUSKO(i);
    if instim>1
        CSfreezingKO(i,:)=mean(TACSfreezingKO(1:instim,:));
        USfreezingKO(i,:)=mean(TAUSfreezingKO(1:instim,:));
    else
        CSfreezingKO(i,:)=(TACSfreezingKO(1,:));
        USfreezingKO(i,:)=(TAUSfreezingKO(1,:));
    end
    CSfreezingKOlate(i,:)=mean(TACSfreezingKO(latestim:15,:));
    USfreezingKOlate(i,:)=mean(TAUSfreezingKO(latestim:15,:));
    TA_MotionIndexShock=zeros(15,1801);
    for j=1:15
        TA_MotionIndexShock(j,:)=framediff(round(shocks(1,j)-900):round(shocks(1,j)+900));
    end
    TA_MotionIndexShockKO(i,:)=mean(TA_MotionIndexShock);
        TAshocksspeed=zeros(15,1801);
    for j=1:length(shocks)
        TAshocksspeed(j,:)=speed(round(shocks(1,j)-900):round(shocks(1,j)+900))';
    end
    TAshocksspeedKO(i,:)=mean(TAshocksspeed);
    TA_MotionIndexShockKO5(i,:)=mean(TA_MotionIndexShock(1:instim,:));
    TA_MotionIndexShockKO1(i,:)=TA_MotionIndexShock(1,:);
    MotionIndexBaselineKO(i)=MotionIndexBaseline;
    MotionIndexSoundKO(i)=MotionIndexSound(1);
    MotionIndexSoundUPKO(i)=MotionIndexSoundUP(1);
    MotionIndexShockKO(i)=(MotionIndexShock(1));
    MotionIndex1sAfterShockKO(i)=(MotionIndex1sAfterShock(1));
    MotionIndex2sAfterShockKO(i)=(MotionIndex2sAfterShock(1));
    MotionIndex3sAfterShockKO(i)=(MotionIndex3sAfterShock(1));
    MotionIndex4sAfterShockKO(i)=(MotionIndex4sAfterShock(1));
    MotionIndex5sAfterShockKO(i)=(MotionIndex5sAfterShock(1));
end
boutlengthBLctrl(boutnumberBLctrl==0)=0;
boutlengthCSctrl(boutnumberCSctrl==0)=0;
boutlengthUSctrl(boutnumberUSctrl==0)=0;

boutlengthBLKO(boutnumberBLKO==0)=0;
boutlengthCSKO(boutnumberCSKO==0)=0;
boutlengthUSKO(boutnumberUSKO==0)=0;

freezingbaselinectrl=freezingbaselineoriginalctrl;
if instim>1
    freezingsoundlistctrl=mean(freezingsoundlistoriginalctrl(1:instim,:));
    freezingunpairedsoundlistctrl=mean(freezingunpairedsoundlistoriginalctrl(1:instim,:));
else
    freezingsoundlistctrl=(freezingsoundlistoriginalctrl(1,:));
    freezingunpairedsoundlistctrl=(freezingunpairedsoundlistoriginalctrl(1,:));
end

freezingbaselineKO=freezingbaselineoriginalKO;
if instim>1
    freezingsoundlistKO=mean(freezingsoundlistoriginalKO(1:instim,:));
    freezingunpairedsoundlistKO=mean(freezingunpairedsoundlistoriginalKO(1:instim,:));
else
    freezingsoundlistKO=(freezingsoundlistoriginalKO(1,:));
    freezingunpairedsoundlistKO=(freezingunpairedsoundlistoriginalKO(1,:));
end

%% make figure 1
figure('Position',[100 100 1700 900]);subplot(3,6,7,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,4,7],'FontName','Arial','FontSize',14);
hold on;
plot(zeros(samplesizectrl,1)+1,boutnumberBLctrl/1.9944,'.','Color',ColorCtrl,'MarkerSize',10);plot([0.7,1.3],[mean(boutnumberBLctrl/1.9944),mean(boutnumberBLctrl/1.9944)],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizeKO,1)+2,boutnumberBLKO/1.9944,'.','Color',ColorKO,'MarkerSize',10);plot([1.7,2.3],[mean(boutnumberBLKO/1.9944),mean(boutnumberBLKO/1.9944)],'-','Color',ColorKO,'LineWidth',2)
plot(zeros(samplesizectrl,1)+4,boutnumberCSctrl/7.5,'.','Color',ColorCtrl,'MarkerSize',10);plot([3.7,4.3],[mean(boutnumberCSctrl/7.5),mean(boutnumberCSctrl/7.5)],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizectrl,1)+7,boutnumberUSctrl/7.5,'.','Color',ColorCtrl,'MarkerSize',10);plot([6.7,7.3],[mean(boutnumberUSctrl/7.5),mean(boutnumberUSctrl/7.5)],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizeKO,1)+5,boutnumberCSKO/7.5,'.','Color',ColorKO,'MarkerSize',10);plot([4.7,5.3],[mean(boutnumberCSKO/7.5),mean(boutnumberCSKO/7.5)],'-','Color',ColorKO,'LineWidth',2)
plot(zeros(samplesizeKO,1)+8,boutnumberUSKO/7.5,'.','Color',ColorKO,'MarkerSize',10);plot([7.7,8.3],[mean(boutnumberUSKO/7.5),mean(boutnumberUSKO/7.5)],'-','Color',ColorKO,'LineWidth',2)
ylabel('bouts per min')

subplot(3,6,8,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,4,7],'FontName','Arial','FontSize',14);
hold on;
plot(zeros(samplesizectrl,1)+1,boutlengthBLctrl/30,'.','Color',ColorCtrl,'MarkerSize',10);plot([0.7,1.3],[mean(boutlengthBLctrl)/30,mean(boutlengthBLctrl)/30],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizeKO,1)+2,boutlengthBLKO/30,'.','Color',ColorKO,'MarkerSize',10);plot([1.7,2.3],[mean(boutlengthBLKO)/30,mean(boutlengthBLKO)/30],'-','Color',ColorKO,'LineWidth',2)
plot(zeros(samplesizectrl,1)+4,boutlengthCSctrl/30,'.','Color',ColorCtrl,'MarkerSize',10);plot([3.7,4.3],[mean(boutlengthCSctrl)/30,mean(boutlengthCSctrl)/30],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizectrl,1)+7,boutlengthUSctrl/30,'.','Color',ColorCtrl,'MarkerSize',10);plot([6.7,7.3],[mean(boutlengthUSctrl)/30,mean(boutlengthUSctrl)/30],'-','Color',ColorCtrl,'LineWidth',2)
plot(zeros(samplesizeKO,1)+5,boutlengthCSKO/30,'.','Color',ColorKO,'MarkerSize',10);plot([4.7,5.3],[mean(boutlengthCSKO)/30,mean(boutlengthCSKO)/30],'-','Color',ColorKO,'LineWidth',2)
plot(zeros(samplesizeKO,1)+8,boutlengthUSKO/30,'.','Color',ColorKO,'MarkerSize',10);plot([7.7,8.3],[mean(boutlengthUSKO)/30,mean(boutlengthUSKO)/30],'-','Color',ColorKO,'LineWidth',2)
ylabel('bout length [sec]')

%% make figure 1, freezing during first 5 stimuli or whatever is indicated by variable 'instim'
averageXa=mean(freezingbaselinectrl);stdXa=std(freezingbaselinectrl);
averageXb=mean(freezingbaselineKO);stdXb=std(freezingbaselineKO);
averageYa=mean(freezingsoundlistctrl);stdYa=std(freezingsoundlistctrl);
averageYb=mean(freezingsoundlistKO);stdYb=std(freezingsoundlistKO);
averageZa=mean(freezingunpairedsoundlistctrl);stdZa=std(freezingunpairedsoundlistctrl);
averageZb=mean(freezingunpairedsoundlistKO);stdZb=std(freezingunpairedsoundlistKO);


subplot(3,6,1,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,4,7],'FontName','Arial','FontSize',14);
hold on;
ylabel('Freezing trial 1-5 [%]','FontName','Arial','FontSize',14);title('Mean,SEM','FontName','Arial','FontSize',12)
text(1,90,'ctrl','FontSize',12,'Color',ColorCtrl); % add text
text(1,75,'KO','FontSize',12,'Color',ColorKO); % add text
fill([0.7,0.7,1.3,1.3],[averageXa-(stdXa/sqrt(samplesizectrl)),averageXa+(stdXa/sqrt(samplesizectrl)),averageXa+(stdXa/sqrt(samplesizectrl)),averageXa-(stdXa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([0.7 1.3],[averageXa,averageXa],'Color',ColorCtrl,'LineWidth',2)
fill([1.7,1.7,2.3,2.3],[averageXb-(stdXb/sqrt(samplesizeKO)),averageXb+(stdXb/sqrt(samplesizeKO)),averageXb+(stdXb/sqrt(samplesizeKO)),averageXb-(stdXb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([1.7 2.3],[averageXb,averageXb],'Color',ColorKO,'LineWidth',2)
fill([3.7,3.7,4.3,4.3],[averageYa-(stdYa/sqrt(samplesizectrl)),averageYa+(stdYa/sqrt(samplesizectrl)),averageYa+(stdYa/sqrt(samplesizectrl)),averageYa-(stdYa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([3.7 4.3],[averageYa,averageYa],'Color',ColorCtrl,'LineWidth',2)
fill([4.7,4.7,5.3,5.3],[averageYb-(stdYb/sqrt(samplesizeKO)),averageYb+(stdYb/sqrt(samplesizeKO)),averageYb+(stdYb/sqrt(samplesizeKO)),averageYb-(stdYb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([4.7 5.3],[averageYb,averageYb],'Color',ColorKO,'LineWidth',2)
fill([6.7,6.7,7.3,7.3],[averageZa-(stdZa/sqrt(samplesizectrl)),averageZa+(stdZa/sqrt(samplesizectrl)),averageZa+(stdZa/sqrt(samplesizectrl)),averageZa-(stdZa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([6.7 7.3],[averageZa,averageZa],'Color',ColorCtrl,'LineWidth',2)
fill([7.7,7.7,8.3,8.3],[averageZb-(stdZb/sqrt(samplesizeKO)),averageZb+(stdZb/sqrt(samplesizeKO)),averageZb+(stdZb/sqrt(samplesizeKO)),averageZb-(stdZb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([7.7 8.3],[averageZb,averageZb],'Color',ColorKO,'LineWidth',2)

averageYa=mean(freezingsoundlistctrl-freezingbaselinectrl);stdYa=std(freezingsoundlistctrl-freezingbaselinectrl);
averageYb=mean(freezingsoundlistKO-freezingbaselineKO);stdYb=std(freezingsoundlistKO-freezingbaselineKO);
averageZa=mean(freezingunpairedsoundlistctrl-freezingbaselinectrl);stdZa=std(freezingunpairedsoundlistctrl-freezingbaselinectrl);
averageZb=mean(freezingunpairedsoundlistKO-freezingbaselineKO);stdZb=std(freezingunpairedsoundlistKO-freezingbaselineKO);
subplot(3,6,2,'XTickLabel',{'CS+','CS-'},'XTickLabelRotation',45,'XTick',[4,7],'FontName','Arial','FontSize',14);
hold on;
ylabel('Freezing trial 1-5 [%]','FontName','Arial','FontSize',14);title('Mean,SEM,-BL','FontName','Arial','FontSize',12)
text(3,90,'ctrl','FontSize',12,'Color',ColorCtrl); % add text
text(3,75,'KO','FontSize',12,'Color',ColorKO); % add text
fill([3.7,3.7,4.3,4.3],[averageYa-(stdYa/sqrt(samplesizectrl)),averageYa+(stdYa/sqrt(samplesizectrl)),averageYa+(stdYa/sqrt(samplesizectrl)),averageYa-(stdYa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([3.7 4.3],[averageYa,averageYa],'Color',ColorCtrl,'LineWidth',2)
fill([4.7,4.7,5.3,5.3],[averageYb-(stdYb/sqrt(samplesizeKO)),averageYb+(stdYb/sqrt(samplesizeKO)),averageYb+(stdYb/sqrt(samplesizeKO)),averageYb-(stdYb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([4.7 5.3],[averageYb,averageYb],'Color',ColorKO,'LineWidth',2)
fill([6.7,6.7,7.3,7.3],[averageZa-(stdZa/sqrt(samplesizectrl)),averageZa+(stdZa/sqrt(samplesizectrl)),averageZa+(stdZa/sqrt(samplesizectrl)),averageZa-(stdZa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([6.7 7.3],[averageZa,averageZa],'Color',ColorCtrl,'LineWidth',2)
fill([7.7,7.7,8.3,8.3],[averageZb-(stdZb/sqrt(samplesizeKO)),averageZb+(stdZb/sqrt(samplesizeKO)),averageZb+(stdZb/sqrt(samplesizeKO)),averageZb-(stdZb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([7.7 8.3],[averageZb,averageZb],'Color',ColorKO,'LineWidth',2)


subplot(3,6,1);hold on
maxrand=[];
for i=0:step:uppervalue;
    j=freezingbaselinectrl;
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot((xcoord/width)+1,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
        
    end
end

for i=0:step:uppervalue;
    j=freezingbaselineKO;
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
       plot(((xcoord)/width)+2,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end

for p=1:2 %
    subplot(3,6,p); 
if groups>2;
for i=0:step:uppervalue;
    j=freezingsoundlistctrl;
    if p==2
        j=freezingsoundlistctrl-freezingbaselinectrl;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+4,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
    end
end
end

if groups>3;
for i=0:step:uppervalue;
    j=freezingsoundlistKO;
     if p==2
        j=freezingsoundlistKO-freezingbaselineKO;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+5,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
end

if groups>4;
for i=0:step:uppervalue;
    j=freezingunpairedsoundlistctrl;
    if p==2
        j=freezingunpairedsoundlistctrl-freezingbaselinectrl;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+7,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
    end
end
end

for i=0:step:uppervalue;
    j=freezingunpairedsoundlistKO;
    if p==2
        j=freezingunpairedsoundlistKO-freezingbaselineKO;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+8,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
if p==2
    axis([2 9 0 100])
else
    axis([0 9 0 100])
end
end

%line plot
subplot(3,6,3,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,2,3],'FontName','Arial','FontSize',14);
ylabel('Freezing trial 1-5 [%]','FontName','Arial','FontSize',14);title('Mean,SEM','FontName','Arial','FontSize',12)
hold on 
freezingallctrl=[freezingbaselinectrl;freezingsoundlistctrl;freezingunpairedsoundlistctrl];
freezingallKO=[freezingbaselineKO;freezingsoundlistKO;freezingunpairedsoundlistKO];
if lines==1
    plot(freezingallctrl,'-','Color',ColorCtrl)
    plot(freezingallKO,'-','Color',ColorKO)
end
axis([0.5 3.5 0 100])

%discrimination index based on first 5 sounds or whatever indicated
subplot(3,6,6,'XTickLabel',{'ctrl','KO'},'XTickLabelRotation',45,'XTick',[1,2],'FontName','Arial','FontSize',14);
hold on 
ylabel('Discrimination index','FontName','Arial','FontSize',14)
title('Discrimination 1-5','FontName','Arial','FontSize',14)
freezingratioctrl=[(freezingsoundlistctrl-freezingunpairedsoundlistctrl)./(freezingsoundlistctrl+freezingunpairedsoundlistctrl)];
freezingratioKO=[(freezingsoundlistKO-freezingunpairedsoundlistKO)./(freezingsoundlistKO+freezingunpairedsoundlistKO)];

averageXa=nanmean(freezingratioctrl);
averageXb=nanmean(freezingratioKO);
stdXa=nanstd(freezingratioctrl);
stdXb=nanstd(freezingratioKO);
fill([0.7,0.7,1.3,1.3],[averageXa-(stdXa/sqrt(samplesizectrl)),averageXa+(stdXa/sqrt(samplesizectrl)),averageXa+(stdXa/sqrt(samplesizectrl)),averageXa-(stdXa/sqrt(samplesizectrl))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
for i=-100:0.1:100;
    j=freezingratioctrl;
    j=j(~isnan(j));
    j(find(j<i))=[];
    j(find(j>=i+0.1))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot((xcoord/width)+1,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
        
    end
end
plot([0.7 1.3],[averageXa,averageXa],'Color',ColorCtrl,'LineWidth',2)
fill([1.7,1.7,2.3,2.3],[averageXb-(stdXb/sqrt(samplesizeKO)),averageXb+(stdXb/sqrt(samplesizeKO)),averageXb+(stdXb/sqrt(samplesizeKO)),averageXb-(stdXb/sqrt(samplesizeKO))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
for i=-100:0.1:100
    j=freezingratioKO;
    j=j(~isnan(j));
    j(find(j<i))=[];
    j(find(j>=i+0.1))=[];
    if length(j)>0
        if length(j)==1
            xcoord=0;
        end
       if length(j)==2
           xcoord=[-2,2];
       end
       if length(j)==3
           xcoord=[-3,0,3];
       end
       if length(j)>3
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
       plot((xcoord/width)+2,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
hold on
plot([1.7 2.3],[averageXb,averageXb],'Color',ColorKO,'LineWidth',2)
axis([0.5 2.5 -1 1])

% calculate p values for first 5 stimuli, or whatever number is indicated above (instim):
[~,p_baseline]=ttest2(freezingbaselinectrl,freezingbaselineKO)
[~,p_CS_early]=ttest2(freezingsoundlistctrl,freezingsoundlistKO)
[~,p_CS_early_subBL]=ttest2(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO)
[~,p_discrimination_early]=ttest2(freezingratioctrl,freezingratioKO)

%% Figure 1, freezing timecourse
subplot(3,6,4,'XTick',[1:900:3000],'XTickLabel',[-30:30:90],'FontName','Arial','FontSize',14);hold on;xlabel('sec')
ylabel('Freezing trial 1-5 [%]','FontName','Arial','FontSize',14);
fill([901 901 1800 1800],[0 100 100 0],'y','FaceAlpha',1,'EdgeAlpha',0)
stdX=std(CSfreezing*100)/sqrt(size(CSfreezing,1));%;
for i=1:length(CSfreezing)
    errBoxY = [(mean(CSfreezing(:,i))*100)-stdX(i),(mean(CSfreezing(:,i))*100)+stdX(i), (mean(CSfreezing(:,i))*100)+stdX(i),(mean(CSfreezing(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
stdX=std(CSfreezingKO*100)/sqrt(size(CSfreezingKO,1));%;
for i=1:length(CSfreezingKO)
    errBoxY = [(mean(CSfreezingKO(:,i))*100)-stdX(i),(mean(CSfreezingKO(:,i))*100)+stdX(i), (mean(CSfreezingKO(:,i))*100)+stdX(i),(mean(CSfreezingKO(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(CSfreezing)*100,'-','Color',ColorCtrl,'LineWidth',1)
plot(mean(CSfreezingKO)*100,'Color',ColorKO,'LineWidth',1)
title('CS+'); axis([0 3600 0 100])

subplot(3,6,5,'XTick',[1:900:3000],'XTickLabel',[-30:30:90],'FontName','Arial','FontSize',14);hold on;xlabel('sec')
fill([901 901 1800 1800],[0 100 100 0],'y','FaceAlpha',1,'EdgeAlpha',0)
stdX=std(USfreezing*100)/sqrt(size(CSfreezing,1));%;
for i=1:length(USfreezing)
    errBoxY = [(mean(USfreezing(:,i))*100)-stdX(i),(mean(USfreezing(:,i))*100)+stdX(i), (mean(USfreezing(:,i))*100)+stdX(i),(mean(USfreezing(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
stdX=std(USfreezingKO*100)/sqrt(size(CSfreezingKO,1));%;
for i=1:length(USfreezingKO)
    errBoxY = [(mean(USfreezingKO(:,i))*100)-stdX(i),(mean(USfreezingKO(:,i))*100)+stdX(i), (mean(USfreezingKO(:,i))*100)+stdX(i),(mean(USfreezingKO(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(USfreezing)*100,'-','Color',ColorCtrl,'LineWidth',1)
plot(mean(USfreezingKO)*100,'Color',ColorKO,'LineWidth',1)
title('CS-');axis([0 3600 0 100])

%% figure 1 Motion index
subplot(3,6,13,'XTickLabel',{'baseline','CS+','CS-','Shock','1s after','2s after','3s after','4s after','5s after'},'XTickLabelRotation',45,'XTick',[1.5:2:18],'FontName','Arial','FontSize',14);
average=([mean(MotionIndexBaselinectrl);mean(MotionIndexBaselineKO);mean(MotionIndexSoundctrl);mean(MotionIndexSoundKO);mean(MotionIndexSoundUPctrl);mean(MotionIndexSoundUPKO);mean(MotionIndexShockctrl);mean(MotionIndexShockKO);mean(MotionIndex1sAfterShockctrl);mean(MotionIndex1sAfterShockKO);mean(MotionIndex2sAfterShockctrl);mean(MotionIndex2sAfterShockKO);mean(MotionIndex3sAfterShockctrl);mean(MotionIndex3sAfterShockKO);mean(MotionIndex4sAfterShockctrl);mean(MotionIndex4sAfterShockKO);mean(MotionIndex5sAfterShockctrl);mean(MotionIndex5sAfterShockKO)]);
sdev=([std(MotionIndexBaselinectrl);std(MotionIndexBaselineKO);std(MotionIndexSoundctrl);std(MotionIndexSoundKO);std(MotionIndexSoundUPctrl);std(MotionIndexSoundUPKO);std(MotionIndexShockctrl);std(MotionIndexShockKO);std(MotionIndex1sAfterShockctrl);std(MotionIndex1sAfterShockKO);std(MotionIndex2sAfterShockctrl);std(MotionIndex2sAfterShockKO);std(MotionIndex3sAfterShockctrl);std(MotionIndex3sAfterShockKO);std(MotionIndex4sAfterShockctrl);std(MotionIndex4sAfterShockKO);std(MotionIndex5sAfterShockctrl);std(MotionIndex5sAfterShockKO)]);
for i=[0:2:16]
    for j=1:2
        hold on
        if j==1
            fill([i+j-0.3 i+j-0.3 i+j+0.3 i+j+0.3],[average(i+j)-sdev(i+j) average(i+j)+sdev(i+j) average(i+j)+sdev(i+j) average(i+j)-sdev(i+j)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
            plot([i+j-0.3 i+j+0.3],[average(i+j) average(i+j)],'-','LineWidth',2,'Color',ColorCtrl)
        else
            fill([i+j-0.3 i+j-0.3 i+j+0.3 i+j+0.3],[average(i+j)-sdev(i+j) average(i+j)+sdev(i+j) average(i+j)+sdev(i+j) average(i+j)-sdev(i+j)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
            plot([i+j-0.3 i+j+0.3],[average(i+j) average(i+j)],'-','LineWidth',2,'Color',ColorKO)
        end
        
    end
end
ylabel('Motion Index (A.U.)')

%% Figure 1: plot speed during shocks and sounds
for i=14:15
    subplot(3,6,i,'XTick',1:60:600,'XTickLabel',[-2:2:10]); hold on;ylabel('Motion Index (a.u.)')
    fill([61 61 90 90],[0 100 100 0],'r','FaceAlpha',1,'EdgeAlpha',0)
end
    subplot(3,6,16,'XTick',1:60:600,'XTickLabel',[-2:2:10]); hold on;ylabel('speed (cm/s)')
    fill([61 61 90 90],[0 100 100 0],'r','FaceAlpha',1,'EdgeAlpha',0)

subplot(3,6,14);hold on
plot(mean(TA_MotionIndexShockctrl1(:,841:1081)),'Color',ColorCtrl_BG)
plot(mean(TA_MotionIndexShockKO1(:,841:1081)),'Color',ColorKO)
axis tight
xlabel('time after shock onset [sec]')
title('trial averaged shock response shock 1');
subplot(3,6,15); hold on
for i=841:1081
    fill([i-840 i-840 i-840+1 i-840+1],[mean(TA_MotionIndexShockctrl5(:,i))-std(TA_MotionIndexShockctrl5(:,i)) mean(TA_MotionIndexShockctrl5(:,i))+std(TA_MotionIndexShockctrl5(:,i)) mean(TA_MotionIndexShockctrl5(:,i))+std(TA_MotionIndexShockctrl5(:,i)) mean(TA_MotionIndexShockctrl5(:,i))-std(TA_MotionIndexShockctrl5(:,i))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
    fill([i-840 i-840 i-840+1 i-840+1],[mean(TA_MotionIndexShockKO5(:,i))-std(TA_MotionIndexShockKO5(:,i)) mean(TA_MotionIndexShockKO5(:,i))+std(TA_MotionIndexShockKO5(:,i)) mean(TA_MotionIndexShockKO5(:,i))+std(TA_MotionIndexShockKO5(:,i)) mean(TA_MotionIndexShockKO5(:,i))-std(TA_MotionIndexShockKO5(:,i))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(TA_MotionIndexShockctrl5(:,841:1081)),'Color',ColorCtrl_BG,'LineWidth',2)
plot(mean(TA_MotionIndexShockKO5(:,841:1081)),'Color',ColorKO,'LineWidth',2)
xlabel('time after shock onset [sec]')
axis tight
title('shock 1-4')
subplot(3,6,16); hold on
for i=841:1081
    fill([i-840 i-840 i-840+1 i-840+1],[mean(TAshocksspeedctrl(:,i))-std(TAshocksspeedctrl(:,i)) mean(TAshocksspeedctrl(:,i))+std(TAshocksspeedctrl(:,i)) mean(TAshocksspeedctrl(:,i+1))+std(TAshocksspeedctrl(:,i+1)) mean(TAshocksspeedctrl(:,i+1))-std(TAshocksspeedctrl(:,i+1))],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
    fill([i-840 i-840 i-840+1 i-840+1],[mean(TAshocksspeedKO(:,i))-std(TAshocksspeedKO(:,i)) mean(TAshocksspeedKO(:,i))+std(TAshocksspeedKO(:,i)) mean(TAshocksspeedKO(:,i+1))+std(TAshocksspeedKO(:,i+1)) mean(TAshocksspeedKO(:,i+1))-std(TAshocksspeedKO(:,i+1))],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(TAshocksspeedctrl(:,841:1081)),'Color',ColorCtrl)
plot(mean(TAshocksspeedKO(:,841:1081)),'Color',ColorKO)
axis tight
title('shock1-15')
xlabel('time after shock onset [sec]')
saveas(gcf,strcat(directorynew,'\',filenamesave,'_supp.png'),'png')
print('-depsc','-painters',strcat(directorynew,'\',filenamesave,'_supp.eps'));

%statistics for TAshockspeed
ValCtrl=sum(TAshocksspeedctrl(:,901:1081),2)/30;
ValKO=sum(TAshocksspeedKO(:,901:1081),2)/30;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
text(1,90,testStatistics,'FontSize',6)
%text(1,95,string(p),'FontSize',6)
p_AUCshockspeed=p;
stdCtrl_AUCshockspeed=stdCtrl;
stdKO_AUCshockspeed=stdKO;
meanCtrl_AUCshockspeed=meanCtrl;
meanKO_AUCshockspeed=meanKO;
testStatistics_AUCshockspeed=testStatistics;

%% make figure 2: freezing during all stimuli
figure('Position',[100 100 1100 900]);
freezingbaselinectrl=freezingbaselineoriginalctrl;
freezingsoundlistctrl=mean(freezingsoundlistoriginalctrl(latestim:15,:));
freezingunpairedsoundlistctrl=mean(freezingunpairedsoundlistoriginalctrl(latestim:15,:));
freezingbaselineKO=freezingbaselineoriginalKO;
freezingsoundlistKO=mean(freezingsoundlistoriginalKO(latestim:15,:));
freezingunpairedsoundlistKO=mean(freezingunpairedsoundlistoriginalKO(latestim:15,:));

subplot(3,4,9,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,4,7],'FontName','Arial','FontSize',14);
title('Mean,SEM','FontName','Arial','FontSize',12)
hold on;
ylabel('Freezing trial 1-15 [%]','FontName','Arial','FontSize',14);%title('Freezing [%]','FontName','Arial','FontSize',14)

ValCtrl=freezingbaselinectrl;
ValKO=freezingbaselineKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([0.7,0.7,1.3,1.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([0.7 1.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([1.7,1.7,2.3,2.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([1.7 2.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(1,100,testStatistics,'FontSize',6)
%text(1,95,string(p),'FontSize',6)
p_Baseline=p;
stdCtrl_Baseline=stdCtrl;
stdKO_Baseline=stdKO;
meanCtrl_Baseline=meanCtrl;
meanKO_Baseline=meanKO;
testStatistics_Baseline=testStatistics;


ValCtrl=freezingsoundlistctrl;
ValKO=freezingsoundlistKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([3.7,3.7,4.3,4.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([3.7 4.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([4.7,4.7,5.3,5.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([4.7 5.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(4,100,testStatistics,'FontSize',6)
%text(4,95,string(p),'FontSize',6)
p_Sound=p;
stdCtrl_Sound=stdCtrl;
stdKO_Sound=stdKO;
meanCtrl_Sound=meanCtrl;
meanKO_Sound=meanKO;
testStatistics_Sound=testStatistics;


ValCtrl=freezingunpairedsoundlistctrl;
ValKO=freezingunpairedsoundlistKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([6.7,6.7,7.3,7.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([6.7 7.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([7.7,7.7,8.3,8.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([7.7 8.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(7,100,testStatistics,'FontSize',6)
p_UnpairedSound=p;
stdCtrl_UnpairedSound=stdCtrl;
stdKO_UnpairedSound=stdKO;
meanCtrl_UnpairedSound=meanCtrl;
meanKO_UnpairedSound=meanKO;
testStatistics_UnpairedSound=testStatistics;


subplot(3,4,1,'XTickLabel',{'CS+','CS-'},'XTickLabelRotation',45,'XTick',[4,7],'FontName','Arial','FontSize',14);
hold on;
ylabel('Freezing trial 1-15 [%]','FontName','Arial','FontSize',14);title('Mean,SEM,-BL','FontName','Arial','FontSize',12)
text(2,90,'ctrl','FontSize',12,'Color',ColorCtrl); % add text
text(2,80,'KO','FontSize',12,'Color',ColorKO); % add text
ValCtrl=freezingsoundlistctrl-freezingbaselinectrl;
ValKO=freezingsoundlistKO-freezingbaselineKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([3.7,3.7,4.3,4.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([3.7 4.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([4.7,4.7,5.3,5.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([4.7 5.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(4,100,testStatistics,'FontSize',6)
%text(4,95,string(p),'FontSize',6)
p_SoundBLSub=p;
stdCtrl_SoundBLSub=stdCtrl;
stdKO_SoundBLSub=stdKO;
meanCtrl_SoundBLSub=meanCtrl;
meanKO_SoundBLSub=meanKO;
testStatistics_SoundBLSub=testStatistics;

ValCtrl=freezingunpairedsoundlistctrl-freezingbaselinectrl;
ValKO=freezingunpairedsoundlistKO-freezingbaselineKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([6.7,6.7,7.3,7.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([6.7 7.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([7.7,7.7,8.3,8.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([7.7 8.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(7,100,testStatistics,'FontSize',6)



subplot(3,4,9); hold on
maxrand=[];
for i=0:step:uppervalue;
    j=freezingbaselinectrl;
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(xcoord/width+1,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
        
    end
end

for i=0:step:uppervalue;
    j=freezingbaselineKO;
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
       plot(((xcoord)/width)+2,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end

for p=[9,1];
    subplot(3,4,p); hold on
if groups>2;
for i=0:step:uppervalue;
    j=freezingsoundlistctrl;
    if p==1
        j=freezingsoundlistctrl-freezingbaselinectrl;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+4,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
    end
end
end

if groups>3;
for i=0:step:uppervalue;
    j=freezingsoundlistKO;
    if p==1
        j=freezingsoundlistKO-freezingbaselineKO;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+5,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
end

if groups>4;
for i=0:step:uppervalue;
    j=freezingunpairedsoundlistctrl;
    if p==1
        j=freezingunpairedsoundlistctrl-freezingbaselinectrl;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+7,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
    end
end
end

for i=0:step:uppervalue;
    j=freezingunpairedsoundlistKO;
    if p==1
        j=freezingunpairedsoundlistKO-freezingbaselineKO;
    end
    j(find(j<i))=[];
    j(find(j>=i+step))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot(((xcoord)/width)+8,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
if p==1
    axis([2 9 0 100])
else
    axis([0 9 0 100])
end
end

%line plot
subplot(3,4,10,'XTickLabel',{'baseline','CS+','CS-'},'XTickLabelRotation',45,'XTick',[1,2,3],'FontName','Arial','FontSize',14);
title('Mean,SEM','FontName','Arial','FontSize',12)
hold on 
freezingallctrl=[freezingbaselinectrl;freezingsoundlistctrl;freezingunpairedsoundlistctrl];
freezingallKO=[freezingbaselineKO;freezingsoundlistKO;freezingunpairedsoundlistKO];

if lines==1
    plot(freezingallctrl,'-','Color',ColorCtrl)
    plot(freezingallKO,'-','Color',ColorKO)
end
axis([0.5 3.5 0 100])

%discrimination ratio all
subplot(3,4,4,'XTickLabel',{'ctrl','KO'},'XTickLabelRotation',45,'XTick',[1,2],'FontName','Arial','FontSize',14);
title('Discrimination','FontName','Arial','FontSize',12)
hold on 
ylabel('Discrimination index','FontName','Arial','FontSize',14)
% title('CS discrimination','FontName','Arial','FontSize',14)
freezingratioctrl=[(freezingsoundlistctrl-freezingunpairedsoundlistctrl)./(freezingsoundlistctrl+freezingunpairedsoundlistctrl)];
freezingratioKO=[(freezingsoundlistKO-freezingunpairedsoundlistKO)./(freezingsoundlistKO+freezingunpairedsoundlistKO)];


ValCtrl=freezingratioctrl;
ValKO=freezingratioKO;
pShapiroWilk_Ctrl=swtestSarah(ValCtrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_test=swtestSarah(ValKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance]=vartest2(ValCtrl,ValKO);%F-test to test variance of normally distributed data
        if min([pShapiroWilk_Ctrl,pShapiroWilk_test])<=0.05;%if one of the two or both is non normally distributed
            %disp('Mann-Whitney U')
            testStatistics='MWU';
            [p,t,~,~]=mwwtestSarah(ValCtrl,ValKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
            meanCtrl=median(ValCtrl);
            stdCtrl=[prctile(ValCtrl,75)-median(ValCtrl),median(ValCtrl)-prctile(ValCtrl,25)];
            meanKO=median(ValKO);
            stdKO=[prctile(ValKO,75)-median(ValKO),median(ValKO)-prctile(ValKO,25)];
         elseif pEqualVariance>0.05 %if variance is equal
            %disp('ttest')
            testStatistics='ttest';
            [~,p,~,stats]=ttest2(ValCtrl,ValKO);%%if both groups are parametric and variance is euqal, use t-test
            t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
        else
            %disp('ttest for unequal Variance')
            testStatistics='ttestUnequal';
            [~,p,~,stats] = ttest2(ValCtrl,s,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
             t=stats.tstat;
            df=stats.df;
            meanCtrl=mean(ValCtrl);
            stdCtrl=[std(ValCtrl)/sqrt(samplesizectrl),std(ValCtrl)/sqrt(samplesizectrl)];
            meanKO=mean(ValKO);
            stdKO=[std(ValKO)/sqrt(samplesizeKO),std(ValKO)/sqrt(samplesizeKO)];
       end
fill([0.7,0.7,1.3,1.3],[meanCtrl-stdCtrl(2),meanCtrl+stdCtrl(1),meanCtrl+stdCtrl(1),meanCtrl-stdCtrl(2)],ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([0.7 1.3],[meanCtrl,meanCtrl],'Color',ColorCtrl,'LineWidth',2)
fill([1.7,1.7,2.3,2.3],[meanKO-stdKO(2),meanKO+stdKO(1),meanKO+stdKO(1),meanKO-stdKO(2)],ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
plot([1.7 2.3],[meanKO,meanKO],'Color',ColorKO,'LineWidth',2)
text(1,0.9,testStatistics,'FontSize',6)
%text(4,95,string(p),'FontSize',6)
p_Discrim=p;
stdCtrl_Discrim=stdCtrl;
stdKO_Discrim=stdKO;
meanCtrl_Discrim=meanCtrl;
meanKO_Discrim=meanKO;
testStatistics_Discrim=testStatistics;

averageXa=nanmean(freezingratioctrl);
averageXb=nanmean(freezingratioKO);
stdXa=nanstd(freezingratioctrl);
stdXb=nanstd(freezingratioKO);

for i=-100:0.1:100;
    j=freezingratioctrl;
    j=j(~isnan(j));
    j(find(j<i))=[];
    j(find(j>=i+0.1))=[];
    if length(j)>0;
        if length(j)==1;
            xcoord=0;
        end
       if length(j)==2;
           xcoord=[-2,2];
       end
       if length(j)==3;
           xcoord=[-3,0,3];
       end
       if length(j)>3;
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
        plot((xcoord/width)+1,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorCtrl)
        
    end
end

for i=-100:0.1:100
    j=freezingratioKO;
    j=j(~isnan(j));
    j(find(j<i))=[];
    j(find(j>=i+0.1))=[];
    if length(j)>0
        if length(j)==1
            xcoord=0;
        end
       if length(j)==2
           xcoord=[-2,2];
       end
       if length(j)==3
           xcoord=[-3,0,3];
       end
       if length(j)>3
           xcoord=randi([-length(j),length(j)],[1 length(j)]);
       end
       plot((xcoord/width)+2,j,'.','MarkerSize',20,'Color','none','MarkerEdgeColor',ColorKO)
    end
end
hold on
axis([0.5 2.5 -1 1])

%% figure 2: freezing timecourse during trials 1-15
subplot(3,4,2,'XTick',[1:900:3000],'XTickLabel',[-30:30:90],'FontName','Arial','FontSize',14);hold on;xlabel('sec')
title('Mean,SEM CS+','FontName','Arial','FontSize',12)
fill([901 901 1800 1800],[0 100 100 0],'y','FaceAlpha',1,'EdgeAlpha',0)
stdX=std(CSfreezinglate*100)/sqrt(size(CSfreezing,1));%;
for i=1:length(CSfreezinglate)
    errBoxY = [(mean(CSfreezinglate(:,i))*100)-stdX(i),(mean(CSfreezinglate(:,i))*100)+stdX(i), (mean(CSfreezinglate(:,i))*100)+stdX(i),(mean(CSfreezinglate(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
stdX=std(CSfreezingKOlate*100)/sqrt(size(CSfreezingKO,1));%;
for i=1:length(CSfreezingKOlate)
    errBoxY = [(mean(CSfreezingKOlate(:,i))*100)-stdX(i),(mean(CSfreezingKOlate(:,i))*100)+stdX(i), (mean(CSfreezingKOlate(:,i))*100)+stdX(i),(mean(CSfreezingKOlate(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(CSfreezinglate)*100,'-','Color',ColorCtrl,'LineWidth',1)
plot(mean(CSfreezingKOlate)*100,'Color',ColorKO,'LineWidth',1)
axis([0 3600 0 100])

subplot(3,4,3,'XTick',[1:900:3000],'XTickLabel',[-30:30:90],'FontName','Arial','FontSize',14);hold on;xlabel('sec')
title('Mean,SEM CS-','FontName','Arial','FontSize',12)
fill([901 901 1800 1800],[0 100 100 0],'y','FaceAlpha',1,'EdgeAlpha',0)
stdX=std(USfreezinglate*100)/sqrt(size(CSfreezing,1));%;
for i=1:length(USfreezinglate)
    errBoxY = [(mean(USfreezinglate(:,i))*100)-stdX(i),(mean(USfreezinglate(:,i))*100)+stdX(i), (mean(USfreezinglate(:,i))*100)+stdX(i),(mean(USfreezinglate(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
stdX=std(USfreezingKOlate*100)/sqrt(size(CSfreezingKO,1));%;
for i=1:length(USfreezingKOlate)
    errBoxY = [(mean(USfreezingKOlate(:,i))*100)-stdX(i),(mean(USfreezingKOlate(:,i))*100)+stdX(i), (mean(USfreezingKOlate(:,i))*100)+stdX(i),(mean(USfreezingKOlate(:,i))*100)-stdX(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(mean(USfreezinglate)*100,'-','Color',ColorCtrl,'LineWidth',1)
plot(mean(USfreezingKOlate)*100,'Color',ColorKO,'LineWidth',1)
axis([0 3600 0 100])

subplot(3,4,5:6,'XTickLabel',{'5','10','15'},'XTick',[5,10,15],'FontName','Arial','FontSize',14);
hold on
seriesCS=mean(freezingsoundlistoriginalctrl');
seriesCSstd=std(freezingsoundlistoriginalctrl')/sqrt(samplesizectrl);
for i=1:length(seriesCS)
    errBoxY = [seriesCS(i)-seriesCSstd(i),seriesCS(i)+seriesCSstd(i), seriesCS(i)+seriesCSstd(i),seriesCS(i)-seriesCSstd(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(seriesCS,'Color',ColorCtrl,'LineWidth',1)
seriesCS=mean(freezingsoundlistoriginalKO');
seriesCSstd=std(freezingsoundlistoriginalKO')/sqrt(samplesizeKO);
for i=1:length(seriesCS)
    errBoxY = [seriesCS(i)-seriesCSstd(i),seriesCS(i)+seriesCSstd(i), seriesCS(i)+seriesCSstd(i),seriesCS(i)-seriesCSstd(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(seriesCS,'Color',ColorKO,'LineWidth',1)
title('CS+');ylabel('Freezing [%]');xlabel('CS+ No.')
axis([0 16 0 100])

subplot(3,4,7:8,'XTickLabel',{'5','10','15'},'XTick',[5,10,15],'FontName','Arial','FontSize',14);
hold on 
seriesUS=mean(freezingunpairedsoundlistoriginalctrl');
seriesUSstd=std(freezingunpairedsoundlistoriginalctrl')/sqrt(samplesizectrl);
for i=1:length(seriesUS)
    errBoxY = [seriesUS(i)-seriesUSstd(i),seriesUS(i)+seriesUSstd(i), seriesUS(i)+seriesUSstd(i),seriesUS(i)-seriesUSstd(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorCtrl_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(seriesUS,'Color',ColorCtrl,'LineWidth',1)
seriesUS=mean(freezingunpairedsoundlistoriginalKO');
seriesUSstd=std(freezingunpairedsoundlistoriginalKO')/sqrt(samplesizeKO);
for i=1:length(seriesUS)
    errBoxY = [seriesUS(i)-seriesUSstd(i),seriesUS(i)+seriesUSstd(i), seriesUS(i)+seriesUSstd(i),seriesUS(i)-seriesUSstd(i)];
    errBoxX=[i-0.5,i-0.5,i+0.5,i+0.5];
    fill(errBoxX',errBoxY',ColorKO_BG,'FaceAlpha',1,'EdgeAlpha',0)
end
plot(seriesUS,'Color',ColorKO,'LineWidth',1)
title('CS-','FontName','Arial','FontSize',14)
xlabel('CS- No.','FontName','Arial','FontSize',14)
axis([0 16 0 100])

%% statistics
if length(freezingbaselinectrl)>2 & length(freezingbaselineKO)>2
pShapiroWilk_BL_Ctrl=swtestSarah(freezingbaselinectrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_BL_KO=swtestSarah(freezingbaselineKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance_BL]=vartest2(freezingbaselinectrl,freezingbaselineKO);%F-test to test variance of normally distributed data
if min([pShapiroWilk_BL_Ctrl,pShapiroWilk_BL_KO])<=0.05;%if one of the two or both is non normally distributed
    disp('Mann-Whitney U for Baseline')
    [pBaseline,tBaseline,meanrank1,meanrank2]=mwwtestSarah(freezingbaselinectrl,freezingbaselineKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
    dfBaseline=[];
     if pEqualVariance_BL<0.05 %if variance is unequal
        disp('Variance is unequal and data are non-parametric! Does it make sense to transform the data???')
    end
elseif pEqualVariance_BL>0.05 %if variance is equal
    disp('ttest for Baseline')
    [~,pBaseline,~,stats]=ttest2(freezingbaselinectrl,freezingbaselineKO);%%if both groups are parametric and variance is euqal, use t-test
    tBaseline=stats.tstat;
    dfBaseline=stats.df;
else
    disp('ttest for unequal Variance for Baseline')
    [~,pBaseline,~,stats] = ttest2(freezingbaselinectrl,freezingbaselineKO,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
    tBaseline=stats.tstat;
    dfBaseline=stats.df;
end

pShapiroWilk_Sound_Ctrl=swtestSarah(freezingsoundlistctrl-freezingbaselinectrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_Sound_KO=swtestSarah(freezingsoundlistKO-freezingbaselineKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance_Sound]=vartest2(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO);%F-test to test variance of normally distributed data
if min([pShapiroWilk_Sound_Ctrl,pShapiroWilk_Sound_KO])<=0.05;%if one of the two or both is non normally distributed
    disp('Mann-Whitney U for CS+')
    [pSound,tSound,meanrank1,meanrank2]=mwwtestSarah(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
    if pEqualVariance_Sound<0.05 %if variance is unequal
        disp('Variance is unequal and data are non-parametric! Does it make sense to transform the data???')
    end
elseif pEqualVariance_Sound>0.05 %if variance is equal
    [~,pSound,~,stats]=ttest2(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO);%%if both groups are parametric and variance is euqal, use t-test
    tSound=stats.tstat;
    dfSound=stats.df;
        disp('ttest for CS+')
else
    disp('ttest for unequal Variance for CS+')
    [~,pSound,~,stats] = ttest2(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance;
    tSound=stats.tstat;
    dfSound=stats.df;
end


pShapiroWilk_Discr_Ctrl=swtestSarah(freezingratioctrl,0.05);%Shapiro-Wilk test tests for normal distribution
pShapiroWilk_Discr_KO=swtestSarah(freezingratioKO,0.05);%Shapiro-Wilk test tests for normal distribution
[~,pEqualVariance_Discr]=vartest2(freezingratioctrl,freezingratioKO);%F-test to test variance of normally distributed data
if min([pShapiroWilk_Discr_Ctrl,pShapiroWilk_Discr_KO])<=0.05;%if one of the two or both is non normally distributed
    disp('Mann-Whitney U for Discrimination')
    [pDiscrimination,tDiscrimination,meanrank1,meanrank2]=mwwtestSarah(freezingratioctrl,freezingratioKO);%Mann-Whitney U if at least one group is non-parametric and variance is equal
    dfDiscrimination=[];
     if pEqualVariance_Discr<0.05 %if variance is unequal
        disp('Variance is unequal and data are non-parametric! Does it make sense to transform the data???')
    end
elseif pEqualVariance_Discr>0.05 %if variance is equal
    disp('ttest for Discrimination')
    [~,pDiscrimination,~,stats]=ttest2(freezingratioctrl,freezingratioKO);%%if both groups are parametric and variance is euqal, use t-test
    tDiscrimination=stats.tstat;
    dfDiscrimination=stats.df;
else
    disp('ttest for unequal Variance for Discrimination')
    [~,pDiscrimination,~,stats] = ttest2(freezingratioctrl,freezingratioKO,'Vartype','unequal');%if both groups are parametric and variance is uneuqal, use t-test for unequal variance
    tDiscrimination=stats.tstat;
    dfDiscrimination=stats.df;
end


%use holm-bonferroni test to correct for familywise error rate
s=size([p_Baseline,p_Sound,p_Discrim]);
if isvector([p_Baseline,p_Sound,p_Discrim]),
    if size([p_Baseline,p_Sound,p_Discrim],1)>1,
       pvalues=pvalues'; 
    end
    [sorted_p sort_ids]=sort([p_Baseline,p_Sound,p_Discrim]);    
end
[dummy, unsort_ids]=sort(sort_ids); %indices to return sorted_p to pvalues order

m=length(sorted_p); %number of tests
mult_fac=m:-1:1;
cor_p_sorted=sorted_p.*mult_fac;
for i=2:m
    cor_p_sorted(i)=max(cor_p_sorted(i-1:i));%Bonferroni-Holm adjusted p-value
end 
corrected_p=cor_p_sorted(unsort_ids);
corrected_p=reshape(corrected_p,s);
for i=1:length(corrected_p);
    if corrected_p(i)>1
        corrected_p(i)=1;
    end
end
% pBaseline=corrected_p(1)
% tBaseline
% dfBaseline
% pSound=corrected_p(2)
% tSound
% % dfSound
% pDiscrimination=corrected_p(3)
% tDiscrimination
% dfDiscrimination
% 
% %use holm-bonferroni test to correct for familywise error rate
% s=size([p_UnpairedSound,p_Sound]);
% if isvector([p_UnpairedSound,p_Sound]),
%     if size([p_UnpairedSound,p_Sound],1)>1,
%        pvalues=pvalues'; 
%     end
%     [sorted_p sort_ids]=sort([p_Baseline,p_Sound]);    
% end
% [dummy, unsort_ids]=sort(sort_ids); %indices to return sorted_p to pvalues order
% 
% m=length(sorted_p); %number of tests
% mult_fac=m:-1:1;
% cor_p_sorted=sorted_p.*mult_fac;
% for i=2:m
%     cor_p_sorted(i)=max(cor_p_sorted(i-1:i));%Bonferroni-Holm adjusted p-value
% end 
% corrected_p=cor_p_sorted(unsort_ids);
% corrected_p=reshape(corrected_p,s);
% for i=1:length(corrected_p);
%     if corrected_p(i)>1
%         corrected_p(i)=1;
%     end
% end

subplot(3,4,1)
if p_SoundBLSub<0.001
    text(4,90,'***','FontSize',12,'Color','k'); % add text)
elseif p_SoundBLSub<0.01
    text(4,90,'**','FontSize',12,'Color','k'); % add text)
elseif p_SoundBLSub<0.05
    text(4,90,'*','FontSize',12,'Color','k'); % add text)
else
    text(4,90,'n.s.','FontSize',12,'Color','k'); % add text)
end

subplot(3,4,9)
if p_Baseline<0.001
    text(1,30,'***','FontSize',12,'Color','k'); % add text)
elseif p_Baseline<0.01
    text(1,30,'**','FontSize',12,'Color','k'); % add text)
elseif p_Baseline<0.05
    text(1,30,'*','FontSize',12,'Color','k'); % add text)
else
    text(1,30,'n.s.','FontSize',12,'Color','k'); % add text)
end

if p_Sound<0.001
    text(4,90,'***','FontSize',12,'Color','k'); % add text)
elseif p_Sound<0.01
    text(4,90,'**','FontSize',12,'Color','k'); % add text)
elseif p_Sound<0.05
    text(4,90,'*','FontSize',12,'Color','k'); % add text)
else
    text(4,90,'n.s.','FontSize',12,'Color',ColorCtrl); % add text)
end

%statistics
[~,p_CS_all]=ttest2(freezingsoundlistctrl,freezingsoundlistKO)
[~,p_CS_all_subBL]=ttest2(freezingsoundlistctrl-freezingbaselinectrl,freezingsoundlistKO-freezingbaselineKO)
[~,p_discrimination_all]=ttest2(freezingratioctrl,freezingratioKO)

end


subplot(3,4,4)
if p_Discrim<0.001
    text(1,0.7,'***','FontSize',12,'Color','k'); % add text)
elseif p_Discrim<0.01
    text(1,0.7,'**','FontSize',12,'Color','k'); % add text)
elseif p_Discrim<0.05
    text(1,0.7,'*','FontSize',12,'Color','k'); % add text)
else
    text(1,0.7,'n.s.','FontSize',12,'Color','k'); % add text)
end

saveas(gcf,strcat(directorynew,'\',filenamesave,'_mainFigure.png'),'png')
print('-depsc','-painters',strcat(directorynew,'\',filenamesave,'_mainFigure.eps'));

%% descriptive statistics
% SEM calculation

% sample sizes (excluding NaNs)
n_ctrl_BL = sum(~isnan(freezingbaselinectrl));
n_KO_BL   = sum(~isnan(freezingbaselineKO));

n_ctrl_CS = sum(~isnan(freezingsoundlistctrl));
n_KO_CS   = sum(~isnan(freezingsoundlistKO));

% SEM
sem_ctrl_BL = std(freezingbaselinectrl,'omitnan') / sqrt(n_ctrl_BL);
sem_KO_BL   = std(freezingbaselineKO,'omitnan')   / sqrt(n_KO_BL);

sem_ctrl_CS = std(freezingsoundlistctrl,'omitnan') / sqrt(n_ctrl_CS);
sem_KO_CS   = std(freezingsoundlistKO,'omitnan')   / sqrt(n_KO_CS);

% print nicely
fprintf('\n=== SEM ===\n');
fprintf('Baseline Ctrl SEM = %.3f | KO SEM = %.3f\n', sem_ctrl_BL, sem_KO_BL);
fprintf('CS+      Ctrl SEM = %.3f | KO SEM = %.3f\n', sem_ctrl_CS, sem_KO_CS);
fprintf('KO:   Mean = %.3f, Median = %.3f, IQR = %.3f, SD = %.3f\n', ...
    mean(freezingsoundlistKO,'omitnan'), ...
    median(freezingsoundlistKO,'omitnan'), ...
    iqr(freezingsoundlistKO), ...
    std(freezingsoundlistKO,'omitnan'));

fprintf('\n=== Baseline freezing (median [Q1, Q3]) ===\n');
fprintf('Ctrl: %.3f [%.3f, %.3f]\n', ...
    median(freezingbaselinectrl,'omitnan'), ...
    prctile(freezingbaselinectrl,25), ...
    prctile(freezingbaselinectrl,75));

fprintf('KO:   %.3f [%.3f, %.3f]\n', ...
    median(freezingbaselineKO,'omitnan'), ...
    prctile(freezingbaselineKO,25), ...
    prctile(freezingbaselineKO,75));

fprintf('\n=== CS+ freezing (all sounds; median [Q1, Q3]) ===\n');
fprintf('Ctrl: %.3f [%.3f, %.3f]\n', ...
    median(freezingsoundlistctrl,'omitnan'), ...
    prctile(freezingsoundlistctrl,25), ...
    prctile(freezingsoundlistctrl,75));

fprintf('KO:   %.3f [%.3f, %.3f]\n', ...
    median(freezingsoundlistKO,'omitnan'), ...
    prctile(freezingsoundlistKO,25), ...
    prctile(freezingsoundlistKO,75));

%% save freezing data and statistics
save(strcat(directorynew,'\',filenamesave,'_statistics'),'freezingsoundlistctrl','freezingunpairedsoundlistctrl','freezingsoundlistKO','freezingunpairedsoundlistKO','p_Baseline','meanCtrl_Baseline','meanKO_Baseline','stdCtrl_Baseline','stdKO_Baseline','testStatistics_Baseline','p_Sound','meanCtrl_Sound','meanKO_Sound','stdCtrl_Sound','stdKO_Sound','testStatistics_Sound','p_Discrim','meanCtrl_Discrim','meanKO_Discrim','stdCtrl_Discrim','stdKO_Discrim','testStatistics_Discrim','p_SoundBLSub','meanCtrl_SoundBLSub','meanKO_SoundBLSub','stdCtrl_SoundBLSub','stdKO_SoundBLSub','testStatistics_SoundBLSub','p_UnpairedSound','meanCtrl_UnpairedSound','meanKO_UnpairedSound','stdCtrl_UnpairedSound','stdKO_UnpairedSound','testStatistics_UnpairedSound','corrected_p','p_AUCshockspeed','meanCtrl_AUCshockspeed','meanKO_AUCshockspeed','stdCtrl_AUCshockspeed','stdKO_AUCshockspeed','testStatistics_AUCshockspeed');
disp('corrected p values for baseline, CS+, discrimination')
corrected_p