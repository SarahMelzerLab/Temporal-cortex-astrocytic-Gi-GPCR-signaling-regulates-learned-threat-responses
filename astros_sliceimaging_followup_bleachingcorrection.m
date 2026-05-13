%% Astrocyte follow-up analysis with bleaching correction
% - Loads any number of conditions from selected folders
% - Each folder contains .mat files with variables:
%       DeltaFF       [T x N]
% - Computes mean traces, bleaching correction
%   plots and stats (Holm-Bonferroni)

clearvars
close all
clc

%%  User parameters
framerate      = 4;        % Hz
defaultLen     = 6500;     % expected max length (frames)
plotEndSec     = 15 * 60;  % plot up to 15 min
plotEndFrames  = plotEndSec * framerate;

% Peak window (in minutes)
peakStartMin   = 4;
peakEndMin     = 10;

% Smoothing window for peak detection
smoothWinMin   = 1;                         % 1 min moving average
smoothWinFrames = round(smoothWinMin * 60 * framerate);

%%Ask where to save results 
savePath = uigetdir(pwd, 'Select folder where you want to save the results');

if isequal(savePath, 0)
    error('Folder selection cancelled. No save directory selected.');
end

% Set selected save folder as current path so future uigetdir starts there
cd(savePath);

%%  Ask for number of conditions & names --------------------------
numConditions = input('Enter TOTAL number of conditions (including control): ');
while ~isscalar(numConditions) || numConditions < 2
    disp('Please enter a number >= 2 (at least 1 control + 1 experimental).');
    numConditions = input('Enter TOTAL number of conditions (including control): ');
end

% Struct to hold all condition data
conditions = struct( ...
    'name',            [], ...
    'folder',          [], ...
    'files',           [], ...
    'meanDeltaFF',     [], ...
    'meanTrace',       [], ...
    'meanSTD',         [], ...
    'smoothedTrace',   [], ...
    'smoothedSlices',  [], ...
    'peak',            [], ...
    'peakFrame',       [], ...
    'peak_mean',       [], ...
    'peak_sem',        [], ...
    'peak_n',          [], ...
    'T',               [] );

%%  Load all conditions 
for c = 1:numConditions
    fprintf('\n--- Condition %d ---\n', c);
    conditions(c).name = input(sprintf('Enter name for condition %d: ', c), 's');
    
    folderPath = uigetdir(savePath, sprintf('Select folder for "%s"', conditions(c).name));
    if folderPath == 0
        error('Folder selection cancelled.');
    end
    conditions(c).folder = folderPath;
    
    conditions(c).files = dir(fullfile(folderPath, '*.mat'));
    if isempty(conditions(c).files)
        error('No .mat files found in folder "%s".', folderPath);
    end
    
    nFiles = numel(conditions(c).files);
    tmpTraces = cell(nFiles,1);
    
    for f = 1:nFiles
        dataFile = fullfile(folderPath, conditions(c).files(f).name);
        data = load(dataFile);
        
        if ~isfield(data, 'DeltaFF')
            error('File %s does not contain variable "DeltaFF".', ...
                conditions(c).files(f).name);
        end
        
        % Mean across ROIs within a slice -> one trace per slice
        trace = mean(data.DeltaFF, 2)';   % 1 x T
        tmpTraces{f} = trace;
    end
    
    lenVec = cellfun(@numel, tmpTraces);
    Tcond  = min(lenVec);
    
    conditions(c).meanDeltaFF = zeros(nFiles, Tcond);
    for f = 1:nFiles
        vec = tmpTraces{f};
        conditions(c).meanDeltaFF(f,:) = vec(1:Tcond);
    end
    
    conditions(c).T = Tcond;
end

%%  Determine common length across all conditions 
allLens = arrayfun(@(x) x.T, conditions);
if any(allLens <= 0)
    error('At least one condition has zero usable frames.');
end

Tcommon = min(allLens);
fprintf('\nUsing %d frames (common across all conditions).\n', Tcommon);

for c = 1:numConditions
    conditions(c).meanDeltaFF = conditions(c).meanDeltaFF(:, 1:Tcommon);
end

%% Compute mean traces and std per frame across slices
for c = 1:numConditions
    conditions(c).meanTrace = nanmean(conditions(c).meanDeltaFF, 1);
    conditions(c).meanSTD   = nanstd(conditions(c).meanDeltaFF, 0, 1);
end

%%  Ask which condition is control for comparison 
fprintf('\nConditions:\n');
for c = 1:numConditions
    fprintf('  %d = %s\n', c, conditions(c).name);
end

controlIdx = input('Enter index of CONTROL condition (for stats & overlay plots): ');
if controlIdx < 1 || controlIdx > numConditions
    error('Invalid control condition index.');
end

expIdx = setdiff(1:numConditions, controlIdx);

%% Bleaching correction (CONTROL-based) 
doBleach = input('\nApply bleaching correction based on CONTROL trace? (1=yes, 0=no): ');
if isempty(doBleach), doBleach = 1; end

if doBleach == 1
    
    fitStartFrame = 100;
    fitEndFrame   = min(plotEndFrames, Tcommon);
    fitIdx        = fitStartFrame:fitEndFrame;

    tFit = ((fitIdx - fitIdx(1)) / framerate) / 60;
    yCtlRaw = conditions(controlIdx).meanTrace(fitIdx);

    winSec    = 60;
    pctl      = 20;
    winFrames = max(5, round(winSec * framerate));

    yBase = running_prctile(yCtlRaw, winFrames, pctl);

    smoothSec    = 20;
    smoothFrames = max(3, round(smoothSec * framerate));
    yBaseSmooth  = movmean(yBase, smoothFrames, 'omitnan');

    expModel = @(p,t) p(1).*exp(p(2).*t) + p(3);
    sseExp   = @(p) sum((expModel(p,tFit) - yBaseSmooth).^2);

    y0   = yBaseSmooth(1);
    yEnd = yBaseSmooth(end);
    a0   = y0 - yEnd; if abs(a0) < eps, a0 = 1; end
    b0   = -1 / max(tFit(end), 1e-6);
    c0   = yEnd;
    p0   = [a0 b0 c0];

    opts = optimset('Display','off');
    pExp = fminsearch(sseExp, p0, opts);

    yFit = expModel(pExp, tFit);
    trendToSubtract = yFit - yFit(1);

    figBleach = figure('Name','Bleaching correction preview','Position',[200 200 1100 450]);

    subplot(1,2,1); hold on;
    plot(tFit, yCtlRaw,     'Color',[0.6 0.6 0.6], 'LineWidth',1.5);
    plot(tFit, yBaseSmooth, 'b', 'LineWidth',2);
    plot(tFit, yFit,        'r', 'LineWidth',2);
    xlabel('Time [min]'); ylabel('\DeltaF/F');
    title('Control: raw + baseline + exp fit');
    legend({'Control mean (raw)','Baseline (running pctl)','Exp fit to baseline'},'Location','best');
    box on; axis tight;

    subplot(1,2,2); hold on;
    yCtlCorrPreview = yCtlRaw - trendToSubtract;
    plot(tFit, yCtlCorrPreview, 'k', 'LineWidth',2);
    yline(0,'--');
    xlabel('Time [min]'); ylabel('Corrected \DeltaF/F');
    title('Control after correction (preview)');
    box on; axis tight;

    % Apply same correction to all slices in all conditions
    for c = 1:numConditions
       conditions(c).meanDeltaFF(:, fitIdx) = conditions(c).meanDeltaFF(:, fitIdx) - trendToSubtract;
%           conditions(c).meanDeltaFF(:, fitIdx) = conditions(c).meanDeltaFF(:, fitIdx) ./ yFit
    end

    % Recompute mean/std after correction
    for c = 1:numConditions
        conditions(c).meanTrace = nanmean(conditions(c).meanDeltaFF, 1);
        conditions(c).meanSTD   = nanstd(conditions(c).meanDeltaFF, 0, 1);
    end

    for c = 1:numConditions
        conditions(c).bleaching.method    = 'exp fit to running-percentile baseline (anchored subtraction)';
        conditions(c).bleaching.pctl      = pctl;
        conditions(c).bleaching.winSec    = winSec;
        conditions(c).bleaching.smoothSec = smoothSec;
        conditions(c).bleaching.expParams = pExp;
        conditions(c).bleaching.fitFrames = fitIdx;
    end

    fprintf('\nBleaching correction applied (EXP fit to baseline from CONTROL).\n');
end

%%  Plot mean traces: each experimental vs control
timeMin = (0:Tcommon-1) / framerate / 60;

nComp  = numel(expIdx);
nCols  = ceil(sqrt(max(nComp,1)));
nRows  = ceil(nComp / nCols);

figTraces = figure('Name','Mean traces (control vs each condition)', ...
                   'Position',[100 100 1200 800]);

controlColor = [0 0.6 0];
expColors    = lines(numConditions);

for k = 1:nComp
    cIdx = expIdx(k);
    subplot(nRows, nCols, k); hold on;
    
    ctlMean = conditions(controlIdx).meanTrace(100:min(plotEndFrames,Tcommon));
    ctlSTD  = conditions(controlIdx).meanSTD(100:min(plotEndFrames,Tcommon));
    tPlot   = timeMin(100:min(plotEndFrames,Tcommon));
    
    fill([tPlot, fliplr(tPlot)], ...
         [ctlMean + ctlSTD, fliplr(ctlMean - ctlSTD)], ...
         controlColor, 'FaceAlpha', 0.2, 'EdgeColor','none');
    plot(tPlot, ctlMean, 'Color', controlColor, 'LineWidth', 2);
    
    exMean = conditions(cIdx).meanTrace(100:min(plotEndFrames,Tcommon));
    exSTD  = conditions(cIdx).meanSTD(100:min(plotEndFrames,Tcommon));
    
    fill([tPlot, fliplr(tPlot)], ...
         [exMean + exSTD, fliplr(exMean - exSTD)], ...
         expColors(cIdx,:), 'FaceAlpha', 0.2, 'EdgeColor','none');
    plot(tPlot, exMean, 'Color', expColors(cIdx,:), 'LineWidth', 2);
    
    title(sprintf('%s vs %s', conditions(cIdx).name, conditions(controlIdx).name), ...
          'Interpreter','none');
    xlabel('Time [min]');
    ylabel('\DeltaF/F');
    box on;
    axis tight
end

sgtitle('Mean traces (Control vs experimental conditions)','FontSize',14);

%%  Compute smoothed peak for each slice & condition 
peakStartFrame = max(1, round(peakStartMin * 60 * framerate));
peakEndFrame   = min(Tcommon, round(peakEndMin * 60 * framerate));

fprintf('\nPeak window: %.1f–%.1f min (frames %d–%d of %d)\n', ...
    peakStartMin, peakEndMin, peakStartFrame, peakEndFrame, Tcommon);
fprintf('Smoothing window: %.1f min (%d frames)\n', smoothWinMin, smoothWinFrames);

for c = 1:numConditions
    nSlices = size(conditions(c).meanDeltaFF, 1);
    conditions(c).smoothedSlices = movmean(conditions(c).meanDeltaFF, smoothWinFrames, 2, 'omitnan');
    conditions(c).smoothedTrace  = nanmean(conditions(c).smoothedSlices, 1);
    
    [peakVals, peakLocs] = max(conditions(c).smoothedSlices(:, peakStartFrame:peakEndFrame), [], 2);
    conditions(c).peak      = peakVals;
    conditions(c).peakFrame = peakLocs + peakStartFrame - 1;
    
    n = sum(~isnan(peakVals));
    conditions(c).peak_mean = mean(peakVals, 'omitnan');
    conditions(c).peak_sem  = std(peakVals, 'omitnan') / sqrt(n);
    conditions(c).peak_n    = n;
    
    conditions(c).peak_median = median(peakVals, 'omitnan');
qtmp = prctile(peakVals(~isnan(peakVals)), [25 75]);
conditions(c).peak_q1     = qtmp(1);
conditions(c).peak_q3     = qtmp(2);
conditions(c).peak_iqr    = qtmp(2) - qtmp(1);
end

fprintf('\n--- Smoothed peak summary | window %.1f–%.1f min ---\n', ...
    peakStartMin, peakEndMin);
for c = 1:numConditions
    fprintf('%-20s: mean = %.4g, SEM = %.4g | median = %.4g, IQR = [%.4g-%.4g], N = %d\n', ...
        conditions(c).name, ...
        conditions(c).peak_mean, ...
        conditions(c).peak_sem, ...
        conditions(c).peak_median, ...
        conditions(c).peak_q1, ...
        conditions(c).peak_q3, ...
        conditions(c).peak_n);
end
%%  Plot smoothed mean traces with peak window 
figSmoothed = figure('Name','Smoothed mean traces','Position',[120 120 1200 800]);

for k = 1:nComp
    cIdx = expIdx(k);
    subplot(nRows, nCols, k); hold on;
    
    tPlot = timeMin(100:min(plotEndFrames,Tcommon));
    xPatch = [peakStartMin peakEndMin peakEndMin peakStartMin];
    yPatch = [-1e6 -1e6 1e6 1e6];
    patch(xPatch, yPatch, [0.95 0.95 0.8], 'EdgeColor','none', 'FaceAlpha',0.4);
    
    plot(tPlot, conditions(controlIdx).smoothedTrace(100:min(plotEndFrames,Tcommon)), ...
        'Color', controlColor, 'LineWidth', 2);
    plot(tPlot, conditions(cIdx).smoothedTrace(100:min(plotEndFrames,Tcommon)), ...
        'Color', expColors(cIdx,:), 'LineWidth', 2);
    
    title(sprintf('%s vs %s (smoothed)', conditions(cIdx).name, conditions(controlIdx).name), ...
        'Interpreter','none');
    xlabel('Time [min]');
    ylabel('\DeltaF/F');
    box on;
    axis tight
end

sgtitle('Smoothed mean traces (1 min movmean)','FontSize',14);

% %%  Plot PEAK scatter + bar + SEM 
% figPeak = figure('Name','Peak response (all conditions)', ...
%                  'Position',[150 150 1000 600]);
% hold on;
% colorsPeak = lines(numConditions);
% 
% for c = 1:numConditions
%     xPos = c * ones(size(conditions(c).peak));
%     scatter(xPos, conditions(c).peak, 50, 'filled', ...
%         'MarkerFaceColor', colorsPeak(c,:), ...
%         'MarkerEdgeColor', 'k');
% end
% 
% meanPeak = arrayfun(@(x) x.peak_mean, conditions);
% semPeak  = arrayfun(@(x) x.peak_sem,  conditions);
% 
% bar(1:numConditions, meanPeak, 'FaceColor','none', 'EdgeColor','k', 'LineWidth',1.5);
% errorbar(1:numConditions, meanPeak, semPeak, 'k', 'LineStyle','none', 'LineWidth',1.5);
% 
% set(gca, 'XTick', 1:numConditions, ...
%          'XTickLabel', {conditions.name}, ...
%          'XTickLabelRotation', 45);
% ylabel('Smoothed peak \DeltaF/F');
% title(sprintf('Peak response (movmean %.1f min, window %.1f-%.1f min)', ...
%     smoothWinMin, peakStartMin, peakEndMin));
% box on;
% hold off;

%%  Statistics: PEAK of each experimental vs control 
alpha = 0.05;
m     = numel(expIdx);

rawP      = nan(m,1);
testName  = cell(m,1);
compNames = cell(m,1);

for i = 1:m
    cIdx = expIdx(i);
    group1 = conditions(controlIdx).peak;
    group2 = conditions(cIdx).peak;
    
    h1 = lillietest(group1);
    h2 = lillietest(group2);
    
    if h1 == 0 && h2 == 0
        [~, p] = ttest2(group1, group2);
        testName{i} = 't-test';
    else
        p = ranksum(group1, group2);
        testName{i} = 'Mann-Whitney U';
    end
    
    rawP(i)      = p;
    compNames{i} = conditions(cIdx).name;
end

[sortedP, sortIdx] = sort(rawP);
adjSorted = zeros(size(sortedP));
for i = 1:m
    adjSorted(i) = (m - i + 1) * sortedP(i);
end
adjSorted = min(adjSorted, 1);
for i = 2:m
    adjSorted(i) = max(adjSorted(i), adjSorted(i-1));
end
adjP = zeros(size(sortedP));
adjP(sortIdx) = adjSorted;

fprintf('\n--- Statistical comparison of smoothed peak vs control: %s ---\n', conditions(controlIdx).name);
for i = 1:m
    fprintf('Control vs %-20s: %-15s  raw p = %.4g, Holm p = %.4g', ...
        compNames{i}, testName{i}, rawP(i), adjP(i));
    if adjP(i) < alpha
        fprintf('  --> SIGNIFICANT (p < %.2f)\n', alpha);
    else
        fprintf('  --> not significant\n');
    end
end


%% -Text figure with stats summary 
figStats = figure('Name','Statistical Comparison', ...
                  'Position',[200 200 850 100 + 25*m]);
axis off; hold on;

yStart = 0.95;
dy     = 0.06;

titleStr = sprintf('Peak comparison vs control: %s (Holm-Bonferroni, \\alpha=%.2f)', ...
    conditions(controlIdx).name, alpha);
text(0.01, 0.98, titleStr, 'FontSize', 14, 'FontWeight','bold', 'Interpreter','none');

for i = 1:m
    lineStr = sprintf('Control vs %-20s: %-15s  raw p = %.4g, Holm p = %.4g', ...
        compNames{i}, testName{i}, rawP(i), adjP(i));
    if adjP(i) < alpha
        lineStr = [lineStr '  --> SIGNIFICANT'];
    else
        lineStr = [lineStr '  --> not significant'];
    end
    text(0.02, yStart - i*dy, lineStr, 'FontSize', 11, 'Interpreter','none');
end

%% - Save figures and data 
fprintf('\nSaving figures and data to: %s\n', savePath);

if exist('figTraces', 'var')
    saveas(figTraces, fullfile(savePath, 'MeanTraces_ControlVsConditions.png'));
    print(figTraces, '-depsc', '-painters', fullfile(savePath, 'MeanTraces_ControlVsConditions.eps'));
end

if exist('figBleach', 'var')
    saveas(figBleach, fullfile(savePath, 'BleachingCorrectionPreview.png'));
    print(figBleach, '-depsc', '-painters', fullfile(savePath, 'BleachingCorrectionPreview.eps'));
end

if exist('figSmoothed', 'var')
    saveas(figSmoothed, fullfile(savePath, 'SmoothedMeanTraces.png'));
    print(figSmoothed, '-depsc', '-painters', fullfile(savePath, 'SmoothedMeanTraces.eps'));
end

if exist('figPeak', 'var')
    saveas(figPeak, fullfile(savePath, 'Peak_AllConditions.png'));
    print(figPeak, '-depsc', '-painters', fullfile(savePath, 'Peak_AllConditions.eps'));
end

if exist('figStats', 'var')
    saveas(figStats, fullfile(savePath, 'Statistics_HolmBonferroni_Peak.png'));
    print(figStats, '-depsc', '-painters', fullfile(savePath, 'Statistics_HolmBonferroni_Peak.eps'));
end

save(fullfile(savePath, 'Analysis_AllConditions_Peak.mat'), ...
     'conditions', 'controlIdx', 'expIdx', 'framerate', ...
     'peakStartMin', 'peakEndMin', 'smoothWinMin', 'smoothWinFrames');

fprintf('All figures and data saved.\n');

%% helper function
function yP = running_prctile(y, winFrames, p)
% running_prctile: sliding-window percentile 

    y = y(:);
    n = numel(y);
    hw = floor(winFrames/2);
    yP = nan(n,1);

    for i = 1:n
        i1 = max(1, i-hw);
        i2 = min(n, i+hw);
        seg = y(i1:i2);
        seg = seg(~isnan(seg));
        if ~isempty(seg)
            yP(i) = prctile(seg, p);
        end
    end

    yP = yP.';
end