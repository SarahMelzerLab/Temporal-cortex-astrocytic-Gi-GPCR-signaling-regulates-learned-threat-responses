% Add path to your data folder: select the folder with barcodes.tsv,
% features.tsv, matrix.mtx zipped files
cd('S:\MelzerLab\Lab\RNAseqData')

disp('choose the folder with the source data')
dataFolder = uigetdir('*')
disp('choose the folder to save the new data')
saveFolder = uigetdir('*')

cd(dataFolder)
close all

global editBoxes
global fig
global S
global target_genes


%% extracts zipped barcodes files
dataType1=input('data already formatted? YES=1; NO=0')
if dataType1==0
   dataType=input('1 = data formated as zipped barcode,features,matrix files; 2=a single tsv file; 3=a single txt file; 4=csv file; 5=csv file too large to read at once; 6=mtx file')
   if dataType==1
barfile = [dataFolder '\barcodes.tsv.gz'];
gunzip(barfile);
barfile2 = strrep(barfile, '.gz','');
 fid = fopen(barfile2);
    barcodes = textscan(fid, '%s','Delimiter','\n');
    fclose(fid);
    barcodes = barcodes{1};

% extracts zipped features files
features = [dataFolder '\features.tsv.gz'];
gunzip(features);


% extracts zipped natrix files
matrix = [dataFolder '\matrix.mtx.gz'];
gunzip(matrix);    
filename='matrix.mtx';

% Read gene list features, barcodes, and expression matrix
genes = readtable([dataFolder '\features.tsv'], 'FileType', 'text', 'ReadVariableNames', false);
barcodes = readtable([dataFolder '\barcodes.tsv'], 'FileType', 'text', 'ReadVariableNames', false);

fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    % Skip header lines
    line = fgetl(fid);
    while startsWith(line, '%')
        line = fgetl(fid);
    end

    % Read matrix size and number of non-zero entries
    dims = sscanf(line, '%d %d %d');
    nRows = dims(1); nCols = dims(2); nVals = dims(3);

    % Read sparse entries
    data = fscanf(fid, '%d %d %f', [3, nVals]);
    fclose(fid);

    % Build sparse matrix
    expr_vals = sparse(data(1,:), data(2,:), data(3,:), nRows, nCols);
% Optional: convert to full matrix if needed (can be large!)
%X = full(X);

% Extract gene symbols
gene_names = genes.Var2;

   elseif dataType==6

% extracts zipped natrix files
matrix = [dataFolder '\matrix.mtx'];
 

fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    % Skip header lines
    line = fgetl(fid);
    while startsWith(line, '%')
        line = fgetl(fid);
    end

    % Read matrix size and number of non-zero entries
    dims = sscanf(line, '%d %d %d');
    nRows = dims(1); nCols = dims(2); nVals = dims(3);

    % Read sparse entries
    data = fscanf(fid, '%d %d %f', [3, nVals]);
    fclose(fid);

    % Build sparse matrix
    expr_vals = sparse(data(1,:), data(2,:), data(3,:), nRows, nCols);

% Extract gene symbols
gene_names = genes.Var2;

elseif dataType==2

    % Full path to TSV
filename = uigetfile('*.tsv');

% Read the table
T = readtable(filename, 'FileType','text', 'Delimiter','\t');

% The first column holds gene names
gene_names = T{:,1};  % cell array for gene names

% The other columns are expression values
expr_vals = T{:,2:end};  % numeric matrix: genes × cells

% Also get cell/sample names (column headers of expression columns)
cell_names = T.Properties.VariableNames(2:end);
   elseif dataType==3
       filename = uigetfile('*.txt');
               % Open file
        fid = fopen(filename, 'rt');
        
        % Read header line (contains cell IDs)
        headerLine = fgetl(fid);
        sampleIDs = strsplit(headerLine, '\t');
        sampleIDs = sampleIDs(2:end);  % remove first column ("gene" column)
        
        % Read the rest of the file
        data = textscan(fid, '%s %f', 'Delimiter', '\t', 'HeaderLines', 0, 'CollectOutput', 1);
        fclose(fid);
        
        % If textscan only gets one column, use readtable instead
        if numel(sampleIDs) > 1
            % Better to use readtable if multiple samples
            T = readtable(filename, 'FileType', 'text', 'Delimiter', '\t');
            
            gene_names = T{:,1};
            expr_vals = T{:,2:end};
            
            %expr_vals=log(expr_vals+1);
        else
            error('Check file formatting or use readtable for robustness.');
        end
   elseif dataType==4
       filename = uigetfile('*.csv');
      
       try
       % Read the full table
        T = readtable(filename, 'ReadRowNames', true);  % first column = row names (genes)
                % Extract expression values
         SpTrans=input('1=spatial transcriptomics; 0=scRNAseq')
            if SpTrans==1
                gene_names = T{:,1};
                expr_vals = T{:,2:3:end};
            else
                expr_vals = log(table2array(T)+1);             % numeric matrix: genes x cells
                %expr_vals = table2array(T);             % numeric matrix: genes x cells
                gene_names = T.Properties.RowNames;   % cell array of gene names
            end
        T = readtable(filename, 'ReadVariableNames', true);
        sampleIDs1 = T.Properties.VariableNames;
        if SpTrans==1
            sampleIDs1=sampleIDs1(3:3:end);
            sampleIDs=sampleIDs1;
            save(strcat(saveFolder,'\extractedData'),'expr_vals','gene_names','sampleIDs')
        else
        sampleIDs1=sampleIDs1(2:end);
        sampleIDs=sampleIDs1;
         save(strcat(saveFolder,'\extractedData'),'expr_vals','gene_names','sampleIDs')
        end
       end
       if SpTrans==1
       else
       GeneNameSep=input('1=gene names are in separate table')
        if GeneNameSep==1
            filename = uigetfile('*.csv');
        T = readtable(filename);
        gene_names=table2cell(T(2:end,1));
        end

%         %if the first row is gene names and the first x columns are other
%         %information:
%         raw = readcell(filename);
%         gene_names = raw(1, 6:end)';  % Cell array of gene names
%         expr_vals = log(cell2mat(raw(2:end, 6:end))'+1);  % Converts cell to numeric
        ClustSort=input('1=sort by clusters')
        if ClustSort==1
        disp('select the cell clustering table')
        filename = uigetfile('*.csv');
        T = readtable(filename);
        sampleIDs = table2cell(T(1:end,47));%column 11 for Tasic 2016
        sampleIDs2 = table2cell(T(1:end,1));
        sortidx=[];
        for i=1:length(sampleIDs1)
            sortidx(i)=find(strcmp(sampleIDs1,sampleIDs2(i)));
        end
        expr_valsorig=expr_vals;
        expr_vals=expr_vals(:,sortidx);
        sampleIDs1=sampleIDs1(sortidx);
        save(strcat(saveFolder,'\extractedData'),'expr_vals','gene_names','sampleIDs','sampleIDs2')
        end
       end
   elseif dataType==5
    load("S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\sampleIDs.mat")%cell IDs as they appear in metadata
    load("S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\cell_ids.mat")% cell IDs as they appear in the expression matrix
    load("S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\gene_names.mat")%cell IDs as they appear in metadata
    [~, idx] = ismember(cell_ids_cell, sampleIDs);
    load('S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\regionIDs.mat')
    idx(idx==0)=length(regionIDs)+1;
    regionIDs=[regionIDs;"NaN"];
     regionIDs=regionIDs(idx);
    unique(regionIDs)
    Filter1=input('select one of the above region(s) to filter for: precise names as ["","",""]')
    idx1 = find(strcmp(regionIDs,Filter1));
    load('S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\subclassIDs.mat')
    subclassIDs=[subclassIDs;"NaN"];
    subclassIDs=subclassIDs(idx);
    unique(subclassIDs)
    Filter2=input('select one of the above subclass(es) to filter for: precise name as ["","",""]; 0=no subclass filter')
    if isa(Filter2, 'double')
        IDFilter=idx1;
    else
    idx2 = find(contains(subclassIDs,Filter2));
    IDFilter = intersect(idx1, idx2);
    sampleIDs=subclassIDs(IDFilter);
    end
    % Display result
    fprintf('Found %d matching rows.\n', length(IDFilter));
    save('S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\IDFilter.mat', 'IDFilter');
    pause(2)
    disp('Waiting for extraction in python: S:\MelzerLab\Lab\RNAseqData\extract_rows.py');
    system('python S:\MelzerLab\Lab\RNAseqData\extract_rows.py');
    [status, cmdout] = system('python "S:\MelzerLab\Lab\RNAseqData\extract_rows.py"');
    if status ~= 0
        error('Python script failed:\n%s', cmdout);
    end
    load('S:\MelzerLab\Lab\RNAseqData\Cortex_Yao_2021\all_cells\matrix_filtered.mat')
    size(data)
    expr_vals2=data';
    expr_vals2=log(expr_vals2+1);
    expr_vals=expr_vals2;
    save(strcat(saveFolder,'\extractedData'),'expr_vals','gene_names','sampleIDs')
   end
   
elseif dataType1==1
       try
           load('extractedData.mat')
       catch
           load('extractedData1.mat')
           expr_vals_orig=[expr_vals];
           load('extractedData2.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           try
           load('extractedData3.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           end
           try
           load('extractedData4.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           end
           try
           load('extractedData5.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           end
           try
           load('extractedData6.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           end
           try
           load('extractedData7.mat')
           expr_vals_orig=[expr_vals_orig;expr_vals];
           end
           expr_vals=expr_vals_orig;
           
       end

end

%% decide whether you want to exclude any data to make the cell population more specific
expr_vals_orig=expr_vals;
excludeData=input('exclude any data? 1=filter for gene; 2=exclude by; 3=filter by sample ID; 4=filter by cluster column; 5=filter by subclass and region from separate mat files; 0=none')
if excludeData==1
    geneFilter=input('type gene name to filter for')
    % Find the indices of these genes
    idx = find(strcmp(gene_names,geneFilter))
    keep=find(expr_vals(idx,:)>max(expr_vals(idx,:))/10*3);
    expr_vals2 = expr_vals(:, keep);  % rows = genes, columns = cells
elseif excludeData==2
    geneFilter=input('type gene to exclude')
    % Find the indices of these genes
    idx = find(strcmp(gene_names,geneFilter));
    exclude=find(expr_vals(idx,:));
    expr_vals2=expr_vals;
    expr_vals2(:, exclude)=[];  % rows = genes, columns = cells
elseif excludeData==3
    sampleIDs
    IDFilter=input('type ID name to filter for as ["","",""]')
    % Find the indices of these genes
    idx = find(contains(sampleIDs,IDFilter))
    expr_vals2 = expr_vals(:, idx);  % rows = genes, columns = cells
elseif excludeData==4
    ColFilter=input('type cluster-columns to filter for as [1,2,3]')
    expr_vals2 = expr_vals(:, ColFilter);  % rows = genes, columns = cells
elseif excludeData==5
    disp('should be already extracted;this step takes long!')
else
    expr_vals2=expr_vals;
end
% if dataType==1
% else
%     saveData=input('1=save extracted data; 0=already saved')
%     if saveData==1
%     save('extractedData','expr_vals','gene_names')
%     try 
%         save('extractedData','expr_vals','gene_names','sampleIDs')
%     end
%     end
% end
expr_vals=expr_vals2;

%% GUI to select genes
close all
fig = uifigure('Name', 'Select gene names', 'Position', [100 100 400 1000]);

    % Instructions
    uilabel(fig, 'Position', [20 950 360 30], 'Text', 'Enter up to 24 gene names; case- and spelling sensitive!!!');
    uilabel(fig, 'Position', [20 920 360 30], 'Text', 'Genes that will be used for sorting','FontColor',[1 0.7 0.7]);
    uilabel(fig, 'Position', [20 620 360 30], 'Text', 'Other genes of interest','FontColor',[0.6 0.6 0.6]);

    % Create 12 editable text fields
    editBoxes = gobjects(12,1);
    y = 900;
    for i = 1:8
        editBoxes(i) = uieditfield(fig, 'text', 'Position', [50 y 300 25],'BackgroundColor',[1 0.5 0.5]);
        y = y - 35;
    end
    y=y-25;
    for i = 9:24
        editBoxes(i) = uieditfield(fig, 'text', 'Position', [50 y 300 25],'BackgroundColor',[0.9 0.9 0.9]);
        y = y - 35;
    end

    % Button to create structure
    btn = uibutton(fig, ...
        'Text', 'Select genes', ...
        'Position', [230 20 100 30],'BackgroundColor',[0.9 0.3 0.3], ...
        'ButtonPushedFcn', @(btn,event) create_struct_callback());
% 
%     % Output text area
%     outputLabel = uilabel(fig, 'Position', [20 100 360 100], ...
%         'Text', '', 'WordWrap', 'on');

% Button to reuse gene names
    btn2 = uibutton(fig, ...
        'Text', 'Reuse gene selection', ...
        'Position', [10 30 130 20], ...
        'ButtonPushedFcn', @(btn2,event) reuse_old_data());
   % Button to use typical gene names
    btn3 = uibutton(fig, ...
        'Text', 'Use typical markers', ...
        'Position', [10 5 130 20], ...
        'ButtonPushedFcn', @(btn3,event) create_struct_callback2());
   % Button to use typical gene names
    btn4 = uibutton(fig, ...
        'Text', 'Clear all', ...
        'Position', [150 20 70 30], ...
        'ButtonPushedFcn', @(btn4,event) clear_callback());


%% make figure 1

waitfor(fig)
% List of genes of interest
target_genes = S;

% Find the indices of these genes
idx=[];
excludegene=[];
for i=1:length(target_genes)
    if length(find(strcmp(gene_names,target_genes(i))))==1
        idx = [idx,find(strcmp(gene_names,target_genes(i)))];
    else
        excludegene=[excludegene,i];

     warning('Some genes not found or empty: %s', strjoin(target_genes(i), ', '));
    end
end

% Extract expression rows for these genes
expr_subset = expr_vals(idx, :);  % rows = genes, columns = cells
target_genes(excludegene)=[];
gene_labels = target_genes;  % your row labels



figure('Position', [100 100 1500 1200]);
for i=1:min(8,length(target_genes))
[~, sort_idx] = sort(expr_subset(i, :), 'descend');  % highest expression first
expr_sorted = expr_subset(:, sort_idx);

subplot(4,2,i)
heatmap(expr_sorted, ...
    'Colormap', turbo, ...
       'ColorbarVisible', 'on', ...
        'GridVisible', 'off', ...  %turn off cell borders
    'XDisplayLabels', repmat(" ", 1, size(expr_sorted,2)), ...  % hide cell names if too many
    'YDisplayLabels', gene_labels);

title(gene_labels(i)');
xlabel('Cells');
ylabel('Genes');
end
cd(saveFolder)
saveas(gcf,'heatplot.png');
Marker_genes=target_genes;
cd(dataFolder)

%% make figure 2
% figure('Position',[100 100 1500 400])
% % Transpose: rows = cells, columns = genes
% X = expr_vals';  % now: [n_cells × n_genes]
% 
% 
% % Optional: normalize each cell (row) to sum 1 (CPM-like)
% % X = X ./ sum(X, 2);
% 
% % Optional: log-transform (for TPM, log1p is common)
% X = log1p(X);  % log(1 + TPM)
% 
% % Optional: select most variable genes
% % Compute variance of each gene (column)
% gene_variances = var(X, 0, 1);
% [~, idx_top] = maxk(gene_variances, 1000);  % top 1000 most variable genes
% X = X(:, idx_top);
% 
% %--- Run t-SNE ---
% rng(42);  % for reproducibility
% Y = tsne(X, 'NumDimensions', 2, 'Perplexity', 10);
% n_cells = size(expr_vals, 2);
% 
% for j=1:length(gene_labels)
% 
% 
% % Assign colors
% C = zeros(n_cells, 3);
% for i = 1:n_cells
%     if expr_vals(idx(j),i)>max(expr_vals(idx(j),:))/10*3
%         C(i, :) = [0 0.2 0.8];
%     else
%         C(i, :) = [0.6 0.6 0.6];
%     end
% end
% 
% % Plot
% subplot(2,6,j)
% scatter(Y(:,1), Y(:,2), 15, C, 'filled');
% %title(gene_labels(j));
% xlabel('t-SNE 1');
% ylabel('t-SNE 2');
% axis equal;
% grid off;
%     text(25,35-(j*5),gene_labels(j), 'Color',[0 0.2 0.8]);
% end
% 
% saveas(gcf,'tsne.png');

% %% make figure 3
% figure('Position', [100 100 1200 1200])
% for j=1:min(12,length(target_genes))
%     subplot(6,2,j); hold on
% % Assumes: expr_vals is 10x20000
% %          target_genes is 1x10 cell array
% 
% % Define groups based on first row (Crhr1 or similar)
% is_pos = expr_subset(j, :) > 0;   % Logical: positive cells
% is_neg = ~is_pos;               % negative cells
% 
% % Preallocate mean and SEM
% n_genes = size(expr_subset, 1);
% means_pos = zeros(n_genes, 1);
% means_neg = zeros(n_genes, 1);
% sems_pos  = zeros(n_genes, 1);
% sems_neg  = zeros(n_genes, 1);
% 
% % Calculate mean and SEM for each group per gene
% for i = 1:n_genes
%     gene_data = expr_subset(i, :);
%     
%     pos_vals = gene_data(is_pos);
%     neg_vals = gene_data(is_neg);
%     
%     means_pos(i) = mean(pos_vals);
%     means_neg(i) = mean(neg_vals);
%     
%     sems_pos(i) = std(pos_vals) / sqrt(length(pos_vals));
%     sems_neg(i) = std(neg_vals) / sqrt(length(neg_vals));
% end
% 
% % Prepare for bar plot
% x = 1:n_genes;
% bar_width = 0.4;
% 
% % Plot SEM as shaded boxes
% for i = 1:n_genes
%     % Positive group (green)
%     x_box1 = [x(i)-bar_width, x(i), x(i), x(i)-bar_width];
%     y_box1 = [means_pos(i)-sems_pos(i), means_pos(i)-sems_pos(i), ...
%               means_pos(i)+sems_pos(i), means_pos(i)+sems_pos(i)];
%     fill(x_box1, y_box1, [0.6 0.9 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
%     
%     % Negative group (gray)
%     x_box2 = [x(i), x(i)+bar_width, x(i)+bar_width, x(i)];
%     y_box2 = [means_neg(i)-sems_neg(i), means_neg(i)-sems_neg(i), ...
%               means_neg(i)+sems_neg(i), means_neg(i)+sems_neg(i)];
%     fill(x_box2, y_box2, [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
% end
% 
% % Plot bars
% bar(x - bar_width/2, means_pos, bar_width, 'FaceColor', [0.2 0.8 0.2], 'EdgeColor', 'none');  % Green
% bar(x + bar_width/2, means_neg, bar_width, 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none');  % Gray
% 
% % Add scatter dots for both groups
% for i = 1:n_genes
%     % Crhr1-positive
%     jitter_pos = (rand(1, sum(is_pos)) - 0.5) * 0.2;
%     scatter(repmat(x(i)-bar_width/2, 1, sum(is_pos)) + jitter_pos, ...
%             expr_subset(i, is_pos), 5, [0 0.5 0], 'filled', 'MarkerFaceAlpha', 0.3);
%     
%     % Crhr1-negative
%     jitter_neg = (rand(1, sum(is_neg)) - 0.5) * 0.2;
%     scatter(repmat(x(i)+bar_width/2, 1, sum(is_neg)) + jitter_neg, ...
%             expr_subset(i, is_neg), 5, [0.3 0.3 0.3], 'filled', 'MarkerFaceAlpha', 0.3);
% end
% 
% % Labels
% xticks(x);
% xticklabels(gene_labels);
% xtickangle(45);
% xlabel('Genes');
% ylabel('Expression');
% title(gene_labels(j));
% xlim([0.5, n_genes + 0.5]);
% grid on;
% box on;
% end
% saveas(gcf,'barplot.png');

%% make figure 4

AveragePlot=input('1=average across all cells,2=dont average at all,3=use predefined cell types')
if AveragePlot==3
    CellTypeLabels=unique(sampleIDs);
elseif AveragePlot==2
    if excludeData==4
        CellTypeLabels=ColFilter;
    else
        CellTypeLabels=[1:size(expr_vals,2)];
    end
elseif AveragePlot==1
    CellTypeLabels="1";
end

if AveragePlot==1
figure('Position', [100 100 1400 300])
elseif size(expr_vals,2)<5
    figure('Position', [100 100 1400 300])
else
    figure('Position', [100 100 2400 1200])
end
% List of genes of interest

gene_labels=[];

genesNP = [
    "Npy1r","Npy2r","Npy4r","Npy5r", ...
    "Tacr1","Tacr2","Tacr3", ...
    "Sstr1","Sstr2","Sstr3","Sstr4","Sstr5", ...
    "Oprm1","Oprd1","Oprk1","Oprl1", ...
    "Oxtr","Avpr1a","Avpr1b","Avpr2", ...
    "Vipr1","Vipr2","Adcyap1r1","Sctr","Ghrhr", ...
    "Cckar","Cckbr", ...
    "Galr1","Galr2","Galr3", ...
    "Hcrtr1","Hcrtr2", ...
    "Mc1r","Mc2r","Mc3r","Mc4r","Mc5r", ...
    "Crhr1","Crhr2", ...
    "Npffr1","Npffr2", ...
    "Kiss1r", ...
    "Gnrhr", ...
    "Prlhr", ...
    "Nmur1","Nmur2","Nmbr", ...
    "Grpr", ...
    "Rxfp1","Rxfp2","Rxfp3","Rxfp4", ...
    "Aplnr", ...
    "Ghsr", ...
    "Ednra","Ednrb", ...
    "Pth1r","Pth2r", ...
    "Calcr","Calcrl", ...
    "Ntsr1","Ntsr2", ...
    "Mlnr","Npbwr1","Npbwr2", ...
    "Bdkrb1","Bdkrb2","Agtr1","Uts2r","Mrgprx1","Mrgprx2","Mchr1","Mchr2","Gpr19","Fpr1","Fpr2"
];


targetgenesNP1=cellstr(genesNP(1:22));
targetgenesNP2=cellstr(genesNP(23:44));
targetgenesNP3=cellstr(genesNP(45:65));



targetgenesNA{1} = 'Adra1a';
targetgenesNA{2} = 'Adra1b';
targetgenesNA{3} = 'Adra1d';
targetgenesNA{4} = 'Adra2a';
targetgenesNA{5} = 'Adra2b';
targetgenesNA{6} = 'Adra2c';
targetgenesNA{7} = 'Adrb1';
targetgenesNA{8} = 'Adrb2';
targetgenesNA{9} = 'Adrb3';
targetgenesNA{10} = 'Drd1';
targetgenesNA{11} = 'Drd2';
targetgenesNA{12} = 'Drd3';
targetgenesNA{13} = 'Drd4';
targetgenesHT{1} = 'Htr1a';
targetgenesHT{2} = 'Htr1b';
targetgenesHT{3} = 'Htr1d';
targetgenesHT{4} = 'Htr1e';
targetgenesHT{5} = 'Htr1f';
targetgenesHT{6} = 'Htr2a';
targetgenesHT{7} = 'Htr2b';
targetgenesHT{8} = 'Htr2c';
targetgenesHT{9} = 'NA';
targetgenesHT{10} = 'Htr3c';
targetgenesHT{11} = 'Htr3d';
targetgenesHT{12} = 'Htr3e';
targetgenesHT{13} = 'Htr4';
targetgenesHT{14} = 'Htr5a';
targetgenesHT{15} = 'Htr5bp';
targetgenesHT{16} = 'Htr6';
targetgenesHT{17} = 'Htr7';

targetgenesGlu{1} = 'Grm1';
targetgenesGlu{2} = 'Grm2';
targetgenesGlu{3} = 'Grm3';
targetgenesGlu{4} = 'Grm4';
targetgenesGlu{5} = 'Grm5';
targetgenesGlu{6} = 'Grm6';
targetgenesGlu{7} = 'Grm7';
targetgenesGlu{8} = 'Grm8';
targetgenesGlu{9} = 'Gabbr1';
targetgenesGlu{10} = 'Gabbr2';
targetgenesGlu{11} = 'Chrm1';
targetgenesGlu{12} = 'Chrm2';
targetgenesGlu{13} = 'Chrm3';
targetgenesGlu{14} = 'Chrm4';
targetgenesGlu{15} = 'Chrm5';
targetgenesAdo{1} = 'Adora1';
targetgenesAdo{2} = 'Adora2';
targetgenesAdo{3} = 'Adora2b';
targetgenesAdo{4} = 'Adora3';
targetgenesAdo{5}='Hrh1';
targetgenesAdo{6}='Hrh2';
targetgenesAdo{7}='Hrh3';
targetgenesAdo{8}='Hrh4';
targetgenesAdo{9}='Cnr1';
targetgenesAdo{10}='Cnr2';
targetgenesAdo{11}='Gpr55';
targetgenesAdo{12}='Gpr18';
targetgenesOthers1 =["P2ry1", "P2ry2", "P2ry4", "P2ry6","P2ry10", "P2ry11","P2ry12", "P2ry13", "P2ry14","Mtnr1a","Mtnr1b","Gipr","Gpr39","Gpr174","Gpr17","Oxgr1","Ccr1", "Ccr5", "Cxcr4", "Cx3cr1","F2r","F2rl1","F2rl2","F2rl3"];
targetgenesOthers1=cellstr(targetgenesOthers1);
targetgenesOthers2 =["Lpar1", "Lpar2", "Lpar3", "Lpar4", "Lpar5", "Lpar6", "S1pr1","S1pr2","S1pr3","S1pr4","S1pr5","Ffar1","Ffar2","Ffar3","Ffar4","Ptafr","Ptgdr","Ptgfr","Ptgir","Gpr119","Gpr132","Gpr55","Gpr183","Gpr34","Gpr84","Tbxa2r","Gpr35","Ltb4r","Ltb4r2","Cysltr1","Cysltr2","Ptger1","Ptger2","Ptger3","Ptger4"];
targetgenesOthers2=cellstr(targetgenesOthers2);
targetgenesG=["Gnai1","Gnai2","Gnai3","Gnao1","Gnaz","Gnaq","Gnal","Gnas","Gna11","Gna14","Gna15","Gna12","Gna13","Gnb1","Gnb2","Gnb3","Gnb4","Gnb5","Gng1","Gng2","Gng3","Gng4","Gng5","Gng6","Gng7","Gng8","Gng9","Gng10","Gng11","Gng12","Gng13"];
targetgenesG=cellstr(targetgenesG);


gene_labels{1} = 'marker genes';  % your row labels
gene_labels{2} = 'G proteins';
gene_labels{3} = 'Monoamines';
gene_labels{4} = 'Glut,GABA,ACh';
gene_labels{5} = 'Non-classical NTs, others';
gene_labels{6} = 'Lipid signaling';
gene_labels{7} = 'Neuropeptides';
gene_labels{8} = 'Neuropeptides';
gene_labels{9} = 'Neuropeptides';


for PlotNo=1:9;
    if PlotNo==1
        target_genes=Marker_genes;
    elseif PlotNo==2
            target_genes=targetgenesG;
    elseif PlotNo==3
        target_genes=[targetgenesNA,targetgenesHT];
        elseif PlotNo==4
        target_genes=targetgenesGlu;
        elseif PlotNo==5
        target_genes=[targetgenesAdo,targetgenesOthers1];
        elseif PlotNo==6
        target_genes=targetgenesOthers2;
        elseif PlotNo==7
        target_genes=targetgenesNP1;
           elseif PlotNo==8
        target_genes=targetgenesNP2;
           elseif PlotNo==9
        target_genes=targetgenesNP3;

    end
    
% Find the indices of these genes
idx=[];
excludegene=[];
for i=1:length(target_genes)
    if length(find(strcmp(gene_names,target_genes(i))))==1
        idx = [idx,find(strcmp(gene_names,target_genes(i)))];
    else
        excludegene=[excludegene,i];

     warning('Some genes not found or empty: %s', strjoin(target_genes(i), ', '));
    end
end

% Extract expression rows for these genes
expr_subset = expr_vals(idx, :);  % rows = genes, columns = cells
if AveragePlot==2
if PlotNo==1
    [~, sort_idx] = sort(expr_subset(1, :), 'descend');  % highest expression first
    CellTypeLabels=CellTypeLabels(sort_idx);
end
end

target_genes(excludegene)=[];

if AveragePlot==1
   expr_sorted=mean(expr_subset,2);
elseif AveragePlot==3
    expr_sortedNew=[];
    for i=1:length(CellTypeLabels)
        sort_idx=find(strcmp(sampleIDs,CellTypeLabels(i)));
        expr_sortedNew(:,i)=mean(expr_subset(:,sort_idx),2);
    end
    expr_sorted=expr_sortedNew;
 else
        if PlotNo==1
            [~, sort_idx] = sort(expr_subset(1, :), 'descend');  % highest expression first
        end
expr_sorted = expr_subset(:, sort_idx);
end
%expr_sorted = expr_subset;

if AveragePlot==1
subplot(1,10,PlotNo)
elseif size(expr_vals,2)<5
subplot(1,10,PlotNo)
else
subplot(3,3,PlotNo)
end
if PlotNo<length(gene_labels)
heatmap(expr_sorted, ...
    'Colormap', turbo, ...
       'ColorbarVisible', 'off', ...
        'GridVisible', 'off', ...  %turn off cell borders
        'YDisplayLabels', target_genes,'XDisplayLabels',CellTypeLabels,  'CellLabelColor', 'none', 'ColorLimits', [0 max(expr_vals(:))]);   % example limits);       % hide numbers);
else
    heatmap(expr_sorted, ...
    'Colormap', turbo, ...
       'ColorbarVisible', 'on', ...
        'GridVisible', 'off', ...  %turn off cell borders
        'YDisplayLabels', target_genes,'XDisplayLabels',CellTypeLabels,  'CellLabelColor', 'none', 'ColorLimits', [0 max(expr_vals(:))]);   % example limits);       % hide numbers);

end

title(gene_labels(PlotNo)');
% xlabel('Cells');
% ylabel('Genes');
save(strcat(saveFolder,'\GPCR_expr_vals_',string(PlotNo)),'expr_sorted','target_genes')
end
cd(saveFolder)
saveas(gcf,'heatplot_AllGPCRs.png');
print('-depsc','-painters','heatplot_AllGPCRs')
cd(dataFolder)
target_genes=Marker_genes;

%% figure 5
% plot ionotropic receptors
if AveragePlot==1
figure('Position', [100 100 120 700])
elseif size(expr_vals,2)<5
    figure('Position', [100 100 200 700])
else
    figure('Position', [100 100 600 1200])
end
% List of genes of interest

gene_labels=[];

targetgenesIono = ["Gabra1", "Gabra2", "Gabra3", "Gabra4", "Gabra5","Gabrb1", "Gabrb2", "Gabrb3","Gabrg1", "Gabrg2", "Gabrg3","Gabrd", "Gabre", "Gabrf","Gabrr1", "Gabrr2", "Gabrr3","Gria1", "Gria2", "Gria3", "Gria4","Grin1", "Grin2a", "Grin2b", "Grin2c", "Grin2d", "Grin3a", "Grin3b","Grik1", "Grik2", "Grik3", "Grik4", "Grik5","Glra1", "Glra2", "Glra3", "Glra4", "Glrb","Htr3a", "Htr3b","Chrna2","Chrna3","Chrna4","Chrna5","Chrna6","Chrna7","Chrna9","Chrna10","Chrnb2","Chrnb3","Chrnb4","P2rx1", "P2rx2", "P2rx3", "P2rx4", "P2rx5", "P2rx6", "P2rx7"];

gene_labels{1} = 'ionotropic';  % your row labels



target_genes=targetgenesIono;
    
% Find the indices of these genes
idx=[];
excludegene=[];
for i=1:length(target_genes)
    if length(find(strcmp(gene_names,target_genes(i))))==1
        idx = [idx,find(strcmp(gene_names,target_genes(i)))];
    else
        excludegene=[excludegene,i];

     warning('Some genes not found or empty: %s', strjoin(target_genes(i), ', '));
    end
end

% Extract expression rows for these genes
expr_subset = expr_vals(idx, :);  % rows = genes, columns = cells
if AveragePlot==1
else
end

target_genes(excludegene)=[];

if AveragePlot==1
   expr_sorted=mean(expr_subset,2);
elseif AveragePlot==3
    expr_sortedNew=[];
    for i=1:length(CellTypeLabels)
        sort_idx=find(strcmp(sampleIDs,CellTypeLabels(i)));
        expr_sortedNew(:,i)=mean(expr_subset(:,sort_idx),2);
    end
    expr_sorted=expr_sortedNew;
 else
        if PlotNo==1
            [~, sort_idx] = sort(expr_subset(1, :), 'descend');  % highest expression first
        end
expr_sorted = expr_subset(:, sort_idx);
end
%expr_sorted = expr_subset;


subplot(1,1,1)
    heatmap(expr_sorted, ...
    'Colormap', turbo, ...
       'ColorbarVisible', 'on', ...
        'GridVisible', 'off', ...  %turn off cell borders
        'YDisplayLabels', target_genes,'XDisplayLabels',CellTypeLabels,  'CellLabelColor', 'none', 'ColorLimits', [0 max(expr_vals(:))]);   % example limits);       % hide numbers);


title(gene_labels(1)');
cd(saveFolder)
save('Iono_expr_vals','expr_sorted','target_genes')

saveas(gcf,'heatplot_AllIonos.png');
print('-depsc','-painters','heatplot_AllIonos')

target_genes=Marker_genes;
cd(dataFolder)
%% figure 5
% plot ionotropic receptors
if AveragePlot==1
figure('Position', [100 100 120 700])
elseif size(expr_vals,2)<5
    figure('Position', [100 100 200 700])
else
    figure('Position', [100 100 600 1200])
end
% List of genes of interest

gene_labels=[];

targetgenesCaV = ["Cacna1c","Cacna1d","Cacna1s","Cacna1f","Cacna1a","Cacna1b","Cacna1e","Cacna1g","Cacna1h","Cacna1i"];

gene_labels{1} = 'CaV';  % your row labels



target_genes=targetgenesCaV;
    
% Find the indices of these genes
idx=[];
excludegene=[];
for i=1:length(target_genes)
    if length(find(strcmp(gene_names,target_genes(i))))==1
        idx = [idx,find(strcmp(gene_names,target_genes(i)))];
    else
        excludegene=[excludegene,i];

     warning('Some genes not found or empty: %s', strjoin(target_genes(i), ', '));
    end
end

% Extract expression rows for these genes
expr_subset = expr_vals(idx, :);  % rows = genes, columns = cells
if AveragePlot==1
else
end

target_genes(excludegene)=[];

if AveragePlot==1
   expr_sorted=mean(expr_subset,2);
elseif AveragePlot==3
    expr_sortedNew=[];
    for i=1:length(CellTypeLabels)
        sort_idx=find(strcmp(sampleIDs,CellTypeLabels(i)));
        expr_sortedNew(:,i)=mean(expr_subset(:,sort_idx),2);
    end
    expr_sorted=expr_sortedNew;
 else
        if PlotNo==1
            [~, sort_idx] = sort(expr_subset(1, :), 'descend');  % highest expression first
        end
expr_sorted = expr_subset(:, sort_idx);
end
%expr_sorted = expr_subset;


subplot(1,1,1)
    heatmap(expr_sorted, ...
    'Colormap', turbo, ...
       'ColorbarVisible', 'on', ...
        'GridVisible', 'off', ...  %turn off cell borders
        'YDisplayLabels', target_genes,'XDisplayLabels',CellTypeLabels,  'CellLabelColor', 'none', 'ColorLimits', [0 max(expr_vals(:))]);   % example limits);       % hide numbers);


title(gene_labels(1)');
cd(saveFolder)
save('CaV_expr_vals','expr_sorted','target_genes')

saveas(gcf,'heatplot_AllCaV.png');
print('-depsc','-painters','heatplot_AllCaV')

target_genes=Marker_genes;
%% Callback function for the button
    function create_struct_callback()
    global editBoxes
    global fig
    global S
        % Create structure with empty cell arrays
        S = [];
           for idx = 1:24
            val = editBoxes(idx).Value;
            
            if isempty(val)
                S{idx} = 'NaN';
            else
                disp(val)
            S{idx} = editBoxes(idx).Value;
            end
            
        end
        close(fig)

    end


    function create_struct_callback2()
    global editBoxes
    global fig
    global target_genes

    load('TypicalMarkers.mat')
    target_genes=TypicalMarkers;

    y = 900;
    for i = 1:min(8,length(target_genes))
        editBoxes(i) = uieditfield(fig, 'text', 'Value', target_genes{i},'Position', [50 y 300 25],'BackgroundColor',[1 0.5 0.5]);
        y = y - 35;
    end
    y=y-25;
    for i = 9:length(target_genes)
        editBoxes(i) = uieditfield(fig, 'text', 'Value', target_genes{i},'Position', [50 y 300 25],'BackgroundColor',[0.9 0.9 0.9]);
        y = y - 35;
    end
    end


    %to reuse old gene selection
    function reuse_old_data()
    global editBoxes
    global fig
    global target_genes

    y = 900;
    for i = 1:min(8,length(target_genes))
        editBoxes(i) = uieditfield(fig, 'text', 'Value', target_genes{i},'Position', [50 y 300 25],'BackgroundColor',[1 0.5 0.5]);
        y = y - 35;
    end
    y=y-25;
    for i = 9:length(target_genes)
        editBoxes(i) = uieditfield(fig, 'text', 'Value', target_genes{i},'Position', [50 y 300 25],'BackgroundColor',[0.9 0.9 0.9]);
        y = y - 35;
    end
    end



% clear gene names
    function clear_callback()
    global editBoxes
    global fig
    global target_genes

    y = 900;
    for i = 1:24
        editBoxes(i) = uieditfield(fig, 'text', 'Value', [],'Position', [50 y 300 25],'BackgroundColor',[1 0.5 0.5]);
        y = y - 35;
    end
    y=y-25;
    for i = 9:length(target_genes)
        editBoxes(i) = uieditfield(fig, 'text', 'Value', [],'Position', [50 y 300 25],'BackgroundColor',[0.9 0.9 0.9]);
        y = y - 35;
    end
    end