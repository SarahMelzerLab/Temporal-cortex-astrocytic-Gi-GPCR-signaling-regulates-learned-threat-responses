%% 
global i
global c
global hFig
global xdata
global ydata
global threshold
global frame
global roilist2

global nROI
global lengthvideo
global k
global filename
global scale
global scale2
global frame1
global frame2
global rect_I
global scaleM
global frameM
global hAxis2
global hAxis1


close all
[filename,directory]=uigetfile('*.*', 'Select any file');%select video to be analyzed
cd(directory)
framerate=4;
% movementcorrection=1;
movementcorrection=input('type 1 if movementcorrection needed; 0 if not')
uncaging=input('type 1 if this is an uncaging experiment, 0 if not')
if uncaging==1
    Sensor=input('1=GRAB sensor, 2=GCaMPwithOT, 3=gCarvi')
    else Sensor=0
end


lengthvideo=numel(imfinfo(filename));
a=imfinfo(filename);
x=a.Height;
y=a.Width;
hM4D=0;
hM4D=input('type 1 if this is an hM4D test with caddis')

frame1 = imread(filename,'Index',101);
scale=65535/double(max(frame1(:)));
frame2 = imread(filename,'Index',lengthvideo-100);
scale2=65535/double(max(frame2(:)));
%imshow(frame1*scale);
bleachingcorrection=1;
filename_short=filename(1:length(filename)-24)

frameM = imread(filename,'Index',10);
scaleM=65535/double(max(frameM(:)));


% only for astrocytes make max intensity projection
astrocytes=input('Are these astrocytes? 1=yes; 0=no')
if astrocytes==1;
    frameMax=imread(filename,'Index',1199);
    for iFrames=1200:1500
        frameMax(:,:,iFrames-1) = imread(filename,'Index',iFrames);
    end
frame1=max(frameMax,[],3);
scale=65535/double(max(frame1(:)));
imshow(frame1*scale)
end
 
%% select ROIs
close all
nROI=1;
roilist=[];
if movementcorrection==1
    frame=uint16(zeros(x*2,y*2));
    frame(((x/2)+1):(1.5*x),((0.5*y)+1):(1.5*y))=frameM;
else
    frame=uint16(zeros(x,y));
    frame((1:x),(1:y))=frameM;
end
[xdata,ydata]=size(frame);
i=double(1);
    
% Create new figure
hFig = figure('position',[100 178 960 768],...
               'HandleVisibility','callback'); % hide the handle to prevent unintended modifications of our custom UI

% Create panel for figure
hPanel = uipanel('parent',hFig,'Position',[0.01 0.01 0.8 0.9],'Units','Normalized');%define how much of figure should be covered with video

% Create axis for figure
hAxis = axes('position',[0 0 1 1],'Parent',hPanel);%1 for whole image, 2 for half of it
hAxis.XTick = [];
hAxis.YTick = [];
hAxis.XColor = [1 1 1];
hAxis.YColor = [1 1 1];
     
% Exit button with text Exit
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit and Continue',...
                'BackgroundColor',[0.2 1 1],'position',[780 10 150 25],'callback', ...
                {@exitCallback,hFig});

% Add ROI button
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Add ROI',...
                'BackgroundColor',[1 1 0.2],'position',[830 400 100 25],'callback', ...
                {@addCallback,hFig});    
% Save ROI button
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Save ROI',...
                'BackgroundColor',[0.4 0.4 1],'position',[830 300 100 25],'callback', ...
                {@saveCallback,hFig});    

% Delete ROI button
uicontrol(hFig,'unit','pixel','style','pushbutton','string','Delete last ROI',...
                'BackgroundColor',[1 0.2 0.2],'position',[830 200 100 25],'callback', ...
                {@deleteCallback,hFig});    
            
% add title     
uicontrol(hFig,'unit','pixel','style','text','string','Select ROIs by pressing Add ROI and save ROI; end with 1 background ROI',...
                'position',[200 730 400 20],'BackgroundColor',[1 1 1]);

% Initialize the display with the first frame to be tracked of the video
imshow(frame*scaleM,'Parent', hAxis)

%% define an area for movement tracking
waitfor(hFig)
frame1 = imread(filename,'Index',101);
scale=65535/double(max(frame1(:)));
if movementcorrection==1
    waitfor(hFig);
    hFig=figure('Position',[600,100,3*y,(3*x)+200]); hold on
        % Create panel for figure
        hPanel = uipanel('parent',hFig,'Position',[0 0 1 1],'Units','Normalized');
    % Create axis for figure
    hAxis = axes('position',[0 0 1 1],'Parent',hPanel);%1 for whole image, 2 for half of it
    hAxis.XTick = [];
    hAxis.YTick = [];
    hAxis.XColor = [1 1 1];
    hAxis.YColor = [1 1 1];
    k=1;
    % Create title
    uicontrol(hFig,'unit','pixel','style','text','string','select area with one cell that stays quite stable; right click --> crop image --> exit',...
            'position',[100 (3*x)+150 3*y-50 20],'BackgroundColor',[1 1 1]);

    % Exit button with text Exit
    uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit and Continue',...
                    'BackgroundColor',[1 0.2 0.2],'position',[850 10 150 25],'callback', ...
                    {@exitCallback,hFig});

    %switch between first and last frame
    uicontrol(hFig,'unit','pixel','style','pushbutton','string','switch between first and last',...
                    'BackgroundColor',[0.4 0.9 0.9],'position',[200 10 200 25],'callback', ...
                    {@testAreaCallback,hAxis});
   
    %initiate area selection tool
    uicontrol(hFig,'unit','pixel','style','pushbutton','string','create selection tool',...
                    'BackgroundColor',[0.5 0.9 0.5],'position',[550 10 200 25],'callback', ...
                    {@selectAreaCallback,hAxis});
    
    % draw first frame of video
    imshow(frame1*scale,'Parent',hAxis)
% 
     % generate cropping tool
     [~,rect_I]=imcrop;
    
    waitfor(hFig);
    rect_I=round(rect_I);
    frame1 = imread(filename,'Index',lengthvideo-100);
    frame2 = imread(filename,'Index',101);
    frameCrop=frame1(rect_I(2):(rect_I(2))+rect_I(4),rect_I(1):(rect_I(1)+rect_I(3)));
    frame2=frame2(rect_I(2):(rect_I(2))+rect_I(4),rect_I(1):(rect_I(1)+rect_I(3)));
end

%% define size of cell using thresholding

if movementcorrection==1
    frame=(frameCrop);
    [xdata,ydata]=size(frame);
    threshold=((double(mean(mean(frame)))/65535));
    biggest = bwareafilt(im2bw(frame,threshold),[1,10000]);[yT,xT]=ind2sub([xdata,ydata],find(biggest));
    location=[mean(xT),mean(yT)]; %location corresponds to centroid of cell
    frameT=frame;
    frameT2=frame2;
    for j=1:length(xT)   
        frameT(yT(j),xT(j))=65535;
    end

    A=flip(sort(reshape(frame2,[(rect_I(4)+1)*(rect_I(3)+1),1])));
    B=(double(A(length(xT)))+double(A(length(xT)+1)))/2;thresholdStart=B/65535;
    biggest = bwareafilt(im2bw(frame2,thresholdStart),[1,10000]);[yT,xT]=ind2sub([xdata,ydata],find(biggest));
    location=[mean(xT),mean(yT)]; %location corresponds to centroid of mouse
    for j=1:length(xT)   
        frameT2(yT(j),xT(j))=65535;
    end
   
    i=double(1);
    
            % Create new figure
            hFig = figure('position',[100 178 1460 568],...
                   'HandleVisibility','callback'); % hide the handle to prevent unintended modifications of our custom UI
    
    %         Create panel for figure
            hPanel1 = uipanel('parent',hFig,'Position',[0.02 0.18 0.4 0.4],'Units','Normalized');%define how much of figure should be covered with video
    hPanel2 = uipanel('parent',hFig,'Position',[0.52 0.18 0.4 0.4],'Units','Normalized');%define how much of figure should be covered with video

    %         Create axis for figure
            hAxis1 = axes('position',[0 0 1 1],'Parent',hPanel1);%1 for whole image, 2 for half of it
            hAxis2 = axes('position',[0 0 1 1],'Parent',hPanel2);%1 for whole image, 2 for half of it

            hAxis1.XTick = [];
            hAxis1.YTick = [];
            hAxis1.XColor = [1 1 1];
            hAxis1.YColor = [1 1 1];
            hAxis2.XTick = [];
            hAxis2.YTick = [];
            hAxis2.XColor = [1 1 1];
            hAxis2.YColor = [1 1 1];
            
         
      % Exit button with text Exit
            uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                    'BackgroundColor',[1 0.2 0.2],'position',[830 10 50 25],'callback', ...
                    {@exitCallback,hFig});
                
                
       %slider     
             c = uicontrol(hFig,'Style','slider','SliderStep',[0.0001 0.1],...
                 'BackgroundColor',[0.7 1 0.7],'Position',[10 50 850 20],'string','adjust threshold','callback', ...
                    {@SliderCallback2,hAxis});
             c.Value = threshold;
             
        %add title     
             uicontrol(hFig,'unit','pixel','style','text','string','Move slider to adjust threshold; both shapes should look similar',...
                    'position',[100 730 400 20],'BackgroundColor',[1 1 1]);
    
    % Initialize the display with the first frame to be tracked of the video
     imshow(frameT*scale2,'Parent', hAxis1);hold on
     imshow(frameT2*scale,'Parent', hAxis2);hold on
end

 %% track selected cell automatically to determine how much it moves
 if movementcorrection==1
     waitfor(hFig);
    biggest = bwareafilt(im2bw(frameCrop,threshold),[1,10000]);[yO,xO]=ind2sub([xdata,ydata],find(biggest));
    location=[mean(xO),mean(yO)]; %location corresponds to centroid cell
    celllocation=zeros(lengthvideo-100,2);

    pause on

    for i =1:lengthvideo-100;    
        frame=imread(filename,'Index',i+100);
        reshapeCrop=(frame(rect_I(2):(rect_I(2))+rect_I(4),rect_I(1):(rect_I(1)+rect_I(3))));
        A=flip(sort(reshape(reshapeCrop,[(rect_I(4)+1)*(rect_I(3)+1),1])));
        B=(double(A(length(xO)))+double(A(length(xO)+1)))/2;threshold=B/65535;
        biggest = bwareafilt(im2bw(reshapeCrop,threshold),[1,10000]);[yT,xT]=ind2sub([xdata,ydata],find(biggest));
        location=[mean(xT),mean(yT)]; %location corresponds to centroid cell
        celllocation(i,:)=location;
    
        if mod(i,50)==0;
            disp('tracking cell')
            i
            imshow(reshapeCrop*3);
            hold on
            plot(location(1),location(2),'r.')
            pause(1)
            
        end
    end
    celllocation(2:end,:)=celllocation(2:end,:)-celllocation(1,:);
    celllocation(1,:)=[0,0];
    celllocationmean=movmean(celllocation,8);
    celllocationmean3=fit([1:length(celllocation(:,1))]',celllocation(:,1),'exp1');
    celllocationmean4=fit([1:length(celllocation(:,2))]',celllocation(:,2),'exp1');
    celllocationmean2=movmean(celllocationmean,12);
    celllocationmean2=movmean(celllocationmean2,12);
    celllocationmean2=movmean(celllocationmean2,12);
    celllocationmean2=movmean(celllocationmean2,12);
    celllocationmean2=round(celllocationmean2);
    celllocationmean=round(celllocationmean);
    celllocationmean3=round(celllocationmean3(1:length(celllocation)));
    celllocationmean4=round(celllocationmean4(1:length(celllocation)));
    celllocationmean3=[celllocationmean3,celllocationmean4];
    celllocationmean2(1,:)=[0,0];
    celllocationmean(1,:)=[0,0];
    celllocationmean3(1,:)=[0,0];
    celllocation=round(celllocation);
    save(strcat(filename_short,'_movementcorrection'),'filename_short','filename','a','directory','lengthvideo','x','y','celllocationmean3','celllocation','celllocationmean','celllocationmean2','xO','yO')
    celllocationmean=celllocationmean3;

 end

%% correct movement by making videos
if movementcorrection==1  
    a=imfinfo(filename);
    x=a.Height;
    y=a.Width;
    close all
    outputFileName1=[filename_short,'_1.tif'];
    outputFileName2=[filename_short,'_2.tif'];
    outputFileName3=[filename_short,'_3.tif'];  
    outputFileName4=[filename_short,'_4.tif'];
    outputFileName5=[filename_short,'_5.tif'];
    outputFileName6=[filename_short,'_6.tif'];
    outputFileName7=[filename_short,'_7.tif'];
    outputFileName8=[filename_short,'_8.tif'];
    outputFileName9=[filename_short,'_9.tif'];
    outputFileName10=[filename_short,'_10.tif'];
    outputFileName11=[filename_short,'_11.tif'];
    outputFileName12=[filename_short,'_12.tif'];

    delete(outputFileName1)
    delete(outputFileName2)
    delete(outputFileName3)
    delete(outputFileName4)
    delete(outputFileName5)
    delete(outputFileName6)
    delete(outputFileName7)
    delete(outputFileName8)
    delete(outputFileName9)
    delete(outputFileName10)
    delete(outputFileName11)
    delete(outputFileName12)
    

     
    for i =1:1200;    
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName1,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    
    for i =1201:2400;
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName2,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    for i =2401:3600;
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName3,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end

    for i =3601:min(4800, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName4,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    if lengthvideo>4900
    for i =4801:min(6000, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName5,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>6100
    for i =6001:min(7200, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName6,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>7300
    for i =7201:min(8400, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName7,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>8500
    for i =8401:min(9600, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName8,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>9700
    for i =9601:min(10800, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName9,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>10900
    for i =10801:min(12000, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName10,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>12100
    for i =12001:min(13200, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName11,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
    if lengthvideo>13300
    for i =13201:min(14400, lengthvideo-100);
        frame=imread(filename,'Index',i+100);
        reshapeShift=uint16(zeros(x*2,y*2));
        reshapeShift(((x/2)-celllocationmean(i,2)+1):((1.5*x)-celllocationmean(i,2)),((0.5*y)-celllocationmean(i,1)+1):((1.5*y)-celllocationmean(i,1)))=frame;
        imwrite(reshapeShift,outputFileName12,'WriteMode','append','Compression','none');
        if mod(i,100)==0;
            disp('saving movie')
            i
        end
    end
    end
 
    save(strcat(filename_short,'_movementcorrection'),'filename_short','filename','a','directory','lengthvideo','x','y','celllocationmean3','celllocation','celllocationmean','celllocationmean2','xO','yO','outputFileName1','outputFileName2','outputFileName3','outputFileName4','outputFileName5','outputFileName6','outputFileName7','outputFileName8','outputFileName9','outputFileName10','outputFileName11','outputFileName12')
disp('movement correction completed')

end
save(strcat(filename_short,'_movementcorrection'),'filename_short','filename','directory','lengthvideo','x','y')


%% measure ROIs
nROI=dir('roilist*');
nROI=size(nROI); nROI=nROI(1);
intensity1=zeros(1200,nROI);
intensity2=zeros(1200,nROI);
intensity3=zeros(1200,nROI);
intensity4=zeros(min(1200,lengthvideo-3700),nROI);
if lengthvideo>4900
intensity5=zeros(min(1200,lengthvideo-4900),nROI);
end
if lengthvideo>6100
intensity6=zeros(min(1200,lengthvideo-6100),nROI);
end
if lengthvideo>7300
intensity7=zeros(min(1200,lengthvideo-7300),nROI);
end
if lengthvideo>8500
intensity8=zeros(min(1200,lengthvideo-8500),nROI);
end
if lengthvideo>9700
intensity9=zeros(min(1200,lengthvideo-9700),nROI);
end
if lengthvideo>10900
intensity10=zeros(min(1200,lengthvideo-10900),nROI);
end
if lengthvideo>12100
intensity11=zeros(min(1200,lengthvideo-12100),nROI);
end
if lengthvideo>13300
intensity12=zeros(min(1200,lengthvideo-13300),nROI);
end

close all

for i=1:1200
    if movementcorrection==1
        frame=imread(outputFileName1,'Index',i);
    else
        frame=imread(filename,'Index',i+100);
    end
    imshow(frame)
    if mod(i,100)==0
        disp('measuring ROI')
        i
    end
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity1(i,j)=sum(intensity(:))/sum(a(:));
    end
end

for i=1:1200
    if movementcorrection==1
        frame=imread(outputFileName2,'Index',i);
    else
        frame=imread(filename,'Index',i+1200+100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+1200
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity2(i,j)=sum(intensity(:))/sum(a(:));
    end
end

for i=1:1200
    if movementcorrection==1
        frame=imread(outputFileName3,'Index',i);
    else
        frame=imread(filename,'Index',i+2400+100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+2400
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity3(i,j)=sum(intensity(:))/sum(a(:));
    end
end
 
 for i=1:min(1200,(lengthvideo-3600-100))
    if movementcorrection==1
        frame=imread(outputFileName4,'Index',i);
    else
        frame=imread(filename,'Index',i+3600+100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+3600
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity4(i,j)=sum(intensity(:))/sum(a(:));
    end
end

if lengthvideo>4900
 for i=1:min(1200,lengthvideo-4900)
    if movementcorrection==1
        frame=imread(outputFileName5,'Index',i);
    else
        frame=imread(filename,'Index',i+4800+100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+4800
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity5(i,j)=sum(intensity(:))/sum(a(:));
    end
 end
end

if lengthvideo>6100
for i=1:min(1200,lengthvideo-6100)
    if movementcorrection==1
        frame=imread(outputFileName6,'Index',i);
    else
        frame=imread(filename,'Index',i+6000+100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+6000
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity6(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>7300
for i=1:min(1200,lengthvideo-7300)
    if movementcorrection==1
        frame=imread(outputFileName7,'Index',i);
    else
        frame=imread(filename,'Index',i+7300);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+7200
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity7(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>8500
for i=1:min(1200,lengthvideo-8500)
    if movementcorrection==1
        frame=imread(outputFileName8,'Index',i);
    else
        frame=imread(filename,'Index',i+8500);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+8400
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity8(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>9700
for i=1:min(1200,lengthvideo-9700)
    if movementcorrection==1
        frame=imread(outputFileName9,'Index',i);
    else
        frame=imread(filename,'Index',i+9700);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+9600
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity9(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>10900
for i=1:min(1200,lengthvideo-10900)
    if movementcorrection==1
        frame=imread(outputFileName10,'Index',i);
    else
        frame=imread(filename,'Index',i+10900);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+10800
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity10(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>12100
for i=1:min(1200,lengthvideo-12100)
    if movementcorrection==1
        frame=imread(outputFileName11,'Index',i);
    else
        frame=imread(filename,'Index',i+12100);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+12000
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity11(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

if lengthvideo>13300
for i=1:min(1200,lengthvideo-13300)
    if movementcorrection==1
        frame=imread(outputFileName12,'Index',i);
    else
        frame=imread(filename,'Index',i+13300);
    end
    if mod(i,100)==0
        disp('measuring ROI')
        i+13200
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensity12(i,j)=sum(intensity(:))/sum(a(:));
    end
end
end

intensitymBeRFP=zeros(10,nROI);
for i=1:10
    if movementcorrection==1
        frame1 = imread(filename,'Index',1);
        frame=uint16(zeros(x*2,y*2));
        frame(((x/2)+1):(1.5*x),((0.5*y)+1):(1.5*y))=frame1;
    else
        frame=imread(filename,'Index',i);
    end
    imshow(frame)
    for j=1:nROI
        load(strcat('roilist_',string(j),'.mat'));
        roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=createMask(roilist); % <- get roi mask
        intensity=uint16(a).*frame;
        intensitymBeRFP(i,j)=sum(intensity(:))/sum(a(:));
    end
end
intensitymBeRFPoriginal=mean(intensitymBeRFP);

if movementcorrection==1
    save(strcat(filename_short,'_movementcorrection'),'filename_short','filename','a','directory','lengthvideo','x','y','celllocationmean3','celllocation','celllocationmean','celllocationmean2','xO','yO','outputFileName1','outputFileName2','outputFileName3','outputFileName4','outputFileName5','outputFileName6','outputFileName7','outputFileName8','outputFileName9','outputFileName10','outputFileName11','outputFileName12','nROI')
else
    save(strcat(filename_short,'_movementcorrection'),'filename_short','filename','a','directory','lengthvideo','x','y','nROI')
end



%% concatenate intensity values from both videos

if lengthvideo>13300
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5;intensity6;intensity7;intensity8;intensity9;intensity10;intensity11;intensity12];
elseif lengthvideo>12100
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5;intensity6;intensity7;intensity8;intensity9;intensity10;intensity11];
elseif lengthvideo>8500
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5;intensity6;intensity7;intensity8];
elseif lengthvideo>7300
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5;intensity6;intensity7];
elseif lengthvideo>6100
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5;intensity6];
elseif lengthvideo>4900
intensity=[intensity1;intensity2;intensity3;intensity4;intensity5];
else
    intensity=[intensity1;intensity2;intensity3;intensity4];
end
%% invert if caddis with hm4d
if hM4D==1
intensity=intensity*-1;
for i=1:length(intensity(1,:));
    intensity(:,i)=intensity(:,i)+(intensity(1,i)*-2);
end
end

save(strcat(filename_short,'_Analysis'),'lengthvideo','intensity','intensitymBeRFP','nROI','bleachingcorrection','scale','movementcorrection','framerate','intensitymBeRFPoriginal','uncaging','Sensor','astrocytes');

%% Smoothen traces
intensitysmooth = movmean(intensity, 5);
nROI = size(intensity, 2);

% Bleaching correction
bleachingcorrection = 1;

if uncaging==1
    % First attempt: use first 4 minutes (e.g., frames 1–960 at 4 Hz)
    if Sensor==1
        time = [1:10:620];
    else
         time = [1:10:700,5620];
%         time = [1:10:700];
    end
        normintensitysmooth = intensitysmooth;
        for i = 1:nROI
            normintensitysmooth(:, i) = normintensitysmooth(:, i) / mean(normintensitysmooth(1:500, i));
        end
        
        if nROI>3
            meanNormIntensity=mean(normintensitysmooth(time, 1:nROI-1)');
            meanNormIntensity2=mean(normintensitysmooth(:,1:nROI-1),2);
        else
            meanNormIntensity=normintensitysmooth(time, 1)';
            meanNormIntensity2=normintensitysmooth(:, 1)';
        end

        % Fit exponential decay (first 4 min)
        filtSig1fit = fit(time', meanNormIntensity', 'exp1');
        
        % Plot first fit
        figure;
        subplot(1,3,1);hold on
        plot(meanNormIntensity2', 'DisplayName', 'Normalized Intensity');
        hold on;
        plot(filtSig1fit(1:length(normintensitysmooth)), 'DisplayName', 'Fit (First 3 min)');
        legend;
        title('Initial Bleaching Correction, exp1');
        
        filtSig1fit = fit(time', meanNormIntensity', 'exp2');
        subplot(1,3,2);hold on
        plot(meanNormIntensity2', 'DisplayName', 'Normalized Intensity');
        hold on;
        plot(filtSig1fit(1:length(normintensitysmooth)), 'DisplayName', 'Fit (First 3 min)');
        legend;
        title('Initial Bleaching Correction, exp2');

        filtSig1fit = fit(time', meanNormIntensity', 'poly1');
        subplot(1,3,3);hold on
        plot(meanNormIntensity2', 'DisplayName', 'Normalized Intensity');
        hold on;
        plot(filtSig1fit(1:length(normintensitysmooth)), 'DisplayName', 'Fit (First 3 min)');
        legend;
        title('Initial Bleaching Correction, linear');
             
        pause(1);
        fitok = input('Is the bleaching correction fit OK? (1=Yes left one, 2=middle one, 3=right one, 4=None, continue without bleaching correction): ');
        if fitok==1
            filtSig1fit = fit(time', meanNormIntensity', 'exp1');
        elseif fitok==2
            filtSig1fit = fit(time', meanNormIntensity', 'exp2');
        end
        % Apply first correction
        intensitysmoothcorrected = normintensitysmooth;
        if fitok==4
        else
        for i = 1:nROI
            intensitysmoothcorrected(:, i) = normintensitysmooth(:, i) ./ filtSig1fit(1:length(intensitysmooth));
            intensitysmoothcorrected(:, i) = intensitysmoothcorrected(:, i) * mean(intensitysmooth(1:500, i));
        end
        end

else
% First attempt: use first 4 minutes (e.g., frames 1–960 at 4 Hz)
if Sensor==1
    endBaseline=860;
else
    endBaseline=960;
end

time = 1:10:endBaseline;
normintensitysmooth = intensitysmooth;
for i = 1:nROI
    normintensitysmooth(:, i) = normintensitysmooth(:, i) / mean(normintensitysmooth(1:endBaseline, i));
end

% Fit exponential decay (first 4 min)
filtSig1fit = fit(time', mean(normintensitysmooth(time, 1:nROI-1)')', 'exp1');

% Plot first fit
figure;
plot(mean(normintensitysmooth(:, 1:nROI-1)'), 'DisplayName', 'Normalized Intensity');
hold on;
plot(filtSig1fit(1:length(normintensitysmooth)), 'DisplayName', 'Fit (First 4 min)');
legend;
title('Initial Bleaching Correction (First 4 min)');

% Apply first correction
intensitysmoothcorrected = normintensitysmooth;
for i = 1:nROI
    intensitysmoothcorrected(:, i) = normintensitysmooth(:, i) ./ filtSig1fit(1:length(intensitysmooth));
    intensitysmoothcorrected(:, i) = intensitysmoothcorrected(:, i) * mean(intensitysmooth(1:endBaseline, i));
end

pause(1);
fitok = input('Is the bleaching correction fit OK? (1 = Yes, 2 = No): ');

% Second attempt: use last 3 minutes
if fitok == 2
    disp('Trying bleaching correction using the last 3 minutes of recording...');
    normintensitysmooth = intensitysmooth;
    for i = 1:nROI
        normintensitysmooth(:, i) = normintensitysmooth(:, i) / mean(normintensitysmooth(end-719:end, i));
    end

    time_last = (size(normintensitysmooth, 1) - 719):10:size(normintensitysmooth, 1);
    filtSig2fit = fit(time_last', mean(normintensitysmooth(time_last, 1:nROI-1)')', 'exp1');

    % Plot second fit
    figure;
    plot(mean(normintensitysmooth(:, 1:nROI-1)'), 'DisplayName', 'Normalized Intensity');
    hold on;
    plot(filtSig2fit(1:length(normintensitysmooth)), 'DisplayName', 'Fit (Last 3 min)');
    legend;
    title('Bleaching Correction – Last 3 Minutes');

    pause(1);
    fitok2 = input('Use bleaching correction based on last 3 minutes? (1 = Yes, 2 = No): ');

    if fitok2 == 1
        for i = 1:nROI
            intensitysmoothcorrected(:, i) = normintensitysmooth(:, i) ./ filtSig2fit(1:length(intensitysmooth));
            intensitysmoothcorrected(:, i) = intensitysmoothcorrected(:, i) * mean(intensitysmooth(end-719:end, i));
        end
    else
        % Third attempt: average of first and second fit
        disp('Trying average of first and second bleaching fits...');
        fitAvg = @(x) (filtSig1fit(x) + filtSig2fit(x)) / 2;

        % Plot average fit
        figure;
        plot(mean(normintensitysmooth(:, 1:nROI-1)'), 'DisplayName', 'Normalized Intensity');
        hold on;
        plot(arrayfun(fitAvg, 1:length(normintensitysmooth)), 'DisplayName', 'Average Fit');
        legend;
        title('Bleaching Correction – Averaged Fit');

        pause(1);
        fitok3 = input('Use average bleaching correction? (1 = Yes, 2 = No): ');

        if fitok3 == 1
            for i = 1:nROI
                intensitysmoothcorrected(:, i) = normintensitysmooth(:, i) ./ arrayfun(fitAvg, 1:length(intensitysmooth))';
                intensitysmoothcorrected(:, i) = intensitysmoothcorrected(:, i) * mean(intensitysmooth(:, i));
            end
        else
            % Final fallback: no bleaching correction
            disp('All fits were rejected.');
            useNoCorrection = input('Continue without bleaching correction? (1 = Yes, 0 = Terminate script): ');
            if useNoCorrection == 1
                intensitysmoothcorrected = intensitysmooth;
                bleachingcorrection = 0;
                disp('Bleaching correction skipped.');
            else
                error('Bleaching correction aborted by user. Script terminated.');
            end
        end
    end
end
end

% Background subtraction (last ROI)
disp('Background fluorescence (last ROI):');
disp(mean(intensity(101:820, end)));

backsub = input('Type 1 to use background ROI, 2 for fixed value (50ms), 3 for fixed value (25ms), 0 for no subtraction: ');

if backsub == 1
    for i = 1:nROI
        intensitysmoothcorrected(:, i) = intensitysmoothcorrected(:, i) - intensitysmoothcorrected(:, end);
    end
elseif backsub == 2
    intensitysmoothcorrected = intensitysmoothcorrected - 2600;
elseif backsub == 3
    intensitysmoothcorrected = intensitysmoothcorrected - 1300;
elseif backsub == 0
    % No background subtraction
end

%% correct 405nm LED
if uncaging==1
close all
figure
plot(intensitysmoothcorrected(:,1:nROI-1))
pause(1)
start_LED=zeros(8,1);
start_LED(1)=input('type time point for start of first LED (start of the ramp up)');
start_LED(2)=start_LED(1)+8;
start_LED(3)=input('type time point for end of first LED (start of the ramp down)');
start_LED(5)=input('type time point for start of 2nd LED (start of the ramp up)');
start_LED(6)=start_LED(5)+8;
start_LED(7)=input('type time point for end of 2nd LED (start of the ramp down)');
if Sensor==3
start_LED(4)=start_LED(3)+30;
start_LED(8)=start_LED(7)+30;
else
start_LED(4)=start_LED(3)+12;
start_LED(8)=start_LED(7)+12;
end

for i=1:nROI-1
    intensitysmoothcorrected(start_LED(2):start_LED(3),i)=intensitysmoothcorrected(start_LED(2):start_LED(3),i)-(intensitysmoothcorrected(start_LED(2),i)-intensitysmoothcorrected(start_LED(1),i));
    intensitysmoothcorrected(start_LED(6):start_LED(7),i)=intensitysmoothcorrected(start_LED(6):start_LED(7),i)-(intensitysmoothcorrected(start_LED(6),i)-intensitysmoothcorrected(start_LED(5),i));
    intensitysmoothcorrected(start_LED(1):start_LED(2),i)=intensitysmoothcorrected(start_LED(1),i);
    intensitysmoothcorrected(start_LED(3):start_LED(4),i)=intensitysmoothcorrected(start_LED(3),i);
    intensitysmoothcorrected(start_LED(5):start_LED(6),i)=intensitysmoothcorrected(start_LED(5),i);
    intensitysmoothcorrected(start_LED(7):start_LED(8),i)=intensitysmoothcorrected(start_LED(7),i);
end
end
plot(intensitysmoothcorrected(:,1:nROI-1))

%% delete cells with too low brightness relative to background
eliminate=[];
ChooseElimination=input('type 1 if you want to use normal elimination of cells based on Forskolin/KCl response, type 0 if not')
if ChooseElimination==1
    nROI=length(intensity(1,:));
    backgroundForsk=mean(intensity(lengthvideo-140:lengthvideo-100,nROI))
    Galphai=input('type 1 if you are activating Galpha i, type 0 if not')
    disp('eliminated because of too small Forskolin response:')
    for i=1:nROI-1
        if lengthvideo>4000
            DeltaForsk=(max(intensitysmoothcorrected(lengthvideo-2000:lengthvideo-100,i))-mean(intensitysmoothcorrected(1:(framerate*180),i)));
            if Galphai==0
                if DeltaForsk<2*std(intensitysmoothcorrected(1:(framerate*180),i))
                    eliminate=[eliminate,i]; 
                    i
                end
            end
        end
        if mean(intensitysmoothcorrected(lengthvideo-1000:lengthvideo-100,i))<0.5*backgroundForsk
            eliminate=[eliminate,i];
        end
    end
    disp('all eliminated cells:')
    eliminate
end

nROI=nROI-length(eliminate);
intensitysmoothcorrected(:,eliminate)=[];
if astrocytes==0
    if backsub==1
    intensitymBeRFP=intensitymBeRFPoriginal-intensitymBeRFPoriginal(end);
    elseif backsub==2
        intensitymBeRFP=intensitymBeRFPoriginal-3400;
    elseif backsub==3
        intensitymBeRFP=intensitymBeRFPoriginal-1700;
    elseif backsub==0
        intensitymBeRFP=intensitymBeRFPoriginal-0;%--> No subtraction of background ROI
    end
    intensitymBeRFP(eliminate)=[];
end
%% calculate DF/F as usual or as F being the final fluorescence during or relative to mBeRFP
%forskolin; use first 3 min as baseline to normalize

DeltaFF=zeros(lengthvideo-100,nROI-1);
DeltaFForsk=zeros(lengthvideo-100,nROI-1);
DeltaFmBeRFP=zeros(lengthvideo-100,nROI-1);

% if astrocytes==1
%     DeltaFF=zeros(lengthvideo,nROI-1);
% DeltaFForsk=zeros(lengthvideo,nROI-1);
% end
if Sensor==1

        for i=1:nROI-1;
        DeltaFF(:,i)=((intensitysmoothcorrected(:,i)-mean(intensitysmoothcorrected(1:550,i)))*1)/mean(intensitysmoothcorrected(1:550,i))*100;%
        end

else
for i=1:nROI-1;
        DeltaFF(:,i)=((intensitysmoothcorrected(:,i)-mean(intensitysmoothcorrected(1:(framerate*180),i)))*1)/mean(intensitysmoothcorrected(1:(framerate*180),i))*100;%
        DeltaFForsk(:,i)=((intensitysmoothcorrected(:,i)-mean(intensitysmoothcorrected(1:(framerate*180),i)))*1)/mean(max(intensitysmoothcorrected(lengthvideo-2000:lengthvideo-100,i)))*100;
        if astrocytes==0
        DeltaFmBeRFP(:,i)=((intensitysmoothcorrected(:,i)-mean(intensitysmoothcorrected(1:(framerate*180),i)))*1)/intensitymBeRFP(i)*100;%
        end
end
end

meanDeltaFF=mean(DeltaFF');
meanDeltaFForsk=mean(DeltaFForsk');
if astrocytes==0
    meanDeltaFmBeRFP=mean(DeltaFmBeRFP');
end

%% plot everything
close all
figure('position',[200,50,1400,750]);%distance from left, distance from bottom, width, height
xtickvector=1:(framerate*60*3):6500;


%Plot everything for DF/F in first row
subplot(3,5,1,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
plot(DeltaFF);
axis tight; title('Delta F/F');ylabel('Delta F/F [%]');xlabel('time [min]')

subplot(3,5,2,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
Xstd=std(DeltaFF')/sqrt(length(DeltaFF(1,:)));
for i=1:10:length(meanDeltaFF)-10
    errBoxY = [meanDeltaFF(i)-Xstd(i),meanDeltaFF(i)+Xstd(i), meanDeltaFF(i)+Xstd(i),meanDeltaFF(i)-Xstd(i)];
    errBoxX=[i,i,i+10,i+10];
    fill(errBoxX',errBoxY','k','FaceAlpha',0.3,'EdgeAlpha',0)
end
plot(meanDeltaFF,'k')
plot([720,1200],[0,0],'c-','LineWidth',2)
plot([3600,lengthvideo-100],[0,0],'y-','LineWidth',2)
title('mean Delta F/F (SEM) [%]'); axis tight;xlabel('time [min]')

subplot(3,5,3,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',[xtickvector])
hold on
imagesc(DeltaFF');
axis tight; title('Delta F/F'); xlabel('time [min]')

%Plot everything for DF/Forsk in second row
subplot(3,5,6,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
plot(DeltaFForsk);
axis tight; title('Delta F/Forskolin');ylabel('Delta F/Forsk [%]');xlabel('time [min]')

subplot(3,5,7,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
Xstd=std(DeltaFForsk')/sqrt(length(DeltaFForsk(1,:)));
for i=1:10:length(meanDeltaFForsk)-10
    errBoxY = [meanDeltaFForsk(i)-Xstd(i),meanDeltaFForsk(i)+Xstd(i), meanDeltaFForsk(i)+Xstd(i),meanDeltaFForsk(i)-Xstd(i)];
    errBoxX=[i,i,i+10,i+10];
    fill(errBoxX',errBoxY','k','FaceAlpha',0.3,'EdgeAlpha',0)
end
plot(meanDeltaFForsk,'k')
plot([720,1200],[0,0],'c-','LineWidth',2)
plot([3600,lengthvideo-100],[0,0],'y-','LineWidth',2)
title('mean Delta F/Forskolin (SEM) [%]'); axis tight;xlabel('time [min]')

subplot(3,5,8,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',[xtickvector])
hold on
imagesc(DeltaFForsk');
axis tight; title('Delta F/Forskolin'); xlabel('time [min]')

%plot everything for DeltaF/mBeRFP in 3rd row
if astrocytes==0
subplot(3,5,11,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
plot(DeltaFmBeRFP);
axis tight; title('Delta F/mBeRFP');ylabel('Delta F/F [%]');xlabel('time [min]')

subplot(3,5,12,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',xtickvector); hold on
Xstd=std(DeltaFmBeRFP')/sqrt(length(DeltaFmBeRFP(1,:)));
for i=1:10:length(meanDeltaFmBeRFP)-10
    errBoxY = [meanDeltaFmBeRFP(i)-Xstd(i),meanDeltaFmBeRFP(i)+Xstd(i), meanDeltaFmBeRFP(i)+Xstd(i),meanDeltaFmBeRFP(i)-Xstd(i)];
    errBoxX=[i,i,i+10,i+10];
    fill(errBoxX',errBoxY','k','FaceAlpha',0.3,'EdgeAlpha',0)
end
plot(meanDeltaFmBeRFP,'k')
plot([720,1200],[0,0],'c-','LineWidth',2)
plot([3600,lengthvideo-100],[0,0],'y-','LineWidth',2)
title('mean Delta F/mBeRFP (SEM) [%]'); axis tight;xlabel('time [min]')

subplot(3,5,13,'XTickLabel',{'0','3','6','9','12','15','18','21','24','27'},'XTick',[xtickvector])
hold on
imagesc(DeltaFmBeRFP');
axis tight; title('Delta F/mBeRFP'); xlabel('time [min]')
end

subplot(3,5,[4,5,9,10]); hold on
frame1 = imread(filename,'Index',1);
imshow(frame1*scale)
for j=1:nROI+length(eliminate)
    if any(eliminate==j)
        load(strcat('roilist_',string(j),'.mat'));
        %roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=round(roilist.Center(1));
        b=round(roilist.Center(2));
        if movementcorrection==1
            text(a-y/2,b-x/2,string(j),'Color','r')
        else
            text(a,b,string(j),'Color','r')
        end

    else
        load(strcat('roilist_',string(j),'.mat'));
        %roilist=drawellipse('Center',[roilist.Center],'SemiAxes',[roilist.SemiAxes],'RotationAngle',roilist.RotationAngle,'AspectRatio',roilist.AspectRatio);
        a=round(roilist.Center(1));
        b=round(roilist.Center(2));
        if movementcorrection==1
            text(a-y/2,b-x/2,string(j),'Color','b')
        else
            text(a,b,string(j),'Color','b')
        end

    end
end
if movementcorrection==1
    text(a-y/2,b-x/2,string(j),'Color','y')
else
    text(a,b,string(j),'Color','y')
end
%title(strcat(filename_short(1:9),filename_short(11:16)))

if astrocytes==0
    if Sensor==1
    else
subplot(3,5,14);hold on
plot(intensitymBeRFP,mean(intensitysmoothcorrected(1:720,:)),'k.')
title('baseline vs mBeRFP')
xlabel('mBeRFP intensity')
ylabel('gCarvi basline intensity')

if lengthvideo>4000
subplot(3,5,15); hold on
plot(intensitymBeRFP,max(intensitysmoothcorrected(lengthvideo-1000:lengthvideo-100,:)),'k.')
title('Forskolin vs mBeRFP')
end
    end
end

%% save everything
saveas(gcf,strcat(filename_short,'_Analysis'),'png')
if astrocytes==0
save(strcat(filename_short,'_Analysis'),'lengthvideo','meanDeltaFF','DeltaFF','intensity','intensitymBeRFP','DeltaFmBeRFP','meanDeltaFmBeRFP','intensitysmooth','intensitysmoothcorrected','nROI','eliminate','bleachingcorrection','DeltaFForsk','meanDeltaFForsk','scale','movementcorrection','framerate','intensitymBeRFPoriginal');
if uncaging==1
    save(strcat(filename_short,'_Analysis'),'lengthvideo','meanDeltaFF','DeltaFF','intensity','intensitymBeRFP','DeltaFmBeRFP','meanDeltaFmBeRFP','intensitysmooth','intensitysmoothcorrected','nROI','eliminate','bleachingcorrection','DeltaFForsk','meanDeltaFForsk','scale','movementcorrection','framerate','intensitymBeRFPoriginal','start_LED');
end
else
save(strcat(filename_short,'_Analysis'),'lengthvideo','meanDeltaFF','DeltaFF','intensity','intensitysmooth','intensitysmoothcorrected','nROI','eliminate','bleachingcorrection','DeltaFForsk','meanDeltaFForsk','scale','movementcorrection','framerate');
end
print('-depsc','-painters',strcat(filename_short,'_Analysis'));

%% function definitions used in this script
%Execute exit
function exitCallback(~,~,hFig)
        close(hFig);
        close all
end
    

%Execute slider button
function SliderCallback2(~,hAxis2,hAxis1)
    global i
    global c
    global hFig
    global xdata
    global ydata
    global threshold
    global frame
    global frame2
    global scale
    global scale2
    global hAxis2
    global hAxis1
    global rect_I
    
    threshold=c.Value;
    biggest = bwareafilt(im2bw(frame,threshold),[1,10000]);[yT,xT]=ind2sub([xdata,ydata],find(biggest));
    frameT=frame;
    for j=1:length(xT)
         frameT(yT(j),xT(j))=65535;
    end
    imshow(frameT*scale2,'Parent', hAxis1);
    
    A=flip(sort(reshape(frame2,[(rect_I(4)+1)*(rect_I(3)+1),1])));
    B=(double(A(length(xT)))+double(A(length(xT)+1)))/2;
    thresholdStart=B/65535;
    biggest = bwareafilt(im2bw(frame2,thresholdStart),[1,10000]);[yT,xT]=ind2sub([xdata,ydata],find(biggest));
    frameT2=frame2;
    for j=1:length(xT)
         frameT2(yT(j),xT(j))=65535;
    end
    imshow(frameT2*scale,'Parent', hAxis2);

    uicontrol(hFig,'unit','pixel','style','pushbutton','string',i,...
              'BackgroundColor',[0.5 0.5 1],'position',[830 400 100 25]);  
end

%Execute Add ROI
function addCallback(~,~,hAxis)
global roilist
global nROI
success = false;
repeats=0;
while ~success
    try       
        roilist=drawellipse('StripeColor','m');
        % If the code reaches this point without errors, set success to true
        success = true;
        
    catch exception
        % If there's an error, display the error message and wait for a while before trying again
        repeats=repeats+1
        disp(['Error: ', exception.message]);
        disp('Retrying in 5 seconds...');
        pause(5);  % You can adjust the pause duration as needed
    end
end
end


%Execute save ROI
function saveCallback(~,~,hAxis)
global roilist
global nROI
global scale
save(strcat('roilist_',string(nROI)),'roilist')
nROI=nROI+1;
a=round(roilist.Center(1));
b=round(roilist.Center(2));
text(a,b,string(nROI-1),'Color','y')
end

%Execute delete ROI
function deleteCallback(~,~,hAxis)
global roilist
global nROI
global scale
delete(strcat('roilist_',string(nROI-1)))
a=round(roilist.Center(1));
b=round(roilist.Center(2));
text(a,b,string(nROI-1),'Color','k')
nROI=nROI-1;
end


%execute to switch between 1st and last slide
function testAreaCallback(~,~,hAxis)
global filename
global lengthvideo
global k
global scale
global scale2
global frame1
if k==1
frame1 =imread(filename,'Index',lengthvideo-100);
imshow(frame1*scale2,'Parent',hAxis);hold on
k=0;
else
frame1 =imread(filename,'Index',101); 
imshow(frame1*scale,'Parent',hAxis);hold on
k=1;
end
end

%execute generate area selection tool
function selectAreaCallback(~,~,hAxis)
global rect_I
global frame1
global scale
global scale2
global k
if k==0
[~,rect_I]=imcrop(frame1*scale2);
else
    [~,rect_I]=imcrop(frame1*scale);
end
end


