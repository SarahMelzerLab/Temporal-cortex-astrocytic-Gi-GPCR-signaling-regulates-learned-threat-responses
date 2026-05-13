clearvars
close all

% prompt user to select folder with data
[directory]=uigetdir;%select video to be analyzed
filename = 'Followup'
% define parameters
soundduration = 30; % in seconds
samplerate = 30; % in Hz
startbuffer = 30; % in seconds
endbuffer = 30; % in seconds
videolength = (samplerate*60*60);

%% get files

cd(fullfile(directory, 'CNO'))
filelist = dir('*.mat');
DeltaFF_sensor = zeros(length(filelist),videolength);
TAsound1start_sensor = zeros(15,2700);
TAsound2start_sensor = [];
TAfreezingstart_sensor = [];
meanTAfreezingend_one = [];
TAfreezingend_sensor = [];
std_TAsound1start_sensor = zeros(15,2700);
std_TAsound2start_sensor = zeros(15,2700);

for i = 1:length(filelist)
    load(filelist(i).name)
    DeltaFF_sensor(i,:) = DeltaFF(1:length(videolength));
    
    TAsound1start_sensor = TAsound1start
    if isempty(TAsound1start_sensor)
        TAsound1start_sensor = TAsound1start;
    else
        TAsound1start_sensor = TAsound1start_sensor + TAsound1start;
    end
   
      TAsound2start_sensor = TAsound2start
    if isempty(TAsound2start_sensor)
        TAsound2start_sensor = TAsound2start;
    else
        TAsound2start_sensor = TAsound2start_sensor + TAsound2start;
    end

%     meanTAfreezingstart_one = mean(TAfreezingstart, 1);
%     TAfreezingstart_sensor (i,:) = meanTAfreezingstart_one;
%     std_TAfreezingstart_sensor(i,:) = std(TAfreezingstart, 0, 1);
%     std_TAfreezingstart_sensor = mean(std_TAfreezingstart_sensor, 1);
%     meanTAfreezingend_one = mean(TAfreezingend, 1);
%     TAfreezingend_sensor (i,:) = meanTAfreezingend_one;
%     std_TAfreezingend_sensor(i,:) = std(TAfreezingend,0,1);
%     std_TAfreezingend_sensor = mean(std_TAfreezingend_sensor, 1);
    std_TAsound1start_sensor = std_TAsound1start_sensor + (TAsound1start - mean(TAsound1start,1)).^2;
    std_TAsound2start_sensor = std_TAsound2start_sensor + (TAsound2start - mean(TAsound2start,1)).^2;
    
end 
meanTAsound1start_sensor = TAsound1start_sensor / length(filelist); %already computes average here
meanTAsound2start_sensor = TAsound2start_sensor / length(filelist);

std_TAsound1start_sensor = sqrt(std_TAsound1start_sensor ./ (length(filelist) - 1));
std_TAsound2start_sensor = sqrt(std_TAsound2start_sensor ./ (length(filelist) - 1));

cd(fullfile(directory, 'saline'))
filelist = dir('*.mat');
DeltaFF_ctrl = zeros(length(filelist), videolength);
TAsound1start_ctrl = [];
TAsound2start_ctrl = [];
TAfreezingstart_ctrl = [];
meanTAfreezingend_two = [];
TAfreezingend_ctrl = [];
std_TAsound1start_ctrl = zeros(15,2700);
std_TAsound2start_ctrl = zeros(15,2700);

for i = 1:length(filelist)
    load(filelist(i).name)
    DeltaFF_ctrl(i,:) = DeltaFF(1:length(videolength));
       
    TAsound1start_ctrl = TAsound1start
  
    if isempty(TAsound1start_ctrl)
        TAsound1start_ctrl = TAsound1start;
    else
        TAsound1start_ctrl = TAsound1start_ctrl + TAsound1start;
    end
   
      TAsound2start_ctrl = TAsound2start
  
    if isempty(TAsound2start_ctrl)
        TAsound2start_ctrl = TAsound2start;
    else
        TAsound2start_ctrl = TAsound2start_ctrl + TAsound2start;
    end
    
%     meanTAfreezingstart_two = mean(TAfreezingstart, 1);
%     TAfreezingstart_ctrl (i,:) = meanTAfreezingstart_two;
%     std_TAfreezingstart_ctrl(i,:) = std(TAfreezingstart, 0, 1);
%     std_TAfreezingstart_ctrl = mean(std_TAfreezingstart_ctrl, 1);
%      std_TAfreezingend_ctrl(i,:) = std(TAfreezingend,0,1);
%     std_TAfreezingend_ctrl = mean(std_TAfreezingend_ctrl, 1);
%     meanTAfreezingend_two = mean(TAfreezingend, 1);
%     TAfreezingend_ctrl (i,:) = meanTAfreezingend_two;
    std_TAsound1start_ctrl = std_TAsound1start_ctrl + (TAsound1start - mean(TAsound1start,1)).^2;
    std_TAsound2start_ctrl = std_TAsound2start_ctrl + (TAsound2start - mean(TAsound2start,1)).^2;
end 

meanTAsound1start_ctrl = TAsound1start_ctrl / length(filelist); %already computes average here
meanTAsound2start_ctrl = TAsound2start_ctrl / length(filelist);
std_TAsound1start_ctrl = sqrt(std_TAsound1start_ctrl ./ (length(filelist) - 1));
std_TAsound2start_ctrl = sqrt(std_TAsound2start_ctrl ./ (length(filelist) - 1));

%% calculate average
% Compute means and medians for Sensor group
meanDeltaFF_sensor = mean(DeltaFF_sensor, 1);
medianDeltaFF_sensor = median(DeltaFF_sensor, 1);

% meanTAfreezingstart_sensor = mean(TAfreezingstart_sensor,1);
% medianTAfreezingstart_sensor = median(TAfreezingend_sensor,1);
% meanTAfreezingend_sensor = mean(TAfreezingend_sensor,1);
% medianTAfreezingend_sensor = median(TAfreezingend_sensor,1);

% Compute means and medians for Control group
meanDeltaFF_ctrl = mean(DeltaFF_ctrl, 1);
medianDeltaFF_ctrl = median(DeltaFF_ctrl, 1);

% meanTAfreezingstart_ctrl = mean(TAfreezingstart_ctrl,1);
% medianTAfreezingstart_ctrl = median(TAfreezingend_ctrl,1);
% meanTAfreezingend_ctrl = mean(TAfreezingend_ctrl,1);
% medianTAfreezingend_ctrl = median(TAfreezingend_ctrl,1);
%% plot 
close all
figure('Position',[50,80,1300,1100])

% DFF after freezing start, sensor

% x = 1:length(meanTAfreezingstart_sensor);
% subplot(3,4,1,'XTick',1:90:360,'XTickLabel',-6:3:6); hold on;
% plot(x, meanTAfreezingstart_sensor, 'b', 'LineWidth', 2);
% fill([x fliplr(x)], [meanTAfreezingstart_sensor+1*std_TAfreezingstart_sensor, fliplr(meanTAfreezingstart_sensor-1*std_TAfreezingstart_sensor)], [0.8 0.8 0.8], 'LineStyle', 'none');
% plot(x, meanTAfreezingstart_sensor, 'b', 'LineWidth', 2);
% xline(181, '--', 'Color', [1, 0.4, 0.6]);
% axis('tight');
% ylim([-15 10]);
% xlabel('time after freezing start [sec]'); ylabel('DF/F [%]');
% title('freezing start, sensor');
% 
% % DFF after freezing end, sensor
% x = 1:length(meanTAfreezingend_sensor);
% subplot(3,4,2,'XTick',1:90:360,'XTickLabel',-6:3:6); hold on;
% plot(x, meanTAfreezingend_sensor, 'b', 'LineWidth', 2);
% fill([x fliplr(x)], [meanTAfreezingend_sensor+1*std_TAfreezingend_sensor, fliplr(meanTAfreezingend_sensor-1*std_TAfreezingend_sensor)], [0.8 0.8 0.8], 'LineStyle', 'none');
% plot(x, meanTAfreezingend_sensor, 'b', 'LineWidth', 2);
% xline(181, '--', 'Color', [1, 0.4, 0.6]);
% axis('tight');
% ylim([-15 10]);
% xlabel('time after freezing end [sec]'); ylabel('DF/F [%]');
% title('freezing end, sensor');
% 
% % DFF after freezing start, ctrl
% x = 1:length(meanTAfreezingstart_ctrl);
% subplot(3,4,3,'XTick',1:90:360,'XTickLabel',-6:3:6); hold on;
% plot(x, meanTAfreezingstart_ctrl, 'b', 'LineWidth', 2);
% fill([x fliplr(x)], [meanTAfreezingstart_ctrl+1*std_TAfreezingstart_ctrl, fliplr(meanTAfreezingstart_ctrl-1*std_TAfreezingstart_ctrl)], [0.8 0.8 0.8], 'LineStyle', 'none');
% plot(x, meanTAfreezingstart_ctrl, 'b', 'LineWidth', 2);
% xline(181, '--', 'Color', [1, 0.4, 0.6]);
% axis('tight');
% ylim([-15 10]);
% xlabel('time after freezing start [sec]'); ylabel('DF/F [%]');
% title('freezing start, ctrl');
% 
% % DFF after freezing end, ctrl
% x = 1:length(meanTAfreezingend_ctrl);
% subplot(3,4,4,'XTick',1:90:360,'XTickLabel',-6:3:6); hold on;
% plot(x, meanTAfreezingend_ctrl, 'b', 'LineWidth', 2);
% fill([x fliplr(x)], [meanTAfreezingend_ctrl+1*std_TAfreezingend_ctrl, fliplr(meanTAfreezingend_ctrl-1*std_TAfreezingend_ctrl)], [0.8 0.8 0.8], 'LineStyle', 'none');
% plot(x, meanTAfreezingend_ctrl, 'b', 'LineWidth', 2);
% xline(181, '--', 'Color', [1, 0.4, 0.6]);
% axis('tight');
% ylim([-15 10]);
% xlabel('time after freezing end [sec]'); ylabel('DF/F [%]');
% title('freezing end, ctrl');

% Reaction to sound 1-5, CS+, sensor
subplot(3,4,5,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound1start_sensor_1_15 = mean(meanTAsound1start_sensor(1:15,:)); % compute mean of first 5 rows
std_TAsound1start_sensor_1_15 = std(meanTAsound1start_sensor(1:15,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound1start_sensor_1_15); % create x-coordinates
upper_bound = meanTAsound1start_sensor_1_15 + std_TAsound1start_sensor_1_15; % upper bound of shaded area
lower_bound = meanTAsound1start_sensor_1_15 - std_TAsound1start_sensor_1_15; % lower bound of shaded area
 fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.9294, 0.6902, 0.7882],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound1start_sensor_1_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after paired sound start [sec]'); ylabel('DF/F [%]');
title('trials 1-15, CS+, CNO')
    
    % Reaction to sound 1-5, CS-, sensor
subplot(3,4,9,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound2start_sensor_1_15 = mean(meanTAsound2start_sensor(1:15,:)); % compute mean of first 5 rows
std_TAsound2start_sensor_1_15 = std(meanTAsound2start_sensor(1:15,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound2start_sensor_1_15); % create x-coordinates
upper_bound = meanTAsound2start_sensor_1_15 + std_TAsound2start_sensor_1_15; % upper bound of shaded area
lower_bound = meanTAsound2start_sensor_1_15 - std_TAsound2start_sensor_1_15; % lower bound of shaded area
fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.7529, 0.9294, 0.8078],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound2start_sensor_1_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after unpaired sound start [sec]'); ylabel('DF/F [%]');
title('trials 1-15, CS-, CNO')

    %Reaction sound 11-15, CS-, sensor
        
subplot(3,4,10,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound2start_sensor_11_15 = mean(meanTAsound2start_sensor(11:15,:)); % compute mean of last 5 rows
std_TAsound2start_sensor_11_15 = std(meanTAsound2start_sensor(11:15,:),0,1); % compute SD across columns of last 5 rows
x = 1:length(meanTAsound2start_sensor_11_15); % create x-coordinates
upper_bound = meanTAsound2start_sensor_11_15 + std_TAsound2start_sensor_11_15; % upper bound of shaded area
lower_bound = meanTAsound2start_sensor_11_15 - std_TAsound2start_sensor_11_15; % lower bound of shaded area
fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.7529, 0.9294, 0.8078],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound2start_sensor_11_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after unpaired sound start [sec]'); ylabel('DF/F [%]');
title('trials 11-15, CS-, sensor')

    %reaction sound 11-15, CS+, sensor
   
subplot(3,4,6,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound1start_sensor_11_15 = mean(meanTAsound1start_sensor(11:15,:)); % compute mean of first 5 rows
std_TAsound1start_sensor_11_15 = std(meanTAsound1start_sensor(11:15,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound1start_sensor_11_15); % create x-coordinates
upper_bound = meanTAsound1start_sensor_11_15 + std_TAsound1start_sensor_11_15; % upper bound of shaded area
lower_bound = meanTAsound1start_sensor_11_15 - std_TAsound1start_sensor_11_15; % lower bound of shaded area
 fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.9294, 0.6902, 0.7882],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound1start_sensor_11_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after paired sound start [sec]'); ylabel('DF/F [%]');
title('trials 11-15, CS+, sensor')
    
     %this is the reaction to sound 1-5, CS+, ctrl
   subplot(3,4,7,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound1start_ctrl_1_15 = mean(meanTAsound1start_ctrl(1:15,:)); % compute mean of first 5 rows
std_TAsound1start_ctrl_1_15 = std(meanTAsound1start_ctrl(1:15,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound1start_ctrl_1_15); % create x-coordinates
upper_bound = meanTAsound1start_ctrl_1_15 + std_TAsound1start_ctrl_1_15; % upper bound of shaded area
lower_bound = meanTAsound1start_ctrl_1_15 - std_TAsound1start_ctrl_1_15; % lower bound of shaded area
 fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.9294, 0.6902, 0.7882],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound1start_ctrl_1_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after paired sound start [sec]'); ylabel('DF/F [%]');
title('trials 1-15, CS+, ctrl')

    %this is the reaction to sound 1-5, CS-, ctrl
 subplot(3,4,11,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound2start_ctrl_1_15 = mean(meanTAsound2start_ctrl(1:5,:)); % compute mean of first 5 rows
std_TAsound2start_ctrl_1_15 = std(meanTAsound2start_ctrl(1:5,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound2start_ctrl_1_15); % create x-coordinates
upper_bound = meanTAsound2start_ctrl_1_15 + std_TAsound2start_ctrl_1_15; % upper bound of shaded area
lower_bound = meanTAsound2start_ctrl_1_15 - std_TAsound2start_ctrl_1_15; % lower bound of shaded area
fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.7529, 0.9294, 0.8078],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound2start_ctrl_1_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after unpaired sound start [sec]'); ylabel('DF/F [%]');
title('trials 1-15, CS-, ctrl')

%this is trial 11-15, CS-, ctrl
    subplot(3,4,12,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound2start_ctrl_11_15 = mean(meanTAsound2start_ctrl(11:15,:)); % compute mean of last 5 rows
std_TAsound2start_ctrl_11_15 = std(meanTAsound2start_ctrl(11:15,:),0,1); % compute SD across columns of last 5 rows
x = 1:length(meanTAsound2start_ctrl_11_15); % create x-coordinates
upper_bound = meanTAsound2start_ctrl_11_15 + std_TAsound2start_ctrl_11_15; % upper bound of shaded area
lower_bound = meanTAsound2start_ctrl_11_15 - std_TAsound2start_ctrl_11_15; % lower bound of shaded area
fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.7529, 0.9294, 0.8078],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound2start_ctrl_11_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after unpaired sound start [sec]'); ylabel('DF/F [%]');
title('trials 11-15, CS-, ctrl')


%CS+ trial 11-15, ctrl
    subplot(3,4,8,'XTick',1:300:2700,'XTickLabel',-30:10:60); hold on
meanTAsound1start_ctrl_11_15 = mean(meanTAsound1start_ctrl(11:15,:)); % compute mean of first 5 rows
std_TAsound1start_ctrl_11_15 = std(meanTAsound1start_ctrl(11:15,:),0,1); % compute SD across columns of first 5 rows
x = 1:length(meanTAsound1start_ctrl_11_15); % create x-coordinates
upper_bound = meanTAsound1start_ctrl_11_15 + std_TAsound1start_ctrl_11_15; % upper bound of shaded area
lower_bound = meanTAsound1start_ctrl_11_15 - std_TAsound1start_ctrl_11_15; % lower bound of shaded area
 fill([901,901,900+(soundduration*30),900+(soundduration*30)],[min(DeltaFF),max(DeltaFF),max(DeltaFF),min(DeltaFF)],[0.9294, 0.6902, 0.7882],'EdgeColor','none','FaceAlpha',0.3);
fill([x, fliplr(x)], [upper_bound, fliplr(lower_bound)], [0.8 0.8 0.8], 'LineStyle', 'none');
plot(meanTAsound1start_ctrl_11_15,'b','LineWidth',1)
axis('tight')
ylim([-5 5]);
xlabel('time after paired sound start [sec]'); ylabel('DF/F [%]');
title('trials 11-15, CS+, ctrl')
% %% statistics
% % Define analysis window (sound period)
% window = 901 : (900 + soundduration*30);
% 
% % Compute AUC for each trial
% AUC_ctrl   = trapz(meanTAsound1start_ctrl(:, window), 2);
% AUC_sensor = trapz(meanTAsound1start_sensor(:, window), 2);
% 
% % Independent-samples t-test (use ttest2 for unpaired data)
% [~, p, ci, stats] = ttest2(AUC_ctrl, AUC_sensor);
% 
% % Compute effect size (Cohen's d)
% mean_ctrl   = mean(AUC_ctrl);
% mean_sensor = mean(AUC_sensor);
% std_pooled  = sqrt(((length(AUC_ctrl)-1)*var(AUC_ctrl) + (length(AUC_sensor)-1)*var(AUC_sensor)) ...
%                    / (length(AUC_ctrl) + length(AUC_sensor) - 2));
% cohens_d = (mean_ctrl - mean_sensor) / std_pooled;
% 
% % Display summary statistics
% fprintf('\n===== AUC Comparison: Control vs Sensor =====\n');
% fprintf('Mean AUC (Control): %.4f ± %.4f\n', mean_ctrl, std(AUC_ctrl));
% fprintf('Mean AUC (Sensor):  %.4f ± %.4f\n', mean_sensor, std(AUC_sensor));
% fprintf('t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
% fprintf('95%% CI of difference: [%.4f, %.4f]\n', ci(1), ci(2));
% fprintf('Cohen''s d = %.3f\n', cohens_d);
% fprintf('============================================\n');
% 
% % Optional: boxplot
% figure;
% boxplot([AUC_ctrl, AUC_sensor], {'Control', 'CNO'});
% ylabel('AUC');
% title(sprintf('AUC Comparison (p = %.3f, d = %.2f)', p, cohens_d));


%% 
 saveas(gcf,strcat(filename,'_photometryAnalysis_total'),'png');
%       save(strcat(filename,'_photometryAnalysis_total'),'meanTAsound1start_ctrl','meanTAsound1start_sensor', 'meanTAsound2start_ctrl','meanTAsound2start_sensor','meanDeltaFF_ctrl','meanDeltaFF_sensor','meanTAfreezingstart_ctrl','meanTAfreezingstart_sensor','meanTAfreezingend_ctrl','meanTAfreezingend_sensor');
